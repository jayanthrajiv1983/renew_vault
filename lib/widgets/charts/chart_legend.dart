import 'package:flutter/material.dart';

import '../../core/theme/design_system.dart';
import '../../core/theme/app_text_styles.dart';

class ChartLegendItem {
  const ChartLegendItem({
    required this.label,
    required this.color,
    this.value,
    this.onTap,
  });

  final String label;
  final Color color;
  final String? value;
  final VoidCallback? onTap;
}

class ChartLegend extends StatelessWidget {
  const ChartLegend({
    super.key,
    required this.items,
    this.wrapSpacing = AppDesignTokens.cardGap,
    this.runSpacing = AppDesignTokens.space8,
  });

  final List<ChartLegendItem> items;
  final double wrapSpacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyles = AppTextStyles.of(context);
    final colorScheme = theme.colorScheme;

    return Wrap(
      spacing: wrapSpacing,
      runSpacing: runSpacing,
      children: items.map((item) {
        final legend = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: AppDesignTokens.space8),
            Text(
              item.value != null ? '${item.label} (${item.value})' : item.label,
              style: textStyles.tertiaryInfo(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
              ),
            ),
          ],
        );

        if (item.onTap == null) {
          return legend;
        }

        return InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignTokens.space4,
              vertical: AppDesignTokens.space4 / 2,
            ),
            child: legend,
          ),
        );
      }).toList(),
    );
  }
}
