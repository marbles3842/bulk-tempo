import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/features/gain_target/data/models/gain_target_dto.dart';
import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';

void main() {
  group('GainTargetDto', () {
    const validEntity = GainTargetEntity(
      minWeeklyGainKg: 0.15,
      maxWeeklyGainKg: 0.25,
    );
    const validDto = GainTargetDto(
      minWeeklyGainKg: 0.15,
      maxWeeklyGainKg: 0.25,
    );

    test('converts to/from entity faithfully', () {
      final dto = GainTargetDto.fromEntity(validEntity);
      expect(dto.minWeeklyGainKg, 0.15);
      expect(dto.maxWeeklyGainKg, 0.25);
      expect(dto.toEntity(), equals(validEntity));
    });

    test('serializes to JSON correctly', () {
      final json = validDto.toJson();
      expect(json, {'minWeeklyGainKg': 0.15, 'maxWeeklyGainKg': 0.25});
    });

    test('deserializes from valid double JSON map', () {
      final dto = GainTargetDto.fromJson({
        'minWeeklyGainKg': 0.15,
        'maxWeeklyGainKg': 0.25,
      });
      expect(dto, equals(validDto));
      expect(dto.minWeeklyGainKg, 0.15);
      expect(dto.maxWeeklyGainKg, 0.25);
    });

    test('deserializes from integer numbers (num.toDouble)', () {
      final dto = GainTargetDto.fromJson({
        'minWeeklyGainKg': 1,
        'maxWeeklyGainKg': 2,
      });
      expect(dto.minWeeklyGainKg, 1.0);
      expect(dto.maxWeeklyGainKg, 2.0);
      expect(dto.toEntity().isValid, isTrue);
    });

    test('supports unconstrained upper bound values (e.g. 5.0 to 6.0)', () {
      final dto = GainTargetDto.fromJson({
        'minWeeklyGainKg': 5.0,
        'maxWeeklyGainKg': 6.0,
      });
      expect(dto.minWeeklyGainKg, 5.0);
      expect(dto.maxWeeklyGainKg, 6.0);
    });

    test('throws FormatException when minWeeklyGainKg is missing', () {
      expect(
        () => GainTargetDto.fromJson({'maxWeeklyGainKg': 0.25}),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Missing required gain target fields'),
          ),
        ),
      );
    });

    test('throws FormatException when maxWeeklyGainKg is missing', () {
      expect(
        () => GainTargetDto.fromJson({'minWeeklyGainKg': 0.15}),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Missing required gain target fields'),
          ),
        ),
      );
    });

    test('throws FormatException when fields are strings', () {
      expect(
        () => GainTargetDto.fromJson({
          'minWeeklyGainKg': '0.15',
          'maxWeeklyGainKg': 0.25,
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('must be numeric numbers'),
          ),
        ),
      );

      expect(
        () => GainTargetDto.fromJson({
          'minWeeklyGainKg': 0.15,
          'maxWeeklyGainKg': '0.25',
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('must be numeric numbers'),
          ),
        ),
      );
    });

    test('throws FormatException when fields are booleans or nulls', () {
      expect(
        () => GainTargetDto.fromJson({
          'minWeeklyGainKg': true,
          'maxWeeklyGainKg': false,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when min is zero or negative', () {
      expect(
        () => GainTargetDto.fromJson({
          'minWeeklyGainKg': 0.0,
          'maxWeeklyGainKg': 0.25,
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('greater than 0'),
          ),
        ),
      );

      expect(
        () => GainTargetDto.fromJson({
          'minWeeklyGainKg': -0.15,
          'maxWeeklyGainKg': 0.25,
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('greater than 0'),
          ),
        ),
      );
    });

    test('throws FormatException when max <= min (equal or reversed)', () {
      expect(
        () => GainTargetDto.fromJson({
          'minWeeklyGainKg': 0.25,
          'maxWeeklyGainKg': 0.25,
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('greater than minimum'),
          ),
        ),
      );

      expect(
        () => GainTargetDto.fromJson({
          'minWeeklyGainKg': 0.35,
          'maxWeeklyGainKg': 0.25,
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('greater than minimum'),
          ),
        ),
      );
    });

    test(
      'throws FormatException when values are nonfinite (NaN, infinity)',
      () {
        expect(
          () => GainTargetDto.fromJson({
            'minWeeklyGainKg': double.nan,
            'maxWeeklyGainKg': 0.25,
          }),
          throwsA(isA<FormatException>()),
        );

        expect(
          () => GainTargetDto.fromJson({
            'minWeeklyGainKg': 0.15,
            'maxWeeklyGainKg': double.infinity,
          }),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test('value equality and hashCode', () {
      const dto1 = GainTargetDto(minWeeklyGainKg: 0.15, maxWeeklyGainKg: 0.25);
      const dto2 = GainTargetDto(minWeeklyGainKg: 0.15, maxWeeklyGainKg: 0.25);
      const dto3 = GainTargetDto(minWeeklyGainKg: 0.2, maxWeeklyGainKg: 0.3);

      expect(dto1, equals(dto2));
      expect(dto1.hashCode, equals(dto2.hashCode));
      expect(dto1, isNot(equals(dto3)));
      expect(dto1.toString(), contains('minWeeklyGainKg: 0.15'));
    });
  });
}
