import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/form_status.dart';

export 'package:bulk_tempo/features/auth/presentation/view_models/form_status.dart';

part 'hevy_key_form_state.freezed.dart';

/// Pure-Dart state for the Hevy API key setup and update form.
@freezed
abstract class HevyKeyFormState with _$HevyKeyFormState {
  const HevyKeyFormState._();

  const factory HevyKeyFormState({
    @Default('') String rawKey,
    @Default(FormStatus.initial) FormStatus status,
    String? validationError,
    String? submitErrorMessage,
  }) = _HevyKeyFormState;

  bool get isSubmitting => status == FormStatus.submitting;
}
