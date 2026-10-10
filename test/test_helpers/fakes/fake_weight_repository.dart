import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/result/result.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';
import 'package:bulk_tempo/features/weight/domain/repositories/weight_repository.dart';

/// In-memory fake implementation of [WeightRepository] isolating data per [userId].
class FakeWeightRepository implements WeightRepository {
  /// Map of `userId` -> (`dateIso` -> `WeightEntryEntity`).
  final Map<String, Map<String, WeightEntryEntity>> _userEntries = {};

  AppFailure? nextFailure;
  AppFailure? getFailure;
  AppFailure? saveFailure;

  @override
  Future<Result<List<WeightEntryEntity>, AppFailure>> getWeightEntries({
    required String userId,
  }) async {
    final failure = nextFailure ?? getFailure;
    if (failure != null) {
      nextFailure = null;
      return Result.failure(failure);
    }

    final entriesMap = _userEntries[userId];
    if (entriesMap == null || entriesMap.isEmpty) {
      return const Result.success(<WeightEntryEntity>[]);
    }

    final entries = entriesMap.values.toList()
      ..sort((a, b) => b.dateIso.compareTo(a.dateIso));
    return Result.success(entries);
  }

  @override
  Future<Result<WeightEntryEntity, AppFailure>> saveWeightEntry({
    required String userId,
    required WeightEntryEntity entry,
  }) async {
    final failure = nextFailure ?? saveFailure;
    if (failure != null) {
      nextFailure = null;
      return Result.failure(failure);
    }

    final entriesMap = _userEntries.putIfAbsent(
      userId,
      () => <String, WeightEntryEntity>{},
    );
    entriesMap[entry.dateIso] = entry;
    return Result.success(entry);
  }

  /// Seeds initial [entries] for a specific [userId].
  void seedEntries(String userId, List<WeightEntryEntity> entries) {
    final map = _userEntries.putIfAbsent(
      userId,
      () => <String, WeightEntryEntity>{},
    );
    for (final entry in entries) {
      map[entry.dateIso] = entry;
    }
  }

  /// Returns current entries stored for [userId] (sorted newest date first).
  List<WeightEntryEntity> getEntriesForUser(String userId) {
    final entriesMap = _userEntries[userId];
    if (entriesMap == null) return <WeightEntryEntity>[];
    return entriesMap.values.toList()
      ..sort((a, b) => b.dateIso.compareTo(a.dateIso));
  }

  /// Clears all entries and pending failures.
  void reset() {
    _userEntries.clear();
    nextFailure = null;
    getFailure = null;
    saveFailure = null;
  }
}
