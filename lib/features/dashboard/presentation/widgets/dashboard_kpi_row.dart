import 'package:flutter/material.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/weekly_progress_overview_entity.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_state.dart';

/// Renders the 4 headline KPI metrics above the charts in a 2x2 grid of stat tiles:
/// Current Pace, Latest Average Weight, Total Gain, and Workouts This Week.
class DashboardKpiRow extends StatelessWidget {
  final WeeklyProgressOverviewEntity overview;
  final DashboardCardStatus workoutStatus;

  const DashboardKpiRow({
    super.key,
    required this.overview,
    required this.workoutStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 1. Current Pace
    final pace = overview.currentPaceKgPerWeek;
    final String paceValue;
    final String paceSubtitle;
    if (pace == null) {
      paceValue = '—';
      paceSubtitle = 'Log 2+ weeks';
    } else {
      final sign = pace >= 0 ? '+' : '';
      paceValue = '$sign${pace.toStringAsFixed(2)} kg/wk';
      paceSubtitle = 'Current pace';
    }

    // 2. Latest Average
    final avg = overview.latestAverageWeightKg;
    final String avgValue;
    final Widget avgSubtitleWidget;
    if (avg == null) {
      avgValue = '—';
      avgSubtitleWidget = Text(
        '—',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    } else {
      avgValue = '${avg.toStringAsFixed(2)} kg';
      if (overview.isLatestWeekCurrentWeek) {
        avgSubtitleWidget = Text(
          'This week · ${overview.latestWeekLoggedDays}/7 days logged',
          key: overview.isLatestWeekIncomplete
              ? const Key('dashboard_incomplete_week_badge')
              : null,
          style: theme.textTheme.bodySmall?.copyWith(
            color: overview.isLatestWeekIncomplete
                ? theme.colorScheme.tertiary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: overview.isLatestWeekIncomplete
                ? FontWeight.w600
                : FontWeight.normal,
          ),
        );
      } else if (overview.latestWeekStartMonday != null &&
          overview.latestWeekEndSunday != null) {
        avgSubtitleWidget = Text(
          WeekDateUtils.formatWeekRange(
            overview.latestWeekStartMonday!,
            overview.latestWeekEndSunday!,
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      } else {
        avgSubtitleWidget = Text(
          overview.latestWeekStartIso ?? 'Prior week',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
      }
    }

    // 3. Total Gain
    final gain = overview.totalGainKg;
    final String gainValue;
    final String gainSubtitle;
    if (gain == null) {
      gainValue = '—';
      gainSubtitle = 'Log 2+ weeks';
    } else {
      final sign = gain >= 0 ? '+' : '';
      gainValue = '$sign${gain.toStringAsFixed(2)} kg';
      gainSubtitle = 'All-time gain';
    }

    // 4. Workouts This Week
    final String workoutsValue;
    final String workoutsSubtitle;
    switch (workoutStatus) {
      case DashboardCardStatus.loaded:
      case DashboardCardStatus.empty:
        workoutsValue = '${overview.currentWeekWorkoutCount}';
        workoutsSubtitle = 'This week';
      case DashboardCardStatus.unconfigured:
        workoutsValue = '—';
        workoutsSubtitle = 'Not connected';
      case DashboardCardStatus.error:
        workoutsValue = '—';
        workoutsSubtitle = 'Sync error';
      case DashboardCardStatus.loading:
        workoutsValue = '...';
        workoutsSubtitle = 'Loading...';
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                tileKey: const Key('dashboard_kpi_pace_tile'),
                title: 'Current Pace',
                value: paceValue,
                subtitleWidget: Text(
                  paceSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _KpiTile(
                tileKey: const Key('dashboard_kpi_average_tile'),
                title: 'Latest Average',
                value: avgValue,
                subtitleWidget: avgSubtitleWidget,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                tileKey: const Key('dashboard_kpi_total_gain_tile'),
                title: 'Total Gain',
                value: gainValue,
                subtitleWidget: Text(
                  gainSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _KpiTile(
                tileKey: const Key('dashboard_kpi_workouts_tile'),
                title: 'Workouts',
                value: workoutsValue,
                subtitleWidget: Text(
                  workoutsSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  final Key tileKey;
  final String title;
  final String value;
  final Widget subtitleWidget;

  const _KpiTile({
    required this.tileKey,
    required this.title,
    required this.value,
    required this.subtitleWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: tileKey,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            subtitleWidget,
          ],
        ),
      ),
    );
  }
}
