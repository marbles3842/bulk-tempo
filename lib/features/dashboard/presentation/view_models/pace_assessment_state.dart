import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/pace_assessment_entity.dart';

part 'pace_assessment_state.freezed.dart';

/// Presentation status for the contextual AI pace assessment card.
enum PaceAssessmentViewStatus { loading, ineligible, error, loaded }

/// Immutable pure-Dart presentation state for the contextual pace assessment card and report.
@freezed
abstract class PaceAssessmentState with _$PaceAssessmentState {
  const PaceAssessmentState._();

  const factory PaceAssessmentState({
    @Default(PaceAssessmentViewStatus.loading) PaceAssessmentViewStatus status,
    PaceAssessmentEntity? assessment,
    PaceAssessmentIneligibilityReason? ineligibilityReason,
    @Default(0) int recordedWeightWeeksCount,
    @Default(0) int priorWeightWeeksCount,
    @Default(false) bool isRefreshing,
    @Default(false) bool isOutdated,
    String? errorMessage,
    String? refreshErrorMessage,
    String? lastEvaluatedFingerprint,
  }) = _PaceAssessmentState;
}
