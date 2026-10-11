import 'package:bulk_tempo/core/utils/weight_validators.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/form_status.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';

/// The active user action being submitted.
enum WeightEntryAction { save, delete }

/// The terminal outcome of an acknowledged mutation.
enum WeightEntryOutcome { saved, deleted }

/// Pure-Dart state representing the Add/Edit Weight measurement form.
class WeightEntryFormState {
  final String weightInput;
  final DateTime selectedDate;
  final FormStatus status;
  final String? weightError;
  final String? dateError;
  final String? errorMessage;
  final bool requiresOverwriteConfirmation;
  final WeightEntryEntity? existingEntryForDate;

  /// Retained immutable original entry when the form was opened in edit mode.
  final WeightEntryEntity? originalEntry;

  /// User ID captured when the form session was opened or initialized.
  final String? openingUserId;

  /// Active action currently being processed (save or delete).
  final WeightEntryAction? pendingAction;

  /// Terminal outcome of an acknowledged mutation (saved or deleted).
  final WeightEntryOutcome? outcome;

  const WeightEntryFormState({
    this.weightInput = '',
    required this.selectedDate,
    this.status = FormStatus.initial,
    this.weightError,
    this.dateError,
    this.errorMessage,
    this.requiresOverwriteConfirmation = false,
    this.existingEntryForDate,
    this.originalEntry,
    this.openingUserId,
    this.pendingAction,
    this.outcome,
  });

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

  WeightEntryFormState copyWith({
    String? weightInput,
    DateTime? selectedDate,
    FormStatus? status,
    String? weightError,
    bool clearWeightError = false,
    String? dateError,
    bool clearDateError = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? requiresOverwriteConfirmation,
    WeightEntryEntity? existingEntryForDate,
    bool clearExistingEntry = false,
    WeightEntryEntity? originalEntry,
    bool clearOriginalEntry = false,
    String? openingUserId,
    WeightEntryAction? pendingAction,
    bool clearPendingAction = false,
    WeightEntryOutcome? outcome,
    bool clearOutcome = false,
  }) {
    return WeightEntryFormState(
      weightInput: weightInput ?? this.weightInput,
      selectedDate: selectedDate ?? this.selectedDate,
      status: status ?? this.status,
      weightError: clearWeightError ? null : (weightError ?? this.weightError),
      dateError: clearDateError ? null : (dateError ?? this.dateError),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      requiresOverwriteConfirmation:
          requiresOverwriteConfirmation ?? this.requiresOverwriteConfirmation,
      existingEntryForDate: clearExistingEntry
          ? null
          : (existingEntryForDate ?? this.existingEntryForDate),
      originalEntry: clearOriginalEntry
          ? null
          : (originalEntry ?? this.originalEntry),
      openingUserId: openingUserId ?? this.openingUserId,
      pendingAction: clearPendingAction
          ? null
          : (pendingAction ?? this.pendingAction),
      outcome: clearOutcome ? null : (outcome ?? this.outcome),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeightEntryFormState &&
          runtimeType == other.runtimeType &&
          weightInput == other.weightInput &&
          selectedDate == other.selectedDate &&
          status == other.status &&
          weightError == other.weightError &&
          dateError == other.dateError &&
          errorMessage == other.errorMessage &&
          requiresOverwriteConfirmation ==
              other.requiresOverwriteConfirmation &&
          existingEntryForDate == other.existingEntryForDate &&
          originalEntry == other.originalEntry &&
          openingUserId == other.openingUserId &&
          pendingAction == other.pendingAction &&
          outcome == other.outcome;

  @override
  int get hashCode => Object.hash(
    weightInput,
    selectedDate,
    status,
    weightError,
    dateError,
    errorMessage,
    requiresOverwriteConfirmation,
    existingEntryForDate,
    originalEntry,
    openingUserId,
    pendingAction,
    outcome,
  );

  @override
  String toString() =>
      'WeightEntryFormState(weightInput: $weightInput, selectedDate: $selectedDate, status: $status, isEdit: $isEdit, isDirty: $isDirty, pendingAction: $pendingAction, outcome: $outcome, errorMessage: $errorMessage)';
}
