import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GainTargetEntity', () {
    const entity = GainTargetEntity(
      minWeeklyGainKg: 0.15,
      maxWeeklyGainKg: 0.25,
    );

    test('supports value equality', () {
      const sameEntity = GainTargetEntity(
        minWeeklyGainKg: 0.15,
        maxWeeklyGainKg: 0.25,
      );

      const differentMin = GainTargetEntity(
        minWeeklyGainKg: 0.10,
        maxWeeklyGainKg: 0.25,
      );

      const differentMax = GainTargetEntity(
        minWeeklyGainKg: 0.15,
        maxWeeklyGainKg: 0.30,
      );

      expect(entity, equals(sameEntity));
      expect(entity.hashCode, equals(sameEntity.hashCode));
      expect(entity, isNot(equals(differentMin)));
      expect(entity, isNot(equals(differentMax)));
    });

    test('copyWith creates new entity with updated fields', () {
      final updatedMin = entity.copyWith(minWeeklyGainKg: 0.20);
      expect(updatedMin.minWeeklyGainKg, 0.20);
      expect(updatedMin.maxWeeklyGainKg, 0.25);

      final updatedMax = entity.copyWith(maxWeeklyGainKg: 0.35);
      expect(updatedMax.minWeeklyGainKg, 0.15);
      expect(updatedMax.maxWeeklyGainKg, 0.35);

      final unmodified = entity.copyWith();
      expect(unmodified, equals(entity));
    });

    test(
      'formattedTarget and displayText format with 2 decimals and kg/week unit',
      () {
        expect(entity.formattedTarget, equals('0.15–0.25 kg/week'));
        expect(entity.displayText, equals('0.15–0.25 kg/week'));

        const customEntity = GainTargetEntity(
          minWeeklyGainKg: 0.29,
          maxWeeklyGainKg: 0.57,
        );
        expect(customEntity.formattedTarget, equals('0.29–0.57 kg/week'));
        expect(customEntity.displayText, equals('0.29–0.57 kg/week'));

        const largeEntity = GainTargetEntity(
          minWeeklyGainKg: 5.0,
          maxWeeklyGainKg: 6.0,
        );
        expect(largeEntity.formattedTarget, equals('5.00–6.00 kg/week'));
      },
    );

    test('spread returns difference between max and min', () {
      expect(entity.spread, closeTo(0.10, 0.0001));
    });

    test('toString formats correctly', () {
      expect(
        entity.toString(),
        equals(
          'GainTargetEntity(minWeeklyGainKg: 0.15, maxWeeklyGainKg: 0.25)',
        ),
      );
    });

    test(
      'isValid helper correctly identifies valid and invalid configurations',
      () {
        expect(entity.isValid, isTrue);

        const validSmall = GainTargetEntity(
          minWeeklyGainKg: 0.01,
          maxWeeklyGainKg: 0.02,
        );
        expect(validSmall.isValid, isTrue);

        const validLarge = GainTargetEntity(
          minWeeklyGainKg: 5.0,
          maxWeeklyGainKg: 6.0,
        );
        expect(validLarge.isValid, isTrue);

        const zeroMin = GainTargetEntity(
          minWeeklyGainKg: 0.0,
          maxWeeklyGainKg: 0.25,
        );
        expect(zeroMin.isValid, isFalse);

        const negativeMin = GainTargetEntity(
          minWeeklyGainKg: -0.15,
          maxWeeklyGainKg: 0.25,
        );
        expect(negativeMin.isValid, isFalse);

        const equalEndpoints = GainTargetEntity(
          minWeeklyGainKg: 0.20,
          maxWeeklyGainKg: 0.20,
        );
        expect(equalEndpoints.isValid, isFalse);

        const reversedEndpoints = GainTargetEntity(
          minWeeklyGainKg: 0.30,
          maxWeeklyGainKg: 0.20,
        );
        expect(reversedEndpoints.isValid, isFalse);

        const nanMin = GainTargetEntity(
          minWeeklyGainKg: double.nan,
          maxWeeklyGainKg: 0.25,
        );
        expect(nanMin.isValid, isFalse);

        const infMax = GainTargetEntity(
          minWeeklyGainKg: 0.15,
          maxWeeklyGainKg: double.infinity,
        );
        expect(infMax.isValid, isFalse);
      },
    );
  });
}
