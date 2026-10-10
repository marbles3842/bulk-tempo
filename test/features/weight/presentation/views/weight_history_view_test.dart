import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/weight/data/repositories/weight_repository_impl.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';
import 'package:bulk_tempo/features/weight/domain/models/weekly_weight_summary_entity.dart';
import 'package:bulk_tempo/features/weight/presentation/views/weight_history_view.dart';
import 'package:bulk_tempo/features/weight/presentation/widgets/weekly_weight_card.dart';
import 'package:bulk_tempo/features/weight/presentation/widgets/weekly_weight_chart.dart';
import 'package:bulk_tempo/features/weight/presentation/widgets/weight_entry_bottom_sheet.dart';

import '../../../../test_helpers/fakes/fake_auth_repository.dart';
import '../../../../test_helpers/fakes/fake_weight_repository.dart';
import '../../../../test_helpers/pump_app.dart';

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late FakeWeightRepository fakeWeightRepository;

  const testUser = UserEntity(id: 'u1', email: 'athlete@example.com');

  setUp(() {
    fakeAuthRepository = FakeAuthRepository(initialUser: testUser);
    fakeWeightRepository = FakeWeightRepository();
  });

  tearDown(() {
    fakeAuthRepository.dispose();
    fakeWeightRepository.reset();
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

  group('WeightHistoryView States', () {
    testWidgets('renders empty state when user has zero weight entries', (
      tester,
    ) async {
      await tester.pumpApp(
        const WeightHistoryView(),
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
          weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
        ],
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('weight_history_empty_state')),
        findsOneWidget,
      );
      expect(find.text('No weight entries yet'), findsOneWidget);
      expect(
        find.byKey(const Key('empty_state_add_weight_button')),
        findsOneWidget,
      );
    });

    testWidgets(
      'tapping Add First Weight button opens WeightEntryBottomSheet',
      (tester) async {
        await tester.pumpApp(
          const WeightHistoryView(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
          ],
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('empty_state_add_weight_button')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(WeightEntryBottomSheet), findsOneWidget);
        expect(find.byKey(const Key('weight_input_field')), findsOneWidget);
        expect(find.byKey(const Key('save_weight_button')), findsOneWidget);
      },
    );

    testWidgets(
      'renders error view on initial fetch failure and retries on button tap',
      (tester) async {
        fakeWeightRepository.getFailure = const ServerFailure(
          'Failed to load entries from server',
        );

        await tester.pumpApp(
          const WeightHistoryView(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
          ],
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('weight_history_error_state')),
          findsOneWidget,
        );
        expect(find.text('Failed to load entries from server'), findsOneWidget);
        expect(
          find.byKey(const Key('weight_history_retry_button')),
          findsOneWidget,
        );

        // Clear failure and tap retry
        fakeWeightRepository.getFailure = null;
        await tester.tap(find.byKey(const Key('weight_history_retry_button')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('weight_history_empty_state')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders trend chart and weekly cards with first card expanded for single week',
      (tester) async {
        fakeWeightRepository.seedEntries(testUser.id, [
          createEntry('2026-10-06', 78.5),
        ]);

        await tester.pumpApp(
          const WeightHistoryView(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
          ],
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('weekly_weight_chart_card')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('single_week_chart_hint')), findsOneWidget);
        expect(find.byKey(const Key('week_card_2026-10-05')), findsOneWidget);
        expect(find.byKey(const Key('daily_entry_2026-10-06')), findsOneWidget);
        expect(find.text('78.50 kg avg'), findsOneWidget);
        expect(find.text('1/7 days'), findsOneWidget);
      },
    );

    testWidgets(
      'multi-week state hides single-week hint and renders all week cards',
      (tester) async {
        fakeWeightRepository.seedEntries(testUser.id, [
          createEntry('2026-10-07', 80.0),
          createEntry('2026-09-30', 81.2),
        ]);

        await tester.pumpApp(
          const WeightHistoryView(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
          ],
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('weekly_weight_chart_card')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('single_week_chart_hint')), findsNothing);
        expect(find.byKey(const Key('week_card_2026-10-05')), findsOneWidget);
        expect(find.byKey(const Key('week_card_2026-09-28')), findsOneWidget);
      },
    );

    testWidgets(
      'shows refresh error SnackBar without destroying loaded content on pull-to-refresh failure',
      (tester) async {
        fakeWeightRepository.seedEntries(testUser.id, [
          createEntry('2026-10-06', 79.0),
        ]);

        await tester.pumpApp(
          const WeightHistoryView(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
          ],
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('week_card_2026-10-05')), findsOneWidget);

        fakeWeightRepository.getFailure = const NetworkFailure(
          'Refresh network timeout',
        );

        // Fling list view to trigger pull-to-refresh
        await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('weight_history_refresh_error_snackbar')),
          findsOneWidget,
        );
        expect(find.text('Refresh network timeout'), findsOneWidget);
        // Existing card is preserved
        expect(find.byKey(const Key('week_card_2026-10-05')), findsOneWidget);
      },
    );
  });

  group('WeightEntryBottomSheet Interactions', () {
    testWidgets('shows validation error when attempting to save empty weight', (
      tester,
    ) async {
      await tester.pumpApp(
        const WeightEntryBottomSheet(),
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
          weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('save_weight_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a weight'), findsOneWidget);
    });

    testWidgets('shows error banner when repository fails during save', (
      tester,
    ) async {
      fakeWeightRepository.saveFailure = const ServerFailure(
        'Server storage full',
      );

      await tester.pumpApp(
        const WeightEntryBottomSheet(),
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
          weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
        ],
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('weight_input_field')),
        '85.50',
      );
      await tester.tap(find.byKey(const Key('save_weight_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('weight_entry_error_banner')),
        findsOneWidget,
      );
      expect(find.text('Server storage full'), findsOneWidget);
      // User input preserved
      expect(find.text('85.50'), findsOneWidget);
    });

    testWidgets(
      'detects same-day conflict, prompts confirmation dialog, and saves on Replace',
      (tester) async {
        final todayIso = WeekDateUtils.toIsoDateString(DateTime.now());
        fakeWeightRepository.seedEntries(testUser.id, [
          createEntry(todayIso, 77.0),
        ]);

        await tester.pumpApp(
          const WeightHistoryView(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
          ],
        );
        await tester.pumpAndSettle();

        // Open bottom sheet
        await tester.tap(find.byKey(const Key('add_weight_fab')));
        await tester.pumpAndSettle();

        // Enter replacement weight
        await tester.enterText(
          find.byKey(const Key('weight_input_field')),
          '78.20',
        );
        await tester.tap(find.byKey(const Key('save_weight_button')));
        await tester.pumpAndSettle();

        // Verify overwrite dialog appeared
        expect(
          find.byKey(const Key('overwrite_weight_dialog')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('confirm_overwrite_weight_button')),
          findsOneWidget,
        );

        // Tap Replace
        await tester.tap(
          find.byKey(const Key('confirm_overwrite_weight_button')),
        );
        await tester.pumpAndSettle();

        // Bottom sheet and dialog dismissed
        expect(find.byKey(const Key('overwrite_weight_dialog')), findsNothing);
        expect(find.byType(WeightEntryBottomSheet), findsNothing);

        // Check repository was updated
        final entries = fakeWeightRepository.getEntriesForUser(testUser.id);
        expect(entries.first.weightKg, equals(78.2));
      },
    );
  });

  group('Standalone Widget tests', () {
    testWidgets('WeeklyWeightChart handles empty list gracefully', (
      tester,
    ) async {
      await tester.pumpApp(const WeeklyWeightChart(chartSummaries: []));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('weekly_weight_chart_card')), findsOneWidget);
    });

    testWidgets('WeeklyWeightCard expands and collapses on tap', (
      tester,
    ) async {
      final summary = WeeklyWeightSummaryEntity(
        weekStartIso: '2026-10-05',
        weekStartMonday: DateTime.utc(2026, 10, 5),
        weekEndSunday: DateTime.utc(2026, 10, 11),
        averageWeightKg: 75.0,
        entries: [createEntry('2026-10-07', 75.0)],
      );

      await tester.pumpApp(
        WeeklyWeightCard(summary: summary, initiallyExpanded: false),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('week_card_2026-10-05')), findsOneWidget);
      // Tap ExpansionTile to expand
      await tester.tap(find.text('Oct 5 – Oct 11, 2026'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('daily_entry_2026-10-07')), findsOneWidget);
    });
  });
}
