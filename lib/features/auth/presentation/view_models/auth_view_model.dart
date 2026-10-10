import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_state.dart';

final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  AuthViewModel.new,
);

class AuthViewModel extends Notifier<AuthState> {
  StreamSubscription<UserEntity?>? _subscription;

  @override
  AuthState build() {
    final repository = ref.watch(authRepositoryProvider);

    _subscription?.cancel();
    _subscription = repository.authStateChanges().listen(
      (user) {
        state = state.copyWith(
          user: user,
          isInitializing: false,
          errorMessage: null,
        );
      },
      onError: (Object error) {
        state = state.copyWith(
          user: null,
          isInitializing: false,
          errorMessage:
              'Failed to verify authentication status. Please try again.',
        );
      },
    );

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return AuthState(user: repository.currentUser, isInitializing: true);
  }

  Future<void> signOut() async {
    state = state.copyWith(errorMessage: null);
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.signOut();

    result.when(
      success: (_) {
        state = state.copyWith(errorMessage: null);
      },
      failure: (failure) {
        state = state.copyWith(errorMessage: failure.message);
      },
    );
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
