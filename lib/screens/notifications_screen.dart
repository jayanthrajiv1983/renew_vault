import 'package:flutter/material.dart';

import '../constants/reminder_intervals.dart';
import '../services/pending_delete_controller.dart';
import '../services/reminders_service.dart';
import '../theme/app_spacing.dart';
import '../utils/form_padding.dart';
import '../widgets/reminders_caught_up_empty_state.dart';
import 'item_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _reminders = RemindersService.instance;
  List<UpcomingReminder> _upcomingReminders = [];

  @override
  void initState() {
    super.initState();
    PendingDeleteController.instance.addListener(_loadReminders);
    _loadReminders();
  }

  @override
  void dispose() {
    PendingDeleteController.instance.removeListener(_loadReminders);
    super.dispose();
  }

  void _loadReminders() {
    setState(() {
      _upcomingReminders = _reminders.getUpcomingReminders();
    });
  }

  Future<void> _openItemDetail(UpcomingReminder reminder) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ItemDetailScreen(item: reminder.item),
      ),
    );
    _loadReminders();
  }

  String _formatReminderDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: SafeArea(
        child: _upcomingReminders.isEmpty
            ? const RemindersCaughtUpEmptyState()
            : ListView.builder(
                padding: listScrollPadding(
                  context,
                  top: AppSpacing.fieldLabelGap,
                ),
                itemCount: _upcomingReminders.length,
                itemBuilder: (context, index) {
                  final reminder = _upcomingReminders[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.cardSpacing),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.notifications_none,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(reminder.item.title),
                      subtitle: Text(
                        '${ReminderIntervals.labelFor(reminder.reminderDays)}\n'
                        'Reminder on ${_formatReminderDate(reminder.reminderDate)}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openItemDetail(reminder),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
