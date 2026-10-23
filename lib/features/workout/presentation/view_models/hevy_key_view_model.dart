import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/providers/secure_storage_provider.dart';
import 'package:bulk_tempo/core/utils/hevy_key_validators.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:bulk_tempo/features/workout/data/repositories/workout_repository_impl.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/hevy_key_form_state.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/workout_progress_view_model.dart';

final hevyKeyViewModelProvider =
    AutoDisposeNotifierProvider<HevyKeyViewModel, HevyKeyFormState>(
      HevyKeyViewModel.new,
    );

/// Pure-Dart ViewModel managing the Hevy API key input form, local UUID format
/// check, remote `/v1/workouts/count` pre-validation, and initial workout load.
class HevyKeyViewModel extends AutoDisposeNotifier<HevyKeyFormState> {
  bool _disposed = false;

  @override
  HevyKeyFormState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
    });

    ref.watch(authViewModelProvider.select((s) => s.user?.id));
    ref.watch(workoutRepositoryProvider);

    return const HevyKeyFormState();
  }

  /// Updates the raw API key input and clears prior validation/submission errors.
  void updateKey(String value) {
    state = state.copyWith(
      rawKey: value,
      status: FormStatus.initial,
      validationError: null,
      submitErrorMessage: null,
    );
  }

  /// Resets the form state to a clean initial state.
  void reset() {
    state = const HevyKeyFormState();
  }

  /// Validates the UUID format locally, pre-validates and saves the key via
  /// [WorkoutRepository.validateAndSaveApiKey], and triggers
  /// [WorkoutProgressViewModel.loadWorkouts] on success.
  Future<bool> submitKey() async {
    final writes = ref.read(secureStorageWritesProvider);
    if (writes.isPaused || state.status == FormStatus.submitting) {
      return false;
    }

    final validationError = HevyKeyValidators.validateKeyInput(state.rawKey);
    if (validationError != null) {
      state = state.copyWith(
        status: FormStatus.failure,
        validationError: validationError,
        submitErrorMessage: null,
      );
      return false;
    }

    final user = ref.read(authViewModelProvider).user;
    if (user == null || user.id.trim().isEmpty) {
      state = state.copyWith(
        status: FormStatus.failure,
        submitErrorMessage: 'User is not authenticated',
        validationError: null,
      );
      return false;
    }

    final targetUserId = user.id;
    final normalizedKey = HevyKeyValidators.normalizeKey(state.rawKey);

    state = state.copyWith(
      status: FormStatus.submitting,
      validationError: null,
      submitErrorMessage: null,
    );

    final repository = ref.read(workoutRepositoryProvider);
    final result = await writes.run(
      () => repository.validateAndSaveApiKey(
        userId: targetUserId,
        apiKey: normalizedKey,
      ),
    );

    if (_disposed) return false;
    if (result == null || writes.isPaused) {
      state = state.copyWith(status: FormStatus.initial);
      return false;
    }
    if (ref.read(authViewModelProvider).user?.id != targetUserId) {
      return false;
    }

    var savedOk = false;
    result.when(
      success: (_) {
        savedOk = true;
        state = state.copyWith(
          status: FormStatus.success,
          validationError: null,
          submitErrorMessage: null,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          status: FormStatus.failure,
          submitErrorMessage: failure.message,
          validationError: null,
        );
      },
    );

    if (!savedOk) {
      return false;
    }

    await ref
        .read(workoutProgressViewModelProvider.notifier)
        .loadWorkouts(showLoading: true);
    return true;
  }
}
