import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_set_entity.dart';

/// Domain entity representing an exercise performed within a workout.
class WorkoutExerciseEntity {
  final int index;
  final String title;
  final String exerciseTemplateId;
  final String? notes;
  final int? supersetId;
  final List<WorkoutSetEntity> sets;

  const WorkoutExerciseEntity({
    required this.index,
    required this.title,
    required this.exerciseTemplateId,
    this.notes,
    this.supersetId,
    required this.sets,
  });

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

  WorkoutExerciseEntity copyWith({
    int? index,
    String? title,
    String? exerciseTemplateId,
    String? notes,
    int? supersetId,
    List<WorkoutSetEntity>? sets,
  }) {
    return WorkoutExerciseEntity(
      index: index ?? this.index,
      title: title ?? this.title,
      exerciseTemplateId: exerciseTemplateId ?? this.exerciseTemplateId,
      notes: notes ?? this.notes,
      supersetId: supersetId ?? this.supersetId,
      sets: sets ?? this.sets,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WorkoutExerciseEntity || runtimeType != other.runtimeType) {
      return false;
    }
    if (index != other.index ||
        title != other.title ||
        exerciseTemplateId != other.exerciseTemplateId ||
        notes != other.notes ||
        supersetId != other.supersetId ||
        sets.length != other.sets.length) {
      return false;
    }
    for (int i = 0; i < sets.length; i++) {
      if (sets[i] != other.sets[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    index,
    title,
    exerciseTemplateId,
    notes,
    supersetId,
    Object.hashAll(sets),
  );

  @override
  String toString() =>
      'WorkoutExerciseEntity(index: $index, title: $title, exerciseTemplateId: $exerciseTemplateId, notes: $notes, supersetId: $supersetId, sets: $sets)';
}
