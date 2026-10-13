import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';

part 'workout_set_entity.freezed.dart';

/// Domain entity representing a single set within a workout exercise.
@freezed
abstract class WorkoutSetEntity with _$WorkoutSetEntity {
  const WorkoutSetEntity._();

  const factory WorkoutSetEntity({
    required int index,
    required String type,
    double? weightKg,
    int? reps,
    double? distanceMeters,
    int? durationSeconds,
    double? rpe,
  }) = _WorkoutSetEntity;

  /// Returns `true` if this set is a working set (`'normal'`, `'failure'`, or
  /// `'dropset'`), excluding `'warmup'` sets.
  bool get isWorkingSet => type != 'warmup';

  /// Returns the volume (`weightKg * reps`) rounded to two decimal places for
  /// working sets with positive weight and reps, or `0.0` otherwise.
  double get volumeKg {
    if (!isWorkingSet || weightKg == null || reps == null) {
      return 0.0;
    }
    if (weightKg! <= 0 || reps! <= 0) {
      return 0.0;
    }
    return WeekDateUtils.roundToTwoDecimals(weightKg! * reps!);
  }
}
