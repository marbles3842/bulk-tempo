import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/result/result.dart';
import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';

/// Domain repository boundary for reading and persisting user-scoped weekly gain targets.
abstract class GainTargetRepository {
  /// Fetches the configured weekly gain target for [userId].
  ///
  /// Returns `null` wrapped in [Success] if no target has been set.
  Future<Result<GainTargetEntity?, AppFailure>> getGainTarget({
    required String userId,
  });

  /// Saves or replaces the weekly gain target for [userId].
  ///
  /// Requires server acknowledgement to succeed.
  Future<Result<GainTargetEntity, AppFailure>> saveGainTarget({
    required String userId,
    required GainTargetEntity target,
  });
}
