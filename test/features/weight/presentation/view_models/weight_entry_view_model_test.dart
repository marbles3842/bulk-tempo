import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/form_status.dart';
import 'package:bulk_tempo/features/weight/data/repositories/weight_repository_impl.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_entry_form_state.dart';
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

  WeightEntryEntity createTestEntry({
    required String dateIso,
    required double weightKg,
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

  group('Add mode (existing contracts)', () {
    test(
      'initial state has empty weight, default date, and initial status',
      () {
        final state = container.read(weightEntryViewModelProvider);
        expect(state.weightInput, isEmpty);
        expect(state.status, equals(FormStatus.initial));
        expect(state.weightError, isNull);
        expect(state.dateError, isNull);
        expect(state.errorMessage, isNull);
        expect(state.requiresOverwriteConfirmation, isFalse);
        expect(state.existingEntryForDate, isNull);
        expect(state.isEdit, isFalse);
        expect(state.originalEntry, isNull);
        expect(state.pendingAction, isNull);
        expect(state.outcome, isNull);
        expect(state.isDirty, isFalse);
      },
    );

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
        final existingEntry = createTestEntry(dateIso: dateIso, weightKg: 78.0);
        fakeWeightRepository.seedEntries(testUser.id, [existingEntry]);

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
        final existingEntry = createTestEntry(dateIso: dateIso, weightKg: 78.0);
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
        expect(state.outcome, equals(WeightEntryOutcome.saved));
        expect(state.requiresOverwriteConfirmation, isFalse);

        final updatedEntries = fakeWeightRepository.getEntriesForUser(
          testUser.id,
        );
        expect(updatedEntries.length, equals(1));
        expect(updatedEntries.first.weightKg, equals(79.5));

        final historyState =
            container.read(weightHistoryViewModelProvider)
                as WeightHistoryLoaded;
        expect(historyState.entries.first.weightKg, equals(79.5));
      },
    );

    for (final historyStatus in ['initial', 'loading', 'error']) {
      for (final confirmOverwrite in [false, true]) {
        test(
          'blocks save with $historyStatus history and confirm=$confirmOverwrite',
          () async {
            final today = WeekDateUtils.normalizeDateUtc(DateTime.now());
            final existing = createTestEntry(
              dateIso: WeekDateUtils.toIsoDateString(today),
              weightKg: 78.0,
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
      await container
          .read(weightHistoryViewModelProvider.notifier)
          .loadEntries();
      final entryDate = DateTime.now().subtract(const Duration(days: 3));
      final notifier = container.read(weightEntryViewModelProvider.notifier);
      notifier.onDateChanged(entryDate);
      notifier.onWeightChanged('72.50');

      final result = await notifier.submit();
      expect(result, isTrue);

      final state = container.read(weightEntryViewModelProvider);
      expect(state.status, equals(FormStatus.success));
      expect(state.outcome, equals(WeightEntryOutcome.saved));
      expect(state.errorMessage, isNull);

      final entries = fakeWeightRepository.getEntriesForUser(testUser.id);
      expect(entries.length, equals(1));
      expect(entries.first.weightKg, equals(72.5));
    });

    test('submit transitions to failure on repository error', () async {
      await container
          .read(weightHistoryViewModelProvider.notifier)
          .loadEntries();
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
      expect(state.weightInput, equals('80.0')); // input preserved
    });
  });

  group('Correction session initialization & reset', () {
    test(
      'initializeEdit prefills two-decimal weight, captures immutable original entry and date',
      () {
        final existing = createTestEntry(dateIso: '2025-01-15', weightKg: 80.0);
        final notifier = container.read(weightEntryViewModelProvider.notifier);

        notifier.initializeEdit(existing, userId: testUser.id);

        final state = container.read(weightEntryViewModelProvider);
        expect(state.isEdit, isTrue);
        expect(state.originalEntry, equals(existing));
        expect(state.fixedDateIso, equals('2025-01-15'));
        expect(state.fixedDate, equals(existing.date));
        expect(state.weightInput, equals('80.00'));
        expect(state.openingUserId, equals(testUser.id));
        expect(state.status, equals(FormStatus.initial));
        expect(state.weightError, isNull);
        expect(state.dateError, isNull);
        expect(state.errorMessage, isNull);
        expect(state.requiresOverwriteConfirmation, isFalse);
        expect(state.isDirty, isFalse);
      },
    );

    test(
      'reopening for Add after Edit resets state and does not leak inputs',
      () {
        final existing = createTestEntry(dateIso: '2025-01-15', weightKg: 80.0);
        final notifier = container.read(weightEntryViewModelProvider.notifier);
        notifier.initializeEdit(existing);
        notifier.onWeightChanged('85.50');

        // Now reopen for Add
        notifier.initializeAdd(userId: testUser.id);

        final state = container.read(weightEntryViewModelProvider);
        expect(state.isEdit, isFalse);
        expect(state.originalEntry, isNull);
        expect(state.weightInput, isEmpty);
        expect(state.status, equals(FormStatus.initial));
        expect(state.weightError, isNull);
        expect(state.errorMessage, isNull);
        expect(state.requiresOverwriteConfirmation, isFalse);
        expect(state.isDirty, isFalse);
      },
    );

    test(
      'reset clears all errors, terminal status, and returns to initial Add state',
      () {
        final notifier = container.read(weightEntryViewModelProvider.notifier);
        notifier.onWeightChanged('invalid');
        notifier.initializeAdd();

        final state = container.read(weightEntryViewModelProvider);
        expect(state.weightInput, isEmpty);
        expect(state.status, equals(FormStatus.initial));
        expect(state.weightError, isNull);
      },
    );
  });

  group('Edit mode date immutability & validation', () {
    test('onDateChanged is ignored in edit mode', () {
      final existing = createTestEntry(dateIso: '2025-01-15', weightKg: 79.0);
      final notifier = container.read(weightEntryViewModelProvider.notifier);
      notifier.initializeEdit(existing);

      notifier.onDateChanged(DateTime.utc(2026, 6, 1));

      final state = container.read(weightEntryViewModelProvider);
      expect(state.selectedDate, equals(existing.date));
      expect(state.fixedDateIso, equals('2025-01-15'));
    });

    test(
      'submit in edit mode saves at original date even if older than 365 days',
      () async {
        final oldDateIso = '2024-01-10'; // > 2 years in the past
        final existing = createTestEntry(dateIso: oldDateIso, weightKg: 75.0);
        fakeWeightRepository.seedEntries(testUser.id, [existing]);
        await container
            .read(weightHistoryViewModelProvider.notifier)
            .loadEntries();

        final notifier = container.read(weightEntryViewModelProvider.notifier);
        notifier.initializeEdit(existing);
        notifier.onWeightChanged('77.50');

        final success = await notifier.submit();
        expect(success, isTrue);

        final state = container.read(weightEntryViewModelProvider);
        expect(state.status, equals(FormStatus.success));
        expect(state.outcome, equals(WeightEntryOutcome.saved));

        final saved = fakeWeightRepository.getEntriesForUser(testUser.id);
        expect(saved.length, equals(1));
        expect(saved.first.dateIso, equals(oldDateIso));
        expect(saved.first.weightKg, equals(77.5));
      },
    );

    test(
      'submit in edit mode bypasses overwrite-self confirmation prompt',
      () async {
        final existing = createTestEntry(dateIso: '2026-10-01', weightKg: 80.0);
        fakeWeightRepository.seedEntries(testUser.id, [existing]);
        await container
            .read(weightHistoryViewModelProvider.notifier)
            .loadEntries();

        final notifier = container.read(weightEntryViewModelProvider.notifier);
        notifier.initializeEdit(existing);
        notifier.onWeightChanged('81.00');

        // submit without confirmOverwrite should succeed immediately without prompt
        final success = await notifier.submit(confirmOverwrite: false);
        expect(success, isTrue);

        final state = container.read(weightEntryViewModelProvider);
        expect(state.requiresOverwriteConfirmation, isFalse);
        expect(state.status, equals(FormStatus.success));
      },
    );
  });

  group('Dirty state equivalence', () {
    test(
      'treats equivalent inputs 80, 80.00, 80,00 as unchanged (not dirty)',
      () {
        final existing = createTestEntry(dateIso: '2026-10-01', weightKg: 80.0);
        final notifier = container.read(weightEntryViewModelProvider.notifier);
        notifier.initializeEdit(existing);

        expect(container.read(weightEntryViewModelProvider).isDirty, isFalse);

        notifier.onWeightChanged('80');
        expect(container.read(weightEntryViewModelProvider).isDirty, isFalse);

        notifier.onWeightChanged('80.00');
        expect(container.read(weightEntryViewModelProvider).isDirty, isFalse);

        notifier.onWeightChanged('80,00');
        expect(container.read(weightEntryViewModelProvider).isDirty, isFalse);

        notifier.onWeightChanged('80,0');
        expect(container.read(weightEntryViewModelProvider).isDirty, isFalse);

        notifier.onWeightChanged(' 80.00 ');
        expect(container.read(weightEntryViewModelProvider).isDirty, isFalse);
      },
    );

    test('marks changed valid weight as dirty', () {
      final existing = createTestEntry(dateIso: '2026-10-01', weightKg: 80.0);
      final notifier = container.read(weightEntryViewModelProvider.notifier);
      notifier.initializeEdit(existing);

      notifier.onWeightChanged('80.05');
      expect(container.read(weightEntryViewModelProvider).isDirty, isTrue);

      notifier.onWeightChanged('81');
      expect(container.read(weightEntryViewModelProvider).isDirty, isTrue);
    });

    test('marks changed empty or invalid draft as dirty', () {
      final existing = createTestEntry(dateIso: '2026-10-01', weightKg: 80.0);
      final notifier = container.read(weightEntryViewModelProvider.notifier);
      notifier.initializeEdit(existing);

      notifier.onWeightChanged('');
      expect(container.read(weightEntryViewModelProvider).isDirty, isTrue);

      notifier.onWeightChanged('   ');
      expect(container.read(weightEntryViewModelProvider).isDirty, isTrue);

      notifier.onWeightChanged('abc');
      expect(container.read(weightEntryViewModelProvider).isDirty, isTrue);

      notifier.onWeightChanged('80.123'); // > 2 decimal places
      expect(container.read(weightEntryViewModelProvider).isDirty, isTrue);
    });
  });

  group('Delete command', () {
    test('delete returns false when called in Add mode', () async {
      final notifier = container.read(weightEntryViewModelProvider.notifier);
      notifier.initializeAdd();

      final result = await notifier.delete();
      expect(result, isFalse);
    });

    test(
      'delete ignores unsaved draft validity and deletes original date target',
      () async {
        final existing = createTestEntry(dateIso: '2026-10-01', weightKg: 80.0);
        fakeWeightRepository.seedEntries(testUser.id, [existing]);
        await container
            .read(weightHistoryViewModelProvider.notifier)
            .loadEntries();

        final notifier = container.read(weightEntryViewModelProvider.notifier);
        notifier.initializeEdit(existing);

        // User typed an invalid or empty draft weight
        notifier.onWeightChanged('invalid weight');

        final result = await notifier.delete();
        expect(result, isTrue);

        final state = container.read(weightEntryViewModelProvider);
        expect(state.status, equals(FormStatus.success));
        expect(state.outcome, equals(WeightEntryOutcome.deleted));

        // Entry is removed from repository
        expect(fakeWeightRepository.getEntriesForUser(testUser.id), isEmpty);

        // History reflects deletion immediately
        final historyState =
            container.read(weightHistoryViewModelProvider)
                as WeightHistoryLoaded;
        expect(historyState.hasEntryForDate('2026-10-01'), isFalse);
      },
    );

    test(
      'delete failure preserves state and sets FormStatus.failure',
      () async {
        final existing = createTestEntry(dateIso: '2026-10-01', weightKg: 80.0);
        fakeWeightRepository.seedEntries(testUser.id, [existing]);
        fakeWeightRepository.deleteFailure = const ServerFailure(
          'Delete failed',
        );

        final notifier = container.read(weightEntryViewModelProvider.notifier);
        notifier.initializeEdit(existing);
        notifier.onWeightChanged('79.0');

        final result = await notifier.delete();
        expect(result, isFalse);

        final state = container.read(weightEntryViewModelProvider);
        expect(state.status, equals(FormStatus.failure));
        expect(state.errorMessage, equals('Delete failed'));
        expect(state.weightInput, equals('79.0')); // input preserved
      },
    );
  });

  group('Reentrant calls and controlled async races', () {
    test('rejects concurrent repeat-tap during submit', () async {
      await container
          .read(weightHistoryViewModelProvider.notifier)
          .loadEntries();

      final completer = Completer<void>();
      fakeWeightRepository.saveCompleter = completer;

      final notifier = container.read(weightEntryViewModelProvider.notifier);
      notifier.onWeightChanged('75.0');

      final firstFuture = notifier.submit();
      expect(
        container.read(weightEntryViewModelProvider).status,
        equals(FormStatus.submitting),
      );
      expect(container.read(weightEntryViewModelProvider).isSaving, isTrue);

      // Reentrant second call
      final secondResult = await notifier.submit();
      expect(secondResult, isFalse);

      // Reentrant delete call
      final deleteResult = await notifier.delete();
      expect(deleteResult, isFalse);

      // Complete the first call
      completer.complete();
      expect(await firstFuture, isTrue);
    });

    test('rejects concurrent repeat-tap during delete', () async {
      final existing = createTestEntry(dateIso: '2026-10-01', weightKg: 80.0);
      fakeWeightRepository.seedEntries(testUser.id, [existing]);

      final completer = Completer<void>();
      fakeWeightRepository.deleteCompleter = completer;

      final notifier = container.read(weightEntryViewModelProvider.notifier);
      notifier.initializeEdit(existing);

      final firstFuture = notifier.delete();
      expect(
        container.read(weightEntryViewModelProvider).status,
        equals(FormStatus.submitting),
      );
      expect(container.read(weightEntryViewModelProvider).isDeleting, isTrue);

      // Reentrant second call
      final secondResult = await notifier.delete();
      expect(secondResult, isFalse);

      final submitResult = await notifier.submit();
      expect(submitResult, isFalse);

      completer.complete();
      expect(await firstFuture, isTrue);
    });

    test(
      'account switch during in-flight save suppresses form and history effects',
      () async {
        await container
            .read(weightHistoryViewModelProvider.notifier)
            .loadEntries();

        final completer = Completer<void>();
        fakeWeightRepository.saveCompleter = completer;

        final notifier = container.read(weightEntryViewModelProvider.notifier);
        notifier.onWeightChanged('77.0');

        final future = notifier.submit();

        // Switch active account before write completes
        fakeAuthRepository.setCurrentUser(
          const UserEntity(id: 'u2', email: 'other@example.com'),
        );

        completer.complete();
        final result = await future;
        expect(result, isFalse);

        // History for testUser was not touched on current container
        final historyState = container.read(weightHistoryViewModelProvider);
        expect(historyState, isA<WeightHistoryInitial>());
      },
    );

    test('disposal during in-flight save is inert', () async {
      final completer = Completer<void>();
      fakeWeightRepository.saveCompleter = completer;

      final localContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
          weightRepositoryProvider.overrideWithValue(fakeWeightRepository),
        ],
      );
      addTearDown(localContainer.dispose);
      localContainer.listen(weightHistoryViewModelProvider, (_, _) {});
      localContainer.listen(weightEntryViewModelProvider, (_, _) {});
      await localContainer
          .read(weightHistoryViewModelProvider.notifier)
          .loadEntries();

      final notifier = localContainer.read(
        weightEntryViewModelProvider.notifier,
      );
      notifier.onWeightChanged('78.0');

      final future = notifier.submit();

      // Dispose container before repository completes
      localContainer.dispose();
      completer.complete();

      // Should complete gracefully without unhandled exceptions
      final result = await future;
      expect(result, isFalse);
    });
  });
}
