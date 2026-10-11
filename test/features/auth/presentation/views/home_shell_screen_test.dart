import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_state.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:bulk_tempo/features/auth/presentation/views/home_shell_screen.dart';
import 'package:bulk_tempo/features/gain_target/data/repositories/gain_target_repository_impl.dart';
import 'package:bulk_tempo/features/gain_target/presentation/views/gain_target_view.dart';
import 'package:bulk_tempo/features/weight/data/repositories/weight_repository_impl.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';
import 'package:bulk_tempo/features/weight/presentation/views/weight_history_view.dart';
import 'package:bulk_tempo/features/weight/presentation/widgets/weekly_weight_card.dart';
import 'package:bulk_tempo/features/weight/presentation/widgets/weekly_weight_chart.dart';
import 'package:bulk_tempo/features/weight/presentation/widgets/weight_entry_bottom_sheet.dart';

import '../../../../test_helpers/fakes/fake_auth_repository.dart';
import '../../../../test_helpers/fakes/fake_gain_target_repository.dart';
import '../../../../test_helpers/fakes/fake_weight_repository.dart';
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
  const testUser = UserEntity(id: 'u1', email: 'athlete@example.com');

  setUp(() {
    fakeRepository = FakeAuthRepository(initialUser: testUser);
    fakeWeightRepository = FakeWeightRepository();
    fakeGainTargetRepository = FakeGainTargetRepository();
  });

  tearDown(() {
    fakeRepository.dispose();
    fakeWeightRepository.reset();
    fakeGainTargetRepository.reset();
  });

  WeightEntryEntity createEntry(String dateIso, double weightKg) {
    final parsed = DateTime.parse('${dateIso}T00:00:00.000Z');
    return WeightEntryEntity(
      dateIso: dateIso,
      date: parsed,
      weightKg: weightKg,
      updatedAt: parsed,
    );
  }

  testWidgets('renders welcome message and authenticated user email', (
    tester,
  ) async {
    await tester.pumpApp(
      const HomeShellScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Bulk Tempo'), findsOneWidget);
    expect(find.text('athlete@example.com'), findsOneWidget);
    expect(find.byKey(const Key('home_logout_button')), findsOneWidget);
  });

  testWidgets(
    'tapping logout button shows confirmation dialog with Cancel and Log Out actions',
    (tester) async {
      await tester.pumpApp(
        const HomeShellScreen(),
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('home_logout_button')));
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
    await tester.pumpApp(
      const HomeShellScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_logout_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(fakeRepository.currentUser, equals(testUser));
  });

  testWidgets('confirming logout signs out user from repository', (
    tester,
  ) async {
    await tester.pumpApp(
      const HomeShellScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_logout_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('confirm_logout_button')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(fakeRepository.currentUser, isNull);
  });

  testWidgets('tapping app bar logout icon also shows confirmation dialog', (
    tester,
  ) async {
    await tester.pumpApp(
      const HomeShellScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_app_bar_logout_button')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Are you sure you want to log out?'), findsOneWidget);
  });

  testWidgets('displays error SnackBar when logout fails', (tester) async {
    fakeRepository.signOutFailure = const ServerFailure('Sign out failed');

    await tester.pumpApp(
      const HomeShellScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_logout_button')));
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
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
      );
      await tester.pumpAndSettle();

      // First logout attempt fails
      await tester.tap(find.byKey(const Key('home_logout_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_logout_button')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Sign out failed'), findsOneWidget);

      // Dismiss current SnackBar to verify next presentation
      ScaffoldMessenger.of(tester.element(find.byType(HomeShellScreen)))
          .hideCurrentSnackBar();
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);

      // Second logout attempt with same error
      await tester.tap(find.byKey(const Key('home_logout_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_logout_button')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Sign out failed'), findsOneWidget);
    },
  );

  group('3-Tab Navigation & Weights Integration', () {
    testWidgets(
      'tapping quick-action button on Home tab switches to Weights tab',
      (tester) async {
        await tester.pumpApp(
          const HomeShellScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepository),
            weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
          ],
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('home_go_to_weights_button')),
          findsOneWidget,
        );
        expect(find.byType(WeightHistoryView), findsNothing);

        await tester.tap(find.byKey(const Key('home_go_to_weights_button')));
        await tester.pumpAndSettle();

        expect(find.byType(WeightHistoryView), findsOneWidget);
        expect(
          find.byKey(const Key('weight_history_empty_state')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'navigating to Weights tab via bottom NavigationBar renders empty state when no weights',
      (tester) async {
        await tester.pumpApp(
          const HomeShellScreen(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepository),
            weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
          ],
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
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepository),
            weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
          ],
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
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepository),
            weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
          ],
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
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepository),
            weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
            gainTargetRepositoryProvider.overrideWithValue(
              fakeGainTargetRepository,
            ),
          ],
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
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepository),
            weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
            gainTargetRepositoryProvider.overrideWithValue(
              fakeGainTargetRepository,
            ),
          ],
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
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepository),
            weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
            gainTargetRepositoryProvider.overrideWithValue(
              fakeGainTargetRepository,
            ),
          ],
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
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepository),
            weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
            gainTargetRepositoryProvider.overrideWithValue(
              fakeGainTargetRepository,
            ),
          ],
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
}
