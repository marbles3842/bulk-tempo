import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/form_status.dart';

export 'package:bulk_tempo/features/auth/presentation/view_models/form_status.dart';

part 'login_form_state.freezed.dart';

@freezed
abstract class LoginFormState with _$LoginFormState {
  const LoginFormState._();

  const factory LoginFormState({
    @Default('') String email,
    @Default('') String password,
    @Default(FormStatus.initial) FormStatus status,
    String? errorMessage,
    String? emailError,
    String? passwordError,
  }) = _LoginFormState;

  bool get isValid =>
      emailError == null &&
      passwordError == null &&
      email.trim().isNotEmpty &&
      password.isNotEmpty;
}
