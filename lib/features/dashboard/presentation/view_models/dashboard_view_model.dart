import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/providers/clock_provider.dart';
import 'package:bulk_tempo/features/dashboard/domain/calculators/weekly_progress_calculator.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_state.dart';
import 'package:bulk_tempo/features/gain_target/presentation/view_models/gain_target_view_model.dart';
import 'package:bulk_tempo/features/weight/domain/models/weekly_weight_summary_entity.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_history_state.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_history_view_model.dart';
import 'package:bulk_tempo/features/workout/domain/models/weekly_workout_summary_entity.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/workout_progress_state.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/workout_progress_view_model.dart';

final dashboardViewModelProvider =
    AutoDisposeNotifierProvider<DashboardViewModel, DashboardState>(
      DashboardViewModel.new,
    );

/// Pure-Dart ViewModel reactively composing weight history, workout progress,
/// and gain target states into [DashboardState].
class DashboardViewModel extends AutoDisposeNotifier<DashboardState> {
  @override
  DashboardState build() {
    final weightState = ref.watch(weightHistoryViewModelProvider);
    final workoutState = ref.watch(workoutProgressViewModelProvider);
    final gainTargetState = ref.watch(gainTargetViewModelProvider);
    final clock = ref.watch(clockProvider);
    final now = clock();

    final DashboardCardStatus weightStatus = switch (weightState) {
      WeightHistoryInitial() ||
      WeightHistoryLoading() => DashboardCardStatus.loading,
      WeightHistoryError() => DashboardCardStatus.error,
      WeightHistoryLoaded(:final weeklySummaries) =>
        weeklySummaries.isEmpty
            ? DashboardCardStatus.empty
            : DashboardCardStatus.loaded,
    };

    final DashboardCardStatus workoutStatus = switch (workoutState) {
      WorkoutProgressInitial() ||
      WorkoutProgressLoading() => DashboardCardStatus.loading,
      WorkoutProgressUnconfigured() => DashboardCardStatus.unconfigured,
      WorkoutProgressError() => DashboardCardStatus.error,
      WorkoutProgressLoaded() => DashboardCardStatus.loaded,
    };

    final bool isWeightOutdated =
        weightState is WeightHistoryLoaded &&
        weightState.refreshErrorMessage != null;

    final bool isWorkoutOutdated =
        workoutState is WorkoutProgressLoaded &&
        workoutState.refreshErrorMessage != null;

    final bool isGainTargetOutdated =
        gainTargetState.refreshErrorMessage != null;

    final String? weightErrorMessage = switch (weightState) {
      WeightHistoryError(:final message) => message,
      WeightHistoryLoaded(:final refreshErrorMessage) => refreshErrorMessage,
      _ => null,
    };

    final String? workoutErrorMessage = switch (workoutState) {
      WorkoutProgressError(:final message) => message,
      WorkoutProgressLoaded(:final refreshErrorMessage) => refreshErrorMessage,
      _ => null,
    };

    final gainTarget = gainTargetState.savedTarget;

    final bool hasAnyWorkoutInWindow =
        workoutState is WorkoutProgressLoaded &&
        workoutState.weeklySummaries.isNotEmpty;

    final allWeightSummaries = weightState is WeightHistoryLoaded
        ? weightState.weeklySummaries
        : const <WeeklyWeightSummaryEntity>[];

    final workoutSummaries = workoutState is WorkoutProgressLoaded
        ? workoutState.weeklySummaries
        : const <WeeklyWorkoutSummaryEntity>[];

    final overview = WeeklyProgressCalculator.calculate(
      allWeightSummaries: allWeightSummaries,
      workoutSummaries: workoutSummaries,
      now: now,
    );

    return DashboardState(
      weightStatus: weightStatus,
      workoutStatus: workoutStatus,
      isWeightOutdated: isWeightOutdated,
      isWorkoutOutdated: isWorkoutOutdated,
      isGainTargetOutdated: isGainTargetOutdated,
      weightErrorMessage: weightErrorMessage,
      workoutErrorMessage: workoutErrorMessage,
      gainTarget: gainTarget,
      overview: overview,
      hasAnyWorkoutInWindow: hasAnyWorkoutInWindow,
    );
  }

  /// Concurrently initializes weight history, workout progress, and gain target.
  Future<void> ensureInitialized() async {
    final weightNotifier = ref.read(weightHistoryViewModelProvider.notifier);
    final workoutNotifier = ref.read(workoutProgressViewModelProvider.notifier);
    final gainTargetNotifier = ref.read(gainTargetViewModelProvider.notifier);

    await Future.wait([
      weightNotifier.ensureInitialized(),
      workoutNotifier.ensureInitialized(),
      gainTargetNotifier.ensureInitialized(),
    ]);
  }

  /// Concurrently refreshes weight history, workout progress, and gain target.
  Future<void> refreshAll() async {
    final weightNotifier = ref.read(weightHistoryViewModelProvider.notifier);
    final workoutNotifier = ref.read(workoutProgressViewModelProvider.notifier);
    final gainTargetNotifier = ref.read(gainTargetViewModelProvider.notifier);

    await Future.wait([
      weightNotifier.loadEntries(showLoading: false),
      workoutNotifier.loadWorkouts(showLoading: false),
      gainTargetNotifier.loadTarget(showLoading: false, isRefresh: true),
    ]);
  }

  /// Retries loading weight history entries.
  Future<void> retryWeights() async {
    await ref.read(weightHistoryViewModelProvider.notifier).loadEntries();
  }

  /// Retries loading workouts.
  Future<void> retryWorkouts() async {
    await ref.read(workoutProgressViewModelProvider.notifier).loadWorkouts();
  }
}
