import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/weight/domain/models/weekly_weight_summary_entity.dart';

/// Renders the weekly-average dynamic trend chart above the weekly list using
/// `fl_chart`'s [LineChart], plotting up to 12 weekly averages chronologically left-to-right.
class WeeklyWeightChart extends StatelessWidget {
  final List<WeeklyWeightSummaryEntity> chartSummaries;

  const WeeklyWeightChart({super.key, required this.chartSummaries});

  @override
  Widget build(BuildContext context) {
    if (chartSummaries.isEmpty) {
      return const Card(
        key: Key('weekly_weight_chart_card'),
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('No weekly data available')),
        ),
      );
    }

    final isSingleWeek = chartSummaries.length == 1;

    final weights = chartSummaries.map((s) => s.averageWeightKg).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);

    var minY = (minWeight - 1.0).floorToDouble();
    var maxY = (maxWeight + 1.0).ceilToDouble();
    if (minY >= maxY) {
      minY -= 1;
      maxY += 1;
    }

    final double minX = isSingleWeek ? -0.5 : 0.0;
    final double maxX = isSingleWeek
        ? 0.5
        : (chartSummaries.length - 1).toDouble();

    final spots = [
      for (int i = 0; i < chartSummaries.length; i++)
        FlSpot(i.toDouble(), chartSummaries[i].averageWeightKg),
    ];

    final primaryColor = Theme.of(context).colorScheme.primary;

    return Card(
      key: const Key('weekly_weight_chart_card'),
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Weekly Weight Trend',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: minX,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (value != index.toDouble() ||
                              index < 0 ||
                              index >= chartSummaries.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              WeekDateUtils.formatShortWeekLabel(
                                chartSummaries[index].weekStartMonday,
                              ),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              '${value.toStringAsFixed(1)} kg',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.round();
                          if (index < 0 || index >= chartSummaries.length) {
                            return null;
                          }
                          final summary = chartSummaries[index];
                          final range = WeekDateUtils.formatWeekRange(
                            summary.weekStartMonday,
                            summary.weekEndSunday,
                          );
                          return LineTooltipItem(
                            '$range\n${summary.averageWeightKg.toStringAsFixed(2)} kg avg',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: !isSingleWeek,
                      barWidth: 3,
                      color: primaryColor,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            if (isSingleWeek) ...[
              const SizedBox(height: 12),
              Container(
                key: const Key('single_week_chart_hint'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Log weights in at least 2 weeks to see a multi-week trend line',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
