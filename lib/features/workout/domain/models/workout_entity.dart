import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_exercise_entity.dart';

/// Domain entity representing a single logged Hevy workout.
class WorkoutEntity {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime localDate;
  final String localDateIso;
  final List<WorkoutExerciseEntity> exercises;

  const WorkoutEntity({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.localDate,
    required this.localDateIso,
    required this.exercises,
  });

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

  WorkoutEntity copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? localDate,
    String? localDateIso,
    List<WorkoutExerciseEntity>? exercises,
  }) {
    return WorkoutEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      localDate: localDate ?? this.localDate,
      localDateIso: localDateIso ?? this.localDateIso,
      exercises: exercises ?? this.exercises,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WorkoutEntity || runtimeType != other.runtimeType) {
      return false;
    }
    if (id != other.id ||
        title != other.title ||
        description != other.description ||
        startTime != other.startTime ||
        endTime != other.endTime ||
        localDate != other.localDate ||
        localDateIso != other.localDateIso ||
        exercises.length != other.exercises.length) {
      return false;
    }
    for (int i = 0; i < exercises.length; i++) {
      if (exercises[i] != other.exercises[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    startTime,
    endTime,
    localDate,
    localDateIso,
    Object.hashAll(exercises),
  );

  @override
  String toString() =>
      'WorkoutEntity(id: $id, title: $title, description: $description, startTime: $startTime, endTime: $endTime, localDate: $localDate, localDateIso: $localDateIso, exercises: $exercises)';
}
