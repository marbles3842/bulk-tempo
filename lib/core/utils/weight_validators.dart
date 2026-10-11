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
  /// or a clear user-facing error message.
  static String? validateWeightInput(String rawInput) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) {
      return 'Please enter a weight';
    }

    final parsed = parseWeightKg(trimmed);
    if (parsed == null) {
      return 'Enter a valid weight with up to 2 decimal places';
    }

    if (parsed < minWeightKg || parsed > maxWeightKg) {
      return 'Weight must be between ${minWeightKg.toStringAsFixed(1)} and ${maxWeightKg.toStringAsFixed(1)} kg';
    }

    return null;
  }

  /// Validates that an entry [date] is not in the future and not older than
  /// [maxLookbackDays] (365 days) relative to [now].
  ///
  /// Compares normalized calendar dates in UTC to avoid time-of-day or DST discrepancies.
  static String? validateEntryDate(DateTime date, {required DateTime now}) {
    final entryDateUtc = DateTime.utc(date.year, date.month, date.day);
    final nowDateUtc = DateTime.utc(now.year, now.month, now.day);
    final minDateUtc = DateTime.utc(
      nowDateUtc.year,
      nowDateUtc.month,
      nowDateUtc.day - maxLookbackDays,
    );

    if (entryDateUtc.isAfter(nowDateUtc)) {
      return 'Date cannot be in the future';
    }
    if (entryDateUtc.isBefore(minDateUtc)) {
      return 'Date cannot be more than 365 days in the past';
    }

    return null;
  }
}
