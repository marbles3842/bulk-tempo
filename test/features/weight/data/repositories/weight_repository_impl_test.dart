import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/features/weight/data/models/weight_entry_dto.dart';
import 'package:bulk_tempo/features/weight/data/repositories/weight_repository_impl.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';

import '../../../../test_helpers/mocks.dart';

void main() {
  late MockWeightRemoteDataSource mockRemoteDataSource;
  late WeightRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      const WeightEntryDto(
        date: '2026-10-10',
        weightKg: 80.0,
        updatedAt: '2026-10-10T12:00:00.000Z',
      ),
    );
  });

  setUp(() {
    mockRemoteDataSource = MockWeightRemoteDataSource();
    repository = WeightRepositoryImpl(mockRemoteDataSource);
  });

  group('WeightRepositoryImpl.getWeightEntries', () {
    test('returns ValidationFailure when userId is empty', () async {
      final result = await repository.getWeightEntries(userId: '   ');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      verifyNever(
        () =>
            mockRemoteDataSource.getWeightEntries(userId: any(named: 'userId')),
      );
    });

    test('returns Success with entities mapped from DTOs', () async {
      final dtos = [
        const WeightEntryDto(
          date: '2026-10-10',
          weightKg: 82.5,
          updatedAt: '2026-10-10T12:00:00.000Z',
        ),
      ];

      when(
        () => mockRemoteDataSource.getWeightEntries(userId: 'user_1'),
      ).thenAnswer((_) async => dtos);

      final result = await repository.getWeightEntries(userId: 'user_1');

      expect(result.isSuccess, isTrue);
      final entries = result.dataOrNull!;
      expect(entries.length, 1);
      expect(entries.first.dateIso, '2026-10-10');
      expect(entries.first.weightKg, 82.5);
    });

    test('maps AuthException to AuthFailure', () async {
      when(
        () => mockRemoteDataSource.getWeightEntries(userId: 'user_1'),
      ).thenThrow(const AuthException('permission-denied', 'No permission'));

      final result = await repository.getWeightEntries(userId: 'user_1');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<AuthFailure>());
      expect(result.failureOrNull?.message, 'No permission');
    });

    test('maps NetworkException to NetworkFailure', () async {
      when(
        () => mockRemoteDataSource.getWeightEntries(userId: 'user_1'),
      ).thenThrow(const NetworkException('No connection'));

      final result = await repository.getWeightEntries(userId: 'user_1');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('maps ServerException to ServerFailure', () async {
      when(
        () => mockRemoteDataSource.getWeightEntries(userId: 'user_1'),
      ).thenThrow(
        const ServerException(message: 'DB failure', statusCode: 500),
      );

      final result = await repository.getWeightEntries(userId: 'user_1');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
      expect((result.failureOrNull as ServerFailure).statusCode, 500);
    });

    test('maps unexpected exception to UnknownFailure', () async {
      when(
        () => mockRemoteDataSource.getWeightEntries(userId: 'user_1'),
      ).thenThrow(Exception('Boom'));

      final result = await repository.getWeightEntries(userId: 'user_1');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<UnknownFailure>());
    });
  });

  group('WeightRepositoryImpl.saveWeightEntry', () {
    final validEntity = WeightEntryEntity(
      dateIso: '2026-10-10',
      date: DateTime.utc(2026, 10, 10),
      weightKg: 82.5,
      updatedAt: DateTime.utc(2026, 10, 10, 12),
    );

    test('returns ValidationFailure when userId is empty', () async {
      final result = await repository.saveWeightEntry(
        userId: '',
        entry: validEntity,
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('returns ValidationFailure when weightKg is below 20.0', () async {
      final invalidEntity = validEntity.copyWith(weightKg: 19.9);

      final result = await repository.saveWeightEntry(
        userId: 'user_1',
        entry: invalidEntity,
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull?.message, contains('20.0 and 300.0 kg'));
    });

    test('returns ValidationFailure when weightKg is above 300.0', () async {
      final invalidEntity = validEntity.copyWith(weightKg: 300.1);

      final result = await repository.saveWeightEntry(
        userId: 'user_1',
        entry: invalidEntity,
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull?.message, contains('20.0 and 300.0 kg'));
    });

    test('returns ValidationFailure when dateIso is invalid', () async {
      final invalidEntity = validEntity.copyWith(dateIso: '2026-02-30');

      final result = await repository.saveWeightEntry(
        userId: 'user_1',
        entry: invalidEntity,
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('saves DTO and returns Success entity', () async {
      const savedDto = WeightEntryDto(
        date: '2026-10-10',
        weightKg: 82.5,
        updatedAt: '2026-10-10T12:00:00.000Z',
      );

      when(
        () => mockRemoteDataSource.saveWeightEntry(
          userId: 'user_1',
          dto: any(named: 'dto'),
        ),
      ).thenAnswer((_) async => savedDto);

      final result = await repository.saveWeightEntry(
        userId: 'user_1',
        entry: validEntity,
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.dateIso, '2026-10-10');
      expect(result.dataOrNull?.weightKg, 82.5);
    });

    test('maps remote exceptions to domain failures', () async {
      when(
        () => mockRemoteDataSource.saveWeightEntry(
          userId: 'user_1',
          dto: any(named: 'dto'),
        ),
      ).thenThrow(const NetworkException('Offline'));

      final result = await repository.saveWeightEntry(
        userId: 'user_1',
        entry: validEntity,
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });
  });

  group('WeightRepositoryImpl.deleteWeightEntry', () {
    for (final userId in ['', '   ']) {
      test('rejects empty user "$userId" before data access', () async {
        final result = await repository.deleteWeightEntry(
          userId: userId,
          dateIso: '2026-10-10',
        );
        expect(result.failureOrNull, isA<ValidationFailure>());
        verifyZeroInteractions(mockRemoteDataSource);
      });
    }

    for (final dateIso in [
      '',
      '2026-02-30',
      '2025-02-29',
      '2026-13-01',
      '2026-01-00',
      '2026-1-01',
      '2026-10-10T00:00:00Z',
      ' 2026-10-10',
      '2026-10-10 ',
      '2026-10-10/other',
    ]) {
      test(
        'rejects invalid or noncanonical date "$dateIso" before access',
        () async {
          final result = await repository.deleteWeightEntry(
            userId: 'user_1',
            dateIso: dateIso,
          );
          expect(result.failureOrNull, isA<ValidationFailure>());
          verifyZeroInteractions(mockRemoteDataSource);
        },
      );
    }

    test('forwards an older date and succeeds on repeated deletion', () async {
      when(
        () => mockRemoteDataSource.deleteWeightEntry(
          userId: 'user_1',
          dateIso: '2000-02-29',
        ),
      ).thenAnswer((_) async {});

      for (var attempt = 0; attempt < 2; attempt++) {
        final result = await repository.deleteWeightEntry(
          userId: 'user_1',
          dateIso: '2000-02-29',
        );
        expect(result.isSuccess, isTrue);
      }
      verify(
        () => mockRemoteDataSource.deleteWeightEntry(
          userId: 'user_1',
          dateIso: '2000-02-29',
        ),
      ).called(2);
      verifyNoMoreInteractions(mockRemoteDataSource);
    });

    final failures = <Exception, AppFailure>{
      const AuthException('permission-denied', 'No permission'):
          const AuthFailure('No permission'),
      const NetworkException('Offline'): const NetworkFailure(
        'Network error. Please check your connection.',
      ),
      const ServerException(message: 'DB failure', statusCode: 500):
          const ServerFailure('DB failure', statusCode: 500),
      Exception('Unexpected'): const UnknownFailure(
        'An unexpected error occurred. Please try again.',
      ),
    };
    for (final entry in failures.entries) {
      test(
        'maps ${entry.key.runtimeType} to ${entry.value.runtimeType}',
        () async {
          when(
            () => mockRemoteDataSource.deleteWeightEntry(
              userId: 'user_1',
              dateIso: '2026-10-10',
            ),
          ).thenAnswer((_) async => throw entry.key);
          final result = await repository.deleteWeightEntry(
            userId: 'user_1',
            dateIso: '2026-10-10',
          );
          expect(result.failureOrNull, entry.value);
        },
      );
    }
  });
}
