import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../DB/db_helper.dart';
import '../models/app_settings.dart';
import 'connectivity_service.dart';

/// Backup status for the cloud backup service
enum BackupStatus { idle, backing_up, restoring, error }

/// Result of a backup operation
class BackupResult {
  final int recordsBackedUp;
  final Duration duration;
  final String? errorMessage;
  final String? backupPath;

  const BackupResult({
    this.recordsBackedUp = 0,
    this.duration = Duration.zero,
    this.errorMessage,
    this.backupPath,
  });

  bool get isSuccess => errorMessage == null;

  @override
  String toString() =>
      'BackupResult(records: $recordsBackedUp, duration: ${duration.inMilliseconds}ms, path: $backupPath)';
}

/// Cloud Backup Service - handles local database backup to JSON files
///
/// Strategy: Local-first with periodic JSON backup
/// - All data operations happen in local SQLite database
/// - Periodic backup exports database to JSON file
/// - Backup files can be shared/uploaded to any cloud storage
/// - Runs silently in background without interrupting user
class CloudBackupService {
  static final CloudBackupService instance = CloudBackupService._();
  CloudBackupService._();

  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));
  final _dbHelper = DatabaseHelper.instance;
  final _connectivity = ConnectivityService.instance;

  Timer? _periodicTimer;
  bool _isBackingUp = false;
  BackupStatus _status = BackupStatus.idle;
  final _statusController = StreamController<BackupStatus>.broadcast();
  final _backupCompletedController = StreamController<BackupResult>.broadcast();

  /// Current backup status
  BackupStatus get status => _status;

  /// Stream of backup status changes
  Stream<BackupStatus> get onStatusChange => _statusController.stream;

  /// Stream of backup completion events
  Stream<BackupResult> get onBackupCompleted =>
      _backupCompletedController.stream;

  /// Initialize the backup service with periodic backup
  void initialize({Duration interval = const Duration(hours: 1)}) {
    // Listen for connectivity restoration to trigger backup
    _connectivity.onConnectivityRestored = () {
      _logger.i('Connectivity restored - scheduling backup');
      // Delay to avoid immediate backup on connectivity change
      Future.delayed(const Duration(seconds: 10), () => createBackup());
    };

    // Periodic backup
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(interval, (_) {
      createBackup();
    });

    // Initial backup after app starts (with delay)
    Future.delayed(const Duration(seconds: 30), () => createBackup());

    _logger.i(
      'Cloud backup service initialized (interval: ${interval.inHours}h)',
    );
  }

  /// Create a backup of the local database
  Future<BackupResult> createBackup() async {
    if (_isBackingUp) {
      _logger.d('Backup already in progress, skipping');
      return const BackupResult();
    }

    _isBackingUp = true;
    _setStatus(BackupStatus.backing_up);
    final stopwatch = Stopwatch()..start();
    int totalRecords = 0;

    try {
      // Gather all data from local database
      final categories = await _dbHelper.getAllCategories();
      final cards = await _dbHelper.getAllCards();
      final payments = await _dbHelper.getAllPayments();
      final wishlist = await _dbHelper.getAllWishlistItems();
      final settings = await _dbHelper.getAllSettings();

      // Build backup data structure
      final backupData = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'app_name': 'GoobleGoblin',
        'data': {
          'categories': categories.map((c) => c.toMap()).toList(),
          'cards': cards.map((c) => c.toMap()).toList(),
          'payments': payments.map((p) => p.toMap()).toList(),
          'wishlist': wishlist, // Already List<Map>
          'settings': settings,
        },
      };

      totalRecords =
          categories.length + cards.length + payments.length + wishlist.length;

      // Save to local backup file
      final backupPath = await _saveBackupToFile(backupData);

      // Update last backup timestamp
      await _dbHelper.setSetting(
        AppSettingsKeys.lastBackupDate,
        DateTime.now().toIso8601String(),
      );

      stopwatch.stop();
      final result = BackupResult(
        recordsBackedUp: totalRecords,
        duration: stopwatch.elapsed,
        backupPath: backupPath,
      );

      _logger.i('Backup completed: $result');
      _setStatus(BackupStatus.idle);
      _backupCompletedController.add(result);

      return result;
    } catch (e) {
      stopwatch.stop();
      _logger.e('Backup failed: $e');
      _setStatus(BackupStatus.error);

      final result = BackupResult(
        recordsBackedUp: totalRecords,
        duration: stopwatch.elapsed,
        errorMessage: e.toString(),
      );
      _backupCompletedController.add(result);

      return result;
    } finally {
      _isBackingUp = false;
    }
  }

  /// Save backup data to a JSON file
  Future<String> _saveBackupToFile(Map<String, dynamic> data) async {
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/backups');

    // Create backup directory if it doesn't exist
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    // Generate filename with timestamp
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final filename = 'gooble_goblin_backup_$timestamp.json';
    final file = File('${backupDir.path}/$filename');

    // Write JSON data
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    await file.writeAsString(jsonString);

    // Clean up old backups (keep last 5)
    await _cleanupOldBackups(backupDir);

    _logger.d('Backup saved to: ${file.path}');
    return file.path;
  }

  /// Clean up old backup files, keeping only the most recent ones
  Future<void> _cleanupOldBackups(
    Directory backupDir, {
    int keepCount = 5,
  }) async {
    try {
      final files = await backupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();

      if (files.length <= keepCount) return;

      // Sort by modification time (newest first)
      files.sort((a, b) {
        final aTime = a.lastModifiedSync();
        final bTime = b.lastModifiedSync();
        return bTime.compareTo(aTime);
      });

      // Delete old files
      for (int i = keepCount; i < files.length; i++) {
        await files[i].delete();
        _logger.d('Deleted old backup: ${files[i].path}');
      }
    } catch (e) {
      _logger.w('Failed to cleanup old backups: $e');
    }
  }

  /// Restore data from a backup file
  Future<BackupResult> restoreFromBackup(String filePath) async {
    _setStatus(BackupStatus.restoring);
    final stopwatch = Stopwatch()..start();
    int totalRecords = 0;

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Backup file not found: $filePath');
      }

      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate backup format
      if (data['version'] == null || data['data'] == null) {
        throw Exception('Invalid backup format');
      }

      final backupData = data['data'] as Map<String, dynamic>;

      // Restore categories
      if (backupData['categories'] != null) {
        for (final catMap in backupData['categories'] as List) {
          await _dbHelper.upsertFromRemote(
            'categories',
            Map<String, dynamic>.from(catMap),
          );
          totalRecords++;
        }
      }

      // Restore cards
      if (backupData['cards'] != null) {
        for (final cardMap in backupData['cards'] as List) {
          await _dbHelper.upsertFromRemote(
            'cards',
            Map<String, dynamic>.from(cardMap),
          );
          totalRecords++;
        }
      }

      // Restore payments
      if (backupData['payments'] != null) {
        for (final payMap in backupData['payments'] as List) {
          await _dbHelper.upsertFromRemote(
            'payments',
            Map<String, dynamic>.from(payMap),
          );
          totalRecords++;
        }
      }

      // Restore wishlist
      if (backupData['wishlist'] != null) {
        for (final wishMap in backupData['wishlist'] as List) {
          await _dbHelper.upsertFromRemote(
            'wishlist',
            Map<String, dynamic>.from(wishMap),
          );
          totalRecords++;
        }
      }

      stopwatch.stop();
      final result = BackupResult(
        recordsBackedUp: totalRecords,
        duration: stopwatch.elapsed,
        backupPath: filePath,
      );

      _logger.i('Restore completed: $result');
      _setStatus(BackupStatus.idle);

      return result;
    } catch (e) {
      stopwatch.stop();
      _logger.e('Restore failed: $e');
      _setStatus(BackupStatus.error);

      return BackupResult(
        recordsBackedUp: totalRecords,
        duration: stopwatch.elapsed,
        errorMessage: e.toString(),
      );
    }
  }

  /// Get list of available backup files
  Future<List<File>> getAvailableBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');

      if (!await backupDir.exists()) {
        return [];
      }

      final files = await backupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();

      // Sort by modification time (newest first)
      files.sort((a, b) {
        final aTime = a.lastModifiedSync();
        final bTime = b.lastModifiedSync();
        return bTime.compareTo(aTime);
      });

      return files;
    } catch (e) {
      _logger.e('Failed to get backup list: $e');
      return [];
    }
  }

  /// Get the path to the latest backup file (for sharing)
  Future<String?> getLatestBackupPath() async {
    final backups = await getAvailableBackups();
    return backups.isNotEmpty ? backups.first.path : null;
  }

  /// Get backup directory path
  Future<String> getBackupDirectoryPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/backups';
  }

  /// Trigger an immediate backup
  Future<BackupResult> triggerBackup() async {
    return await createBackup();
  }

  void _setStatus(BackupStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  /// Dispose resources
  void dispose() {
    _periodicTimer?.cancel();
    _statusController.close();
    _backupCompletedController.close();
  }
}
