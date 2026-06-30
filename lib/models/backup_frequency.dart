enum BackupFrequency {
  disabled,
  weekly,
  monthly;

  String get label {
    switch (this) {
      case BackupFrequency.disabled:
        return 'Disabled';
      case BackupFrequency.weekly:
        return 'Weekly';
      case BackupFrequency.monthly:
        return 'Monthly';
    }
  }

  static BackupFrequency fromName(String? value) {
    for (final frequency in BackupFrequency.values) {
      if (frequency.name == value) {
        return frequency;
      }
    }
    return BackupFrequency.monthly;
  }
}
