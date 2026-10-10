import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/domain/repositories/auth_repository.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/login_form_state.dart';

final loginViewModelProvider =
    AutoDisposeNotifierProvider<LoginViewModel, LoginFormState>(
      LoginViewModel.new,
    );

class LoginViewModel extends AutoDisposeNotifier<LoginFormState> {
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  late final AuthRepository _repository;

  @override
  LoginFormState build() {
    _repository = ref.watch(authRepositoryProvider);
    return const LoginFormState();
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

    final result = await _repository.signInWithEmailAndPassword(
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
