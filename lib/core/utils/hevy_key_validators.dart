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
  /// Returns `'Hevy API key is required'` when empty after trimming,
  /// `'Enter a valid Hevy API key (UUID format)'` when not a valid UUID,
  /// or `null` when valid.
  static String? validateKeyInput(String rawInput) {
    final normalized = normalizeKey(rawInput);
    if (normalized.isEmpty) {
      return 'Hevy API key is required';
    }
    if (!isValidUuid(normalized)) {
      return 'Enter a valid Hevy API key (UUID format)';
    }
    return null;
  }

  /// Masks [apiKey] for safe display in the UI, preserving only the trailing
  /// 12 characters of a valid 36-character UUID.
  static String maskApiKey(String apiKey) {
    final trimmed = normalizeKey(apiKey);
    if (!isValidUuid(trimmed)) {
      return '••••••••';
    }
    return '••••••••-••••-••••-••••-${trimmed.substring(trimmed.length - 12)}';
  }
}
