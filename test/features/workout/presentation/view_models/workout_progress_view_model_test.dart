import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/workout/data/repositories/workout_repository_impl.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_exercise_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_set_entity.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/workout_progress_state.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/workout_progress_view_model.dart';

import '../../../../test_helpers/fakes/fake_auth_repository.dart';
import '../../../../test_helpers/fakes/fake_workout_repository.dart';

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late FakeWorkoutRepository fakeWorkoutRepository;
  late ProviderContainer container;

  const testUser = UserEntity(id: 'u1', email: 'athlete@example.com');
  const validApiKey = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
  const expectedMaskedKey = '••••••••-••••-••••-••••-ef1234567890';

  setUp(() {
    fakeAuthRepository = FakeAuthRepository(initialUser: testUser);
    fakeWorkoutRepository = FakeWorkoutRepository()
      ..defaultNow = DateTime.utc(2026, 10, 11, 12);
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        workoutRepositoryProvider.overrideWithValue(fakeWorkoutRepository),
      ],
    );
    container.listen(workoutProgressViewModelProvider, (_, _) {});
  });

  tearDown(() {
    container.dispose();
    fakeAuthRepository.dispose();
    fakeWorkoutRepository.reset();
  });

  WorkoutEntity createWorkout({
    required String id,
    required String title,
    required String localDateIso,
    required DateTime startTime,
    double weightKg = 100.0,
    int reps = 8,
  }) {
    final parsedDate = DateTime.parse('${localDateIso}T00:00:00.000Z');
    return WorkoutEntity(
      id: id,
      title: title,
      startTime: startTime,
      endTime: startTime.add(const Duration(minutes: 60)),
      localDate: parsedDate,
      localDateIso: localDateIso,
      exercises: [
        WorkoutExerciseEntity(
          index: 0,
          title: 'Bench Press',
          exerciseTemplateId: 'tpl_bench',
          sets: [
            const WorkoutSetEntity(
              index: 0,
              type: 'warmup',
              weightKg: 60.0,
              reps: 10,
            ),
            WorkoutSetEntity(
              index: 1,
              type: 'normal',
              weightKg: weightKg,
              reps: reps,
            ),
          ],
        ),
      ],
    );
  }

  group('Initial state & unconfigured flow', () {
    test('initial state is WorkoutProgressInitial with null maskedApiKey', () {
      final state = container.read(workoutProgressViewModelProvider);
      expect(state, isA<WorkoutProgressInitial>());
      expect(state.maskedApiKey, isNull);
    });

    test(
      'loadWorkouts emits WorkoutProgressUnconfigured when no key is saved',
      () async {
        final notifier = container.read(
          workoutProgressViewModelProvider.notifier,
        );
        await notifier.loadWorkouts();

        final state = container.read(workoutProgressViewModelProvider);
        expect(state, equals(const WorkoutProgressUnconfigured()));
        expect(state.maskedApiKey, isNull);
      },
    );
  });

  group('Configured key & weekly grouping', () {
    test('loadWorkouts masks key, fetches 12-week workouts, and groups by ISO week descending', () async {
      fakeWorkoutRepository.seedApiKey(testUser.id, validApiKey);
      fakeWorkoutRepository.seedWorkouts(testUser.id, [
        createWorkout(
          id: 'w1',
          title: 'Upper A',
          localDateIso: '2026-10-06',
          startTime: DateTime.utc(2026, 10, 6, 17),
          weightKg: 100.0,
          reps: 8,
        ),
        createWorkout(
          id: 'w2',
          title: 'Lower A',
          localDateIso: '2026-10-08',
          startTime: DateTime.utc(2026, 10, 8, 17),
          weightKg: 120.0,
          reps: 5,
        ),
        createWorkout(
          id: 'w3',
          title: 'Full Body',
          localDateIso: '2026-09-30',
          startTime: DateTime.utc(2026, 9, 30, 17),
          weightKg: 80.0,
          reps: 10,
        ),
      ]);

      final notifier = container.read(
        workoutProgressViewModelProvider.notifier,
      );
      await notifier.loadWorkouts();

      final state = container.read(workoutProgressViewModelProvider);
      expect(state, isA<WorkoutProgressLoaded>());
      final loaded = state as WorkoutProgressLoaded;
      expect(loaded.maskedApiKey, equals(expectedMaskedKey));
      expect(loaded.workouts, hasLength(3));
      expect(loaded.weeklySummaries, hasLength(2));
      expect(loaded.weeklySummaries[0].weekStartIso, equals('2026-10-05'));
      expect(loaded.weeklySummaries[0].workoutCount, equals(2));
      expect(loaded.weeklySummaries[0].totalWorkingSets, equals(2));
      expect(loaded.weeklySummaries[0].totalVolumeKg, equals(1400.0));
      expect(loaded.weeklySummaries[1].weekStartIso, equals('2026-09-28'));
      expect(loaded.weeklySummaries[1].workoutCount, equals(1));
      expect(loaded.refreshErrorMessage, isNull);
    });

    test('ensureInitialized loads only from WorkoutProgressInitial and caches across subsequent calls', () async {
      fakeWorkoutRepository.seedApiKey(testUser.id, validApiKey);
      var fetchCalls = 0;
      fakeWorkoutRepository.onGetWorkoutsForLastWeeks = () async {
        fetchCalls++;
      };

      final notifier = container.read(
        workoutProgressViewModelProvider.notifier,
      );
      await notifier.ensureInitialized();
      expect(fetchCalls, equals(1));
      expect(
        container.read(workoutProgressViewModelProvider),
        isA<WorkoutProgressLoaded>(),
      );

      // Subsequent ensureInitialized calls (e.g. switching tabs) do not re-fetch
      await notifier.ensureInitialized();
      await notifier.ensureInitialized();
      expect(fetchCalls, equals(1));
    });
  });

  group('Error handling & non-destructive refresh', () {
    test('loadWorkouts emits WorkoutProgressError with maskedApiKey when initial workout fetch fails', () async {
      fakeWorkoutRepository.seedApiKey(testUser.id, validApiKey);
      fakeWorkoutRepository.getWorkoutsFailure = const ServerFailure(
        'Hevy service unavailable',
      );

      final notifier = container.read(
        workoutProgressViewModelProvider.notifier,
      );
      await notifier.loadWorkouts();

      final state = container.read(workoutProgressViewModelProvider);
      expect(state, isA<WorkoutProgressError>());
      final errorState = state as WorkoutProgressError;
      expect(errorState.message, equals('Hevy service unavailable'));
      expect(errorState.maskedApiKey, equals(expectedMaskedKey));
    });

    test('loadWorkouts(showLoading: false) preserves loaded workouts and sets refreshErrorMessage on failure', () async {
      fakeWorkoutRepository.seedApiKey(testUser.id, validApiKey);
      fakeWorkoutRepository.seedWorkouts(testUser.id, [
        createWorkout(
          id: 'w1',
          title: 'Push',
          localDateIso: '2026-10-06',
          startTime: DateTime.utc(2026, 10, 6, 18),
        ),
      ]);

      final notifier = container.read(
        workoutProgressViewModelProvider.notifier,
      );
      await notifier.loadWorkouts();
      expect(
        container.read(workoutProgressViewModelProvider),
        isA<WorkoutProgressLoaded>(),
      );

      fakeWorkoutRepository.getWorkoutsFailure = const NetworkFailure(
        'Network error. Please check your connection.',
      );
      await notifier.loadWorkouts(showLoading: false);

      final state = container.read(workoutProgressViewModelProvider);
      expect(state, isA<WorkoutProgressLoaded>());
      final loaded = state as WorkoutProgressLoaded;
      expect(loaded.workouts, hasLength(1));
      expect(
        loaded.refreshErrorMessage,
        equals('Network error. Please check your connection.'),
      );

      notifier.clearRefreshError();
      final cleared = container.read(
        workoutProgressViewModelProvider,
      ) as WorkoutProgressLoaded;
      expect(cleared.refreshErrorMessage, isNull);
      expect(cleared.workouts, hasLength(1));
    });

    test(
      'loadWorkouts emits WorkoutProgressError when user is unauthenticated',
      () async {
        final unauthContainer = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            workoutRepositoryProvider.overrideWithValue(fakeWorkoutRepository),
          ],
        );
        addTearDown(unauthContainer.dispose);
        unauthContainer.listen(workoutProgressViewModelProvider, (_, _) {});
        await pumpEventQueue();

        final notifier = unauthContainer.read(
          workoutProgressViewModelProvider.notifier,
        );
        await notifier.loadWorkouts();

        final state = unauthContainer.read(workoutProgressViewModelProvider);
        expect(state, isA<WorkoutProgressError>());
        expect(
          (state as WorkoutProgressError).message,
          equals('User is not authenticated'),
        );
      },
    );
  });

  group('Disconnect & account isolation', () {
    test('disconnectApiKey clears saved key and transitions to WorkoutProgressUnconfigured', () async {
      fakeWorkoutRepository.seedApiKey(testUser.id, validApiKey);
      final notifier = container.read(
        workoutProgressViewModelProvider.notifier,
      );
      await notifier.loadWorkouts();
      expect(
        container.read(workoutProgressViewModelProvider),
        isA<WorkoutProgressLoaded>(),
      );

      final disconnected = await notifier.disconnectApiKey();
      expect(disconnected, isTrue);
      expect(fakeWorkoutRepository.getApiKeyForUser(testUser.id), isNull);
      expect(
        container.read(workoutProgressViewModelProvider),
        equals(const WorkoutProgressUnconfigured()),
      );
    });

    test('switching authenticated user resets state to WorkoutProgressInitial and drops in-flight read', () async {
      final completer = Completer<void>();
      fakeWorkoutRepository.getWorkoutsCompleter = completer;
      fakeWorkoutRepository.seedApiKey(testUser.id, validApiKey);

      final notifier = container.read(
        workoutProgressViewModelProvider.notifier,
      );
      final loadFuture = notifier.loadWorkouts();
      await pumpEventQueue();

      // Switch active user while fetch is in flight
      fakeAuthRepository.setCurrentUser(
        const UserEntity(id: 'u2', email: 'other@example.com'),
      );
      await pumpEventQueue();

      completer.complete();
      await loadFuture;

      final state = container.read(workoutProgressViewModelProvider);
      expect(state, isA<WorkoutProgressInitial>());
    });
  });
}
