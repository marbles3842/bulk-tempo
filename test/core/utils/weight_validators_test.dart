import 'package:bulk_tempo/core/utils/weight_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeightValidators constants', () {
    test('exposes expected limits', () {
      expect(WeightValidators.minWeightKg, equals(20.0));
      expect(WeightValidators.maxWeightKg, equals(300.0));
      expect(WeightValidators.maxLookbackDays, equals(365));
    });
  });

  group('WeightValidators.parseWeightKg', () {
    test('parses integer weights', () {
      expect(WeightValidators.parseWeightKg('75'), equals(75.0));
    });

    test('parses dot decimal separators up to 2 decimal places', () {
      expect(WeightValidators.parseWeightKg('82.5'), equals(82.5));
      expect(WeightValidators.parseWeightKg('82.45'), equals(82.45));
    });

    test('parses comma decimal separators up to 2 decimal places', () {
      expect(WeightValidators.parseWeightKg('82,5'), equals(82.5));
      expect(WeightValidators.parseWeightKg('82,45'), equals(82.45));
    });

    test('trims surrounding whitespace', () {
      expect(WeightValidators.parseWeightKg('  82.45  '), equals(82.45));
      expect(WeightValidators.parseWeightKg('\t82,5\n'), equals(82.5));
    });

    test('returns null for empty or whitespace-only inputs', () {
      expect(WeightValidators.parseWeightKg(''), isNull);
      expect(WeightValidators.parseWeightKg('   '), isNull);
    });

    test('returns null for more than 2 decimal places', () {
      expect(WeightValidators.parseWeightKg('80.123'), isNull);
      expect(WeightValidators.parseWeightKg('80,123'), isNull);
    });

    test('returns null for missing leading digits', () {
      expect(WeightValidators.parseWeightKg('.5'), isNull);
      expect(WeightValidators.parseWeightKg(',5'), isNull);
    });

    test('returns null for invalid characters or formats', () {
      expect(WeightValidators.parseWeightKg('abc'), isNull);
      expect(WeightValidators.parseWeightKg('80kg'), isNull);
      expect(WeightValidators.parseWeightKg('-75.5'), isNull);
      expect(WeightValidators.parseWeightKg('75..5'), isNull);
      expect(WeightValidators.parseWeightKg('75.,5'), isNull);
      expect(WeightValidators.parseWeightKg('75.5.5'), isNull);
    });
  });

  group('WeightValidators.validateWeightInput', () {
    test('returns error for empty input', () {
      final error = WeightValidators.validateWeightInput('');
      expect(error, equals('Please enter a weight'));
    });

    test('returns error for unparseable input', () {
      final error = WeightValidators.validateWeightInput('invalid');
      expect(error, contains('Enter a valid weight'));
    });

    test('returns error for more than 2 decimal places', () {
      final error = WeightValidators.validateWeightInput('80.125');
      expect(error, contains('Enter a valid weight'));
    });

    test('rejects values below minWeightKg (20.0)', () {
      final error = WeightValidators.validateWeightInput('19.99');
      expect(error, contains('between 20.0 and 300.0 kg'));
    });

    test('rejects values above maxWeightKg (300.0)', () {
      final error = WeightValidators.validateWeightInput('300.01');
      expect(error, contains('between 20.0 and 300.0 kg'));
    });

    test('accepts exact lower bound 20.0 kg', () {
      expect(WeightValidators.validateWeightInput('20.0'), isNull);
      expect(WeightValidators.validateWeightInput('20'), isNull);
    });

    test('accepts exact upper bound 300.0 kg', () {
      expect(WeightValidators.validateWeightInput('300.0'), isNull);
      expect(WeightValidators.validateWeightInput('300'), isNull);
    });

    test('accepts valid weights with comma or dot separators', () {
      expect(WeightValidators.validateWeightInput('78.45'), isNull);
      expect(WeightValidators.validateWeightInput('78,45'), isNull);
      expect(WeightValidators.validateWeightInput('  82.5  '), isNull);
    });
  });

  group('WeightValidators.validateEntryDate', () {
    final now = DateTime(2026, 10, 10, 15, 30);

    test('accepts today regardless of time-of-day', () {
      final todayMorning = DateTime(2026, 10, 10, 6, 0);
      final todayEvening = DateTime(2026, 10, 10, 23, 59);

      expect(
        WeightValidators.validateEntryDate(todayMorning, now: now),
        isNull,
      );
      expect(
        WeightValidators.validateEntryDate(todayEvening, now: now),
        isNull,
      );
      expect(WeightValidators.validateEntryDate(now, now: now), isNull);
    });

    test('rejects tomorrow and future dates', () {
      final tomorrow = DateTime(2026, 10, 11, 0, 1);
      final future = DateTime(2027, 1, 1);

      expect(
        WeightValidators.validateEntryDate(tomorrow, now: now),
        equals('Date cannot be in the future'),
      );
      expect(
        WeightValidators.validateEntryDate(future, now: now),
        equals('Date cannot be in the future'),
      );
    });

    test('accepts historical dates within 365 days', () {
      final yesterday = DateTime(2026, 10, 9);
      final monthAgo = DateTime(2026, 9, 10);
      final exact365DaysAgo = DateTime(2025, 10, 10);

      expect(WeightValidators.validateEntryDate(yesterday, now: now), isNull);
      expect(WeightValidators.validateEntryDate(monthAgo, now: now), isNull);
      expect(
        WeightValidators.validateEntryDate(exact365DaysAgo, now: now),
        isNull,
      );
    });

    test('rejects historical dates older than 365 days', () {
      final day366Ago = DateTime(2025, 10, 9);
      final twoYearsAgo = DateTime(2024, 10, 10);

      expect(
        WeightValidators.validateEntryDate(day366Ago, now: now),
        equals('Date cannot be more than 365 days in the past'),
      );
      expect(
        WeightValidators.validateEntryDate(twoYearsAgo, now: now),
        equals('Date cannot be more than 365 days in the past'),
      );
    });

    test('handles leap year lookback calculations safely', () {
      // Leap year reference: 2024-03-01
      final leapRef = DateTime(2024, 3, 1, 12, 0);
      // 365 days before 2024-03-01 is 2023-03-02 (2024 has Feb 29)
      final exact365BeforeLeap = DateTime(2023, 3, 2);
      final day366BeforeLeap = DateTime(2023, 3, 1);

      expect(
        WeightValidators.validateEntryDate(exact365BeforeLeap, now: leapRef),
        isNull,
      );
      expect(
        WeightValidators.validateEntryDate(day366BeforeLeap, now: leapRef),
        equals('Date cannot be more than 365 days in the past'),
      );
    });
  });
}
