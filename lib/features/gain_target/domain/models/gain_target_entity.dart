import 'package:freezed_annotation/freezed_annotation.dart';

part 'gain_target_entity.freezed.dart';

/// Domain entity representing a user's target weekly weight gain range in kg/week.
@freezed
abstract class GainTargetEntity with _$GainTargetEntity {
  const GainTargetEntity._();

  const factory GainTargetEntity({
    required double minWeeklyGainKg,
    required double maxWeeklyGainKg,
  }) = _GainTargetEntity;

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
}
