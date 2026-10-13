import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bulk_tempo/features/workout/domain/models/weekly_workout_summary_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_entity.dart';

part 'workout_progress_state.freezed.dart';

/// Pure-Dart state representations for the Workout Progress screen and
/// Hevy API integration status.
@freezed
sealed class WorkoutProgressState with _$WorkoutProgressState {
  const WorkoutProgressState._();

  /// Masked Hevy API key if one is currently saved for the user, or `null`
  /// when unconfigured or not yet checked.
  String? get maskedApiKey => whenOrNull(
    loading: (maskedApiKey) => maskedApiKey,
    loaded: (maskedApiKey, workouts, weeklySummaries, refreshErrorMessage) =>
        maskedApiKey,
    error: (message, maskedApiKey) => maskedApiKey,
  );

  const factory WorkoutProgressState.initial() = WorkoutProgressInitial;
  const factory WorkoutProgressState.unconfigured() =
      WorkoutProgressUnconfigured;
  const factory WorkoutProgressState.loading({String? maskedApiKey}) =
      WorkoutProgressLoading;
  const factory WorkoutProgressState.loaded({
    required String maskedApiKey,
    required List<WorkoutEntity> workouts,
    required List<WeeklyWorkoutSummaryEntity> weeklySummaries,
    String? refreshErrorMessage,
  }) = WorkoutProgressLoaded;
  const factory WorkoutProgressState.error({
    required String message,
    String? maskedApiKey,
  }) = WorkoutProgressError;
}

extension WorkoutProgressLoadedX on WorkoutProgressLoaded {
  /// Whether there are no workouts in the loaded 12-week window.
  bool get isEmpty => weeklySummaries.isEmpty;
}
