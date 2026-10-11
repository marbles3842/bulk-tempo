import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:bulk_tempo/core/constants/hevy_api_constants.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/features/workout/data/models/workout_dto.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final workoutRemoteDataSourceProvider = Provider<WorkoutRemoteDataSource>((
  ref,
) {
  final client = ref.watch(httpClientProvider);
  return WorkoutRemoteDataSourceImpl(client);
});

abstract class WorkoutRemoteDataSource {
  Future<int> fetchWorkoutCount({required String apiKey});
  Future<PaginatedWorkoutsResponseDto> fetchWorkoutsPage({
    required String apiKey,
    required int page,
    int pageSize = HevyApiConstants.pageSize,
  });
}

class WorkoutRemoteDataSourceImpl implements WorkoutRemoteDataSource {
  final http.Client _client;

  WorkoutRemoteDataSourceImpl(this._client);

  Map<String, String> _buildHeaders(String apiKey) {
    return <String, String>{
      HevyApiConstants.apiKeyHeader: apiKey,
      'accept': 'application/json',
    };
  }

  static const Duration requestTimeout = Duration(seconds: 15);

  @override
  Future<int> fetchWorkoutCount({required String apiKey}) async {
    final uri = Uri.parse(
      '${HevyApiConstants.baseUrl}${HevyApiConstants.workoutsCountPath}',
    );
    try {
      final response = await _client
          .get(uri, headers: _buildHeaders(apiKey))
          .timeout(requestTimeout);
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const AuthException(
          'invalid-api-key',
          'Invalid or unauthorized Hevy API key',
        );
      }
      if (response.statusCode != 200) {
        throw ServerException(
          message:
              'Failed to fetch workout count (HTTP ${response.statusCode})',
          statusCode: response.statusCode,
        );
      }

      final Object? decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const ServerException(
          message: 'Invalid workout count response format',
        );
      }
      final rawCount = decoded['workout_count'];
      if (rawCount is! num) {
        throw const ServerException(
          message: 'Missing workout_count in response',
        );
      }
      return rawCount.toInt();
    } on AppException {
      rethrow;
    } on TimeoutException {
      throw const NetworkException(
        'Request timed out. Please check your connection.',
      );
    } on FormatException catch (e) {
      throw ServerException(message: 'Invalid JSON response: ${e.message}');
    } on http.ClientException catch (e) {
      throw NetworkException(e.message);
    } catch (e) {
      if (_isNetworkError(e)) {
        throw NetworkException(e.toString());
      }
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<PaginatedWorkoutsResponseDto> fetchWorkoutsPage({
    required String apiKey,
    required int page,
    int pageSize = HevyApiConstants.pageSize,
  }) async {
    final uri = Uri.parse(
      '${HevyApiConstants.baseUrl}${HevyApiConstants.workoutsPath}?page=$page&pageSize=$pageSize',
    );
    try {
      final response = await _client
          .get(uri, headers: _buildHeaders(apiKey))
          .timeout(requestTimeout);
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const AuthException(
          'invalid-api-key',
          'Invalid or unauthorized Hevy API key',
        );
      }
      if (response.statusCode != 200) {
        throw ServerException(
          message:
              'Failed to fetch workouts page $page (HTTP ${response.statusCode})',
          statusCode: response.statusCode,
        );
      }

      final Object? decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const ServerException(
          message: 'Invalid workouts page response format',
        );
      }
      return PaginatedWorkoutsResponseDto.fromJson(decoded);
    } on AppException {
      rethrow;
    } on TimeoutException {
      throw const NetworkException(
        'Request timed out. Please check your connection.',
      );
    } on FormatException catch (e) {
      throw ServerException(message: 'Invalid JSON response: ${e.message}');
    } on http.ClientException catch (e) {
      throw NetworkException(e.message);
    } catch (e) {
      if (_isNetworkError(e)) {
        throw NetworkException(e.toString());
      }
      throw ServerException(message: e.toString());
    }
  }

  bool _isNetworkError(Object error) {
    final typeName = error.runtimeType.toString();
    final lower = error.toString().toLowerCase();
    return typeName == 'SocketException' ||
        typeName == 'HandshakeException' ||
        lower.contains('socketexception') ||
        lower.contains('network') ||
        lower.contains('connection refused') ||
        lower.contains('failed host lookup');
  }
}
