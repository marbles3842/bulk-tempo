import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';
import 'package:bulk_tempo/features/weight/domain/models/weekly_weight_summary_entity.dart';

void main() {
  group('WeeklyWeightSummaryEntity', () {
    test('supports value equality', () {
      final entry = WeightEntryEntity(
        dateIso: '2026-10-05',
        date: DateTime.utc(2026, 10, 5),
        weightKg: 80.0,
        updatedAt: DateTime.utc(2026, 10, 5),
      );

      final summary1 = WeeklyWeightSummaryEntity(
        weekStartIso: '2026-10-05',
        weekStartMonday: DateTime.utc(2026, 10, 5),
        weekEndSunday: DateTime.utc(2026, 10, 11),
        averageWeightKg: 80.0,
        entries: [entry],
      );

      final summary2 = WeeklyWeightSummaryEntity(
        weekStartIso: '2026-10-05',
        weekStartMonday: DateTime.utc(2026, 10, 5),
        weekEndSunday: DateTime.utc(2026, 10, 11),
        averageWeightKg: 80.0,
        entries: [entry],
      );

      expect(summary1, equals(summary2));
      expect(summary1.hashCode, equals(summary2.hashCode));
      expect(summary1.loggedDaysCount, 1);
    });

    test('copyWith updates fields correctly', () {
      final summary = WeeklyWeightSummaryEntity(
        weekStartIso: '2026-10-05',
        weekStartMonday: DateTime.utc(2026, 10, 5),
        weekEndSunday: DateTime.utc(2026, 10, 11),
        averageWeightKg: 80.0,
        entries: const [],
      );

      final updated = summary.copyWith(averageWeightKg: 81.5);
      expect(updated.averageWeightKg, 81.5);
      expect(updated.weekStartIso, '2026-10-05');
    });

    group('groupEntriesByIsoWeek', () {
      test('returns empty list for empty entries', () {
        final result = WeeklyWeightSummaryEntity.groupEntriesByIsoWeek([]);
        expect(result, isEmpty);
      });

      test('handles 1-day week correctly', () {
        final entry = WeightEntryEntity(
          dateIso: '2026-10-07', // Wednesday
          date: DateTime.utc(2026, 10, 7),
          weightKg: 82.5,
          updatedAt: DateTime.utc(2026, 10, 7, 8),
        );

        final summaries = WeeklyWeightSummaryEntity.groupEntriesByIsoWeek([
          entry,
        ]);

        expect(summaries.length, 1);
        final summary = summaries.first;
        expect(summary.weekStartIso, '2026-10-05'); // Monday
        expect(summary.weekStartMonday, DateTime.utc(2026, 10, 5));
        expect(summary.weekEndSunday, DateTime.utc(2026, 10, 11));
        expect(summary.averageWeightKg, 82.5);
        expect(summary.loggedDaysCount, 1);
        expect(summary.entries.first, entry);
      });

      test('handles 7-day week and rounds average to 2 decimal places', () {
        // Monday 2026-10-05 to Sunday 2026-10-11
        final weights = [80.1, 80.2, 80.4, 80.3, 80.5, 80.6, 80.8];
        // Sum = 562.9, 562.9 / 7 = 80.4142857... -> 80.41
        final entries = <WeightEntryEntity>[];
        for (int i = 0; i < 7; i++) {
          final day = 5 + i;
          final dateIso = '2026-10-${day.toString().padLeft(2, '0')}';
          entries.add(
            WeightEntryEntity(
              dateIso: dateIso,
              date: DateTime.utc(2026, 10, day),
              weightKg: weights[i],
              updatedAt: DateTime.utc(2026, 10, day, 8),
            ),
          );
        }

        final summaries = WeeklyWeightSummaryEntity.groupEntriesByIsoWeek(
          entries,
        );

        expect(summaries.length, 1);
        final summary = summaries.first;
        expect(summary.weekStartIso, '2026-10-05');
        expect(summary.loggedDaysCount, 7);
        expect(summary.averageWeightKg, 80.41);
        // entries sorted newest date first (Sunday to Monday)
        expect(summary.entries.first.dateIso, '2026-10-11');
        expect(summary.entries.last.dateIso, '2026-10-05');
      });

      test('omits skipped empty weeks between logged weeks', () {
        // Week 1: Monday 2026-09-28
        // (Skipped Week: Monday 2026-10-05)
        // Week 3: Monday 2026-10-12
        final entryWeek1 = WeightEntryEntity(
          dateIso: '2026-09-30',
          date: DateTime.utc(2026, 9, 30),
          weightKg: 80.0,
          updatedAt: DateTime.utc(2026, 9, 30),
        );
        final entryWeek3 = WeightEntryEntity(
          dateIso: '2026-10-14',
          date: DateTime.utc(2026, 10, 14),
          weightKg: 81.0,
          updatedAt: DateTime.utc(2026, 10, 14),
        );

        final summaries = WeeklyWeightSummaryEntity.groupEntriesByIsoWeek([
          entryWeek1,
          entryWeek3,
        ]);

        expect(summaries.length, 2);
        // Sorted newest week first
        expect(summaries[0].weekStartIso, '2026-10-12');
        expect(summaries[1].weekStartIso, '2026-09-28');
        expect(summaries.any((s) => s.weekStartIso == '2026-10-05'), isFalse);
      });

      test(
        'correctly handles week boundary transitions (Sunday vs Monday)',
        () {
          // Sunday 2026-10-04 (belongs to week of 2026-09-28)
          // Monday 2026-10-05 (belongs to week of 2026-10-05)
          final sundayEntry = WeightEntryEntity(
            dateIso: '2026-10-04',
            date: DateTime.utc(2026, 10, 4),
            weightKg: 79.5,
            updatedAt: DateTime.utc(2026, 10, 4),
          );
          final mondayEntry = WeightEntryEntity(
            dateIso: '2026-10-05',
            date: DateTime.utc(2026, 10, 5),
            weightKg: 80.0,
            updatedAt: DateTime.utc(2026, 10, 5),
          );

          final summaries = WeeklyWeightSummaryEntity.groupEntriesByIsoWeek([
            sundayEntry,
            mondayEntry,
          ]);

          expect(summaries.length, 2);
          expect(summaries[0].weekStartIso, '2026-10-05');
          expect(summaries[0].entries.first.dateIso, '2026-10-05');

          expect(summaries[1].weekStartIso, '2026-09-28');
          expect(summaries[1].entries.first.dateIso, '2026-10-04');
        },
      );

      test(
        'deduplicates entries with identical dateIso keeping latest updatedAt',
        () {
          final olderEntry = WeightEntryEntity(
            dateIso: '2026-10-06',
            date: DateTime.utc(2026, 10, 6),
            weightKg: 80.0,
            updatedAt: DateTime.utc(2026, 10, 6, 8, 0),
          );
          final newerEntry = WeightEntryEntity(
            dateIso: '2026-10-06',
            date: DateTime.utc(2026, 10, 6),
            weightKg: 81.5,
            updatedAt: DateTime.utc(2026, 10, 6, 12, 0),
          );

          final summaries = WeeklyWeightSummaryEntity.groupEntriesByIsoWeek([
            olderEntry,
            newerEntry,
          ]);

          expect(summaries.length, 1);
          expect(summaries.first.entries.length, 1);
          expect(summaries.first.entries.first.weightKg, 81.5);
          expect(summaries.first.averageWeightKg, 81.5);
        },
      );
    });
  });
}
