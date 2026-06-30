import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:hive/hive.dart';

import 'app_lock_controller.dart';
import 'hive_encryption_service.dart';
import '../core/services/logging_service.dart';



import '../models/backup_frequency.dart';
import '../models/backup_reminder_interval.dart';

import '../models/renewal_item.dart';

import '../models/sort_option.dart';

import '../providers/theme_provider.dart';



class SettingsService extends ChangeNotifier {

  SettingsService._();



  static final SettingsService instance = SettingsService._();



  static const _boxName = 'settings';



  static const sortOptionKey = 'sortOption';

  static const defaultReminderDaysKey = 'defaultReminderDays';

  static const enableNotificationsKey = 'enableNotifications';

  static const showExpiredBannerKey = 'showExpiredBanner';

  static const autoSortByNearestExpiryKey = 'autoSortByNearestExpiry';

  static const enableAppLockKey = 'enableAppLock';

  static const hideAppContentsInRecentsKey = 'hideAppContentsInRecents';

  static const backupReminderIntervalKey = 'backupReminderInterval';

  static const automaticBackupFrequencyKey = 'automaticBackupFrequency';

  static const lastBackupAtKey = 'lastBackupAt';

  static const lastCloudBackupAtKey = 'lastCloudBackupAt';

  static const backupReminderDismissedAtKey = 'backupReminderDismissedAt';

  static const categoryMigrationV1CompleteKey = 'categoryMigrationV1Complete';

  static const completedMilestonesKey = 'completedMilestones';

  static const milestonesBootstrappedKey = 'milestonesBootstrapped';

  static const crashReportingEnabledKey = 'crashReportingEnabled';

  static const crashReportingConsentPromptShownKey =
      'crashReportingConsentPromptShown';



  Box? _box;



  Future<void> init() async {

    _box = await HiveEncryptionService.instance.openBox(_boxName);

  }



  Map<String, dynamic> getAll() {

    final box = _box;

    if (box == null || box.isEmpty) {

      return {};

    }



    return Map<String, dynamic>.from(box.toMap());

  }



  AppThemeMode getThemeMode() => ThemeProvider.instance.appThemeMode;



  Future<void> setThemeMode(AppThemeMode mode) =>

      ThemeProvider.instance.setThemeMode(mode);



  List<int> getDefaultReminderDays() {

    final value = _box?.get(defaultReminderDaysKey);

    if (value is List) {

      return value.whereType<int>().toList();

    }

    return List<int>.from(RenewalItem.defaultReminderDays);

  }



  Future<void> setDefaultReminderDays(List<int> days) async {

    await _box?.put(defaultReminderDaysKey, days);

    notifyListeners();

  }



  bool getEnableNotifications() {

    final value = _box?.get(enableNotificationsKey);

    if (value is bool) {

      return value;

    }

    return true;

  }



  Future<void> setEnableNotifications(bool enabled) async {

    await _box?.put(enableNotificationsKey, enabled);

    notifyListeners();

  }



  bool getShowExpiredBanner() {

    final value = _box?.get(showExpiredBannerKey);

    if (value is bool) {

      return value;

    }

    return true;

  }



  Future<void> setShowExpiredBanner(bool show) async {

    await _box?.put(showExpiredBannerKey, show);

    notifyListeners();

  }



  bool getAutoSortByNearestExpiry() {

    final value = _box?.get(autoSortByNearestExpiryKey);

    if (value is bool) {

      return value;

    }

    return false;

  }



  Future<void> setAutoSortByNearestExpiry(bool enabled) async {

    await _box?.put(autoSortByNearestExpiryKey, enabled);

    notifyListeners();

  }



  bool getAppLockEnabled() {

    final value = _box?.get(enableAppLockKey);

    final enabled = value is bool ? value : true;

    debugPrint('App Lock Enabled: $enabled (read)');

    return enabled;

  }



  Future<void> setAppLockEnabled(bool enabled) async {

    await _box?.put(enableAppLockKey, enabled);

    debugPrint('App Lock Enabled: $enabled (write)');
    LoggingService.instance.logInfo(
      'SETTINGS',
      'App lock changed: ${enabled ? 'Enabled' : 'Disabled'}',
    );

    AppLockController.instance.onAppLockPreferenceChanged(enabled);

    notifyListeners();

  }



  bool getHideAppContentsInRecents() {

    final value = _box?.get(hideAppContentsInRecentsKey);

    if (value is bool) {

      return value;

    }

    return true;

  }



  Future<void> setHideAppContentsInRecents(bool enabled) async {

    await _box?.put(hideAppContentsInRecentsKey, enabled);

    notifyListeners();

  }



  SortOption? getSortOption() {

    final value = _box?.get(sortOptionKey);

    if (value is! String) {

      return null;

    }



    for (final option in SortOption.values) {

      if (option.name == value) {

        return option;

      }

    }

    return null;

  }



  Future<void> setSortOption(SortOption? option) async {

    if (option == null) {

      await _box?.delete(sortOptionKey);

    } else {

      await _box?.put(sortOptionKey, option.name);

    }

    notifyListeners();

  }



  SortOption? getEffectiveSortOption() {

    final saved = getSortOption();

    if (saved != null) {

      return saved;

    }

    if (getAutoSortByNearestExpiry()) {

      return SortOption.nearestExpiry;

    }

    return null;

  }



