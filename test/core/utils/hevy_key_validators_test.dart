import 'dart:ui';
import 'package:bulk_tempo/core/utils/hevy_key_validators.dart';
import 'package:bulk_tempo/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validLowerUuid = 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d';
  const validUpperUuid = 'A1B2C3D4-E5F6-4A7B-8C9D-0E1F2A3B4C5D';
  const validMixedUuid = 'a1B2c3D4-e5F6-4a7B-8c9D-0e1F2a3B4c5D';

  group('HevyKeyValidators.normalizeKey', () {
    test('trims leading and trailing whitespace', () {
      expect(
        HevyKeyValidators.normalizeKey('  $validLowerUuid  '),
        equals(validLowerUuid),
      );
      expect(
        HevyKeyValidators.normalizeKey('\t$validLowerUuid\n'),
        equals(validLowerUuid),
      );
    });

    test('returns empty string for whitespace-only input', () {
      expect(HevyKeyValidators.normalizeKey('   \t\n '), isEmpty);
    });
  });

  group('HevyKeyValidators.isValidUuid', () {
    test('accepts lowercase, uppercase, and mixed-case UUIDs', () {
      expect(HevyKeyValidators.isValidUuid(validLowerUuid), isTrue);
      expect(HevyKeyValidators.isValidUuid(validUpperUuid), isTrue);
      expect(HevyKeyValidators.isValidUuid(validMixedUuid), isTrue);
    });

    test('returns true for valid UUID with surrounding whitespace', () {
      expect(HevyKeyValidators.isValidUuid('  $validLowerUuid\n'), isTrue);
    });

    test('returns false for empty or whitespace-only strings', () {
      expect(HevyKeyValidators.isValidUuid(''), isFalse);
      expect(HevyKeyValidators.isValidUuid('   '), isFalse);
    });

    test('returns false for malformed UUIDs', () {
      // Missing hyphens
      expect(
        HevyKeyValidators.isValidUuid('a1b2c3d4e5f64a7b8c9d0e1f2a3b4c5d'),
        isFalse,
      );
      // Wrong segment lengths
      expect(
        HevyKeyValidators.isValidUuid('a1b2c3d-e5f6-4a7b-8c9d-0e1f2a3b4c5d'),
        isFalse,
      );
      expect(
        HevyKeyValidators.isValidUuid('a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5'),
        isFalse,
      );
      // Non-hex characters
      expect(
        HevyKeyValidators.isValidUuid('g1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d'),
        isFalse,
      );
      // Extra characters
      expect(HevyKeyValidators.isValidUuid('$validLowerUuid-extra'), isFalse);
    });
  });

  group('HevyKeyValidators.validateKeyInput', () {
    test('returns empty error for empty or whitespace-only input', () {
      expect(
        HevyKeyValidators.validateKeyInput(''),
        equals(HevyKeyValidationError.empty),
      );
      expect(
        HevyKeyValidators.validateKeyInput('   \t\n '),
        equals(HevyKeyValidationError.empty),
      );
      expect(
        HevyKeyValidationError.empty.defaultMessage,
        equals('Hevy API key is required'),
      );
    });

    test('returns invalidUuid error for malformed UUID', () {
      expect(
        HevyKeyValidators.validateKeyInput('not-a-uuid'),
        equals(HevyKeyValidationError.invalidUuid),
      );
      expect(
        HevyKeyValidators.validateKeyInput('a1b2c3d4e5f64a7b8c9d0e1f2a3b4c5d'),
        equals(HevyKeyValidationError.invalidUuid),
      );
      expect(
        HevyKeyValidationError.invalidUuid.defaultMessage,
        equals('Enter a valid Hevy API key (UUID format)'),
      );
    });

    test('returns null for valid UUIDs with surrounding whitespace', () {
      expect(HevyKeyValidators.validateKeyInput(validLowerUuid), isNull);
      expect(HevyKeyValidators.validateKeyInput(validUpperUuid), isNull);
      expect(HevyKeyValidators.validateKeyInput(' $validMixedUuid '), isNull);
    });
  });

  group('HevyKeyValidators.maskApiKey', () {
    test('masks valid UUID preserving trailing 4 characters', () {
      expect(
        HevyKeyValidators.maskApiKey(validLowerUuid),
        equals('••••••••-••••-••••-••••-••••••••4c5d'),
      );
      expect(
        HevyKeyValidators.maskApiKey('  $validUpperUuid  '),
        equals('••••••••-••••-••••-••••-••••••••4C5D'),
      );
    });

    test('returns fallback mask for shorter or invalid strings', () {
      expect(HevyKeyValidators.maskApiKey(''), equals('••••••••'));
      expect(HevyKeyValidators.maskApiKey('short-key'), equals('••••••••'));
      expect(HevyKeyValidators.maskApiKey('   '), equals('••••••••'));
    });
  });

  group('HevyKeyValidationError localization', () {
    final l10nEn = lookupAppLocalizations(const Locale('en'));
    final l10nPl = lookupAppLocalizations(const Locale('pl'));

    test('resolves English error messages correctly', () {
      expect(
        HevyKeyValidationError.empty.toLocalizedMessage(l10nEn),
        equals('Hevy API key is required'),
      );
      expect(
        HevyKeyValidationError.invalidUuid.toLocalizedMessage(l10nEn),
        equals('Enter a valid Hevy API key (UUID format)'),
      );
    });

    test('resolves Polish error messages correctly', () {
      expect(
        HevyKeyValidationError.empty.toLocalizedMessage(l10nPl),
        equals('Klucz API Hevy jest wymagany'),
      );
      expect(
        HevyKeyValidationError.invalidUuid.toLocalizedMessage(l10nPl),
        equals('Wprowadź poprawny klucz API Hevy (format UUID)'),
      );
    });

    test(
      'message() helper and HevyKeyValidators.getErrorMessage fall back or localize',
      () {
        expect(
          HevyKeyValidationError.empty.message(),
          equals('Hevy API key is required'),
        );
        expect(
          HevyKeyValidationError.empty.message(l10nPl),
          equals('Klucz API Hevy jest wymagany'),
        );
        expect(
          HevyKeyValidators.getErrorMessage(HevyKeyValidationError.invalidUuid),
          equals('Enter a valid Hevy API key (UUID format)'),
        );
        expect(
          HevyKeyValidators.getErrorMessage(
            HevyKeyValidationError.invalidUuid,
            l10nPl,
          ),
          equals('Wprowadź poprawny klucz API Hevy (format UUID)'),
        );
      },
    );
  });
}
