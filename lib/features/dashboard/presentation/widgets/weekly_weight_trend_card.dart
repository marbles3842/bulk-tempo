import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final color = Theme.of(context).colorScheme.primary;

    return DashboardCardShell(
      cardKey: const Key('dashboard_weight_trend_card'),
      title: context.l10n.dashboardWeightTrendTitle,
      status: state.weightStatus,
      isOutdated: state.isWeightOutdated,
      outdatedBadgeKey: const Key('weight_trend_outdated_badge'),
      errorMessage: state.weightErrorMessage,
      onRetry: onRetry,
      retryButtonKey: const Key('dashboard_weight_retry_button'),
      emptyMessage: context.l10n.dashboardWeightEmpty,
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: 11,
            minY: weights.isEmpty
                ? 0
                : (weights.reduce((a, b) => a < b ? a : b) - 1).floorToDouble(),
            maxY: weights.isEmpty
                ? 1
                : (weights.reduce((a, b) => a > b ? a : b) + 1).ceilToDouble(),
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
                  reservedSize: 46,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(
                      '${value.toStringAsFixed(0)} kg',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots.map((spot) {
                  final week = weeks[spot.x.toInt()];
                  return LineTooltipItem(
                    '${WeekDateUtils.formatWeekRange(week.weekStartMonday, week.weekEndSunday, locale)}\n${context.l10n.dashboardWeightMetric(formatter.format(week.averageWeightKg))}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
                color: color,
                barWidth: 3,
                dotData: const FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
