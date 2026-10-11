import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/workout/data/repositories/workout_repository_impl.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_entity.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/hevy_key_form_state.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/hevy_key_view_model.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/workout_progress_state.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/workout_progress_view_model.dart';

import '../../../../test_helpers/fakes/fake_auth_repository.dart';
import '../../../../test_helpers/fakes/fake_workout_repository.dart';

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late FakeWorkoutRepository fakeWorkoutRepository;
  late ProviderContainer container;

  const testUser = UserEntity(id: 'u1', email: 'athlete@example.com');
  const validUuid = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

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
    container.listen(hevyKeyViewModelProvider, (_, _) {});
    container.listen(workoutProgressViewModelProvider, (_, _) {});
  });

  tearDown(() {
    container.dispose();
    fakeAuthRepository.dispose();
    fakeWorkoutRepository.reset();
  });

  group('HevyKeyViewModel validation and submission', () {
    test('initial state is clean HevyKeyFormState', () {
      final state = container.read(hevyKeyViewModelProvider);
      expect(state.rawKey, isEmpty);
      expect(state.status, equals(FormStatus.initial));
      expect(state.validationError, isNull);
      expect(state.submitErrorMessage, isNull);
    });

    test(
      'submitKey rejects empty input locally with validationError',
      () async {
        final notifier = container.read(hevyKeyViewModelProvider.notifier);
        final ok = await notifier.submitKey();

        expect(ok, isFalse);
        final state = container.read(hevyKeyViewModelProvider);
        expect(state.status, equals(FormStatus.failure));
        expect(state.validationError, equals('Hevy API key is required'));
        expect(state.submitErrorMessage, isNull);
        expect(fakeWorkoutRepository.getApiKeyForUser(testUser.id), isNull);
      },
    );

    test(
      'submitKey rejects malformed UUID locally and clears error on updateKey',
      () async {
        final notifier = container.read(hevyKeyViewModelProvider.notifier);
        notifier.updateKey('not-a-valid-uuid');

        final ok = await notifier.submitKey();
        expect(ok, isFalse);

        var state = container.read(hevyKeyViewModelProvider);
        expect(state.status, equals(FormStatus.failure));
        expect(
          state.validationError,
          equals('Enter a valid Hevy API key (UUID format)'),
        );

        notifier.updateKey(validUuid);
        state = container.read(hevyKeyViewModelProvider);
        expect(state.rawKey, equals(validUuid));
        expect(state.validationError, isNull);
        expect(state.status, equals(FormStatus.initial));
      },
    );

    test('submitKey trims whitespace, saves valid key, and triggers workoutProgressViewModel loadWorkouts', () async {
      fakeWorkoutRepository.seedWorkouts(testUser.id, [
        WorkoutEntity(
          id: 'w1',
          title: 'Push Day',
          startTime: DateTime.utc(2026, 10, 6, 17),
          endTime: DateTime.utc(2026, 10, 6, 18),
          localDate: DateTime.utc(2026, 10, 6),
          localDateIso: '2026-10-06',
          exercises: const [],
        ),
      ]);

      final notifier = container.read(hevyKeyViewModelProvider.notifier);
      notifier.updateKey('  $validUuid  ');

      final ok = await notifier.submitKey();
      expect(ok, isTrue);

      final formState = container.read(hevyKeyViewModelProvider);
      expect(formState.status, equals(FormStatus.success));
      expect(formState.validationError, isNull);
      expect(formState.submitErrorMessage, isNull);

      expect(
        fakeWorkoutRepository.getApiKeyForUser(testUser.id),
        equals(validUuid),
      );

      final progressState = container.read(workoutProgressViewModelProvider);
      expect(progressState, isA<WorkoutProgressLoaded>());
      final loaded = progressState as WorkoutProgressLoaded;
      expect(loaded.workouts, hasLength(1));
      expect(
        loaded.maskedApiKey,
        equals('••••••••-••••-••••-••••-••••••••7890'),
      );
    });

    test('submitKey preserves rawKey and sets submitErrorMessage when repository validation fails', () async {
      fakeWorkoutRepository.saveKeyFailure = const AuthFailure(
        'Invalid Hevy API key or Hevy Pro subscription required.',
      );

      final notifier = container.read(hevyKeyViewModelProvider.notifier);
      notifier.updateKey(validUuid);

      final ok = await notifier.submitKey();
      expect(ok, isFalse);

      final state = container.read(hevyKeyViewModelProvider);
      expect(state.rawKey, equals(validUuid));
      expect(state.status, equals(FormStatus.failure));
      expect(
        state.submitErrorMessage,
        equals('Invalid Hevy API key or Hevy Pro subscription required.'),
      );
      expect(state.validationError, isNull);
    });

    test('reset restores clean initial HevyKeyFormState', () async {
      final notifier = container.read(hevyKeyViewModelProvider.notifier);
      notifier.updateKey('bad-key');
      await notifier.submitKey();

      notifier.reset();
      final state = container.read(hevyKeyViewModelProvider);
      expect(state, equals(const HevyKeyFormState()));
    });
  });
}
