import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/result/result.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_entity.dart';

abstract class WorkoutRepository {
  Future<Result<String?, AppFailure>> getSavedApiKey({required String userId});
  Future<Result<void, AppFailure>> validateAndSaveApiKey({
    required String userId,
    required String apiKey,
  });
  Future<Result<void, AppFailure>> clearApiKey({required String userId});
  Future<Result<List<WorkoutEntity>, AppFailure>> getWorkoutsForLastWeeks({
    required String userId,
    int weeks = 12,
    DateTime? now,
  });
}
