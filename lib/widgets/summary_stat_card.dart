import 'package:flutter/material.dart';

import '../core/theme/app_text_styles.dart';
import '../core/theme/design_system.dart';
import '../theme/app_spacing.dart';

/// Tappable summary tile for dashboard and analytics grids.
class SummaryStatCard extends StatelessWidget {
  const SummaryStatCard({
    super.key,
    required this.label,
    required this.count,
    this.onTap,
    this.countColor,
  });

  final String label;
  final int count;
  final VoidCallback? onTap;
  final Color? countColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyles = AppTextStyles.of(context);
    final cardRadius = AppSpacing.cardBorderRadius;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: cardRadius,
        child: Padding(
          padding: AppDesignTokens.cardInsets,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textStyles.secondaryInfo(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppDesignTokens.space8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$count',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyles.dashboardNumber(
                    color: countColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
