import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../shared/widgets/empty_state_widget.dart';
import '../../theme/app_spacing.dart';
import '../../services/analytics_service.dart';
import 'chart_legend.dart';

class ExpiryLineChart extends StatelessWidget {
  const ExpiryLineChart({
    super.key,
    required this.monthlyExpiries,
  });

  final List<MonthlyExpiryBucket> monthlyExpiries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lineColor = scheme.primary;
    final dotColor = scheme.secondary;
    final fillColor = scheme.primary.withValues(alpha: 0.12);

    if (monthlyExpiries.isEmpty) {
      return EmptyStateWidget.compact(
        title: 'No upcoming expiry data',
      );
    }

    final maxY = monthlyExpiries
        .map((bucket) => bucket.count)
        .fold<int>(0, (max, count) => count > max ? count : max)
        .toDouble();

    final spots = monthlyExpiries
        .asMap()
        .entries
        .map(
          (entry) => FlSpot(
            entry.key.toDouble(),
            entry.value.count.toDouble(),
          ),
        )
        .toList();

    final showEveryNthLabel = monthlyExpiries.length > 8 ? 2 : 1;

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY + (maxY * 0.2).clamp(1, 4),
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
                    reservedSize: 32,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 ||
                          index >= monthlyExpiries.length ||
                          index % showEveryNthLabel != 0) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          monthlyExpiries[index].label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: lineColor,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: dotColor,
                        strokeWidth: 2,
                        strokeColor: scheme.surface,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: fillColor,
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => scheme.inverseSurface,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      if (index < 0 || index >= monthlyExpiries.length) {
                        return null;
                      }
                      final bucket = monthlyExpiries[index];
                      return LineTooltipItem(
                        '${bucket.label}\n${bucket.count} expiring',
                        theme.textTheme.labelSmall!.copyWith(
                          color: scheme.onInverseSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        AppSpacing.gapSection,
        ChartLegend(
          items: [
            ChartLegendItem(
              label: 'Upcoming expiries',
              color: lineColor,
            ),
            ChartLegendItem(
              label: 'Monthly data points',
              color: dotColor,
            ),
          ],
        ),
      ],
    );
  }
}
