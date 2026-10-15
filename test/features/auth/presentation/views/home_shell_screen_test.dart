import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:bulk_tempo/core/localization/locale_provider.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_state.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:bulk_tempo/features/auth/presentation/views/home_shell_screen.dart';
import 'package:bulk_tempo/features/dashboard/presentation/views/dashboard_view.dart';
import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';
import 'package:bulk_tempo/features/gain_target/presentation/view_models/gain_target_view_model.dart';
import 'package:bulk_tempo/features/gain_target/data/repositories/gain_target_repository_impl.dart';
import 'package:bulk_tempo/features/gain_target/presentation/views/gain_target_view.dart';
import 'package:bulk_tempo/features/weight/data/repositories/weight_repository_impl.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';
import 'package:bulk_tempo/features/weight/presentation/views/weight_history_view.dart';
import 'package:bulk_tempo/features/weight/presentation/widgets/weekly_weight_card.dart';
import 'package:bulk_tempo/features/weight/presentation/widgets/weekly_weight_chart.dart';
import 'package:bulk_tempo/features/weight/presentation/widgets/weight_entry_bottom_sheet.dart';
import 'package:bulk_tempo/features/workout/data/repositories/workout_repository_impl.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_exercise_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_set_entity.dart';
import 'package:bulk_tempo/features/workout/presentation/views/workout_progress_view.dart';
import 'package:bulk_tempo/features/workout/presentation/widgets/hevy_key_bottom_sheet.dart';
import 'package:bulk_tempo/features/workout/presentation/widgets/weekly_workout_card.dart';

import '../../../../test_helpers/fakes/fake_auth_repository.dart';
import '../../../../test_helpers/fakes/fake_gain_target_repository.dart';
import '../../../../test_helpers/fakes/fake_weight_repository.dart';
import '../../../../test_helpers/fakes/fake_workout_repository.dart';
import '../../../../test_helpers/pump_app.dart';

class FakeAuthViewModel extends AuthViewModel {
  final AuthState initialState;
  FakeAuthViewModel(this.initialState);

  @override
  AuthState build() => initialState;
}

