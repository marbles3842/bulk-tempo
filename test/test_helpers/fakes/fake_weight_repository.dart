import 'dart:async';

import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/result/result.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';
import 'package:bulk_tempo/features/weight/domain/repositories/weight_repository.dart';

/// In-memory fake implementation of [WeightRepository] isolating data per [userId].
class FakeWeightRepository implements WeightRepository {
  /// Map of `userId` -> (`dateIso` -> `WeightEntryEntity`).
  final Map<String, Map<String, WeightEntryEntity>> _userEntries = {};

  AppFailure? nextFailure;
  AppFailure? getFailure;
  AppFailure? saveFailure;
  AppFailure? deleteFailure;

  /// Controlled completers to pause and resume operations deterministically in tests.
  Completer<void>? getCompleter;
  Completer<void>? saveCompleter;
  Completer<void>? deleteCompleter;

  /// Optional callbacks invoked when respective operations are called.
  Future<void> Function()? onGetWeightEntries;
  Future<void> Function()? onSaveWeightEntry;
  Future<void> Function()? onDeleteWeightEntry;

  @override
  Future<Result<List<WeightEntryEntity>, AppFailure>> getWeightEntries({
    required String userId,
  }) async {
    if (onGetWeightEntries != null) {
      await onGetWeightEntries!();
    }
    if (getCompleter != null) {
      await getCompleter!.future;
    }

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
    if (onSaveWeightEntry != null) {
      await onSaveWeightEntry!();
    }
    if (saveCompleter != null) {
      await saveCompleter!.future;
    }

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

  @override
  Future<Result<void, AppFailure>> deleteWeightEntry({
    required String userId,
    required String dateIso,
  }) async {
    if (onDeleteWeightEntry != null) {
      await onDeleteWeightEntry!();
    }
    if (deleteCompleter != null) {
      await deleteCompleter!.future;
    }

    if (userId.trim().isEmpty) {
      return const Result.failure(ValidationFailure('User ID cannot be empty'));
    }
    if (dateIso != dateIso.trim() ||
        WeekDateUtils.tryParseIsoDate(dateIso) == null) {
      return const Result.failure(ValidationFailure('Invalid date format'));
    }

    final failure = nextFailure ?? deleteFailure;
    if (failure != null) {
      nextFailure = null;
      return Result.failure(failure);
    }

    _userEntries[userId]?.remove(dateIso);
    return const Result.success(null);
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

  /// Clears all entries, pending failures, and controlled completers.
  void reset() {
    _userEntries.clear();
    nextFailure = null;
    getFailure = null;
    saveFailure = null;
    deleteFailure = null;
    getCompleter = null;
    saveCompleter = null;
    deleteCompleter = null;
    onGetWeightEntries = null;
    onSaveWeightEntry = null;
    onDeleteWeightEntry = null;
  }
}
