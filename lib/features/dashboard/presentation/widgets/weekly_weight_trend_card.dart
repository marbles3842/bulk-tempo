import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bulk_tempo/core/design_system.dart';
import 'package:bulk_tempo/core/localization/locale_provider.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_state.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/dashboard_card_shell.dart';

class WeeklyWeightTrendCard extends StatelessWidget {
  final DashboardState state;
  final VoidCallback onRetry;

  const WeeklyWeightTrendCard({
    super.key,
    required this.state,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final weeks = state.overview.calendarWeeks;
    final weights = [
      for (final week in weeks)
        if (week.averageWeightKg != null) week.averageWeightKg!,
    ];
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 2,
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
      context.l10n.dashboardWeightTrendTitle,
      for (final week in weeks)
        if (week.averageWeightKg != null)
          '${WeekDateUtils.formatWeekRange(week.weekStartMonday, week.weekEndSunday, locale)}: ${context.l10n.dashboardWeightMetric(formatter.format(week.averageWeightKg))}',
    ];

    return DashboardCardShell(
      cardKey: const Key('dashboard_weight_trend_card'),
      title: context.l10n.dashboardWeightTrendTitle,
      leadingIcon: AppIcon.weight,
      status: state.weightStatus,
      isOutdated: state.isWeightOutdated,
      outdatedBadgeKey: const Key('weight_trend_outdated_badge'),
      errorMessage: state.weightErrorMessage,
      onRetry: onRetry,
      retryButtonKey: const Key('dashboard_weight_retry_button'),
      emptyMessage: context.l10n.dashboardWeightEmpty,
      child: Semantics(
        container: true,
        excludeSemantics: true,
        label: semanticsParts.join('. '),
        child: SizedBox(
          height: chartTheme.chartHeight,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: 11,
              minY: weights.isEmpty
                  ? 0
                  : (weights.reduce((a, b) => a < b ? a : b) - 1)
                        .floorToDouble(),
              maxY: weights.isEmpty
                  ? 1
                  : (weights.reduce((a, b) => a > b ? a : b) + 1)
                        .ceilToDouble(),
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
                    reservedSize: chartTheme.weightLeftAxisReservedSize,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(
                        '${value.toStringAsFixed(0)} kg',
                        style: axisLabelStyle,
                      ),
                    ),
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => chartTheme.tooltipSurface,
                  getTooltipItems: (spots) => spots.map((spot) {
                    final week = weeks[spot.x.toInt()];
                    return LineTooltipItem(
                      '${WeekDateUtils.formatWeekRange(week.weekStartMonday, week.weekEndSunday, locale)}\n${context.l10n.dashboardWeightMetric(formatter.format(week.averageWeightKg))}',
                      tooltipTextStyle,
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < weeks.length; i++)
                      weeks[i].averageWeightKg == null
                          ? FlSpot.nullSpot
                          : FlSpot(i.toDouble(), weeks[i].averageWeightKg!),
                  ],
                  color: chartTheme.seriesWeight,
                  barWidth: chartTheme.lineStrokeWidth,
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
