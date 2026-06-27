import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_brand.dart';

enum FeedbackType {
  feedback(subject: 'Renew Vault Feedback'),
  bugReport(subject: 'Renew Vault Bug Report'),
  featureRequest(subject: 'Renew Vault Feature Request'),
  support(subject: 'Renew Vault Support');

  const FeedbackType({required this.subject});

  final String subject;
}

class FeedbackService {
  FeedbackService._();

  static final FeedbackService instance = FeedbackService._();

  static const supportEmail = 'jayanthrajiv@gmail.com';

  Future<String> buildEmailBody({required bool darkModeEnabled}) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = await _getDeviceInfo();

    return '''
App Version: ${AppBrand.version}
Build Number: ${packageInfo.buildNumber}
Device Platform: ${deviceInfo.platform}
OS Version: ${deviceInfo.osVersion}
Dark Mode Enabled: ${darkModeEnabled ? 'Yes' : 'No'}
Timestamp: ${DateTime.now().toIso8601String()}


''';
  }

  Uri buildMailtoUri({required String subject, required String body}) {
    return Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );
  }

  Future<bool> launchFeedback({
    required BuildContext context,
    required FeedbackType type,
  }) async {
    final darkModeEnabled = Theme.of(context).brightness == Brightness.dark;
    final body = await buildEmailBody(darkModeEnabled: darkModeEnabled);
    final emailUri = buildMailtoUri(subject: type.subject, body: body);

    debugPrint('Launching email URI: $emailUri');

    try {
      final launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        debugPrint('launchUrl returned false for email URI: $emailUri');
        await _handleEmailLaunchFailure(context);
        return false;
      }
      return true;
    } catch (e, stackTrace) {
      debugPrint('Failed to launch email URI: $emailUri');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      await _handleEmailLaunchFailure(context);
      return false;
    }
  }

  Future<void> _handleEmailLaunchFailure(BuildContext context) async {
    if (!context.mounted) {
      return;
    }

    await Clipboard.setData(const ClipboardData(text: supportEmail));

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No email application is installed on this device.\n'
          'Email address copied to clipboard',
        ),
      ),
    );
  }

  Future<({String platform, String osVersion})> _getDeviceInfo() async {
    final plugin = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      return (
        platform: 'Android',
        osVersion: '${info.version.release} (SDK ${info.version.sdkInt})',
      );
    }
    if (Platform.isIOS) {
      final info = await plugin.iosInfo;
      return (platform: 'iOS', osVersion: info.systemVersion);
    }
    if (Platform.isWindows) {
      final info = await plugin.windowsInfo;
      return (
        platform: 'Windows',
        osVersion:
            '${info.majorVersion}.${info.minorVersion}.${info.buildNumber}',
      );
    }
    if (Platform.isMacOS) {
      final info = await plugin.macOsInfo;
      return (
        platform: 'macOS',
        osVersion:
            '${info.majorVersion}.${info.minorVersion}.${info.patchVersion}',
      );
    }
    if (Platform.isLinux) {
      final info = await plugin.linuxInfo;
      return (platform: 'Linux', osVersion: info.prettyName);
    }

    return (
      platform: Platform.operatingSystem,
      osVersion: Platform.operatingSystemVersion,
    );
  }
}
