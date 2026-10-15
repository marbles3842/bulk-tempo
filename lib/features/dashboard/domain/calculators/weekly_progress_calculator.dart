import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/weekly_progress_overview_entity.dart';
import 'package:bulk_tempo/features/weight/domain/models/weekly_weight_summary_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/weekly_workout_summary_entity.dart';

abstract final class WeeklyProgressCalculator {
  static const int windowWeeks = 12;

  static WeeklyProgressOverviewEntity calculate({
    required List<WeeklyWeightSummaryEntity> allWeightSummaries,
    required List<WeeklyWorkoutSummaryEntity> workoutSummaries,
    required DateTime now,
  }) {
    final currentMonday = WeekDateUtils.startOfIsoWeekUtc(now);
    final sortedWeights = _deduplicateAndSortWeights(allWeightSummaries);
    final paceByWeekIso = _computePaceByWeekIso(sortedWeights);
    final workoutByWeekIso = _indexWorkoutsByWeek(workoutSummaries);

    final calendarWeeks = _buildCalendarSlots(
      currentMonday: currentMonday,
      weightByIso: {for (final w in sortedWeights) w.weekStartIso: w},
      paceByIso: paceByWeekIso,
      workoutByIso: workoutByWeekIso,
    );

    return _buildOverview(
      calendarWeeks: calendarWeeks,
      sortedWeights: sortedWeights,
      paceByWeekIso: paceByWeekIso,
    );
  }

  static List<WeeklyWeightSummaryEntity> _deduplicateAndSortWeights(
    List<WeeklyWeightSummaryEntity> summaries,
  ) {
    final Map<String, WeeklyWeightSummaryEntity> deduped = {
      for (final s in summaries) s.weekStartIso: s,
    };
    return deduped.values.toList()
      ..sort((a, b) => a.weekStartIso.compareTo(b.weekStartIso));
  }

  static Map<String, double?> _computePaceByWeekIso(
    List<WeeklyWeightSummaryEntity> sortedWeights,
  ) {
    final Map<String, double?> paceMap = {};
    if (sortedWeights.isEmpty) {
      return paceMap;
    }

    paceMap[sortedWeights.first.weekStartIso] = null;
    for (int i = 1; i < sortedWeights.length; i++) {
      paceMap[sortedWeights[i].weekStartIso] = _calculateGapAdjustedPace(
        current: sortedWeights[i],
        previous: sortedWeights[i - 1],
      );
    }
    return paceMap;
  }

  static double? _calculateGapAdjustedPace({
    required WeeklyWeightSummaryEntity current,
    required WeeklyWeightSummaryEntity previous,
  }) {
    final weeksBetween =
        current.weekStartMonday.difference(previous.weekStartMonday).inDays ~/
        7;

    if (weeksBetween < 1) {
      return null;
    }

    final diff = current.averageWeightKg - previous.averageWeightKg;
    return WeekDateUtils.roundToTwoDecimals(diff / weeksBetween);
  }

  static Map<String, WeeklyWorkoutSummaryEntity> _indexWorkoutsByWeek(
    List<WeeklyWorkoutSummaryEntity> summaries,
  ) {
    return {for (final s in summaries) s.weekStartIso: s};
  }

  static List<CalendarWeekProgressSlotEntity> _buildCalendarSlots({
    required DateTime currentMonday,
    required Map<String, WeeklyWeightSummaryEntity> weightByIso,
    required Map<String, double?> paceByIso,
    required Map<String, WeeklyWorkoutSummaryEntity> workoutByIso,
  }) {
    return List.generate(windowWeeks, (index) {
      final weeksFromCurrent = windowWeeks - 1 - index;
      final weekStartMonday = DateTime.utc(
        currentMonday.year,
        currentMonday.month,
        currentMonday.day - (7 * weeksFromCurrent),
      );
      final weekStartIso = WeekDateUtils.toIsoDateString(weekStartMonday);
      final weight = weightByIso[weekStartIso];

      return CalendarWeekProgressSlotEntity(
        weekStartIso: weekStartIso,
        weekStartMonday: weekStartMonday,
        weekEndSunday: WeekDateUtils.endOfIsoWeekUtc(weekStartMonday),
        averageWeightKg: weight?.averageWeightKg,
        loggedWeightDaysCount: weight?.loggedDaysCount ?? 0,
        paceKgPerWeek: weight != null ? paceByIso[weekStartIso] : null,
        workoutCount: workoutByIso[weekStartIso]?.workoutCount ?? 0,
        isCurrentWeek: index == windowWeeks - 1,
      );
    });
  }

  static WeeklyProgressOverviewEntity _buildOverview({
    required List<CalendarWeekProgressSlotEntity> calendarWeeks,
    required List<WeeklyWeightSummaryEntity> sortedWeights,
    required Map<String, double?> paceByWeekIso,
  }) {
    final latestWeight = sortedWeights.isEmpty ? null : sortedWeights.last;
    final earliestWeight = sortedWeights.isEmpty ? null : sortedWeights.first;
    final currentWeekIso = calendarWeeks.last.weekStartIso;
    final latestWeekIso = latestWeight?.weekStartIso;
    final isCurrentWeek =
        latestWeight != null && latestWeekIso == currentWeekIso;
    final isLatestWeekRecent =
        isCurrentWeek ||
        latestWeekIso == calendarWeeks[calendarWeeks.length - 2].weekStartIso;

    final hasAtLeastTwoWeeks = sortedWeights.length >= 2;
    final currentPace = hasAtLeastTwoWeeks && isLatestWeekRecent
        ? paceByWeekIso[latestWeight!.weekStartIso]
        : null;
    final totalGain = hasAtLeastTwoWeeks
        ? WeekDateUtils.roundToTwoDecimals(
            latestWeight!.averageWeightKg - earliestWeight!.averageWeightKg,
          )
        : null;

    final loggedDays = latestWeight?.loggedDaysCount ?? 0;

    return WeeklyProgressOverviewEntity(
      calendarWeeks: calendarWeeks,
      currentPaceKgPerWeek: currentPace,
      latestAverageWeightKg: latestWeight?.averageWeightKg,
      latestWeekStartIso: latestWeekIso,
      latestWeekStartMonday: latestWeight?.weekStartMonday,
      latestWeekEndSunday: latestWeight?.weekEndSunday,
      latestWeekLoggedDays: loggedDays,
      isLatestWeekCurrentWeek: isCurrentWeek,
      isLatestWeekIncomplete: isCurrentWeek && loggedDays > 0 && loggedDays < 7,
      totalGainKg: totalGain,
      currentWeekWorkoutCount: calendarWeeks.last.workoutCount,
      loggedWeightWeeksCount: sortedWeights.length,
    );
  }
}
