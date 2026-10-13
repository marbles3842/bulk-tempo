import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/form_status.dart';

export 'package:bulk_tempo/features/auth/presentation/view_models/form_status.dart';

part 'register_form_state.freezed.dart';

@freezed
abstract class RegisterFormState with _$RegisterFormState {
  const RegisterFormState._();

  const factory RegisterFormState({
    @Default('') String email,
    @Default('') String password,
    @Default(FormStatus.initial) FormStatus status,
    String? errorMessage,
    String? emailError,
    String? passwordError,
  }) = _RegisterFormState;

  bool get isValid =>
      emailError == null &&
      passwordError == null &&
      email.trim().isNotEmpty &&
      password.isNotEmpty;
}
