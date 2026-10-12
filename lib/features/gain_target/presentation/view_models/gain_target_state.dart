import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';

/// Immutable presentation state for the weekly gain target profile section.
class GainTargetState {
  /// Confirmed server target, or `null` if no target is currently set.
  final GainTargetEntity? savedTarget;

  /// Raw text input for minimum weekly gain rate.
  final String minInput;

  /// Raw text input for maximum weekly gain rate.
  final String maxInput;

  /// Field-level validation error message for minimum input.
  final String? minError;

  /// Field-level validation error message for maximum input.
  final String? maxError;

  /// Range ordering validation error message (e.g. min >= max).
  final String? rangeError;

  /// True during initial data loading from repository.
  final bool isLoading;

  /// True during explicit user pull-to-refresh / button refresh.
  final bool isRefreshing;

  /// True while a save operation is pending server confirmation.
  final bool isSubmitting;

  /// Candidate entity submitted to server, kept until confirmed or rejected.
  final GainTargetEntity? pendingTarget;

  /// Fatal error message for initial load failure.
  final String? errorMessage;

  /// Transient error message during refresh failure (preserving visible data).
  final String? refreshErrorMessage;

  /// Transient error message during save failure (preserving draft for retry).
  final String? saveErrorMessage;

  /// Transient success message upon acknowledged server save.
  final String? successMessage;

  /// True when the user has edited inputs since load or save.
  final bool isDirty;

  /// Authenticated user identifier this state belongs to.
  final String? userId;

  /// True if gain target has completed at least one load attempt in the current session.
  final bool hasLoadedOnce;

  const GainTargetState({
    this.savedTarget,
    this.minInput = '',
    this.maxInput = '',
    this.minError,
    this.maxError,
    this.rangeError,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isSubmitting = false,
    this.pendingTarget,
    this.errorMessage,
    this.refreshErrorMessage,
    this.saveErrorMessage,
    this.successMessage,
    this.isDirty = false,
    this.userId,
    this.hasLoadedOnce = false,
  });

  /// Effective error for the maximum input field, combining [maxError] and [rangeError].
  String? get effectiveMaxError => maxError ?? rangeError;

  /// True if a target has been confirmed by the server.
  bool get hasSavedTarget => savedTarget != null;

  /// Formatted target summary string, e.g. '0.15–0.25 kg/week' or 'No target set'.
  String get summaryText => savedTarget?.displayText ?? 'No target set';

  GainTargetState copyWith({
    GainTargetEntity? savedTarget,
    bool clearSavedTarget = false,
    String? minInput,
    String? maxInput,
    String? minError,
    bool clearMinError = false,
    String? maxError,
    bool clearMaxError = false,
    String? rangeError,
    bool clearRangeError = false,
    bool? isLoading,
    bool? isRefreshing,
    bool? isSubmitting,
    GainTargetEntity? pendingTarget,
    bool clearPendingTarget = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? refreshErrorMessage,
    bool clearRefreshErrorMessage = false,
    String? saveErrorMessage,
    bool clearSaveErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
    bool? isDirty,
    String? userId,
    bool? hasLoadedOnce,
  }) {
    return GainTargetState(
      savedTarget: clearSavedTarget ? null : (savedTarget ?? this.savedTarget),
      minInput: minInput ?? this.minInput,
      maxInput: maxInput ?? this.maxInput,
      minError: clearMinError ? null : (minError ?? this.minError),
      maxError: clearMaxError ? null : (maxError ?? this.maxError),
      rangeError: clearRangeError ? null : (rangeError ?? this.rangeError),
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      pendingTarget: clearPendingTarget
          ? null
          : (pendingTarget ?? this.pendingTarget),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      refreshErrorMessage: clearRefreshErrorMessage
          ? null
          : (refreshErrorMessage ?? this.refreshErrorMessage),
      saveErrorMessage: clearSaveErrorMessage
          ? null
          : (saveErrorMessage ?? this.saveErrorMessage),
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
      isDirty: isDirty ?? this.isDirty,
      userId: userId ?? this.userId,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GainTargetState &&
          runtimeType == other.runtimeType &&
          savedTarget == other.savedTarget &&
          minInput == other.minInput &&
          maxInput == other.maxInput &&
          minError == other.minError &&
          maxError == other.maxError &&
          rangeError == other.rangeError &&
          isLoading == other.isLoading &&
          isRefreshing == other.isRefreshing &&
          isSubmitting == other.isSubmitting &&
          pendingTarget == other.pendingTarget &&
          errorMessage == other.errorMessage &&
          refreshErrorMessage == other.refreshErrorMessage &&
          saveErrorMessage == other.saveErrorMessage &&
          successMessage == other.successMessage &&
          isDirty == other.isDirty &&
          userId == other.userId &&
          hasLoadedOnce == other.hasLoadedOnce;

  @override
  int get hashCode => Object.hashAll([
    savedTarget,
    minInput,
    maxInput,
    minError,
    maxError,
    rangeError,
    isLoading,
    isRefreshing,
    isSubmitting,
    pendingTarget,
    errorMessage,
    refreshErrorMessage,
    saveErrorMessage,
    successMessage,
    isDirty,
    userId,
    hasLoadedOnce,
  ]);

  @override
  String toString() =>
      'GainTargetState('
      'savedTarget: $savedTarget, '
      'minInput: "$minInput", '
      'maxInput: "$maxInput", '
      'minError: $minError, '
      'maxError: $maxError, '
      'rangeError: $rangeError, '
      'isLoading: $isLoading, '
      'isRefreshing: $isRefreshing, '
      'isSubmitting: $isSubmitting, '
      'pendingTarget: $pendingTarget, '
      'errorMessage: $errorMessage, '
      'refreshErrorMessage: $refreshErrorMessage, '
      'saveErrorMessage: $saveErrorMessage, '
      'successMessage: $successMessage, '
      'isDirty: $isDirty, '
      'userId: $userId, '
      'hasLoadedOnce: $hasLoadedOnce)';
}
