import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/result/result.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/core/utils/weight_validators.dart';
import 'package:bulk_tempo/features/weight/data/datasources/weight_remote_data_source.dart';
import 'package:bulk_tempo/features/weight/data/models/weight_entry_dto.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';
import 'package:bulk_tempo/features/weight/domain/repositories/weight_repository.dart';

final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  final remoteDataSource = ref.watch(weightRemoteDataSourceProvider);
  return WeightRepositoryImpl(remoteDataSource);
});

class WeightRepositoryImpl implements WeightRepository {
  final WeightRemoteDataSource _remoteDataSource;

  WeightRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<List<WeightEntryEntity>, AppFailure>> getWeightEntries({
    required String userId,
  }) async {
    if (userId.trim().isEmpty) {
      return const Result.failure(ValidationFailure('User ID cannot be empty'));
    }

    try {
      final dtos = await _remoteDataSource.getWeightEntries(userId: userId);
      final entities = dtos.map((dto) => dto.toEntity()).toList();
      return Result.success(entities);
    } on AuthException catch (e) {
      return Result.failure(AuthFailure(e.message));
    } on NetworkException {
      return const Result.failure(
        NetworkFailure('Network error. Please check your connection.'),
      );
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (_) {
      return const Result.failure(
        UnknownFailure('An unexpected error occurred. Please try again.'),
      );
    }
  }

  @override
  Future<Result<WeightEntryEntity, AppFailure>> saveWeightEntry({
    required String userId,
    required WeightEntryEntity entry,
  }) async {
    if (userId.trim().isEmpty) {
      return const Result.failure(ValidationFailure('User ID cannot be empty'));
    }

    if (entry.weightKg < WeightValidators.minWeightKg ||
        entry.weightKg > WeightValidators.maxWeightKg) {
      return Result.failure(
        ValidationFailure(
          'Weight must be between ${WeightValidators.minWeightKg.toStringAsFixed(1)} and ${WeightValidators.maxWeightKg.toStringAsFixed(1)} kg',
        ),
      );
    }

    if (WeekDateUtils.tryParseIsoDate(entry.dateIso) == null) {
      return const Result.failure(ValidationFailure('Invalid date format'));
    }

    try {
      final dto = WeightEntryDto.fromEntity(entry);
      final savedDto = await _remoteDataSource.saveWeightEntry(
        userId: userId,
        dto: dto,
      );
      return Result.success(savedDto.toEntity());
    } on AuthException catch (e) {
      return Result.failure(AuthFailure(e.message));
    } on NetworkException {
      return const Result.failure(
        NetworkFailure('Network error. Please check your connection.'),
      );
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (_) {
      return const Result.failure(
        UnknownFailure('An unexpected error occurred. Please try again.'),
      );
    }
  }

  @override
  Future<Result<void, AppFailure>> deleteWeightEntry({
    required String userId,
    required String dateIso,
  }) async {
    if (userId.trim().isEmpty) {
      return const Result.failure(ValidationFailure('User ID cannot be empty'));
    }

    if (dateIso != dateIso.trim() ||
        WeekDateUtils.tryParseIsoDate(dateIso) == null) {
      return const Result.failure(ValidationFailure('Invalid date format'));
    }

    try {
      await _remoteDataSource.deleteWeightEntry(
        userId: userId,
        dateIso: dateIso,
      );
      return const Result.success(null);
    } on AuthException catch (e) {
      return Result.failure(AuthFailure(e.message));
    } on NetworkException {
      return const Result.failure(
        NetworkFailure('Network error. Please check your connection.'),
      );
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (_) {
      return const Result.failure(
        UnknownFailure('An unexpected error occurred. Please try again.'),
      );
    }
  }
}
