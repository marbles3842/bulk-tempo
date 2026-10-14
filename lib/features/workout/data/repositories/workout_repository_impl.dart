import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/constants/hevy_api_constants.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/result/result.dart';
import 'package:bulk_tempo/core/utils/hevy_key_validators.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/workout/data/datasources/hevy_key_local_data_source.dart';
import 'package:bulk_tempo/features/workout/data/datasources/workout_remote_data_source.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_entity.dart';
import 'package:bulk_tempo/features/workout/domain/repositories/workout_repository.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final localDataSource = ref.watch(hevyKeyLocalDataSourceProvider);
  final remoteDataSource = ref.watch(workoutRemoteDataSourceProvider);
  return WorkoutRepositoryImpl(localDataSource, remoteDataSource);
});

class WorkoutRepositoryImpl implements WorkoutRepository {
  final HevyKeyLocalDataSource _localDataSource;
  final WorkoutRemoteDataSource _remoteDataSource;

  WorkoutRepositoryImpl(this._localDataSource, this._remoteDataSource);

  @override
  Future<Result<String?, AppFailure>> getSavedApiKey({
    required String userId,
  }) async {
    if (userId.trim().isEmpty) {
      return const Result.failure(ValidationFailure('User ID cannot be empty'));
    }

    try {
      final apiKey = await _localDataSource.readApiKey(userId: userId);
      if (apiKey == null || apiKey.trim().isEmpty) {
        return const Result.success(null);
      }
      return Result.success(apiKey.trim());
    } on CacheException catch (e) {
      return Result.failure(CacheFailure(e.message));
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
  Future<Result<void, AppFailure>> validateAndSaveApiKey({
    required String userId,
    required String apiKey,
  }) async {
    if (userId.trim().isEmpty) {
      return const Result.failure(ValidationFailure('User ID cannot be empty'));
    }

    final validationError = HevyKeyValidators.validateKeyInput(apiKey);
    if (validationError != null) {
      return Result.failure(ValidationFailure(validationError.name));
    }

    final normalizedKey = HevyKeyValidators.normalizeKey(apiKey);

    try {
      await _remoteDataSource.fetchWorkoutCount(apiKey: normalizedKey);
      await _localDataSource.writeApiKey(userId: userId, apiKey: normalizedKey);
      return const Result.success(null);
    } on AuthException catch (e) {
      return Result.failure(AuthFailure(e.message));
    } on NetworkException {
      return const Result.failure(
        NetworkFailure('Network error. Please check your connection.'),
      );
    } on CacheException catch (e) {
      return Result.failure(CacheFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (_) {
      return const Result.failure(
        UnknownFailure('An unexpected error occurred. Please try again.'),
      );
    }
  }

  @override
  Future<Result<void, AppFailure>> clearApiKey({required String userId}) async {
    if (userId.trim().isEmpty) {
      return const Result.failure(ValidationFailure('User ID cannot be empty'));
    }

    try {
      await _localDataSource.deleteApiKey(userId: userId);
      return const Result.success(null);
    } on CacheException catch (e) {
      return Result.failure(CacheFailure(e.message));
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
  Future<Result<List<WorkoutEntity>, AppFailure>> getWorkoutsForLastWeeks({
    required String userId,
    int weeks = HevyApiConstants.lookbackWeeks,
    DateTime? now,
  }) async {
    if (userId.trim().isEmpty) {
      return const Result.failure(ValidationFailure('User ID cannot be empty'));
    }
    if (weeks < 1) {
      return const Result.failure(
        ValidationFailure('Weeks must be at least 1'),
      );
    }

    try {
      final apiKey = await _localDataSource.readApiKey(userId: userId);
      if (apiKey == null || apiKey.trim().isEmpty) {
        return const Result.failure(
          AuthFailure('Hevy API key is not configured'),
        );
      }

      final referenceLocal = (now ?? DateTime.now()).toLocal();
      final todayUtc = DateTime.utc(
        referenceLocal.year,
        referenceLocal.month,
        referenceLocal.day,
      );
      final currentWeekMonday = WeekDateUtils.startOfIsoWeekUtc(todayUtc);
      final cutoffMonday = currentWeekMonday.subtract(
        Duration(days: (weeks - 1) * 7),
      );

      final List<WorkoutEntity> collected = [];
      int currentPage = 1;
      while (currentPage <= HevyApiConstants.maxPages) {
        final pageDto = await _remoteDataSource.fetchWorkoutsPage(
          apiKey: apiKey,
          page: currentPage,
          pageSize: HevyApiConstants.pageSize,
        );
        if (pageDto.workouts.isEmpty) break;

        bool reachedCutoff = false;
        for (final dto in pageDto.workouts) {
          final entity = dto.toEntity();
          if (entity.localDate.isBefore(cutoffMonday)) {
            reachedCutoff = true;
          } else {
            collected.add(entity);
          }
        }
        if (reachedCutoff || currentPage >= pageDto.pageCount) break;
        currentPage++;
      }

      final Map<String, WorkoutEntity> deduped = {};
      for (final workout in collected) {
        final existing = deduped[workout.id];
        if (existing == null ||
            !workout.startTime.isBefore(existing.startTime)) {
          deduped[workout.id] = workout;
        }
      }

      final sorted = deduped.values.toList();
      sorted.sort((a, b) => b.startTime.compareTo(a.startTime));

      return Result.success(List.unmodifiable(sorted));
    } on AuthException catch (e) {
      return Result.failure(AuthFailure(e.message));
    } on NetworkException {
      return const Result.failure(
        NetworkFailure('Network error. Please check your connection.'),
      );
    } on CacheException catch (e) {
      return Result.failure(CacheFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, statusCode: e.statusCode));
    } on FormatException catch (e) {
      return Result.failure(
        ServerFailure('Invalid workout data: ${e.message}'),
      );
    } catch (_) {
      return const Result.failure(
        UnknownFailure('An unexpected error occurred. Please try again.'),
      );
    }
  }
}
