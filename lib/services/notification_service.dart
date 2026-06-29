import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../core/services/logging_service.dart';
import '../models/renewal_item.dart';
import 'settings_service.dart';
import 'storage_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  factory NotificationService() => instance;

  static const _channelId = 'renewvault_channel';
  static const _channelName = 'Renew Vault Notifications';
  static const _notificationTitle = 'Renew Vault Reminder';
  static const _allReminderDays = [90, 60, 30, 15, 7, 3, 1, 0];

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz.initializeTimeZones();
    _configureLocalTimeZone();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Renewal reminder notifications',
      importance: Importance.defaultImportance,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    _initialized = true;
  }

  void _configureLocalTimeZone() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    tz.Location? match;

    for (final location in tz.timeZoneDatabase.locations.values) {
      if (tz.TZDateTime.from(now, location).timeZoneOffset == offset) {
        match = location;
        break;
      }
    }

    tz.setLocalLocation(match ?? tz.UTC);
  }

  static const _testNotificationId = 2147483647;

  Future<void> showInstantNotification({
    String title = 'Renew Vault',
    String body = 'Test notification',
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(_testNotificationId, title, body, details);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    LoggingService.instance.logInfo(
      'NOTIFICATIONS',
      'Notification scheduled (id hash: $id)',
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
    LoggingService.instance.logInfo(
      'NOTIFICATIONS',
      'Notification cancelled (id hash: $id)',
    );
  }

  int notificationIdFor(String itemId, int reminderDays) {
    return Object.hash(itemId, reminderDays) & 0x7FFFFFFF;
  }

  static String _formatNotificationBody(String title, int daysRemaining) {
    if (daysRemaining == 0) {
      return '$title expires today.';
    }
    if (daysRemaining == 1) {
      return '$title expires tomorrow.';
    }
    return '$title expires in $daysRemaining days.';
  }

  Future<void> cancelRenewalReminders(RenewalItem item) async {
    final idsToCancel = <int>{...item.notificationIds.values};
    for (final days in _allReminderDays) {
      idsToCancel.add(notificationIdFor(item.id, days));
    }

    for (final id in idsToCancel) {
      await cancelNotification(id);
    }
  }

  Future<RenewalItem> scheduleRenewalReminders(RenewalItem item) async {
    await cancelRenewalReminders(item);

    if (!SettingsService.instance.getEnableNotifications()) {
      return item.copyWith(notificationIds: const {});
    }

    final renewalDay = DateTime(
      item.renewalDate.year,
      item.renewalDate.month,
      item.renewalDate.day,
    );
    final now = tz.TZDateTime.now(tz.local);
    final notificationIds = <String, int>{};

    for (final reminderDays in item.reminderDays) {
      final reminderDay = renewalDay.subtract(Duration(days: reminderDays));
      final scheduledTz = tz.TZDateTime(
        tz.local,
        reminderDay.year,
        reminderDay.month,
        reminderDay.day,
        9,
      );

      if (scheduledTz.isBefore(now)) {
        continue;
      }

      final id = notificationIdFor(item.id, reminderDays);
      await scheduleNotification(
        id: id,
        title: _notificationTitle,
        body: _formatNotificationBody(item.title, reminderDays),
        scheduledDate: scheduledTz,
      );
      notificationIds[reminderDays.toString()] = id;
    }

    return item.copyWith(notificationIds: notificationIds);
  }

  Future<void> rescheduleAllReminders() async {
    for (final item in StorageService.instance.getAll()) {
      final updated = await scheduleRenewalReminders(item);
      await StorageService.instance.saveToBox(updated);
    }
  }
}
