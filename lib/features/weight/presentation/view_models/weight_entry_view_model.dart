import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/core/utils/weight_validators.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/form_status.dart';
import 'package:bulk_tempo/features/weight/data/repositories/weight_repository_impl.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_entry_form_state.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_history_state.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_history_view_model.dart';

final weightEntryViewModelProvider =
    AutoDisposeNotifierProvider<WeightEntryViewModel, WeightEntryFormState>(
      WeightEntryViewModel.new,
    );

/// Pure-Dart ViewModel managing the Weight Entry modal form state, validation,
/// same-day conflict prompt, edit/delete actions, and repository persistence.
class WeightEntryViewModel extends AutoDisposeNotifier<WeightEntryFormState> {
  bool _disposed = false;

  @override
  WeightEntryFormState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
    });

    final userId = ref.watch(authViewModelProvider.select((s) => s.user?.id));
    return WeightEntryFormState(
      selectedDate: WeekDateUtils.normalizeDateUtc(DateTime.now()),
      openingUserId: userId,
    );
  }

  /// Initializes a clean Add session for the opening user.
  void initializeAdd({String? userId}) {
    final openingUserId = userId ?? ref.read(authViewModelProvider).user?.id;
    state = WeightEntryFormState(
      selectedDate: WeekDateUtils.normalizeDateUtc(DateTime.now()),
      openingUserId: openingUserId,
      status: FormStatus.initial,
    );
  }

  /// Alias for [initializeAdd].
  void initializeForAdd({String? userId}) => initializeAdd(userId: userId);

  /// Initializes a clean Edit session for an existing [entry] and opening user.
  void initializeEdit(WeightEntryEntity entry, {String? userId}) {
    final openingUserId = userId ?? ref.read(authViewModelProvider).user?.id;
    state = WeightEntryFormState(
      weightInput: entry.weightKg.toStringAsFixed(2),
      selectedDate: WeekDateUtils.normalizeDateUtc(entry.date),
      openingUserId: openingUserId,
      originalEntry: entry,
      status: FormStatus.initial,
    );
  }

  /// Alias for [initializeEdit].
  void initializeForEdit(WeightEntryEntity entry, {String? userId}) =>
      initializeEdit(entry, userId: userId);

  /// Initializes either an Add or Edit session based on whether [existingEntry] is supplied.
  void initialize({String? userId, WeightEntryEntity? existingEntry}) {
    if (existingEntry != null) {
      initializeEdit(existingEntry, userId: userId);
    } else {
      initializeAdd(userId: userId);
    }
  }

  /// Resets the form state to default uninitialized Add mode.
  void reset() => initializeAdd();

  void onWeightChanged(String value) {
    state = state.copyWith(
      weightInput: value,
      weightError: null,
      errorMessage: null,
    );
  }

  void onDateChanged(DateTime date) {
    if (state.isEdit) {
      // In edit mode, attempts to change the original date are ignored.
      return;
    }
    state = state.copyWith(
      selectedDate: WeekDateUtils.normalizeDateUtc(date),
      dateError: null,
      errorMessage: null,
      requiresOverwriteConfirmation: false,
      existingEntryForDate: null,
    );
  }

  void cancelOverwriteConfirmation() {
    state = state.copyWith(
      requiresOverwriteConfirmation: false,
      existingEntryForDate: null,
    );
  }

  /// Submits the weight entry form (Add or Edit).
  ///
  /// Returns `true` if save succeeded and sheet can dismiss, or `false`
  /// if validation failed, reentrant call was rejected, conflict confirmation is required,
  /// or repository returned a failure.
  Future<bool> submit({bool confirmOverwrite = false}) async {
    // 1. Reentrant rejection
    if (state.status == FormStatus.submitting) {
      return false;
    }

    // 2. Validate weight
    final weightError = WeightValidators.validateWeightInput(state.weightInput);
    if (weightError != null) {
      state = state.copyWith(
        status: FormStatus.failure,
        weightError: weightError,
      );
      return false;
    }

    final parsedWeight = WeightValidators.parseWeightKg(state.weightInput);
    if (parsedWeight == null) {
      state = state.copyWith(
        status: FormStatus.failure,
        weightError: WeightValidationError.invalidFormat,
      );
      return false;
    }

    // 3. Capture account identity before awaiting
    final authState = ref.read(authViewModelProvider);
    final user = authState.user;
    final targetUserId = state.openingUserId ?? user?.id;

    if (targetUserId == null || targetUserId.trim().isEmpty) {
      state = state.copyWith(
        status: FormStatus.failure,
        errorMessage: 'User is not authenticated',
      );
      return false;
    }

    final bool isEdit = state.isEdit;
    late final String dateIso;
    late final DateTime date;

    if (isEdit) {
      // Edit mode: read date-only state from immutable original entry.
      // Bypasses Add's 365-day validation and overwrite-self prompt.
      final original = state.originalEntry!;
      dateIso = original.dateIso;
      date = original.date;
    } else {
      // Add mode: validate date against 365-day historical window.
      final dateError = WeightValidators.validateEntryDate(
        state.selectedDate,
        now: DateTime.now(),
      );
      if (dateError != null) {
        state = state.copyWith(
          status: FormStatus.failure,
          dateError: dateError,
        );
        return false;
      }

      dateIso = WeekDateUtils.toIsoDateString(state.selectedDate);
      date = WeekDateUtils.normalizeDateUtc(state.selectedDate);

      // Verify loaded history gate
      final historyState = ref.read(weightHistoryViewModelProvider);
      if (historyState is! WeightHistoryLoaded) {
        state = state.copyWith(
          status: FormStatus.failure,
          errorMessage: 'Load weight history before saving. Please try again.',
          requiresOverwriteConfirmation: false,
          existingEntryForDate: null,
        );
        return false;
      }

      // Check overwrite prompt
      if (historyState.hasEntryForDate(dateIso)) {
        if (!confirmOverwrite) {
          final existing = historyState.entries.firstWhere(
            (e) => e.dateIso == dateIso,
          );
          state = state.copyWith(
            requiresOverwriteConfirmation: true,
            existingEntryForDate: existing,
          );
          return false;
        }
      }
    }

    state = state.copyWith(
      status: FormStatus.submitting,
      pendingAction: WeightEntryAction.save,
      errorMessage: null,
      requiresOverwriteConfirmation: false,
    );

    final entry = WeightEntryEntity(
      dateIso: dateIso,
      date: date,
      weightKg: parsedWeight,
      updatedAt: DateTime.now().toUtc(),
    );

    final repository = ref.read(weightRepositoryProvider);
    final result = await repository.saveWeightEntry(
      userId: targetUserId,
      entry: entry,
    );

    if (_disposed) return false;

    // Suppress side effects if active account changed during await
    final currentUserId = ref.read(authViewModelProvider).user?.id;
    if (currentUserId != targetUserId) {
      return false;
    }

    return result.when(
      success: (savedEntry) {
        final historyNotifier = ref.read(
          weightHistoryViewModelProvider.notifier,
        );
        historyNotifier.applySavedEntry(
          userId: targetUserId,
          entry: savedEntry,
        );

        state = state.copyWith(
          status: FormStatus.success,
          outcome: WeightEntryOutcome.saved,
          errorMessage: null,
        );

        // Nonblocking guarded refresh owned by history
        unawaited(historyNotifier.loadEntries(showLoading: false));
        return true;
      },
      failure: (failure) {
        state = state.copyWith(
          status: FormStatus.failure,
          errorMessage: failure.message,
          pendingAction: null,
        );
        return false;
      },
    );
  }

  /// Deletes the currently opened original weight entry.
  ///
  /// Callable only when initialized in edit mode. Ignores unsaved draft weight validity.
  /// Returns `true` if delete succeeded and sheet can dismiss, or `false`
  /// if not in edit mode, reentrant call was rejected, or repository failed.
  Future<bool> delete() async {
    // 1. Reentrant rejection
    if (state.status == FormStatus.submitting) {
      return false;
    }

    // 2. Callable only for an initialized edit
    if (!state.isEdit) {
      return false;
    }

    final original = state.originalEntry!;
    final targetDateIso = original.dateIso;

    // 3. Capture account identity before awaiting
    final authState = ref.read(authViewModelProvider);
    final user = authState.user;
    final targetUserId = state.openingUserId ?? user?.id;

    if (targetUserId == null || targetUserId.trim().isEmpty) {
      state = state.copyWith(
        status: FormStatus.failure,
        errorMessage: 'User is not authenticated',
      );
      return false;
    }

    // Ignores unsaved weight validity
    state = state.copyWith(
      status: FormStatus.submitting,
      pendingAction: WeightEntryAction.delete,
      errorMessage: null,
      requiresOverwriteConfirmation: false,
    );

    final repository = ref.read(weightRepositoryProvider);
    final result = await repository.deleteWeightEntry(
      userId: targetUserId,
      dateIso: targetDateIso,
    );

    if (_disposed) return false;

    // Suppress side effects if active account changed during await
    final currentUserId = ref.read(authViewModelProvider).user?.id;
    if (currentUserId != targetUserId) {
      return false;
    }

    return result.when(
      success: (_) {
        final historyNotifier = ref.read(
          weightHistoryViewModelProvider.notifier,
        );
        historyNotifier.applyDeletedEntry(
          userId: targetUserId,
          dateIso: targetDateIso,
        );

        state = state.copyWith(
          status: FormStatus.success,
          outcome: WeightEntryOutcome.deleted,
          errorMessage: null,
        );

        // Nonblocking guarded refresh owned by history
        unawaited(historyNotifier.loadEntries(showLoading: false));
        return true;
      },
      failure: (failure) {
        state = state.copyWith(
          status: FormStatus.failure,
          errorMessage: failure.message,
          pendingAction: null,
        );
        return false;
      },
    );
  }

  /// Alias for [delete].
  Future<bool> deleteEntry() => delete();
}
