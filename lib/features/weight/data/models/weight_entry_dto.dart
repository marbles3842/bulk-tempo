import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/core/utils/weight_validators.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';

/// Data Transfer Object for serializing and deserializing weight measurements
/// between Firebase Realtime Database and [WeightEntryEntity].
class WeightEntryDto {
  final String date;
  final double weightKg;
  final String updatedAt;

  const WeightEntryDto({
    required this.date,
    required this.weightKg,
    required this.updatedAt,
  });

  /// Deserializes a Firebase Realtime Database JSON map.
  ///
  /// Handles `int`, `double`, or numeric strings for [weightKg].
  /// Uses [keyDate] if the `'date'` field is absent in the map.
  /// Throws [FormatException] for invalid dates or weights.
  factory WeightEntryDto.fromJson(
    Map<Object?, Object?> json, {
    String? keyDate,
  }) {
    final dateVal = json['date'] ?? keyDate;
    final parsedDate = dateVal is String
        ? WeekDateUtils.tryParseIsoDate(dateVal)
        : null;
    if (parsedDate == null) {
      throw const FormatException('Invalid weight entry date');
    }
    final rawWeight = json['weightKg'];
    final double? weightKg;
    if (rawWeight is num) {
      weightKg = rawWeight.toDouble();
    } else if (rawWeight is String) {
      weightKg = double.tryParse(rawWeight);
    } else {
      weightKg = null;
    }
    if (weightKg == null ||
        !weightKg.isFinite ||
        weightKg < WeightValidators.minWeightKg ||
        weightKg > WeightValidators.maxWeightKg) {
      throw const FormatException('Invalid weight entry weight');
    }

    final updatedAtVal =
        (json['updatedAt'] as String?) ??
        DateTime.now().toUtc().toIso8601String();

    return WeightEntryDto(
      date: WeekDateUtils.toIsoDateString(parsedDate),
      weightKg: weightKg,
      updatedAt: updatedAtVal,
    );
  }

  /// Creates a DTO from a domain entity.
  factory WeightEntryDto.fromEntity(WeightEntryEntity entity) {
    return WeightEntryDto(
      date: entity.dateIso,
      weightKg: entity.weightKg,
      updatedAt: entity.updatedAt.toUtc().toIso8601String(),
    );
  }

  /// Converts this DTO to a domain entity with normalized UTC date.
  WeightEntryEntity toEntity() {
    final parsed = WeekDateUtils.tryParseIsoDate(date);
    if (parsed == null) {
      throw const FormatException('Invalid weight entry date');
    }
    final parsedUpdatedAt =
        DateTime.tryParse(updatedAt)?.toUtc() ?? DateTime.now().toUtc();

    return WeightEntryEntity(
      dateIso: WeekDateUtils.toIsoDateString(parsed),
      date: parsed,
      weightKg: weightKg,
      updatedAt: parsedUpdatedAt,
    );
  }

  /// Serializes to a JSON map for Firebase Realtime Database.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'date': date,
      'weightKg': weightKg,
      'updatedAt': updatedAt,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeightEntryDto &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          weightKg == other.weightKg &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => date.hashCode ^ weightKg.hashCode ^ updatedAt.hashCode;

  @override
  String toString() =>
      'WeightEntryDto(date: $date, weightKg: $weightKg, updatedAt: $updatedAt)';
}
