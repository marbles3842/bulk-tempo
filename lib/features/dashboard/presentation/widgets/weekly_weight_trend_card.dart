import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/weekly_progress_overview_entity.dart';
import 'package:bulk_tempo/features/dashboard/presentation/utils/dashboard_chart_utils.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_state.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/dashboard_card_shell.dart';

/// Card widget displaying the 12-calendar-week average weight LineChart using fl_chart.
class WeeklyWeightTrendCard extends StatelessWidget {
  final DashboardCardStatus status;
  final bool isOutdated;
  final String? errorMessage;
  final List<CalendarWeekProgressSlotEntity> slots;
  final VoidCallback? onRetry;

  const WeeklyWeightTrendCard({
    super.key,
    required this.status,
    this.isOutdated = false,
    this.errorMessage,
    required this.slots,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final validWeights = slots
        .map((s) => s.averageWeightKg)
        .whereType<double>()
        .toList();

    final effectiveStatus =
        (status == DashboardCardStatus.loaded && validWeights.isEmpty)
        ? DashboardCardStatus.empty
        : status;

    final minWeight = validWeights.isNotEmpty
        ? validWeights.reduce((a, b) => a < b ? a : b)
        : 70.0;
    final maxWeight = validWeights.isNotEmpty
        ? validWeights.reduce((a, b) => a > b ? a : b)
        : 80.0;

    var minY = (minWeight - 1.0).floorToDouble();
    var maxY = (maxWeight + 1.0).ceilToDouble();
    if (minY >= maxY) {
      minY -= 1;
      maxY += 1;
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < slots.length; i++) {
      final avg = slots[i].averageWeightKg;
      if (avg != null) {
        spots.add(FlSpot(i.toDouble(), avg));
      } else {
        spots.add(FlSpot.nullSpot);
      }
    }

    final primaryColor = Theme.of(context).colorScheme.primary;

    return DashboardCardShell(
      cardKey: const Key('dashboard_weight_trend_card'),
      title: 'Weekly Weight Trend',
      status: effectiveStatus,
      isOutdated: isOutdated,
      outdatedBadgeKey: const Key('weight_trend_outdated_badge'),
      errorMessage: errorMessage,
      onRetry: onRetry,
      retryButtonKey: const Key('dashboard_weight_retry_button'),
      emptyContent: Text(
        'No weights logged yet — add one on the Weights tab',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: 11,
            minY: minY,
            maxY: maxY,
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: DashboardChartUtils.buildBottomWeekTitles(
                slots: slots,
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
                    if (index < 0 || index >= slots.length) return null;
                    final slot = slots[index];
                    if (slot.averageWeightKg == null) return null;
                    final range = WeekDateUtils.formatWeekRange(
                      slot.weekStartMonday,
                      slot.weekEndSunday,
                    );
                    return LineTooltipItem(
                      '$range\n${slot.averageWeightKg!.toStringAsFixed(2)} kg avg',
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
                isCurved: true,
                barWidth: 3,
                color: primaryColor,
                dotData: FlDotData(
                  show: true,
                  checkToShowDot: (spot, barData) =>
                      !spot.x.isNaN && !spot.y.isNaN,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
