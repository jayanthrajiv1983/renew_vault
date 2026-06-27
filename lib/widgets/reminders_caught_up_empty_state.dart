import 'package:flutter/material.dart';

import '../shared/widgets/empty_state_widget.dart';

/// Empty state shown when there are no upcoming scheduled reminders.
class RemindersCaughtUpEmptyState extends StatelessWidget {
  const RemindersCaughtUpEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: EmptyStateWidget.mutedIcon(context, Icons.check_circle_outline),
      title: "You're all caught up",
      subtitle: 'No reminders are due right now.',
      semanticLabel:
          "You're all caught up. No reminders are due right now.",
    );
  }
}
