import 'package:flutter/material.dart';

import '../services/insights_service.dart';
import '../theme/app_spacing.dart';

class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.insight,
  });

  final InsightItem insight;

  Color _accentColor(ColorScheme colorScheme) {
    switch (insight.priority) {
      case InsightPriority.high:
        return colorScheme.error;
      case InsightPriority.medium:
        return colorScheme.primary;
      case InsightPriority.low:
        return colorScheme.tertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = _accentColor(colorScheme);

    return Card(
      color: accent.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.cardBorderRadius,
        side: BorderSide(
          color: accent.withValues(alpha: 0.24),
        ),
      ),
      child: Padding(
        padding: AppSpacing.cardInsets,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppSpacing.chipRadius + 4),
              ),
              child: Icon(
                insight.icon,
                color: accent,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                insight.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
