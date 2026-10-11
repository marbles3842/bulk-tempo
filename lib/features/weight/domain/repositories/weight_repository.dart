import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/result/result.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';

/// Domain repository boundary for reading and persisting user-scoped weight measurements.
abstract class WeightRepository {
  /// Fetches all logged weight entries for [userId], ordered newest date first.
  Future<Result<List<WeightEntryEntity>, AppFailure>> getWeightEntries({
    required String userId,
  });

  /// Saves or overwrites a single daily weight entry for [userId].
  Future<Result<WeightEntryEntity, AppFailure>> saveWeightEntry({
    required String userId,
    required WeightEntryEntity entry,
  });

  /// Deletes one daily entry for [userId], succeeding if it is already absent.
  /// [dateIso] must be a valid canonical `YYYY-MM-DD` date, of any age.
  Future<Result<void, AppFailure>> deleteWeightEntry({
    required String userId,
    required String dateIso,
  });
}
