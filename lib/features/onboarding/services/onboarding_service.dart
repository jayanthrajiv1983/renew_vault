import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/logging_service.dart';
import '../../../services/app_info_service.dart';

/// Persists first-launch onboarding completion via [SharedPreferences].
class OnboardingService {
  OnboardingService._();

  static final OnboardingService instance = OnboardingService._();

  static const onboardingCompletedKey = 'onboarding_completed';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  bool get isCompleted => _prefs?.getBool(onboardingCompletedKey) ?? false;

  Future<void> markCompleted() async {
    await _prefs?.setBool(onboardingCompletedKey, true);
    final appInfo = AppInfoService.instance;
    final version = appInfo.versionSync ?? 'Unknown';
    final buildNumber = appInfo.buildNumberSync ?? 'Unknown';
    LoggingService.instance.logInfo(
      'ONBOARDING',
      'Onboarding completed — '
          '${AppInfoService.formatVersionString(version: version, buildNumber: buildNumber)}',
    );
  }
}
