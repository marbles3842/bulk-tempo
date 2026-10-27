import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/features/dashboard/data/datasources/pace_assessment_cache_data_source.dart';
import 'package:bulk_tempo/features/dashboard/data/models/pace_assessment_dto.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/pace_assessment_entity.dart';

import '../../../../test_helpers/mocks.dart';

void main() {
  late MockFirebaseDatabase mockDatabase;
  late MockDatabaseReference mockRef;
  late MockDataSnapshot mockSnapshot;
  late PaceAssessmentCacheDataSource dataSource;

  Map<Object?, Object?> buildValidMap({String fingerprint = 'fp_1'}) {
    return <Object?, Object?>{
      'status': 'onTarget',
      'baselineStatus': 'onTarget',
      'headlineSummary': 'Pace is right on target.',
      'weightTrendAnalysis': 'Consistent weekly gain of 0.20 kg.',
      'workoutContextAnalysis': 'Bench press and squat progressed.',
      'actionableTakeaways': <Object?>[
        'Keep daily calorie intake steady.',
        'Add 2.5 kg to main lifts next week.',
      ],
      'assessedWeekStartIso': '2026-04-06',
      'isAssessedWeekPartial': false,
      'currentPaceKgPerWeek': 0.20,
      'targetMinKgPerWeek': 0.15,
      'targetMaxKgPerWeek': 0.25,
      'priorWeightWeeksCount': 3,
      'localeCode': 'en',
      'fingerprint': fingerprint,
      'generatedAt': '2026-04-12T10:00:00.000Z',
    };
  }

  const validDto = PaceAssessmentDto(
    status: 'onTarget',
    baselineStatus: 'onTarget',
    headlineSummary: 'Pace is right on target.',
    weightTrendAnalysis: 'Consistent weekly gain of 0.20 kg.',
    workoutContextAnalysis: 'Bench press and squat progressed.',
    actionableTakeaways: <String>[
      'Keep daily calorie intake steady.',
      'Add 2.5 kg to main lifts next week.',
    ],
    assessedWeekStartIso: '2026-04-06',
    isAssessedWeekPartial: false,
    currentPaceKgPerWeek: 0.20,
    targetMinKgPerWeek: 0.15,
    targetMaxKgPerWeek: 0.25,
    priorWeightWeeksCount: 3,
    localeCode: 'en',
    fingerprint: 'fp_1',
    generatedAt: '2026-04-12T10:00:00.000Z',
  );

  setUp(() {
    mockDatabase = MockFirebaseDatabase();
    mockRef = MockDatabaseReference();
    mockSnapshot = MockDataSnapshot();
    dataSource = PaceAssessmentCacheDataSourceImpl(mockDatabase);

    when(() => mockDatabase.ref(any())).thenReturn(mockRef);
  });

  group('PaceAssessmentCacheDataSource.getCachedAssessment', () {
    test('returns null when snapshot does not exist', () async {
      when(() => mockRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(false);
      when(() => mockSnapshot.value).thenReturn(null);

      final result = await dataSource.getCachedAssessment(userId: 'user_123');

      expect(result, isNull);
      verify(
        () => mockDatabase.ref('users/user_123/pace_assessment'),
      ).called(1);
    });

    test('returns null when snapshot exists but value is null', () async {
      when(() => mockRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.value).thenReturn(null);

      final result = await dataSource.getCachedAssessment(userId: 'user_123');

      expect(result, isNull);
    });

    test(
      'returns parsed PaceAssessmentDto and converts cleanly to entity when valid map exists',
      () async {
        when(() => mockRef.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(true);
        when(() => mockSnapshot.value).thenReturn(buildValidMap());

        final result = await dataSource.getCachedAssessment(userId: 'user_123');

        expect(result, isNotNull);
        expect(result, equals(validDto));

        final entity = result!.toEntity();
        expect(entity.status, PaceAssessmentStatus.onTarget);
        expect(entity.baselineStatus, PaceAssessmentStatus.onTarget);
        expect(entity.headlineSummary, 'Pace is right on target.');
        expect(entity.actionableTakeaways, hasLength(2));
        expect(entity.fingerprint, 'fp_1');
        expect(PaceAssessmentDto.fromEntity(entity), equals(validDto));
      },
    );

    test(
      'returns null when cached map is malformed (invalid status or missing fields)',
      () async {
        when(() => mockRef.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(true);
        final malformed = buildValidMap()..['status'] = 'unknownStatus';
        when(() => mockSnapshot.value).thenReturn(malformed);

        final result = await dataSource.getCachedAssessment(userId: 'user_123');

        expect(result, isNull);
      },
    );

    test('returns null when cached value is not a Map', () async {
      when(() => mockRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.value).thenReturn('corrupted_scalar');

      final result = await dataSource.getCachedAssessment(userId: 'user_123');

      expect(result, isNull);
    });

    test('throws ServerException on TimeoutException', () async {
      when(
        () => mockRef.get(),
      ).thenThrow(TimeoutException('Timeout waiting for database response'));

      expect(
        () => dataSource.getCachedAssessment(userId: 'user_123'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            contains('Request timed out'),
          ),
        ),
      );
    });

    test('throws AuthException on permission-denied', () async {
      when(() => mockRef.get()).thenThrow(
        FirebaseException(
          plugin: 'database',
          code: 'permission-denied',
          message: 'Permission denied',
        ),
      );

      expect(
        () => dataSource.getCachedAssessment(userId: 'user_123'),
        throwsA(isA<AuthException>()),
      );
    });

    test('throws NetworkException on network errors', () async {
      when(() => mockRef.get()).thenThrow(
        FirebaseException(
          plugin: 'database',
          code: 'network-error',
          message: 'Offline',
        ),
      );

      expect(
        () => dataSource.getCachedAssessment(userId: 'user_123'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('throws ServerException on generic FirebaseException', () async {
      when(() => mockRef.get()).thenThrow(
        FirebaseException(
          plugin: 'database',
          code: 'unknown',
          message: 'Database error',
        ),
      );

      expect(
        () => dataSource.getCachedAssessment(userId: 'user_123'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('PaceAssessmentCacheDataSource.saveCachedAssessment', () {
    test('saves DTO at users/user_123/pace_assessment', () async {
      when(() => mockRef.set(any())).thenAnswer((_) async {});

      await dataSource.saveCachedAssessment(userId: 'user_123', dto: validDto);

      verify(
        () => mockDatabase.ref('users/user_123/pace_assessment'),
      ).called(1);
      verify(() => mockRef.set(validDto.toJson())).called(1);
    });

    test('throws AuthException on permission-denied', () async {
      when(() => mockRef.set(any())).thenThrow(
        FirebaseException(
          plugin: 'database',
          code: 'permission-denied',
          message: 'Permission denied',
        ),
      );

      expect(
        () =>
            dataSource.saveCachedAssessment(userId: 'user_123', dto: validDto),
        throwsA(isA<AuthException>()),
      );
    });

    test('throws NetworkException on network error', () async {
      when(() => mockRef.set(any())).thenThrow(
        FirebaseException(
          plugin: 'database',
          code: 'unavailable',
          message: 'Unavailable',
        ),
      );

      expect(
        () =>
            dataSource.saveCachedAssessment(userId: 'user_123', dto: validDto),
        throwsA(isA<NetworkException>()),
      );
    });

    test('throws ServerException on other crash', () async {
      when(() => mockRef.set(any())).thenThrow(Exception('Crash'));

      expect(
        () =>
            dataSource.saveCachedAssessment(userId: 'user_123', dto: validDto),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
