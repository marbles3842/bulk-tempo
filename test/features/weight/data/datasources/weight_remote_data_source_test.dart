import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/features/weight/data/datasources/weight_remote_data_source.dart';
import 'package:bulk_tempo/features/weight/data/models/weight_entry_dto.dart';

import 'package:bulk_tempo/features/weight/domain/models/weekly_weight_summary_entity.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_history_state.dart';

import '../../../../test_helpers/mocks.dart';

void main() {
  late MockFirebaseDatabase mockDatabase;
  late MockDatabaseReference mockRef;
  late MockDataSnapshot mockSnapshot;
  late WeightRemoteDataSource dataSource;

  setUp(() {
    mockDatabase = MockFirebaseDatabase();
    mockRef = MockDatabaseReference();
    mockSnapshot = MockDataSnapshot();
    dataSource = WeightRemoteDataSourceImpl(mockDatabase);

    when(() => mockDatabase.ref(any())).thenReturn(mockRef);
  });

  group('WeightRemoteDataSource.getWeightEntries', () {
    test(
      'returns empty list when snapshot does not exist or value is null',
      () async {
        when(() => mockRef.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(false);
        when(() => mockSnapshot.value).thenReturn(null);

        final result = await dataSource.getWeightEntries(userId: 'user_123');

        expect(result, isEmpty);
        verify(() => mockDatabase.ref('users/user_123/weight_entries'))
            .called(1);
      },
    );

    test('returns entries sorted descending by date', () async {
      when(() => mockRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.value).thenReturn(<Object?, Object?>{
        '2026-10-01': <Object?, Object?>{
          'date': '2026-10-01',
          'weightKg': 80.0,
          'updatedAt': '2026-10-01T12:00:00.000Z',
        },
        '2026-10-05': <Object?, Object?>{
          'date': '2026-10-05',
          'weightKg': 81.0,
          'updatedAt': '2026-10-05T12:00:00.000Z',
        },
      });

      final result = await dataSource.getWeightEntries(userId: 'user_123');

      expect(result.length, 2);
      expect(result[0].date, '2026-10-05');
      expect(result[0].weightKg, 81.0);
      expect(result[1].date, '2026-10-01');
      expect(result[1].weightKg, 80.0);
    });

    for (final useList in [false, true]) {
      test(
        'skips malformed records in ${useList ? 'list' : 'map'} snapshots',
        () async {
          final records = <String, Object?>{
            '2026-10-05': {'date': '2026-10-05', 'weightKg': 80},
            '2026-10-06': {'date': '2026-10-06', 'weightKg': 82},
            '2026-10-07': {'date': '2026-10-07', 'weightKg': 'bad'},
            '2026-10-08': {'date': '', 'weightKg': 90},
            '2026-10-09': {'date': 'invalid', 'weightKg': 90},
            '2026-10-10': {'date': '2026-10-10', 'weightKg': double.nan},
            'bad-key': {'weightKg': 90},
            '2026-10-11': {'date': 123, 'weightKg': 90},
            'other': null,
          };
          when(() => mockRef.get()).thenAnswer((_) async => mockSnapshot);
          when(() => mockSnapshot.exists).thenReturn(true);
          when(() => mockSnapshot.value)
              .thenReturn(useList ? records.values.toList() : records);

          final dtos = await dataSource.getWeightEntries(userId: 'user_123');
          expect(dtos.map((dto) => dto.date), ['2026-10-06', '2026-10-05']);
          final entries = dtos.map((dto) => dto.toEntity()).toList();
          final summaries = WeeklyWeightSummaryEntity.groupEntriesByIsoWeek(
            entries,
          );
          expect(summaries.single.averageWeightKg, 81);
          expect(summaries.single.entries.length, 2);
          final history = WeightHistoryLoaded(
            entries: entries,
            weeklySummaries: summaries,
            chartSummaries: summaries,
          );
          expect(history.hasEntryForDate('2026-10-07'), isFalse);
          expect(history.hasEntryForDate('2026-10-08'), isFalse);
          expect(history.hasEntryForDate('2026-10-06'), isTrue);
        },
      );
    }

    test('uses a valid map key when a record has no date', () async {
      when(() => mockRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.value).thenReturn({
        '2026-10-10': {'weightKg': '80.5'},
      });
      final entries = await dataSource.getWeightEntries(userId: 'user_123');
      expect(entries.single.date, '2026-10-10');
      expect(entries.single.weightKg, 80.5);
    });

    test('throws AuthException when permission-denied occurs', () async {
      when(() => mockRef.get()).thenThrow(
        FirebaseException(
          plugin: 'database',
          code: 'permission-denied',
          message: 'Permission denied',
        ),
      );

      expect(
        () => dataSource.getWeightEntries(userId: 'user_123'),
        throwsA(isA<AuthException>()),
      );
    });

    test('throws NetworkException when network-error occurs', () async {
      when(() => mockRef.get()).thenThrow(
        FirebaseException(
          plugin: 'database',
          code: 'network-error',
          message: 'Network offline',
        ),
      );

      expect(
        () => dataSource.getWeightEntries(userId: 'user_123'),
        throwsA(isA<NetworkException>()),
      );
    });

    test(
      'throws ServerException for generic FirebaseException or unknown errors',
      () async {
        when(() => mockRef.get()).thenThrow(
          FirebaseException(
            plugin: 'database',
            code: 'unknown',
            message: 'Unknown DB error',
          ),
        );

        expect(
          () => dataSource.getWeightEntries(userId: 'user_123'),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('WeightRemoteDataSource.saveWeightEntry', () {
    const dto = WeightEntryDto(
      date: '2026-10-10',
      weightKg: 82.5,
      updatedAt: '2026-10-10T12:00:00.000Z',
    );

    test('saves DTO and returns it on success', () async {
      when(() => mockRef.set(any())).thenAnswer((_) async {});

      final result = await dataSource.saveWeightEntry(
        userId: 'user_123',
        dto: dto,
      );

      expect(result, equals(dto));
      verify(() => mockDatabase.ref('users/user_123/weight_entries/2026-10-10'))
          .called(1);
      verify(() => mockRef.set(dto.toJson())).called(1);
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
        () => dataSource.saveWeightEntry(userId: 'user_123', dto: dto),
        throwsA(isA<AuthException>()),
      );
    });

    test('throws NetworkException on network-error', () async {
      when(() => mockRef.set(any())).thenThrow(
        FirebaseException(
          plugin: 'database',
          code: 'network-request-failed',
          message: 'Connection failed',
        ),
      );

      expect(
        () => dataSource.saveWeightEntry(userId: 'user_123', dto: dto),
        throwsA(isA<NetworkException>()),
      );
    });

    test('throws ServerException on other error', () async {
      when(() => mockRef.set(any())).thenThrow(Exception('Unexpected crash'));

      expect(
        () => dataSource.saveWeightEntry(userId: 'user_123', dto: dto),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
