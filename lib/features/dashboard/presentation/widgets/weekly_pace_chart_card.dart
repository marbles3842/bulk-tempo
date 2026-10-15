import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bulk_tempo/core/localization/locale_provider.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_state.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/dashboard_card_shell.dart';
import 'package:bulk_tempo/features/gain_target/presentation/formatters/gain_target_formatter.dart';

class WeeklyPaceChartCard extends StatelessWidget {
  final DashboardState state;
  final VoidCallback onRetry;

  const WeeklyPaceChartCard({
    super.key,
    required this.state,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final weeks = state.overview.calendarWeeks;
    final target = state.gainTarget;
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 2,
    );
    final values = [
      for (final week in weeks)
        if (week.paceKgPerWeek != null) week.paceKgPerWeek!,
    ];
    final bounds = [
      0.0,
      ...values,
      if (target != null) target.minWeeklyGainKg,
      if (target != null) target.maxWeeklyGainKg,
    ];
    final low = bounds.reduce(math.min);
    final high = bounds.reduce(math.max);
    final padding = math.max((high - low) * 0.15, 0.1);
    final color = Theme.of(context).colorScheme.primary;
    final DashboardCardStatus status;
    if (state.weightStatus == DashboardCardStatus.loading ||
        state.gainTargetStatus == DashboardCardStatus.loading) {
      status = DashboardCardStatus.loading;
    } else if (state.weightStatus == DashboardCardStatus.error ||
        state.gainTargetStatus == DashboardCardStatus.error) {
      status = DashboardCardStatus.error;
    } else if (state.weightStatus == DashboardCardStatus.loaded &&
        values.isEmpty) {
      status = DashboardCardStatus.empty;
    } else {
      status = state.weightStatus;
    }

    final errorMessage =
        state.weightErrorMessage ?? state.gainTargetErrorMessage;

    return DashboardCardShell(
      cardKey: const Key('dashboard_weekly_pace_card'),
      title: context.l10n.dashboardPaceTitle,
      subtitle: target == null
          ? null
          : context.l10n.dashboardPaceTargetSubtitle(
              '${GainTargetFormatter.formatRange(target, locale)} ${context.l10n.kgPerWeekUnit}',
            ),
      subtitleKey: const Key('dashboard_pace_target_subtitle'),
      status: status,
      isOutdated: state.isWeightOutdated || state.isGainTargetOutdated,
      outdatedBadgeKey: const Key('weekly_pace_outdated_badge'),
      errorMessage: errorMessage,
      onRetry: onRetry,
      retryButtonKey: const Key('dashboard_pace_retry_button'),
      emptyMessage: state.overview.loggedWeightWeeksCount == 0
          ? context.l10n.dashboardPaceEmpty
          : context.l10n.dashboardPaceNeedTwoWeeks,
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            minY: low - padding,
            maxY: high + padding,
            alignment: BarChartAlignment.spaceAround,
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            rangeAnnotations: target == null
                ? null
                : RangeAnnotations(
                    horizontalRangeAnnotations: [
                      HorizontalRangeAnnotation(
                        y1: target.minWeeklyGainKg,
                        y2: target.maxWeeklyGainKg,
                        color: Theme.of(
                          context,
                        ).colorScheme.tertiary.withValues(alpha: 0.18),
                      ),
                    ],
                  ),
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
                  reservedSize: 58,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(
                      '${value > 0 ? '+' : ''}${formatter.format(value)}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final week = weeks[group.x];
                  final pace = week.paceKgPerWeek;
                  if (pace == null) return null;
                  return BarTooltipItem(
                    '${WeekDateUtils.formatWeekRange(week.weekStartMonday, week.weekEndSunday, locale)}\n'
                    '${pace >= 0 ? '+' : ''}${formatter.format(pace)} ${context.l10n.kgPerWeekUnit}',
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
                      fromY: 0,
                      toY: weeks[i].paceKgPerWeek ?? 0,
                      width: weeks[i].paceKgPerWeek == null ? 0 : 12,
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
