import 'package:flutter/material.dart';

import '../constants/reminder_intervals.dart';
import '../theme/app_spacing.dart';
import '../utils/form_padding.dart';

class ReminderIntervalPicker extends StatelessWidget {
  const ReminderIntervalPicker({
    super.key,
    required this.selectedDays,
    required this.onChanged,
    this.title,
    this.subtitle,
    this.contentPadding,
  });

  final Set<int> selectedDays;
  final ValueChanged<List<int>> onChanged;
  final String? title;
  final String? subtitle;
  final EdgeInsetsGeometry? contentPadding;

  List<int> get _sortedSelected => ReminderIntervals.sortDescending(selectedDays);

  List<int> get _availableDays =>
      ReminderIntervals.orderedDays.where((d) => !selectedDays.contains(d)).toList();

  void _removeDay(int days) {
    final updated = Set<int>.from(selectedDays)..remove(days);
    onChanged(ReminderIntervals.sortDescending(updated));
  }

  void _addDay(int days) {
    if (selectedDays.contains(days)) {
      return;
    }
    final updated = Set<int>.from(selectedDays)..add(days);
    onChanged(ReminderIntervals.sortDescending(updated));
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final available = _availableDays;

        return SafeArea(
          child: SingleChildScrollView(
            padding: bottomSheetPadding(sheetContext),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add Reminder',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.fieldLabelGap),
                Text(
                  'Choose when to be reminded before the due date.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionSpacing),
                if (available.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sectionSpacing,
                    ),
                    child: Text(
                      'All reminder intervals are already selected.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...available.map(
                    (days) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(ReminderIntervals.labelFor(days)),
                      trailing: Icon(
                        Icons.add_circle_outline,
                        color: theme.colorScheme.primary,
                      ),
                      onTap: () {
                        _addDay(days);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = contentPadding ?? EdgeInsets.zero;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: theme.textTheme.titleSmall,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.fieldLabelGap),
          ],
          if (_sortedSelected.isNotEmpty)
            Wrap(
              spacing: AppSpacing.fieldLabelGap,
              runSpacing: AppSpacing.fieldLabelGap,
              children: _sortedSelected.map(
                (days) => InputChip(
                  label: Text(ReminderIntervals.chipLabelFor(days)),
                  onDeleted: () => _removeDay(days),
                  deleteIconColor: theme.colorScheme.onSurfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                  ),
                ),
              ).toList(),
            ),
          if (_sortedSelected.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.fieldLabelGap),
              child: Text(
                'No reminders selected',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              avatar: Icon(
                Icons.add,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              label: const Text('Add Reminder'),
              onPressed: _availableDays.isEmpty
                  ? null
                  : () => _openAddSheet(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
