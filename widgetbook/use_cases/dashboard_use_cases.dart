import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:bulk_tempo/core/design_system.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_state.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:bulk_tempo/features/dashboard/domain/calculators/weekly_progress_calculator.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/weekly_progress_overview_entity.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_state.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_view_model.dart';
import 'package:bulk_tempo/features/dashboard/presentation/views/dashboard_view.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/dashboard_card_shell.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/dashboard_kpi_row.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/weekly_pace_chart_card.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/weekly_weight_trend_card.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/weekly_workouts_chart_card.dart';
import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';
import 'package:bulk_tempo/features/weight/domain/models/weekly_weight_summary_entity.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/weekly_workout_summary_entity.dart';

final DateTime _catalogNow = DateTime.utc(2026, 10, 14, 12);

WeeklyProgressOverviewEntity _buildCatalogOverview({
  bool populated = true,
  bool isLatestWeekIncomplete = true,
}) {
  if (!populated) {
    return WeeklyProgressCalculator.calculate(
      allWeightSummaries: const [],
      workoutSummaries: const [],
      now: _catalogNow,
    );
  }

  final currentMonday = DateTime.utc(2026, 10, 12);
  final weights = <WeeklyWeightSummaryEntity>[];
  final workouts = <WeeklyWorkoutSummaryEntity>[];
  const sampleWeights = <double>[
    80.10,
    80.35,
    80.60,
    80.80,
    81.10,
    81.35,
    81.55,
    81.85,
    82.10,
    82.40,
    82.65,
    82.95,
  ];
  const sampleWorkouts = <int>[3, 4, 4, 3, 5, 4, 4, 3, 4, 5, 4, 4];

  for (var i = 0; i < 12; i++) {
    final weeksAgo = 11 - i;
    final monday = DateTime.utc(
      currentMonday.year,
      currentMonday.month,
      currentMonday.day - (7 * weeksAgo),
    );
    final sunday = monday.add(const Duration(days: 6));
    final iso =
        '${monday.year.toString().padLeft(4, '0')}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';

    final daysToLog = (i == 11 && isLatestWeekIncomplete) ? 4 : 7;
    weights.add(
      WeeklyWeightSummaryEntity(
        weekStartIso: iso,
        weekStartMonday: monday,
        weekEndSunday: sunday,
        averageWeightKg: sampleWeights[i],
        entries: [
          for (var d = 0; d < daysToLog; d++)
            WeightEntryEntity(
              dateIso: iso,
              date: monday.add(Duration(days: d)),
              weightKg: sampleWeights[i],
              updatedAt: _catalogNow,
            ),
        ],
      ),
    );

    workouts.add(
      WeeklyWorkoutSummaryEntity(
        weekStartIso: iso,
        weekStartMonday: monday,
        weekEndSunday: sunday,
        workoutCount: sampleWorkouts[i],
        workouts: const [],
        totalWorkingSets: sampleWorkouts[i] * 12,
        totalVolumeKg: sampleWorkouts[i] * 4200.0,
      ),
    );
  }

  return WeeklyProgressCalculator.calculate(
    allWeightSummaries: weights,
    workoutSummaries: workouts,
    now: _catalogNow,
  );
}

DashboardState _buildCatalogDashboardState({
  DashboardCardStatus weightStatus = DashboardCardStatus.loaded,
  DashboardCardStatus workoutStatus = DashboardCardStatus.loaded,
  DashboardCardStatus gainTargetStatus = DashboardCardStatus.loaded,
  bool isWeightOutdated = false,
  bool isWorkoutOutdated = false,
  bool isGainTargetOutdated = false,
  bool isLatestWeekIncomplete = true,
  bool includeGainTarget = true,
}) {
  final populated = weightStatus == DashboardCardStatus.loaded;
  return DashboardState(
    weightStatus: weightStatus,
    workoutStatus: workoutStatus,
    gainTargetStatus: gainTargetStatus,
    isWeightOutdated: isWeightOutdated,
    isWorkoutOutdated: isWorkoutOutdated,
    isGainTargetOutdated: isGainTargetOutdated,
    weightErrorMessage: weightStatus == DashboardCardStatus.error
        ? 'Failed to synchronize weight measurements.'
        : null,
    workoutErrorMessage: workoutStatus == DashboardCardStatus.error
        ? 'Failed to reach Hevy API.'
        : null,
    gainTargetErrorMessage: gainTargetStatus == DashboardCardStatus.error
        ? 'Failed to load weekly gain target.'
        : null,
    gainTarget: includeGainTarget
        ? const GainTargetEntity(minWeeklyGainKg: 0.20, maxWeeklyGainKg: 0.40)
        : null,
    overview: _buildCatalogOverview(
      populated: populated,
      isLatestWeekIncomplete: isLatestWeekIncomplete,
    ),
    hasAnyWorkoutInWindow: workoutStatus == DashboardCardStatus.loaded,
  );
}

class _WidgetbookAuthViewModel extends AuthViewModel {
  @override
  AuthState build() {
    return const AuthState(
      user: UserEntity(id: 'widgetbook-user', email: 'athlete@bulktempo.app'),
      isInitializing: false,
    );
  }
}

class _WidgetbookDashboardViewModel extends DashboardViewModel {
  _WidgetbookDashboardViewModel(this._catalogState);

  final DashboardState _catalogState;

  @override
  DashboardState build() => _catalogState;

  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<void> refreshAll() async {}

  @override
  Future<void> retryWeights() async {}

  @override
  Future<void> retryWorkouts() async {}

  @override
  Future<void> retryPace() async {}
}

