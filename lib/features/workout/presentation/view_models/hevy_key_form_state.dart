import 'package:bulk_tempo/features/auth/presentation/view_models/form_status.dart';

export 'package:bulk_tempo/features/auth/presentation/view_models/form_status.dart';

const Object _sentinel = Object();

/// Pure-Dart state for the Hevy API key setup and update form.
class HevyKeyFormState {
  final String rawKey;
  final FormStatus status;
  final String? validationError;
  final String? submitErrorMessage;

  const HevyKeyFormState({
    this.rawKey = '',
    this.status = FormStatus.initial,
    this.validationError,
    this.submitErrorMessage,
  });

  bool get isSubmitting => status == FormStatus.submitting;

  HevyKeyFormState copyWith({
    String? rawKey,
    FormStatus? status,
    Object? validationError = _sentinel,
    bool clearValidationError = false,
    Object? submitErrorMessage = _sentinel,
    bool clearSubmitErrorMessage = false,
  }) {
    return HevyKeyFormState(
      rawKey: rawKey ?? this.rawKey,
      status: status ?? this.status,
      validationError: clearValidationError
          ? null
          : (identical(validationError, _sentinel)
                ? this.validationError
                : validationError as String?),
      submitErrorMessage: clearSubmitErrorMessage
          ? null
          : (identical(submitErrorMessage, _sentinel)
                ? this.submitErrorMessage
                : submitErrorMessage as String?),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HevyKeyFormState &&
          runtimeType == other.runtimeType &&
          rawKey == other.rawKey &&
          status == other.status &&
          validationError == other.validationError &&
          submitErrorMessage == other.submitErrorMessage;

  @override
  int get hashCode =>
      Object.hash(rawKey, status, validationError, submitErrorMessage);

  @override
  String toString() =>
      'HevyKeyFormState(rawKey: $rawKey, status: $status, validationError: $validationError, submitErrorMessage: $submitErrorMessage)';
}
