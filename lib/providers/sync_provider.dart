import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/connectivity_service.dart';
import '../core/services/cloud_backup_service.dart';

/// State for the backup provider
class BackupState {
  final BackupStatus status;
  final bool isOnline;
  final BackupResult? lastResult;
  final String? lastBackupTime;

  const BackupState({
    this.status = BackupStatus.idle,
    this.isOnline = false,
    this.lastResult,
    this.lastBackupTime,
  });

  BackupState copyWith({
    BackupStatus? status,
    bool? isOnline,
    BackupResult? lastResult,
    String? lastBackupTime,
  }) {
    return BackupState(
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      lastResult: lastResult ?? this.lastResult,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
    );
  }

  bool get isBackingUp => status == BackupStatus.backing_up;
  bool get hasError => status == BackupStatus.error;
}

/// Notifier that manages backup state and bridges connectivity + backup service
class BackupNotifier extends StateNotifier<BackupState> {
  final CloudBackupService _backupService;
  final ConnectivityService _connectivity;
  StreamSubscription<BackupStatus>? _backupSub;
  StreamSubscription<bool>? _connectSub;
  StreamSubscription<BackupResult>? _resultSub;

  BackupNotifier(this._backupService, this._connectivity)
    : super(BackupState(isOnline: _connectivity.isOnline)) {
    _listen();
  }

  void _listen() {
    _backupSub = _backupService.onStatusChange.listen((status) {
      state = state.copyWith(status: status);
    });

    _connectSub = _connectivity.onStatusChange.listen((online) {
      state = state.copyWith(isOnline: online);
    });

    _resultSub = _backupService.onBackupCompleted.listen((result) {
      state = state.copyWith(
        lastResult: result,
        lastBackupTime: DateTime.now().toIso8601String(),
      );
    });
  }

  /// Trigger a manual backup
  Future<BackupResult> backupNow() async {
    final result = await _backupService.triggerBackup();
    state = state.copyWith(
      lastResult: result,
      lastBackupTime: DateTime.now().toIso8601String(),
    );
    return result;
  }

  /// Get path to latest backup for sharing
  Future<String?> getLatestBackupPath() async {
    return await _backupService.getLatestBackupPath();
  }

  /// Restore from a backup file
  Future<BackupResult> restoreFromBackup(String filePath) async {
    return await _backupService.restoreFromBackup(filePath);
  }

  /// Get list of available backups
  Future<List<dynamic>> getAvailableBackups() async {
    return await _backupService.getAvailableBackups();
  }

  @override
  void dispose() {
    _backupSub?.cancel();
    _connectSub?.cancel();
    _resultSub?.cancel();
    super.dispose();
  }
}

/// Main backup provider
final backupProvider = StateNotifierProvider<BackupNotifier, BackupState>((
  ref,
) {
  return BackupNotifier(
    CloudBackupService.instance,
    ConnectivityService.instance,
  );
});

/// Provider for online/offline status
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(backupProvider).isOnline;
});

/// Provider for backup status
final backupStatusProvider = Provider<BackupStatus>((ref) {
  return ref.watch(backupProvider).status;
});

// Legacy aliases for backward compatibility
typedef SyncState = BackupState;
typedef SyncNotifier = BackupNotifier;
final syncProvider = backupProvider;
