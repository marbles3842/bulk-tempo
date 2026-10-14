import 'dart:async';

import 'package:bulk_tempo/core/constants/hevy_api_constants.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/result/result.dart';
import 'package:bulk_tempo/core/utils/hevy_key_validators.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_entity.dart';
import 'package:bulk_tempo/features/workout/domain/repositories/workout_repository.dart';

/// In-memory fake implementation of [WorkoutRepository] isolating API keys and
/// workout history per [userId].
class FakeWorkoutRepository implements WorkoutRepository {
  /// Map of `userId` -> saved Hevy API key.
  final Map<String, String> _userApiKeys = {};

  /// Map of `userId` -> (`workout.id` -> `WorkoutEntity`).
  final Map<String, Map<String, WorkoutEntity>> _userWorkouts = {};

  /// Optional reference clock used when `now` is omitted in
  /// [getWorkoutsForLastWeeks].
  DateTime? defaultNow;

  AppFailure? nextFailure;
  AppFailure? getKeyFailure;
  AppFailure? saveKeyFailure;
  AppFailure? clearKeyFailure;
  AppFailure? getWorkoutsFailure;

  /// Controlled completers to pause and resume operations deterministically.
  Completer<void>? getKeyCompleter;
  Completer<void>? saveKeyCompleter;
  Completer<void>? clearKeyCompleter;
  Completer<void>? getWorkoutsCompleter;

  /// Optional callbacks invoked when respective operations are called.
  Future<void> Function()? onGetSavedApiKey;
  Future<void> Function()? onValidateAndSaveApiKey;
  Future<void> Function()? onClearApiKey;
  Future<void> Function()? onGetWorkoutsForLastWeeks;

  @override
  Future<Result<String?, AppFailure>> getSavedApiKey({
    required String userId,
  }) async {
    if (onGetSavedApiKey != null) {
      await onGetSavedApiKey!();
    }
    if (getKeyCompleter != null) {
      await getKeyCompleter!.future;
    }

    if (userId.trim().isEmpty) {
      return const Result.failure(ValidationFailure('User ID cannot be empty'));
    }

    final failure = nextFailure ?? getKeyFailure;
    if (failure != null) {
      nextFailure = null;
      return Result.failure(failure);
    }

    return Result.success(_userApiKeys[userId]);
  }

  @override
  Future<Result<void, AppFailure>> validateAndSaveApiKey({
    required String userId,
    required String apiKey,
  }) async {
    if (onValidateAndSaveApiKey != null) {
      await onValidateAndSaveApiKey!();
    }
    if (saveKeyCompleter != null) {
      await saveKeyCompleter!.future;
    }

    if (userId.trim().isEmpty) {
      return const Result.failure(ValidationFailure('User ID cannot be empty'));
    }

    final validationError = HevyKeyValidators.validateKeyInput(apiKey);
    if (validationError != null) {
      return Result.failure(ValidationFailure(validationError.name));
    }

    final failure = nextFailure ?? saveKeyFailure;
    if (failure != null) {
      nextFailure = null;
      return Result.failure(failure);
    }

    _userApiKeys[userId] = HevyKeyValidators.normalizeKey(apiKey);
    return const Result.success(null);
  }

  @override
  Future<Result<void, AppFailure>> clearApiKey({required String userId}) async {
    if (onClearApiKey != null) {
      await onClearApiKey!();
    }
    if (clearKeyCompleter != null) {
      await clearKeyCompleter!.future;
    }

    if (userId.trim().isEmpty) {
      return const Result.failure(ValidationFailure('User ID cannot be empty'));
    }

    final failure = nextFailure ?? clearKeyFailure;
    if (failure != null) {
      nextFailure = null;
      return Result.failure(failure);
    }

    _userApiKeys.remove(userId);
    return const Result.success(null);
  }

  @override
  Future<Result<List<WorkoutEntity>, AppFailure>> getWorkoutsForLastWeeks({
    required String userId,
    int weeks = HevyApiConstants.lookbackWeeks,
    DateTime? now,
  }) async {
    if (onGetWorkoutsForLastWeeks != null) {
      await onGetWorkoutsForLastWeeks!();
    }
    if (getWorkoutsCompleter != null) {
      await getWorkoutsCompleter!.future;
    }

    if (userId.trim().isEmpty) {
      return const Result.failure(ValidationFailure('User ID cannot be empty'));
    }
    if (weeks < 1) {
      return const Result.failure(
        ValidationFailure('Weeks must be at least 1'),
      );
    }

    final failure = nextFailure ?? getWorkoutsFailure;
    if (failure != null) {
      nextFailure = null;
      return Result.failure(failure);
    }

    final savedKey = _userApiKeys[userId];
    if (savedKey == null || savedKey.trim().isEmpty) {
      return const Result.failure(
        AuthFailure('Hevy API key is not configured'),
      );
    }

    final workoutsMap = _userWorkouts[userId];
    if (workoutsMap == null || workoutsMap.isEmpty) {
      return const Result.success(<WorkoutEntity>[]);
    }

    final referenceLocal = (now ?? defaultNow ?? DateTime.now()).toLocal();
    final todayUtc = DateTime.utc(
      referenceLocal.year,
      referenceLocal.month,
      referenceLocal.day,
    );
    final currentWeekMonday = WeekDateUtils.startOfIsoWeekUtc(todayUtc);
    final cutoffMonday = currentWeekMonday.subtract(
      Duration(days: (weeks - 1) * 7),
    );

    final filtered = workoutsMap.values
        .where((workout) => !workout.localDate.isBefore(cutoffMonday))
        .toList();
    filtered.sort((a, b) => b.startTime.compareTo(a.startTime));

    return Result.success(List.unmodifiable(filtered));
  }

  /// Seeds a saved Hevy [apiKey] for [userId].
  void seedApiKey(String userId, String apiKey) {
    _userApiKeys[userId] = HevyKeyValidators.normalizeKey(apiKey);
  }

  /// Returns the currently stored API key for [userId], or `null` if none.
  String? getApiKeyForUser(String userId) => _userApiKeys[userId];

  /// Seeds initial [workouts] for a specific [userId].
  void seedWorkouts(String userId, List<WorkoutEntity> workouts) {
    final map = _userWorkouts.putIfAbsent(
      userId,
      () => <String, WorkoutEntity>{},
    );
    for (final workout in workouts) {
      map[workout.id] = workout;
    }
  }

  /// Returns all seeded workouts for [userId] (sorted newest `startTime` first).
  List<WorkoutEntity> getWorkoutsForUser(String userId) {
    final workoutsMap = _userWorkouts[userId];
    if (workoutsMap == null) return <WorkoutEntity>[];
    final list = workoutsMap.values.toList();
    list.sort((a, b) => b.startTime.compareTo(a.startTime));
    return list;
  }

  /// Clears all keys, workouts, pending failures, and controlled completers.
  void reset() {
    _userApiKeys.clear();
    _userWorkouts.clear();
    defaultNow = null;
    nextFailure = null;
    getKeyFailure = null;
    saveKeyFailure = null;
    clearKeyFailure = null;
    getWorkoutsFailure = null;
    getKeyCompleter = null;
    saveKeyCompleter = null;
    clearKeyCompleter = null;
    getWorkoutsCompleter = null;
    onGetSavedApiKey = null;
    onValidateAndSaveApiKey = null;
    onClearApiKey = null;
    onGetWorkoutsForLastWeeks = null;
  }
}
