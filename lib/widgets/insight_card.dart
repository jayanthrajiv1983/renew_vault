import 'package:flutter/material.dart';

import '../services/insights_service.dart';
import '../theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/design_system.dart';
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
  static const double _iconSlotSize = 44;

  Color _accentColor(ColorScheme colorScheme) {
    switch (insight.priority) {
      case InsightPriority.high:
        return colorScheme.expiringColor;
      case InsightPriority.medium:
        return colorScheme.infoColor;
      case InsightPriority.low:
        return colorScheme.neutralColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyles = AppTextStyles.of(context);
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
            SizedBox(
              width: _iconSlotSize,
              height: _iconSlotSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primaryContainer.withValues(
                    alpha: isDark ? 0.4 : 0.55,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: accent.withValues(alpha: 0.85),
                    size: AppDesignTokens.iconMedium,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDesignTokens.space12),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  insight.message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
