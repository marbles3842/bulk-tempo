import 'package:bulk_tempo/features/auth/presentation/view_models/form_status.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';

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

  const WeightEntryFormState({
    this.weightInput = '',
    required this.selectedDate,
    this.status = FormStatus.initial,
    this.weightError,
    this.dateError,
    this.errorMessage,
    this.requiresOverwriteConfirmation = false,
    this.existingEntryForDate,
  });

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
          existingEntryForDate == other.existingEntryForDate;

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
  );

  @override
  String toString() =>
      'WeightEntryFormState(weightInput: $weightInput, selectedDate: $selectedDate, status: $status, weightError: $weightError, dateError: $dateError, errorMessage: $errorMessage, requiresOverwriteConfirmation: $requiresOverwriteConfirmation, existingEntryForDate: $existingEntryForDate)';
}
