import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/utils/hevy_key_validators.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:bulk_tempo/features/workout/data/repositories/workout_repository_impl.dart';
import 'package:bulk_tempo/features/workout/domain/models/weekly_workout_summary_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_entity.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/workout_progress_state.dart';

final workoutProgressViewModelProvider =
    NotifierProvider<WorkoutProgressViewModel, WorkoutProgressState>(
      WorkoutProgressViewModel.new,
    );

/// Session-cached pure-Dart ViewModel managing the user's Hevy API key status
/// and 12-week workout progress history across tab switches.
class WorkoutProgressViewModel extends Notifier<WorkoutProgressState> {
  bool _disposed = false;
  int _requestCounter = 0;
  int _minEligibleRequestId = 0;
  int _lastAcceptedRequestId = 0;

  @override
  WorkoutProgressState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
    });

    ref.watch(authViewModelProvider.select((s) => s.user?.id));
    ref.watch(workoutRepositoryProvider);

    _requestCounter = 0;
    _minEligibleRequestId = 0;
    _lastAcceptedRequestId = 0;

    return const WorkoutProgressInitial();
  }

  /// Triggers [loadWorkouts] only when the ViewModel is still in
  /// [WorkoutProgressInitial], preserving session-cached state across tab switches.
  Future<void> ensureInitialized() async {
    if (state is WorkoutProgressInitial) {
      await loadWorkouts();
    }
  }

  /// Reads the saved Hevy API key and fetches 12-week workout history for the
  /// currently authenticated user.
  ///
  /// When [showLoading] is `false` and state is already [WorkoutProgressLoaded],
  /// failures are surfaced non-destructively via
  /// [WorkoutProgressLoaded.refreshErrorMessage] while preserving loaded data.
  Future<void> loadWorkouts({bool showLoading = true}) async {
    final authState = ref.read(authViewModelProvider);
    final user = authState.user;

    if (user == null || user.id.trim().isEmpty) {
      if (!_disposed) {
        state = const WorkoutProgressError(
          message: 'User is not authenticated',
        );
      }
      return;
    }

    final requestUserId = user.id;
    final requestId = ++_requestCounter;
    final existingMaskedKey = state.maskedApiKey;

    if (showLoading || state is! WorkoutProgressLoaded) {
      state = WorkoutProgressLoading(maskedApiKey: existingMaskedKey);
    }

    final repository = ref.read(workoutRepositoryProvider);
    final keyResult = await repository.getSavedApiKey(userId: requestUserId);

    if (_disposed) return;
    if (ref.read(authViewModelProvider).user?.id != requestUserId) return;
    if (requestId < _minEligibleRequestId ||
        requestId < _lastAcceptedRequestId) {
      return;
    }

    String? savedKey;
    var keyReadFailed = false;

    keyResult.when(
      success: (key) {
        savedKey = key;
      },
      failure: (failure) {
        keyReadFailed = true;
        _lastAcceptedRequestId = requestId;
        if (!showLoading && state is WorkoutProgressLoaded) {
          final current = state as WorkoutProgressLoaded;
          state = current.copyWith(refreshErrorMessage: failure.message);
        } else {
          state = WorkoutProgressError(
            message: failure.message,
            maskedApiKey: existingMaskedKey,
          );
        }
      },
    );

    if (keyReadFailed) return;

    if (savedKey == null || savedKey!.trim().isEmpty) {
      _lastAcceptedRequestId = requestId;
      state = const WorkoutProgressUnconfigured();
      return;
    }

    final maskedKey = HevyKeyValidators.maskApiKey(savedKey!);
    if (state is WorkoutProgressLoading) {
      state = WorkoutProgressLoading(maskedApiKey: maskedKey);
    }

    final workoutsResult = await repository.getWorkoutsForLastWeeks(
      userId: requestUserId,
    );

    if (_disposed) return;
    if (ref.read(authViewModelProvider).user?.id != requestUserId) return;
    if (requestId < _minEligibleRequestId ||
        requestId < _lastAcceptedRequestId) {
      return;
    }

    _lastAcceptedRequestId = requestId;

    workoutsResult.when(
      success: (workouts) {
        final weeklySummaries =
            WeeklyWorkoutSummaryEntity.groupWorkoutsByIsoWeek(workouts);
        state = WorkoutProgressLoaded(
          maskedApiKey: maskedKey,
          workouts: List<WorkoutEntity>.unmodifiable(workouts),
          weeklySummaries: List<WeeklyWorkoutSummaryEntity>.unmodifiable(
            weeklySummaries,
          ),
        );
      },
      failure: (failure) {
        if (!showLoading && state is WorkoutProgressLoaded) {
          final current = state as WorkoutProgressLoaded;
          state = current.copyWith(
            maskedApiKey: maskedKey,
            refreshErrorMessage: failure.message,
          );
        } else {
          state = WorkoutProgressError(
            message: failure.message,
            maskedApiKey: maskedKey,
          );
        }
      },
    );
  }

  /// Removes the saved Hevy API key for the current user and transitions state
  /// to [WorkoutProgressUnconfigured].
  Future<bool> disconnectApiKey() async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null || user.id.trim().isEmpty) {
      return false;
    }

    final requestUserId = user.id;
    _minEligibleRequestId = _requestCounter + 1;

    final repository = ref.read(workoutRepositoryProvider);
    final result = await repository.clearApiKey(userId: requestUserId);

    if (_disposed) return false;
    if (ref.read(authViewModelProvider).user?.id != requestUserId) {
      return false;
    }

    return result.when(
      success: (_) {
        state = const WorkoutProgressUnconfigured();
        return true;
      },
      failure: (failure) {
        if (state is WorkoutProgressLoaded) {
          final current = state as WorkoutProgressLoaded;
          state = current.copyWith(refreshErrorMessage: failure.message);
        } else {
          state = WorkoutProgressError(
            message: failure.message,
            maskedApiKey: state.maskedApiKey,
          );
        }
        return false;
      },
    );
  }

  /// Clears any transient pull-to-refresh error on [WorkoutProgressLoaded].
  void clearRefreshError() {
    if (state is WorkoutProgressLoaded) {
      final current = state as WorkoutProgressLoaded;
      state = current.copyWith(clearRefreshError: true);
    }
  }
}
