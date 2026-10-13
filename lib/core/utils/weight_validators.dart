import 'package:bulk_tempo/l10n/app_localizations.dart';

/// Validation error codes for body weight values and historical entry dates.
enum WeightValidationError {
  empty,
  invalidFormat,
  outOfBounds,
  futureDate,
  lookbackExceeded;

  /// Returns the default English user-facing error message.
  String get defaultMessage {
    switch (this) {
      case WeightValidationError.empty:
        return 'Please enter a weight';
      case WeightValidationError.invalidFormat:
        return 'Enter a valid weight with up to 2 decimal places';
      case WeightValidationError.outOfBounds:
        return 'Weight must be between ${WeightValidators.minWeightKg.toStringAsFixed(1)} and ${WeightValidators.maxWeightKg.toStringAsFixed(1)} kg';
      case WeightValidationError.futureDate:
        return 'Date cannot be in the future';
      case WeightValidationError.lookbackExceeded:
        return 'Date cannot be more than ${WeightValidators.maxLookbackDays} days in the past';
    }
  }

  /// Returns the localized error message using [l10n].
  String toLocalizedMessage(AppLocalizations l10n) {
    switch (this) {
      case WeightValidationError.empty:
        return l10n.weightErrorEmpty;
      case WeightValidationError.invalidFormat:
        return l10n.weightErrorInvalidFormat;
      case WeightValidationError.outOfBounds:
        return l10n.weightErrorOutOfBounds(
          WeightValidators.minWeightKg.toStringAsFixed(1),
          WeightValidators.maxWeightKg.toStringAsFixed(1),
        );
      case WeightValidationError.futureDate:
        return l10n.weightErrorFutureDate;
      case WeightValidationError.lookbackExceeded:
        return l10n.weightErrorLookbackExceeded(
          WeightValidators.maxLookbackDays,
        );
    }
  }

  /// Returns the localized error message if [l10n] is provided, falling back to [defaultMessage].
  String message([AppLocalizations? l10n]) {
    if (l10n != null) {
      return toLocalizedMessage(l10n);
    }
    return defaultMessage;
  }
}

/// Validation utilities for user body weight inputs and entry dates.
abstract final class WeightValidators {
  /// Minimum allowed weight in kilograms.
  static const double minWeightKg = 20.0;

  /// Maximum allowed weight in kilograms.
  static const double maxWeightKg = 300.0;

  /// Maximum historical lookback allowed for weight entry dates in days.
  static const int maxLookbackDays = 365;

  static final RegExp _weightRegex = RegExp(r'^\d+(\.\d{1,2})?$');

  /// Parses a raw weight string into a [double], or returns `null` if invalid.
  ///
  /// Trims whitespace, normalizes decimal commas to dots, and ensures the format
  /// matches positive numeric values with up to 2 decimal places.
  static double? parseWeightKg(String rawInput) {
    final normalized = rawInput.trim().replaceAll(',', '.');
    if (!_weightRegex.hasMatch(normalized)) {
      return null;
    }
    return double.tryParse(normalized);
  }

  /// Validates a raw weight string against format and bounds constraints.
  ///
  /// Returns `null` when valid (`20.0 <= value <= 300.0` and at most 2 decimals),
  /// or a typed [WeightValidationError].
  static WeightValidationError? validateWeightInput(String rawInput) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) {
      return WeightValidationError.empty;
    }

    final parsed = parseWeightKg(trimmed);
    if (parsed == null) {
      return WeightValidationError.invalidFormat;
    }

    if (parsed < minWeightKg || parsed > maxWeightKg) {
      return WeightValidationError.outOfBounds;
    }

    return null;
  }

  /// Validates that an entry [date] is not in the future and not older than
  /// [maxLookbackDays] (365 days) relative to [now].
  ///
  /// Compares normalized calendar dates in UTC to avoid time-of-day or DST discrepancies.
  static WeightValidationError? validateEntryDate(
    DateTime date, {
    required DateTime now,
  }) {
    final entryDateUtc = DateTime.utc(date.year, date.month, date.day);
    final nowDateUtc = DateTime.utc(now.year, now.month, now.day);
    final minDateUtc = DateTime.utc(
      nowDateUtc.year,
      nowDateUtc.month,
      nowDateUtc.day - maxLookbackDays,
    );

    if (entryDateUtc.isAfter(nowDateUtc)) {
      return WeightValidationError.futureDate;
    }
    if (entryDateUtc.isBefore(minDateUtc)) {
      return WeightValidationError.lookbackExceeded;
    }

    return null;
  }

  /// Maps a [WeightValidationError] to a user-facing string using [l10n],
  /// or returns the English default if [l10n] is omitted.
  static String getErrorMessage(
    WeightValidationError error, [
    AppLocalizations? l10n,
  ]) {
    return error.message(l10n);
  }
}
