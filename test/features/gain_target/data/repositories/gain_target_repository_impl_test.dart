import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/features/gain_target/data/models/gain_target_dto.dart';
import 'package:bulk_tempo/features/gain_target/data/repositories/gain_target_repository_impl.dart';
import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';

import '../../../../test_helpers/mocks.dart';

void main() {
  late MockGainTargetRemoteDataSource mockRemoteDataSource;
  late GainTargetRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      const GainTargetDto(minWeeklyGainKg: 0.15, maxWeeklyGainKg: 0.25),
    );
  });

  setUp(() {
    mockRemoteDataSource = MockGainTargetRemoteDataSource();
    repository = GainTargetRepositoryImpl(mockRemoteDataSource);
  });

  group('GainTargetRepositoryImpl.getGainTarget', () {
    test(
      'returns ValidationFailure when userId is empty or whitespace',
      () async {
        final result1 = await repository.getGainTarget(userId: '');
        final result2 = await repository.getGainTarget(userId: '   ');

        expect(result1.isFailure, isTrue);
        expect(result1.failureOrNull, isA<ValidationFailure>());
        expect(result2.isFailure, isTrue);
        expect(result2.failureOrNull, isA<ValidationFailure>());
        verifyNever(
          () =>
              mockRemoteDataSource.getGainTarget(userId: any(named: 'userId')),
        );
      },
    );

    test('returns Success(null) when target does not exist', () async {
      when(() => mockRemoteDataSource.getGainTarget(userId: 'user_123'))
          .thenAnswer((_) async => null);

      final result = await repository.getGainTarget(userId: 'user_123');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isNull);
    });

    test('returns Success with GainTargetEntity mapped from DTO', () async {
      const dto = GainTargetDto(minWeeklyGainKg: 0.15, maxWeeklyGainKg: 0.25);

      when(() => mockRemoteDataSource.getGainTarget(userId: 'user_123'))
          .thenAnswer((_) async => dto);

      final result = await repository.getGainTarget(userId: 'user_123');

      expect(result.isSuccess, isTrue);
      final entity = result.dataOrNull!;
      expect(entity.minWeeklyGainKg, 0.15);
      expect(entity.maxWeeklyGainKg, 0.25);
    });

    test('maps AuthException to AuthFailure', () async {
      when(() => mockRemoteDataSource.getGainTarget(userId: 'user_123'))
          .thenThrow(const AuthException('permission-denied', 'No permission'));

      final result = await repository.getGainTarget(userId: 'user_123');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<AuthFailure>());
      expect(result.failureOrNull?.message, 'No permission');
    });

    test('maps NetworkException to NetworkFailure', () async {
      when(() => mockRemoteDataSource.getGainTarget(userId: 'user_123'))
          .thenThrow(const NetworkException('Network error occurred'));

      final result = await repository.getGainTarget(userId: 'user_123');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('maps ServerException to ServerFailure', () async {
      when(() => mockRemoteDataSource.getGainTarget(userId: 'user_123'))
          .thenThrow(const ServerException(message: 'Request timed out'));

      final result = await repository.getGainTarget(userId: 'user_123');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.message, 'Request timed out');
    });

    test('maps unexpected exception to UnknownFailure', () async {
      when(() => mockRemoteDataSource.getGainTarget(userId: 'user_123'))
          .thenThrow(Exception('Unexpected crash'));

      final result = await repository.getGainTarget(userId: 'user_123');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<UnknownFailure>());
    });
  });

  group('GainTargetRepositoryImpl.saveGainTarget', () {
    const validEntity = GainTargetEntity(
      minWeeklyGainKg: 0.15,
      maxWeeklyGainKg: 0.25,
    );

    test(
      'returns ValidationFailure when userId is empty or whitespace',
      () async {
        final result1 = await repository.saveGainTarget(
          userId: '',
          target: validEntity,
        );
        final result2 = await repository.saveGainTarget(
          userId: '  ',
          target: validEntity,
        );

        expect(result1.isFailure, isTrue);
        expect(result1.failureOrNull, isA<ValidationFailure>());
        expect(result2.isFailure, isTrue);
        expect(result2.failureOrNull, isA<ValidationFailure>());
        verifyNever(
          () => mockRemoteDataSource.saveGainTarget(
            userId: any(named: 'userId'),
            dto: any(named: 'dto'),
          ),
        );
      },
    );

    test(
      'validates domain invariants before calling data source (min <= 0)',
      () async {
        const invalidEntity = GainTargetEntity(
          minWeeklyGainKg: 0.0,
          maxWeeklyGainKg: 0.25,
        );

        final result = await repository.saveGainTarget(
          userId: 'user_123',
          target: invalidEntity,
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ValidationFailure>());
        verifyNever(
          () => mockRemoteDataSource.saveGainTarget(
            userId: any(named: 'userId'),
            dto: any(named: 'dto'),
          ),
        );
      },
    );

    test(
      'validates domain invariants before calling data source (min >= max)',
      () async {
        const invalidEntity = GainTargetEntity(
          minWeeklyGainKg: 0.30,
          maxWeeklyGainKg: 0.25,
        );

        final result = await repository.saveGainTarget(
          userId: 'user_123',
          target: invalidEntity,
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ValidationFailure>());
        verifyNever(
          () => mockRemoteDataSource.saveGainTarget(
            userId: any(named: 'userId'),
            dto: any(named: 'dto'),
          ),
        );
      },
    );

    test(
      'validates domain invariants before calling data source (nonfinite)',
      () async {
        const invalidEntity = GainTargetEntity(
          minWeeklyGainKg: 0.15,
          maxWeeklyGainKg: double.infinity,
        );

        final result = await repository.saveGainTarget(
          userId: 'user_123',
          target: invalidEntity,
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ValidationFailure>());
        verifyNever(
          () => mockRemoteDataSource.saveGainTarget(
            userId: any(named: 'userId'),
            dto: any(named: 'dto'),
          ),
        );
      },
    );

    test('saves DTO and returns Success with mapped entity on server acknowledgement', () async {
      const savedDto = GainTargetDto(
        minWeeklyGainKg: 0.15,
        maxWeeklyGainKg: 0.25,
      );

      when(
        () => mockRemoteDataSource.saveGainTarget(
          userId: 'user_123',
          dto: any(named: 'dto'),
        ),
      ).thenAnswer((_) async => savedDto);

      final result = await repository.saveGainTarget(
        userId: 'user_123',
        target: validEntity,
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals(validEntity));
      verify(
        () => mockRemoteDataSource.saveGainTarget(
          userId: 'user_123',
          dto: const GainTargetDto(
            minWeeklyGainKg: 0.15,
            maxWeeklyGainKg: 0.25,
          ),
        ),
      ).called(1);
    });

    test('maps remote AuthException to AuthFailure', () async {
      when(
        () => mockRemoteDataSource.saveGainTarget(
          userId: 'user_123',
          dto: any(named: 'dto'),
        ),
      ).thenThrow(
        const AuthException('permission-denied', 'Permission denied'),
      );

      final result = await repository.saveGainTarget(
        userId: 'user_123',
        target: validEntity,
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<AuthFailure>());
    });

    test('maps remote NetworkException to NetworkFailure', () async {
      when(
        () => mockRemoteDataSource.saveGainTarget(
          userId: 'user_123',
          dto: any(named: 'dto'),
        ),
      ).thenThrow(const NetworkException('Network error'));

      final result = await repository.saveGainTarget(
        userId: 'user_123',
        target: validEntity,
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('maps remote ServerException to ServerFailure', () async {
      when(
        () => mockRemoteDataSource.saveGainTarget(
          userId: 'user_123',
          dto: any(named: 'dto'),
        ),
      ).thenThrow(const ServerException(message: 'Database error'));

      final result = await repository.saveGainTarget(
        userId: 'user_123',
        target: validEntity,
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test('maps unexpected exception to UnknownFailure', () async {
      when(
        () => mockRemoteDataSource.saveGainTarget(
          userId: 'user_123',
          dto: any(named: 'dto'),
        ),
      ).thenThrow(Exception('Crash'));

      final result = await repository.saveGainTarget(
        userId: 'user_123',
        target: validEntity,
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<UnknownFailure>());
    });
  });
}
