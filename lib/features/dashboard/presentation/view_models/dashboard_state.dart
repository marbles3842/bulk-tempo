import 'package:bulk_tempo/features/dashboard/domain/models/weekly_progress_overview_entity.dart';

/// Card-level lifecycle and presentation status.
enum DashboardCardStatus { loading, error, unconfigured, empty, loaded }

/// Pure Dart immutable representation of the dashboard state composing
/// weight history and workout progress feature states.
class DashboardState {
  final DashboardCardStatus weightStatus;
  final DashboardCardStatus workoutStatus;
  final bool isWeightOutdated;
  final bool isWorkoutOutdated;
  final String? weightErrorMessage;
  final String? workoutErrorMessage;
  final WeeklyProgressOverviewEntity overview;

  const DashboardState({
    required this.weightStatus,
    required this.workoutStatus,
    this.isWeightOutdated = false,
    this.isWorkoutOutdated = false,
    this.weightErrorMessage,
    this.workoutErrorMessage,
    required this.overview,
  });

  DashboardState copyWith({
    DashboardCardStatus? weightStatus,
    DashboardCardStatus? workoutStatus,
    bool? isWeightOutdated,
    bool? isWorkoutOutdated,
    String? weightErrorMessage,
    bool clearWeightErrorMessage = false,
    String? workoutErrorMessage,
    bool clearWorkoutErrorMessage = false,
    WeeklyProgressOverviewEntity? overview,
  }) {
    return DashboardState(
      weightStatus: weightStatus ?? this.weightStatus,
      workoutStatus: workoutStatus ?? this.workoutStatus,
      isWeightOutdated: isWeightOutdated ?? this.isWeightOutdated,
      isWorkoutOutdated: isWorkoutOutdated ?? this.isWorkoutOutdated,
      weightErrorMessage: clearWeightErrorMessage
          ? null
          : (weightErrorMessage ?? this.weightErrorMessage),
      workoutErrorMessage: clearWorkoutErrorMessage
          ? null
          : (workoutErrorMessage ?? this.workoutErrorMessage),
      overview: overview ?? this.overview,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardState &&
          runtimeType == other.runtimeType &&
          weightStatus == other.weightStatus &&
          workoutStatus == other.workoutStatus &&
          isWeightOutdated == other.isWeightOutdated &&
          isWorkoutOutdated == other.isWorkoutOutdated &&
          weightErrorMessage == other.weightErrorMessage &&
          workoutErrorMessage == other.workoutErrorMessage &&
          overview == other.overview;

  @override
  int get hashCode => Object.hash(
    weightStatus,
    workoutStatus,
    isWeightOutdated,
    isWorkoutOutdated,
    weightErrorMessage,
    workoutErrorMessage,
    overview,
  );

  @override
  String toString() =>
      'DashboardState('
      'weightStatus: $weightStatus, '
      'workoutStatus: $workoutStatus, '
      'isWeightOutdated: $isWeightOutdated, '
      'isWorkoutOutdated: $isWorkoutOutdated, '
      'weightErrorMessage: $weightErrorMessage, '
      'workoutErrorMessage: $workoutErrorMessage, '
      'overview: $overview)';
}
