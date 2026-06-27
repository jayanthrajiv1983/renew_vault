import 'package:flutter/foundation.dart';

/// Coordinates app-lock UI state between [SettingsService] and [AppLockGate].
class AppLockController extends ChangeNotifier {
  AppLockController._();

  static final AppLockController instance = AppLockController._();

  /// Latest preference-driven lock state; `null` means no pending preference signal.
  bool? _preferenceEnabled;

  bool? get preferenceEnabled => _preferenceEnabled;

  void onAppLockPreferenceChanged(bool enabled) {
    _preferenceEnabled = enabled;
    debugPrint('App Lock Enabled: $enabled (preference changed)');
    notifyListeners();
  }
}
