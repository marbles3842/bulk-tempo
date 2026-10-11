import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';

/// Result object for pair input validation containing field-level errors,
/// range-level errors, and/or the parsed [GainTargetEntity].
class GainTargetValidationResult {
  final String? minError;
  final String? maxError;
  final String? rangeError;
  final GainTargetEntity? target;

  const GainTargetValidationResult({
    this.minError,
    this.maxError,
    this.rangeError,
    this.target,
  });

  /// True when both fields and the range are valid, and target is constructed.
  bool get isValid =>
      minError == null &&
      maxError == null &&
      rangeError == null &&
      target != null;

  /// The first encountered error message, or `null` if all inputs are valid.
  String? get firstError => minError ?? maxError ?? rangeError;

  /// Effective error for the maximum input field, combining [maxError] and [rangeError].
  String? get effectiveMaxError => maxError ?? rangeError;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GainTargetValidationResult &&
          runtimeType == other.runtimeType &&
          minError == other.minError &&
          maxError == other.maxError &&
          rangeError == other.rangeError &&
          target == other.target;

  @override
  int get hashCode =>
      minError.hashCode ^
      maxError.hashCode ^
      rangeError.hashCode ^
      target.hashCode;

  @override
  String toString() =>
      'GainTargetValidationResult(minError: $minError, maxError: $maxError, rangeError: $rangeError, target: $target)';
}

/// Validation utilities for weekly gain target inputs and entity bounds.
abstract final class GainTargetValidator {
  static final RegExp _gainRateRegex = RegExp(r'^\d+(\.\d{1,2})?$');

  /// Parses a raw gain rate string into a positive finite [double], or returns `null` if invalid.
  ///
  /// Trims whitespace, normalizes decimal commas to dots, and ensures the format
  /// matches numeric values with up to 2 decimal places.
  /// Scientific notation, negative values, and non-numeric inputs return `null`.
  static double? parseGainRate(String? rawInput) {
    if (rawInput == null) return null;
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) return null;
    final normalized = trimmed.replaceAll(',', '.');
    if (!_gainRateRegex.hasMatch(normalized)) {
      return null;
    }
    final parsed = double.tryParse(normalized);
    if (parsed == null || !parsed.isFinite || parsed.isNaN) {
      return null;
    }
    return parsed;
  }

  /// Validates a raw minimum weekly gain rate string.
  ///
  /// Returns `null` if valid (non-empty, up to 2 decimals, > 0),
  /// or a user-facing error message.
  static String? validateMinInput(String? rawInput) {
    if (rawInput == null) {
      return 'Please enter a minimum gain rate';
    }
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) {
      return 'Please enter a minimum gain rate';
    }
    if (trimmed.startsWith('-')) {
      return 'Minimum gain rate must be greater than 0 kg/week';
    }
    final parsed = parseGainRate(trimmed);
    if (parsed == null) {
      return 'Enter a valid gain rate with up to 2 decimal places';
    }
    if (parsed <= 0) {
      return 'Minimum gain rate must be greater than 0 kg/week';
    }
    return null;
  }

  /// Validates a raw maximum weekly gain rate string.
  ///
  /// Returns `null` if valid (non-empty, up to 2 decimals, > 0),
  /// or a user-facing error message.
  static String? validateMaxInput(String? rawInput) {
    if (rawInput == null) {
      return 'Please enter a maximum gain rate';
    }
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) {
      return 'Please enter a maximum gain rate';
    }
    if (trimmed.startsWith('-')) {
      return 'Maximum gain rate must be greater than 0 kg/week';
    }
    final parsed = parseGainRate(trimmed);
    if (parsed == null) {
      return 'Enter a valid gain rate with up to 2 decimal places';
    }
    if (parsed <= 0) {
      return 'Maximum gain rate must be greater than 0 kg/week';
    }
    return null;
  }

  /// Validates a single gain rate endpoint string with a customizable field label.
  static String? validateEndpointInput(
    String? rawInput, {
    String fieldName = 'Gain rate',
  }) {
    if (rawInput == null) {
      return 'Please enter a $fieldName';
    }
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) {
      return 'Please enter a $fieldName';
    }
    if (trimmed.startsWith('-')) {
      return '$fieldName must be greater than 0 kg/week';
    }
    final parsed = parseGainRate(trimmed);
    if (parsed == null) {
      return 'Enter a valid gain rate with up to 2 decimal places';
    }
    if (parsed <= 0) {
      return '$fieldName must be greater than 0 kg/week';
    }
    return null;
  }

  /// Validates numeric range endpoints enforcing `0 < minWeeklyGainKg < maxWeeklyGainKg`
  /// with finite values.
  ///
  /// Notice: There is intentionally no upper limit cap on [maxWeeklyGainKg].
  /// Returns `null` if valid, or a user-facing error message.
  static String? validateRange(double minWeeklyGainKg, double maxWeeklyGainKg) {
    if (!minWeeklyGainKg.isFinite || minWeeklyGainKg.isNaN) {
      return 'Minimum gain rate must be a valid finite number';
    }
    if (!maxWeeklyGainKg.isFinite || maxWeeklyGainKg.isNaN) {
      return 'Maximum gain rate must be a valid finite number';
    }
    if (minWeeklyGainKg <= 0) {
      return 'Minimum gain rate must be greater than 0 kg/week';
    }
    if (maxWeeklyGainKg <= 0) {
      return 'Maximum gain rate must be greater than 0 kg/week';
    }
    if (minWeeklyGainKg >= maxWeeklyGainKg) {
      return 'Maximum gain rate must be greater than minimum gain rate';
    }
    return null;
  }

  /// Validates a [GainTargetEntity] instance against numeric range invariants.
  static String? validateTarget(GainTargetEntity target) {
    return validateRange(target.minWeeklyGainKg, target.maxWeeklyGainKg);
  }

  /// Returns true if [minWeeklyGainKg] and [maxWeeklyGainKg] satisfy all range invariants.
  static bool isValidRange(double minWeeklyGainKg, double maxWeeklyGainKg) {
    return validateRange(minWeeklyGainKg, maxWeeklyGainKg) == null;
  }

  /// Returns true if [target] satisfies all range invariants.
  static bool isValid(GainTargetEntity target) {
    return validateTarget(target) == null;
  }

  /// Validates both raw input strings together, returning a [GainTargetValidationResult]
  /// with field-level errors and range-level errors.
  static GainTargetValidationResult validateInputs(
    String? rawMin,
    String? rawMax,
  ) {
    final minError = validateMinInput(rawMin);
    final maxError = validateMaxInput(rawMax);

    if (minError != null || maxError != null) {
      return GainTargetValidationResult(minError: minError, maxError: maxError);
    }

    final parsedMin = parseGainRate(rawMin!)!;
    final parsedMax = parseGainRate(rawMax!)!;

    final rangeError = validateRange(parsedMin, parsedMax);
    if (rangeError != null) {
      return GainTargetValidationResult(rangeError: rangeError);
    }

    return GainTargetValidationResult(
      target: GainTargetEntity(
        minWeeklyGainKg: parsedMin,
        maxWeeklyGainKg: parsedMax,
      ),
    );
  }

  /// Returns the first error message across both raw inputs, or `null` if valid.
  static String? validateInputsError(String? rawMin, String? rawMax) {
    return validateInputs(rawMin, rawMax).firstError;
  }
}
