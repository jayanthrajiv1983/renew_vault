import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import '../core/services/logging_service.dart';
import 'settings_service.dart';

/// Handles biometric / device-credential app lock timing and authentication.
class AppLockService {
  AppLockService._();

  static final AppLockService instance = AppLockService._();

  static const backgroundLockThreshold = Duration(seconds: 30);

  static const authenticateReason =
      'Unlock Renew Vault to access your renewals';

  final LocalAuthentication _auth = LocalAuthentication();

  DateTime? _lastBackgroundTime;
  bool _authInProgress = false;
  bool _unlockedThisSession = false;

  bool get authInProgress => _authInProgress;

  bool get isUnlockedThisSession => _unlockedThisSession;

  Future<void> init() async {
    final enabled = isAppLockEnabled();
    debugPrint('App Lock enabled: $enabled');

    final isSupported = await isDeviceSupported();
    debugPrint('Device supported: $isSupported');

    final canCheck = await canCheckBiometrics();
    debugPrint('Can check biometrics: $canCheck');

    final availableBiometrics = await getAvailableBiometrics();
    debugPrint('Available biometrics: $availableBiometrics');
  }

  bool isAppLockEnabled() => SettingsService.instance.getAppLockEnabled();

  void recordBackground() {
    _lastBackgroundTime = DateTime.now();
    debugPrint('Last Background Time: $_lastBackgroundTime');
  }

  void clearBackgroundTime() {
    _lastBackgroundTime = null;
  }

  void markUnlocked() {
    _unlockedThisSession = true;
    debugPrint('Session unlocked');
  }

  void markLocked() {
    _unlockedThisSession = false;
    debugPrint('Session locked');
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
      debugPrint('Authentication requested: skipped (already in progress)');
      return false;
    }

    _authInProgress = true;
    LoggingService.instance.logInfo('SECURITY', 'Biometric authentication started');
    debugPrint('Authentication requested');
    try {
      final isSupported = await isDeviceSupported();
      debugPrint('Device supported: $isSupported');

      final canCheck = await canCheckBiometrics();
      debugPrint('Can check biometrics: $canCheck');

      final availableBiometrics = await getAvailableBiometrics();
      debugPrint('Available biometrics: $availableBiometrics');

      if (!isSupported) {
        debugPrint('Authentication result: false (device not supported)');
        LoggingService.instance.logError('SECURITY', 'Authentication failed');
        return false;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: authenticateReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      debugPrint('Authentication result: $authenticated');
      if (authenticated) {
        LoggingService.instance.logInfo('SECURITY', 'Authentication successful');
        markUnlocked();
      } else {
        LoggingService.instance.logError('SECURITY', 'Authentication failed');
      }
      return authenticated;
    } on Exception catch (error) {
      debugPrint('Authentication result: false ($error)');
      LoggingService.instance.logError('SECURITY', 'Authentication failed');
      return false;
    } finally {
      _authInProgress = false;
    }
  }
}
