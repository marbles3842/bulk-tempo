import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/features/weight/data/models/weight_entry_dto.dart';

final firebaseDatabaseProvider = Provider<FirebaseDatabase>((ref) {
  return FirebaseDatabase.instance;
});

final weightRemoteDataSourceProvider = Provider<WeightRemoteDataSource>((ref) {
  final database = ref.watch(firebaseDatabaseProvider);
  return WeightRemoteDataSourceImpl(database);
});

abstract class WeightRemoteDataSource {
  Future<void> deleteWeightEntry({
    required String userId,
    required String dateIso,
  });
  Future<List<WeightEntryDto>> getWeightEntries({required String userId});
  Future<WeightEntryDto> saveWeightEntry({
    required String userId,
    required WeightEntryDto dto,
  });
}

class WeightRemoteDataSourceImpl implements WeightRemoteDataSource {
  final FirebaseDatabase _database;

  WeightRemoteDataSourceImpl(this._database);

  @override
  Future<List<WeightEntryDto>> getWeightEntries({
    required String userId,
  }) async {
    try {
      final snapshot = await _database
          .ref('users/$userId/weight_entries')
          .get();
      if (!snapshot.exists || snapshot.value == null) {
        return <WeightEntryDto>[];
      }

      final rawValue = snapshot.value;
      final List<WeightEntryDto> entries = [];

      if (rawValue is Map) {
        for (final entry in rawValue.entries) {
          final keyDate = entry.key?.toString();
          final val = entry.value;
          if (val is Map) {
            try {
              entries.add(
                WeightEntryDto.fromJson(
                  Map<Object?, Object?>.from(val),
                  keyDate: keyDate,
                ),
              );
            } on FormatException {
              // Ignore malformed records before they reach history grouping.
            }
          }
        }
      } else if (rawValue is List) {
        for (final item in rawValue) {
          if (item is Map) {
            try {
              entries.add(
                WeightEntryDto.fromJson(Map<Object?, Object?>.from(item)),
              );
            } on FormatException {
              // Ignore malformed records before they reach history grouping.
            }
          }
        }
      }

      entries.sort((a, b) => b.date.compareTo(a.date));
      return entries;
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
  Future<WeightEntryDto> saveWeightEntry({
    required String userId,
    required WeightEntryDto dto,
  }) async {
    try {
      await _database
          .ref('users/$userId/weight_entries/${dto.date}')
          .set(dto.toJson());
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

  @override
  Future<void> deleteWeightEntry({
    required String userId,
    required String dateIso,
  }) async {
    try {
      await _database.ref('users/$userId/weight_entries/$dateIso').remove();
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
