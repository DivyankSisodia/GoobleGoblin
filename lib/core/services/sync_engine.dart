import 'dart:async';
import 'package:logger/logger.dart';

import '../DB/db_helper.dart';
import '../models/card.dart';
import '../models/category.dart';
import '../models/payment.dart';
import '../models/wishlist_item.dart';
import 'connectivity_service.dart';
import 'supabase_config.dart';
import 'supabase_data_source.dart';

/// Sync status for the overall sync engine
enum SyncEngineStatus { idle, syncing, error, offline }

/// Result of a sync operation
class SyncResult {
  final int pushed;
  final int pulled;
  final int conflicts;
  final int errors;
  final Duration duration;
  final String? errorMessage;

  const SyncResult({
    this.pushed = 0,
    this.pulled = 0,
    this.conflicts = 0,
    this.errors = 0,
    this.duration = Duration.zero,
    this.errorMessage,
  });

  bool get isSuccess => errors == 0 && errorMessage == null;

  @override
  String toString() =>
      'SyncResult(pushed: $pushed, pulled: $pulled, conflicts: $conflicts, errors: $errors, duration: ${duration.inMilliseconds}ms)';
}

/// The sync engine coordinates bidirectional sync between local SQLite and Supabase.
///
/// Strategy: Offline-first with background push/pull
/// - All writes go to local SQLite first (always fast)
/// - Pending changes are pushed to Supabase when online
/// - Remote changes are pulled down periodically
/// - Conflict resolution: Last-write-wins (based on updatedAt timestamp)
/// - Sync order: Categories → Cards → Payments → Wishlist (respects FK dependencies)
class SyncEngine {
  static final SyncEngine instance = SyncEngine._();
  SyncEngine._();

  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));
  final _dbHelper = DatabaseHelper.instance;
  final _remote = SupabaseDataSource.instance;
  final _connectivity = ConnectivityService.instance;

  Timer? _periodicTimer;
  bool _isSyncing = false;
  SyncEngineStatus _status = SyncEngineStatus.idle;
  final _statusController = StreamController<SyncEngineStatus>.broadcast();

  /// Fires after any sync that changed data (pulled > 0 or pushed > 0).
  /// Listeners should reload their local data from SQLite.
  final _dataChangedController = StreamController<SyncResult>.broadcast();
  Stream<SyncResult> get onDataChanged => _dataChangedController.stream;

  /// Current sync status
  SyncEngineStatus get status => _status;

  /// Stream of sync status changes
  Stream<SyncEngineStatus> get onStatusChange => _statusController.stream;

  /// Initialize the sync engine with periodic sync and connectivity triggers
  void initialize({Duration interval = const Duration(minutes: 5)}) {
    if (!SupabaseConfig.isConfigured) {
      _logger.w('Supabase not configured - sync disabled');
      return;
    }

    // Listen for connectivity restoration
    _connectivity.onConnectivityRestored = () {
      _logger.i('Connectivity restored - triggering sync');
      syncAll();
    };

    // Periodic sync
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(interval, (_) {
      if (_connectivity.isOnline) {
        syncAll();
      }
    });

    // Initial sync if online
    if (_connectivity.isOnline) {
      Future.delayed(const Duration(seconds: 2), () => syncAll());
    }

    _logger.i('Sync engine initialized (interval: ${interval.inMinutes}min)');
  }

  /// Perform a full bidirectional sync
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      _logger.d('Sync already in progress, skipping');
      return const SyncResult();
    }

    if (!_connectivity.isOnline) {
      _setStatus(SyncEngineStatus.offline);
      return const SyncResult(errorMessage: 'Device is offline');
    }

    if (!SupabaseConfig.isConfigured) {
      return const SyncResult(errorMessage: 'Supabase not configured');
    }

    _isSyncing = true;
    _setStatus(SyncEngineStatus.syncing);
    final stopwatch = Stopwatch()..start();

    int totalPushed = 0;
    int totalPulled = 0;
    int totalConflicts = 0;
    int totalErrors = 0;

    try {
      // Sync in dependency order: Categories → Cards → Payments → Wishlist

      // 1. Push local changes to remote
      final pushResult = await _pushAllPendingChanges();
      totalPushed = pushResult.pushed;
      totalErrors += pushResult.errors;

      // 2. Pull remote changes to local
      final pullResult = await _pullRemoteChanges();
      totalPulled = pullResult.pulled;
      totalConflicts = pullResult.conflicts;
      totalErrors += pullResult.errors;

      // 3. Purge locally-deleted records that have been synced
      await _purgeDeletedRecords();

      stopwatch.stop();
      final result = SyncResult(
        pushed: totalPushed,
        pulled: totalPulled,
        conflicts: totalConflicts,
        errors: totalErrors,
        duration: stopwatch.elapsed,
      );

      _logger.i('Sync completed: $result');
      _setStatus(SyncEngineStatus.idle);

      // Notify listeners if any data moved (so UI providers can reload)
      if (result.pulled > 0 || result.pushed > 0) {
        _dataChangedController.add(result);
      }

      return result;
    } catch (e) {
      stopwatch.stop();
      _logger.e('Sync failed: $e');
      _setStatus(SyncEngineStatus.error);
      return SyncResult(
        pushed: totalPushed,
        pulled: totalPulled,
        errors: totalErrors + 1,
        duration: stopwatch.elapsed,
        errorMessage: e.toString(),
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Push all pending local changes to Supabase
  Future<SyncResult> _pushAllPendingChanges() async {
    int pushed = 0;
    int errors = 0;

    // 1. Categories (no dependencies)
    final catResult = await _pushTable<Category>(
      table: 'categories',
      remoteTable: SupabaseConfig.categoriesTable,
      toSupabaseMap: (map) => Category.fromMap(map).toSupabaseMap(),
      onDelete: (uuid) => _remote.deleteCategory(uuid),
      onUpsert: (data) => _remote.upsertCategory(data),
    );
    pushed += catResult.pushed;
    errors += catResult.errors;

    // 2. Cards (no dependencies)
    final cardResult = await _pushTable<BankCard>(
      table: 'cards',
      remoteTable: SupabaseConfig.cardsTable,
      toSupabaseMap: (map) => BankCard.fromMap(map).toSupabaseMap(),
      onDelete: (uuid) => _remote.deleteCard(uuid),
      onUpsert: (data) => _remote.upsertCard(data),
    );
    pushed += cardResult.pushed;
    errors += cardResult.errors;

    // 3. Payments (depends on cards + categories)
    final payResult = await _pushTable<Payment>(
      table: 'payments',
      remoteTable: SupabaseConfig.paymentsTable,
      toSupabaseMap: (map) => Payment.fromMap(map).toSupabaseMap(),
      onDelete: (uuid) => _remote.deletePayment(uuid),
      onUpsert: (data) => _remote.upsertPayment(data),
    );
    pushed += payResult.pushed;
    errors += payResult.errors;

    // 4. Wishlist (no dependencies)
    final wishResult = await _pushTable<WishlistItem>(
      table: 'wishlist',
      remoteTable: SupabaseConfig.wishlistTable,
      toSupabaseMap: (map) => WishlistItem.fromMap(map).toSupabaseMap(),
      onDelete: (uuid) => _remote.deleteWishlistItem(uuid),
      onUpsert: (data) => _remote.upsertWishlistItem(data),
    );
    pushed += wishResult.pushed;
    errors += wishResult.errors;

    return SyncResult(pushed: pushed, errors: errors);
  }

  /// Push pending changes for a single table
  Future<SyncResult> _pushTable<T>({
    required String table,
    required String remoteTable,
    required Map<String, dynamic> Function(Map<String, dynamic>) toSupabaseMap,
    required Future<void> Function(String uuid) onDelete,
    required Future<Map<String, dynamic>> Function(Map<String, dynamic>)
    onUpsert,
  }) async {
    int pushed = 0;
    int errors = 0;

    try {
      // Handle pending creates and updates
      final pendingCreates = await _dbHelper.getPendingCreates(table);
      final pendingUpdates = await _dbHelper.getPendingUpdates(table);

      for (final record in [...pendingCreates, ...pendingUpdates]) {
        try {
          final uuid = record['uuid'] as String?;
          if (uuid == null) continue;

          final remoteData = toSupabaseMap(record);
          remoteData['updated_at'] = DateTime.now().toIso8601String();

          await onUpsert(remoteData);
          await _dbHelper.markSynced(table, record['id'] as int);
          pushed++;
        } catch (e) {
          _logger.e('Failed to push $table record ${record['id']}: $e');
          errors++;
        }
      }

      // Handle pending deletes
      final pendingDeletes = await _dbHelper.getPendingDeletes(table);
      for (final record in pendingDeletes) {
        try {
          final uuid = record['uuid'] as String?;
          if (uuid == null) continue;

          await onDelete(uuid);
          await _dbHelper.markSynced(table, record['id'] as int);
          pushed++;
        } catch (e) {
          _logger.e(
            'Failed to push delete for $table uuid=${record['uuid']}: $e',
          );
          errors++;
        }
      }
    } catch (e) {
      _logger.e('Failed to push $table: $e');
      errors++;
    }

    return SyncResult(pushed: pushed, errors: errors);
  }

  /// Pull remote changes from Supabase to local database
  Future<SyncResult> _pullRemoteChanges() async {
    int pulled = 0;
    int conflicts = 0;
    int errors = 0;

    final lastSync = await _dbHelper.getSetting('last_sync_timestamp');

    try {
      // 1. Pull categories
      final remoteCats = await _remote.fetchCategories(since: lastSync);
      for (final remoteCat in remoteCats) {
        try {
          final result = await _pullRecord('categories', remoteCat, (map) {
            return {
              'label': map['label'],
              'icon': map['icon'],
              'assetPath': map['asset_path'],
              'isPredefined': (map['is_predefined'] == true) ? 1 : 0,
              'uuid': map['uuid'],
              'isDeleted': (map['is_deleted'] == true) ? 1 : 0,
            };
          });
          if (result == _PullResult.pulled) pulled++;
          if (result == _PullResult.conflict) conflicts++;
        } catch (e) {
          errors++;
        }
      }

      // 2. Pull cards
      final remoteCards = await _remote.fetchCards(since: lastSync);
      for (final remoteCard in remoteCards) {
        try {
          final result = await _pullRecord('cards', remoteCard, (map) {
            final now = DateTime.now().toIso8601String();
            return {
              'bankName': map['bank_name'],
              'balance': map['balance'],
              'date': map['date'],
              'type': map['type'],
              'isPrimary': (map['is_primary'] == true) ? 1 : 0,
              'createdAt': map['created_at'] ?? now,
              'updatedAt': map['updated_at'] ?? now,
              'accountType': map['account_type'] ?? 'DEBIT',
              'creditLimit': map['credit_limit'] ?? 0,
              'usedAmount': map['used_amount'] ?? 0,
              'uuid': map['uuid'],
              'isDeleted': (map['is_deleted'] == true) ? 1 : 0,
            };
          });
          if (result == _PullResult.pulled) pulled++;
          if (result == _PullResult.conflict) conflicts++;
        } catch (e) {
          errors++;
        }
      }

      // 3. Pull payments (need to resolve card/category UUIDs to local IDs)
      final remotePayments = await _remote.fetchPayments(since: lastSync);
      final cardUuidMap = await _dbHelper.getReverseUuidMapping('cards');
      final catUuidMap = await _dbHelper.getReverseUuidMapping('categories');

      for (final remotePay in remotePayments) {
        try {
          final cardUuid = remotePay['card_uuid'] as String?;
          final catUuid = remotePay['category_uuid'] as String?;

          final localCardId = cardUuid != null ? cardUuidMap[cardUuid] : null;
          final localCatId = catUuid != null ? catUuidMap[catUuid] : null;

          if (localCardId == null && remotePay['is_deleted'] != true) {
            _logger.w(
              'Skipping payment ${remotePay['uuid']}: card UUID $cardUuid not found locally',
            );
            continue;
          }

          final result = await _pullRecord('payments', remotePay, (map) {
            final now = DateTime.now().toIso8601String();
            return {
              'amount': map['amount'],
              'date': map['date'],
              'cardId': localCardId ?? 0,
              'categoryId': localCatId ?? 0,
              'isRecurring': (map['is_recurring'] == true) ? 1 : 0,
              'frequency': map['frequency'],
              'reminderNotification': (map['reminder_notification'] == true)
                  ? 1
                  : 0,
              'note': map['note'],
              'createdAt': map['created_at'] ?? now,
              'uuid': map['uuid'],
              'cardUuid': cardUuid,
              'categoryUuid': catUuid,
              'isDeleted': (map['is_deleted'] == true) ? 1 : 0,
            };
          });
          if (result == _PullResult.pulled) pulled++;
          if (result == _PullResult.conflict) conflicts++;
        } catch (e) {
          errors++;
        }
      }

      // 4. Pull wishlist
      final remoteWishlist = await _remote.fetchWishlist(since: lastSync);
      for (final remoteItem in remoteWishlist) {
        try {
          final result = await _pullRecord('wishlist', remoteItem, (map) {
            return {
              'url': map['url'],
              'title': map['title'],
              'image_url': map['image_url'],
              'price': map['price'],
              'notes': map['notes'],
              'date_added': map['date_added'],
              'is_purchased': (map['is_purchased'] == true) ? 1 : 0,
              'updated_at': map['updated_at'],
              'uuid': map['uuid'],
              'isDeleted': (map['is_deleted'] == true) ? 1 : 0,
            };
          });
          if (result == _PullResult.pulled) pulled++;
          if (result == _PullResult.conflict) conflicts++;
        } catch (e) {
          errors++;
        }
      }

      // Update last sync timestamp
      await _dbHelper.setSetting(
        'last_sync_timestamp',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      _logger.e('Failed to pull remote changes: $e');
      errors++;
    }

    return SyncResult(pulled: pulled, conflicts: conflicts, errors: errors);
  }

  /// Pull a single record from remote, handling conflicts
  Future<_PullResult> _pullRecord(
    String table,
    Map<String, dynamic> remoteData,
    Map<String, dynamic> Function(Map<String, dynamic>) toLocalMap,
  ) async {
    final uuid = remoteData['uuid'] as String?;
    if (uuid == null) return _PullResult.skipped;

    final localRecord = await _dbHelper.getByUuid(table, uuid);
    final localData = toLocalMap(remoteData);
    localData['syncStatus'] = 'SYNCED';
    localData['lastSyncedAt'] = DateTime.now().toIso8601String();

    if (localRecord == null) {
      // New record from remote - insert locally
      await _dbHelper.upsertFromRemote(table, localData);
      return _PullResult.pulled;
    }

    // Record exists locally - check for conflicts
    final localSyncStatus = localRecord['syncStatus'] as String?;

    if (localSyncStatus == 'SYNCED') {
      // No local changes - safe to overwrite
      localData.remove('id');
      final db = await _dbHelper.database;
      await db.update(table, localData, where: 'uuid = ?', whereArgs: [uuid]);
      return _PullResult.pulled;
    }

    // Local has pending changes - conflict!
    // Strategy: Last-write-wins based on updatedAt
    final remoteUpdated = remoteData['updated_at'] as String?;
    final localUpdated = localRecord['updatedAt'] ?? localRecord['updated_at'];

    if (remoteUpdated != null && localUpdated != null) {
      final remoteTime = DateTime.tryParse(remoteUpdated);
      final localTime = DateTime.tryParse(localUpdated as String);

      if (remoteTime != null &&
          localTime != null &&
          remoteTime.isAfter(localTime)) {
        // Remote is newer - overwrite local
        localData.remove('id');
        final db = await _dbHelper.database;
        await db.update(table, localData, where: 'uuid = ?', whereArgs: [uuid]);
        _logger.w('Conflict resolved for $table uuid=$uuid: Remote wins');
        return _PullResult.conflict;
      }
    }

    // Local is newer or can't determine - keep local (will push on next sync)
    _logger.d(
      'Conflict for $table uuid=$uuid: Local wins, will push next sync',
    );
    return _PullResult.conflict;
  }

  /// Remove locally deleted records that have been successfully synced
  Future<void> _purgeDeletedRecords() async {
    await _dbHelper.purgeDeletedRecords('categories');
    await _dbHelper.purgeDeletedRecords('cards');
    await _dbHelper.purgeDeletedRecords('payments');
    await _dbHelper.purgeDeletedRecords('wishlist');
  }

  void _setStatus(SyncEngineStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  /// Trigger an immediate sync (called after local changes)
  Future<void> triggerSync() async {
    if (_connectivity.isOnline && !_isSyncing) {
      // Debounce: wait a bit for multiple rapid changes
      await Future.delayed(const Duration(milliseconds: 500));
      await syncAll();
    }
  }

  /// Dispose resources
  void dispose() {
    _periodicTimer?.cancel();
    _statusController.close();
    _dataChangedController.close();
  }
}

enum _PullResult { pulled, conflict, skipped }
