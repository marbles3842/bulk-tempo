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

  WeightEntryEntity createEntry(String dateIso, double weightKg) {
    final parsed = DateTime.parse('${dateIso}T00:00:00.000Z');
    return WeightEntryEntity(
      dateIso: dateIso,
      date: parsed,
      weightKg: weightKg,
      updatedAt: parsed,
    );
  }

  test('initial state is WeightHistoryInitial', () {
    final state = container.read(weightHistoryViewModelProvider);
    expect(state, isA<WeightHistoryInitial>());
  });

  test(
    'loadEntries fetches entries and builds weeklySummaries and chartSummaries',
    () async {
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
    },
  );

  test('loadEntries slices at most 12 weeks for chartSummaries', () async {
    // Generate 15 distinct weeks (from 2026-01-05 up to 2026-04-13)
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
    // Newest week first in weeklySummaries
    expect(state.weeklySummaries.first.averageWeightKg, equals(84.0));

    // chartSummaries has maximum 12 weeks, sorted oldest to newest
    expect(state.chartSummaries.length, equals(12));
    expect(state.chartSummaries.first.averageWeightKg, equals(73.0)); // week 4
    expect(state.chartSummaries.last.averageWeightKg, equals(84.0)); // week 15
  });

  test(
    'hasEntryForDate returns true for logged date and false otherwise',
    () async {
      fakeWeightRepository.seedEntries(testUser.id, [
        createEntry('2026-10-05', 75.0),
      ]);

      final notifier = container.read(weightHistoryViewModelProvider.notifier);
      await notifier.loadEntries();

      final state =
          container.read(weightHistoryViewModelProvider) as WeightHistoryLoaded;
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

    // Simulate pull to refresh failure
    fakeWeightRepository.getFailure = const NetworkFailure('No internet');
    await notifier.loadEntries(showLoading: false);

    final state = container.read(weightHistoryViewModelProvider);
    expect(state, isA<WeightHistoryLoaded>());
    final loaded = state as WeightHistoryLoaded;
    expect(loaded.entries.length, equals(1));
    expect(loaded.refreshErrorMessage, equals('No internet'));

    // Clearing refresh error
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
}
