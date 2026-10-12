import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/weekly_progress_overview_entity.dart';
import 'package:bulk_tempo/features/weight/domain/models/weekly_weight_summary_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/weekly_workout_summary_entity.dart';

/// Pure calculator that computes 12-calendar-week slots and headline metrics.
class WeeklyProgressCalculator {
  static const int windowWeeks = 12;

  static WeeklyProgressOverviewEntity calculate({
    required List<WeeklyWeightSummaryEntity> allWeightSummaries,
    required List<WeeklyWorkoutSummaryEntity> workoutSummaries,
    required DateTime now,
  }) {
    // 1. Normalize reference date to current week Monday UTC.
    final currentMonday = WeekDateUtils.startOfIsoWeekUtc(now);

    // 2. Sort all historical weight summaries ascending by weekStartIso (oldest first).
    final sortedWeights = List<WeeklyWeightSummaryEntity>.from(
      allWeightSummaries,
    )..sort((a, b) => a.weekStartIso.compareTo(b.weekStartIso));

    // 3. Precompute gap-adjusted pace for each logged weight week against its
    // immediately preceding logged week across all history.
    final Map<String, double?> paceByWeekIso = {};
    if (sortedWeights.isNotEmpty) {
      paceByWeekIso[sortedWeights[0].weekStartIso] = null;
      for (int k = 1; k < sortedWeights.length; k++) {
        final currentWeek = sortedWeights[k];
        final previousWeek = sortedWeights[k - 1];
        final weeksBetween =
            currentWeek.weekStartMonday
                .difference(previousWeek.weekStartMonday)
                .inDays ~/
            7;

        if (weeksBetween >= 1) {
          final pace =
              (currentWeek.averageWeightKg - previousWeek.averageWeightKg) /
              weeksBetween;
          paceByWeekIso[currentWeek.weekStartIso] =
              WeekDateUtils.roundToTwoDecimals(pace);
        } else {
          paceByWeekIso[currentWeek.weekStartIso] = null;
        }
      }
    }

    // 4. Index weights and workouts by weekStartIso for lookup.
    final Map<String, WeeklyWeightSummaryEntity> weightByIso = {
      for (final summary in sortedWeights) summary.weekStartIso: summary,
    };
    final Map<String, WeeklyWorkoutSummaryEntity> workoutByIso = {
      for (final summary in workoutSummaries) summary.weekStartIso: summary,
    };

    // 5. Build the 12 consecutive ISO calendar weeks (slot 0 = 11 weeks ago, slot 11 = current week).
    final List<CalendarWeekProgressSlotEntity> calendarWeeks = [];
    for (int i = 0; i < windowWeeks; i++) {
      final weekStartMonday = DateTime.utc(
        currentMonday.year,
        currentMonday.month,
        currentMonday.day - (7 * (windowWeeks - 1 - i)),
      );
      final weekEndSunday = WeekDateUtils.endOfIsoWeekUtc(weekStartMonday);
      final weekStartIso = WeekDateUtils.toIsoDateString(weekStartMonday);
      final isCurrentWeek = i == windowWeeks - 1;

      final weightSummary = weightByIso[weekStartIso];
      final averageWeightKg = weightSummary?.averageWeightKg;
      final loggedWeightDaysCount = weightSummary?.loggedDaysCount ?? 0;
      final paceKgPerWeek = weightSummary != null
          ? paceByWeekIso[weekStartIso]
          : null;

      final workoutSummary = workoutByIso[weekStartIso];
      final workoutCount = workoutSummary?.workoutCount ?? 0;

      calendarWeeks.add(
        CalendarWeekProgressSlotEntity(
          weekStartIso: weekStartIso,
          weekStartMonday: weekStartMonday,
          weekEndSunday: weekEndSunday,
          averageWeightKg: averageWeightKg,
          loggedWeightDaysCount: loggedWeightDaysCount,
          paceKgPerWeek: paceKgPerWeek,
          workoutCount: workoutCount,
          isCurrentWeek: isCurrentWeek,
        ),
      );
    }

    // 6. Compute headline overview metrics.
    final currentWeekSlot = calendarWeeks[windowWeeks - 1];
    final currentWeekWorkoutCount = currentWeekSlot.workoutCount;
    final loggedWeightWeeksCount = sortedWeights.length;

    double? currentPaceKgPerWeek;
    double? latestAverageWeightKg;
    String? latestWeekStartIso;
    DateTime? latestWeekStartMonday;
    DateTime? latestWeekEndSunday;
    int latestWeekLoggedDays = 0;
    bool isLatestWeekCurrentWeek = false;
    bool isLatestWeekIncomplete = false;
    double? totalGainKg;

    if (sortedWeights.isNotEmpty) {
      final latestLoggedWeek = sortedWeights.last;
      final earliestLoggedWeek = sortedWeights.first;

      latestAverageWeightKg = latestLoggedWeek.averageWeightKg;
      latestWeekStartIso = latestLoggedWeek.weekStartIso;
      latestWeekStartMonday = latestLoggedWeek.weekStartMonday;
      latestWeekEndSunday = latestLoggedWeek.weekEndSunday;
      latestWeekLoggedDays = latestLoggedWeek.loggedDaysCount;

      isLatestWeekCurrentWeek =
          latestWeekStartIso == currentWeekSlot.weekStartIso;
      isLatestWeekIncomplete =
          isLatestWeekCurrentWeek &&
          latestWeekLoggedDays > 0 &&
          latestWeekLoggedDays < 7;

      if (sortedWeights.length >= 2) {
        currentPaceKgPerWeek = paceByWeekIso[latestLoggedWeek.weekStartIso];
        totalGainKg = WeekDateUtils.roundToTwoDecimals(
          latestLoggedWeek.averageWeightKg - earliestLoggedWeek.averageWeightKg,
        );
      }
    }

    return WeeklyProgressOverviewEntity(
      calendarWeeks: List.unmodifiable(calendarWeeks),
      currentPaceKgPerWeek: currentPaceKgPerWeek,
      latestAverageWeightKg: latestAverageWeightKg,
      latestWeekStartIso: latestWeekStartIso,
      latestWeekStartMonday: latestWeekStartMonday,
      latestWeekEndSunday: latestWeekEndSunday,
      latestWeekLoggedDays: latestWeekLoggedDays,
      isLatestWeekCurrentWeek: isLatestWeekCurrentWeek,
      isLatestWeekIncomplete: isLatestWeekIncomplete,
      totalGainKg: totalGainKg,
      currentWeekWorkoutCount: currentWeekWorkoutCount,
      loggedWeightWeeksCount: loggedWeightWeeksCount,
    );
  }
}
