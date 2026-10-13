import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_exercise_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_set_entity.dart';

part 'workout_dto.freezed.dart';
part 'workout_dto.g.dart';

/// Data Transfer Object for a single set in a Hevy workout response.
@Freezed(toJson: true)
abstract class WorkoutSetDto with _$WorkoutSetDto {
  const WorkoutSetDto._();

  const factory WorkoutSetDto({
    required int index,
    required String type,
    double? weightKg,
    int? reps,
    double? distanceMeters,
    int? durationSeconds,
    double? rpe,
  }) = _WorkoutSetDto;

  factory WorkoutSetDto.fromJson(Map<String, dynamic> json) {
    final rawIndex = json['index'];
    final index = rawIndex is num ? rawIndex.toInt() : 0;
    final rawType = json['type'] ?? json['set_type'];
    final type = rawType is String && rawType.trim().isNotEmpty
        ? rawType.toLowerCase().trim()
        : 'normal';

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
}

/// Data Transfer Object for an exercise in a Hevy workout response.
@Freezed(toJson: true)
abstract class WorkoutExerciseDto with _$WorkoutExerciseDto {
  const WorkoutExerciseDto._();

  const factory WorkoutExerciseDto({
    required int index,
    required String title,
    required String exerciseTemplateId,
    String? notes,
    int? supersetId,
    required List<WorkoutSetDto> sets,
  }) = _WorkoutExerciseDto;

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
}

/// Data Transfer Object for a single workout in a Hevy `/v1/workouts` response.
@Freezed(toJson: true)
abstract class WorkoutDto with _$WorkoutDto {
  const WorkoutDto._();

  const factory WorkoutDto({
    required String id,
    required String title,
    String? description,
    required String startTime,
    required String endTime,
    required List<WorkoutExerciseDto> exercises,
  }) = _WorkoutDto;

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
}

/// Data Transfer Object for a paginated `/v1/workouts` response from Hevy.
@Freezed(toJson: true)
abstract class PaginatedWorkoutsResponseDto
    with _$PaginatedWorkoutsResponseDto {
  const PaginatedWorkoutsResponseDto._();

  const factory PaginatedWorkoutsResponseDto({
    required int page,
    required int pageCount,
    required List<WorkoutDto> workouts,
  }) = _PaginatedWorkoutsResponseDto;

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
}
