import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/DB/db_helper.dart';
import '../../../core/models/app_settings.dart';

/// Authentication state
class AuthState {
  final bool isBiometricEnabled;
  final bool isAuthenticated;
  final bool isLoading;
  final bool canCheckBiometrics;
  final String? error;

  const AuthState({
    this.isBiometricEnabled = false,
    this.isAuthenticated = false,
    this.isLoading = true,
    this.canCheckBiometrics = false,
    this.error,
  });

  AuthState copyWith({
    bool? isBiometricEnabled,
    bool? isAuthenticated,
    bool? isLoading,
    bool? canCheckBiometrics,
    String? error,
  }) {
    return AuthState(
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      canCheckBiometrics: canCheckBiometrics ?? this.canCheckBiometrics,
      error: error,
    );
  }

  /// Whether to show the auth screen
  bool get shouldShowAuth => isBiometricEnabled && !isAuthenticated;
}

/// Auth notifier for managing authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  final LocalAuthentication _localAuth;
  final DatabaseHelper _db;

  AuthNotifier(this._localAuth, this._db) : super(const AuthState()) {
    _initialize();
  }

  /// Initialize auth state
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      // Check if device supports biometrics
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      final hasBiometrics =
          canCheckBiometrics && availableBiometrics.isNotEmpty;

      // Check if biometric auth setting exists
      final biometricSetting = await _db.getSetting(
        AppSettingsKeys.biometricEnabled,
      );

      // Enable biometrics by default on supported devices
      // Only disable if user explicitly set it to 'false'
      final bool isBiometricEnabled;
      if (biometricSetting == null && hasBiometrics) {
        // First launch on supported device - enable by default
        isBiometricEnabled = true;
        await _db.setSetting(AppSettingsKeys.biometricEnabled, 'true');
      } else {
        // Use saved setting (or false if device doesn't support)
        isBiometricEnabled = biometricSetting == 'true' && hasBiometrics;
      }

      state = state.copyWith(
        canCheckBiometrics: hasBiometrics,
        isBiometricEnabled: isBiometricEnabled,
        isLoading: false,
        // Require authentication if biometric is enabled
        isAuthenticated: !isBiometricEnabled,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize auth: $e',
        // On error, allow access
        isAuthenticated: true,
      );
    }
  }

  /// Toggle biometric authentication setting
  Future<bool> toggleBiometric(bool enabled) async {
    try {
      await _db.setSetting(
        AppSettingsKeys.biometricEnabled,
        enabled.toString(),
      );
      state = state.copyWith(isBiometricEnabled: enabled);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to update setting: $e');
      return false;
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticate() async {
    if (!state.canCheckBiometrics || !state.isBiometricEnabled) {
      return true;
    }

    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your finances',
        authMessages: const [],
      );

      if (didAuthenticate) {
        state = state.copyWith(isAuthenticated: true, error: null);
      }

      return didAuthenticate;
    } catch (e) {
      state = state.copyWith(error: 'Authentication failed: $e');
      return false;
    }
  }

  /// Logout (require re-authentication)
  void logout() {
    state = state.copyWith(isAuthenticated: false);
  }

  /// Refresh auth state from settings
  Future<void> refresh() async {
    await _initialize();
  }
}

/// Provider for LocalAuthentication
final localAuthProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

/// Provider for auth state
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final localAuth = ref.watch(localAuthProvider);
  return AuthNotifier(localAuth, DatabaseHelper.instance);
});

/// Provider to check if auth is needed (for app router)
final isAuthNeededProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.shouldShowAuth;
});
