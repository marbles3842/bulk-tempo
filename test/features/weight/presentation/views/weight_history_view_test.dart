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

    testWidgets(
      'tapping date picker button displays calendar with Monday as first day of week',
      (tester) async {
        await tester.pumpApp(
          const WeightEntryBottomSheet(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
          ],
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('weight_date_picker_button')));
        await tester.pumpAndSettle();

        expect(find.byType(DatePickerDialog), findsOneWidget);

        final BuildContext dialogContext = tester.element(
          find.byType(DatePickerDialog),
        );
        final localizations = MaterialLocalizations.of(dialogContext);
        expect(localizations.firstDayOfWeekIndex, equals(1)); // 1 == Monday
      },
    );

    testWidgets('shows error banner when repository fails during save', (
      tester,
    ) async {
      fakeWeightRepository.saveFailure = const ServerFailure(
        'Server storage full',
      );

      await tester.pumpApp(
        const WeightHistoryView(),
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
          weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('empty_state_add_weight_button')));
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

  group('Correction UI & Edit Mode', () {
    testWidgets(
      'tapping daily row opens prefilled sheet in edit mode with read-only date',
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

        // Tap daily row
        await tester.tap(find.byKey(const Key('daily_entry_2026-10-06')));
        await tester.pumpAndSettle();

        expect(find.byType(WeightEntryBottomSheet), findsOneWidget);
        expect(find.text('Edit Weight Entry'), findsOneWidget);
        expect(find.text('78.50'), findsOneWidget);
        expect(find.byKey(const Key('save_weight_button')), findsOneWidget);
        expect(find.byKey(const Key('delete_weight_button')), findsOneWidget);

        // Date picker button should be disabled in edit mode
        await tester.tap(find.byKey(const Key('weight_date_picker_button')));
        await tester.pumpAndSettle();
        expect(find.byType(DatePickerDialog), findsNothing);
      },
    );

    testWidgets(
      'tapping edit affordance icon opens prefilled sheet in edit mode',
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

        // Tap edit affordance IconButton
        await tester.tap(find.byKey(const Key('edit_entry_2026-10-06')));
        await tester.pumpAndSettle();

        expect(find.byType(WeightEntryBottomSheet), findsOneWidget);
        expect(find.text('Edit Weight Entry'), findsOneWidget);
        expect(find.text('78.50'), findsOneWidget);
      },
    );

    testWidgets(
      'old-entry correction bypasses 365-day age limit and persists update',
      (tester) async {
        // Seed entry older than 365 days (2 years ago)
        fakeWeightRepository.seedEntries(testUser.id, [
          createEntry('2024-01-15', 85.0),
        ]);

        await tester.pumpApp(
          const WeightHistoryView(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
          ],
        );
        await tester.pumpAndSettle();

        // Tap row of the 2-year-old entry
        await tester.tap(find.byKey(const Key('daily_entry_2024-01-15')));
        await tester.pumpAndSettle();

        expect(find.text('85.00'), findsOneWidget);

        // Edit weight and save
        await tester.enterText(
          find.byKey(const Key('weight_input_field')),
          '86.50',
        );
        await tester.tap(find.byKey(const Key('save_weight_button')));
        await tester.pumpAndSettle();

        // Sheet dismissed and update persisted
        expect(find.byType(WeightEntryBottomSheet), findsNothing);
        expect(
          find.byKey(const Key('weight_entry_success_snackbar')),
          findsOneWidget,
        );

        final entries = fakeWeightRepository.getEntriesForUser(testUser.id);
        expect(entries.first.weightKg, equals(86.50));
        expect(entries.first.dateIso, equals('2024-01-15'));
      },
    );

    testWidgets(
      'saving edited entry applies weight without overwrite-self confirmation',
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

        await tester.tap(find.byKey(const Key('daily_entry_2026-10-06')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('weight_input_field')),
          '79.50',
        );
        await tester.tap(find.byKey(const Key('save_weight_button')));
        await tester.pumpAndSettle();

        // Overwrite dialog should never appear
        expect(find.byKey(const Key('overwrite_weight_dialog')), findsNothing);
        expect(find.byType(WeightEntryBottomSheet), findsNothing);
        expect(find.text('79.50 kg'), findsOneWidget);

        final entries = fakeWeightRepository.getEntriesForUser(testUser.id);
        expect(entries.first.weightKg, equals(79.50));
      },
    );

    testWidgets(
      'Add-after-edit reset: opening Add mode after edit resets form to clean state',
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

        // 1. Open edit mode
        await tester.tap(find.byKey(const Key('daily_entry_2026-10-06')));
        await tester.pumpAndSettle();
        expect(find.text('Edit Weight Entry'), findsOneWidget);

        // 2. Close edit mode without changes
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(find.byType(WeightEntryBottomSheet), findsNothing);

        // 3. Open Add mode via FAB
        await tester.tap(find.byKey(const Key('add_weight_fab')));
        await tester.pumpAndSettle();

        // Verify clean Add mode
        expect(find.text('Log Body Weight'), findsOneWidget);
        final textField = tester.widget<TextField>(
          find.byKey(const Key('weight_input_field')),
        );
        expect(textField.controller?.text, isEmpty);
        expect(find.byKey(const Key('delete_weight_button')), findsNothing);

        // Date picker button should be enabled in Add mode
        await tester.tap(find.byKey(const Key('weight_date_picker_button')));
        await tester.pumpAndSettle();
        expect(find.byType(DatePickerDialog), findsOneWidget);
      },
    );
  });

  group('Deletion Confirmation & Execution', () {
    testWidgets(
      'delete confirmation dialog names original date and saved weight even if draft changed',
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

        await tester.tap(find.byKey(const Key('daily_entry_2026-10-06')));
        await tester.pumpAndSettle();

        // Type a different weight in draft
        await tester.enterText(
          find.byKey(const Key('weight_input_field')),
          '99.99',
        );

        // Tap Delete
        await tester.tap(find.byKey(const Key('delete_weight_button')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('delete_confirmation_dialog')),
          findsOneWidget,
        );
        // Confirmation dialog must name original weight 78.50 kg, not draft 99.99
        expect(
          find.descendant(
            of: find.byKey(const Key('delete_confirmation_dialog')),
            matching: find.textContaining('78.50 kg'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('delete_confirmation_dialog')),
            matching: find.textContaining('99.99'),
          ),
          findsNothing,
        );
        expect(find.byKey(const Key('cancel_delete_button')), findsOneWidget);
        expect(find.byKey(const Key('confirm_delete_button')), findsOneWidget);
      },
    );

    testWidgets(
      'cancelling delete preserves draft in sheet and leaves storage unchanged',
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

        await tester.tap(find.byKey(const Key('daily_entry_2026-10-06')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('weight_input_field')),
          '99.99',
        );
        await tester.tap(find.byKey(const Key('delete_weight_button')));
        await tester.pumpAndSettle();

        // Tap cancel
        await tester.tap(find.byKey(const Key('cancel_delete_button')));
        await tester.pumpAndSettle();

        // Dialog closed, sheet still open, draft preserved
        expect(
          find.byKey(const Key('delete_confirmation_dialog')),
          findsNothing,
        );
        expect(find.byType(WeightEntryBottomSheet), findsOneWidget);
        expect(find.text('99.99'), findsOneWidget);

        // Storage unchanged
        final entries = fakeWeightRepository.getEntriesForUser(testUser.id);
        expect(entries, hasLength(1));
        expect(entries.first.weightKg, equals(78.5));
      },
    );

    testWidgets(
      'confirming delete removes entry, dismisses sheet, and displays success feedback',
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

        await tester.tap(find.byKey(const Key('daily_entry_2026-10-06')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('delete_weight_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('confirm_delete_button')));
        await tester.pumpAndSettle();

        expect(find.byType(WeightEntryBottomSheet), findsNothing);
        expect(
          find.byKey(const Key('weight_entry_success_snackbar')),
          findsOneWidget,
        );
        expect(find.text('Weight entry deleted successfully'), findsOneWidget);

        // Storage has 0 entries and empty state is rendered
        final entries = fakeWeightRepository.getEntriesForUser(testUser.id);
        expect(entries, isEmpty);
        expect(
          find.byKey(const Key('weight_history_empty_state')),
          findsOneWidget,
        );
      },
    );

    testWidgets('invalid draft deletion still deletes original target', (
      tester,
    ) async {
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

      await tester.tap(find.byKey(const Key('daily_entry_2026-10-06')));
      await tester.pumpAndSettle();

      // Clear weight to invalid empty input
      await tester.enterText(find.byKey(const Key('weight_input_field')), '');

      // Delete should still work
      await tester.tap(find.byKey(const Key('delete_weight_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirm_delete_button')));
      await tester.pumpAndSettle();

      expect(find.byType(WeightEntryBottomSheet), findsNothing);
      final entries = fakeWeightRepository.getEntriesForUser(testUser.id);
      expect(entries, isEmpty);
    });

    testWidgets(
      'deleting sole entry in a week removes that week card while preserving other weeks',
      (tester) async {
        fakeWeightRepository.seedEntries(testUser.id, [
          createEntry('2026-10-06', 78.5),
          createEntry('2026-09-29', 80.0),
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
        expect(find.byKey(const Key('week_card_2026-09-28')), findsOneWidget);

        // Delete entry in week 2026-10-05
        await tester.tap(find.byKey(const Key('daily_entry_2026-10-06')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('delete_weight_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('confirm_delete_button')));
        await tester.pumpAndSettle();

        // Week 2026-10-05 is completely removed, week 2026-09-28 remains
        expect(find.byKey(const Key('week_card_2026-10-05')), findsNothing);
        expect(find.byKey(const Key('week_card_2026-09-28')), findsOneWidget);
      },
    );
  });

  group('Dismissal & Dirty Confirmation', () {
    testWidgets(
      'unchanged edit closes directly via close button without prompt',
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

        await tester.tap(find.byKey(const Key('daily_entry_2026-10-06')));
        await tester.pumpAndSettle();

        // Tap close without modifying input
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('discard_changes_dialog')), findsNothing);
        expect(find.byType(WeightEntryBottomSheet), findsNothing);
      },
    );

    testWidgets(
      'dirty edit close button prompts Discard / Keep Editing; Keep Editing retains draft, Discard drops it',
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

        await tester.tap(find.byKey(const Key('daily_entry_2026-10-06')));
        await tester.pumpAndSettle();

        // Modify weight
        await tester.enterText(
          find.byKey(const Key('weight_input_field')),
          '81.20',
        );

        // Tap close
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('discard_changes_dialog')), findsOneWidget);
        expect(find.byKey(const Key('keep_editing_button')), findsOneWidget);
        expect(find.byKey(const Key('discard_changes_button')), findsOneWidget);

        // 1. Tap Keep Editing -> dialog dismisses, sheet stays open with draft
        await tester.tap(find.byKey(const Key('keep_editing_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('discard_changes_dialog')), findsNothing);
        expect(find.byType(WeightEntryBottomSheet), findsOneWidget);
        expect(find.text('81.20'), findsOneWidget);

        // 2. Tap close again -> tap Discard
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('discard_changes_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('discard_changes_dialog')), findsNothing);
        expect(find.byType(WeightEntryBottomSheet), findsNothing);

        // Storage remains original value
        final entries = fakeWeightRepository.getEntriesForUser(testUser.id);
        expect(entries.first.weightKg, equals(78.5));
      },
    );

    testWidgets('dirty edit downward swipe prompts Discard / Keep Editing', (
      tester,
    ) async {
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

      await tester.tap(find.byKey(const Key('daily_entry_2026-10-06')));
      await tester.pumpAndSettle();

      // Modify weight
      await tester.enterText(
        find.byKey(const Key('weight_input_field')),
        '83.00',
      );

      // Fling down on sheet
      await tester.fling(
        find.byType(WeightEntryBottomSheet),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('discard_changes_dialog')), findsOneWidget);

      await tester.tap(find.byKey(const Key('keep_editing_button')));
      await tester.pumpAndSettle();
      expect(find.byType(WeightEntryBottomSheet), findsOneWidget);
    });

    testWidgets(
      'multi-step swipe on dirty edit opens exactly one discard dialog',
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

        await tester.tap(find.byKey(const Key('daily_entry_2026-10-06')));
        await tester.pumpAndSettle();

        // Modify weight
        await tester.enterText(
          find.byKey(const Key('weight_input_field')),
          '83.00',
        );

        // Perform multi-step downward drag
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(WeightEntryBottomSheet)),
        );
        await gesture.moveBy(const Offset(0, 30));
        await tester.pump();
        await gesture.moveBy(const Offset(0, 30));
        await tester.pump();
        await gesture.moveBy(const Offset(0, 50));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        // Exactly one discard dialog is opened
        expect(find.byKey(const Key('discard_changes_dialog')), findsOneWidget);

        // Discarding pops the dialog and sheet cleanly
        await tester.tap(find.byKey(const Key('discard_changes_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('discard_changes_dialog')), findsNothing);
        expect(find.byType(WeightEntryBottomSheet), findsNothing);
      },
    );
  });

  group('Mutation Failure, Retry & Refresh Warning', () {
    testWidgets(
      'mutation failure displays error banner, retains input, and enables retry',
      (tester) async {
        fakeWeightRepository.seedEntries(testUser.id, [
          createEntry('2026-10-06', 78.5),
        ]);
        fakeWeightRepository.saveFailure = const ServerFailure(
          'Write rejected',
        );

        await tester.pumpApp(
          const WeightHistoryView(),
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
          ],
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('daily_entry_2026-10-06')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('weight_input_field')),
          '80.50',
        );
        await tester.tap(find.byKey(const Key('save_weight_button')));
        await tester.pumpAndSettle();

        // Error banner shown, input retained
        expect(
          find.byKey(const Key('weight_entry_error_banner')),
          findsOneWidget,
        );
        expect(find.text('Write rejected'), findsOneWidget);
        expect(find.text('80.50'), findsOneWidget);

        // Clear failure and retry save
        fakeWeightRepository.saveFailure = null;
        await tester.tap(find.byKey(const Key('save_weight_button')));
        await tester.pumpAndSettle();

        expect(find.byType(WeightEntryBottomSheet), findsNothing);
        final entries = fakeWeightRepository.getEntriesForUser(testUser.id);
        expect(entries.first.weightKg, equals(80.50));
      },
    );

    testWidgets(
      'confirmed change plus refresh failure retains visible change and offers Retry action',
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

        // Inject background refresh failure
        fakeWeightRepository.getFailure = const NetworkFailure(
          'Reconciliation timed out',
        );

        await tester.tap(find.byKey(const Key('daily_entry_2026-10-06')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('weight_input_field')),
          '82.00',
        );
        await tester.tap(find.byKey(const Key('save_weight_button')));
        await tester.pumpAndSettle();

        // Sheet closed
        expect(find.byType(WeightEntryBottomSheet), findsNothing);

        // Confirmed correction remains visible!
        expect(find.text('82.00 kg'), findsOneWidget);
        expect(find.text('82.00 kg avg'), findsOneWidget);

        // Refresh warning SnackBar shown with Retry action
        expect(
          find.byKey(const Key('weight_history_refresh_error_snackbar')),
          findsOneWidget,
        );
        expect(find.text('Reconciliation timed out'), findsOneWidget);
        expect(
          find.byKey(const Key('weight_history_refresh_retry_action')),
          findsOneWidget,
        );

        // Clear getFailure and tap Retry
        fakeWeightRepository.getFailure = null;
        await tester.tap(
          find.byKey(const Key('weight_history_refresh_retry_action')),
        );
        await tester.pumpAndSettle();

        // Confirmed correction still visible after successful retry
        expect(find.text('82.00 kg'), findsOneWidget);
      },
    );
  });
}
