import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/core/providers/firebase_database_provider.dart';
import 'package:bulk_tempo/features/gain_target/data/models/gain_target_dto.dart';

final gainTargetRemoteDataSourceProvider = Provider<GainTargetRemoteDataSource>(
  (ref) {
    final database = ref.watch(firebaseDatabaseProvider);
    return GainTargetRemoteDataSourceImpl(database);
  },
);

abstract class GainTargetRemoteDataSource {
  Future<GainTargetDto?> getGainTarget({required String userId});
  Future<GainTargetDto> saveGainTarget({
    required String userId,
    required GainTargetDto dto,
  });
}

class GainTargetRemoteDataSourceImpl implements GainTargetRemoteDataSource {
  final FirebaseDatabase _database;

  GainTargetRemoteDataSourceImpl(this._database);

  @override
  Future<GainTargetDto?> getGainTarget({required String userId}) async {
    try {
      final snapshot = await _database
          .ref('users/$userId/gain_target')
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
          return GainTargetDto.fromJson(Map<Object?, Object?>.from(rawValue));
        } on FormatException catch (e) {
          throw ServerException(
            message: 'Malformed target data in database: ${e.message}',
          );
        }
      }

      throw const ServerException(message: 'Malformed target data in database');
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
  Future<GainTargetDto> saveGainTarget({
    required String userId,
    required GainTargetDto dto,
  }) async {
    try {
      await _database.ref('users/$userId/gain_target').set(dto.toJson());
      return dto;
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
