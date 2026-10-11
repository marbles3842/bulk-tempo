import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_entity.dart';

import 'fake_workout_repository.dart';

void main() {
  late FakeWorkoutRepository repository;

  const validUuid1 = 'f4352809-838a-4e2c-98bb-922f1f14e552';
  const validUuid2 = '11111111-2222-3333-4444-555555555555';

  WorkoutEntity createWorkout({
    required String id,
    required DateTime localDate,
    required DateTime startTime,
  }) {
    final y = localDate.year.toString().padLeft(4, '0');
    final m = localDate.month.toString().padLeft(2, '0');
    final d = localDate.day.toString().padLeft(2, '0');
    return WorkoutEntity(
      id: id,
      title: 'Workout $id',
      startTime: startTime,
      endTime: startTime.add(const Duration(hours: 1)),
      localDate: DateTime.utc(localDate.year, localDate.month, localDate.day),
      localDateIso: '$y-$m-$d',
      exercises: const [],
    );
  }

  setUp(() {
    repository = FakeWorkoutRepository();
  });

  group('FakeWorkoutRepository API key management', () {
    test('returns null when no key is saved for user', () async {
      final result = await repository.getSavedApiKey(userId: 'user_1');
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isNull);
    });

    test('isolates API keys strictly between different users', () async {
      await repository.validateAndSaveApiKey(
        userId: 'user_1',
        apiKey: '  $validUuid1  ',
      );
      await repository.validateAndSaveApiKey(
        userId: 'user_2',
        apiKey: validUuid2,
      );

      final res1 = await repository.getSavedApiKey(userId: 'user_1');
      final res2 = await repository.getSavedApiKey(userId: 'user_2');

      expect(res1.dataOrNull, validUuid1);
      expect(res2.dataOrNull, validUuid2);
    });

    test('rejects invalid UUID without saving or consuming failure', () async {
      repository.nextFailure = const NetworkFailure('Offline');

      final result = await repository.validateAndSaveApiKey(
        userId: 'user_1',
        apiKey: 'not-a-uuid',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(repository.getApiKeyForUser('user_1'), isNull);
      expect(repository.nextFailure, const NetworkFailure('Offline'));
    });

    test('clearApiKey removes only the target user key', () async {
      repository.seedApiKey('user_1', validUuid1);
      repository.seedApiKey('user_2', validUuid2);

      final clearResult = await repository.clearApiKey(userId: 'user_1');
      expect(clearResult.isSuccess, isTrue);

      expect(repository.getApiKeyForUser('user_1'), isNull);
      expect(repository.getApiKeyForUser('user_2'), validUuid2);
    });
  });

  group('FakeWorkoutRepository.getWorkoutsForLastWeeks', () {
    test('returns AuthFailure when no API key is saved', () async {
      final result = await repository.getWorkoutsForLastWeeks(userId: 'user_1');
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<AuthFailure>());
    });

    test('filters workouts to the 12-ISO-week window and isolates by userId', () async {
      repository.seedApiKey('user_1', validUuid1);
      repository.seedApiKey('user_2', validUuid2);

      // Reference date: Wednesday 2026-10-07 -> currentWeekMonday = 2026-10-05
      // 12 weeks inclusive -> cutoffMonday = 2026-10-05 - 77 days = 2026-07-20
      final referenceNow = DateTime(2026, 10, 7, 12);

      final currentWeekWorkout = createWorkout(
        id: 'w_current',
        localDate: DateTime.utc(2026, 10, 6),
        startTime: DateTime.utc(2026, 10, 6, 18),
      );
      final boundaryMondayWorkout = createWorkout(
        id: 'w_cutoff_monday',
        localDate: DateTime.utc(2026, 7, 20),
        startTime: DateTime.utc(2026, 7, 20, 10),
      );
      final beforeCutoffSundayWorkout = createWorkout(
        id: 'w_before_cutoff',
        localDate: DateTime.utc(2026, 7, 19),
        startTime: DateTime.utc(2026, 7, 19, 10),
      );
      final otherUserWorkout = createWorkout(
        id: 'w_user2',
        localDate: DateTime.utc(2026, 10, 6),
        startTime: DateTime.utc(2026, 10, 6, 9),
      );

      repository.seedWorkouts('user_1', [
        boundaryMondayWorkout,
        currentWeekWorkout,
        beforeCutoffSundayWorkout,
      ]);
      repository.seedWorkouts('user_2', [otherUserWorkout]);

      final res1 = await repository.getWorkoutsForLastWeeks(
        userId: 'user_1',
        weeks: 12,
        now: referenceNow,
      );
      final res2 = await repository.getWorkoutsForLastWeeks(
        userId: 'user_2',
        weeks: 12,
        now: referenceNow,
      );

      expect(res1.isSuccess, isTrue);
      final user1Ids = res1.dataOrNull?.map((w) => w.id).toList();
      expect(user1Ids, ['w_current', 'w_cutoff_monday']);

      expect(res2.isSuccess, isTrue);
      final user2Ids = res2.dataOrNull?.map((w) => w.id).toList();
      expect(user2Ids, ['w_user2']);
    });

    test('honors controllable failures and reset()', () async {
      repository.seedApiKey('user_1', validUuid1);
      repository.getWorkoutsFailure = const ServerFailure('Hevy down');

      final failRes = await repository.getWorkoutsForLastWeeks(
        userId: 'user_1',
      );
      expect(failRes.isFailure, isTrue);
      expect(failRes.failureOrNull, const ServerFailure('Hevy down'));

      repository.reset();
      expect(repository.getWorkoutsFailure, isNull);
      expect(repository.getApiKeyForUser('user_1'), isNull);
    });
  });
}
