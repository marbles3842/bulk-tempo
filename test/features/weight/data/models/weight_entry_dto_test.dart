import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/features/weight/data/models/weight_entry_dto.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';

void main() {
  group('WeightEntryDto', () {
    const dto = WeightEntryDto(
      date: '2026-10-10',
      weightKg: 82.5,
      updatedAt: '2026-10-10T12:00:00.000Z',
    );

    test('fromJson deserializes map with double weightKg', () {
      final json = <Object?, Object?>{
        'date': '2026-10-10',
        'weightKg': 82.5,
        'updatedAt': '2026-10-10T12:00:00.000Z',
      };

      final result = WeightEntryDto.fromJson(json);

      expect(result.date, '2026-10-10');
      expect(result.weightKg, 82.5);
      expect(result.updatedAt, '2026-10-10T12:00:00.000Z');
    });

    test('fromJson handles int weightKg from RTDB', () {
      final json = <Object?, Object?>{
        'date': '2026-10-10',
        'weightKg': 82,
        'updatedAt': '2026-10-10T12:00:00.000Z',
      };

      final result = WeightEntryDto.fromJson(json);

      expect(result.weightKg, 82.0);
    });

    test('fromJson falls back to keyDate when date field is missing', () {
      final json = <Object?, Object?>{
        'weightKg': 80.0,
        'updatedAt': '2026-10-10T12:00:00.000Z',
      };

      final result = WeightEntryDto.fromJson(json, keyDate: '2026-10-10');

      expect(result.date, '2026-10-10');
      expect(result.weightKg, 80.0);
    });

    test('toJson serializes correctly', () {
      final json = dto.toJson();

      expect(json, {
        'date': '2026-10-10',
        'weightKg': 82.5,
        'updatedAt': '2026-10-10T12:00:00.000Z',
      });
    });

    test('fromEntity converts domain entity to DTO', () {
      final entity = WeightEntryEntity(
        dateIso: '2026-10-10',
        date: DateTime.utc(2026, 10, 10),
        weightKg: 82.5,
        updatedAt: DateTime.utc(2026, 10, 10, 12, 0),
      );

      final result = WeightEntryDto.fromEntity(entity);

      expect(result.date, '2026-10-10');
      expect(result.weightKg, 82.5);
      expect(result.updatedAt, '2026-10-10T12:00:00.000Z');
    });

    test('toEntity converts DTO to domain entity with normalized UTC date', () {
      final entity = dto.toEntity();

      expect(entity.dateIso, '2026-10-10');
      expect(entity.date, DateTime.utc(2026, 10, 10));
      expect(entity.weightKg, 82.5);
      expect(entity.updatedAt, DateTime.utc(2026, 10, 10, 12));
    });

    test('supports value equality', () {
      const same = WeightEntryDto(
        date: '2026-10-10',
        weightKg: 82.5,
        updatedAt: '2026-10-10T12:00:00.000Z',
      );
      const different = WeightEntryDto(
        date: '2026-10-11',
        weightKg: 82.5,
        updatedAt: '2026-10-10T12:00:00.000Z',
      );

      expect(dto, equals(same));
      expect(dto.hashCode, equals(same.hashCode));
      expect(dto, isNot(equals(different)));
    });
  });
}
