import 'package:flutter/material.dart';

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
    this.wrapSpacing = 12,
    this.runSpacing = 8,
  });

  final List<ChartLegendItem> items;
  final double wrapSpacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: wrapSpacing,
      runSpacing: runSpacing,
      children: items.map((item) {
        final legend = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              item.value != null ? '${item.label} (${item.value})' : item.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: legend,
          ),
        );
      }).toList(),
    );
  }
}
