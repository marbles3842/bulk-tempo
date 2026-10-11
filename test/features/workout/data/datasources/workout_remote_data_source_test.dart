import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/features/workout/data/datasources/workout_remote_data_source.dart';

import '../../../../test_helpers/mocks.dart';

void main() {
  late MockHttpClient mockHttpClient;
  late WorkoutRemoteDataSourceImpl dataSource;

  const validKey = 'f4352809-838a-4e2c-98bb-922f1f14e552';

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://api.hevyapp.com/v1/workouts'));
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    dataSource = WorkoutRemoteDataSourceImpl(mockHttpClient);
  });

  group('WorkoutRemoteDataSourceImpl.fetchWorkoutCount', () {
    test('sends GET /v1/workouts/count with api-key header and returns workout_count', () async {
      final expectedUri = Uri.parse(
        'https://api.hevyapp.com/v1/workouts/count',
      );

      when(
        () => mockHttpClient.get(
          expectedUri,
          headers: <String, String>{
            'api-key': validKey,
            'accept': 'application/json',
          },
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode(<String, dynamic>{'workout_count': 42}),
          200,
        ),
      );

      final count = await dataSource.fetchWorkoutCount(apiKey: validKey);
      expect(count, 42);
    });

    for (final statusCode in [401, 403]) {
      test('throws AuthException on HTTP $statusCode', () async {
        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => http.Response('Unauthorized', statusCode));

        expect(
          () => dataSource.fetchWorkoutCount(apiKey: validKey),
          throwsA(
            isA<AuthException>().having(
              (e) => e.code,
              'code',
              'invalid-api-key',
            ),
          ),
        );
      });
    }

    for (final statusCode in [400, 500]) {
      test('throws ServerException on HTTP $statusCode', () async {
        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => http.Response('Server Error', statusCode));

        expect(
          () => dataSource.fetchWorkoutCount(apiKey: validKey),
          throwsA(
            isA<ServerException>().having(
              (e) => e.statusCode,
              'statusCode',
              statusCode,
            ),
          ),
        );
      });
    }

    test('throws NetworkException on ClientException', () async {
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(http.ClientException('Connection reset'));

      expect(
        () => dataSource.fetchWorkoutCount(apiKey: validKey),
        throwsA(isA<NetworkException>()),
      );
    });

    test('throws NetworkException on timeout', () async {
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
            (_) => Future<http.Response>.error(TimeoutException('timeout')),
          );

      expect(
        () => dataSource.fetchWorkoutCount(apiKey: validKey),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.message,
            'message',
            contains('timed out'),
          ),
        ),
      );
    });
  });

  group('WorkoutRemoteDataSourceImpl.fetchWorkoutsPage', () {
    test('sends GET /v1/workouts?page=2&pageSize=10 with api-key header and parses response', () async {
      final expectedUri = Uri.parse(
        'https://api.hevyapp.com/v1/workouts?page=2&pageSize=10',
      );

      final body = jsonEncode(<String, dynamic>{
        'page': 2,
        'page_count': 4,
        'workouts': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'w_1',
            'title': 'Leg Day',
            'start_time': '2026-10-05T10:00:00Z',
            'end_time': '2026-10-05T11:00:00Z',
            'exercises': <Map<String, dynamic>>[],
          },
        ],
      });

      when(
        () => mockHttpClient.get(
          expectedUri,
          headers: <String, String>{
            'api-key': validKey,
            'accept': 'application/json',
          },
        ),
      ).thenAnswer((_) async => http.Response(body, 200));

      final result = await dataSource.fetchWorkoutsPage(
        apiKey: validKey,
        page: 2,
        pageSize: 10,
      );

      expect(result.page, 2);
      expect(result.pageCount, 4);
      expect(result.workouts.length, 1);
      expect(result.workouts.first.id, 'w_1');
      expect(result.workouts.first.title, 'Leg Day');
    });

    test(
      'throws AuthException on HTTP 401 and ServerException on 500',
      () async {
        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => http.Response('Unauthorized', 401));

        await expectLater(
          () => dataSource.fetchWorkoutsPage(apiKey: validKey, page: 1),
          throwsA(isA<AuthException>()),
        );

        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => http.Response('Error', 500));

        await expectLater(
          () => dataSource.fetchWorkoutsPage(apiKey: validKey, page: 1),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });
}
