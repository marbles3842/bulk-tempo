import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:bulk_tempo/features/gain_target/data/repositories/gain_target_repository_impl.dart';
import 'package:bulk_tempo/features/gain_target/domain/repositories/gain_target_repository.dart';
import 'package:bulk_tempo/features/gain_target/domain/validation/gain_target_validator.dart';
import 'package:bulk_tempo/features/gain_target/presentation/view_models/gain_target_state.dart';

final gainTargetViewModelProvider =
    StateNotifierProvider<GainTargetViewModel, GainTargetState>((ref) {
      final repository = ref.watch(gainTargetRepositoryProvider);
      final userId = ref.watch(authViewModelProvider.select((s) => s.user?.id));
      return GainTargetViewModel(repository: repository, userId: userId);
    });

/// Pure-Dart ViewModel coordinating weekly gain target reads, edits, validation,
/// server saves, and account isolation without UI dependencies.
class GainTargetViewModel extends StateNotifier<GainTargetState> {
  final GainTargetRepository repository;
  String? _userId;
  int _generation = 0;

  GainTargetViewModel({required this.repository, String? userId})
    : _userId = userId,
      super(GainTargetState(userId: userId));

  /// Loads the weekly gain target for the current authenticated user.
  ///
  /// When [isRefresh] is true, preserves dirty draft inputs and existing confirmed target,
  /// routing errors to [GainTargetState.refreshErrorMessage].
  /// When [showLoading] is true and not a refresh, sets [GainTargetState.isLoading] = true.
  /// Suppresses reads if a save is currently pending ([GainTargetState.isSubmitting]).
  Future<void> loadTarget({
    bool showLoading = true,
    bool isRefresh = false,
  }) async {
    if (state.isSubmitting) {
      return;
    }

    final currentUserId = _userId;
    if (currentUserId == null || currentUserId.trim().isEmpty) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: 'User is not authenticated',
      );
      return;
    }

    final generation = ++_generation;

    if (isRefresh) {
      state = state.copyWith(
        isRefreshing: true,
        clearRefreshErrorMessage: true,
      );
    } else if (showLoading) {
      state = state.copyWith(isLoading: true, clearErrorMessage: true);
    }

    final result = await repository.getGainTarget(userId: currentUserId);

    if (!mounted || generation != _generation || _userId != currentUserId) {
      return;
    }

    if (state.isSubmitting) {
      return;
    }

    result.when(
      success: (target) {
        if (state.isDirty) {
          state = state.copyWith(
            savedTarget: target,
            clearSavedTarget: target == null,
            isLoading: false,
            isRefreshing: false,
            clearErrorMessage: true,
            clearRefreshErrorMessage: true,
          );
        } else {
          state = state.copyWith(
            savedTarget: target,
            clearSavedTarget: target == null,
            isLoading: false,
            isRefreshing: false,
            minInput: target != null
                ? target.minWeeklyGainKg.toStringAsFixed(2)
                : '',
            maxInput: target != null
                ? target.maxWeeklyGainKg.toStringAsFixed(2)
                : '',
            clearMinError: true,
            clearMaxError: true,
            clearRangeError: true,
            clearErrorMessage: true,
            clearRefreshErrorMessage: true,
          );
        }
      },
      failure: (failure) {
        if (isRefresh) {
          state = state.copyWith(
            isRefreshing: false,
            refreshErrorMessage: failure.message,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          );
        }
      },
    );
  }

  /// Updates minimum input, marks state dirty, and validates field.
  void updateMinInput(String value) {
    final minError = GainTargetValidator.validateMinInput(value);
    final parsedMin = GainTargetValidator.parseGainRate(value);
    final parsedMax = GainTargetValidator.parseGainRate(state.maxInput);
    final rangeError =
        (minError == null && parsedMin != null && parsedMax != null)
        ? GainTargetValidator.validateRange(parsedMin, parsedMax)
        : null;

    state = state.copyWith(
      minInput: value,
      isDirty: true,
      minError: minError,
      clearMinError: minError == null,
      rangeError: rangeError,
      clearRangeError: rangeError == null,
      clearSaveErrorMessage: true,
      clearSuccessMessage: true,
    );
  }

  /// Updates maximum input, marks state dirty, and validates field.
  void updateMaxInput(String value) {
    final maxError = GainTargetValidator.validateMaxInput(value);
    final parsedMin = GainTargetValidator.parseGainRate(state.minInput);
    final parsedMax = GainTargetValidator.parseGainRate(value);
    final rangeError =
        (maxError == null && parsedMin != null && parsedMax != null)
        ? GainTargetValidator.validateRange(parsedMin, parsedMax)
        : null;

    state = state.copyWith(
      maxInput: value,
      isDirty: true,
      maxError: maxError,
      clearMaxError: maxError == null,
      rangeError: rangeError,
      clearRangeError: rangeError == null,
      clearSaveErrorMessage: true,
      clearSuccessMessage: true,
    );
  }

  /// Validates inputs and persists weekly gain target to repository.
  ///
  /// Rejects duplicate submissions if already submitting.
  Future<void> saveTarget() async {
    if (state.isSubmitting) return;

    final validationResult = GainTargetValidator.validateInputs(
      state.minInput,
      state.maxInput,
    );

    if (!validationResult.isValid) {
      state = state.copyWith(
        minError: validationResult.minError,
        clearMinError: validationResult.minError == null,
        maxError: validationResult.maxError,
        clearMaxError: validationResult.maxError == null,
        rangeError: validationResult.rangeError,
        clearRangeError: validationResult.rangeError == null,
      );
      return;
    }

    final validTarget = validationResult.target!;
    final currentUserId = _userId;
    if (currentUserId == null || currentUserId.trim().isEmpty) {
      state = state.copyWith(saveErrorMessage: 'User is not authenticated');
      return;
    }

    final generation = ++_generation;

    state = state.copyWith(
      isSubmitting: true,
      pendingTarget: validTarget,
      clearSaveErrorMessage: true,
      clearSuccessMessage: true,
      clearMinError: true,
      clearMaxError: true,
      clearRangeError: true,
    );

    final result = await repository.saveGainTarget(
      userId: currentUserId,
      target: validTarget,
    );

    if (!mounted || generation != _generation || _userId != currentUserId) {
      return;
    }

    result.when(
      success: (saved) {
        state = state.copyWith(
          savedTarget: saved,
          isSubmitting: false,
          clearPendingTarget: true,
          isDirty: false,
          successMessage: 'Weekly gain target saved successfully',
          minInput: saved.minWeeklyGainKg.toStringAsFixed(2),
          maxInput: saved.maxWeeklyGainKg.toStringAsFixed(2),
          clearMinError: true,
          clearMaxError: true,
          clearRangeError: true,
          clearSaveErrorMessage: true,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          isSubmitting: false,
          clearPendingTarget: true,
          saveErrorMessage: failure.message,
        );
      },
    );
  }

  /// Resets input fields back to the last confirmed target (or empty if none),
  /// clears validation errors, and sets [GainTargetState.isDirty] = false.
  ///
  /// Does NOT discard if a save is currently pending.
  void discardDraft() {
    if (!mounted || state.isSubmitting || !state.isDirty) return;

    final saved = state.savedTarget;
    state = state.copyWith(
      minInput: saved != null ? saved.minWeeklyGainKg.toStringAsFixed(2) : '',
      maxInput: saved != null ? saved.maxWeeklyGainKg.toStringAsFixed(2) : '',
      isDirty: false,
      clearMinError: true,
      clearMaxError: true,
      clearRangeError: true,
      clearSaveErrorMessage: true,
    );
  }

  /// Clears transient feedback messages.
  void clearMessages() {
    state = state.copyWith(
      clearSuccessMessage: true,
      clearSaveErrorMessage: true,
      clearRefreshErrorMessage: true,
    );
  }

  /// Clears fatal initial-load error message.
  void clearErrorMessage() {
    state = state.copyWith(clearErrorMessage: true);
  }

  /// Resets ViewModel state and captures a new user context.
  void onUserChanged(String? newUserId) {
    if (_userId == newUserId) return;
    _userId = newUserId;
    _generation++;
    state = GainTargetState(userId: newUserId);
  }

  /// Alias for [onUserChanged].
  void updateUserId(String? newUserId) => onUserChanged(newUserId);
}
