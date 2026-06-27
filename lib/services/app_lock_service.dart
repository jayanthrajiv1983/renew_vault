import 'package:local_auth/local_auth.dart';

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
  bool _isAuthenticating = false;

  bool get isAuthenticating => _isAuthenticating;

  bool isAppLockEnabled() => SettingsService.instance.getAppLockEnabled();

  void recordBackground() {
    _lastBackgroundTime = DateTime.now();
  }

  void clearBackgroundTime() {
    _lastBackgroundTime = null;
  }

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
    if (_isAuthenticating) {
      return false;
    }

    _isAuthenticating = true;
    try {
      final supported = await isDeviceSupported();
      if (!supported) {
        return false;
      }

      return await _auth.authenticate(
        localizedReason: authenticateReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on Exception {
      return false;
    } finally {
      _isAuthenticating = false;
    }
  }
}
