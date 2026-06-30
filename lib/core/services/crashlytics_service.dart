import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../services/app_info_service.dart';

/// Centralizes Firebase Crashlytics initialization and non-fatal error reporting.
///
/// **Privacy:** Only exception, stack trace, feature name, operation label, and
/// app version are sent. Log messages, OCR text, paths, and user data are never
/// attached. Collection is enabled only when the user grants consent in release
/// builds.
class CrashlyticsService {
  CrashlyticsService._();

  static final CrashlyticsService instance = CrashlyticsService._();

  static const featureOcr = 'OCR';
  static const featureBackup = 'BACKUP';
  static const featureCloud = 'CLOUD';
  static const featureRestore = 'RESTORE';
  static const featureAttachments = 'ATTACHMENTS';
  static const featureNotifications = 'NOTIFICATIONS';
  static const featureBiometrics = 'BIOMETRICS';
  static const featureCrashlytics = 'CRASHLYTICS';

  bool _handlersConfigured = false;
  bool _userConsentEnabled = false;

  bool get _shouldCollect => kReleaseMode && _userConsentEnabled;

  bool get isEnabled => _shouldCollect && _handlersConfigured;

  /// User granted crash reporting consent in Settings.
  bool get hasUserConsent => _userConsentEnabled;

  /// Reports upload only in release builds when consent is granted.
  bool get willUploadReports => _shouldCollect;

  /// Enables/disables collection and installs global error handlers.
  ///
  /// Call immediately after [Firebase.initializeApp]. [crashReportingEnabled]
  /// reflects the persisted user preference from [SettingsService].
  Future<void> init({required bool crashReportingEnabled}) async {
    if (_handlersConfigured) {
      return;
    }

    _userConsentEnabled = crashReportingEnabled;
    await _applyCollectionSetting();

    FlutterError.onError = (FlutterErrorDetails details) {
      if (_shouldCollect) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      } else {
        FlutterError.presentError(details);
      }
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      if (_shouldCollect) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
      return true;
    };

    _handlersConfigured = true;
  }

  /// Updates collection when the user changes consent in Settings or the prompt.
  Future<void> updateConsent(bool enabled) async {
    _userConsentEnabled = enabled;
    await _applyCollectionSetting();
  }

  Future<void> _applyCollectionSetting() async {
    try {
      if (kReleaseMode) {
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(_userConsentEnabled);
      } else {
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(false);
      }
    } catch (_) {
      // Crashlytics must never break callers.
    }
  }

  /// Sets release-only custom keys that depend on [AppInfoService].
  ///
  /// Call after [AppInfoService.init].
  Future<void> configureCustomKeys() async {
    if (!_shouldCollect) {
      return;
    }

    final version = AppInfoService.instance.versionSync;
    if (version != null) {
      await FirebaseCrashlytics.instance.setCustomKey('app_version', version);
    }
  }

  /// Forwards a [LoggingService.logError] call as a non-fatal Crashlytics event.
  ///
  /// Uses [feature] (log category) only — never the log message, to avoid PII.
  void recordNonFatalFromLog(String feature) {
    if (!isEnabled) {
      return;
    }

    unawaited(_recordNonFatalFromLog(feature));
  }

  Future<void> _recordNonFatalFromLog(String feature) async {
    try {
      await FirebaseCrashlytics.instance.setCustomKey('feature', feature);
      await FirebaseCrashlytics.instance.recordError(
        _LoggedApplicationError(feature),
        StackTrace.current,
        reason: feature,
        fatal: false,
      );
    } catch (_) {
      // Crashlytics must never break app logging.
    }
  }

  /// Records an exception with optional stack trace (release builds only).
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    required String feature,
    bool fatal = false,
  }) async {
    if (!isEnabled) {
      return;
    }

    try {
      await FirebaseCrashlytics.instance.setCustomKey('feature', feature);
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: feature,
        fatal: fatal,
      );
    } catch (_) {
      // Crashlytics must never break callers.
    }
  }

  /// Non-fatal feature error with [feature], [operation], and [app_version] keys.
  ///
  /// [reason] is `'$feature $operation'` only — never log messages or PII.
  void recordFeatureError({
    required String feature,
    required String operation,
    required Object exception,
    StackTrace? stackTrace,
  }) {
    if (!isEnabled) {
      return;
    }

    unawaited(
      _recordFeatureError(
        feature: feature,
        operation: operation,
        exception: exception,
        stackTrace: stackTrace,
      ),
    );
  }

  Future<void> _recordFeatureError({
    required String feature,
    required String operation,
    required Object exception,
    StackTrace? stackTrace,
  }) async {
    try {
      await FirebaseCrashlytics.instance.setCustomKey('feature', feature);
      await FirebaseCrashlytics.instance.setCustomKey('operation', operation);
      final version = AppInfoService.instance.versionSync;
      if (version != null) {
        await FirebaseCrashlytics.instance.setCustomKey('app_version', version);
      }
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stackTrace ?? StackTrace.current,
        reason: '$feature $operation',
        fatal: false,
      );
    } catch (_) {
      // Crashlytics must never break callers.
    }
  }

  /// Beta tester tool: sends a deliberate non-fatal error to Crashlytics.
  Future<void> testNonFatal() async {
    try {
      await FirebaseCrashlytics.instance
          .setCustomKey('feature', featureCrashlytics);
      await FirebaseCrashlytics.instance.recordError(
        Exception('Renew Vault test non-fatal error'),
        StackTrace.current,
        reason: 'Beta test non-fatal',
        fatal: false,
      );
    } catch (_) {
      // Crashlytics must never break beta tools.
    }
  }

  /// Beta tester tool: forces a native crash via Crashlytics.
  void testCrash() {
    try {
      FirebaseCrashlytics.instance.crash();
    } catch (_) {
      // Fallback if crash() is unavailable on this platform.
      throw Exception('Renew Vault test crash');
    }
  }
}

/// Lightweight marker exception — carries no user or document data.
class _LoggedApplicationError implements Exception {
  _LoggedApplicationError(this.feature);

  final String feature;

  @override
  String toString() => 'LoggedApplicationError($feature)';
}
