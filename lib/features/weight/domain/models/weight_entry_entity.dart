import 'package:freezed_annotation/freezed_annotation.dart';

part 'weight_entry_entity.freezed.dart';

/// Domain entity representing a single daily weight measurement.
@freezed
abstract class WeightEntryEntity with _$WeightEntryEntity {
  const factory WeightEntryEntity({
    required String dateIso,
    required DateTime date,
    required double weightKg,
    required DateTime updatedAt,
  }) = _WeightEntryEntity;
}
