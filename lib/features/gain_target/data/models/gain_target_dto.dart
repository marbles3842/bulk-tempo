import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';
import 'package:bulk_tempo/features/gain_target/domain/validation/gain_target_validator.dart';

/// Data Transfer Object for serializing and deserializing weekly gain targets
/// between Firebase Realtime Database and [GainTargetEntity].
class GainTargetDto {
  /// Minimum weekly gain rate in kilograms per week.
  final double minWeeklyGainKg;

  /// Maximum weekly gain rate in kilograms per week.
  final double maxWeeklyGainKg;

  const GainTargetDto({
    required this.minWeeklyGainKg,
    required this.maxWeeklyGainKg,
  });

  /// Deserializes a Firebase Realtime Database JSON map.
  ///
  /// Accepts numeric int and double values (converts via `num.toDouble()`).
  /// Rejects missing fields, non-numeric types (e.g. strings, nulls, booleans),
  /// nonfinite values (NaN, infinity), and invalid ordering
  /// (`minWeeklyGainKg >= maxWeeklyGainKg` or `minWeeklyGainKg <= 0`).
  /// Throws [FormatException] with a descriptive message on invalid payload.
  factory GainTargetDto.fromJson(Map<Object?, Object?> json) {
    final rawMin = json['minWeeklyGainKg'];
    final rawMax = json['maxWeeklyGainKg'];

    if (rawMin == null || rawMax == null) {
      throw const FormatException(
        'Missing required gain target fields in JSON payload',
      );
    }

    if (rawMin is! num || rawMax is! num) {
      throw const FormatException('Gain target fields must be numeric numbers');
    }

    final min = rawMin.toDouble();
    final max = rawMax.toDouble();

    final validationError = GainTargetValidator.validateRange(min, max);
    if (validationError != null) {
      throw FormatException('Invalid gain target values: $validationError');
    }

    return GainTargetDto(minWeeklyGainKg: min, maxWeeklyGainKg: max);
  }

  /// Creates a DTO from a domain entity.
  factory GainTargetDto.fromEntity(GainTargetEntity entity) {
    return GainTargetDto(
      minWeeklyGainKg: entity.minWeeklyGainKg,
      maxWeeklyGainKg: entity.maxWeeklyGainKg,
    );
  }

  /// Converts this DTO to a domain entity.
  GainTargetEntity toEntity() {
    return GainTargetEntity(
      minWeeklyGainKg: minWeeklyGainKg,
      maxWeeklyGainKg: maxWeeklyGainKg,
    );
  }

  /// Serializes to a JSON map for Firebase Realtime Database.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'minWeeklyGainKg': minWeeklyGainKg,
      'maxWeeklyGainKg': maxWeeklyGainKg,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GainTargetDto &&
          runtimeType == other.runtimeType &&
          minWeeklyGainKg == other.minWeeklyGainKg &&
          maxWeeklyGainKg == other.maxWeeklyGainKg;

  @override
  int get hashCode => minWeeklyGainKg.hashCode ^ maxWeeklyGainKg.hashCode;

  @override
  String toString() =>
      'GainTargetDto(minWeeklyGainKg: $minWeeklyGainKg, maxWeeklyGainKg: $maxWeeklyGainKg)';
}
