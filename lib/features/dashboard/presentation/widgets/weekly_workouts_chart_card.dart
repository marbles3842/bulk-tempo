import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/weekly_progress_overview_entity.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_state.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/dashboard_card_shell.dart';

/// Card widget displaying the 12-calendar-week workouts count BarChart using fl_chart.
class WeeklyWorkoutsChartCard extends StatelessWidget {
  final DashboardCardStatus status;
  final bool isOutdated;
  final String? errorMessage;
  final List<CalendarWeekProgressSlotEntity> slots;
  final VoidCallback? onRetry;

  const WeeklyWorkoutsChartCard({
    super.key,
    required this.status,
    this.isOutdated = false,
    this.errorMessage,
    required this.slots,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxWorkouts = slots.isNotEmpty
        ? slots.map((s) => s.workoutCount).reduce((a, b) => a > b ? a : b)
        : 0;
    final maxY = (maxWorkouts < 4 ? 4 : maxWorkouts + 1).toDouble();

    final primaryColor = theme.colorScheme.primary;

    Widget? emptyContent;
    if (status == DashboardCardStatus.unconfigured) {
      emptyContent = Text(
        'Hevy not connected — connect in Profile',
        key: const Key('dashboard_workouts_unconfigured_text'),
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return DashboardCardShell(
      cardKey: const Key('dashboard_weekly_workouts_card'),
      title: 'Workouts per Week',
      status: status,
      isOutdated: isOutdated,
      outdatedBadgeKey: const Key('weekly_workouts_outdated_badge'),
      errorMessage: errorMessage,
      onRetry: onRetry,
      retryButtonKey: const Key('dashboard_workouts_retry_button'),
      emptyContent: emptyContent,
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            minY: 0,
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
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: 2,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (value != index.toDouble() ||
                        index < 0 ||
                        index >= slots.length) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        WeekDateUtils.formatShortWeekLabel(
                          slots[index].weekStartMonday,
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
                  reservedSize: 32,
                  interval: maxY > 8 ? (maxY / 4).ceilToDouble() : 1,
                  getTitlesWidget: (value, meta) {
                    if (value % 1 != 0 || value < 0) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        '${value.toInt()}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  if (group.x < 0 || group.x >= slots.length) return null;
                  final slot = slots[group.x];
                  final range = WeekDateUtils.formatWeekRange(
                    slot.weekStartMonday,
                    slot.weekEndSunday,
                  );
                  return BarTooltipItem(
                    '$range\n${slot.workoutCount} workouts',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            barGroups: [
              for (int i = 0; i < slots.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      fromY: 0,
                      toY: slots[i].workoutCount.toDouble(),
                      color: primaryColor,
                      width: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
