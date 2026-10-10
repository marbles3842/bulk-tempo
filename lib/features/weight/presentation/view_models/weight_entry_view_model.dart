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
/// same-day conflict prompt, and repository persistence.
class WeightEntryViewModel extends AutoDisposeNotifier<WeightEntryFormState> {
  @override
  WeightEntryFormState build() {
    return WeightEntryFormState(
      selectedDate: WeekDateUtils.normalizeDateUtc(DateTime.now()),
    );
  }

  void onWeightChanged(String value) {
    state = state.copyWith(
      weightInput: value,
      clearWeightError: true,
      clearErrorMessage: true,
    );
  }

  void onDateChanged(DateTime date) {
    state = state.copyWith(
      selectedDate: WeekDateUtils.normalizeDateUtc(date),
      clearDateError: true,
      clearErrorMessage: true,
      requiresOverwriteConfirmation: false,
      clearExistingEntry: true,
    );
  }

  void cancelOverwriteConfirmation() {
    state = state.copyWith(
      requiresOverwriteConfirmation: false,
      clearExistingEntry: true,
    );
  }

  /// Submits the weight entry form.
  ///
  /// Returns `true` if save succeeded and bottom sheet can dismiss, or `false`
  /// if validation failed, conflict confirmation is required, or repository returned a failure.
  Future<bool> submit({bool confirmOverwrite = false}) async {
    final weightError = WeightValidators.validateWeightInput(state.weightInput);
    final dateError = WeightValidators.validateEntryDate(
      state.selectedDate,
      now: DateTime.now(),
    );

    if (weightError != null || dateError != null) {
      state = state.copyWith(
        status: FormStatus.failure,
        weightError: weightError,
        dateError: dateError,
      );
      return false;
    }

    final dateIso = WeekDateUtils.toIsoDateString(state.selectedDate);
    final historyState = ref.read(weightHistoryViewModelProvider);

    if (historyState is WeightHistoryLoaded &&
        historyState.hasEntryForDate(dateIso)) {
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

    final parsedWeight = WeightValidators.parseWeightKg(state.weightInput);
    if (parsedWeight == null) {
      state = state.copyWith(
        status: FormStatus.failure,
        weightError: 'Enter a valid weight with up to 2 decimal places',
      );
      return false;
    }

    final authState = ref.read(authViewModelProvider);
    final user = authState.user;
    if (user == null || user.id.trim().isEmpty) {
      state = state.copyWith(
        status: FormStatus.failure,
        errorMessage: 'User is not authenticated',
      );
      return false;
    }

    state = state.copyWith(
      status: FormStatus.submitting,
      clearErrorMessage: true,
      requiresOverwriteConfirmation: false,
    );

    final entry = WeightEntryEntity(
      dateIso: dateIso,
      date: WeekDateUtils.normalizeDateUtc(state.selectedDate),
      weightKg: parsedWeight,
      updatedAt: DateTime.now().toUtc(),
    );

    final repository = ref.read(weightRepositoryProvider);
    final result = await repository.saveWeightEntry(
      userId: user.id,
      entry: entry,
    );

    return result.when(
      success: (_) async {
        await ref
            .read(weightHistoryViewModelProvider.notifier)
            .loadEntries(showLoading: false);
        state = state.copyWith(
          status: FormStatus.success,
          clearErrorMessage: true,
        );
        return true;
      },
      failure: (failure) {
        state = state.copyWith(
          status: FormStatus.failure,
          errorMessage: failure.message,
        );
        return false;
      },
    );
  }
}
