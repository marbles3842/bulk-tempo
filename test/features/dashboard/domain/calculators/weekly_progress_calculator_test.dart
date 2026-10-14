import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/dashboard/domain/calculators/weekly_progress_calculator.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/weekly_progress_overview_entity.dart';
import 'package:bulk_tempo/features/weight/domain/models/weekly_weight_summary_entity.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/weekly_workout_summary_entity.dart';
import 'package:flutter_test/flutter_test.dart';

WeeklyWeightSummaryEntity _createWeightSummary({
  required String weekStartIso,
  required double averageWeightKg,
  int loggedDaysCount = 7,
}) {
  final monday = WeekDateUtils.tryParseIsoDate(weekStartIso)!;
  final sunday = WeekDateUtils.endOfIsoWeekUtc(monday);
  final entries = List.generate(
    loggedDaysCount,
    (i) => WeightEntryEntity(
      dateIso: WeekDateUtils.toIsoDateString(monday.add(Duration(days: i))),
      date: monday.add(Duration(days: i)),
      weightKg: averageWeightKg,
      updatedAt: monday,
    ),
  );
  return WeeklyWeightSummaryEntity(
    weekStartIso: weekStartIso,
    weekStartMonday: monday,
    weekEndSunday: sunday,
    averageWeightKg: averageWeightKg,
    entries: entries,
  );
}

WeeklyWorkoutSummaryEntity _createWorkoutSummary({
  required String weekStartIso,
  required int workoutCount,
}) {
  final monday = WeekDateUtils.tryParseIsoDate(weekStartIso)!;
  final sunday = WeekDateUtils.endOfIsoWeekUtc(monday);
  return WeeklyWorkoutSummaryEntity(
    weekStartIso: weekStartIso,
    weekStartMonday: monday,
    weekEndSunday: sunday,
    workouts: const [],
    workoutCount: workoutCount,
    totalWorkingSets: workoutCount * 3,
    totalVolumeKg: workoutCount * 1000.0,
  );
}

