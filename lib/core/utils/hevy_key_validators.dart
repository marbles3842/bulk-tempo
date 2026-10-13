import 'package:bulk_tempo/l10n/app_localizations.dart';

/// Validation error codes for Hevy API keys.
enum HevyKeyValidationError {
  empty,
  invalidUuid;

  /// Returns the default English user-facing error message.
  String get defaultMessage {
    switch (this) {
      case HevyKeyValidationError.empty:
        return 'Hevy API key is required';
      case HevyKeyValidationError.invalidUuid:
        return 'Enter a valid Hevy API key (UUID format)';
    }
  }

  /// Returns the localized error message using [l10n].
  String toLocalizedMessage(AppLocalizations l10n) {
    switch (this) {
      case HevyKeyValidationError.empty:
        return l10n.hevyKeyErrorEmpty;
      case HevyKeyValidationError.invalidUuid:
        return l10n.hevyKeyErrorInvalidUuid;
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

/// Validation and masking utilities for user-supplied Hevy API keys.
abstract final class HevyKeyValidators {
  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Trims leading and trailing whitespace from [rawInput].
  static String normalizeKey(String rawInput) => rawInput.trim();

  /// Returns `true` if [rawInput] (after trimming whitespace) matches the
  /// canonical 8-4-4-4-12 hexadecimal UUID format.
  static bool isValidUuid(String rawInput) {
    final normalized = normalizeKey(rawInput);
    return _uuidRegex.hasMatch(normalized);
  }

  /// Validates [rawInput] as a Hevy API key.
  ///
  /// Returns [HevyKeyValidationError.empty] when empty after trimming,
  /// [HevyKeyValidationError.invalidUuid] when not a valid UUID,
  /// or `null` when valid.
  static HevyKeyValidationError? validateKeyInput(String rawInput) {
    final normalized = normalizeKey(rawInput);
    if (normalized.isEmpty) {
      return HevyKeyValidationError.empty;
    }
    if (!isValidUuid(normalized)) {
      return HevyKeyValidationError.invalidUuid;
    }
    return null;
  }

  /// Masks [apiKey] for safe display in the UI, preserving only the trailing
  /// 4 characters of a valid 36-character UUID.
  static String maskApiKey(String apiKey) {
    final trimmed = normalizeKey(apiKey);
    if (!isValidUuid(trimmed)) {
      return '••••••••';
    }
    return '••••••••-••••-••••-••••-••••••••${trimmed.substring(trimmed.length - 4)}';
  }

  /// Maps a [HevyKeyValidationError] to a user-facing string using [l10n],
  /// or returns the English default if [l10n] is omitted.
  static String getErrorMessage(
    HevyKeyValidationError error, [
    AppLocalizations? l10n,
  ]) {
    return error.message(l10n);
  }
}
