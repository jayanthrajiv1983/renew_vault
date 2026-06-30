import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import '../core/services/logging_service.dart';
import '../core/services/crashlytics_service.dart';
import 'settings_service.dart';

/// Handles biometric / device-credential app lock timing and authentication.
class AppLockService {
  AppLockService._();

  static final AppLockService instance = AppLockService._();

  static const backgroundLockThreshold = Duration(seconds: 30);

  static const authenticateReason =
      'Unlock Renew Vault to access your items';

  final LocalAuthentication _auth = LocalAuthentication();

  DateTime? _lastBackgroundTime;
  bool _authInProgress = false;
  bool _unlockedThisSession = false;

  bool get authInProgress => _authInProgress;

  bool get isUnlockedThisSession => _unlockedThisSession;

  Future<void> init() async {
    if (kDebugMode) {
      debugPrint('AppLockService: initialized');
    }
  }

  bool isAppLockEnabled() => SettingsService.instance.getAppLockEnabled();

  void recordBackground() {
    _lastBackgroundTime = DateTime.now();
  }

  void clearBackgroundTime() {
    _lastBackgroundTime = null;
  }

  void markUnlocked() {
    _unlockedThisSession = true;
  }

  void markLocked() {
    _unlockedThisSession = false;
  }

  DateTime? get lastBackgroundTime => _lastBackgroundTime;

  /// Whether the lock should appear when returning from background.
  bool isLockRequiredOnResume() {
    if (!isAppLockEnabled()) {
      return false;
    }

    final lastBackground = _lastBackgroundTime;
    if (lastBackground == null) {
      return false;
    }

    return DateTime.now().difference(lastBackground) >= backgroundLockThreshold;
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } on Exception {
      return false;
    }
  }

  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } on Exception {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on Exception {
      return const [];
    }
  }

  Future<bool> authenticate() async {
    if (_authInProgress) {
      return false;
    }

    _authInProgress = true;
    LoggingService.instance.logInfo('SECURITY', 'Biometric authentication started');
    try {
      final isSupported = await isDeviceSupported();

      if (!isSupported) {
        LoggingService.instance.logError(
          CrashlyticsService.featureBiometrics,
          'Authentication failed',
          exception: StateError('Device not supported'),
          operation: 'Authentication Failed',
        );
        return false;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: authenticateReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (authenticated) {
        LoggingService.instance.logInfo('BIOMETRICS', 'Authentication successful');
        markUnlocked();
      } else {
        LoggingService.instance.logError(
          CrashlyticsService.featureBiometrics,
          'Authentication failed',
          exception: StateError('Authentication declined'),
          operation: 'Authentication Failed',
        );
      }
      return authenticated;
    } on Exception catch (error, stack) {
      LoggingService.instance.logError(
        CrashlyticsService.featureBiometrics,
        'Authentication failed',
        exception: error,
        stackTrace: stack,
        operation: 'Authentication Failed',
      );
      return false;
    } finally {
      _authInProgress = false;
    }
  }
}
