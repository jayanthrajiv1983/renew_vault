import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../core/services/logging_service.dart';
import '../core/services/crashlytics_service.dart';
import '../models/renewal_item.dart';
import 'notification_navigation_service.dart';
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

    try {
      tz.initializeTimeZones();
      _configureLocalTimeZone();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      final launchResponse = launchDetails?.notificationResponse;
      if (launchDetails?.didNotificationLaunchApp == true &&
          launchResponse != null) {
        _onNotificationResponse(launchResponse);
      }

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

      _initialized = true;
    } catch (error, stack) {
      LoggingService.instance.logError(
        CrashlyticsService.featureNotifications,
        'Notification initialization failed',
        exception: error,
        stackTrace: stack,
        operation: 'Initialization Failed',
      );
      rethrow;
    }
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
  static const _betaTestNotificationId = 2147483646;

  /// Schedules a beta-tester notification 10 seconds from now.
  Future<void> scheduleTestNotification() async {
    final scheduled = tz.TZDateTime.now(tz.local).add(
      const Duration(seconds: 10),
    );

    await scheduleNotification(
      id: _betaTestNotificationId,
      title: 'Renew Vault Test Notification',
      body: 'Notifications are working correctly.',
      scheduledDate: scheduled,
    );
  }

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

  void _onNotificationResponse(NotificationResponse response) {
    NotificationNavigationService.instance.handlePayload(response.payload);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? payload,
  }) async {
    try {
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
        payload: payload,
      );
      LoggingService.instance.logInfo(
        'NOTIFICATIONS',
        'Notification scheduled (id hash: $id)',
      );
    } catch (error, stack) {
      LoggingService.instance.logError(
        CrashlyticsService.featureNotifications,
        'Notification scheduling failed',
        exception: error,
        stackTrace: stack,
        operation: 'Scheduling Failed',
      );
      rethrow;
    }
  }

  Future<void> scheduleRecurringNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required DateTimeComponents matchComponents,
    String? payload,
  }) async {
    try {
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
        matchDateTimeComponents: matchComponents,
        payload: payload,
      );
      LoggingService.instance.logInfo(
        'NOTIFICATIONS',
        'Recurring notification scheduled (id hash: $id)',
      );
    } catch (error, stack) {
      LoggingService.instance.logError(
        CrashlyticsService.featureNotifications,
        'Recurring notification scheduling failed',
        exception: error,
        stackTrace: stack,
        operation: 'Scheduling Failed',
      );
      rethrow;
    }
  }

  Future<void> requestSystemPermissions() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
    LoggingService.instance.logInfo(
      'PERMISSIONS',
      'Notification system permissions requested',
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
