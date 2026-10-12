import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/features/workout/data/models/workout_dto.dart';
import 'package:bulk_tempo/features/workout/data/repositories/workout_repository_impl.dart';

import '../../../../test_helpers/mocks.dart';

void main() {
  late MockHevyKeyLocalDataSource mockLocalDataSource;
  late MockWorkoutRemoteDataSource mockRemoteDataSource;
  late WorkoutRepositoryImpl repository;

  const validKey = 'f4352809-838a-4e2c-98bb-922f1f14e552';

  WorkoutDto createWorkoutDto({required String id, required DateTime utcTime}) {
    return WorkoutDto(
      id: id,
      title: 'Workout $id',
      startTime: utcTime.toUtc().toIso8601String(),
      endTime: utcTime.add(const Duration(hours: 1)).toUtc().toIso8601String(),
      exercises: const [],
    );
  }

  setUp(() {
    mockLocalDataSource = MockHevyKeyLocalDataSource();
    mockRemoteDataSource = MockWorkoutRemoteDataSource();
    repository = WorkoutRepositoryImpl(
      mockLocalDataSource,
      mockRemoteDataSource,
    );
  });

  group('WorkoutRepositoryImpl.validateAndSaveApiKey', () {
    test(
      'rejects invalid UUID format before calling remote or local data sources',
      () async {
        final result = await repository.validateAndSaveApiKey(
          userId: 'user_1',
          apiKey: 'invalid-key',
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ValidationFailure>());
        verifyZeroInteractions(mockRemoteDataSource);
        verifyZeroInteractions(mockLocalDataSource);
      },
    );

    test(
      'pre-validates key via fetchWorkoutCount and saves only when remote succeeds',
      () async {
        when(
          () => mockRemoteDataSource.fetchWorkoutCount(apiKey: validKey),
        ).thenAnswer((_) async => 15);
        when(
          () => mockLocalDataSource.writeApiKey(
            userId: 'user_1',
            apiKey: validKey,
          ),
        ).thenAnswer((_) async {});

        final result = await repository.validateAndSaveApiKey(
          userId: 'user_1',
          apiKey: '  $validKey  ',
        );

        expect(result.isSuccess, isTrue);
        verify(
          () => mockRemoteDataSource.fetchWorkoutCount(apiKey: validKey),
        ).called(1);
        verify(
          () => mockLocalDataSource.writeApiKey(
            userId: 'user_1',
            apiKey: validKey,
          ),
        ).called(1);
      },
    );

    test(
      'does not save key to local storage when fetchWorkoutCount throws AuthException',
      () async {
        when(
          () => mockRemoteDataSource.fetchWorkoutCount(apiKey: validKey),
        ).thenThrow(
          const AuthException('invalid-api-key', 'Invalid Hevy API key'),
        );

        final result = await repository.validateAndSaveApiKey(
          userId: 'user_1',
          apiKey: validKey,
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, const AuthFailure('Invalid Hevy API key'));
        verifyNever(
          () => mockLocalDataSource.writeApiKey(
            userId: any(named: 'userId'),
            apiKey: any(named: 'apiKey'),
          ),
        );
      },
    );
  });

  group('WorkoutRepositoryImpl.getSavedApiKey & clearApiKey', () {
    test('getSavedApiKey returns stored key or null', () async {
      when(
        () => mockLocalDataSource.readApiKey(userId: 'user_1'),
      ).thenAnswer((_) async => validKey);

      final res = await repository.getSavedApiKey(userId: 'user_1');
      expect(res.dataOrNull, validKey);
    });

    test('clearApiKey deletes stored key and maps CacheException', () async {
      when(
        () => mockLocalDataSource.deleteApiKey(userId: 'user_1'),
      ).thenThrow(const CacheException('Delete failed'));

      final res = await repository.clearApiKey(userId: 'user_1');
      expect(res.failureOrNull, const CacheFailure('Delete failed'));
    });
  });

  group('WorkoutRepositoryImpl.getWorkoutsForLastWeeks', () {
    // Reference clock: Wednesday 2026-10-07 12:00 local
    // currentWeekMonday = 2026-10-05
    // 12 weeks inclusive -> cutoffMonday = 2026-07-20
    final referenceNow = DateTime(2026, 10, 7, 12);

    test('returns AuthFailure when no API key is configured', () async {
      when(
        () => mockLocalDataSource.readApiKey(userId: 'user_1'),
      ).thenAnswer((_) async => null);

      final result = await repository.getWorkoutsForLastWeeks(
        userId: 'user_1',
        now: referenceNow,
      );

      expect(result.isFailure, isTrue);
      expect(
        result.failureOrNull,
        const AuthFailure('Hevy API key is not configured'),
      );
      verifyZeroInteractions(mockRemoteDataSource);
    });

    test(
      'paginates until cutoffMonday is reached, filters boundary page, and stops early',
      () async {
        when(
          () => mockLocalDataSource.readApiKey(userId: 'user_1'),
        ).thenAnswer((_) async => validKey);

        // Page 1: two recent workouts in Oct 2026
        final w1 = createWorkoutDto(
          id: 'w_1',
          utcTime: DateTime(2026, 10, 6, 12).toUtc(),
        );
        final w2 = createWorkoutDto(
          id: 'w_2',
          utcTime: DateTime(2026, 9, 15, 12).toUtc(),
        );

        // Page 2: one workout on cutoffMonday (2026-07-20) and one before (2026-07-19)
        final wOnCutoff = createWorkoutDto(
          id: 'w_cutoff',
          utcTime: DateTime(2026, 7, 20, 12).toUtc(),
        );
        final wBeforeCutoff = createWorkoutDto(
          id: 'w_old',
          utcTime: DateTime(2026, 7, 19, 12).toUtc(),
        );

        when(
          () => mockRemoteDataSource.fetchWorkoutsPage(
            apiKey: validKey,
            page: 1,
            pageSize: 10,
          ),
        ).thenAnswer(
          (_) async => PaginatedWorkoutsResponseDto(
            page: 1,
            pageCount: 5,
            workouts: [w1, w2],
          ),
        );

        when(
          () => mockRemoteDataSource.fetchWorkoutsPage(
            apiKey: validKey,
            page: 2,
            pageSize: 10,
          ),
        ).thenAnswer(
          (_) async => PaginatedWorkoutsResponseDto(
            page: 2,
            pageCount: 5,
            workouts: [wOnCutoff, wBeforeCutoff],
          ),
        );

        final result = await repository.getWorkoutsForLastWeeks(
          userId: 'user_1',
          weeks: 12,
          now: referenceNow,
        );

        expect(result.isSuccess, isTrue);
        final ids = result.dataOrNull!.map((w) => w.id).toList();
        expect(ids, ['w_1', 'w_2', 'w_cutoff']);

        // Page 3 must never be fetched because page 2 reached cutoffMonday
        verifyNever(
          () => mockRemoteDataSource.fetchWorkoutsPage(
            apiKey: validKey,
            page: 3,
            pageSize: 10,
          ),
        );
      },
    );

    test('stops at 15-page safety cap when all workouts are recent', () async {
      when(
        () => mockLocalDataSource.readApiKey(userId: 'user_1'),
      ).thenAnswer((_) async => validKey);

      for (int page = 1; page <= 20; page++) {
        when(
          () => mockRemoteDataSource.fetchWorkoutsPage(
            apiKey: validKey,
            page: page,
            pageSize: 10,
          ),
        ).thenAnswer(
          (_) async => PaginatedWorkoutsResponseDto(
            page: page,
            pageCount: 25,
            workouts: [
              createWorkoutDto(
                id: 'w_page_$page',
                utcTime: DateTime(2026, 10, 6, 12).toUtc(),
              ),
            ],
          ),
        );
      }

      final result = await repository.getWorkoutsForLastWeeks(
        userId: 'user_1',
        weeks: 12,
        now: referenceNow,
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull!.length, 15);
      verifyNever(
        () => mockRemoteDataSource.fetchWorkoutsPage(
          apiKey: validKey,
          page: 16,
          pageSize: 10,
        ),
      );
    });

    test(
      'fails fast on mid-pagination error without returning partial workouts',
      () async {
        when(
          () => mockLocalDataSource.readApiKey(userId: 'user_1'),
        ).thenAnswer((_) async => validKey);

        when(
          () => mockRemoteDataSource.fetchWorkoutsPage(
            apiKey: validKey,
            page: 1,
            pageSize: 10,
          ),
        ).thenAnswer(
          (_) async => PaginatedWorkoutsResponseDto(
            page: 1,
            pageCount: 3,
            workouts: [
              createWorkoutDto(
                id: 'w_1',
                utcTime: DateTime(2026, 10, 6, 12).toUtc(),
              ),
            ],
          ),
        );

        when(
          () => mockRemoteDataSource.fetchWorkoutsPage(
            apiKey: validKey,
            page: 2,
            pageSize: 10,
          ),
        ).thenThrow(
          const ServerException(message: 'Gateway timeout', statusCode: 504),
        );

        final result = await repository.getWorkoutsForLastWeeks(
          userId: 'user_1',
          weeks: 12,
          now: referenceNow,
        );

        expect(result.isFailure, isTrue);
        expect(
          result.failureOrNull,
          const ServerFailure('Gateway timeout', statusCode: 504),
        );
      },
    );
  });
}
