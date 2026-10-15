import 'package:freezed_annotation/freezed_annotation.dart';

part 'weekly_progress_overview_entity.freezed.dart';

@freezed
abstract class CalendarWeekProgressSlotEntity
    with _$CalendarWeekProgressSlotEntity {
  const CalendarWeekProgressSlotEntity._();

  const factory CalendarWeekProgressSlotEntity({
    required String weekStartIso,
    required DateTime weekStartMonday,
    required DateTime weekEndSunday,
    double? averageWeightKg,
    required int loggedWeightDaysCount,
    double? paceKgPerWeek,
    required int workoutCount,
    required bool isCurrentWeek,
  }) = _CalendarWeekProgressSlotEntity;
}

@freezed
abstract class WeeklyProgressOverviewEntity
    with _$WeeklyProgressOverviewEntity {
  const WeeklyProgressOverviewEntity._();

  const factory WeeklyProgressOverviewEntity({
    required List<CalendarWeekProgressSlotEntity> calendarWeeks,
    double? currentPaceKgPerWeek,
    double? latestAverageWeightKg,
    String? latestWeekStartIso,
    DateTime? latestWeekStartMonday,
    DateTime? latestWeekEndSunday,
    required int latestWeekLoggedDays,
    required bool isLatestWeekCurrentWeek,
    required bool isLatestWeekIncomplete,
    double? totalGainKg,
    required int currentWeekWorkoutCount,
    required int loggedWeightWeeksCount,
  }) = _WeeklyProgressOverviewEntity;
}
