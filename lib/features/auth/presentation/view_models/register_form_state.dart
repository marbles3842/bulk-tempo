import 'package:bulk_tempo/features/auth/presentation/view_models/form_status.dart';

export 'package:bulk_tempo/features/auth/presentation/view_models/form_status.dart';

const Object _sentinel = Object();

class RegisterFormState {
  final String email;
  final String password;
  final FormStatus status;
  final String? errorMessage;
  final String? emailError;
  final String? passwordError;

  const RegisterFormState({
    this.email = '',
    this.password = '',
    this.status = FormStatus.initial,
    this.errorMessage,
    this.emailError,
    this.passwordError,
  });

  bool get isValid =>
      emailError == null &&
      passwordError == null &&
      email.trim().isNotEmpty &&
      password.isNotEmpty;

  RegisterFormState copyWith({
    String? email,
    String? password,
    FormStatus? status,
    Object? errorMessage = _sentinel,
    Object? emailError = _sentinel,
    Object? passwordError = _sentinel,
  }) {
    return RegisterFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      status: status ?? this.status,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      emailError: identical(emailError, _sentinel)
          ? this.emailError
          : emailError as String?,
      passwordError: identical(passwordError, _sentinel)
          ? this.passwordError
          : passwordError as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegisterFormState &&
          runtimeType == other.runtimeType &&
          email == other.email &&
          password == other.password &&
          status == other.status &&
          errorMessage == other.errorMessage &&
          emailError == other.emailError &&
          passwordError == other.passwordError;

  @override
  int get hashCode => Object.hash(
    email,
    password,
    status,
    errorMessage,
    emailError,
    passwordError,
  );

  @override
  String toString() =>
      'RegisterFormState(email: $email, status: $status, errorMessage: $errorMessage, emailError: $emailError, passwordError: $passwordError)';
}
