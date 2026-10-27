import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/features/dashboard/data/models/pace_assessment_dto.dart';
import 'package:bulk_tempo/features/dashboard/data/repositories/pace_assessment_repository_impl.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/pace_assessment_entity.dart';
import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';

import '../../../../test_helpers/mocks.dart';

void main() {
  late MockPaceAssessmentCacheDataSource mockCacheDataSource;
  late MockPaceAssessmentAiDataSource mockAiDataSource;
  late PaceAssessmentRepositoryImpl repository;

  final fixedNow = DateTime.utc(2026, 4, 12, 10, 0);

  final sampleInput = PaceAssessmentInputEntity(
    fingerprint: 'fp_current',
    localeCode: 'en',
    gainTarget: const GainTargetEntity(
      minWeeklyGainKg: 0.15,
      maxWeeklyGainKg: 0.25,
    ),
    baselineStatus: PaceAssessmentStatus.onTarget,
    currentPaceKgPerWeek: 0.20,
    assessedWeek: AssessedWeekContextEntity(
      weekStartIso: '2026-04-06',
      weekStartMonday: DateTime.utc(2026, 4, 6),
      weekEndSunday: DateTime.utc(2026, 4, 12),
      averageWeightKg: 80.40,
      loggedWeightDaysCount: 7,
      isCurrentWeek: true,
      isPartialWeek: false,
      paceKgPerWeek: 0.20,
      workoutCount: 3,
      totalWorkingSets: 15,
      totalVolumeKg: 4500.0,
      exercises: const <WeeklyExercisePerformanceEntity>[],
    ),
    priorWeeks: <AssessedWeekContextEntity>[
      AssessedWeekContextEntity(
        weekStartIso: '2026-03-23',
        weekStartMonday: DateTime.utc(2026, 3, 23),
        weekEndSunday: DateTime.utc(2026, 3, 29),
        averageWeightKg: 80.00,
        loggedWeightDaysCount: 7,
        isCurrentWeek: false,
        isPartialWeek: false,
        paceKgPerWeek: null,
        workoutCount: 2,
        totalWorkingSets: 10,
        totalVolumeKg: 3000.0,
        exercises: const <WeeklyExercisePerformanceEntity>[],
      ),
      AssessedWeekContextEntity(
        weekStartIso: '2026-03-30',
        weekStartMonday: DateTime.utc(2026, 3, 30),
        weekEndSunday: DateTime.utc(2026, 4, 5),
        averageWeightKg: 80.20,
        loggedWeightDaysCount: 7,
        isCurrentWeek: false,
        isPartialWeek: false,
        paceKgPerWeek: 0.20,
        workoutCount: 3,
        totalWorkingSets: 14,
        totalVolumeKg: 4200.0,
        exercises: const <WeeklyExercisePerformanceEntity>[],
      ),
    ],
  );

  PaceAssessmentDto buildDto({String fingerprint = 'fp_current'}) {
    return PaceAssessmentDto(
      status: 'onTarget',
      baselineStatus: 'onTarget',
      headlineSummary: 'Steady progress within target range.',
      weightTrendAnalysis: 'Gaining 0.20 kg/week consistently.',
      workoutContextAnalysis: 'Training volume is trending upward.',
      actionableTakeaways: const <String>[
        'Keep daily nutrition consistent.',
        'Progress main compound lifts.',
      ],
      assessedWeekStartIso: '2026-04-06',
      isAssessedWeekPartial: false,
      currentPaceKgPerWeek: 0.20,
      targetMinKgPerWeek: 0.15,
      targetMaxKgPerWeek: 0.25,
      priorWeightWeeksCount: 2,
      localeCode: 'en',
      fingerprint: fingerprint,
      generatedAt: '2026-04-12T10:00:00.000Z',
    );
  }

  setUpAll(() {
    registerFallbackValue(sampleInput);
    registerFallbackValue(buildDto());
  });

  setUp(() {
    mockCacheDataSource = MockPaceAssessmentCacheDataSource();
    mockAiDataSource = MockPaceAssessmentAiDataSource();
    repository = PaceAssessmentRepositoryImpl(
      cacheDataSource: mockCacheDataSource,
      aiDataSource: mockAiDataSource,
      clock: () => fixedNow,
    );
  });

  group('PaceAssessmentRepositoryImpl.getOrGenerateAssessment', () {
    test(
      'returns ValidationFailure when userId is empty or whitespace',
      () async {
        final result = await repository.getOrGenerateAssessment(
          userId: '   ',
          input: sampleInput,
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ValidationFailure>());
        verifyNever(
          () => mockCacheDataSource.getCachedAssessment(
            userId: any(named: 'userId'),
          ),
        );
        verifyNever(
          () => mockAiDataSource.generateAssessment(
            input: any(named: 'input'),
            now: any(named: 'now'),
          ),
        );
      },
    );

    test(
      'returns cached entity on cache hit (matching fingerprint) without calling AI',
      () async {
        final cachedDto = buildDto(fingerprint: 'fp_current');
        when(
          () => mockCacheDataSource.getCachedAssessment(userId: 'user_123'),
        ).thenAnswer((_) async => cachedDto);

        final result = await repository.getOrGenerateAssessment(
          userId: 'user_123',
          input: sampleInput,
        );

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, equals(cachedDto.toEntity()));
        verify(
          () => mockCacheDataSource.getCachedAssessment(userId: 'user_123'),
        ).called(1);
        verifyNever(
          () => mockAiDataSource.generateAssessment(
            input: any(named: 'input'),
            now: any(named: 'now'),
          ),
        );
      },
    );

    test(
      'calls AI and saves to cache on cache miss (mismatched fingerprint)',
      () async {
        final staleDto = buildDto(fingerprint: 'fp_old');
        final freshDto = buildDto(fingerprint: 'fp_current');

        when(
          () => mockCacheDataSource.getCachedAssessment(userId: 'user_123'),
        ).thenAnswer((_) async => staleDto);
        when(
          () => mockAiDataSource.generateAssessment(
            input: sampleInput,
            now: fixedNow,
          ),
        ).thenAnswer((_) async => freshDto);
        when(
          () => mockCacheDataSource.saveCachedAssessment(
            userId: 'user_123',
            dto: freshDto,
          ),
        ).thenAnswer((_) async {});

        final result = await repository.getOrGenerateAssessment(
          userId: 'user_123',
          input: sampleInput,
        );

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, equals(freshDto.toEntity()));
        verify(
          () => mockCacheDataSource.getCachedAssessment(userId: 'user_123'),
        ).called(1);
        verify(
          () => mockAiDataSource.generateAssessment(
            input: sampleInput,
            now: fixedNow,
          ),
        ).called(1);
        verify(
          () => mockCacheDataSource.saveCachedAssessment(
            userId: 'user_123',
            dto: freshDto,
          ),
        ).called(1);
      },
    );

    test(
      'bypasses cache read when forceRefresh is true and saves fresh AI assessment',
      () async {
        final freshDto = buildDto(fingerprint: 'fp_current');
        when(
          () => mockAiDataSource.generateAssessment(
            input: sampleInput,
            now: fixedNow,
          ),
        ).thenAnswer((_) async => freshDto);
        when(
          () => mockCacheDataSource.saveCachedAssessment(
            userId: 'user_123',
            dto: freshDto,
          ),
        ).thenAnswer((_) async {});

        final result = await repository.getOrGenerateAssessment(
          userId: 'user_123',
          input: sampleInput,
          forceRefresh: true,
        );

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, equals(freshDto.toEntity()));
        verifyNever(
          () => mockCacheDataSource.getCachedAssessment(
            userId: any(named: 'userId'),
          ),
        );
        verify(
          () => mockAiDataSource.generateAssessment(
            input: sampleInput,
            now: fixedNow,
          ),
        ).called(1);
        verify(
          () => mockCacheDataSource.saveCachedAssessment(
            userId: 'user_123',
            dto: freshDto,
          ),
        ).called(1);
      },
    );

    test(
      'treats cache write failure as non-fatal when AI generation succeeds',
      () async {
        final freshDto = buildDto(fingerprint: 'fp_current');
        when(
          () => mockCacheDataSource.getCachedAssessment(userId: 'user_123'),
        ).thenAnswer((_) async => null);
        when(
          () => mockAiDataSource.generateAssessment(
            input: sampleInput,
            now: fixedNow,
          ),
        ).thenAnswer((_) async => freshDto);
        when(
          () => mockCacheDataSource.saveCachedAssessment(
            userId: 'user_123',
            dto: freshDto,
          ),
        ).thenThrow(const ServerException(message: 'Cache write failed'));

        final result = await repository.getOrGenerateAssessment(
          userId: 'user_123',
          input: sampleInput,
        );

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, equals(freshDto.toEntity()));
      },
    );

    test(
      'maps AuthException, NetworkException, ServerException, and unexpected exceptions to failures',
      () async {
        when(
          () => mockCacheDataSource.getCachedAssessment(userId: 'user_123'),
        ).thenAnswer((_) async => null);

        when(
          () => mockAiDataSource.generateAssessment(
            input: sampleInput,
            now: fixedNow,
          ),
        ).thenThrow(const AuthException('permission-denied', 'Denied'));
        final authResult = await repository.getOrGenerateAssessment(
          userId: 'user_123',
          input: sampleInput,
        );
        expect(authResult.failureOrNull, isA<AuthFailure>());

        when(
          () => mockAiDataSource.generateAssessment(
            input: sampleInput,
            now: fixedNow,
          ),
        ).thenThrow(const NetworkException('No internet'));
        final netResult = await repository.getOrGenerateAssessment(
          userId: 'user_123',
          input: sampleInput,
        );
        expect(netResult.failureOrNull, isA<NetworkFailure>());

        when(
          () => mockAiDataSource.generateAssessment(
            input: sampleInput,
            now: fixedNow,
          ),
        ).thenThrow(const ServerException(message: 'Malformed AI JSON'));
        final serverResult = await repository.getOrGenerateAssessment(
          userId: 'user_123',
          input: sampleInput,
        );
        expect(serverResult.failureOrNull, isA<ServerFailure>());

        when(
          () => mockAiDataSource.generateAssessment(
            input: sampleInput,
            now: fixedNow,
          ),
        ).thenThrow(StateError('Unexpected crash'));
        final unknownResult = await repository.getOrGenerateAssessment(
          userId: 'user_123',
          input: sampleInput,
        );
        expect(unknownResult.failureOrNull, isA<UnknownFailure>());
      },
    );
  });
}
