import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/dashboard/domain/calculators/weekly_progress_calculator.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/weekly_progress_overview_entity.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';
import 'package:bulk_tempo/features/weight/domain/models/weekly_weight_summary_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/weekly_workout_summary_entity.dart';

WeeklyWeightSummaryEntity _createWeightSummary({
  required String weekStartIso,
  required double averageWeightKg,
  int loggedDaysCount = 1,
}) {
  final monday = WeekDateUtils.tryParseIsoDate(weekStartIso)!;
  final sunday = WeekDateUtils.endOfIsoWeekUtc(monday);
  final entries = List.generate(
    loggedDaysCount,
    (index) => WeightEntryEntity(
      dateIso: WeekDateUtils.toIsoDateString(monday.add(Duration(days: index))),
      date: monday.add(Duration(days: index)),
      weightKg: averageWeightKg,
      updatedAt: monday.add(Duration(days: index)),
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
    // Wednesday 2026-10-14, which falls into the ISO week starting Monday 2026-10-12.
    final testNow = DateTime.utc(2026, 10, 14, 15, 30);
    const currentWeekMondayIso = '2026-10-12';

    test('empty weights and workouts produces 12 empty calendar slots', () {
      final overview = WeeklyProgressCalculator.calculate(
        allWeightSummaries: const [],
        workoutSummaries: const [],
        now: testNow,
      );

      expect(overview.calendarWeeks.length, 12);
      expect(overview.currentPaceKgPerWeek, isNull);
      expect(overview.latestAverageWeightKg, isNull);
      expect(overview.latestWeekStartIso, isNull);
      expect(overview.latestWeekStartMonday, isNull);
      expect(overview.latestWeekEndSunday, isNull);
      expect(overview.latestWeekLoggedDays, 0);
      expect(overview.isLatestWeekCurrentWeek, isFalse);
      expect(overview.isLatestWeekIncomplete, isFalse);
      expect(overview.totalGainKg, isNull);
      expect(overview.currentWeekWorkoutCount, 0);
      expect(overview.loggedWeightWeeksCount, 0);

      // Verify slot index 11 is current week
      final currentSlot = overview.calendarWeeks.last;
      expect(currentSlot.weekStartIso, currentWeekMondayIso);
      expect(currentSlot.isCurrentWeek, isTrue);

      for (int i = 0; i < 12; i++) {
        final slot = overview.calendarWeeks[i];
        expect(slot.averageWeightKg, isNull);
        expect(slot.paceKgPerWeek, isNull);
        expect(slot.workoutCount, 0);
        expect(slot.loggedWeightDaysCount, 0);
        expect(slot.isCurrentWeek, i == 11);
      }

      // Oldest slot (index 0) is 11 weeks before 2026-10-12 -> 2026-07-27
      expect(overview.calendarWeeks.first.weekStartIso, '2026-07-27');
    });

    test(
      'single logged weight week in current week with 2 entries flags incomplete',
      () {
        final weightSummary = _createWeightSummary(
          weekStartIso: currentWeekMondayIso,
          averageWeightKg: 80.5,
          loggedDaysCount: 2,
        );

        final overview = WeeklyProgressCalculator.calculate(
          allWeightSummaries: [weightSummary],
          workoutSummaries: const [],
          now: testNow,
        );

        expect(overview.latestAverageWeightKg, 80.5);
        expect(overview.latestWeekStartIso, currentWeekMondayIso);
        expect(overview.latestWeekLoggedDays, 2);
        expect(overview.isLatestWeekCurrentWeek, isTrue);
        expect(overview.isLatestWeekIncomplete, isTrue);
        expect(overview.currentPaceKgPerWeek, isNull);
        expect(overview.totalGainKg, isNull);
        expect(overview.loggedWeightWeeksCount, 1);

        final currentSlot = overview.calendarWeeks[11];
        expect(currentSlot.averageWeightKg, 80.5);
        expect(currentSlot.loggedWeightDaysCount, 2);
        expect(currentSlot.paceKgPerWeek, isNull);
      },
    );

    test(
      'single logged weight week in current week with 7 entries is not incomplete',
      () {
        final weightSummary = _createWeightSummary(
          weekStartIso: currentWeekMondayIso,
          averageWeightKg: 80.5,
          loggedDaysCount: 7,
        );

        final overview = WeeklyProgressCalculator.calculate(
          allWeightSummaries: [weightSummary],
          workoutSummaries: const [],
          now: testNow,
        );

        expect(overview.latestAverageWeightKg, 80.5);
        expect(overview.isLatestWeekCurrentWeek, isTrue);
        expect(overview.isLatestWeekIncomplete, isFalse);
        expect(overview.latestWeekLoggedDays, 7);
      },
    );

    test(
      'latest logged weight in past week marks isLatestWeekCurrentWeek and isLatestWeekIncomplete false',
      () {
        // Past week: 2026-10-05 (1 week before current week 2026-10-12)
        final pastWeightSummary = _createWeightSummary(
          weekStartIso: '2026-10-05',
          averageWeightKg: 79.8,
          loggedDaysCount: 3,
        );

        final overview = WeeklyProgressCalculator.calculate(
          allWeightSummaries: [pastWeightSummary],
          workoutSummaries: const [],
          now: testNow,
        );

        expect(overview.latestAverageWeightKg, 79.8);
        expect(overview.latestWeekStartIso, '2026-10-05');
        expect(overview.isLatestWeekCurrentWeek, isFalse);
        expect(overview.isLatestWeekIncomplete, isFalse);
        expect(overview.latestWeekLoggedDays, 3);
        expect(overview.calendarWeeks[11].averageWeightKg, isNull);
        expect(overview.calendarWeeks[10].averageWeightKg, 79.8);
      },
    );

    test(
      'gap-adjusted pace: W1 (2026-09-21) avg 80.00, W4 (2026-10-12) avg 80.60 yields +0.20 kg/week',
      () {
        final w1 = _createWeightSummary(
          weekStartIso: '2026-09-21',
          averageWeightKg: 80.00,
          loggedDaysCount: 5,
        );
        final w4 = _createWeightSummary(
          weekStartIso: '2026-10-12',
          averageWeightKg: 80.60,
          loggedDaysCount: 4,
        );

        final overview = WeeklyProgressCalculator.calculate(
          allWeightSummaries: [
            w4,
            w1,
          ], // Pass unordered to verify internal sorting
          workoutSummaries: const [],
          now: testNow,
        );

        expect(overview.loggedWeightWeeksCount, 2);
        expect(overview.currentPaceKgPerWeek, 0.20);
        expect(overview.totalGainKg, 0.60);
        expect(overview.latestAverageWeightKg, 80.60);

        // Slot 11 (2026-10-12) has pace 0.20
        final slot11 = overview.calendarWeeks[11];
        expect(slot11.weekStartIso, '2026-10-12');
        expect(slot11.averageWeightKg, 80.60);
        expect(slot11.paceKgPerWeek, 0.20);

        // Slot 8 (2026-09-21) has weight 80.00 but pace null (first logged in history)
        final slot8 = overview.calendarWeeks[8];
        expect(slot8.weekStartIso, '2026-09-21');
        expect(slot8.averageWeightKg, 80.00);
        expect(slot8.paceKgPerWeek, isNull);

        // Unlogged gap slots W2 (2026-09-28) and W3 (2026-10-05) have null average and null pace
        final slot9 = overview.calendarWeeks[9];
        expect(slot9.weekStartIso, '2026-09-28');
        expect(slot9.averageWeightKg, isNull);
        expect(slot9.paceKgPerWeek, isNull);

        final slot10 = overview.calendarWeeks[10];
        expect(slot10.weekStartIso, '2026-10-05');
        expect(slot10.averageWeightKg, isNull);
        expect(slot10.paceKgPerWeek, isNull);
      },
    );

    test('preserves negative pace and negative total gain with sign', () {
      final w1 = _createWeightSummary(
        weekStartIso: '2026-10-05',
        averageWeightKg: 80.70,
        loggedDaysCount: 7,
      );
      final w2 = _createWeightSummary(
        weekStartIso: '2026-10-12',
        averageWeightKg: 80.35,
        loggedDaysCount: 7,
      );

      final overview = WeeklyProgressCalculator.calculate(
        allWeightSummaries: [w1, w2],
        workoutSummaries: const [],
        now: testNow,
      );

      expect(overview.currentPaceKgPerWeek, -0.35);
      expect(overview.totalGainKg, -0.35);
      expect(overview.calendarWeeks[11].paceKgPerWeek, -0.35);
    });

    test(
      'total gain and first-visible-slot pace use full history beyond 12 calendar weeks',
      () {
        // Slot 0 of 12-week window is 2026-07-27 (11 weeks before 2026-10-12).
        // Older entries:
        // - 16 weeks ago: 2026-06-22 (outside 12-week window) with 75.00 kg
        // - 13 weeks ago: 2026-07-13 (outside 12-week window) with 75.60 kg
        // - 11 weeks ago: 2026-07-27 (slot 0 in 12-week window) with 76.20 kg (2 weeks gap -> +0.30 kg/wk)
        // - Current week: 2026-10-12 (slot 11) with 78.50 kg
        final w16 = _createWeightSummary(
          weekStartIso: '2026-06-22',
          averageWeightKg: 75.00,
          loggedDaysCount: 7,
        );
        final w13 = _createWeightSummary(
          weekStartIso: '2026-07-13',
          averageWeightKg: 75.60,
          loggedDaysCount: 7,
        );
        final w11 = _createWeightSummary(
          weekStartIso: '2026-07-27',
          averageWeightKg: 76.20,
          loggedDaysCount: 7,
        );
        final wCurrent = _createWeightSummary(
          weekStartIso: '2026-10-12',
          averageWeightKg: 78.50,
          loggedDaysCount: 4,
        );

        final overview = WeeklyProgressCalculator.calculate(
          allWeightSummaries: [wCurrent, w13, w16, w11],
          workoutSummaries: const [],
          now: testNow,
        );

        expect(overview.loggedWeightWeeksCount, 4);
        // Total gain: 78.50 - 75.00 = +3.50 kg across all history
        expect(overview.totalGainKg, 3.50);

        // Slot 0 (2026-07-27) was preceded by 2026-07-13 (2 weeks gap):
        // (76.20 - 75.60) / 2 = 0.30 kg/week
        final slot0 = overview.calendarWeeks[0];
        expect(slot0.weekStartIso, '2026-07-27');
        expect(slot0.averageWeightKg, 76.20);
        expect(slot0.paceKgPerWeek, 0.30);
      },
    );

    test(
      'workout counts map onto matching calendar weeks and default to 0 on empty weeks',
      () {
        final workout1 = _createWorkoutSummary(
          weekStartIso: '2026-09-28',
          workoutCount: 4,
        );
        final workoutCurrent = _createWorkoutSummary(
          weekStartIso: currentWeekMondayIso,
          workoutCount: 3,
        );

        final overview = WeeklyProgressCalculator.calculate(
          allWeightSummaries: const [],
          workoutSummaries: [workout1, workoutCurrent],
          now: testNow,
        );

        expect(overview.currentWeekWorkoutCount, 3);
        expect(overview.calendarWeeks[11].workoutCount, 3);
        expect(overview.calendarWeeks[9].weekStartIso, '2026-09-28');
        expect(overview.calendarWeeks[9].workoutCount, 4);

        // Other slots default to 0
        expect(overview.calendarWeeks[10].workoutCount, 0);
        expect(overview.calendarWeeks[8].workoutCount, 0);
      },
    );

    test(
      'CalendarWeekProgressSlotEntity and WeeklyProgressOverviewEntity value equality',
      () {
        final slotA = CalendarWeekProgressSlotEntity(
          weekStartIso: '2026-10-12',
          weekStartMonday: DateTime.utc(2026, 10, 12),
          weekEndSunday: DateTime.utc(2026, 10, 18),
          averageWeightKg: 80.0,
          loggedWeightDaysCount: 5,
          paceKgPerWeek: 0.25,
          workoutCount: 4,
          isCurrentWeek: true,
        );
        final slotB = CalendarWeekProgressSlotEntity(
          weekStartIso: '2026-10-12',
          weekStartMonday: DateTime.utc(2026, 10, 12),
          weekEndSunday: DateTime.utc(2026, 10, 18),
          averageWeightKg: 80.0,
          loggedWeightDaysCount: 5,
          paceKgPerWeek: 0.25,
          workoutCount: 4,
          isCurrentWeek: true,
        );
        expect(slotA, equals(slotB));
        expect(slotA.hashCode, equals(slotB.hashCode));

        final updated = slotA.copyWith(workoutCount: 5);
        expect(updated.workoutCount, 5);
        expect(slotA == updated, isFalse);

        final overview1 = WeeklyProgressCalculator.calculate(
          allWeightSummaries: const [],
          workoutSummaries: const [],
          now: testNow,
        );
        final overview2 = WeeklyProgressCalculator.calculate(
          allWeightSummaries: const [],
          workoutSummaries: const [],
          now: testNow,
        );
        expect(overview1, equals(overview2));
        expect(overview1.hashCode, equals(overview2.hashCode));
      },
    );
  });
}
