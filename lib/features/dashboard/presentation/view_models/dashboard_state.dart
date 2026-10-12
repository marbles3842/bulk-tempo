import 'package:bulk_tempo/features/dashboard/domain/models/weekly_progress_overview_entity.dart';
import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';

/// Card-level lifecycle and presentation status.
enum DashboardCardStatus { loading, error, unconfigured, empty, loaded }

/// Pure Dart immutable representation of the dashboard state composing
/// weight history, workout progress, and gain target feature states.
class DashboardState {
  final DashboardCardStatus weightStatus;
  final DashboardCardStatus workoutStatus;
  final bool isWeightOutdated;
  final bool isWorkoutOutdated;
  final bool isGainTargetOutdated;
  final String? weightErrorMessage;
  final String? workoutErrorMessage;
  final GainTargetEntity? gainTarget;
  final WeeklyProgressOverviewEntity overview;
  final bool hasAnyWorkoutInWindow;

  const DashboardState({
    required this.weightStatus,
    required this.workoutStatus,
    this.isWeightOutdated = false,
    this.isWorkoutOutdated = false,
    this.isGainTargetOutdated = false,
    this.weightErrorMessage,
    this.workoutErrorMessage,
    this.gainTarget,
    required this.overview,
    this.hasAnyWorkoutInWindow = false,
  });

  DashboardState copyWith({
    DashboardCardStatus? weightStatus,
    DashboardCardStatus? workoutStatus,
    bool? isWeightOutdated,
    bool? isWorkoutOutdated,
    bool? isGainTargetOutdated,
    String? weightErrorMessage,
    bool clearWeightErrorMessage = false,
    String? workoutErrorMessage,
    bool clearWorkoutErrorMessage = false,
    GainTargetEntity? gainTarget,
    bool clearGainTarget = false,
    WeeklyProgressOverviewEntity? overview,
    bool? hasAnyWorkoutInWindow,
  }) {
    return DashboardState(
      weightStatus: weightStatus ?? this.weightStatus,
      workoutStatus: workoutStatus ?? this.workoutStatus,
      isWeightOutdated: isWeightOutdated ?? this.isWeightOutdated,
      isWorkoutOutdated: isWorkoutOutdated ?? this.isWorkoutOutdated,
      isGainTargetOutdated: isGainTargetOutdated ?? this.isGainTargetOutdated,
      weightErrorMessage: clearWeightErrorMessage
          ? null
          : (weightErrorMessage ?? this.weightErrorMessage),
      workoutErrorMessage: clearWorkoutErrorMessage
          ? null
          : (workoutErrorMessage ?? this.workoutErrorMessage),
      gainTarget: clearGainTarget ? null : (gainTarget ?? this.gainTarget),
      overview: overview ?? this.overview,
      hasAnyWorkoutInWindow:
          hasAnyWorkoutInWindow ?? this.hasAnyWorkoutInWindow,
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
          isGainTargetOutdated == other.isGainTargetOutdated &&
          weightErrorMessage == other.weightErrorMessage &&
          workoutErrorMessage == other.workoutErrorMessage &&
          gainTarget == other.gainTarget &&
          overview == other.overview &&
          hasAnyWorkoutInWindow == other.hasAnyWorkoutInWindow;

  @override
  int get hashCode => Object.hash(
    weightStatus,
    workoutStatus,
    isWeightOutdated,
    isWorkoutOutdated,
    isGainTargetOutdated,
    weightErrorMessage,
    workoutErrorMessage,
    gainTarget,
    overview,
    hasAnyWorkoutInWindow,
  );

  @override
  String toString() =>
      'DashboardState('
      'weightStatus: $weightStatus, '
      'workoutStatus: $workoutStatus, '
      'isWeightOutdated: $isWeightOutdated, '
      'isWorkoutOutdated: $isWorkoutOutdated, '
      'isGainTargetOutdated: $isGainTargetOutdated, '
      'weightErrorMessage: $weightErrorMessage, '
      'workoutErrorMessage: $workoutErrorMessage, '
      'gainTarget: $gainTarget, '
      'overview: $overview, '
      'hasAnyWorkoutInWindow: $hasAnyWorkoutInWindow)';
}