/// Category containing all Dashboard presentation components and full-view use cases.
final dashboardCategory = WidgetbookCategory(
  name: 'Dashboard',
  children: [
    WidgetbookComponent(
      name: 'DashboardKpiRow',
      useCases: [
        WidgetbookUseCase(
          name: 'Responsive KPI Metric Tiles',
          builder: (context) {
            final populated = context.knobs.boolean(
              label: 'Populated Weight Data',
              initialValue: true,
            );
            final isLatestWeekIncomplete = context.knobs.boolean(
              label: 'Incomplete Current Week (4/7 days)',
              initialValue: true,
            );
            final workoutStatus = context.knobs.object
                .dropdown<DashboardCardStatus>(
                  label: 'Workout Status',
                  options: const [
                    DashboardCardStatus.loaded,
                    DashboardCardStatus.unconfigured,
                    DashboardCardStatus.error,
                    DashboardCardStatus.loading,
                  ],
                  initialOption: DashboardCardStatus.loaded,
                  labelBuilder: (s) => s.name,
                );

            final state = DashboardState(
              weightStatus: populated
                  ? DashboardCardStatus.loaded
                  : DashboardCardStatus.empty,
              workoutStatus: workoutStatus,
              overview: _buildCatalogOverview(
                populated: populated,
                isLatestWeekIncomplete: isLatestWeekIncomplete,
              ),
              hasAnyWorkoutInWindow:
                  workoutStatus == DashboardCardStatus.loaded,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.dashboardMaxWidth,
                  ),
                  child: DashboardKpiRow(state: state),
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'DashboardCardShell',
      useCases: [
        WidgetbookUseCase(
          name: 'Async States & Outdated Badge Matrix',
          builder: (context) {
            final status = context.knobs.object.dropdown<DashboardCardStatus>(
              label: 'Card Status',
              options: DashboardCardStatus.values,
              initialOption: DashboardCardStatus.loaded,
              labelBuilder: (s) => s.name,
            );
            final isOutdated = context.knobs.boolean(
              label: 'Outdated Badge (Stale Cache)',
              initialValue: true,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: DashboardCardShell(
                    title: 'Weekly Weight Trend',
                    subtitle: 'Rolling 12-week body weight averages',
                    leadingIcon: AppIcon.weight,
                    status: status,
                    isOutdated: isOutdated,
                    errorMessage: 'Failed to synchronize weight measurements.',
                    emptyMessage:
                        'No weights logged yet — add one on the Weights tab',
                    unconfiguredMessage:
                        'Hevy not connected — connect in Profile',
                    onRetry: () {},
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AppSpacing.space4,
                      ),
                      child: Text(
                        'Loaded chart content area rendered inside AppCard.',
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Dashboard Charts',
      useCases: [
        WidgetbookUseCase(
          name: 'Weight Trend, Weekly Pace & Workouts Charts',
          builder: (context) {
            final includeGainTarget = context.knobs.boolean(
              label: 'Show Target Gain Band',
              initialValue: true,
            );
            final isOutdated = context.knobs.boolean(
              label: 'Show Outdated Warning Badge',
              initialValue: false,
            );

            final state = _buildCatalogDashboardState(
              includeGainTarget: includeGainTarget,
              isWeightOutdated: isOutdated,
              isWorkoutOutdated: isOutdated,
              isGainTargetOutdated: isOutdated,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.space4),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.dashboardMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WeeklyWeightTrendCard(state: state, onRetry: () {}),
                      const SizedBox(height: AppSpacing.relatedGap),
                      WeeklyPaceChartCard(state: state, onRetry: () {}),
                      const SizedBox(height: AppSpacing.relatedGap),
                      WeeklyWorkoutsChartCard(state: state, onRetry: () {}),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'DashboardView',
      useCases: [
        WidgetbookUseCase(
          name: 'Responsive Home Dashboard',
          builder: (context) {
            final weightStatus = context.knobs.object
                .dropdown<DashboardCardStatus>(
                  label: 'Weight Status',
                  options: const [
                    DashboardCardStatus.loaded,
                    DashboardCardStatus.empty,
                    DashboardCardStatus.loading,
                    DashboardCardStatus.error,
                  ],
                  initialOption: DashboardCardStatus.loaded,
                  labelBuilder: (s) => s.name,
                );
            final workoutStatus = context.knobs.object
                .dropdown<DashboardCardStatus>(
                  label: 'Workout Status',
                  options: const [
                    DashboardCardStatus.loaded,
                    DashboardCardStatus.unconfigured,
                    DashboardCardStatus.loading,
                    DashboardCardStatus.error,
                  ],
                  initialOption: DashboardCardStatus.loaded,
                  labelBuilder: (s) => s.name,
                );
            final includeGainTarget = context.knobs.boolean(
              label: 'Include Weekly Gain Target Band',
              initialValue: true,
            );
            final isLatestWeekIncomplete = context.knobs.boolean(
              label: 'Incomplete Current Week Badge',
              initialValue: true,
            );
            final isOutdated = context.knobs.boolean(
              label: 'Simulate Outdated Refresh Warning',
              initialValue: false,
            );

            final catalogState = _buildCatalogDashboardState(
              weightStatus: weightStatus,
              workoutStatus: workoutStatus,
              includeGainTarget: includeGainTarget,
              isLatestWeekIncomplete: isLatestWeekIncomplete,
              isWeightOutdated: isOutdated,
              isWorkoutOutdated: isOutdated,
              isGainTargetOutdated: isOutdated,
            );

            return ProviderScope(
              overrides: [
                authViewModelProvider.overrideWith(
                  _WidgetbookAuthViewModel.new,
                ),
                dashboardViewModelProvider.overrideWith(
                  () => _WidgetbookDashboardViewModel(catalogState),
                ),
              ],
              child: const Scaffold(body: DashboardView()),
            );
          },
        ),
      ],
    ),
  ],
);
