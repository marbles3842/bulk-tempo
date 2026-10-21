import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bulk_tempo/core/design_system.dart';
import 'package:bulk_tempo/core/localization/locale_provider.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/weekly_progress_overview_entity.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_state.dart';

/// Responsive KPI metric tiles header:
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
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    final paceTile = _buildPaceTile(context, overview, formatter);
    final averageTile = _buildAverageTile(context, overview, formatter);
    final totalGainTile = _buildTotalGainTile(context, overview, formatter);
    final workoutsTile = _buildWorkoutsTile(context, overview);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (textScale >= 1.4 || constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              paceTile,
              const SizedBox(height: AppSpacing.relatedGap),
              averageTile,
              const SizedBox(height: AppSpacing.relatedGap),
              totalGainTile,
              const SizedBox(height: AppSpacing.relatedGap),
              workoutsTile,
            ],
          );
        }

        if (constraints.maxWidth >= AppSpacing.expandedBreakpoint) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: paceTile),
                const SizedBox(width: AppSpacing.relatedGap),
                Expanded(child: averageTile),
                const SizedBox(width: AppSpacing.relatedGap),
                Expanded(child: totalGainTile),
                const SizedBox(width: AppSpacing.relatedGap),
                Expanded(child: workoutsTile),
              ],
            ),
          );
        }

        return Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: paceTile),
                  const SizedBox(width: AppSpacing.relatedGap),
                  Expanded(child: averageTile),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.relatedGap),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: totalGainTile),
                  const SizedBox(width: AppSpacing.relatedGap),
                  Expanded(child: workoutsTile),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaceTile(
    BuildContext context,
    WeeklyProgressOverviewEntity overview,
    NumberFormat formatter,
  ) {
    final pace = overview.currentPaceKgPerWeek;
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
      cardKey: const Key('dashboard_kpi_pace_tile'),
      title: context.l10n.dashboardKpiPaceTitle,
      value: valueText,
      subtitle: subtitleText != null ? Text(subtitleText) : null,
    );
  }

  Widget _buildAverageTile(
    BuildContext context,
    WeeklyProgressOverviewEntity overview,
    NumberFormat formatter,
  ) {
    final theme = Theme.of(context);
    final avg = overview.latestAverageWeightKg;
    final String valueText;
    Widget? subtitleWidget;

    if (avg != null) {
      valueText = context.l10n.dashboardWeightMetric(formatter.format(avg));

      if (overview.isLatestWeekIncomplete) {
        subtitleWidget = AppStatusBadge(
          badgeKey: const Key('dashboard_incomplete_week_badge'),
          label: context.l10n.dashboardKpiAverageSubtitleIncomplete(
            overview.latestWeekLoggedDays,
          ),
          tone: AppFeedbackTone.info,
        );
      } else if (overview.isLatestWeekCurrentWeek) {
        subtitleWidget = Text(
          context.l10n.dashboardKpiAverageSubtitleComplete,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
      } else if (overview.latestWeekStartMonday != null &&
          overview.latestWeekEndSunday != null) {
        subtitleWidget = Text(
          WeekDateUtils.formatWeekRange(
            overview.latestWeekStartMonday!,
            overview.latestWeekEndSunday!,
            Localizations.localeOf(context).languageCode,
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
      }
    } else {
      valueText = '—';
      subtitleWidget = null;
    }

    return _StatTile(
      cardKey: const Key('dashboard_kpi_average_tile'),
      title: context.l10n.dashboardKpiAverageTitle,
      value: valueText,
      subtitle: subtitleWidget,
    );
  }

  Widget _buildTotalGainTile(
    BuildContext context,
    WeeklyProgressOverviewEntity overview,
    NumberFormat formatter,
  ) {
    final gain = overview.totalGainKg;
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
      cardKey: const Key('dashboard_kpi_total_gain_tile'),
      title: context.l10n.dashboardKpiTotalGainTitle,
      value: valueText,
      subtitle: subtitleText != null ? Text(subtitleText) : null,
    );
  }

  Widget _buildWorkoutsTile(
    BuildContext context,
    WeeklyProgressOverviewEntity overview,
  ) {
    final theme = Theme.of(context);
    final String valueText;
    Widget? subtitleWidget;

    switch (state.workoutStatus) {
      case DashboardCardStatus.loaded:
        valueText = '${overview.currentWeekWorkoutCount}';
        subtitleWidget = Text(
          context.l10n.dashboardKpiWorkoutsThisWeek,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
      case DashboardCardStatus.unconfigured:
        valueText = '—';
        subtitleWidget = Text(
          context.l10n.dashboardKpiWorkoutsNotConnected,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
      case DashboardCardStatus.error:
        valueText = '—';
        subtitleWidget = AppStatusBadge(
          label: context.l10n.dashboardKpiWorkoutsSyncError,
          tone: AppFeedbackTone.error,
        );
      case DashboardCardStatus.loading:
      case DashboardCardStatus.empty:
        valueText = '...';
        subtitleWidget = null;
    }

    return _StatTile(
      cardKey: const Key('dashboard_kpi_workouts_tile'),
      title: context.l10n.dashboardKpiWorkoutsTitle,
      value: valueText,
      subtitle: subtitleWidget,
    );
  }
}

class _StatTile extends StatelessWidget {
  final Key? cardKey;
  final String title;
  final String value;
  final Widget? subtitle;

  const _StatTile({
    this.cardKey,
    required this.title,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      cardKey: cardKey,
      variant: AppCardVariant.grouped,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.space1),
            DefaultTextStyle.merge(
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              child: subtitle!,
            ),
          ],
        ],
      ),
    );
  }
}
