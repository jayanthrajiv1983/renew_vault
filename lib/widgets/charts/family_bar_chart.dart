import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import 'chart_legend.dart';

class FamilyBarChart extends StatelessWidget {
  const FamilyBarChart({
    super.key,
    required this.ownerCounts,
  });

  final Map<String, int> ownerCounts;

  List<Color> _barColors(ColorScheme scheme, int count) {
    final palette = [
      scheme.primary,
      scheme.secondary,
      scheme.tertiary,
      scheme.primaryContainer,
      scheme.secondaryContainer,
      scheme.tertiaryContainer,
      scheme.inversePrimary,
      scheme.outline,
    ];

    return List.generate(count, (index) => palette[index % palette.length]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (ownerCounts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.screenPadding),
        child: Text(
          'No family member data yet',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final entries = ownerCounts.entries.toList();
    final colors = _barColors(scheme, entries.length);
    final maxY = entries
        .map((entry) => entry.value)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    final barGroups = <BarChartGroupData>[];
    final legendItems = <ChartLegendItem>[];

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final color = colors[i];

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: entry.value.toDouble(),
              color: color,
              width: 20,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
        ),
      );

      legendItems.add(
        ChartLegendItem(
          label: entry.key,
          color: color,
          value: '${entry.value}',
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              maxY: maxY + (maxY * 0.15).clamp(1, 4),
              barGroups: barGroups,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY <= 4 ? 1 : (maxY / 4).ceilToDouble(),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: maxY <= 4 ? 1 : (maxY / 4).ceilToDouble(),
                    getTitlesWidget: (value, meta) {
                      if (value != value.roundToDouble()) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        value.toInt().toString(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= entries.length) {
                        return const SizedBox.shrink();
                      }
                      final name = entries[index].key;
                      final shortName =
                          name.length > 8 ? '${name.substring(0, 7)}…' : name;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          shortName,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        AppSpacing.gapSection,
        ChartLegend(items: legendItems),
      ],
    );
  }
}
