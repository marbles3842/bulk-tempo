import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/result/result.dart';
import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';
import 'package:bulk_tempo/features/gain_target/domain/repositories/gain_target_repository.dart';

/// In-memory fake implementation of [GainTargetRepository] isolating targets per [userId].
class FakeGainTargetRepository implements GainTargetRepository {
  /// Map of `userId` -> `GainTargetEntity?`.
  final Map<String, GainTargetEntity?> _userTargets = {};

  AppFailure? nextFailure;
  AppFailure? getFailure;
  AppFailure? saveFailure;

  @override
  Future<Result<GainTargetEntity?, AppFailure>> getGainTarget({
    required String userId,
  }) async {
    final failure = nextFailure ?? getFailure;
    if (failure != null) {
      nextFailure = null;
      return Result.failure(failure);
    }

    final target = _userTargets[userId];
    return Result.success(target);
  }

  @override
  Future<Result<GainTargetEntity, AppFailure>> saveGainTarget({
    required String userId,
    required GainTargetEntity target,
  }) async {
    final failure = nextFailure ?? saveFailure;
    if (failure != null) {
      nextFailure = null;
      return Result.failure(failure);
    }

    _userTargets[userId] = target;
    return Result.success(target);
  }

  /// Seeds initial [target] for a specific [userId].
  void seedTarget(String userId, GainTargetEntity? target) {
    _userTargets[userId] = target;
  }

  /// Returns current target stored for [userId].
  GainTargetEntity? getTargetForUser(String userId) {
    return _userTargets[userId];
  }

  /// Clears all targets and pending failures.
  void reset() {
    _userTargets.clear();
    nextFailure = null;
    getFailure = null;
    saveFailure = null;
  }
}
