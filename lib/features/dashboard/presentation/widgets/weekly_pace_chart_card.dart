import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bulk_tempo/core/design_system.dart';
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

    final targetSubtitle = target == null
        ? null
        : context.l10n.dashboardPaceTargetSubtitle(
            '${GainTargetFormatter.formatRange(target, locale)} ${context.l10n.kgPerWeekUnit}',
          );

    final semanticsParts = <String>[
      context.l10n.dashboardPaceTitle,
      ?targetSubtitle,
      for (final week in weeks)
        if (week.paceKgPerWeek != null)
          '${WeekDateUtils.formatWeekRange(week.weekStartMonday, week.weekEndSunday, locale)}: ${context.l10n.dashboardPaceMetric(week.paceKgPerWeek! >= 0 ? '+' : '-', formatter.format(week.paceKgPerWeek!.abs()), context.l10n.kgPerWeekUnit)}',
    ];

    return DashboardCardShell(
      cardKey: const Key('dashboard_weekly_pace_card'),
      title: context.l10n.dashboardPaceTitle,
      subtitle: targetSubtitle,
      subtitleKey: const Key('dashboard_pace_target_subtitle'),
      leadingIcon: AppIcon.target,
      status: status,
      isOutdated: state.isWeightOutdated || state.isGainTargetOutdated,
      outdatedBadgeKey: const Key('weekly_pace_outdated_badge'),
      errorMessage: errorMessage,
      onRetry: onRetry,
      retryButtonKey: const Key('dashboard_pace_retry_button'),
      emptyMessage: state.overview.loggedWeightWeeksCount == 0
          ? context.l10n.dashboardPaceEmpty
          : context.l10n.dashboardPaceNeedTwoWeeks,
      child: Semantics(
        container: true,
        excludeSemantics: true,
        label: semanticsParts.join('. '),
        child: SizedBox(
          height: chartTheme.chartHeight,
          child: BarChart(
            BarChartData(
              minY: low - padding,
              maxY: high + padding,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: chartTheme.gridLine, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              rangeAnnotations: target == null
                  ? null
                  : RangeAnnotations(
                      horizontalRangeAnnotations: [
                        HorizontalRangeAnnotation(
                          y1: target.minWeeklyGainKg,
                          y2: target.maxWeeklyGainKg,
                          color: chartTheme.targetFill.withValues(alpha: 0.55),
                        ),
                      ],
                    ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 0,
                    color: chartTheme.gridLine,
                    strokeWidth: 1,
                  ),
                  if (target != null) ...[
                    HorizontalLine(
                      y: target.minWeeklyGainKg,
                      color: chartTheme.targetBoundary,
                      strokeWidth: 1.5,
                      dashArray: chartTheme.targetDashPattern,
                    ),
                    HorizontalLine(
                      y: target.maxWeeklyGainKg,
                      color: chartTheme.targetBoundary,
                      strokeWidth: 1.5,
                      dashArray: chartTheme.targetDashPattern,
                    ),
                  ],
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
                    reservedSize: chartTheme.paceLeftAxisReservedSize,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(
                        '${value > 0 ? '+' : ''}${formatter.format(value)}',
                        style: axisLabelStyle,
                      ),
                    ),
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => chartTheme.tooltipSurface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final week = weeks[group.x];
                    final pace = week.paceKgPerWeek;
                    if (pace == null) return null;
                    return BarTooltipItem(
                      '${WeekDateUtils.formatWeekRange(week.weekStartMonday, week.weekEndSunday, locale)}\n'
                      '${context.l10n.dashboardPaceMetric(pace >= 0 ? '+' : '-', formatter.format(pace.abs()), context.l10n.kgPerWeekUnit)}',
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
                        fromY: 0,
                        toY: weeks[i].paceKgPerWeek ?? 0,
                        width: weeks[i].paceKgPerWeek == null
                            ? 0
                            : chartTheme.barWidth,
                        color: chartTheme.seriesPace,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(chartTheme.barRadius),
                          bottom: Radius.circular(chartTheme.barRadius),
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
