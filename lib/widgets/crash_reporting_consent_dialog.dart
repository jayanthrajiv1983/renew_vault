import 'package:flutter/material.dart';

import '../core/services/crashlytics_service.dart';
import '../core/services/logging_service.dart';
import '../services/settings_service.dart';
import '../utils/form_padding.dart';

/// Shows the one-time crash reporting consent prompt after upgrade or first launch.
///
/// Returns `true` if the user allowed reporting, `false` if they declined or
/// dismissed the dialog.
Future<bool?> showCrashReportingConsentDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => AlertDialog(
      insetPadding: dialogInsetPadding(context),
      titlePadding: alertDialogTitlePadding,
      contentPadding: alertDialogContentPadding,
      actionsPadding: alertDialogActionsPadding,
      title: const Text('Help Improve Renew Vault'),
      content: const Text(
        'Allow anonymous crash reports to help improve app stability?\n\n'
        'No personal documents or sensitive information are ever shared.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Not Now'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Allow'),
        ),
      ],
    ),
  );
}

/// Presents the consent dialog when needed and persists the user's choice.
Future<void> maybeShowCrashReportingConsentPrompt(BuildContext context) async {
  if (!SettingsService.instance.shouldShowCrashReportingConsentPrompt()) {
    return;
  }

  final allowed = await showCrashReportingConsentDialog(context);
  if (!context.mounted) {
    return;
  }

  final enabled = allowed == true;
  await applyCrashReportingConsent(enabled);
}

/// Persists consent, updates Crashlytics collection, and logs the outcome.
Future<void> applyCrashReportingConsent(bool enabled) async {
  await SettingsService.instance.setCrashReportingEnabled(enabled);
  await SettingsService.instance.setCrashReportingConsentPromptShown(true);
  await CrashlyticsService.instance.updateConsent(enabled);
  LoggingService.instance.logInfo(
    'APP',
    'Crash reporting consent: ${enabled ? 'granted' : 'denied'}',
  );
}
