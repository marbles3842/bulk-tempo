import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';

part 'gain_target_state.freezed.dart';

/// Immutable presentation state for the weekly gain target profile section.
@freezed
abstract class GainTargetState with _$GainTargetState {
  const GainTargetState._();

  const factory GainTargetState({
    GainTargetEntity? savedTarget,
    @Default('') String minInput,
    @Default('') String maxInput,
    String? minError,
    String? maxError,
    String? rangeError,
    @Default(false) bool isLoading,
    @Default(false) bool isRefreshing,
    @Default(false) bool isSubmitting,
    GainTargetEntity? pendingTarget,
    String? errorMessage,
    String? refreshErrorMessage,
    String? saveErrorMessage,
    String? successMessage,
    @Default(false) bool isDirty,
    String? userId,
  }) = _GainTargetState;

  /// Effective error for the maximum input field, combining [maxError] and [rangeError].
  String? get effectiveMaxError => maxError ?? rangeError;

  /// True if a target has been confirmed by the server.
  bool get hasSavedTarget => savedTarget != null;

  /// Formatted target summary string, e.g. '0.15–0.25 kg/week' or 'No target set'.
  String get summaryText => savedTarget?.displayText ?? 'No target set';
}
