import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/result/result.dart';
import 'package:bulk_tempo/features/gain_target/data/datasources/gain_target_remote_data_source.dart';
import 'package:bulk_tempo/features/gain_target/data/models/gain_target_dto.dart';
import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';
import 'package:bulk_tempo/features/gain_target/domain/repositories/gain_target_repository.dart';
import 'package:bulk_tempo/features/gain_target/domain/validation/gain_target_validator.dart';

final gainTargetRepositoryProvider = Provider<GainTargetRepository>((ref) {
  final remoteDataSource = ref.watch(gainTargetRemoteDataSourceProvider);
  return GainTargetRepositoryImpl(remoteDataSource);
});

class GainTargetRepositoryImpl implements GainTargetRepository {
  final GainTargetRemoteDataSource _remoteDataSource;

  GainTargetRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<GainTargetEntity?, AppFailure>> getGainTarget({
    required String userId,
  }) async {
    if (userId.trim().isEmpty) {
      return const Result.failure(ValidationFailure('User ID cannot be empty'));
    }

    try {
      final dto = await _remoteDataSource.getGainTarget(userId: userId);
      if (dto == null) {
        return const Result.success(null);
      }
      return Result.success(dto.toEntity());
    } on AuthException catch (e) {
      return Result.failure(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Result.failure(
        NetworkFailure(
          e.message.isNotEmpty
              ? e.message
              : 'Network error. Please check your connection.',
        ),
      );
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on AppException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(
        UnknownFailure('An unexpected error occurred. Please try again.'),
      );
    }
  }

  @override
  Future<Result<GainTargetEntity, AppFailure>> saveGainTarget({
    required String userId,
    required GainTargetEntity target,
  }) async {
    if (userId.trim().isEmpty) {
      return const Result.failure(ValidationFailure('User ID cannot be empty'));
    }

    final validationError = GainTargetValidator.validateTarget(target);
    if (validationError != null) {
      return Result.failure(ValidationFailure(validationError));
    }

    try {
      final dto = GainTargetDto.fromEntity(target);
      final savedDto = await _remoteDataSource.saveGainTarget(
        userId: userId,
        dto: dto,
      );
      return Result.success(savedDto.toEntity());
    } on AuthException catch (e) {
      return Result.failure(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Result.failure(
        NetworkFailure(
          e.message.isNotEmpty
              ? e.message
              : 'Network error. Please check your connection.',
        ),
      );
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on AppException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (_) {
      return const Result.failure(
        UnknownFailure('An unexpected error occurred. Please try again.'),
      );
    }
  }
}
