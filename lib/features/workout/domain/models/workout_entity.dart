import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_exercise_entity.dart';

part 'workout_entity.freezed.dart';

/// Domain entity representing a single logged Hevy workout.
@freezed
abstract class WorkoutEntity with _$WorkoutEntity {
  const WorkoutEntity._();

  const factory WorkoutEntity({
    required String id,
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    required DateTime localDate,
    required String localDateIso,
    required List<WorkoutExerciseEntity> exercises,
  }) = _WorkoutEntity;

  /// Total number of working sets across all exercises in this workout.
  int get workingSetsCount => exercises.fold<int>(
    0,
    (acc, exercise) => acc + exercise.workingSetsCount,
  );

  /// Total volume in kg across all working sets in this workout, rounded to
  /// two decimal places.
  double get totalVolumeKg {
    final sum = exercises.fold<double>(
      0.0,
      (acc, exercise) => acc + exercise.totalVolumeKg,
    );
    return WeekDateUtils.roundToTwoDecimals(sum);
  }
}
