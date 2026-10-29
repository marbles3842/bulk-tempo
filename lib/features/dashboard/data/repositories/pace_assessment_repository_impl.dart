import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/providers/clock_provider.dart';
import 'package:bulk_tempo/core/result/result.dart';
import 'package:bulk_tempo/features/dashboard/data/datasources/pace_assessment_ai_data_source.dart';
import 'package:bulk_tempo/features/dashboard/data/datasources/pace_assessment_cache_data_source.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/pace_assessment_entity.dart';
import 'package:bulk_tempo/features/dashboard/domain/repositories/pace_assessment_repository.dart';

final paceAssessmentRepositoryProvider = Provider<PaceAssessmentRepository>((
  ref,
) {
  final cacheDataSource = ref.watch(paceAssessmentCacheDataSourceProvider);
  final aiDataSource = ref.watch(paceAssessmentAiDataSourceProvider);
  final clock = ref.watch(clockProvider);
  return PaceAssessmentRepositoryImpl(
    cacheDataSource: cacheDataSource,
    aiDataSource: aiDataSource,
    clock: clock,
  );
});

class PaceAssessmentRepositoryImpl implements PaceAssessmentRepository {
  final PaceAssessmentCacheDataSource _cacheDataSource;
  final PaceAssessmentAiDataSource _aiDataSource;
  final DateTime Function() _clock;

  PaceAssessmentRepositoryImpl({
    required PaceAssessmentCacheDataSource cacheDataSource,
    required PaceAssessmentAiDataSource aiDataSource,
    DateTime Function()? clock,
  }) : _cacheDataSource = cacheDataSource,
       _aiDataSource = aiDataSource,
       _clock = clock ?? DateTime.now;

  @override
  Future<Result<PaceAssessmentEntity, AppFailure>> getOrGenerateAssessment({
    required String userId,
    required PaceAssessmentInputEntity input,
    bool forceRefresh = false,
  }) async {
    if (userId.trim().isEmpty) {
      return const Result.failure(ValidationFailure('User ID cannot be empty'));
    }

    try {
      if (!forceRefresh) {
        final cachedDto = await _cacheDataSource.getCachedAssessment(
          userId: userId,
        );
        if (cachedDto != null && cachedDto.fingerprint == input.fingerprint) {
          return Result.success(cachedDto.toEntity());
        }
      }

      final generatedDto = await _aiDataSource.generateAssessment(
        input: input,
        now: _clock(),
      );
      final entity = generatedDto.toEntity();

      try {
        await _cacheDataSource.saveCachedAssessment(
          userId: userId,
          dto: generatedDto,
        );
      } catch (_) {
        // Cache-write failures are non-fatal if AI generation succeeded.
      }

      return Result.success(entity);
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
