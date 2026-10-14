import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bulk_tempo/core/localization/locale_provider.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_state.dart';

/// 2×2 grid row of headline KPI metric tiles:
/// - Current Pace
/// - Latest Average (with incomplete week indicator)
/// - Total Gain
/// - Workouts This Week
class DashboardKpiRow extends StatelessWidget {
  final DashboardState state;

  const DashboardKpiRow({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 2,
    );
    final overview = state.overview;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildPaceTile(context, overview, formatter)),
              const SizedBox(width: 12),
              Expanded(child: _buildAverageTile(context, overview, formatter)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTotalGainTile(context, overview, formatter),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildWorkoutsTile(context, overview)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaceTile(
    BuildContext context,
    dynamic overview,
    NumberFormat formatter,
  ) {
    final pace = overview.currentPaceKgPerWeek as double?;
    final String valueText;
    final String? subtitleText;

    if (pace != null) {
      final sign = pace >= 0 ? '+' : '-';
      valueText = context.l10n.dashboardPaceMetric(
        sign,
        formatter.format(pace.abs()),
        context.l10n.kgPerWeekUnit,
      );
      subtitleText = null;
    } else {
      valueText = '—';
      subtitleText = context.l10n.dashboardKpiPaceSubtitleEmpty;
    }

    return _StatTile(
      key: const Key('dashboard_kpi_pace_tile'),
      title: context.l10n.dashboardKpiPaceTitle,
      value: valueText,
      subtitle: subtitleText != null ? Text(subtitleText) : null,
    );
  }

  Widget _buildAverageTile(
    BuildContext context,
    dynamic overview,
    NumberFormat formatter,
  ) {
    final theme = Theme.of(context);
    final avg = overview.latestAverageWeightKg as double?;
    final String valueText;
    Widget? subtitleWidget;

    if (avg != null) {
      valueText = context.l10n.dashboardWeightMetric(formatter.format(avg));

      if (overview.isLatestWeekIncomplete as bool) {
        subtitleWidget = Container(
          key: const Key('dashboard_incomplete_week_badge'),
          child: Text(
            context.l10n.dashboardKpiAverageSubtitleIncomplete(
              overview.latestWeekLoggedDays as int,
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      } else if (overview.isLatestWeekCurrentWeek as bool) {
        subtitleWidget = Text(
          context.l10n.dashboardKpiAverageSubtitleComplete,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
      } else if (overview.latestWeekStartMonday != null &&
          overview.latestWeekEndSunday != null) {
        subtitleWidget = Text(
          WeekDateUtils.formatWeekRange(
            overview.latestWeekStartMonday as DateTime,
            overview.latestWeekEndSunday as DateTime,
            Localizations.localeOf(context).languageCode,
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
      }
    } else {
      valueText = '—';
      subtitleWidget = null;
    }

    return _StatTile(
      key: const Key('dashboard_kpi_average_tile'),
      title: context.l10n.dashboardKpiAverageTitle,
      value: valueText,
      subtitle: subtitleWidget,
    );
  }

  Widget _buildTotalGainTile(
    BuildContext context,
    dynamic overview,
    NumberFormat formatter,
  ) {
    final gain = overview.totalGainKg as double?;
    final String valueText;
    final String? subtitleText;

    if (gain != null) {
      final sign = gain >= 0 ? '+' : '-';
      valueText = context.l10n.dashboardGainMetric(
        sign,
        formatter.format(gain.abs()),
      );
      subtitleText = null;
    } else {
      valueText = '—';
      subtitleText = context.l10n.dashboardKpiPaceSubtitleEmpty;
    }

    return _StatTile(
      key: const Key('dashboard_kpi_total_gain_tile'),
      title: context.l10n.dashboardKpiTotalGainTitle,
      value: valueText,
      subtitle: subtitleText != null ? Text(subtitleText) : null,
    );
  }

  Widget _buildWorkoutsTile(BuildContext context, dynamic overview) {
    final String valueText;
    final String subtitleText;

    switch (state.workoutStatus) {
      case DashboardCardStatus.loaded:
        valueText = '${overview.currentWeekWorkoutCount}';
        subtitleText = context.l10n.dashboardKpiWorkoutsThisWeek;
      case DashboardCardStatus.unconfigured:
        valueText = '—';
        subtitleText = context.l10n.dashboardKpiWorkoutsNotConnected;
      case DashboardCardStatus.error:
        valueText = '—';
        subtitleText = context.l10n.dashboardKpiWorkoutsSyncError;
      case DashboardCardStatus.loading:
      case DashboardCardStatus.empty:
        valueText = '...';
        subtitleText = '';
    }

    return _StatTile(
      key: const Key('dashboard_kpi_workouts_tile'),
      title: context.l10n.dashboardKpiWorkoutsTitle,
      value: valueText,
      subtitle: subtitleText.isNotEmpty ? Text(subtitleText) : null,
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final Widget? subtitle;

  const _StatTile({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 18,
              child: subtitle != null
                  ? DefaultTextStyle(
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: subtitle!,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
