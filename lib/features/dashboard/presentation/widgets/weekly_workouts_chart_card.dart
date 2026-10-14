import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:bulk_tempo/core/localization/locale_provider.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_state.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/dashboard_card_shell.dart';

class WeeklyWorkoutsChartCard extends StatelessWidget {
  final DashboardState state;
  final VoidCallback onRetry;

  const WeeklyWorkoutsChartCard({
    super.key,
    required this.state,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final weeks = state.overview.calendarWeeks;
    final locale = Localizations.localeOf(context).toString();
    final maxCount = weeks.fold<int>(
      0,
      (max, week) => math.max(max, week.workoutCount),
    );
    final color = Theme.of(context).colorScheme.primary;

    return DashboardCardShell(
      cardKey: const Key('dashboard_weekly_workouts_card'),
      title: context.l10n.dashboardWorkoutsTitle,
      status: state.workoutStatus,
      isOutdated: state.isWorkoutOutdated,
      outdatedBadgeKey: const Key('weekly_workouts_outdated_badge'),
      errorMessage: state.workoutErrorMessage,
      onRetry: onRetry,
      retryButtonKey: const Key('dashboard_workouts_retry_button'),
      unconfiguredMessage: context.l10n.dashboardWorkoutsUnconfigured,
      unconfiguredMessageKey: const Key('dashboard_workouts_unconfigured_text'),
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            minY: 0,
            maxY: math.max(1, maxCount + 1).toDouble(),
            alignment: BarChartAlignment.spaceAround,
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
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
                        index >= weeks.length ||
                        index.isOdd) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        WeekDateUtils.formatShortWeekLabel(
                          weeks[index].weekStartMonday,
                          locale,
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
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    if (value != value.roundToDouble()) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        value.toInt().toString(),
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
                  final week = weeks[group.x];
                  return BarTooltipItem(
                    '${WeekDateUtils.formatWeekRange(week.weekStartMonday, week.weekEndSunday, locale)}\n'
                    '${context.l10n.dashboardWorkoutsTooltip(week.workoutCount)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            barGroups: [
              for (var i = 0; i < weeks.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: weeks[i].workoutCount.toDouble(),
                      width: 12,
                      color: color,
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
