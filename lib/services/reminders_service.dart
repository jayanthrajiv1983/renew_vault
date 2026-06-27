import '../constants/reminder_intervals.dart';
import '../models/renewal_item.dart';
import 'settings_service.dart';
import 'storage_service.dart';
import '../widgets/renewal_card.dart';

/// A scheduled renewal reminder that has not yet fired.
class UpcomingReminder {
  const UpcomingReminder({
    required this.item,
    required this.reminderDays,
    required this.reminderDate,
  });

  final RenewalItem item;
  final int reminderDays;
  final DateTime reminderDate;

  String get intervalLabel => ReminderIntervals.labelFor(reminderDays);
}

/// Computes upcoming renewal reminders for list screens.
class RemindersService {
  RemindersService._();

  static final RemindersService instance = RemindersService._();

  List<UpcomingReminder> getUpcomingReminders() {
    if (!SettingsService.instance.getEnableNotifications()) {
      return [];
    }

    final today = dateOnly(DateTime.now());
    final reminders = <UpcomingReminder>[];

    for (final item in StorageService.instance.getAll()) {
      final renewalDay = dateOnly(item.renewalDate);

      for (final reminderDays in item.reminderDays) {
        final reminderDate = renewalDay.subtract(Duration(days: reminderDays));
        if (reminderDate.isBefore(today)) {
          continue;
        }

        reminders.add(
          UpcomingReminder(
            item: item,
            reminderDays: reminderDays,
            reminderDate: reminderDate,
          ),
        );
      }
    }

    reminders.sort((a, b) {
      final byDate = a.reminderDate.compareTo(b.reminderDate);
      if (byDate != 0) {
        return byDate;
      }
      return a.item.title.compareTo(b.item.title);
    });

    return reminders;
  }

  List<RenewalItem> getRenewalsWithUpcomingReminders() {
    final itemsById = <String, RenewalItem>{};
    for (final reminder in getUpcomingReminders()) {
      itemsById[reminder.item.id] = reminder.item;
    }

    final items = itemsById.values.toList()
      ..sort((a, b) => a.renewalDate.compareTo(b.renewalDate));
    return items;
  }
}