void main() {
  late FakeAuthRepository fakeRepository;
  late FakeWeightRepository fakeWeightRepository;
  late FakeGainTargetRepository fakeGainTargetRepository;
  late FakeWorkoutRepository fakeWorkoutRepository;
  const testUser = UserEntity(id: 'u1', email: 'athlete@example.com');
  const validApiKey = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

  setUp(() {
    fakeRepository = FakeAuthRepository(initialUser: testUser);
    fakeWeightRepository = FakeWeightRepository();
    fakeGainTargetRepository = FakeGainTargetRepository();
    fakeWorkoutRepository = FakeWorkoutRepository()
      ..defaultNow = DateTime.utc(2026, 10, 11, 12);
  });

  tearDown(() {
    fakeRepository.dispose();
    fakeWeightRepository.reset();
    fakeGainTargetRepository.reset();
    fakeWorkoutRepository.reset();
  });

  List<Override> buildOverrides() => [
    authRepositoryProvider.overrideWithValue(fakeRepository),
    weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
    workoutRepositoryProvider.overrideWithValue(fakeWorkoutRepository),
    gainTargetRepositoryProvider.overrideWithValue(fakeGainTargetRepository),
  ];

  WeightEntryEntity createEntry(String dateIso, double weightKg) {
    final parsed = DateTime.parse('${dateIso}T00:00:00.000Z');
    return WeightEntryEntity(
      dateIso: dateIso,
      date: parsed,
      weightKg: weightKg,
      updatedAt: parsed,
    );
  }

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
      ],
    );
  }

  testWidgets(
    'renders DashboardView with KPI tiles and fl_chart cards on Home tab',
    (tester) async {
      await tester.pumpApp(
        const HomeShellScreen(),
        overrides: buildOverrides(),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DashboardView), findsOneWidget);
      expect(find.byKey(const Key('dashboard_kpi_pace_tile')), findsOneWidget);
      expect(
        find.byKey(const Key('dashboard_kpi_average_tile')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('dashboard_kpi_total_gain_tile')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('dashboard_kpi_workouts_tile')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('dashboard_weight_trend_card')),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('dashboard_weekly_pace_card')),
        100,
      );
      expect(
        find.byKey(const Key('dashboard_weekly_pace_card')),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('dashboard_weekly_workouts_card')),
        100,
      );
      expect(
        find.byKey(const Key('dashboard_weekly_workouts_card')),
        findsOneWidget,
      );

      expect(find.text('Welcome to Bulk Tempo'), findsNothing);
      expect(find.byKey(const Key('home_go_to_weights_button')), findsNothing);
      expect(find.byKey(const Key('home_go_to_workouts_button')), findsNothing);
      expect(find.byKey(const Key('home_logout_button')), findsNothing);
    },
  );

  testWidgets(
    'tapping logout button shows confirmation dialog with Cancel and Log Out actions',
    (tester) async {
      await tester.pumpApp(
        const HomeShellScreen(),
        overrides: buildOverrides(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('home_app_bar_logout_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Are you sure you want to log out?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byKey(const Key('confirm_logout_button')), findsOneWidget);
    },
  );

  testWidgets('tapping Cancel dismisses dialog without logging out', (
    tester,
  ) async {
    await tester.pumpApp(const HomeShellScreen(), overrides: buildOverrides());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_app_bar_logout_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(fakeRepository.currentUser, equals(testUser));
  });

  testWidgets('confirming logout signs out user from repository', (
    tester,
  ) async {
    await tester.pumpApp(const HomeShellScreen(), overrides: buildOverrides());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_app_bar_logout_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('confirm_logout_button')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(fakeRepository.currentUser, isNull);
  });

  testWidgets(
    'Home tab marks cached target band outdated after a failed target refresh',
    (tester) async {
      fakeWeightRepository.seedEntries(testUser.id, [
        createEntry('2026-10-06', 80.0),
        createEntry('2026-09-29', 79.5),
      ]);
      fakeWorkoutRepository.seedApiKey(testUser.id, validApiKey);
      fakeWorkoutRepository.seedWorkouts(testUser.id, [createSampleWorkout()]);
      fakeGainTargetRepository.seedTarget(
        testUser.id,
        const GainTargetEntity(minWeeklyGainKg: 0.1, maxWeeklyGainKg: 0.3),
      );
      await tester.pumpApp(
        const HomeShellScreen(),
        overrides: buildOverrides(),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DashboardView), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);

      await tester.scrollUntilVisible(find.byType(BarChart), 100);
      expect(find.byType(BarChart), findsAtLeastNWidgets(1));
      final targetSubtitle = find.byKey(
        const Key('dashboard_pace_target_subtitle'),
      );
      expect(targetSubtitle, findsOneWidget);
      final subtitleBeforeRefresh = tester.widget<Text>(targetSubtitle).data;
      expect(find.byKey(const Key('weekly_pace_outdated_badge')), findsNothing);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(DashboardView)),
      );
      fakeGainTargetRepository.getFailure = const NetworkFailure('Offline');
      await container
          .read(gainTargetViewModelProvider.notifier)
          .loadTarget(showLoading: false, isRefresh: true);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('weekly_pace_outdated_badge')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('weight_trend_outdated_badge')),
        findsNothing,
      );
      expect(tester.widget<Text>(targetSubtitle).data, subtitleBeforeRefresh);
      final paceChart = tester.widget<BarChart>(find.byType(BarChart).first);
      final targetBand =
          paceChart.data.rangeAnnotations.horizontalRangeAnnotations.single;
      expect(targetBand.y1, 0.1);
      expect(targetBand.y2, 0.3);
    },
  );

  testWidgets('displays error SnackBar when logout fails', (tester) async {
    fakeRepository.signOutFailure = const ServerFailure('Sign out failed');

    await tester.pumpApp(const HomeShellScreen(), overrides: buildOverrides());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_app_bar_logout_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('confirm_logout_button')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Sign out failed'), findsOneWidget);
  });

  testWidgets(
    'displays error SnackBar again when logout repeatedly fails with same error',
    (tester) async {
      fakeRepository.signOutFailure = const ServerFailure('Sign out failed');

      await tester.pumpApp(
        const HomeShellScreen(),
        overrides: buildOverrides(),
      );
      await tester.pumpAndSettle();

      // First logout attempt fails
      await tester.tap(find.byKey(const Key('home_app_bar_logout_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_logout_button')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Sign out failed'), findsOneWidget);

      // Dismiss current SnackBar to verify next presentation
      ScaffoldMessenger.of(
        tester.element(find.byType(HomeShellScreen)),
      ).hideCurrentSnackBar();
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);

      // Second logout attempt with same error
      await tester.tap(find.byKey(const Key('home_app_bar_logout_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_logout_button')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Sign out failed'), findsOneWidget);
    },
  );

  group('3-Tab Navigation & Weights Integration', () {
    testWidgets(
      'navigating to Weights tab via bottom NavigationBar renders empty state when no weights',
      (tester) async {
        await tester.pumpApp(
          const HomeShellScreen(),
          overrides: buildOverrides(),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('nav_weights_tab')));
        await tester.pumpAndSettle();

        expect(find.byType(WeightHistoryView), findsOneWidget);
        expect(
          find.byKey(const Key('weight_history_empty_state')),
          findsOneWidget,
        );
        expect(find.text('No weight entries yet'), findsOneWidget);
        expect(find.byKey(const Key('add_weight_fab')), findsOneWidget);
      },
    );

    testWidgets(
      'Weights tab renders WeeklyWeightChart and WeeklyWeightCard with seeded entries',
      (tester) async {
        fakeWeightRepository.seedEntries(testUser.id, [
          createEntry('2026-10-06', 78.5),
        ]);

        await tester.pumpApp(
          const HomeShellScreen(),
          overrides: buildOverrides(),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('nav_weights_tab')));
        await tester.pumpAndSettle();

        expect(find.byType(WeightHistoryView), findsOneWidget);
        expect(find.byType(WeeklyWeightChart), findsOneWidget);
        expect(
          find.byKey(const Key('weekly_weight_chart_card')),
          findsOneWidget,
        );
        expect(find.byType(WeeklyWeightCard), findsOneWidget);
        expect(find.byKey(const Key('week_card_2026-10-05')), findsOneWidget);
        expect(find.byKey(const Key('daily_entry_2026-10-06')), findsOneWidget);
        expect(find.text('78.50 kg avg'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping add_weight_fab on Weights tab opens bottom sheet and saves new weight entry',
      (tester) async {
        await tester.pumpApp(
          const HomeShellScreen(),
          overrides: buildOverrides(),
        );
        await tester.pumpAndSettle();

        // Switch to Weights tab
        await tester.tap(find.byKey(const Key('nav_weights_tab')));
        await tester.pumpAndSettle();

        // Tap Add Weight FAB
        await tester.tap(find.byKey(const Key('add_weight_fab')));
        await tester.pumpAndSettle();

        // Bottom sheet open
        expect(find.byType(WeightEntryBottomSheet), findsOneWidget);
        expect(find.byKey(const Key('weight_input_field')), findsOneWidget);

        // Enter weight and save
        await tester.enterText(
          find.byKey(const Key('weight_input_field')),
          '82.50',
        );
        await tester.tap(find.byKey(const Key('save_weight_button')));
        await tester.pumpAndSettle();

        // Modal dismissed
        expect(find.byType(WeightEntryBottomSheet), findsNothing);

        // Entry persisted in repository
        final userEntries = fakeWeightRepository.getEntriesForUser(testUser.id);
        expect(userEntries, hasLength(1));
        expect(userEntries.first.weightKg, equals(82.50));

        // UI updated to show chart and card
        expect(find.byType(WeeklyWeightChart), findsOneWidget);
        expect(find.byType(WeeklyWeightCard), findsOneWidget);
        expect(find.text('82.50 kg avg'), findsOneWidget);
      },
    );

    testWidgets(
      'switching to Profile tab displays email and allows logging out',
      (tester) async {
        await tester.pumpApp(
          const HomeShellScreen(),
          overrides: buildOverrides(),
        );
        await tester.pumpAndSettle();

        // Switch to Profile tab
        await tester.tap(find.byKey(const Key('nav_profile_tab')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('profile_heading')), findsOneWidget);
        expect(find.text('athlete@example.com'), findsOneWidget);
        expect(find.byKey(const Key('profile_logout_button')), findsOneWidget);

        // Tap logout
        await tester.ensureVisible(
          find.byKey(const Key('profile_logout_button')),
        );
        await tester.tap(find.byKey(const Key('profile_logout_button')));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Are you sure you want to log out?'), findsOneWidget);

        // Confirm logout
        await tester.tap(find.byKey(const Key('confirm_logout_button')));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(fakeRepository.currentUser, isNull);
      },
    );

    testWidgets(
      'Weights tab allows opening daily entry, editing weight, and saving update',
      (tester) async {
        fakeWeightRepository.seedEntries(testUser.id, [
          createEntry('2026-10-06', 78.5),
        ]);

        await tester.pumpApp(
          const HomeShellScreen(),
          overrides: buildOverrides(),
        );
        await tester.pumpAndSettle();

        // Switch to Weights tab
        await tester.tap(find.byKey(const Key('nav_weights_tab')));
        await tester.pumpAndSettle();

        // Scroll up so daily entry is clear of the bottom navigation bar
        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pumpAndSettle();

        // Tap daily row to open edit sheet
        await tester.tap(find.byKey(const Key('daily_entry_2026-10-06')));
        await tester.pumpAndSettle();

        expect(find.byType(WeightEntryBottomSheet), findsOneWidget);
        expect(find.text('Edit Weight Entry'), findsOneWidget);

        // Change weight and save
        await tester.enterText(
          find.byKey(const Key('weight_input_field')),
          '80.00',
        );
        await tester.tap(find.byKey(const Key('save_weight_button')));
        await tester.pumpAndSettle();

        expect(find.byType(WeightEntryBottomSheet), findsNothing);

        final entries = fakeWeightRepository.getEntriesForUser(testUser.id);
        expect(entries.first.weightKg, equals(80.00));
        expect(find.text('80.00 kg avg'), findsOneWidget);
      },
    );

    testWidgets(
      'logging out while dirty edit sheet is open dismisses sheet immediately without discard prompt',
      (tester) async {
        fakeWeightRepository.seedEntries(testUser.id, [
          createEntry('2026-10-06', 78.5),
        ]);

        await tester.pumpApp(
          const HomeShellScreen(),
          overrides: buildOverrides(),
        );
        await tester.pumpAndSettle();

        // Switch to Weights tab
        await tester.tap(find.byKey(const Key('nav_weights_tab')));
        await tester.pumpAndSettle();

        // Scroll up so daily entry is clear of the bottom navigation bar
        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pumpAndSettle();

        // Open edit sheet
        await tester.tap(find.byKey(const Key('daily_entry_2026-10-06')));
        await tester.pumpAndSettle();

        // Make sheet dirty
        await tester.enterText(
          find.byKey(const Key('weight_input_field')),
          '85.00',
        );

        // Sign out user asynchronously via repository
        await fakeRepository.signOut();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Sheet is dismissed without showing discard dialog
        expect(find.byType(WeightEntryBottomSheet), findsNothing);
        expect(find.byKey(const Key('discard_changes_dialog')), findsNothing);
      },
    );

    testWidgets(
      'Profile tab renders GainTargetView and weekly gain target section alongside profile details',
      (tester) async {
        await tester.pumpApp(
          const HomeShellScreen(),
          overrides: buildOverrides(),
        );
        await tester.pumpAndSettle();

        // Switch to Profile tab
        await tester.tap(find.byKey(const Key('nav_profile_tab')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('profile_heading')), findsOneWidget);
        expect(find.text('athlete@example.com'), findsOneWidget);
        expect(find.byType(GainTargetView), findsOneWidget);
        expect(find.text('Weekly Gain Target'), findsOneWidget);
        expect(find.byKey(const Key('gain_target_summary')), findsOneWidget);
      },
    );
  });

  group('4-Tab Navigation, Workouts & Profile Hevy Key Integration', () {
    testWidgets('renders 4 navigation destinations on Home tab', (
      tester,
    ) async {
      await tester.pumpApp(
        const HomeShellScreen(),
        overrides: buildOverrides(),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('nav_home_tab')), findsOneWidget);
      expect(find.byKey(const Key('nav_weights_tab')), findsOneWidget);
      expect(find.byKey(const Key('nav_workouts_tab')), findsOneWidget);
      expect(find.byKey(const Key('nav_profile_tab')), findsOneWidget);
    });

    testWidgets(
      'navigating to Workouts tab via bottom NavigationBar renders unconfigured state when no key',
      (tester) async {
        await tester.pumpApp(
          const HomeShellScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepository),
            weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
            workoutRepositoryProvider.overrideWithValue(fakeWorkoutRepository),
            gainTargetRepositoryProvider.overrideWithValue(
              fakeGainTargetRepository,
            ),
          ],
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('nav_workouts_tab')));
        await tester.pumpAndSettle();

        expect(find.byType(WorkoutProgressView), findsOneWidget);
        expect(
          find.byKey(const Key('workout_unconfigured_state')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('hevy_key_inline_input_field')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'entering Hevy key inline connects and displays weekly workout cards in Workouts tab',
      (tester) async {
        fakeWorkoutRepository.seedWorkouts(testUser.id, [
          createSampleWorkout(),
        ]);

        await tester.pumpApp(
          const HomeShellScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepository),
            weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
            workoutRepositoryProvider.overrideWithValue(fakeWorkoutRepository),
            gainTargetRepositoryProvider.overrideWithValue(
              fakeGainTargetRepository,
            ),
          ],
        );
        await tester.pumpAndSettle();

        // Switch to Workouts tab
        await tester.tap(find.byKey(const Key('nav_workouts_tab')));
        await tester.pumpAndSettle();

        // Enter valid key and connect
        await tester.enterText(
          find.byKey(const Key('hevy_key_inline_input_field')),
          validApiKey,
        );
        await tester.tap(
          find.byKey(const Key('hevy_key_inline_connect_button')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(WeeklyWorkoutCard), findsOneWidget);
        expect(find.text('Upper Body Hypertrophy'), findsOneWidget);
      },
    );

    testWidgets(
      'Profile tab renders Hevy Integration card showing Not connected and opens bottom sheet',
      (tester) async {
        await tester.pumpApp(
          const HomeShellScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepository),
            weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
            workoutRepositoryProvider.overrideWithValue(fakeWorkoutRepository),
            gainTargetRepositoryProvider.overrideWithValue(
              fakeGainTargetRepository,
            ),
          ],
        );
        await tester.pumpAndSettle();

        // Switch to Profile tab
        await tester.tap(find.byKey(const Key('nav_profile_tab')));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byKey(const Key('profile_hevy_card')));
        expect(find.byKey(const Key('profile_hevy_card')), findsOneWidget);
        expect(find.text('Not connected'), findsOneWidget);
        expect(
          find.byKey(const Key('profile_disconnect_hevy_key_button')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('profile_connect_or_update_hevy_key_button')),
          findsOneWidget,
        );
        expect(find.text('Connect Hevy Key'), findsOneWidget);

        // Tap connect button opens HevyKeyBottomSheet
        await tester.tap(
          find.byKey(const Key('profile_connect_or_update_hevy_key_button')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(HevyKeyBottomSheet), findsOneWidget);
        expect(
          find.byKey(const Key('hevy_key_sheet_input_field')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Profile tab displays masked key, allows updating via bottom sheet, and disconnects',
      (tester) async {
        fakeWorkoutRepository.seedApiKey(testUser.id, validApiKey);
        fakeWorkoutRepository.seedWorkouts(testUser.id, [
          createSampleWorkout(),
        ]);

        await tester.pumpApp(
          const HomeShellScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepository),
            weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
            workoutRepositoryProvider.overrideWithValue(fakeWorkoutRepository),
            gainTargetRepositoryProvider.overrideWithValue(
              fakeGainTargetRepository,
            ),
          ],
        );
        await tester.pumpAndSettle();

        // Switch to Profile tab
        await tester.tap(find.byKey(const Key('nav_profile_tab')));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byKey(const Key('profile_hevy_card')));
        expect(find.byKey(const Key('profile_hevy_card')), findsOneWidget);
        expect(
          find.byKey(const Key('profile_hevy_masked_key')),
          findsOneWidget,
        );
        expect(find.text('Update Key'), findsOneWidget);
        expect(
          find.byKey(const Key('profile_disconnect_hevy_key_button')),
          findsOneWidget,
        );

        // Tap Update Key opens bottom sheet
        await tester.tap(
          find.byKey(const Key('profile_connect_or_update_hevy_key_button')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(HevyKeyBottomSheet), findsOneWidget);

        // Close bottom sheet
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(find.byType(HevyKeyBottomSheet), findsNothing);

        // Tap Disconnect
        await tester.ensureVisible(
          find.byKey(const Key('profile_disconnect_hevy_key_button')),
        );
        await tester.tap(
          find.byKey(const Key('profile_disconnect_hevy_key_button')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Not connected'), findsOneWidget);
        expect(find.byKey(const Key('profile_hevy_masked_key')), findsNothing);
        expect(
          find.byKey(const Key('profile_disconnect_hevy_key_button')),
          findsNothing,
        );
        expect(find.text('Connect Hevy Key'), findsOneWidget);
        expect(fakeWorkoutRepository.getApiKeyForUser(testUser.id), isNull);
      },
    );

    testWidgets(
      'switching between Workouts and Profile tabs preserves session-cached data',
      (tester) async {
        fakeWorkoutRepository.seedApiKey(testUser.id, validApiKey);
        fakeWorkoutRepository.seedWorkouts(testUser.id, [
          createSampleWorkout(),
        ]);

        await tester.pumpApp(
          const HomeShellScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepository),
            weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
            workoutRepositoryProvider.overrideWithValue(fakeWorkoutRepository),
            gainTargetRepositoryProvider.overrideWithValue(
              fakeGainTargetRepository,
            ),
          ],
        );
        await tester.pumpAndSettle();

        // Switch to Workouts tab
        await tester.tap(find.byKey(const Key('nav_workouts_tab')));
        await tester.pumpAndSettle();

        expect(find.byType(WeeklyWorkoutCard), findsOneWidget);
        expect(find.text('Upper Body Hypertrophy'), findsOneWidget);

        // Switch to Profile tab
        await tester.tap(find.byKey(const Key('nav_profile_tab')));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byKey(const Key('profile_hevy_card')));
        expect(find.byKey(const Key('profile_hevy_card')), findsOneWidget);
        expect(
          find.byKey(const Key('profile_hevy_masked_key')),
          findsOneWidget,
        );

        // Switch back to Workouts tab
        await tester.tap(find.byKey(const Key('nav_workouts_tab')));
        await tester.pumpAndSettle();

        expect(find.byType(WeeklyWorkoutCard), findsOneWidget);
        expect(find.text('Upper Body Hypertrophy'), findsOneWidget);
      },
    );

    testWidgets(
      'Profile tab renders Language card and allows selecting languages',
      (tester) async {
        await tester.pumpApp(
          const HomeShellScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepository),
            weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
            workoutRepositoryProvider.overrideWithValue(fakeWorkoutRepository),
            gainTargetRepositoryProvider.overrideWithValue(
              fakeGainTargetRepository,
            ),
          ],
        );
        await tester.pumpAndSettle();

        // Switch to Profile tab
        await tester.tap(find.byKey(const Key('nav_profile_tab')));
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const Key('profile_language_card')),
        );
        expect(find.byKey(const Key('profile_language_card')), findsOneWidget);
        expect(
          find.byKey(const Key('profile_language_selector')),
          findsOneWidget,
        );
        expect(find.text('Language'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);
        expect(find.text('Polski'), findsOneWidget);
        expect(find.text('System'), findsNothing);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(HomeShellScreen)),
        );
        expect(container.read(localeProvider), const Locale('en'));

        // Tap Polski
        await tester.tap(find.text('Polski'));
        await tester.pumpAndSettle();

        expect(container.read(localeProvider), const Locale('pl'));
        final selectorPl = tester.widget<SegmentedButton<String>>(
          find.byKey(const Key('profile_language_selector')),
        );
        expect(selectorPl.selected, {'pl'});

        // Tap English
        await tester.tap(find.text('English'));
        await tester.pumpAndSettle();
        expect(container.read(localeProvider), const Locale('en'));
        final selectorEn = tester.widget<SegmentedButton<String>>(
          find.byKey(const Key('profile_language_selector')),
        );
        expect(selectorEn.selected, {'en'});
      },
    );

    testWidgets(
      'Home tab shows error state on pace card when initial gain target fails and recovers on retry',
      (tester) async {
        fakeGainTargetRepository.getFailure = const NetworkFailure(
          'Failed to load target',
        );
        fakeWeightRepository.seedEntries(testUser.id, [
          createEntry('2026-10-06', 80.0),
          createEntry('2026-10-13', 80.5),
        ]);

        await tester.pumpApp(
          const HomeShellScreen(),
          overrides: buildOverrides(),
        );
        await tester.pumpAndSettle();

        await tester.drag(
          find.byKey(const Key('dashboard_scroll_view')),
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();
        expect(find.text('Failed to load target'), findsOneWidget);
        expect(
          find.byKey(const Key('dashboard_pace_retry_button')),
          findsOneWidget,
        );

        // Clear failure and tap retry
        fakeGainTargetRepository.getFailure = null;
        await tester.tap(find.byKey(const Key('dashboard_pace_retry_button')));
        await tester.pumpAndSettle();

        expect(find.text('Failed to load target'), findsNothing);
      },
    );
  });
}
