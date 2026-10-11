import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_entity.dart';

/// Domain entity representing an ISO Monday–Sunday weekly aggregate of workouts.
class WeeklyWorkoutSummaryEntity {
  final String weekStartIso;
  final DateTime weekStartMonday;
  final DateTime weekEndSunday;
  final List<WorkoutEntity> workouts;
  final int workoutCount;
  final int totalWorkingSets;
  final double totalVolumeKg;

  const WeeklyWorkoutSummaryEntity({
    required this.weekStartIso,
    required this.weekStartMonday,
    required this.weekEndSunday,
    required this.workouts,
    required this.workoutCount,
    required this.totalWorkingSets,
    required this.totalVolumeKg,
  });

  WeeklyWorkoutSummaryEntity copyWith({
    String? weekStartIso,
    DateTime? weekStartMonday,
    DateTime? weekEndSunday,
    List<WorkoutEntity>? workouts,
    int? workoutCount,
    int? totalWorkingSets,
    double? totalVolumeKg,
  }) {
    return WeeklyWorkoutSummaryEntity(
      weekStartIso: weekStartIso ?? this.weekStartIso,
      weekStartMonday: weekStartMonday ?? this.weekStartMonday,
      weekEndSunday: weekEndSunday ?? this.weekEndSunday,
      workouts: workouts ?? this.workouts,
      workoutCount: workoutCount ?? this.workoutCount,
      totalWorkingSets: totalWorkingSets ?? this.totalWorkingSets,
      totalVolumeKg: totalVolumeKg ?? this.totalVolumeKg,
    );
  }

  /// Groups individual workouts into ISO Monday–Sunday weeks using each
  /// workout's local calendar date ([WorkoutEntity.localDate]).
  ///
  /// - Deduplicates workouts by [WorkoutEntity.id], keeping the latest
  ///   [WorkoutEntity.startTime] if duplicates exist.
  /// - Groups workouts by ISO Monday (`WeekDateUtils.startOfIsoWeekUtc`).
  /// - Excludes weeks with 0 workouts.
  /// - Sorts workouts within each week descending by [WorkoutEntity.startTime]
  ///   (newest workout first).
  /// - Computes [workoutCount], [totalWorkingSets], and [totalVolumeKg]
  ///   (rounded to 2 decimal places).
  /// - Returns summaries sorted descending by [weekStartIso] (newest week first).
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WeeklyWorkoutSummaryEntity ||
        runtimeType != other.runtimeType) {
      return false;
    }
    if (weekStartIso != other.weekStartIso ||
        weekStartMonday != other.weekStartMonday ||
        weekEndSunday != other.weekEndSunday ||
        workoutCount != other.workoutCount ||
        totalWorkingSets != other.totalWorkingSets ||
        totalVolumeKg != other.totalVolumeKg ||
        workouts.length != other.workouts.length) {
      return false;
    }
    for (int i = 0; i < workouts.length; i++) {
      if (workouts[i] != other.workouts[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    weekStartIso,
    weekStartMonday,
    weekEndSunday,
    Object.hashAll(workouts),
    workoutCount,
    totalWorkingSets,
    totalVolumeKg,
  );

  @override
  String toString() =>
      'WeeklyWorkoutSummaryEntity(weekStartIso: $weekStartIso, weekStartMonday: $weekStartMonday, weekEndSunday: $weekEndSunday, workoutCount: $workoutCount, totalWorkingSets: $totalWorkingSets, totalVolumeKg: $totalVolumeKg, workouts: $workouts)';
}
