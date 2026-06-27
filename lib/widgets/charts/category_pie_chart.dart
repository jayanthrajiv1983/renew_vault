import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../constants/categories.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../theme/app_spacing.dart';
import 'chart_legend.dart';

class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({
    super.key,
    required this.categoryCounts,
    this.categories = Categories.ordered,
    this.onCategoryTap,
  });

  final Map<String, int> categoryCounts;
  final List<String> categories;
  final ValueChanged<String>? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = categoryCounts.values.fold<int>(0, (sum, count) => sum + count);

    if (total == 0) {
      return EmptyStateWidget.compact(
        title: 'No category data yet',
      );
    }

    final sections = <PieChartSectionData>[];
    final legendItems = <ChartLegendItem>[];

    for (var i = 0; i < categories.length; i++) {
      final category = categories[i];
      final count = categoryCounts[category] ?? 0;
      if (count == 0) {
        continue;
      }

      final color = categoryColor(category, scheme);
      final percentage = (count / total * 100).round();

      sections.add(
        PieChartSectionData(
          value: count.toDouble(),
          color: color,
          title: '$percentage%',
          radius: 56,
          titleStyle: theme.textTheme.labelSmall?.copyWith(
            color: _contrastColor(color, scheme),
            fontWeight: FontWeight.w600,
          ) ??
              TextStyle(
                color: _contrastColor(color, scheme),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
          badgeWidget: null,
        ),
      );

      legendItems.add(
        ChartLegendItem(
          label: category,
          color: color,
          value: '$count',
          onTap: onCategoryTap == null
              ? null
              : () => onCategoryTap!(category),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 36,
              sectionsSpace: 2,
              startDegreeOffset: -90,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        AppSpacing.gapSection,
        ChartLegend(items: legendItems),
      ],
    );
  }

  Color _contrastColor(Color background, ColorScheme scheme) {
    return background.computeLuminance() > 0.5
        ? scheme.onSurface
        : scheme.onPrimary;
  }
}
