import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_exercise_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_set_entity.dart';

/// Data Transfer Object for a single set in a Hevy workout response.
class WorkoutSetDto {
  final int index;
  final String type;
  final double? weightKg;
  final int? reps;
  final double? distanceMeters;
  final int? durationSeconds;
  final double? rpe;

  const WorkoutSetDto({
    required this.index,
    required this.type,
    this.weightKg,
    this.reps,
    this.distanceMeters,
    this.durationSeconds,
    this.rpe,
  });

  factory WorkoutSetDto.fromJson(Map<String, dynamic> json) {
    final rawIndex = json['index'];
    final index = rawIndex is num ? rawIndex.toInt() : 0;
    final rawType = json['type'] ?? json['set_type'];
    final type = rawType is String && rawType.isNotEmpty ? rawType : 'normal';

    return WorkoutSetDto(
      index: index,
      type: type,
      weightKg: _toNullableDouble(json['weight_kg']),
      reps: _toNullableInt(json['reps']),
      distanceMeters: _toNullableDouble(json['distance_meters']),
      durationSeconds: _toNullableInt(json['duration_seconds']),
      rpe: _toNullableDouble(json['rpe']),
    );
  }

  WorkoutSetEntity toEntity() {
    return WorkoutSetEntity(
      index: index,
      type: type,
      weightKg: weightKg,
      reps: reps,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      rpe: rpe,
    );
  }

  static double? _toNullableDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static int? _toNullableInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSetDto &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          type == other.type &&
          weightKg == other.weightKg &&
          reps == other.reps &&
          distanceMeters == other.distanceMeters &&
          durationSeconds == other.durationSeconds &&
          rpe == other.rpe;

  @override
  int get hashCode => Object.hash(
    index,
    type,
    weightKg,
    reps,
    distanceMeters,
    durationSeconds,
    rpe,
  );

  @override
  String toString() =>
      'WorkoutSetDto(index: $index, type: $type, weightKg: $weightKg, reps: $reps, distanceMeters: $distanceMeters, durationSeconds: $durationSeconds, rpe: $rpe)';
}

/// Data Transfer Object for an exercise in a Hevy workout response.
class WorkoutExerciseDto {
  final int index;
  final String title;
  final String exerciseTemplateId;
  final String? notes;
  final int? supersetId;
  final List<WorkoutSetDto> sets;

  const WorkoutExerciseDto({
    required this.index,
    required this.title,
    required this.exerciseTemplateId,
    this.notes,
    this.supersetId,
    required this.sets,
  });