  BackupReminderInterval getBackupReminderInterval() {
    final value = _box?.get(backupReminderIntervalKey);
    if (value is String) {
      return BackupReminderInterval.fromName(value);
    }
    return BackupReminderInterval.monthly;
  }

  Future<void> setBackupReminderInterval(BackupReminderInterval interval) async {
    await _box?.put(backupReminderIntervalKey, interval.name);
    notifyListeners();
  }

  BackupFrequency getBackupFrequency() {
    final value = _box?.get(automaticBackupFrequencyKey);
    if (value is String) {
      return BackupFrequency.fromName(value);
    }
    return BackupFrequency.monthly;
  }

  Future<void> setBackupFrequency(BackupFrequency frequency) async {
    await _box?.put(automaticBackupFrequencyKey, frequency.name);
    notifyListeners();
  }

  DateTime? getLastBackupAt() {
    final value = _box?.get(lastBackupAtKey);
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }

  Future<void> setLastBackupAt(DateTime time) async {
    await _box?.put(lastBackupAtKey, time.toUtc().toIso8601String());
    notifyListeners();
  }

  DateTime? getLastCloudBackupAt() {
    final value = _box?.get(lastCloudBackupAtKey);
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }

  Future<void> setLastCloudBackupAt(DateTime time) async {
    await _box?.put(lastCloudBackupAtKey, time.toUtc().toIso8601String());
    notifyListeners();
  }

  DateTime? getBackupReminderDismissedAt() {
    final value = _box?.get(backupReminderDismissedAtKey);
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }

  Future<void> setBackupReminderDismissedAt(DateTime time) async {
    await _box?.put(backupReminderDismissedAtKey, time.toUtc().toIso8601String());
    notifyListeners();
  }

  Future<void> clearBackupReminderDismissedAt() async {
    await _box?.delete(backupReminderDismissedAtKey);
    notifyListeners();
  }

  Future<void> recordSuccessfulBackup() async {
    await setLastBackupAt(DateTime.now());
    await clearBackupReminderDismissedAt();
  }

  int? getDaysSinceLastBackup() {
    final lastBackup = getLastBackupAt();
    if (lastBackup == null) {
      return null;
    }
    return DateTime.now().difference(lastBackup).inDays;
  }

  bool shouldShowBackupReminder() {
    final interval = getBackupReminderInterval();
    if (interval == BackupReminderInterval.off) {
      return false;
    }

    final dismissedAt = getBackupReminderDismissedAt();
    if (dismissedAt != null && _isSameCalendarDay(dismissedAt, DateTime.now())) {
      return false;
    }

    final lastBackup = getLastBackupAt();
    if (lastBackup == null) {
      return true;
    }

    final daysSince = DateTime.now().difference(lastBackup).inDays;
    return daysSince >= interval.intervalDays;
  }

  String getBackupReminderMessage() {
    final daysSince = getDaysSinceLastBackup();
    if (daysSince == null) {
      return 'Your data has not been backed up yet.';
    }
    return 'Your data has not been backed up for $daysSince days.';
  }

  bool _isSameCalendarDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool isCategoryMigrationV1Complete() {
    final value = _box?.get(categoryMigrationV1CompleteKey);
    return value == true;
  }

  Future<void> setCategoryMigrationV1Complete(bool complete) async {
    await _box?.put(categoryMigrationV1CompleteKey, complete);
    notifyListeners();
  }

  Set<int> getCompletedMilestones() {
    final value = _box?.get(completedMilestonesKey);
    if (value is List) {
      return value.whereType<int>().toSet();
    }
    return {};
  }

  Future<void> setCompletedMilestones(Set<int> milestones) async {
    final sorted = milestones.toList()..sort();
    await _box?.put(completedMilestonesKey, sorted);
    notifyListeners();
  }

  Future<void> markMilestoneCompleted(int threshold) async {
    final completed = getCompletedMilestones()..add(threshold);
    await setCompletedMilestones(completed);
  }

  bool isMilestoneCompleted(int threshold) {
    return getCompletedMilestones().contains(threshold);
  }

  bool getMilestonesBootstrapped() {
    return _box?.get(milestonesBootstrappedKey) == true;
  }

  Future<void> setMilestonesBootstrapped(bool bootstrapped) async {
    await _box?.put(milestonesBootstrappedKey, bootstrapped);
    notifyListeners();
  }

  bool getCrashReportingEnabled() {
    final value = _box?.get(crashReportingEnabledKey);
    if (value is bool) {
      return value;
    }
    return false;
  }

  Future<void> setCrashReportingEnabled(bool enabled) async {
    await _box?.put(crashReportingEnabledKey, enabled);
    notifyListeners();
  }

  bool getCrashReportingConsentPromptShown() {
    return _box?.get(crashReportingConsentPromptShownKey) == true;
  }

  Future<void> setCrashReportingConsentPromptShown(bool shown) async {
    await _box?.put(crashReportingConsentPromptShownKey, shown);
    notifyListeners();
  }

  bool shouldShowCrashReportingConsentPrompt() {
    return !getCrashReportingConsentPromptShown();
  }

  Future<void> applySettings(Map<String, dynamic> settings) async {

    await _box?.clear();

    for (final entry in settings.entries) {

      await _box?.put(entry.key, entry.value);

    }

    ThemeProvider.instance.reload();

    notifyListeners();

  }

}


