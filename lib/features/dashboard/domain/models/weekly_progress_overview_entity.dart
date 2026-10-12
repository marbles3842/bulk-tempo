/// Domain entity representing a single calendar week slot within the 12-week axis.
class CalendarWeekProgressSlotEntity {
  final String weekStartIso;
  final DateTime weekStartMonday;
  final DateTime weekEndSunday;
  final double? averageWeightKg;
  final int loggedWeightDaysCount;
  final double? paceKgPerWeek;
  final int workoutCount;
  final bool isCurrentWeek;

  const CalendarWeekProgressSlotEntity({
    required this.weekStartIso,
    required this.weekStartMonday,
    required this.weekEndSunday,
    this.averageWeightKg,
    required this.loggedWeightDaysCount,
    this.paceKgPerWeek,
    required this.workoutCount,
    required this.isCurrentWeek,
  });

  CalendarWeekProgressSlotEntity copyWith({
    String? weekStartIso,
    DateTime? weekStartMonday,
    DateTime? weekEndSunday,
    double? averageWeightKg,
    int? loggedWeightDaysCount,
    double? paceKgPerWeek,
    int? workoutCount,
    bool? isCurrentWeek,
  }) {
    return CalendarWeekProgressSlotEntity(
      weekStartIso: weekStartIso ?? this.weekStartIso,
      weekStartMonday: weekStartMonday ?? this.weekStartMonday,
      weekEndSunday: weekEndSunday ?? this.weekEndSunday,
      averageWeightKg: averageWeightKg ?? this.averageWeightKg,
      loggedWeightDaysCount:
          loggedWeightDaysCount ?? this.loggedWeightDaysCount,
      paceKgPerWeek: paceKgPerWeek ?? this.paceKgPerWeek,
      workoutCount: workoutCount ?? this.workoutCount,
      isCurrentWeek: isCurrentWeek ?? this.isCurrentWeek,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CalendarWeekProgressSlotEntity ||
        runtimeType != other.runtimeType) {
      return false;
    }
    return weekStartIso == other.weekStartIso &&
        weekStartMonday == other.weekStartMonday &&
        weekEndSunday == other.weekEndSunday &&
        averageWeightKg == other.averageWeightKg &&
        loggedWeightDaysCount == other.loggedWeightDaysCount &&
        paceKgPerWeek == other.paceKgPerWeek &&
        workoutCount == other.workoutCount &&
        isCurrentWeek == other.isCurrentWeek;
  }

  @override
  int get hashCode => Object.hash(
    weekStartIso,
    weekStartMonday,
    weekEndSunday,
    averageWeightKg,
    loggedWeightDaysCount,
    paceKgPerWeek,
    workoutCount,
    isCurrentWeek,
  );

  @override
  String toString() =>
      'CalendarWeekProgressSlotEntity(weekStartIso: $weekStartIso, weekStartMonday: $weekStartMonday, weekEndSunday: $weekEndSunday, averageWeightKg: $averageWeightKg, loggedWeightDaysCount: $loggedWeightDaysCount, paceKgPerWeek: $paceKgPerWeek, workoutCount: $workoutCount, isCurrentWeek: $isCurrentWeek)';
}

/// Domain entity aggregating 12 calendar-week progress slots and headline overview metrics.
class WeeklyProgressOverviewEntity {
  final List<CalendarWeekProgressSlotEntity> calendarWeeks;
  final double? currentPaceKgPerWeek;
  final double? latestAverageWeightKg;
  final String? latestWeekStartIso;
  final DateTime? latestWeekStartMonday;
  final DateTime? latestWeekEndSunday;
  final int latestWeekLoggedDays;
  final bool isLatestWeekCurrentWeek;
  final bool isLatestWeekIncomplete;
  final double? totalGainKg;
  final int currentWeekWorkoutCount;
  final int loggedWeightWeeksCount;

  const WeeklyProgressOverviewEntity({
    required this.calendarWeeks,
    this.currentPaceKgPerWeek,
    this.latestAverageWeightKg,
    this.latestWeekStartIso,
    this.latestWeekStartMonday,
    this.latestWeekEndSunday,
    required this.latestWeekLoggedDays,
    required this.isLatestWeekCurrentWeek,
    required this.isLatestWeekIncomplete,
    this.totalGainKg,
    required this.currentWeekWorkoutCount,
    required this.loggedWeightWeeksCount,
  });

