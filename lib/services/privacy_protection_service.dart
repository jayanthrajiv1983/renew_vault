import 'dart:io';

import 'package:flutter/services.dart';

import 'settings_service.dart';

/// Applies platform-level privacy protection (e.g. Android FLAG_SECURE).
class PrivacyProtectionService {
  PrivacyProtectionService._();

  static final PrivacyProtectionService instance = PrivacyProtectionService._();

  static const _channel =
      MethodChannel('com.renewvault.app/privacy_protection');

  bool isProtectionEnabled() =>
      SettingsService.instance.getHideAppContentsInRecents();

  /// Enables or clears Android FLAG_SECURE based on the current setting.
  Future<void> syncSecureFlag() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      if (isProtectionEnabled()) {
        await _channel.invokeMethod<void>('setSecureFlag');
      } else {
        await _channel.invokeMethod<void>('clearSecureFlag');
      }
    } on PlatformException {
      // Platform channel unavailable — overlay still hides content visually.
    }
  }
}
