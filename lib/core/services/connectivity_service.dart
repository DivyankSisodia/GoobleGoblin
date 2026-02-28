import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Service to monitor network connectivity and trigger sync
class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._();
  ConnectivityService._();

  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final _statusController = StreamController<bool>.broadcast();

  bool _isOnline = false;

  /// Whether the device currently has internet connectivity
  bool get isOnline => _isOnline;

  /// Stream of connectivity status changes (true = online, false = offline)
  Stream<bool> get onStatusChange => _statusController.stream;

  /// Callback to trigger when connectivity is restored
  VoidCallback? onConnectivityRestored;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial status
    final result = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(result);
    _logger.i('Initial connectivity: ${_isOnline ? "Online" : "Offline"}');

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final wasOffline = !_isOnline;
      _isOnline = _isConnected(results);

      _statusController.add(_isOnline);
      _logger.i('Connectivity changed: ${_isOnline ? "Online" : "Offline"}');

      // Trigger sync when coming back online
      if (wasOffline && _isOnline) {
        _logger.i('Connection restored - triggering sync');
        onConnectivityRestored?.call();
      }
    });
  }

  /// Check connectivity manually
  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(result);
    return _isOnline;
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet,
    );
  }

  /// Dispose of resources
  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}
