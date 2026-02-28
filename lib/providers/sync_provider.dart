import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/connectivity_service.dart';
import '../core/services/sync_engine.dart';

/// State for the sync provider
class SyncState {
  final SyncEngineStatus status;
  final bool isOnline;
  final SyncResult? lastResult;
  final String? lastSyncTime;

  const SyncState({
    this.status = SyncEngineStatus.idle,
    this.isOnline = false,
    this.lastResult,
    this.lastSyncTime,
  });

  SyncState copyWith({
    SyncEngineStatus? status,
    bool? isOnline,
    SyncResult? lastResult,
    String? lastSyncTime,
  }) {
    return SyncState(
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      lastResult: lastResult ?? this.lastResult,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }

  bool get isSyncing => status == SyncEngineStatus.syncing;
  bool get hasError => status == SyncEngineStatus.error;
}

/// Notifier that manages sync state and bridges connectivity + sync engine
class SyncNotifier extends StateNotifier<SyncState> {
  final SyncEngine _syncEngine;
  final ConnectivityService _connectivity;
  StreamSubscription<SyncEngineStatus>? _syncSub;
  StreamSubscription<bool>? _connectSub;

  SyncNotifier(this._syncEngine, this._connectivity)
    : super(SyncState(isOnline: _connectivity.isOnline)) {
    _listen();
  }

  void _listen() {
    _syncSub = _syncEngine.onStatusChange.listen((status) {
      state = state.copyWith(status: status);
    });

    _connectSub = _connectivity.onStatusChange.listen((online) {
      state = state.copyWith(isOnline: online);
    });
  }

  /// Trigger a manual sync
  Future<void> syncNow() async {
    final result = await _syncEngine.syncAll();
    state = state.copyWith(
      lastResult: result,
      lastSyncTime: DateTime.now().toIso8601String(),
    );
  }

  /// Trigger sync after a local data change
  Future<void> syncAfterChange() async {
    await _syncEngine.triggerSync();
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    _connectSub?.cancel();
    super.dispose();
  }
}

/// Main sync provider
final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(SyncEngine.instance, ConnectivityService.instance);
});

/// Provider for online/offline status
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(syncProvider).isOnline;
});

/// Provider for sync status
final syncStatusProvider = Provider<SyncEngineStatus>((ref) {
  return ref.watch(syncProvider).status;
});
