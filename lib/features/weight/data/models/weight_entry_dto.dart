import 'package:bulk_tempo/core/utils/week_date_utils.dart';
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
  factory WeightEntryDto.fromJson(
    Map<Object?, Object?> json, {
    String? keyDate,
  }) {
    final dateVal = (json['date'] as String?) ?? keyDate ?? '';
    final rawWeight = json['weightKg'];
    final double weightKg;
    if (rawWeight is num) {
      weightKg = rawWeight.toDouble();
    } else if (rawWeight is String) {
      weightKg = double.tryParse(rawWeight) ?? 0.0;
    } else {
      weightKg = 0.0;
    }

    final updatedAtVal =
        (json['updatedAt'] as String?) ??
        DateTime.now().toUtc().toIso8601String();

    return WeightEntryDto(
      date: dateVal,
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
    final parsed =
        WeekDateUtils.tryParseIsoDate(date) ??
        DateTime.tryParse(date)?.toUtc() ??
        DateTime.now().toUtc();
    final normalized = WeekDateUtils.normalizeDateUtc(parsed);
    final parsedUpdatedAt =
        DateTime.tryParse(updatedAt)?.toUtc() ?? DateTime.now().toUtc();

    return WeightEntryEntity(
      dateIso: date.isNotEmpty
          ? date
          : WeekDateUtils.toIsoDateString(normalized),
      date: normalized,
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
