import 'package:bulk_tempo/core/utils/week_date_utils.dart';

/// Domain entity representing a single set within a workout exercise.
class WorkoutSetEntity {
  final int index;
  final String type;
  final double? weightKg;
  final int? reps;
  final double? distanceMeters;
  final int? durationSeconds;
  final double? rpe;

  const WorkoutSetEntity({
    required this.index,
    required this.type,
    this.weightKg,
    this.reps,
    this.distanceMeters,
    this.durationSeconds,
    this.rpe,
  });

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

  WorkoutSetEntity copyWith({
    int? index,
    String? type,
    double? weightKg,
    int? reps,
    double? distanceMeters,
    int? durationSeconds,
    double? rpe,
  }) {
    return WorkoutSetEntity(
      index: index ?? this.index,
      type: type ?? this.type,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      rpe: rpe ?? this.rpe,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSetEntity &&
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
      'WorkoutSetEntity(index: $index, type: $type, weightKg: $weightKg, reps: $reps, distanceMeters: $distanceMeters, durationSeconds: $durationSeconds, rpe: $rpe)';
}
