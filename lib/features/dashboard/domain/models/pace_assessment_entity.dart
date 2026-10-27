import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';

part 'pace_assessment_entity.freezed.dart';

/// Four classification statuses for weekly weight-gain pace.
enum PaceAssessmentStatus { onTarget, tooFast, tooSlow, stagnant }

/// Reasons why a contextual pace assessment cannot yet be generated.
enum PaceAssessmentIneligibilityReason {
  unauthenticated,
  missingGainTarget,
  workoutUnconfigured,
  noWorkoutsInWindow,
  insufficientWeightWeeks,
}

/// Aggregated weekly performance for a single exercise across all workouts in an ISO week.
@freezed
abstract class WeeklyExercisePerformanceEntity
    with _$WeeklyExercisePerformanceEntity {
  const WeeklyExercisePerformanceEntity._();

  const factory WeeklyExercisePerformanceEntity({
    required String exerciseTemplateId,
    required String title,
    required int workingSetsCount,
    required double totalVolumeKg,
    double? bestWeightKg,
    int? bestReps,
  }) = _WeeklyExercisePerformanceEntity;
}

/// Combined weight and workout context for a single ISO week in the evaluation window.
@freezed
abstract class AssessedWeekContextEntity with _$AssessedWeekContextEntity {
  const AssessedWeekContextEntity._();

  const factory AssessedWeekContextEntity({
    required String weekStartIso,
    required DateTime weekStartMonday,
    required DateTime weekEndSunday,
    double? averageWeightKg,
    required int loggedWeightDaysCount,
    required bool isCurrentWeek,
    required bool isPartialWeek,
    double? paceKgPerWeek,
    required int workoutCount,
    required int totalWorkingSets,
    required double totalVolumeKg,
    required List<WeeklyExercisePerformanceEntity> exercises,
  }) = _AssessedWeekContextEntity;
}

/// Complete domain input context required to look up or generate a contextual pace assessment.
@freezed
abstract class PaceAssessmentInputEntity with _$PaceAssessmentInputEntity {
  const PaceAssessmentInputEntity._();

  const factory PaceAssessmentInputEntity({
    required String fingerprint,
    required String localeCode,
    required GainTargetEntity gainTarget,
    required PaceAssessmentStatus baselineStatus,
    required double currentPaceKgPerWeek,
    required AssessedWeekContextEntity assessedWeek,
    required List<AssessedWeekContextEntity> priorWeeks,
  }) = _PaceAssessmentInputEntity;
}

/// Domain entity representing the generated contextual AI pace assessment and report.
@freezed
abstract class PaceAssessmentEntity with _$PaceAssessmentEntity {
  const PaceAssessmentEntity._();

  const factory PaceAssessmentEntity({
    required PaceAssessmentStatus status,
    required PaceAssessmentStatus baselineStatus,
    required String headlineSummary,
    required String weightTrendAnalysis,
    required String workoutContextAnalysis,
    required List<String> actionableTakeaways,
    required String assessedWeekStartIso,
    required bool isAssessedWeekPartial,
    required double currentPaceKgPerWeek,
    required double targetMinKgPerWeek,
    required double targetMaxKgPerWeek,
    required int priorWeightWeeksCount,
    required String localeCode,
    required String fingerprint,
    required DateTime generatedAt,
  }) = _PaceAssessmentEntity;
}
