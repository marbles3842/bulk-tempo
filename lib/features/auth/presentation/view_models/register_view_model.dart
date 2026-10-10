import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/features/auth/domain/repositories/auth_repository.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/register_form_state.dart';

final registerViewModelProvider =
    AutoDisposeNotifierProvider<RegisterViewModel, RegisterFormState>(
      RegisterViewModel.new,
    );

class RegisterViewModel extends AutoDisposeNotifier<RegisterFormState> {
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  late final AuthRepository _repository;

  @override
  RegisterFormState build() {
    _repository = ref.watch(authRepositoryProvider);
    return const RegisterFormState();
  }

  void updateEmail(String email) {
    state = state.copyWith(email: email, emailError: null, errorMessage: null);
  }

  void updatePassword(String password) {
    state = state.copyWith(
      password: password,
      passwordError: null,
      errorMessage: null,
    );
  }

  Future<void> submit() async {
    if (state.status == FormStatus.submitting) return;

    final trimmedEmail = state.email.trim();
    String? emailError;
    if (trimmedEmail.isEmpty) {
      emailError = 'Email is required';
    } else if (!_emailRegex.hasMatch(trimmedEmail)) {
      emailError = 'Please enter a valid email address';
    }

    String? passwordError;
    if (state.password.isEmpty) {
      passwordError = 'Password is required';
    } else if (state.password.length < 6) {
      passwordError = 'Password must be at least 6 characters';
    }

    if (emailError != null || passwordError != null) {
      state = state.copyWith(
        status: FormStatus.failure,
        emailError: emailError,
        passwordError: passwordError,
      );
      return;
    }

    state = state.copyWith(
      status: FormStatus.submitting,
      emailError: null,
      passwordError: null,
      errorMessage: null,
    );

    final result = await _repository.signUpWithEmailAndPassword(
      email: trimmedEmail,
      password: state.password,
    );

    result.when(
      success: (_) {
        state = state.copyWith(status: FormStatus.success, errorMessage: null);
      },
      failure: (failure) {
        state = state.copyWith(
          status: FormStatus.failure,
          errorMessage: failure.message,
        );
      },
    );
  }
}
