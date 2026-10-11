import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/form_status.dart';
import 'package:bulk_tempo/features/weight/data/repositories/weight_repository_impl.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_entry_view_model.dart';
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
    container.listen(weightEntryViewModelProvider, (_, _) {});
  });

  tearDown(() {
    container.dispose();
    fakeAuthRepository.dispose();
    fakeWeightRepository.reset();
  });

  test('initial state has empty weight, default date, and initial status', () {
    final state = container.read(weightEntryViewModelProvider);
    expect(state.weightInput, isEmpty);
    expect(state.status, equals(FormStatus.initial));
    expect(state.weightError, isNull);
    expect(state.dateError, isNull);
    expect(state.errorMessage, isNull);
    expect(state.requiresOverwriteConfirmation, isFalse);
    expect(state.existingEntryForDate, isNull);
  });

  test(
    'onWeightChanged and onDateChanged update form values and clear errors',
    () {
      final notifier = container.read(weightEntryViewModelProvider.notifier);

      notifier.onWeightChanged('82.5');
      expect(
        container.read(weightEntryViewModelProvider).weightInput,
        equals('82.5'),
      );

      final newDate = DateTime.utc(2026, 5, 10);
      notifier.onDateChanged(newDate);
      expect(
        container.read(weightEntryViewModelProvider).selectedDate,
        equals(WeekDateUtils.normalizeDateUtc(newDate)),
      );
    },
  );

  test(
    'submit fails validation when weight input is empty or invalid',
    () async {
      final notifier = container.read(weightEntryViewModelProvider.notifier);

      final resultEmpty = await notifier.submit();
      expect(resultEmpty, isFalse);
      expect(
        container.read(weightEntryViewModelProvider).weightError,
        equals('Please enter a weight'),
      );

      notifier.onWeightChanged('10.0'); // < minWeightKg (20.0)
      final resultTooLow = await notifier.submit();
      expect(resultTooLow, isFalse);
      expect(
        container.read(weightEntryViewModelProvider).weightError,
        contains('Weight must be between'),
      );

      notifier.onWeightChanged('350.0'); // > maxWeightKg (300.0)
      final resultTooHigh = await notifier.submit();
      expect(resultTooHigh, isFalse);
      expect(
        container.read(weightEntryViewModelProvider).weightError,
        contains('Weight must be between'),
      );
    },
  );

  test(
    'submit fails validation when selected date is out of allowed range',
    () async {
      final notifier = container.read(weightEntryViewModelProvider.notifier);
      notifier.onWeightChanged('75.0');

      // Future date
      notifier.onDateChanged(DateTime.now().add(const Duration(days: 2)));
      final resultFuture = await notifier.submit();
      expect(resultFuture, isFalse);
      expect(
        container.read(weightEntryViewModelProvider).dateError,
        equals('Date cannot be in the future'),
      );

      // More than 365 days ago
      notifier.onDateChanged(
        DateTime.now().subtract(const Duration(days: 370)),
      );
      final resultOld = await notifier.submit();
      expect(resultOld, isFalse);
      expect(
        container.read(weightEntryViewModelProvider).dateError,
        equals('Date cannot be more than 365 days in the past'),
      );
    },
  );

  test(
    'submit prompts for overwrite when entry already exists for selected date',
    () async {
      final conflictDate = DateTime.now().subtract(const Duration(days: 1));
      final dateIso = WeekDateUtils.toIsoDateString(conflictDate);
      final existingEntry = WeightEntryEntity(
        dateIso: dateIso,
        date: WeekDateUtils.normalizeDateUtc(conflictDate),
        weightKg: 78.0,
        updatedAt: DateTime.now().toUtc(),
      );
      fakeWeightRepository.seedEntries(testUser.id, [existingEntry]);

      // Pre-populate weightHistoryViewModelProvider so conflict is detected
      await container
          .read(weightHistoryViewModelProvider.notifier)
          .loadEntries();

      final notifier = container.read(weightEntryViewModelProvider.notifier);
      notifier.onDateChanged(conflictDate);
      notifier.onWeightChanged('79.5');

      final result = await notifier.submit(confirmOverwrite: false);
      expect(result, isFalse);

      final state = container.read(weightEntryViewModelProvider);
      expect(state.requiresOverwriteConfirmation, isTrue);
      expect(state.existingEntryForDate, equals(existingEntry));

      // Canceling overwrite confirmation
      notifier.cancelOverwriteConfirmation();
      final afterCancel = container.read(weightEntryViewModelProvider);
      expect(afterCancel.requiresOverwriteConfirmation, isFalse);
      expect(afterCancel.existingEntryForDate, isNull);
    },
  );

  test(
    'submit overwrites existing entry when confirmOverwrite is true',
    () async {
      final conflictDate = DateTime.now().subtract(const Duration(days: 1));
      final dateIso = WeekDateUtils.toIsoDateString(conflictDate);
      final existingEntry = WeightEntryEntity(
        dateIso: dateIso,
        date: WeekDateUtils.normalizeDateUtc(conflictDate),
        weightKg: 78.0,
        updatedAt: DateTime.now().toUtc(),
      );
      fakeWeightRepository.seedEntries(testUser.id, [existingEntry]);
      await container
          .read(weightHistoryViewModelProvider.notifier)
          .loadEntries();

      final notifier = container.read(weightEntryViewModelProvider.notifier);
      notifier.onDateChanged(conflictDate);
      notifier.onWeightChanged('79.5');

      final result = await notifier.submit(confirmOverwrite: true);
      expect(result, isTrue);

      final state = container.read(weightEntryViewModelProvider);
      expect(state.status, equals(FormStatus.success));
      expect(state.requiresOverwriteConfirmation, isFalse);

      // Verify repository was updated
      final updatedEntries = fakeWeightRepository.getEntriesForUser(
        testUser.id,
      );
      expect(updatedEntries.length, equals(1));
      expect(updatedEntries.first.weightKg, equals(79.5));

      // Verify weightHistory was refreshed
      final historyState =
          container.read(weightHistoryViewModelProvider) as WeightHistoryLoaded;
      expect(historyState.entries.first.weightKg, equals(79.5));
    },
  );

  for (final historyStatus in ['initial', 'loading', 'error']) {
    for (final confirmOverwrite in [false, true]) {
      test(
        'blocks save with $historyStatus history and confirm=$confirmOverwrite',
        () async {
          final today = WeekDateUtils.normalizeDateUtc(DateTime.now());
          final existing = WeightEntryEntity(
            dateIso: WeekDateUtils.toIsoDateString(today),
            date: today,
            weightKg: 78,
            updatedAt: today,
          );
          fakeWeightRepository.seedEntries(testUser.id, [existing]);
          final history = container.read(
            weightHistoryViewModelProvider.notifier,
          );
          Future<void>? loading;
          if (historyStatus == 'error') {
            fakeWeightRepository.getFailure = const NetworkFailure('Offline');
            await history.loadEntries();
            expect(
              container.read(weightHistoryViewModelProvider),
              isA<WeightHistoryError>(),
            );
          } else if (historyStatus == 'loading') {
            loading = history.loadEntries();
            expect(
              container.read(weightHistoryViewModelProvider),
              isA<WeightHistoryLoading>(),
            );
          } else {
            expect(
              container.read(weightHistoryViewModelProvider),
              isA<WeightHistoryInitial>(),
            );
          }

          final notifier = container.read(
            weightEntryViewModelProvider.notifier,
          );
          notifier.onWeightChanged('80');
          expect(
            await notifier.submit(confirmOverwrite: confirmOverwrite),
            isFalse,
          );
          expect(fakeWeightRepository.getEntriesForUser(testUser.id), [
            existing,
          ]);
          expect(
            container.read(weightEntryViewModelProvider).errorMessage,
            'Load weight history before saving. Please try again.',
          );
          if (loading != null) await loading;

          // Once history is available, the existing confirmation flow resumes.
          fakeWeightRepository.getFailure = null;
          await history.loadEntries();
          expect(await notifier.submit(), isFalse);
          expect(
            container
                .read(weightEntryViewModelProvider)
                .requiresOverwriteConfirmation,
            isTrue,
          );
        },
      );
    }
  }

  test('submit successfully saves new entry without conflict', () async {
    await container.read(weightHistoryViewModelProvider.notifier).loadEntries();
    final entryDate = DateTime.now().subtract(const Duration(days: 3));
    final notifier = container.read(weightEntryViewModelProvider.notifier);
    notifier.onDateChanged(entryDate);
    notifier.onWeightChanged('72.50');

    final result = await notifier.submit();
    expect(result, isTrue);

    final state = container.read(weightEntryViewModelProvider);
    expect(state.status, equals(FormStatus.success));
    expect(state.errorMessage, isNull);

    final entries = fakeWeightRepository.getEntriesForUser(testUser.id);
    expect(entries.length, equals(1));
    expect(entries.first.weightKg, equals(72.5));
  });

  test('submit transitions to failure on repository error', () async {
    await container.read(weightHistoryViewModelProvider.notifier).loadEntries();
    fakeWeightRepository.saveFailure = const ServerFailure(
      'Database save failed',
    );

    final notifier = container.read(weightEntryViewModelProvider.notifier);
    notifier.onWeightChanged('80.0');

    final result = await notifier.submit();
    expect(result, isFalse);

    final state = container.read(weightEntryViewModelProvider);
    expect(state.status, equals(FormStatus.failure));
    expect(state.errorMessage, equals('Database save failed'));
  });
}