  factory WorkoutExerciseDto.fromJson(Map<String, dynamic> json) {
    final rawIndex = json['index'];
    final index = rawIndex is num ? rawIndex.toInt() : 0;
    final rawTitle = json['title'];
    final title = rawTitle is String ? rawTitle : '';
    final rawTemplateId = json['exercise_template_id'];
    final exerciseTemplateId = rawTemplateId is String ? rawTemplateId : '';
    final rawNotes = json['notes'];
    final notes = rawNotes is String ? rawNotes : null;
    final rawSupersetId = json['superset_id'];
    final supersetId = rawSupersetId is num ? rawSupersetId.toInt() : null;

    final rawSets = json['sets'];
    final List<WorkoutSetDto> parsedSets = [];
    if (rawSets is List<Object?>) {
      for (final item in rawSets) {
        if (item is Map<Object?, Object?>) {
          parsedSets.add(
            WorkoutSetDto.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return WorkoutExerciseDto(
      index: index,
      title: title,
      exerciseTemplateId: exerciseTemplateId,
      notes: notes,
      supersetId: supersetId,
      sets: List.unmodifiable(parsedSets),
    );
  }

  WorkoutExerciseEntity toEntity() {
    return WorkoutExerciseEntity(
      index: index,
      title: title,
      exerciseTemplateId: exerciseTemplateId,
      notes: notes,
      supersetId: supersetId,
      sets: List.unmodifiable(sets.map((s) => s.toEntity()).toList()),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WorkoutExerciseDto || runtimeType != other.runtimeType) {
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
      'WorkoutExerciseDto(index: $index, title: $title, exerciseTemplateId: $exerciseTemplateId, notes: $notes, supersetId: $supersetId, sets: $sets)';
}

/// Data Transfer Object for a single workout in a Hevy `/v1/workouts` response.
class WorkoutDto {
  final String id;
  final String title;
  final String? description;
  final String startTime;
  final String endTime;
  final List<WorkoutExerciseDto> exercises;

  const WorkoutDto({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.exercises,
  });

  factory WorkoutDto.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    if (rawId is! String || rawId.trim().isEmpty) {
      throw const FormatException('Workout id is required');
    }
    final rawStartTime = json['start_time'];
    if (rawStartTime is! String || rawStartTime.trim().isEmpty) {
      throw const FormatException('Workout start_time is required');
    }
    // Validate that start_time is a valid ISO-8601 timestamp
    DateTime.parse(rawStartTime);

    final rawEndTime = json['end_time'];
    final String endTime;
    if (rawEndTime is String && rawEndTime.trim().isNotEmpty) {
      endTime = rawEndTime;
    } else {
      endTime = rawStartTime;
    }
    DateTime.parse(endTime);

    final rawTitle = json['title'];
    final title = rawTitle is String ? rawTitle : '';
    final rawDescription = json['description'];
    final description = rawDescription is String ? rawDescription : null;

    final rawExercises = json['exercises'];
    final List<WorkoutExerciseDto> parsedExercises = [];
    if (rawExercises is List<Object?>) {
      for (final item in rawExercises) {
        if (item is Map<Object?, Object?>) {
          parsedExercises.add(
            WorkoutExerciseDto.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return WorkoutDto(
      id: rawId,
      title: title,
      description: description,
      startTime: rawStartTime,
      endTime: endTime,
      exercises: List.unmodifiable(parsedExercises),
    );
  }

  /// Maps this DTO to a [WorkoutEntity], deriving [WorkoutEntity.localDate]
  /// and [WorkoutEntity.localDateIso] from `DateTime.parse(startTime).toLocal()`.
  WorkoutEntity toEntity() {
    final parsedStartTime = DateTime.parse(startTime);
    final parsedEndTime = DateTime.parse(endTime);
    final localStart = parsedStartTime.toLocal();
    final localDate = DateTime.utc(
      localStart.year,
      localStart.month,
      localStart.day,
    );
    final localDateIso = WeekDateUtils.toIsoDateString(localDate);

    return WorkoutEntity(
      id: id,
      title: title,
      description: description,
      startTime: parsedStartTime,
      endTime: parsedEndTime,
      localDate: localDate,
      localDateIso: localDateIso,
      exercises: List.unmodifiable(exercises.map((e) => e.toEntity()).toList()),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WorkoutDto || runtimeType != other.runtimeType) {
      return false;
    }
    if (id != other.id ||
        title != other.title ||
        description != other.description ||
        startTime != other.startTime ||
        endTime != other.endTime ||
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
    Object.hashAll(exercises),
  );

  @override
  String toString() =>
      'WorkoutDto(id: $id, title: $title, description: $description, startTime: $startTime, endTime: $endTime, exercises: $exercises)';
}

/// Data Transfer Object for a paginated `/v1/workouts` response from Hevy.
class PaginatedWorkoutsResponseDto {
  final int page;
  final int pageCount;
  final List<WorkoutDto> workouts;

  const PaginatedWorkoutsResponseDto({
    required this.page,
    required this.pageCount,
    required this.workouts,
  });

  factory PaginatedWorkoutsResponseDto.fromJson(Map<String, dynamic> json) {
    final rawPage = json['page'];
    final page = rawPage is num ? rawPage.toInt() : 1;
    final rawPageCount = json['page_count'];
    final pageCount = rawPageCount is num ? rawPageCount.toInt() : 1;

    final rawWorkouts = json['workouts'];
    if (rawWorkouts != null && rawWorkouts is! List<Object?>) {
      throw const FormatException('workouts field must be a list');
    }

    final List<WorkoutDto> parsedWorkouts = [];
    if (rawWorkouts is List<Object?>) {
      for (final item in rawWorkouts) {
        if (item is Map<Object?, Object?>) {
          parsedWorkouts.add(
            WorkoutDto.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return PaginatedWorkoutsResponseDto(
      page: page,
      pageCount: pageCount,
      workouts: List.unmodifiable(parsedWorkouts),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PaginatedWorkoutsResponseDto ||
        runtimeType != other.runtimeType) {
      return false;
    }
    if (page != other.page ||
        pageCount != other.pageCount ||
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
  int get hashCode => Object.hash(page, pageCount, Object.hashAll(workouts));

  @override
  String toString() =>
      'PaginatedWorkoutsResponseDto(page: $page, pageCount: $pageCount, workouts: $workouts)';
}
