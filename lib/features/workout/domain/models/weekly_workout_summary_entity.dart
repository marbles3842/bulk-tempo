import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_entity.dart';

part 'weekly_workout_summary_entity.freezed.dart';

/// Domain entity representing an ISO Monday–Sunday weekly aggregate of workouts.
@freezed
abstract class WeeklyWorkoutSummaryEntity with _$WeeklyWorkoutSummaryEntity {
  const WeeklyWorkoutSummaryEntity._();

  const factory WeeklyWorkoutSummaryEntity({
    required String weekStartIso,
    required DateTime weekStartMonday,
    required DateTime weekEndSunday,
    required List<WorkoutEntity> workouts,
    required int workoutCount,
    required int totalWorkingSets,
    required double totalVolumeKg,
  }) = _WeeklyWorkoutSummaryEntity;

  /// Groups individual workouts into ISO Monday–Sunday weeks using each
  /// workout's local calendar date ([WorkoutEntity.localDate]).
  static List<WeeklyWorkoutSummaryEntity> groupWorkoutsByIsoWeek(
    List<WorkoutEntity> workouts,
  ) {
    if (workouts.isEmpty) {
      return const <WeeklyWorkoutSummaryEntity>[];
    }

    // 1. Deduplicate by id, keeping latest startTime if duplicates exist
    final Map<String, WorkoutEntity> deduped = {};
    for (final workout in workouts) {
      final existing = deduped[workout.id];
      if (existing == null || !workout.startTime.isBefore(existing.startTime)) {
        deduped[workout.id] = workout;
      }
    }

    // 2. Group by ISO Monday of workout.localDate
    final Map<String, List<WorkoutEntity>> weekGroups = {};
    final Map<String, DateTime> weekMondays = {};
    final Map<String, DateTime> weekSundays = {};

    for (final workout in deduped.values) {
      final monday = WeekDateUtils.startOfIsoWeekUtc(workout.localDate);
      final weekStartIso = WeekDateUtils.toIsoDateString(monday);
      final sunday = WeekDateUtils.endOfIsoWeekUtc(workout.localDate);

      weekMondays[weekStartIso] = monday;
      weekSundays[weekStartIso] = sunday;
      weekGroups
          .putIfAbsent(weekStartIso, () => <WorkoutEntity>[])
          .add(workout);
    }

    // 3. Build WeeklyWorkoutSummaryEntity for each non-empty week
    final List<WeeklyWorkoutSummaryEntity> summaries = [];
    for (final groupEntry in weekGroups.entries) {
      final weekStartIso = groupEntry.key;
      final weekWorkouts = groupEntry.value;
      if (weekWorkouts.isEmpty) {
        continue;
      }

      // Sort workouts descending by startTime (newest first)
      weekWorkouts.sort((a, b) => b.startTime.compareTo(a.startTime));

      final totalWorkingSets = weekWorkouts.fold<int>(
        0,
        (acc, workout) => acc + workout.workingSetsCount,
      );
      final rawVolumeKg = weekWorkouts.fold<double>(
        0.0,
        (acc, workout) => acc + workout.totalVolumeKg,
      );
      final totalVolumeKg = WeekDateUtils.roundToTwoDecimals(rawVolumeKg);

      summaries.add(
        WeeklyWorkoutSummaryEntity(
          weekStartIso: weekStartIso,
          weekStartMonday: weekMondays[weekStartIso]!,
          weekEndSunday: weekSundays[weekStartIso]!,
          workouts: List.unmodifiable(weekWorkouts),
          workoutCount: weekWorkouts.length,
          totalWorkingSets: totalWorkingSets,
          totalVolumeKg: totalVolumeKg,
        ),
      );
    }

    // 4. Sort summaries descending by weekStartIso (newest week first)
    summaries.sort((a, b) => b.weekStartIso.compareTo(a.weekStartIso));
    return summaries;
  }
}
