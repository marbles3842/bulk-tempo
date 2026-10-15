import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/providers/clock_provider.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';
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

/// Pure-Dart ViewModel that reactively composes weight history, workout progress,
/// and weekly gain target into a unified [DashboardState].
class DashboardViewModel extends AutoDisposeNotifier<DashboardState> {
  @override
  DashboardState build() {
    final user = ref.watch(authViewModelProvider.select((s) => s.user));
    final now = ref.watch(clockProvider)();

    if (user == null) {
      return DashboardState(
        weightStatus: DashboardCardStatus.empty,
        workoutStatus: DashboardCardStatus.unconfigured,
        overview: WeeklyProgressCalculator.calculate(
          allWeightSummaries: const [],
          workoutSummaries: const [],
          now: now,
        ),
      );
    }

    final weightState = ref.watch(weightHistoryViewModelProvider);
    final workoutState = ref.watch(workoutProgressViewModelProvider);
    final gainTargetState = ref.watch(gainTargetViewModelProvider);

    final weightSummaries = weightState is WeightHistoryLoaded
        ? weightState.weeklySummaries
        : const <WeeklyWeightSummaryEntity>[];

    final workoutSummaries = workoutState is WorkoutProgressLoaded
        ? workoutState.weeklySummaries
        : const <WeeklyWorkoutSummaryEntity>[];

    final overview = WeeklyProgressCalculator.calculate(
      allWeightSummaries: weightSummaries,
      workoutSummaries: workoutSummaries,
      now: now,
    );

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

    final isWeightOutdated =
        weightState is WeightHistoryLoaded &&
        weightState.refreshErrorMessage != null;

    final isWorkoutOutdated =
        workoutState is WorkoutProgressLoaded &&
        workoutState.refreshErrorMessage != null;

    final isGainTargetOutdated = gainTargetState.refreshErrorMessage != null;

    final DashboardCardStatus gainTargetStatus = switch (gainTargetState) {
      _ when gainTargetState.isLoading && !gainTargetState.hasLoadedOnce =>
        DashboardCardStatus.loading,
      _
          when gainTargetState.errorMessage != null &&
              !gainTargetState.hasLoadedOnce =>
        DashboardCardStatus.error,
      _ => DashboardCardStatus.loaded,
    };

    final String? gainTargetErrorMessage = gainTargetState.errorMessage;

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

    final hasAnyWorkoutInWindow =
        workoutState is WorkoutProgressLoaded &&
        workoutState.weeklySummaries.isNotEmpty;

    return DashboardState(
      weightStatus: weightStatus,
      workoutStatus: workoutStatus,
      gainTargetStatus: gainTargetStatus,
      isWeightOutdated: isWeightOutdated,
      isWorkoutOutdated: isWorkoutOutdated,
      isGainTargetOutdated: isGainTargetOutdated,
      weightErrorMessage: weightErrorMessage,
      workoutErrorMessage: workoutErrorMessage,
      gainTargetErrorMessage: gainTargetErrorMessage,
      gainTarget: gainTargetState.savedTarget,
      overview: overview,
      hasAnyWorkoutInWindow: hasAnyWorkoutInWindow,
    );
  }

  /// Concurrently initializes the underlying weight, workout, and gain-target ViewModels.
  Future<void> ensureInitialized() async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;
    final now = ref.read(clockProvider)();
    final weightNotifier = ref.read(weightHistoryViewModelProvider.notifier);
    final workoutNotifier = ref.read(workoutProgressViewModelProvider.notifier);
    final gainTargetNotifier = ref.read(gainTargetViewModelProvider.notifier);
    await Future.wait([
      weightNotifier.ensureInitialized(),
      workoutNotifier.ensureInitialized(now: now),
      gainTargetNotifier.ensureInitialized(),
    ]);
  }

  /// Pull-to-refresh coordination across all three data sources without resetting state to full-screen loaders.
  Future<void> refreshAll() async {
    final now = ref.read(clockProvider)();
    final weightNotifier = ref.read(weightHistoryViewModelProvider.notifier);
    final workoutNotifier = ref.read(workoutProgressViewModelProvider.notifier);
    final gainTargetNotifier = ref.read(gainTargetViewModelProvider.notifier);
    await Future.wait([
      weightNotifier.loadEntries(showLoading: false),
      workoutNotifier.loadWorkouts(showLoading: false, now: now),
      gainTargetNotifier.loadTarget(showLoading: false, isRefresh: true),
    ]);
  }

  /// Retries loading weight history entries.
  Future<void> retryWeights() async {
    await ref.read(weightHistoryViewModelProvider.notifier).loadEntries();
  }

  /// Retries loading workout progress history.
  Future<void> retryWorkouts() async {
    final now = ref.read(clockProvider)();
    await ref
        .read(workoutProgressViewModelProvider.notifier)
        .loadWorkouts(now: now);
  }

  /// Retries loading data needed for the weekly pace card (weight history and gain target).
  Future<void> retryPace() async {
    final weightNotifier = ref.read(weightHistoryViewModelProvider.notifier);
    final gainTargetNotifier = ref.read(gainTargetViewModelProvider.notifier);
    await Future.wait([
      weightNotifier.loadEntries(),
      gainTargetNotifier.loadTarget(),
    ]);
  }
}
