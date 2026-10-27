import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/core/providers/firebase_database_provider.dart';
import 'package:bulk_tempo/features/dashboard/data/models/pace_assessment_dto.dart';

final paceAssessmentCacheDataSourceProvider =
    Provider<PaceAssessmentCacheDataSource>((ref) {
      final database = ref.watch(firebaseDatabaseProvider);
      return PaceAssessmentCacheDataSourceImpl(database);
    });

abstract class PaceAssessmentCacheDataSource {
  Future<PaceAssessmentDto?> getCachedAssessment({required String userId});

  Future<void> saveCachedAssessment({
    required String userId,
    required PaceAssessmentDto dto,
  });
}

class PaceAssessmentCacheDataSourceImpl
    implements PaceAssessmentCacheDataSource {
  final FirebaseDatabase _database;

  PaceAssessmentCacheDataSourceImpl(this._database);

  @override
  Future<PaceAssessmentDto?> getCachedAssessment({
    required String userId,
  }) async {
    try {
      final snapshot = await _database
          .ref('users/$userId/pace_assessment')
          .get()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw const ServerException(message: 'Request timed out'),
          );

      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }

      final rawValue = snapshot.value;
      if (rawValue is Map) {
        try {
          return PaceAssessmentDto.fromRtdbMap(
            Map<Object?, Object?>.from(rawValue),
          );
        } on FormatException {
          // Return null if cached data is malformed so a fresh Gemini call can heal the cache.
          return null;
        }
      }

      // Return null if cached data is not a map so a fresh Gemini call can heal the cache.
      return null;
    } on TimeoutException {
      throw const ServerException(message: 'Request timed out');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw AuthException(e.code, e.message ?? 'Permission denied');
      }
      if (e.code == 'network-error' ||
          e.code == 'network-request-failed' ||
          e.code == 'unavailable' ||
          e.code == 'disconnected') {
        throw NetworkException(e.message ?? 'Network error occurred');
      }
      throw ServerException(message: e.message ?? 'Database error occurred');
    } on AppException {
      rethrow;
    } catch (e) {
      if (e.runtimeType.toString() == 'SocketException' ||
          e.toString().toLowerCase().contains('socketexception') ||
          e.toString().toLowerCase().contains('network')) {
        throw NetworkException(e.toString());
      }
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> saveCachedAssessment({
    required String userId,
    required PaceAssessmentDto dto,
  }) async {
    try {
      await _database
          .ref('users/$userId/pace_assessment')
          .set(dto.toJson())
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw const ServerException(message: 'Request timed out'),
          );
    } on TimeoutException {
      throw const ServerException(message: 'Request timed out');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw AuthException(e.code, e.message ?? 'Permission denied');
      }
      if (e.code == 'network-error' ||
          e.code == 'network-request-failed' ||
          e.code == 'unavailable' ||
          e.code == 'disconnected') {
        throw NetworkException(e.message ?? 'Network error occurred');
      }
      throw ServerException(message: e.message ?? 'Database error occurred');
    } on AppException {
      rethrow;
    } catch (e) {
      if (e.runtimeType.toString() == 'SocketException' ||
          e.toString().toLowerCase().contains('socketexception') ||
          e.toString().toLowerCase().contains('network')) {
        throw NetworkException(e.toString());
      }
      throw ServerException(message: e.toString());
    }
  }
}
