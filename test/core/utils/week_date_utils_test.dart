import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeekDateUtils.normalizeDateUtc', () {
    test('strips time components and returns UTC midnight', () {
      final date = DateTime(2026, 10, 5, 14, 30, 45, 123);
      final normalized = WeekDateUtils.normalizeDateUtc(date);

      expect(normalized.isUtc, isTrue);
      expect(normalized.year, equals(2026));
      expect(normalized.month, equals(10));
      expect(normalized.day, equals(5));
      expect(normalized.hour, equals(0));
      expect(normalized.minute, equals(0));
      expect(normalized.second, equals(0));
      expect(normalized.millisecond, equals(0));
    });
  });

  group('WeekDateUtils.toIsoDateString', () {
    test('formats dates as YYYY-MM-DD with zero-padding', () {
      expect(
        WeekDateUtils.toIsoDateString(DateTime.utc(2026, 10, 5)),
        equals('2026-10-05'),
      );
      expect(
        WeekDateUtils.toIsoDateString(DateTime.utc(2026, 1, 9)),
        equals('2026-01-09'),
      );
      expect(
        WeekDateUtils.toIsoDateString(DateTime.utc(2026, 12, 31)),
        equals('2026-12-31'),
      );
    });
  });

  group('WeekDateUtils.tryParseIsoDate', () {
    test('strictly parses valid YYYY-MM-DD into UTC DateTime', () {
      final parsed = WeekDateUtils.tryParseIsoDate('2026-10-05');
      expect(parsed, equals(DateTime.utc(2026, 10, 5)));
      expect(parsed?.isUtc, isTrue);
    });

    test('accepts valid leap year Feb 29', () {
      final leap = WeekDateUtils.tryParseIsoDate('2024-02-29');
      expect(leap, equals(DateTime.utc(2024, 2, 29)));
    });

    test('rejects non-leap year Feb 29', () {
      expect(WeekDateUtils.tryParseIsoDate('2025-02-29'), isNull);
    });

    test('rejects non-existent calendar dates', () {
      expect(WeekDateUtils.tryParseIsoDate('2026-02-30'), isNull);
      expect(WeekDateUtils.tryParseIsoDate('2026-04-31'), isNull);
      expect(WeekDateUtils.tryParseIsoDate('2026-00-10'), isNull);
      expect(WeekDateUtils.tryParseIsoDate('2026-13-01'), isNull);
      expect(WeekDateUtils.tryParseIsoDate('2026-01-00'), isNull);
      expect(WeekDateUtils.tryParseIsoDate('2026-01-32'), isNull);
    });

    test('rejects non-conforming or malformed date strings', () {
      expect(WeekDateUtils.tryParseIsoDate(''), isNull);
      expect(WeekDateUtils.tryParseIsoDate('   '), isNull);
      expect(WeekDateUtils.tryParseIsoDate('2026/10/05'), isNull);
      expect(WeekDateUtils.tryParseIsoDate('2026-1-5'), isNull);
      expect(WeekDateUtils.tryParseIsoDate('2026-10-05T00:00:00Z'), isNull);
      expect(WeekDateUtils.tryParseIsoDate('not-a-date'), isNull);
    });
  });

  group('WeekDateUtils.startOfIsoWeekUtc & endOfIsoWeekUtc', () {
    test('resolves Monday and Sunday for every day within a week', () {
      // 2026-10-05 is Monday, 2026-10-11 is Sunday
      final expectedMonday = DateTime.utc(2026, 10, 5);
      final expectedSunday = DateTime.utc(2026, 10, 11);

      for (var day = 5; day <= 11; day++) {
        final date = DateTime.utc(2026, 10, day);
        expect(
          WeekDateUtils.startOfIsoWeekUtc(date),
          equals(expectedMonday),
          reason: 'Failed for day $day',
        );
        expect(
          WeekDateUtils.endOfIsoWeekUtc(date),
          equals(expectedSunday),
          reason: 'Failed for day $day',
        );
      }
    });

    test('handles month boundaries properly', () {
      // 2026-09-28 (Mon) to 2026-10-04 (Sun)
      final expectedMonday = DateTime.utc(2026, 9, 28);
      final expectedSunday = DateTime.utc(2026, 10, 4);

      final oct1 = DateTime.utc(2026, 10, 1); // Thursday
      final sep30 = DateTime.utc(2026, 9, 30); // Wednesday

      expect(WeekDateUtils.startOfIsoWeekUtc(oct1), equals(expectedMonday));
      expect(WeekDateUtils.endOfIsoWeekUtc(oct1), equals(expectedSunday));
      expect(WeekDateUtils.startOfIsoWeekUtc(sep30), equals(expectedMonday));
      expect(WeekDateUtils.endOfIsoWeekUtc(sep30), equals(expectedSunday));
    });

    test('handles year boundaries properly', () {
      // 2026-12-28 (Mon) to 2027-01-03 (Sun)
      final expectedMonday = DateTime.utc(2026, 12, 28);
      final expectedSunday = DateTime.utc(2027, 1, 3);

      final dec31 = DateTime.utc(2026, 12, 31); // Thursday
      final jan1 = DateTime.utc(2027, 1, 1); // Friday
      final jan3 = DateTime.utc(2027, 1, 3); // Sunday

      expect(WeekDateUtils.startOfIsoWeekUtc(dec31), equals(expectedMonday));
      expect(WeekDateUtils.endOfIsoWeekUtc(dec31), equals(expectedSunday));
      expect(WeekDateUtils.startOfIsoWeekUtc(jan1), equals(expectedMonday));
      expect(WeekDateUtils.endOfIsoWeekUtc(jan1), equals(expectedSunday));
      expect(WeekDateUtils.startOfIsoWeekUtc(jan3), equals(expectedMonday));
      expect(WeekDateUtils.endOfIsoWeekUtc(jan3), equals(expectedSunday));
    });
  });

  group('WeekDateUtils formatting', () {
    test('formatWeekRange formats same-year weeks with en-dash', () {
      final monSameMonth = DateTime.utc(2026, 10, 5);
      final sunSameMonth = DateTime.utc(2026, 10, 11);
      expect(
        WeekDateUtils.formatWeekRange(monSameMonth, sunSameMonth),
        equals('Oct 5 – Oct 11, 2026'),
      );

      final monCrossMonth = DateTime.utc(2026, 9, 28);
      final sunCrossMonth = DateTime.utc(2026, 10, 4);
      expect(
        WeekDateUtils.formatWeekRange(monCrossMonth, sunCrossMonth),
        equals('Sep 28 – Oct 4, 2026'),
      );
    });

    test('formatWeekRange formats cross-year weeks with both years', () {
      final monCrossYear = DateTime.utc(2026, 12, 28);
      final sunCrossYear = DateTime.utc(2027, 1, 3);
      expect(
        WeekDateUtils.formatWeekRange(monCrossYear, sunCrossYear),
        equals('Dec 28, 2026 – Jan 3, 2027'),
      );
    });

    test('formatShortWeekLabel formats month and day', () {
      expect(
        WeekDateUtils.formatShortWeekLabel(DateTime.utc(2026, 10, 5)),
        equals('Oct 5'),
      );
      expect(
        WeekDateUtils.formatShortWeekLabel(DateTime.utc(2026, 9, 28)),
        equals('Sep 28'),
      );
    });

    test(
      'formatDayWithWeekday formats abbreviated weekday, month, day, year',
      () {
        expect(
          WeekDateUtils.formatDayWithWeekday(DateTime.utc(2026, 10, 5)),
          equals('Mon, Oct 5, 2026'),
        );
        expect(
          WeekDateUtils.formatDayWithWeekday(DateTime.utc(2026, 10, 11)),
          equals('Sun, Oct 11, 2026'),
        );
        expect(
          WeekDateUtils.formatDayWithWeekday(DateTime.utc(2027, 1, 1)),
          equals('Fri, Jan 1, 2027'),
        );
      },
    );

    test('roundToTwoDecimals correctly rounds doubles', () {
      expect(WeekDateUtils.roundToTwoDecimals(82.456), equals(82.46));
      expect(WeekDateUtils.roundToTwoDecimals(82.454), equals(82.45));
      expect(WeekDateUtils.roundToTwoDecimals(82.455), equals(82.46));
      expect(WeekDateUtils.roundToTwoDecimals(82.0), equals(82.0));
      expect(WeekDateUtils.roundToTwoDecimals(82.4), equals(82.4));
      expect(WeekDateUtils.roundToTwoDecimals(20.0), equals(20.0));
    });
  });
}
