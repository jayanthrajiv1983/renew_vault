import 'package:flutter/material.dart';

import '../services/insights_service.dart';
import '../theme/app_spacing.dart';

class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.insight,
  });

  final InsightItem insight;

  static const double _radius = 20;
  static const double _elevation = 2;
  static const EdgeInsets _padding = AppSpacing.cardInsets;

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
    final isDark = theme.brightness == Brightness.dark;
    final accent = _accentColor(colorScheme);

    final backgroundColor = isDark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.primaryContainer.withValues(alpha: 0.25);

    return Material(
      elevation: _elevation,
      shadowColor: colorScheme.shadow.withValues(alpha: isDark ? 0.28 : 0.1),
      surfaceTintColor: colorScheme.surfaceTint.withValues(alpha: 0.04),
      color: backgroundColor,
      borderRadius: BorderRadius.circular(_radius),
      child: Padding(
        padding: _padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: colorScheme.primaryContainer.withValues(
                alpha: isDark ? 0.4 : 0.55,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: accent,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sectionSpacing),
            Expanded(
              child: Text(
                insight.message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
