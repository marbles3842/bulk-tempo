import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bulk_tempo/core/utils/weight_validators.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/form_status.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';

part 'weight_entry_form_state.freezed.dart';

/// The active user action being submitted.
enum WeightEntryAction { save, delete }

/// The terminal outcome of an acknowledged mutation.
enum WeightEntryOutcome { saved, deleted }

/// Pure-Dart state representing the Add/Edit Weight measurement form.
@freezed
abstract class WeightEntryFormState with _$WeightEntryFormState {
  const WeightEntryFormState._();

  const factory WeightEntryFormState({
    @Default('') String weightInput,
    required DateTime selectedDate,
    @Default(FormStatus.initial) FormStatus status,
    WeightValidationError? weightError,
    WeightValidationError? dateError,
    String? errorMessage,
    @Default(false) bool requiresOverwriteConfirmation,
    WeightEntryEntity? existingEntryForDate,

    /// Retained immutable original entry when the form was opened in edit mode.
    WeightEntryEntity? originalEntry,

    /// User ID captured when the form session was opened or initialized.
    String? openingUserId,

    /// Active action currently being processed (save or delete).
    WeightEntryAction? pendingAction,

    /// Terminal outcome of an acknowledged mutation (saved or deleted).
    WeightEntryOutcome? outcome,
  }) = _WeightEntryFormState;

  /// True if initialized to correct an existing entry.
  bool get isEdit => originalEntry != null;

  /// The immutable fixed date when editing, or null when adding.
  DateTime? get fixedDate => originalEntry?.date;

  /// The immutable ISO date string when editing, or null when adding.
  String? get fixedDateIso => originalEntry?.dateIso;

  /// True if currently executing a save mutation.
  bool get isSaving =>
      status == FormStatus.submitting &&
      pendingAction == WeightEntryAction.save;

  /// True if currently executing a delete mutation.
  bool get isDeleting =>
      status == FormStatus.submitting &&
      pendingAction == WeightEntryAction.delete;

  /// Compares parsed valid weight to the original value, treating equivalent
  /// inputs such as `80`, `80.00`, and `80,00` as unchanged.
  /// A changed invalid or empty draft is dirty.
  bool get isDirty {
    if (originalEntry == null) {
      return weightInput.trim().isNotEmpty;
    }
    final parsed = WeightValidators.parseWeightKg(weightInput);
    if (parsed != null) {
      return (parsed - originalEntry!.weightKg).abs() > 0.0001;
    }
    return true;
  }
}
