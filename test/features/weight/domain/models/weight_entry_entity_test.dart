import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';

void main() {
  group('WeightEntryEntity', () {
    final now = DateTime.utc(2026, 10, 10, 12, 0);
    final date = DateTime.utc(2026, 10, 10);
    final entity = WeightEntryEntity(
      dateIso: '2026-10-10',
      date: date,
      weightKg: 82.45,
      updatedAt: now,
    );

    test('supports value equality', () {
      final sameEntity = WeightEntryEntity(
        dateIso: '2026-10-10',
        date: date,
        weightKg: 82.45,
        updatedAt: now,
      );

      final differentWeight = WeightEntryEntity(
        dateIso: '2026-10-10',
        date: date,
        weightKg: 83.0,
        updatedAt: now,
      );

      expect(entity, equals(sameEntity));
      expect(entity.hashCode, equals(sameEntity.hashCode));
      expect(entity, isNot(equals(differentWeight)));
    });

    test('copyWith creates new entity with updated fields', () {
      final updated = entity.copyWith(
        weightKg: 83.5,
        updatedAt: DateTime.utc(2026, 10, 10, 14, 0),
      );

      expect(updated.dateIso, '2026-10-10');
      expect(updated.date, date);
      expect(updated.weightKg, 83.5);
      expect(updated.updatedAt, DateTime.utc(2026, 10, 10, 14, 0));
    });

    test('toString formats correctly', () {
      expect(
        entity.toString(),
        'WeightEntryEntity(dateIso: 2026-10-10, date: 2026-10-10 00:00:00.000Z, weightKg: 82.45, updatedAt: 2026-10-10 12:00:00.000Z)',
      );
    });
  });
}
