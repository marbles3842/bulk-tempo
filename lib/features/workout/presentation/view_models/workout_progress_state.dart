import 'package:bulk_tempo/features/workout/domain/models/weekly_workout_summary_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_entity.dart';

/// Pure-Dart state representations for the Workout Progress screen and
/// Hevy API integration status.
sealed class WorkoutProgressState {
  const WorkoutProgressState();

  /// Masked Hevy API key if one is currently saved for the user, or `null`
  /// when unconfigured or not yet checked.
  String? get maskedApiKey => null;
}

/// Initial state before the user's saved Hevy API key has been checked.
final class WorkoutProgressInitial extends WorkoutProgressState {
  const WorkoutProgressInitial();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutProgressInitial && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'WorkoutProgressInitial()';
}

/// State when no Hevy API key is saved for the current user.
final class WorkoutProgressUnconfigured extends WorkoutProgressState {
  const WorkoutProgressUnconfigured();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutProgressUnconfigured && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'WorkoutProgressUnconfigured()';
}

/// Loading state while checking the API key or fetching 12-week workout history.
final class WorkoutProgressLoading extends WorkoutProgressState {
  @override
  final String? maskedApiKey;

  const WorkoutProgressLoading({this.maskedApiKey});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutProgressLoading &&
          runtimeType == other.runtimeType &&
          maskedApiKey == other.maskedApiKey;

  @override
  int get hashCode => maskedApiKey.hashCode;

  @override
  String toString() => 'WorkoutProgressLoading(maskedApiKey: $maskedApiKey)';
}

/// Loaded state when a Hevy API key is configured and the 12-week workout
/// history has been fetched and grouped into ISO Monday–Sunday weeks.
final class WorkoutProgressLoaded extends WorkoutProgressState {
  @override
  final String maskedApiKey;

  /// All workouts within the 12-week lookback window sorted newest first.
  final List<WorkoutEntity> workouts;

  /// ISO Monday–Sunday weekly summaries sorted newest week first.
  final List<WeeklyWorkoutSummaryEntity> weeklySummaries;

  /// Non-destructive transient error message populated when a background or
  /// pull-to-refresh sync fails.
  final String? refreshErrorMessage;

  const WorkoutProgressLoaded({
    required this.maskedApiKey,
    required this.workouts,
    required this.weeklySummaries,
    this.refreshErrorMessage,
  });

  /// Whether there are no workouts in the loaded 12-week window.
  bool get isEmpty => weeklySummaries.isEmpty;

  WorkoutProgressLoaded copyWith({
    String? maskedApiKey,
    List<WorkoutEntity>? workouts,
    List<WeeklyWorkoutSummaryEntity>? weeklySummaries,
    String? refreshErrorMessage,
    bool clearRefreshError = false,
  }) {
    return WorkoutProgressLoaded(
      maskedApiKey: maskedApiKey ?? this.maskedApiKey,
      workouts: workouts ?? this.workouts,
      weeklySummaries: weeklySummaries ?? this.weeklySummaries,
      refreshErrorMessage: clearRefreshError
          ? null
          : (refreshErrorMessage ?? this.refreshErrorMessage),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WorkoutProgressLoaded || runtimeType != other.runtimeType) {
      return false;
    }
    if (maskedApiKey != other.maskedApiKey ||
        refreshErrorMessage != other.refreshErrorMessage ||
        workouts.length != other.workouts.length ||
        weeklySummaries.length != other.weeklySummaries.length) {
      return false;
    }
    for (int i = 0; i < workouts.length; i++) {
      if (workouts[i] != other.workouts[i]) return false;
    }
    for (int i = 0; i < weeklySummaries.length; i++) {
      if (weeklySummaries[i] != other.weeklySummaries[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    maskedApiKey,
    Object.hashAll(workouts),
    Object.hashAll(weeklySummaries),
    refreshErrorMessage,
  );

  @override
  String toString() =>
      'WorkoutProgressLoaded(maskedApiKey: $maskedApiKey, workouts: ${workouts.length}, weeklySummaries: ${weeklySummaries.length}, refreshErrorMessage: $refreshErrorMessage)';
}

/// Terminal error state when the initial workout history fetch fails.
final class WorkoutProgressError extends WorkoutProgressState {
  final String message;

  @override
  final String? maskedApiKey;

  const WorkoutProgressError({required this.message, this.maskedApiKey});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutProgressError &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          maskedApiKey == other.maskedApiKey;

  @override
  int get hashCode => Object.hash(message, maskedApiKey);

  @override
  String toString() =>
      'WorkoutProgressError(message: $message, maskedApiKey: $maskedApiKey)';
}
