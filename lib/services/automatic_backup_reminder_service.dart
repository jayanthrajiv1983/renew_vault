import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/services/logging_service.dart';
import '../models/backup_frequency.dart';
import 'notification_navigation_service.dart';
import 'notification_service.dart';
import 'settings_service.dart';

class AutomaticBackupReminderService {
  AutomaticBackupReminderService._();

  static final AutomaticBackupReminderService instance =
      AutomaticBackupReminderService._();

  static const notificationId = 2147483645;
  static const weeklyBody = 'Time to back up Renew Vault.';
  static const monthlyBody =
      'Protect your data by creating a fresh backup.';
  static const notificationTitle = 'Renew Vault';

  Future<void> reschedule() async {
    await NotificationService.instance.cancelNotification(notificationId);

    if (!SettingsService.instance.getEnableNotifications()) {
      return;
    }

    final frequency = SettingsService.instance.getBackupFrequency();
    if (frequency == BackupFrequency.disabled) {
      return;
    }

    final scheduledDate = _nextScheduledDate(frequency);
    final body = frequency == BackupFrequency.weekly ? weeklyBody : monthlyBody;
    final matchComponents = frequency == BackupFrequency.weekly
        ? DateTimeComponents.dayOfWeekAndTime
        : DateTimeComponents.dayOfMonthAndTime;

    await NotificationService.instance.scheduleRecurringNotification(
      id: notificationId,
      title: notificationTitle,
      body: body,
      scheduledDate: scheduledDate,
      matchComponents: matchComponents,
      payload: NotificationNavigationService.backupScreenPayload,
    );

    LoggingService.instance.logInfo(
      'BACKUP',
      'Automatic backup reminder scheduled',
    );
  }

  tz.TZDateTime _nextScheduledDate(BackupFrequency frequency) {
    final now = tz.TZDateTime.now(tz.local);

    if (frequency == BackupFrequency.weekly) {
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        9,
      );
      if (!scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 7));
      }
      return scheduled;
    }

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9,
    );
    if (!scheduled.isAfter(now)) {
      var month = now.month + 1;
      var year = now.year;
      if (month > 12) {
        month = 1;
        year++;
      }
      final day = now.day.clamp(1, _daysInMonth(year, month));
      scheduled = tz.TZDateTime(tz.local, year, month, day, 9);
    }
    return scheduled;
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}
