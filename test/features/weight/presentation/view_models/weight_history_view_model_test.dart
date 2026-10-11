import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/weight/data/repositories/weight_repository_impl.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_history_state.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_history_view_model.dart';

import '../../../../test_helpers/fakes/fake_auth_repository.dart';
import '../../../../test_helpers/fakes/fake_weight_repository.dart';

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late FakeWeightRepository fakeWeightRepository;
  late ProviderContainer container;

  const testUser = UserEntity(id: 'u1', email: 'athlete@example.com');

  setUp(() {
    fakeAuthRepository = FakeAuthRepository(initialUser: testUser);
    fakeWeightRepository = FakeWeightRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
      ],
    );
    container.listen(weightHistoryViewModelProvider, (_, _) {});
  });

  tearDown(() {
    container.dispose();
    fakeAuthRepository.dispose();
    fakeWeightRepository.reset();
  });

  WeightEntryEntity createEntry(
    String dateIso,
    double weightKg, {
    DateTime? updatedAt,
  }) {
    final parsed = DateTime.parse('${dateIso}T00:00:00.000Z');
    return WeightEntryEntity(
      dateIso: dateIso,
      date: parsed,
      weightKg: weightKg,
      updatedAt: updatedAt ?? parsed,
    );
  }

  group('Initial state and loading', () {
    test('initial state is WeightHistoryInitial', () {
      final state = container.read(weightHistoryViewModelProvider);
      expect(state, isA<WeightHistoryInitial>());
    });

    test('loadEntries fetches entries and builds weeklySummaries and chartSummaries', () async {
      final entries = [
        createEntry('2026-10-06', 75.0), // Week Oct 5 - Oct 11 (Tuesday)
        createEntry('2026-10-05', 75.4), // Monday
        createEntry('2026-09-29', 76.0), // Week Sep 28 - Oct 4
      ];
      fakeWeightRepository.seedEntries(testUser.id, entries);

      final notifier = container.read(weightHistoryViewModelProvider.notifier);
      await notifier.loadEntries();

      final state = container.read(weightHistoryViewModelProvider);
      expect(state, isA<WeightHistoryLoaded>());
      final loaded = state as WeightHistoryLoaded;
      expect(loaded.entries.length, equals(3));
      expect(loaded.weeklySummaries.length, equals(2));
      // weeklySummaries is sorted newest week first
      expect(loaded.weeklySummaries[0].weekStartIso, equals('2026-10-05'));
      expect(loaded.weeklySummaries[1].weekStartIso, equals('2026-09-28'));
      // chartSummaries is chronologically oldest week first (left to right)
      expect(loaded.chartSummaries.length, equals(2));
      expect(loaded.chartSummaries[0].weekStartIso, equals('2026-09-28'));
      expect(loaded.chartSummaries[1].weekStartIso, equals('2026-10-05'));
      expect(loaded.refreshErrorMessage, isNull);
    });

    test('loadEntries slices at most 12 weeks for chartSummaries', () async {
      final entries = <WeightEntryEntity>[];
      for (int i = 0; i < 15; i++) {
        final monday = DateTime.utc(2026, 1, 5).add(Duration(days: i * 7));
        final dateIso =
            '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
        entries.add(createEntry(dateIso, 70.0 + i));
      }
      fakeWeightRepository.seedEntries(testUser.id, entries);

      final notifier = container.read(weightHistoryViewModelProvider.notifier);
      await notifier.loadEntries();

      final state =
          container.read(weightHistoryViewModelProvider) as WeightHistoryLoaded;
      expect(state.weeklySummaries.length, equals(15));
      expect(state.weeklySummaries.first.averageWeightKg, equals(84.0));

      expect(state.chartSummaries.length, equals(12));
      expect(state.chartSummaries.first.averageWeightKg, equals(73.0));
      expect(state.chartSummaries.last.averageWeightKg, equals(84.0));
    });

    test(
      'hasEntryForDate returns true for logged date and false otherwise',
      () async {
        fakeWeightRepository.seedEntries(testUser.id, [
          createEntry('2026-10-05', 75.0),
        ]);

        final notifier = container.read(
          weightHistoryViewModelProvider.notifier,
        );
        await notifier.loadEntries();

        final state = container.read(
          weightHistoryViewModelProvider,
        ) as WeightHistoryLoaded;
        expect(state.hasEntryForDate('2026-10-05'), isTrue);
        expect(state.hasEntryForDate('2026-10-06'), isFalse);
      },
    );

    test('loadEntries emits WeightHistoryError when repository fails on initial fetch', () async {
      fakeWeightRepository.getFailure = const ServerFailure('Database error');

      final notifier = container.read(weightHistoryViewModelProvider.notifier);
      await notifier.loadEntries();

      final state = container.read(weightHistoryViewModelProvider);
      expect(state, isA<WeightHistoryError>());
      expect((state as WeightHistoryError).message, equals('Database error'));
    });

    test('loadEntries preserves data and sets refreshErrorMessage when pull-to-refresh fails', () async {
      fakeWeightRepository.seedEntries(testUser.id, [
        createEntry('2026-10-05', 75.0),
      ]);

      final notifier = container.read(weightHistoryViewModelProvider.notifier);
      await notifier.loadEntries(showLoading: true);

      expect(
        container.read(weightHistoryViewModelProvider),
        isA<WeightHistoryLoaded>(),
      );

      fakeWeightRepository.getFailure = const NetworkFailure('No internet');
      await notifier.loadEntries(showLoading: false);

      final state = container.read(weightHistoryViewModelProvider);
      expect(state, isA<WeightHistoryLoaded>());
      final loaded = state as WeightHistoryLoaded;
      expect(loaded.entries.length, equals(1));
      expect(loaded.refreshErrorMessage, equals('No internet'));

      notifier.clearRefreshError();
      final cleared =
          container.read(weightHistoryViewModelProvider) as WeightHistoryLoaded;
      expect(cleared.refreshErrorMessage, isNull);
      expect(cleared.entries.length, equals(1));
    });

    test(
      'loadEntries emits WeightHistoryError when user is not authenticated',
      () async {
        final unauthContainer = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
          ],
        );
        addTearDown(unauthContainer.dispose);
        unauthContainer.listen(weightHistoryViewModelProvider, (_, _) {});
        await pumpEventQueue();

        final notifier = unauthContainer.read(
          weightHistoryViewModelProvider.notifier,
        );
        await notifier.loadEntries();

        final state = unauthContainer.read(weightHistoryViewModelProvider);
        expect(state, isA<WeightHistoryError>());
        expect(
          (state as WeightHistoryError).message,
          equals('User is not authenticated'),
        );
      },
    );
  });

  group('applySavedEntry', () {
    test(
      'updates existing entry and recalculates weekly average immediately',
      () async {
        // Monday = 80.00, Tuesday = 82.00 -> avg = 81.00
        final monday = createEntry('2026-10-05', 80.0);
        final tuesday = createEntry('2026-10-06', 82.0);
        fakeWeightRepository.seedEntries(testUser.id, [tuesday, monday]);

        final notifier = container.read(
          weightHistoryViewModelProvider.notifier,
        );
        await notifier.loadEntries();

        final initial = container.read(
          weightHistoryViewModelProvider,
        ) as WeightHistoryLoaded;
        expect(initial.weeklySummaries.first.averageWeightKg, equals(81.0));

        // Correct Tuesday to 84.00 -> avg should become 82.00
        final correctedTuesday = createEntry('2026-10-06', 84.0);
        notifier.applySavedEntry(userId: testUser.id, entry: correctedTuesday);

        final updated = container.read(
          weightHistoryViewModelProvider,
        ) as WeightHistoryLoaded;
        expect(updated.entries.length, equals(2));
        expect(
          updated.entries.firstWhere((e) => e.dateIso == '2026-10-06').weightKg,
          equals(84.0),
        );
        expect(updated.weeklySummaries.first.averageWeightKg, equals(82.0));
      },
    );

    test('inserts new entry in descending date order', () async {
      final notifier = container.read(weightHistoryViewModelProvider.notifier);
      notifier.applySavedEntry(
        userId: testUser.id,
        entry: createEntry('2026-10-05', 80.0),
      );
      notifier.applySavedEntry(
        userId: testUser.id,
        entry: createEntry('2026-10-07', 81.0),
      );

      final state =
          container.read(weightHistoryViewModelProvider) as WeightHistoryLoaded;
      expect(state.entries.length, equals(2));
      expect(state.entries[0].dateIso, equals('2026-10-07'));
      expect(state.entries[1].dateIso, equals('2026-10-05'));
    });

    test(
      'ignores application when userId does not match active account',
      () async {
        final notifier = container.read(
          weightHistoryViewModelProvider.notifier,
        );
        notifier.applySavedEntry(
          userId: 'other_user',
          entry: createEntry('2026-10-05', 80.0),
        );

        final state = container.read(weightHistoryViewModelProvider);
        expect(state, isA<WeightHistoryInitial>());
      },
    );
  });

  group('applyDeletedEntry', () {
    test(
      'deleting one of two entries updates weekly count and average',
      () async {
        final monday = createEntry('2026-10-05', 80.0);
        final tuesday = createEntry('2026-10-06', 82.0);
        fakeWeightRepository.seedEntries(testUser.id, [tuesday, monday]);

        final notifier = container.read(
          weightHistoryViewModelProvider.notifier,
        );
        await notifier.loadEntries();

        // Delete Tuesday
        notifier.applyDeletedEntry(userId: testUser.id, dateIso: '2026-10-06');

        final state = container.read(
          weightHistoryViewModelProvider,
        ) as WeightHistoryLoaded;
        expect(state.entries.length, equals(1));
        expect(state.entries.first.dateIso, equals('2026-10-05'));
        expect(state.weeklySummaries.first.loggedDaysCount, equals(1));
        expect(state.weeklySummaries.first.averageWeightKg, equals(80.0));
      },
    );

    test('deleting last entry in a week removes that week entirely', () async {
      final entryWeek1 = createEntry('2026-10-05', 80.0);
      final entryWeek2 = createEntry('2026-09-28', 79.0);
      fakeWeightRepository.seedEntries(testUser.id, [entryWeek1, entryWeek2]);

      final notifier = container.read(weightHistoryViewModelProvider.notifier);
      await notifier.loadEntries();

      final initial =
          container.read(weightHistoryViewModelProvider) as WeightHistoryLoaded;
      expect(initial.weeklySummaries.length, equals(2));

      // Delete sole entry in week 1
      notifier.applyDeletedEntry(userId: testUser.id, dateIso: '2026-10-05');

      final updated =
          container.read(weightHistoryViewModelProvider) as WeightHistoryLoaded;
      expect(updated.entries.length, equals(1));
      expect(updated.weeklySummaries.length, equals(1));
      expect(updated.weeklySummaries.first.weekStartIso, equals('2026-09-28'));
    });

    test('deleting last account entry yields loaded-empty state', () async {
      final entry = createEntry('2026-10-05', 80.0);
      fakeWeightRepository.seedEntries(testUser.id, [entry]);

      final notifier = container.read(weightHistoryViewModelProvider.notifier);
      await notifier.loadEntries();

      notifier.applyDeletedEntry(userId: testUser.id, dateIso: '2026-10-05');

      final state =
          container.read(weightHistoryViewModelProvider) as WeightHistoryLoaded;
      expect(state.entries, isEmpty);
      expect(state.weeklySummaries, isEmpty);
      expect(state.chartSummaries, isEmpty);
      expect(state.isEmpty, isTrue);
    });

    test('deleting an absent entry succeeds as a no-op', () async {
      final entry = createEntry('2026-10-05', 80.0);
      fakeWeightRepository.seedEntries(testUser.id, [entry]);

      final notifier = container.read(weightHistoryViewModelProvider.notifier);
      await notifier.loadEntries();

      notifier.applyDeletedEntry(userId: testUser.id, dateIso: '2026-10-09');

      final state =
          container.read(weightHistoryViewModelProvider) as WeightHistoryLoaded;
      expect(state.entries.length, equals(1));
    });

    test(
      'ignores deletion when userId does not match active account',
      () async {
        final entry = createEntry('2026-10-05', 80.0);
        fakeWeightRepository.seedEntries(testUser.id, [entry]);

        final notifier = container.read(
          weightHistoryViewModelProvider.notifier,
        );
        await notifier.loadEntries();

        notifier.applyDeletedEntry(userId: 'other_user', dateIso: '2026-10-05');

        final state = container.read(
          weightHistoryViewModelProvider,
        ) as WeightHistoryLoaded;
        expect(state.entries.length, equals(1));
      },
    );
  });

  group('Chart window boundary transitions', () {
    test('deleting sole entry in newest of 13 logged weeks introduces previously excluded 13th week to chart', () async {
      // Generate 13 weeks: week 0 (oldest, 2026-01-05) to week 12 (newest, 2026-03-30)
      final entries = <WeightEntryEntity>[];
      for (int i = 0; i < 13; i++) {
        final monday = DateTime.utc(2026, 1, 5).add(Duration(days: i * 7));
        final dateIso =
            '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
        entries.add(createEntry(dateIso, 70.0 + i));
      }
      fakeWeightRepository.seedEntries(testUser.id, entries);

      final notifier = container.read(weightHistoryViewModelProvider.notifier);
      await notifier.loadEntries();

      final initial =
          container.read(weightHistoryViewModelProvider) as WeightHistoryLoaded;
      expect(initial.weeklySummaries.length, equals(13));
      expect(initial.chartSummaries.length, equals(12));
      // Oldest week in chart should be week 1 (2026-01-12) because maxChartWeeks is 12
      expect(initial.chartSummaries.first.weekStartIso, equals('2026-01-12'));

      // Delete the sole entry in newest week (2026-03-30)
      final newestDateIso = entries.last.dateIso;
      notifier.applyDeletedEntry(userId: testUser.id, dateIso: newestDateIso);

      final updated =
          container.read(weightHistoryViewModelProvider) as WeightHistoryLoaded;
      expect(updated.weeklySummaries.length, equals(12));
      expect(updated.chartSummaries.length, equals(12));
      // The previously excluded week 0 (2026-01-05) is now in the 12-week chart!
      expect(updated.chartSummaries.first.weekStartIso, equals('2026-01-05'));
    });
  });

  group('Accepted last-action-wins semantics', () {
    test('stale save recreates an entry that was deleted', () async {
      final notifier = container.read(weightHistoryViewModelProvider.notifier);
      notifier.applySavedEntry(
        userId: testUser.id,
        entry: createEntry('2026-10-05', 80.0),
      );

      // Deleted on device B
      notifier.applyDeletedEntry(userId: testUser.id, dateIso: '2026-10-05');
      expect(
        (container.read(
          weightHistoryViewModelProvider,
        ) as WeightHistoryLoaded).entries,
        isEmpty,
      );

      // Stale save arrives later
      notifier.applySavedEntry(
        userId: testUser.id,
        entry: createEntry('2026-10-05', 80.5),
      );
      final state =
          container.read(weightHistoryViewModelProvider) as WeightHistoryLoaded;
      expect(state.entries.length, equals(1));
      expect(state.entries.first.weightKg, equals(80.5));
    });

    test('stale delete removes an entry that was updated', () async {
      final notifier = container.read(weightHistoryViewModelProvider.notifier);
      notifier.applySavedEntry(
        userId: testUser.id,
        entry: createEntry('2026-10-05', 80.0),
      );

      // Updated on device B
      notifier.applySavedEntry(
        userId: testUser.id,
        entry: createEntry('2026-10-05', 82.0),
      );

      // Stale delete arrives later
      notifier.applyDeletedEntry(userId: testUser.id, dateIso: '2026-10-05');
      final state =
          container.read(weightHistoryViewModelProvider) as WeightHistoryLoaded;
      expect(state.entries, isEmpty);
    });
  });

  group('Controlled asynchronous races and ordering', () {
    test(
      'read started before mutation completes late: stale read is discarded',
      () async {
        final readCompleter = Completer<void>();
        fakeWeightRepository.getCompleter = readCompleter;

        // Seed repository with old value (70.0)
        fakeWeightRepository.seedEntries(testUser.id, [
          createEntry('2026-10-05', 70.0),
        ]);

        final notifier = container.read(
          weightHistoryViewModelProvider.notifier,
        );

        // 1. Start read (in-flight)
        final readFuture = notifier.loadEntries();

        // 2. A mutation is applied while read is in-flight (new value 85.0)
        notifier.applySavedEntry(
          userId: testUser.id,
          entry: createEntry('2026-10-05', 85.0),
        );

        final stateAfterMutation = container.read(
          weightHistoryViewModelProvider,
        ) as WeightHistoryLoaded;
        expect(stateAfterMutation.entries.first.weightKg, equals(85.0));

        // 3. Complete the old read that started before the mutation
        readCompleter.complete();
        await readFuture;

        // 4. Stale read must NOT have overwritten the mutation!
        final finalState = container.read(
          weightHistoryViewModelProvider,
        ) as WeightHistoryLoaded;
        expect(finalState.entries.first.weightKg, equals(85.0));
      },
    );

    test('failed reconciliation refresh preserves corrected entries and sets refreshErrorMessage', () async {
      final notifier = container.read(weightHistoryViewModelProvider.notifier);
      notifier.applySavedEntry(
        userId: testUser.id,
        entry: createEntry('2026-10-05', 80.0),
      );

      // Refresh fails
      fakeWeightRepository.getFailure = const NetworkFailure('Timeout');
      await notifier.loadEntries(showLoading: false);

      final state =
          container.read(weightHistoryViewModelProvider) as WeightHistoryLoaded;
      expect(state.entries.length, equals(1));
      expect(state.entries.first.weightKg, equals(80.0));
      expect(state.refreshErrorMessage, equals('Timeout'));
    });

    test('out-of-order reads: earlier read completing after newer read is discarded', () async {
      final completer1 = Completer<void>();
      final completer2 = Completer<void>();

      var callCount = 0;
      fakeWeightRepository.onGetWeightEntries = () async {
        callCount++;
        if (callCount == 1) {
          await completer1.future;
        } else if (callCount == 2) {
          await completer2.future;
        }
      };

      final notifier = container.read(weightHistoryViewModelProvider.notifier);

      // Read 1 starts
      fakeWeightRepository.seedEntries(testUser.id, [
        createEntry('2026-10-05', 70.0),
      ]);
      final future1 = notifier.loadEntries();

      // Read 2 starts with updated repository data
      fakeWeightRepository.seedEntries(testUser.id, [
        createEntry('2026-10-05', 90.0),
      ]);
      final future2 = notifier.loadEntries();

      // Read 2 completes first
      completer2.complete();
      await future2;

      var state =
          container.read(weightHistoryViewModelProvider) as WeightHistoryLoaded;
      expect(state.entries.first.weightKg, equals(90.0));

      // Read 1 completes later
      completer1.complete();
      await future1;

      // Read 1's old data must be discarded
      state =
          container.read(weightHistoryViewModelProvider) as WeightHistoryLoaded;
      expect(state.entries.first.weightKg, equals(90.0));
    });

    test(
      'account switch during in-flight read drops result for previous account',
      () async {
        final readCompleter = Completer<void>();
        fakeWeightRepository.getCompleter = readCompleter;
        fakeWeightRepository.seedEntries(testUser.id, [
          createEntry('2026-10-05', 70.0),
        ]);

        final notifier = container.read(
          weightHistoryViewModelProvider.notifier,
        );
        final readFuture = notifier.loadEntries();

        // Active user changes to u2
        fakeAuthRepository.setCurrentUser(
          const UserEntity(id: 'u2', email: 'user2@example.com'),
        );

        readCompleter.complete();
        await readFuture;

        // State on container was reset on auth change to initial, not populated with u1's entries
        final state = container.read(weightHistoryViewModelProvider);
        expect(state, isA<WeightHistoryInitial>());
      },
    );

    test(
      'disposal during in-flight read does not throw or alter state',
      () async {
        final readCompleter = Completer<void>();
        fakeWeightRepository.getCompleter = readCompleter;

        final localContainer = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
          ],
        );
        addTearDown(localContainer.dispose);
        localContainer.listen(weightHistoryViewModelProvider, (_, _) {});

        final notifier = localContainer.read(
          weightHistoryViewModelProvider.notifier,
        );
        final future = notifier.loadEntries();

        // Dispose while read is awaiting
        localContainer.dispose();
        readCompleter.complete();

        await future; // finishes cleanly
      },
    );
  });
}
