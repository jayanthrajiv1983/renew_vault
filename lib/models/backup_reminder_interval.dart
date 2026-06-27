enum BackupReminderInterval {
  off,
  monthly,
  every3Months,
  every6Months;

  String get label {
    switch (this) {
      case BackupReminderInterval.off:
        return 'Off';
      case BackupReminderInterval.monthly:
        return 'Monthly';
      case BackupReminderInterval.every3Months:
        return 'Every 3 Months';
      case BackupReminderInterval.every6Months:
        return 'Every 6 Months';
    }
  }

  int get intervalDays {
    switch (this) {
      case BackupReminderInterval.off:
        return 0;
      case BackupReminderInterval.monthly:
        return 30;
      case BackupReminderInterval.every3Months:
        return 90;
      case BackupReminderInterval.every6Months:
        return 180;
    }
  }

  static BackupReminderInterval fromName(String? value) {
    for (final interval in BackupReminderInterval.values) {
      if (interval.name == value) {
        return interval;
      }
    }
    return BackupReminderInterval.monthly;
  }
}
