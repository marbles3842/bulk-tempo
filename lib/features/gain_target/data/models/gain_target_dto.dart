import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';
import 'package:bulk_tempo/features/gain_target/domain/validation/gain_target_validator.dart';

part 'gain_target_dto.freezed.dart';
part 'gain_target_dto.g.dart';

/// Data Transfer Object for serializing and deserializing weekly gain targets
/// between Firebase Realtime Database and [GainTargetEntity].
@Freezed(toJson: true)
abstract class GainTargetDto with _$GainTargetDto {
  const GainTargetDto._();

  const factory GainTargetDto({
    required double minWeeklyGainKg,
    required double maxWeeklyGainKg,
  }) = _GainTargetDto;

  /// Deserializes a Firebase Realtime Database JSON map.
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
}
