import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:bulk_tempo/core/design_system.dart';
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
    final chartTheme = AppChartTheme.of(context);
    final textTheme = Theme.of(context).textTheme;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final axisLabelStyle = textTheme.labelSmall?.copyWith(
      color: chartTheme.axisLabel,
    );
    final tooltipTextStyle =
        textTheme.labelSmall?.copyWith(
          color: chartTheme.onTooltipSurface,
          fontWeight: FontWeight.w600,
        ) ??
        TextStyle(
          color: chartTheme.onTooltipSurface,
          fontWeight: FontWeight.w600,
        );

    final semanticsParts = <String>[
      context.l10n.dashboardWorkoutsTitle,
      for (final week in weeks)
        '${WeekDateUtils.formatWeekRange(week.weekStartMonday, week.weekEndSunday, locale)}: ${context.l10n.dashboardWorkoutsTooltip(week.workoutCount)}',
    ];

    return DashboardCardShell(
      cardKey: const Key('dashboard_weekly_workouts_card'),
      title: context.l10n.dashboardWorkoutsTitle,
      leadingIcon: AppIcon.workout,
      status: state.workoutStatus,
      isOutdated: state.isWorkoutOutdated,
      outdatedBadgeKey: const Key('weekly_workouts_outdated_badge'),
      errorMessage: state.workoutErrorMessage,
      onRetry: onRetry,
      retryButtonKey: const Key('dashboard_workouts_retry_button'),
      unconfiguredMessage: context.l10n.dashboardWorkoutsUnconfigured,
      unconfiguredMessageKey: const Key('dashboard_workouts_unconfigured_text'),
      child: Semantics(
        container: true,
        excludeSemantics: true,
        label: semanticsParts.join('. '),
        child: SizedBox(
          height: chartTheme.chartHeight,
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: math.max(1, maxCount + 1).toDouble(),
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: chartTheme.gridLine, strokeWidth: 1),
              ),
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
                    reservedSize: chartTheme.bottomAxisReservedSize,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      final showTick = textScale >= 1.3
                          ? index % 4 == 0
                          : index.isEven;
                      if (value != index.toDouble() ||
                          index < 0 ||
                          index >= weeks.length ||
                          !showTick) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          WeekDateUtils.formatShortWeekLabel(
                            weeks[index].weekStartMonday,
                            locale,
                          ),
                          style: axisLabelStyle,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: chartTheme.workoutsLeftAxisReservedSize,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value != value.roundToDouble()) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          value.toInt().toString(),
                          style: axisLabelStyle,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => chartTheme.tooltipSurface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final week = weeks[group.x];
                    return BarTooltipItem(
                      '${WeekDateUtils.formatWeekRange(week.weekStartMonday, week.weekEndSunday, locale)}\n'
                      '${context.l10n.dashboardWorkoutsTooltip(week.workoutCount)}',
                      tooltipTextStyle,
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
                        width: chartTheme.barWidth,
                        color: chartTheme.seriesWorkouts,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(chartTheme.barRadius),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
