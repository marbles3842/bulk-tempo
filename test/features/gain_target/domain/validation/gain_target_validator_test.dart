import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';
import 'package:bulk_tempo/features/gain_target/domain/validation/gain_target_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GainTargetValidator.parseGainRate', () {
    test('parses integer gain rates', () {
      expect(GainTargetValidator.parseGainRate('1'), equals(1.0));
      expect(GainTargetValidator.parseGainRate('2'), equals(2.0));
      expect(GainTargetValidator.parseGainRate('5'), equals(5.0));
    });

    test('parses dot decimal separators up to 2 decimal places', () {
      expect(GainTargetValidator.parseGainRate('0.15'), equals(0.15));
      expect(GainTargetValidator.parseGainRate('0.25'), equals(0.25));
      expect(GainTargetValidator.parseGainRate('0.01'), equals(0.01));
      expect(GainTargetValidator.parseGainRate('0.02'), equals(0.02));
      expect(GainTargetValidator.parseGainRate('0.29'), equals(0.29));
      expect(GainTargetValidator.parseGainRate('0.57'), equals(0.57));
      expect(GainTargetValidator.parseGainRate('5.00'), equals(5.0));
      expect(GainTargetValidator.parseGainRate('6.00'), equals(6.0));
    });

    test('parses comma decimal separators up to 2 decimal places', () {
      expect(GainTargetValidator.parseGainRate('0,15'), equals(0.15));
      expect(GainTargetValidator.parseGainRate('0,25'), equals(0.25));
      expect(GainTargetValidator.parseGainRate('5,50'), equals(5.5));
    });

    test('trims surrounding whitespace', () {
      expect(GainTargetValidator.parseGainRate('  0.15  '), equals(0.15));
      expect(GainTargetValidator.parseGainRate('\t0,25\n'), equals(0.25));
      expect(GainTargetValidator.parseGainRate('   1   '), equals(1.0));
    });

    test('returns null for null, empty or whitespace-only inputs', () {
      expect(GainTargetValidator.parseGainRate(null), isNull);
      expect(GainTargetValidator.parseGainRate(''), isNull);
      expect(GainTargetValidator.parseGainRate('   '), isNull);
      expect(GainTargetValidator.parseGainRate('\t\n'), isNull);
    });

    test('returns null for more than 2 decimal places', () {
      expect(GainTargetValidator.parseGainRate('0.151'), isNull);
      expect(GainTargetValidator.parseGainRate('0,151'), isNull);
      expect(GainTargetValidator.parseGainRate('0.255'), isNull);
      expect(GainTargetValidator.parseGainRate('1.234'), isNull);
    });

    test('returns null for missing leading digits', () {
      expect(GainTargetValidator.parseGainRate('.15'), isNull);
      expect(GainTargetValidator.parseGainRate(',25'), isNull);
    });

    test('returns null for negative values', () {
      expect(GainTargetValidator.parseGainRate('-0.15'), isNull);
      expect(GainTargetValidator.parseGainRate('-1'), isNull);
    });

    test('returns null for scientific notation and exponents', () {
      expect(GainTargetValidator.parseGainRate('1e2'), isNull);
      expect(GainTargetValidator.parseGainRate('1E2'), isNull);
      expect(GainTargetValidator.parseGainRate('1e-2'), isNull);
      expect(GainTargetValidator.parseGainRate('2.5e-1'), isNull);
    });

    test('returns null for non-numeric text and malformed characters', () {
      expect(GainTargetValidator.parseGainRate('abc'), isNull);
      expect(GainTargetValidator.parseGainRate('0.15kg'), isNull);
      expect(GainTargetValidator.parseGainRate('0..15'), isNull);
      expect(GainTargetValidator.parseGainRate('0.15.15'), isNull);
      expect(GainTargetValidator.parseGainRate('NaN'), isNull);
      expect(GainTargetValidator.parseGainRate('Infinity'), isNull);
      expect(GainTargetValidator.parseGainRate('-Infinity'), isNull);
    });

    test('parses 0 and 0.00 as 0.0 (bounds validation handled separately)', () {
      expect(GainTargetValidator.parseGainRate('0'), equals(0.0));
      expect(GainTargetValidator.parseGainRate('0.00'), equals(0.0));
      expect(GainTargetValidator.parseGainRate('0,00'), equals(0.0));
    });
  });

  group('GainTargetValidator.validateMinInput', () {
    test('accepts valid inputs with comma or dot separators', () {
      expect(GainTargetValidator.validateMinInput('0.15'), isNull);
      expect(GainTargetValidator.validateMinInput('0,15'), isNull);
      expect(GainTargetValidator.validateMinInput('  0.15  '), isNull);
      expect(GainTargetValidator.validateMinInput('1'), isNull);
      expect(GainTargetValidator.validateMinInput('0.01'), isNull);
      expect(GainTargetValidator.validateMinInput('5.00'), isNull);
    });

    test('returns error for empty or blank input', () {
      expect(
        GainTargetValidator.validateMinInput(null),
        equals('Please enter a minimum gain rate'),
      );
      expect(
        GainTargetValidator.validateMinInput(''),
        equals('Please enter a minimum gain rate'),
      );
      expect(
        GainTargetValidator.validateMinInput('   '),
        equals('Please enter a minimum gain rate'),
      );
    });

    test('returns error for zero values', () {
      final zeroError = GainTargetValidator.validateMinInput('0');
      expect(zeroError, contains('greater than 0 kg/week'));

      final zeroDecimalError = GainTargetValidator.validateMinInput('0.00');
      expect(zeroDecimalError, contains('greater than 0 kg/week'));
    });

    test('returns error for negative values', () {
      final negativeError = GainTargetValidator.validateMinInput('-0.15');
      expect(negativeError, contains('greater than 0 kg/week'));
    });

    test('returns error for more than 2 decimal places', () {
      final error = GainTargetValidator.validateMinInput('0.151');
      expect(error, contains('up to 2 decimal places'));
    });

    test('returns error for scientific notation', () {
      final error = GainTargetValidator.validateMinInput('1e2');
      expect(error, contains('up to 2 decimal places'));
    });

    test('returns error for malformed or nonnumeric text', () {
      expect(
        GainTargetValidator.validateMinInput('abc'),
        contains('up to 2 decimal places'),
      );
      expect(
        GainTargetValidator.validateMinInput('.15'),
        contains('up to 2 decimal places'),
      );
      expect(
        GainTargetValidator.validateMinInput('0..15'),
        contains('up to 2 decimal places'),
      );
    });
  });

  group('GainTargetValidator.validateMaxInput', () {
    test('accepts valid inputs with comma or dot separators', () {
      expect(GainTargetValidator.validateMaxInput('0.25'), isNull);
      expect(GainTargetValidator.validateMaxInput('0,25'), isNull);
      expect(GainTargetValidator.validateMaxInput('  0.25  '), isNull);
      expect(GainTargetValidator.validateMaxInput('2'), isNull);
      expect(GainTargetValidator.validateMaxInput('0.02'), isNull);
      expect(GainTargetValidator.validateMaxInput('6.00'), isNull);
    });

    test('returns error for empty or blank input', () {
      expect(
        GainTargetValidator.validateMaxInput(null),
        equals('Please enter a maximum gain rate'),
      );
      expect(
        GainTargetValidator.validateMaxInput(''),
        equals('Please enter a maximum gain rate'),
      );
      expect(
        GainTargetValidator.validateMaxInput('   '),
        equals('Please enter a maximum gain rate'),
      );
    });

    test('returns error for zero values', () {
      final zeroError = GainTargetValidator.validateMaxInput('0');
      expect(zeroError, contains('greater than 0 kg/week'));

      final zeroDecimalError = GainTargetValidator.validateMaxInput('0.00');
      expect(zeroDecimalError, contains('greater than 0 kg/week'));
    });

    test('returns error for negative values', () {
      final negativeError = GainTargetValidator.validateMaxInput('-0.25');
      expect(negativeError, contains('greater than 0 kg/week'));
    });

    test('returns error for more than 2 decimal places', () {
      final error = GainTargetValidator.validateMaxInput('0.255');
      expect(error, contains('up to 2 decimal places'));
    });

    test('returns error for scientific notation', () {
      final error = GainTargetValidator.validateMaxInput('1e2');
      expect(error, contains('up to 2 decimal places'));
    });

    test('returns error for malformed text', () {
      expect(
        GainTargetValidator.validateMaxInput('xyz'),
        contains('up to 2 decimal places'),
      );
    });
  });

  group('GainTargetValidator.validateEndpointInput', () {
    test('uses customized fieldName in error messages', () {
      expect(
        GainTargetValidator.validateEndpointInput('', fieldName: 'Rate'),
        equals('Please enter a Rate'),
      );
      expect(
        GainTargetValidator.validateEndpointInput('0', fieldName: 'Rate'),
        contains('Rate must be greater than 0 kg/week'),
      );
    });
  });

  group('GainTargetValidator.validateRange', () {
    test('accepts agreed target range 0.15–0.25 kg/week', () {
      expect(GainTargetValidator.validateRange(0.15, 0.25), isNull);
    });

    test('accepts small range 0.01–0.02 kg/week', () {
      expect(GainTargetValidator.validateRange(0.01, 0.02), isNull);
    });

    test('accepts range 0.29–0.57 kg/week', () {
      expect(GainTargetValidator.validateRange(0.29, 0.57), isNull);
    });

    test('accepts uncapped high ranges (5.00–6.00 and above)', () {
      expect(GainTargetValidator.validateRange(5.0, 6.0), isNull);
      expect(GainTargetValidator.validateRange(10.0, 20.0), isNull);
    });

    test('rejects zero endpoints', () {
      final minZero = GainTargetValidator.validateRange(0.0, 0.25);
      expect(minZero, isNotNull);
      expect(minZero, contains('Minimum gain rate must be greater than 0'));

      final maxZero = GainTargetValidator.validateRange(0.15, 0.0);
      expect(maxZero, isNotNull);
      expect(maxZero, contains('Maximum gain rate must be greater than 0'));
    });

    test('rejects negative endpoints', () {
      final minNegative = GainTargetValidator.validateRange(-0.15, 0.25);
      expect(minNegative, isNotNull);
      expect(minNegative, contains('Minimum gain rate must be greater than 0'));

      final maxNegative = GainTargetValidator.validateRange(0.15, -0.25);
      expect(maxNegative, isNotNull);
      expect(maxNegative, contains('Maximum gain rate must be greater than 0'));
    });

    test('rejects equal endpoints', () {
      final equal = GainTargetValidator.validateRange(0.20, 0.20);
      expect(equal, isNotNull);
      expect(equal, contains('Maximum gain rate must be greater than minimum'));
    });

    test('rejects reversed endpoints', () {
      final reversed = GainTargetValidator.validateRange(0.30, 0.20);
      expect(reversed, isNotNull);
      expect(
        reversed,
        contains('Maximum gain rate must be greater than minimum'),
      );
    });

    test('rejects nonfinite values (NaN and infinity)', () {
      final nanMin = GainTargetValidator.validateRange(double.nan, 0.25);
      expect(nanMin, isNotNull);
      expect(nanMin, contains('finite number'));

      final nanMax = GainTargetValidator.validateRange(0.15, double.nan);
      expect(nanMax, isNotNull);
      expect(nanMax, contains('finite number'));

      final infMin = GainTargetValidator.validateRange(double.infinity, 0.25);
      expect(infMin, isNotNull);
      expect(infMin, contains('finite number'));

      final infMax = GainTargetValidator.validateRange(0.15, double.infinity);
      expect(infMax, isNotNull);
      expect(infMax, contains('finite number'));

      final negInf = GainTargetValidator.validateRange(
        double.negativeInfinity,
        0.25,
      );
      expect(negInf, isNotNull);
      expect(negInf, contains('finite number'));
    });
  });

  group('GainTargetValidator.validateTarget and isValid', () {
    test('validates GainTargetEntity correctly', () {
      const valid = GainTargetEntity(
        minWeeklyGainKg: 0.15,
        maxWeeklyGainKg: 0.25,
      );
      expect(GainTargetValidator.validateTarget(valid), isNull);
      expect(GainTargetValidator.isValid(valid), isTrue);
      expect(GainTargetValidator.isValidRange(0.15, 0.25), isTrue);

      const invalidEqual = GainTargetEntity(
        minWeeklyGainKg: 0.20,
        maxWeeklyGainKg: 0.20,
      );
      expect(GainTargetValidator.validateTarget(invalidEqual), isNotNull);
      expect(GainTargetValidator.isValid(invalidEqual), isFalse);
      expect(GainTargetValidator.isValidRange(0.20, 0.20), isFalse);

      const invalidNonfinite = GainTargetEntity(
        minWeeklyGainKg: double.nan,
        maxWeeklyGainKg: 0.25,
      );
      expect(GainTargetValidator.validateTarget(invalidNonfinite), isNotNull);
      expect(GainTargetValidator.isValid(invalidNonfinite), isFalse);
    });
  });

  group('GainTargetValidator.validateInputs', () {
    test('returns valid result and constructed target for 0.15–0.25', () {
      final result = GainTargetValidator.validateInputs('0.15', '0.25');
      expect(result.isValid, isTrue);
      expect(result.minError, isNull);
      expect(result.maxError, isNull);
      expect(result.rangeError, isNull);
      expect(result.firstError, isNull);
      expect(
        result.target,
        equals(
          const GainTargetEntity(minWeeklyGainKg: 0.15, maxWeeklyGainKg: 0.25),
        ),
      );
    });

    test('accepts comma input', () {
      final result = GainTargetValidator.validateInputs('0,15', '0,25');
      expect(result.isValid, isTrue);
      expect(
        result.target,
        equals(
          const GainTargetEntity(minWeeklyGainKg: 0.15, maxWeeklyGainKg: 0.25),
        ),
      );
    });

    test('accepts whitespace and integer inputs', () {
      final result = GainTargetValidator.validateInputs('  1  ', '\t2\n');
      expect(result.isValid, isTrue);
      expect(
        result.target,
        equals(
          const GainTargetEntity(minWeeklyGainKg: 1.0, maxWeeklyGainKg: 2.0),
        ),
      );
    });

    test('accepts uncapped 5.00–6.00 range', () {
      final result = GainTargetValidator.validateInputs('5.00', '6.00');
      expect(result.isValid, isTrue);
      expect(
        result.target,
        equals(
          const GainTargetEntity(minWeeklyGainKg: 5.0, maxWeeklyGainKg: 6.0),
        ),
      );
    });

    test('identifies empty input errors on both fields', () {
      final result = GainTargetValidator.validateInputs('', '');
      expect(result.isValid, isFalse);
      expect(result.minError, equals('Please enter a minimum gain rate'));
      expect(result.maxError, equals('Please enter a maximum gain rate'));
      expect(result.target, isNull);
    });

    test('identifies malformed minimum input', () {
      final result = GainTargetValidator.validateInputs('abc', '0.25');
      expect(result.isValid, isFalse);
      expect(result.minError, contains('up to 2 decimal places'));
      expect(result.maxError, isNull);
      expect(result.target, isNull);
    });

    test('identifies 3-decimal input on maximum field', () {
      final result = GainTargetValidator.validateInputs('0.15', '0.255');
      expect(result.isValid, isFalse);
      expect(result.minError, isNull);
      expect(result.maxError, contains('up to 2 decimal places'));
      expect(result.target, isNull);
    });

    test('identifies scientific notation input', () {
      final result = GainTargetValidator.validateInputs('1e2', '200');
      expect(result.isValid, isFalse);
      expect(result.minError, contains('up to 2 decimal places'));
      expect(result.maxError, isNull);
    });

    test('identifies zero input', () {
      final result = GainTargetValidator.validateInputs('0', '0.25');
      expect(result.isValid, isFalse);
      expect(result.minError, contains('greater than 0 kg/week'));
      expect(result.maxError, isNull);
    });

    test('identifies equal endpoints range error', () {
      final result = GainTargetValidator.validateInputs('0.20', '0.20');
      expect(result.isValid, isFalse);
      expect(result.minError, isNull);
      expect(result.maxError, isNull);
      expect(
        result.rangeError,
        contains('Maximum gain rate must be greater than minimum'),
      );
      expect(
        result.effectiveMaxError,
        contains('Maximum gain rate must be greater than minimum'),
      );
      expect(result.target, isNull);
    });

    test('identifies reversed endpoints range error', () {
      final result = GainTargetValidator.validateInputs('0.30', '0.20');
      expect(result.isValid, isFalse);
      expect(result.minError, isNull);
      expect(result.maxError, isNull);
      expect(
        result.rangeError,
        contains('Maximum gain rate must be greater than minimum'),
      );
      expect(result.target, isNull);
    });

    test('validateInputsError helper returns first error', () {
      expect(GainTargetValidator.validateInputsError('0.15', '0.25'), isNull);
      expect(
        GainTargetValidator.validateInputsError('', '0.25'),
        equals('Please enter a minimum gain rate'),
      );
      expect(
        GainTargetValidator.validateInputsError('0.30', '0.20'),
        contains('Maximum gain rate must be greater than minimum'),
      );
    });

    test('GainTargetValidationResult value equality', () {
      const result1 = GainTargetValidationResult(
        minError: 'error',
        maxError: null,
      );
      const result2 = GainTargetValidationResult(
        minError: 'error',
        maxError: null,
      );
      const result3 = GainTargetValidationResult(
        minError: null,
        maxError: 'error',
      );

      expect(result1, equals(result2));
      expect(result1.hashCode, equals(result2.hashCode));
      expect(result1, isNot(equals(result3)));
      expect(result1.toString(), contains('minError: error'));
    });
  });
}
