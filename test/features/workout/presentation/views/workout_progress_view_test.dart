import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/workout/data/repositories/workout_repository_impl.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_exercise_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_set_entity.dart';
import 'package:bulk_tempo/features/workout/presentation/views/workout_progress_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/hevy_key_view_model.dart';
import 'package:bulk_tempo/features/workout/presentation/widgets/hevy_key_bottom_sheet.dart';
import 'package:bulk_tempo/features/workout/presentation/widgets/workout_detail_bottom_sheet.dart';

import '../../../../test_helpers/fakes/fake_auth_repository.dart';
import '../../../../test_helpers/fakes/fake_workout_repository.dart';
import '../../../../test_helpers/pump_app.dart';

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late FakeWorkoutRepository fakeWorkoutRepository;

  const testUser = UserEntity(id: 'u1', email: 'athlete@example.com');
  const validApiKey = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

  setUp(() {
    fakeAuthRepository = FakeAuthRepository(initialUser: testUser);
    fakeWorkoutRepository = FakeWorkoutRepository()
      ..defaultNow = DateTime.utc(2026, 10, 11, 12);
  });

  tearDown(() {
    fakeAuthRepository.dispose();
    fakeWorkoutRepository.reset();
  });

  WorkoutEntity createSampleWorkout({
    String id = 'w1',
    String title = 'Upper Body Hypertrophy',
    String localDateIso = '2026-10-06',
    DateTime? startTime,
  }) {
    final start = startTime ?? DateTime.utc(2026, 10, 6, 17, 0);
    return WorkoutEntity(
      id: id,
      title: title,
      startTime: start,
      endTime: start.add(const Duration(minutes: 55)),
      localDate: DateTime.parse('${localDateIso}T00:00:00.000Z'),
      localDateIso: localDateIso,
      exercises: const [
        WorkoutExerciseEntity(
          index: 0,
          title: 'Barbell Bench Press',
          exerciseTemplateId: 'ex_bench',
          notes: 'Paused reps on chest',
          sets: [
            WorkoutSetEntity(
              index: 0,
              type: 'warmup',
              weightKg: 60.0,
              reps: 10,
            ),
            WorkoutSetEntity(index: 1, type: 'normal', weightKg: 95.0, reps: 8),
            WorkoutSetEntity(
              index: 2,
              type: 'failure',
              weightKg: 100.0,
              reps: 8,
            ),
          ],
        ),
        WorkoutExerciseEntity(
          index: 1,
          title: 'Pull Ups',
          exerciseTemplateId: 'ex_pullups',
          sets: [WorkoutSetEntity(index: 0, type: 'normal', reps: 12)],
        ),
      ],
    );
  }

  group('Unconfigured State & Inline Key Setup', () {
    testWidgets(
      'renders unconfigured state with developer link and inline key input when no key is saved',
      (tester) async {
        await tester.pumpApp(
          const WorkoutProgressView(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            workoutRepositoryProvider.overrideWithValue(fakeWorkoutRepository),
          ],
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('workout_unconfigured_state')),
          findsOneWidget,
        );
        expect(
          find.textContaining('https://hevy.com/settings?developer'),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('hevy_key_inline_input_field')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('hevy_key_inline_connect_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'validates UUID format inline and connects successfully when valid key is submitted',
      (tester) async {
        fakeWorkoutRepository.seedWorkouts(testUser.id, [
          createSampleWorkout(),
        ]);

        await tester.pumpApp(
          const WorkoutProgressView(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            workoutRepositoryProvider.overrideWithValue(fakeWorkoutRepository),
          ],
        );
        await tester.pumpAndSettle();

        // Submit invalid key
        await tester.enterText(
          find.byKey(const Key('hevy_key_inline_input_field')),
          'invalid-key',
        );
        await tester.tap(
          find.byKey(const Key('hevy_key_inline_connect_button')),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Enter a valid Hevy API key (UUID format)'),
          findsOneWidget,
        );

        // Submit valid UUID key
        await tester.enterText(
          find.byKey(const Key('hevy_key_inline_input_field')),
          validApiKey,
        );
        await tester.tap(
          find.byKey(const Key('hevy_key_inline_connect_button')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('workout_week_card_2026-10-05')),
          findsOneWidget,
        );
        expect(find.text('Upper Body Hypertrophy'), findsOneWidget);
      },
    );

    testWidgets(
      'synchronizes inline text field when HevyKeyFormState rawKey changes externally',
      (tester) async {
        await tester.pumpApp(
          const WorkoutProgressView(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            workoutRepositoryProvider.overrideWithValue(fakeWorkoutRepository),
          ],
        );
        await tester.pumpAndSettle();

        // User enters a key inline
        await tester.enterText(
          find.byKey(const Key('hevy_key_inline_input_field')),
          'some-partial-key',
        );
        await tester.pumpAndSettle();

        final element = tester.element(find.byType(WorkoutProgressView));
        final container = ProviderScope.containerOf(element);

        // Reset the form provider externally (as happens when opening the bottom sheet)
        container.read(hevyKeyViewModelProvider.notifier).reset();
        await tester.pumpAndSettle();

        // The text controller should now reflect the empty rawKey
        final textField = tester.widget<TextField>(
          find.byKey(const Key('hevy_key_inline_input_field')),
        );
        expect(textField.controller?.text, '');
      },
    );
  });

  group('Error State & HevyKeyBottomSheet', () {
    testWidgets(
      'renders error state on initial fetch failure, retries on tap, and opens HevyKeyBottomSheet on Update API Key',
      (tester) async {
        fakeWorkoutRepository.seedApiKey(testUser.id, validApiKey);
        fakeWorkoutRepository.getWorkoutsFailure = const AuthFailure(
          'Invalid Hevy API key or Hevy Pro subscription required.',
        );

        await tester.pumpApp(
          const WorkoutProgressView(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            workoutRepositoryProvider.overrideWithValue(fakeWorkoutRepository),
          ],
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('workout_progress_error_state')),
          findsOneWidget,
        );
        expect(
          find.text('Invalid Hevy API key or Hevy Pro subscription required.'),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('workout_progress_retry_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('workout_error_update_key_button')),
          findsOneWidget,
        );

        // Open HevyKeyBottomSheet via Update API Key button
        await tester.tap(
          find.byKey(const Key('workout_error_update_key_button')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(HevyKeyBottomSheet), findsOneWidget);
        expect(
          find.byKey(const Key('hevy_key_sheet_input_field')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('hevy_key_sheet_save_button')),
          findsOneWidget,
        );

        // Simulate save failure inside sheet to verify error banner
        fakeWorkoutRepository.saveKeyFailure = const NetworkFailure(
          'Network error. Please check your connection.',
        );
        await tester.enterText(
          find.byKey(const Key('hevy_key_sheet_input_field')),
          validApiKey,
        );
        await tester.tap(find.byKey(const Key('hevy_key_sheet_save_button')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('hevy_key_sheet_error_banner')),
          findsOneWidget,
        );
        expect(
          find.text('Network error. Please check your connection.'),
          findsOneWidget,
        );

        // Clear failures and save again
        fakeWorkoutRepository.saveKeyFailure = null;
        fakeWorkoutRepository.getWorkoutsFailure = null;
        await tester.tap(find.byKey(const Key('hevy_key_sheet_save_button')));
        await tester.pumpAndSettle();

        expect(find.byType(HevyKeyBottomSheet), findsNothing);
        expect(
          find.byKey(const Key('workout_progress_empty_state')),
          findsOneWidget,
        );
      },
    );
  });

  group('Empty & Populated Weekly Workout Cards + Drill-Down Sheet', () {
    testWidgets(
      'renders empty 12-week state when key is configured but no workouts exist',
      (tester) async {
        fakeWorkoutRepository.seedApiKey(testUser.id, validApiKey);

        await tester.pumpApp(
          const WorkoutProgressView(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            workoutRepositoryProvider.overrideWithValue(fakeWorkoutRepository),
          ],
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('workout_progress_empty_state')),
          findsOneWidget,
        );
        expect(find.text('No workouts in the last 12 weeks'), findsOneWidget);
        expect(
          find.byKey(const Key('workout_empty_refresh_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders expandable weekly cards and opens WorkoutDetailBottomSheet with best set and set badges on tap',
      (tester) async {
        fakeWorkoutRepository.seedApiKey(testUser.id, validApiKey);
        fakeWorkoutRepository.seedWorkouts(testUser.id, [
          createSampleWorkout(
            id: 'w1',
            title: 'Upper Body Hypertrophy',
            localDateIso: '2026-10-06',
            startTime: DateTime.utc(2026, 10, 6, 17),
          ),
          createSampleWorkout(
            id: 'w2',
            title: 'Lower Body Power',
            localDateIso: '2026-09-29',
            startTime: DateTime.utc(2026, 9, 29, 17),
          ),
        ]);

        await tester.pumpApp(
          const WorkoutProgressView(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            workoutRepositoryProvider.overrideWithValue(fakeWorkoutRepository),
          ],
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('workout_refresh_button')), findsOneWidget);
        expect(
          find.byKey(const Key('workout_week_card_2026-10-05')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('workout_week_card_2026-09-28')),
          findsOneWidget,
        );
        expect(
          find.text('3 working sets • 1560.00 kg volume'),
          findsNWidgets(2),
        );

        // First week card is initially expanded so workout count chip is hidden
        expect(
          find.byKey(const Key('workout_count_chip_2026-10-05')),
          findsNothing,
        );
        // Second week card is collapsed so workout count chip is visible
        expect(
          find.byKey(const Key('workout_count_chip_2026-09-28')),
          findsOneWidget,
        );
        expect(find.text('1 workout'), findsOneWidget);

        // First week card is initially expanded so workout_item_w1 is visible
        expect(find.byKey(const Key('workout_item_w1')), findsOneWidget);

        // Tap workout_item_w1 to open WorkoutDetailBottomSheet
        await tester.tap(find.byKey(const Key('workout_item_w1')));
        await tester.pumpAndSettle();

        expect(find.byType(WorkoutDetailBottomSheet), findsOneWidget);
        expect(find.byKey(const Key('workout_exercise_0')), findsOneWidget);
        expect(find.byKey(const Key('workout_exercise_1')), findsOneWidget);
        expect(find.text('Barbell Bench Press'), findsOneWidget);
        expect(find.text('Best: 100.00 kg × 8'), findsOneWidget);
        expect(find.byKey(const Key('workout_best_set_0')), findsOneWidget);

        // Check sets and badges
        expect(find.byKey(const Key('workout_set_0_0')), findsOneWidget);
        expect(find.byKey(const Key('workout_set_0_1')), findsOneWidget);
        expect(find.byKey(const Key('workout_set_0_2')), findsOneWidget);
        expect(find.text('Warmup'), findsOneWidget);
        expect(find.text('Failure'), findsOneWidget);
        expect(find.text('Working'), findsNothing);
        expect(find.text('60.00 kg × 10'), findsOneWidget);
        expect(find.text('95.00 kg × 8'), findsOneWidget);
        expect(find.text('100.00 kg × 8'), findsOneWidget);
        expect(find.text('12 reps'), findsOneWidget);
      },
    );

    testWidgets(
      'shows non-destructive refresh error SnackBar when manual refresh fails',
      (tester) async {
        fakeWorkoutRepository.seedApiKey(testUser.id, validApiKey);
        fakeWorkoutRepository.seedWorkouts(testUser.id, [
          createSampleWorkout(id: 'w1'),
        ]);

        await tester.pumpApp(
          const WorkoutProgressView(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            workoutRepositoryProvider.overrideWithValue(fakeWorkoutRepository),
          ],
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('workout_week_card_2026-10-05')),
          findsOneWidget,
        );

        fakeWorkoutRepository.getWorkoutsFailure = const NetworkFailure(
          'Offline during refresh',
        );

        await tester.tap(find.byKey(const Key('workout_refresh_button')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('workout_progress_refresh_error_snackbar')),
          findsOneWidget,
        );
        expect(find.text('Offline during refresh'), findsOneWidget);
        expect(
          find.byKey(const Key('workout_week_card_2026-10-05')),
          findsOneWidget,
        );
      },
    );
  });
}
