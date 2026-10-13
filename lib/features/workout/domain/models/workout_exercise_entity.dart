import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_set_entity.dart';

part 'workout_exercise_entity.freezed.dart';

/// Domain entity representing an exercise performed within a workout.
@freezed
abstract class WorkoutExerciseEntity with _$WorkoutExerciseEntity {
  const WorkoutExerciseEntity._();

  const factory WorkoutExerciseEntity({
    required int index,
    required String title,
    required String exerciseTemplateId,
    String? notes,
    int? supersetId,
    required List<WorkoutSetEntity> sets,
  }) = _WorkoutExerciseEntity;

  /// Returns all sets excluding warmup sets.
  List<WorkoutSetEntity> get workingSets =>
      sets.where((set) => set.isWorkingSet).toList();

  /// Total number of working sets performed for this exercise.
  int get workingSetsCount => workingSets.length;

  /// Total volume in kg across all working sets, rounded to two decimals.
  double get totalVolumeKg {
    final sum = workingSets.fold<double>(0.0, (acc, set) => acc + set.volumeKg);
    return WeekDateUtils.roundToTwoDecimals(sum);
  }

  /// Selects the working set with the highest [WorkoutSetEntity.weightKg]
  /// (treating `null` as `-1.0`), tie-broken by highest [WorkoutSetEntity.reps]
  /// (treating `null` as `0`).
  ///
  /// Returns `null` if [workingSets] is empty or no working set has a non-null
  /// `weightKg` or `reps`.
  WorkoutSetEntity? get bestWorkingSet {
    WorkoutSetEntity? best;
    for (final set in workingSets) {
      if (set.weightKg == null && set.reps == null) {
        continue;
      }
      if (best == null) {
        best = set;
        continue;
      }
      final setWeight = set.weightKg ?? -1.0;
      final bestWeight = best.weightKg ?? -1.0;
      if (setWeight > bestWeight) {
        best = set;
      } else if (setWeight == bestWeight) {
        final setReps = set.reps ?? 0;
        final bestReps = best.reps ?? 0;
        if (setReps > bestReps) {
          best = set;
        }
      }
    }
    return best;
  }
}