void main() {
  group('WeeklyProgressCalculator', () {
    // Reference date: Wednesday 2026-10-14.
    // The current ISO week Monday is 2026-10-12 (Sunday 2026-10-18).
    final refNow = DateTime.utc(2026, 10, 14, 15, 30);

    test(
      'empty weights and empty workouts produces 12 calendar slots ending at current ISO week with nulls and zeros',
      () {
        final overview = WeeklyProgressCalculator.calculate(
          allWeightSummaries: const [],
          workoutSummaries: const [],
          now: refNow,
        );

        expect(overview.calendarWeeks.length, equals(12));
        expect(overview.loggedWeightWeeksCount, equals(0));
        expect(overview.currentPaceKgPerWeek, isNull);
        expect(overview.latestAverageWeightKg, isNull);
        expect(overview.latestWeekStartIso, isNull);
        expect(overview.latestWeekStartMonday, isNull);
        expect(overview.latestWeekEndSunday, isNull);
        expect(overview.latestWeekLoggedDays, equals(0));
        expect(overview.isLatestWeekCurrentWeek, isFalse);
        expect(overview.isLatestWeekIncomplete, isFalse);
        expect(overview.totalGainKg, isNull);
        expect(overview.currentWeekWorkoutCount, equals(0));

        // Check slot continuity: oldest index 0 is 11 weeks before current week.
        // Current week Monday: 2026-10-12
        // Slot 0 Monday: 2026-10-12 - 77 days = 2026-07-27
        expect(overview.calendarWeeks.first.weekStartIso, equals('2026-07-27'));
        expect(overview.calendarWeeks.first.isCurrentWeek, isFalse);
        expect(overview.calendarWeeks.last.weekStartIso, equals('2026-10-12'));
        expect(overview.calendarWeeks.last.isCurrentWeek, isTrue);

        for (final slot in overview.calendarWeeks) {
          expect(slot.averageWeightKg, isNull);
          expect(slot.loggedWeightDaysCount, equals(0));
          expect(slot.paceKgPerWeek, isNull);
          expect(slot.workoutCount, equals(0));
        }
      },
    );

    test(
      'single logged weight week in current week with 2 entries sets incomplete flag and null pace/total gain',
      () {
        final currentWeekSummary = _createWeightSummary(
          weekStartIso: '2026-10-12',
          averageWeightKg: 82.50,
          loggedDaysCount: 2,
        );

        final overview = WeeklyProgressCalculator.calculate(
          allWeightSummaries: [currentWeekSummary],
          workoutSummaries: const [],
          now: refNow,
        );

        expect(overview.loggedWeightWeeksCount, equals(1));
        expect(overview.latestAverageWeightKg, equals(82.50));
        expect(overview.latestWeekStartIso, equals('2026-10-12'));
        expect(overview.latestWeekLoggedDays, equals(2));
        expect(overview.isLatestWeekCurrentWeek, isTrue);
        expect(overview.isLatestWeekIncomplete, isTrue);
        expect(overview.currentPaceKgPerWeek, isNull);
        expect(overview.totalGainKg, isNull);

        // Slot 11 (current week) has the weight and null pace
        final currentSlot = overview.calendarWeeks.last;
        expect(currentSlot.averageWeightKg, equals(82.50));
        expect(currentSlot.loggedWeightDaysCount, equals(2));
        expect(currentSlot.paceKgPerWeek, isNull);
      },
    );

    test(
      'single logged weight week in current week with 7 entries sets isLatestWeekIncomplete false',
      () {
        final currentWeekSummary = _createWeightSummary(
          weekStartIso: '2026-10-12',
          averageWeightKg: 83.00,
          loggedDaysCount: 7,
        );

        final overview = WeeklyProgressCalculator.calculate(
          allWeightSummaries: [currentWeekSummary],
          workoutSummaries: const [],
          now: refNow,
        );

        expect(overview.isLatestWeekCurrentWeek, isTrue);
        expect(overview.isLatestWeekIncomplete, isFalse);
        expect(overview.latestWeekLoggedDays, equals(7));
        expect(overview.latestAverageWeightKg, equals(83.00));
        expect(overview.currentPaceKgPerWeek, isNull);
        expect(overview.totalGainKg, isNull);
      },
    );

    test(
      'latest logged weight week in a past week sets isLatestWeekCurrentWeek false and isLatestWeekIncomplete false',
      () {
        // Logged week in previous week (2026-10-05) with 4 entries
        final pastWeekSummary = _createWeightSummary(
          weekStartIso: '2026-10-05',
          averageWeightKg: 81.20,
          loggedDaysCount: 4,
        );

        final overview = WeeklyProgressCalculator.calculate(
          allWeightSummaries: [pastWeekSummary],
          workoutSummaries: const [],
          now: refNow,
        );

        expect(overview.latestWeekStartIso, equals('2026-10-05'));
        expect(overview.latestAverageWeightKg, equals(81.20));
        expect(overview.latestWeekLoggedDays, equals(4));
        expect(overview.isLatestWeekCurrentWeek, isFalse);
        expect(overview.isLatestWeekIncomplete, isFalse);
      },
    );

    test(
      'gap-adjusted pace: W1 avg 80.00 kg, W2-W3 unlogged, W4 avg 80.60 kg yields +0.20 kg/wk and slot 11 pace 0.20',
      () {
        // W1: 2026-09-21 (3 weeks prior to current week 2026-10-12)
        // W2: 2026-09-28 (unlogged)
        // W3: 2026-10-05 (unlogged)
        // W4: 2026-10-12 (current week)
        final w1 = _createWeightSummary(
          weekStartIso: '2026-09-21',
          averageWeightKg: 80.00,
        );
        final w4 = _createWeightSummary(
          weekStartIso: '2026-10-12',
          averageWeightKg: 80.60,
        );

        final overview = WeeklyProgressCalculator.calculate(
          allWeightSummaries: [w4, w1], // Pass unsorted to verify sorting
          workoutSummaries: const [],
          now: refNow,
        );

        expect(overview.loggedWeightWeeksCount, equals(2));
        expect(overview.currentPaceKgPerWeek, equals(0.20));
        expect(overview.totalGainKg, equals(0.60));
        expect(overview.latestAverageWeightKg, equals(80.60));

        // Find slots:
        // Index 8 is 2026-09-21 (W1)
        // Index 9 is 2026-09-28 (W2)
        // Index 10 is 2026-10-05 (W3)
        // Index 11 is 2026-10-12 (W4)
        final slotW1 = overview.calendarWeeks[8];
        final slotW2 = overview.calendarWeeks[9];
        final slotW3 = overview.calendarWeeks[10];
        final slotW4 = overview.calendarWeeks[11];

        expect(slotW1.weekStartIso, equals('2026-09-21'));
        expect(slotW1.averageWeightKg, equals(80.00));
        expect(slotW1.paceKgPerWeek, isNull); // first week in history

        expect(slotW2.weekStartIso, equals('2026-09-28'));
        expect(slotW2.averageWeightKg, isNull);
        expect(slotW2.paceKgPerWeek, isNull);

        expect(slotW3.weekStartIso, equals('2026-10-05'));
        expect(slotW3.averageWeightKg, isNull);
        expect(slotW3.paceKgPerWeek, isNull);

        expect(slotW4.weekStartIso, equals('2026-10-12'));
        expect(slotW4.averageWeightKg, equals(80.60));
        expect(slotW4.paceKgPerWeek, equals(0.20));
      },
    );

    test('negative pace and negative total gain are preserved with sign', () {
      final w1 = _createWeightSummary(
        weekStartIso: '2026-10-05',
        averageWeightKg: 85.00,
      );
      final w2 = _createWeightSummary(
        weekStartIso: '2026-10-12',
        averageWeightKg: 84.65,
      );

      final overview = WeeklyProgressCalculator.calculate(
        allWeightSummaries: [w1, w2],
        workoutSummaries: const [],
        now: refNow,
      );

      expect(overview.currentPaceKgPerWeek, equals(-0.35));
      expect(overview.totalGainKg, equals(-0.35));
      expect(overview.calendarWeeks.last.paceKgPerWeek, equals(-0.35));
    });

    test(
      'total gain and first-visible-slot pace use full history older than 12 calendar weeks',
      () {
        // Current week: 2026-10-12 (index 11)
        // Window slot 0: 2026-07-27 (11 weeks before current week)
        // Entry 16 weeks ago: 2026-06-22 (avg: 75.00 kg)
        // Entry at slot 0: 2026-07-27 (5 weeks after 2026-06-22, avg: 76.50 kg)
        // Entry at current week: 2026-10-12 (avg: 78.50 kg)
        final wOldest = _createWeightSummary(
          weekStartIso: '2026-06-22',
          averageWeightKg: 75.00,
        );
        final wSlot0 = _createWeightSummary(
          weekStartIso: '2026-07-27',
          averageWeightKg: 76.50,
        );
        final wCurrent = _createWeightSummary(
          weekStartIso: '2026-10-12',
          averageWeightKg: 78.50,
        );

        final overview = WeeklyProgressCalculator.calculate(
          allWeightSummaries: [wOldest, wSlot0, wCurrent],
          workoutSummaries: const [],
          now: refNow,
        );

        // Total gain: 78.50 - 75.00 = +3.50 kg (spans outside the 12-week window)
        expect(overview.totalGainKg, equals(3.50));
        expect(overview.loggedWeightWeeksCount, equals(3));

        // Slot 0 (2026-07-27) pace computed against 2026-06-22 (5 weeks between):
        // (76.50 - 75.00) / 5 = 1.50 / 5 = 0.30 kg/week
        final slot0 = overview.calendarWeeks[0];
        expect(slot0.weekStartIso, equals('2026-07-27'));
        expect(slot0.averageWeightKg, equals(76.50));
        expect(slot0.paceKgPerWeek, equals(0.30));

        // Slot 11 (2026-10-12) pace computed against 2026-07-27 (11 weeks between):
        // (78.50 - 76.50) / 11 = 2.00 / 11 = 0.1818... -> 0.18
        final slot11 = overview.calendarWeeks[11];
        expect(slot11.paceKgPerWeek, equals(0.18));
        expect(overview.currentPaceKgPerWeek, equals(0.18));
      },
    );

    test(
      'workout counts map onto matching calendar weeks and default to 0',
      () {
        final wo1 = _createWorkoutSummary(
          weekStartIso: '2026-10-05',
          workoutCount: 4,
        );
        final wo2 = _createWorkoutSummary(
          weekStartIso: '2026-10-12',
          workoutCount: 3,
        );

        final overview = WeeklyProgressCalculator.calculate(
          allWeightSummaries: const [],
          workoutSummaries: [wo1, wo2],
          now: refNow,
        );

        expect(overview.currentWeekWorkoutCount, equals(3));
        expect(overview.calendarWeeks[10].workoutCount, equals(4));
        expect(overview.calendarWeeks[11].workoutCount, equals(3));
        // Unmatched weeks have workoutCount == 0
        for (int i = 0; i < 10; i++) {
          expect(overview.calendarWeeks[i].workoutCount, equals(0));
        }
      },
    );

    test('entities support value equality, constructors and toString', () {
      final explicitSlot = CalendarWeekProgressSlotEntity(
        weekStartIso: '2026-10-12',
        weekStartMonday: DateTime.utc(2026, 10, 12),
        weekEndSunday: DateTime.utc(2026, 10, 18),
        averageWeightKg: 82.0,
        loggedWeightDaysCount: 4,
        paceKgPerWeek: 0.15,
        workoutCount: 3,
        isCurrentWeek: true,
      );

      expect(explicitSlot.weekStartIso, equals('2026-10-12'));
      expect(explicitSlot.averageWeightKg, equals(82.0));
      expect(explicitSlot.loggedWeightDaysCount, equals(4));
      expect(explicitSlot.paceKgPerWeek, equals(0.15));
      expect(explicitSlot.workoutCount, equals(3));
      expect(explicitSlot.isCurrentWeek, isTrue);

      final explicitOverview = WeeklyProgressOverviewEntity(
        calendarWeeks: [explicitSlot],
        currentPaceKgPerWeek: 0.15,
        latestAverageWeightKg: 82.0,
        latestWeekStartIso: '2026-10-12',
        latestWeekStartMonday: DateTime.utc(2026, 10, 12),
        latestWeekEndSunday: DateTime.utc(2026, 10, 18),
        latestWeekLoggedDays: 4,
        isLatestWeekCurrentWeek: true,
        isLatestWeekIncomplete: true,
        totalGainKg: 1.5,
        currentWeekWorkoutCount: 3,
        loggedWeightWeeksCount: 1,
      );

      expect(explicitOverview.calendarWeeks, equals([explicitSlot]));
      expect(explicitOverview.currentPaceKgPerWeek, equals(0.15));
      expect(explicitOverview.latestAverageWeightKg, equals(82.0));
      expect(explicitOverview.isLatestWeekIncomplete, isTrue);

      final overview1 = WeeklyProgressCalculator.calculate(
        allWeightSummaries: const [],
        workoutSummaries: const [],
        now: refNow,
      );
      final overview2 = WeeklyProgressCalculator.calculate(
        allWeightSummaries: const [],
        workoutSummaries: const [],
        now: refNow,
      );

      expect(overview1, equals(overview2));
      expect(overview1.hashCode, equals(overview2.hashCode));
      expect(overview1.toString(), contains('WeeklyProgressOverviewEntity'));

      final slot1 = overview1.calendarWeeks.first;
      final slot2 = overview2.calendarWeeks.first;
      expect(slot1, equals(slot2));
      expect(slot1.hashCode, equals(slot2.hashCode));
      expect(slot1.toString(), contains('CalendarWeekProgressSlotEntity'));
    });
  });
}
