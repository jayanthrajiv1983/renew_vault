import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/logging_service.dart';

/// Tracks launch eligibility and persists review prompt state via [SharedPreferences].
class AppReviewService {
  AppReviewService._();

  static final AppReviewService instance = AppReviewService._();

  static const launchCountKey = 'app_review_launch_count';
  static const firstLaunchMsKey = 'app_review_first_launch_ms';
  static const permanentlyDismissedKey = 'app_review_permanently_dismissed';
  static const laterDismissedMsKey = 'app_review_later_dismissed_ms';

  static const minLaunches = 10;
  static const minDaysSinceInstall = 30;
  static const laterCooldownDays = 7;

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  int get launchCount => _prefs?.getInt(launchCountKey) ?? 0;

  bool get isPermanentlyDismissed =>
      _prefs?.getBool(permanentlyDismissedKey) ?? false;

  DateTime? get firstLaunchDate {
    final ms = _prefs?.getInt(firstLaunchMsKey);
    if (ms == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  DateTime? get laterDismissedDate {
    final ms = _prefs?.getInt(laterDismissedMsKey);
    if (ms == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  int get daysSinceFirstLaunch {
    final first = firstLaunchDate;
    if (first == null) {
      return 0;
    }
    return DateTime.now().difference(first).inDays;
  }

  bool get meetsLaunchThreshold => launchCount >= minLaunches;

  bool get meetsDaysThreshold => daysSinceFirstLaunch >= minDaysSinceInstall;

  bool get isLaterCooldownActive {
    final dismissed = laterDismissedDate;
    if (dismissed == null) {
      return false;
    }
    return DateTime.now().difference(dismissed).inDays < laterCooldownDays;
  }

  bool get shouldShowPrompt {
    if (isPermanentlyDismissed) {
      return false;
    }
    if (isLaterCooldownActive) {
      return false;
    }
    return meetsLaunchThreshold || meetsDaysThreshold;
  }

  /// Records a home-screen session after splash/onboarding (increments launch count).
  Future<void> recordHomeLaunch() async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }

    final now = DateTime.now();
    if (!prefs.containsKey(firstLaunchMsKey)) {
      await prefs.setInt(firstLaunchMsKey, now.millisecondsSinceEpoch);
    }

    final nextCount = launchCount + 1;
    await prefs.setInt(launchCountKey, nextCount);
    LoggingService.instance.logInfo(
      'APP_REVIEW',
      'Home launch recorded (count: $nextCount, days: $daysSinceFirstLaunch)',
    );
  }

  Future<void> markLater() async {
    await _prefs?.setInt(
      laterDismissedMsKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    LoggingService.instance.logInfo('APP_REVIEW', 'Prompt dismissed (later)');
  }

  Future<void> markPermanentlyDismissed() async {
    await _prefs?.setBool(permanentlyDismissedKey, true);
    LoggingService.instance.logInfo('APP_REVIEW', 'Prompt dismissed (permanent)');
  }

  Future<void> requestReview() async {
    final inAppReview = InAppReview.instance;
    try {
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        LoggingService.instance.logInfo('APP_REVIEW', 'In-app review requested');
        return;
      }
      await inAppReview.openStoreListing();
      LoggingService.instance.logInfo(
        'APP_REVIEW',
        'In-app review unavailable; opened store listing',
      );
    } catch (e, st) {
      LoggingService.instance.logError(
        'APP_REVIEW',
        'Failed to request review: $e',
        exception: e,
        stackTrace: st,
        operation: 'requestReview',
      );
    }
  }
}
