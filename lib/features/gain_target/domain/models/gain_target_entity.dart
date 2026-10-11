/// Domain entity representing a user's target weekly weight gain range in kg/week.
class GainTargetEntity {
  /// Minimum weekly gain rate in kilograms per week.
  final double minWeeklyGainKg;

  /// Maximum weekly gain rate in kilograms per week.
  final double maxWeeklyGainKg;

  const GainTargetEntity({
    required this.minWeeklyGainKg,
    required this.maxWeeklyGainKg,
  });

  /// Formatted display string representing the weekly gain range,
  /// e.g. '0.15–0.25 kg/week'.
  String get formattedTarget =>
      '${minWeeklyGainKg.toStringAsFixed(2)}–${maxWeeklyGainKg.toStringAsFixed(2)} kg/week';

  /// Alias for [formattedTarget].
  String get displayText => formattedTarget;

  /// Returns whether this entity satisfies valid bounds:
  /// finite, non-NaN, and `0 < minWeeklyGainKg < maxWeeklyGainKg`.
  bool get isValid =>
      minWeeklyGainKg.isFinite &&
      maxWeeklyGainKg.isFinite &&
      !minWeeklyGainKg.isNaN &&
      !maxWeeklyGainKg.isNaN &&
      minWeeklyGainKg > 0 &&
      maxWeeklyGainKg > minWeeklyGainKg;

  /// Difference between maximum and minimum weekly gain rates.
  double get spread => maxWeeklyGainKg - minWeeklyGainKg;

  GainTargetEntity copyWith({
    double? minWeeklyGainKg,
    double? maxWeeklyGainKg,
  }) {
    return GainTargetEntity(
      minWeeklyGainKg: minWeeklyGainKg ?? this.minWeeklyGainKg,
      maxWeeklyGainKg: maxWeeklyGainKg ?? this.maxWeeklyGainKg,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GainTargetEntity &&
          runtimeType == other.runtimeType &&
          minWeeklyGainKg == other.minWeeklyGainKg &&
          maxWeeklyGainKg == other.maxWeeklyGainKg;

  @override
  int get hashCode => minWeeklyGainKg.hashCode ^ maxWeeklyGainKg.hashCode;

  @override
  String toString() =>
      'GainTargetEntity(minWeeklyGainKg: $minWeeklyGainKg, maxWeeklyGainKg: $maxWeeklyGainKg)';
}