  WeeklyProgressOverviewEntity copyWith({
    List<CalendarWeekProgressSlotEntity>? calendarWeeks,
    double? currentPaceKgPerWeek,
    double? latestAverageWeightKg,
    String? latestWeekStartIso,
    DateTime? latestWeekStartMonday,
    DateTime? latestWeekEndSunday,
    int? latestWeekLoggedDays,
    bool? isLatestWeekCurrentWeek,
    bool? isLatestWeekIncomplete,
    double? totalGainKg,
    int? currentWeekWorkoutCount,
    int? loggedWeightWeeksCount,
  }) {
    return WeeklyProgressOverviewEntity(
      calendarWeeks: calendarWeeks ?? this.calendarWeeks,
      currentPaceKgPerWeek: currentPaceKgPerWeek ?? this.currentPaceKgPerWeek,
      latestAverageWeightKg:
          latestAverageWeightKg ?? this.latestAverageWeightKg,
      latestWeekStartIso: latestWeekStartIso ?? this.latestWeekStartIso,
      latestWeekStartMonday:
          latestWeekStartMonday ?? this.latestWeekStartMonday,
      latestWeekEndSunday: latestWeekEndSunday ?? this.latestWeekEndSunday,
      latestWeekLoggedDays: latestWeekLoggedDays ?? this.latestWeekLoggedDays,
      isLatestWeekCurrentWeek:
          isLatestWeekCurrentWeek ?? this.isLatestWeekCurrentWeek,
      isLatestWeekIncomplete:
          isLatestWeekIncomplete ?? this.isLatestWeekIncomplete,
      totalGainKg: totalGainKg ?? this.totalGainKg,
      currentWeekWorkoutCount:
          currentWeekWorkoutCount ?? this.currentWeekWorkoutCount,
      loggedWeightWeeksCount:
          loggedWeightWeeksCount ?? this.loggedWeightWeeksCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WeeklyProgressOverviewEntity ||
        runtimeType != other.runtimeType) {
      return false;
    }
    if (currentPaceKgPerWeek != other.currentPaceKgPerWeek ||
        latestAverageWeightKg != other.latestAverageWeightKg ||
        latestWeekStartIso != other.latestWeekStartIso ||
        latestWeekStartMonday != other.latestWeekStartMonday ||
        latestWeekEndSunday != other.latestWeekEndSunday ||
        latestWeekLoggedDays != other.latestWeekLoggedDays ||
        isLatestWeekCurrentWeek != other.isLatestWeekCurrentWeek ||
        isLatestWeekIncomplete != other.isLatestWeekIncomplete ||
        totalGainKg != other.totalGainKg ||
        currentWeekWorkoutCount != other.currentWeekWorkoutCount ||
        loggedWeightWeeksCount != other.loggedWeightWeeksCount ||
        calendarWeeks.length != other.calendarWeeks.length) {
      return false;
    }
    for (int i = 0; i < calendarWeeks.length; i++) {
      if (calendarWeeks[i] != other.calendarWeeks[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(calendarWeeks),
    currentPaceKgPerWeek,
    latestAverageWeightKg,
    latestWeekStartIso,
    latestWeekStartMonday,
    latestWeekEndSunday,
    latestWeekLoggedDays,
    isLatestWeekCurrentWeek,
    isLatestWeekIncomplete,
    totalGainKg,
    currentWeekWorkoutCount,
    loggedWeightWeeksCount,
  );

  @override
  String toString() =>
      'WeeklyProgressOverviewEntity(calendarWeeks: $calendarWeeks, currentPaceKgPerWeek: $currentPaceKgPerWeek, latestAverageWeightKg: $latestAverageWeightKg, latestWeekStartIso: $latestWeekStartIso, latestWeekStartMonday: $latestWeekStartMonday, latestWeekEndSunday: $latestWeekEndSunday, latestWeekLoggedDays: $latestWeekLoggedDays, isLatestWeekCurrentWeek: $isLatestWeekCurrentWeek, isLatestWeekIncomplete: $isLatestWeekIncomplete, totalGainKg: $totalGainKg, currentWeekWorkoutCount: $currentWeekWorkoutCount, loggedWeightWeeksCount: $loggedWeightWeeksCount)';
}
