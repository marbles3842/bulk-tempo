import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/features/gain_target/data/datasources/gain_target_remote_data_source.dart';
import 'package:bulk_tempo/features/gain_target/data/models/gain_target_dto.dart';

import '../../../../test_helpers/mocks.dart';

void main() {
  late MockFirebaseDatabase mockDatabase;
  late MockDatabaseReference mockRef;
  late MockDataSnapshot mockSnapshot;
  late GainTargetRemoteDataSource dataSource;

  setUp(() {
    mockDatabase = MockFirebaseDatabase();
    mockRef = MockDatabaseReference();
    mockSnapshot = MockDataSnapshot();
    dataSource = GainTargetRemoteDataSourceImpl(mockDatabase);

    when(() => mockDatabase.ref(any())).thenReturn(mockRef);
  });

  group('GainTargetRemoteDataSource.getGainTarget', () {
    test('returns null when snapshot does not exist', () async {
      when(() => mockRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(false);
      when(() => mockSnapshot.value).thenReturn(null);

      final result = await dataSource.getGainTarget(userId: 'user_123');

      expect(result, isNull);
      verify(() => mockDatabase.ref('users/user_123/gain_target')).called(1);
    });

    test('returns null when snapshot exists but value is null', () async {
      when(() => mockRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.value).thenReturn(null);

      final result = await dataSource.getGainTarget(userId: 'user_123');

      expect(result, isNull);
    });

    test('returns parsed GainTargetDto when valid map exists', () async {
      when(() => mockRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.value).thenReturn(<Object?, Object?>{
        'minWeeklyGainKg': 0.15,
        'maxWeeklyGainKg': 0.25,
      });

      final result = await dataSource.getGainTarget(userId: 'user_123');

      expect(result, isNotNull);
      expect(result!.minWeeklyGainKg, 0.15);
      expect(result.maxWeeklyGainKg, 0.25);
    });

    test('throws ServerException when data is malformed map', () async {
      when(() => mockRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.value).thenReturn(<Object?, Object?>{
        'minWeeklyGainKg': 'bad',
        'maxWeeklyGainKg': 0.25,
      });

      expect(
        () => dataSource.getGainTarget(userId: 'user_123'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            contains('Malformed target data in database'),
          ),
        ),
      );
    });

    test('throws ServerException when value is not a map', () async {
      when(() => mockRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.value).thenReturn('scalar string');

      expect(
        () => dataSource.getGainTarget(userId: 'user_123'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            contains('Malformed target data in database'),
          ),
        ),
      );
    });

    test('throws ServerException on TimeoutException', () async {
      when(
        () => mockRef.get(),
      ).thenThrow(TimeoutException('Timeout waiting for database response'));

      expect(
        () => dataSource.getGainTarget(userId: 'user_123'),
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
        () => dataSource.getGainTarget(userId: 'user_123'),
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
        () => dataSource.getGainTarget(userId: 'user_123'),
        throwsA(isA<NetworkException>()),
      );
    });

    test(
      'throws ServerException on generic FirebaseException or unknown crash',
      () async {
        when(() => mockRef.get()).thenThrow(
          FirebaseException(
            plugin: 'database',
            code: 'unknown',
            message: 'Server error',
          ),
        );

        expect(
          () => dataSource.getGainTarget(userId: 'user_123'),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('GainTargetRemoteDataSource.saveGainTarget', () {
    const dto = GainTargetDto(minWeeklyGainKg: 0.15, maxWeeklyGainKg: 0.25);

    test('saves DTO at users/user_123/gain_target and returns it', () async {
      when(() => mockRef.set(any())).thenAnswer((_) async {});

      final result = await dataSource.saveGainTarget(
        userId: 'user_123',
        dto: dto,
      );

      expect(result, equals(dto));
      verify(() => mockDatabase.ref('users/user_123/gain_target')).called(1);
      verify(() => mockRef.set(dto.toJson())).called(1);
    });

    test('does not return until set future completes', () async {
      final completer = Completer<void>();
      when(() => mockRef.set(any())).thenAnswer((_) => completer.future);

      var completed = false;
      final future = dataSource
          .saveGainTarget(userId: 'user_123', dto: dto)
          .then((res) {
            completed = true;
            return res;
          });

      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);

      completer.complete();
      final res = await future;
      expect(completed, isTrue);
      expect(res, equals(dto));
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
        () => dataSource.saveGainTarget(userId: 'user_123', dto: dto),
        throwsA(isA<AuthException>()),
      );
    });

    test('throws NetworkException on network error', () async {
      when(() => mockRef.set(any())).thenThrow(
        FirebaseException(
          plugin: 'database',
          code: 'network-request-failed',
          message: 'Offline',
        ),
      );

      expect(
        () => dataSource.saveGainTarget(userId: 'user_123', dto: dto),
        throwsA(isA<NetworkException>()),
      );
    });

    test('throws ServerException on other crash', () async {
      when(() => mockRef.set(any())).thenThrow(Exception('Crash'));

      expect(
        () => dataSource.saveGainTarget(userId: 'user_123', dto: dto),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
