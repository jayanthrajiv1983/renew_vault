/// Reminder interval options shared across settings, forms, and detail views.
abstract final class ReminderIntervals {
  static const orderedDays = [90, 60, 30, 15, 7, 3, 1, 0];

  static const labels = <int, String>{
    90: '90 Days Before',
    60: '60 Days Before',
    30: '30 Days Before',
    15: '15 Days Before',
    7: '7 Days Before',
    3: '3 Days Before',
    1: '1 Day Before',
    0: 'On Due Date',
  };

  static String labelFor(int days) =>
      labels[days] ?? '$days Days Before';

  static String chipLabelFor(int days) {
    if (days == 0) {
      return 'On Due Date';
    }
    if (days == 1) {
      return '1 Day';
    }
    return '$days Days';
  }

  static List<int> sortDescending(Set<int> days) {
    return days.toList()..sort((a, b) => b.compareTo(a));
  }
}
