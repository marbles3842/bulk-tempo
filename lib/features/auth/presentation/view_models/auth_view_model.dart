import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/localization/locale_provider.dart';
import 'package:bulk_tempo/core/providers/secure_storage_provider.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_state.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_view_model.dart';
import 'package:bulk_tempo/features/gain_target/presentation/view_models/gain_target_view_model.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_entry_view_model.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_history_view_model.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/hevy_key_view_model.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/workout_progress_view_model.dart';

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

    try {
      final storage = ref.read(secureStorageProvider);
      await storage.deleteAll();
    } catch (_) {
      // Fail-open: errors during storage wipe must not block sign-out.
    }

    final repository = ref.read(authRepositoryProvider);
    final result = await repository.signOut();

    result.when(
      success: (_) {
        final container = ref.container;
        container.invalidate(workoutProgressViewModelProvider);
        container.invalidate(hevyKeyViewModelProvider);
        container.invalidate(weightHistoryViewModelProvider);
        container.invalidate(weightEntryViewModelProvider);
        container.invalidate(gainTargetViewModelProvider);
        container.invalidate(dashboardViewModelProvider);
        container.invalidate(localeProvider);

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
