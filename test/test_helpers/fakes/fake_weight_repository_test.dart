import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';

import 'fake_weight_repository.dart';

void main() {
  late FakeWeightRepository repository;

  setUp(() {
    repository = FakeWeightRepository();
  });

  group('FakeWeightRepository', () {
    test('returns empty list for user with no entries', () async {
      final result = await repository.getWeightEntries(userId: 'user_1');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isEmpty);
    });

    test('isolates entries strictly between different users', () async {
      final user1Entry = WeightEntryEntity(
        dateIso: '2026-10-10',
        date: DateTime.utc(2026, 10, 10),
        weightKg: 82.5,
        updatedAt: DateTime.utc(2026, 10, 10, 8),
      );
      final user2Entry = WeightEntryEntity(
        dateIso: '2026-10-10',
        date: DateTime.utc(2026, 10, 10),
        weightKg: 75.0,
        updatedAt: DateTime.utc(2026, 10, 10, 8),
      );

      await repository.saveWeightEntry(userId: 'user_1', entry: user1Entry);
      await repository.saveWeightEntry(userId: 'user_2', entry: user2Entry);

      final user1Result = await repository.getWeightEntries(userId: 'user_1');
      final user2Result = await repository.getWeightEntries(userId: 'user_2');

      expect(user1Result.dataOrNull?.length, 1);
      expect(user1Result.dataOrNull?.first.weightKg, 82.5);

      expect(user2Result.dataOrNull?.length, 1);
      expect(user2Result.dataOrNull?.first.weightKg, 75.0);
    });

    test('overwrites existing entry on the same dateIso for a user', () async {
      final entry1 = WeightEntryEntity(
        dateIso: '2026-10-10',
        date: DateTime.utc(2026, 10, 10),
        weightKg: 82.5,
        updatedAt: DateTime.utc(2026, 10, 10, 8),
      );
      final updatedEntry = WeightEntryEntity(
        dateIso: '2026-10-10',
        date: DateTime.utc(2026, 10, 10),
        weightKg: 83.0,
        updatedAt: DateTime.utc(2026, 10, 10, 12),
      );

      await repository.saveWeightEntry(userId: 'user_1', entry: entry1);
      await repository.saveWeightEntry(userId: 'user_1', entry: updatedEntry);

      final result = await repository.getWeightEntries(userId: 'user_1');
      expect(result.dataOrNull?.length, 1);
      expect(result.dataOrNull?.first.weightKg, 83.0);
      expect(
        result.dataOrNull?.first.updatedAt,
        DateTime.utc(2026, 10, 10, 12),
      );
    });

    test('returns entries sorted descending by dateIso', () async {
      final entry1 = WeightEntryEntity(
        dateIso: '2026-10-01',
        date: DateTime.utc(2026, 10, 1),
        weightKg: 80.0,
        updatedAt: DateTime.utc(2026, 10, 1),
      );
      final entry2 = WeightEntryEntity(
        dateIso: '2026-10-05',
        date: DateTime.utc(2026, 10, 5),
        weightKg: 81.0,
        updatedAt: DateTime.utc(2026, 10, 5),
      );
      final entry3 = WeightEntryEntity(
        dateIso: '2026-09-25',
        date: DateTime.utc(2026, 9, 25),
        weightKg: 79.5,
        updatedAt: DateTime.utc(2026, 9, 25),
      );

      repository.seedEntries('user_1', [entry1, entry2, entry3]);

      final result = await repository.getWeightEntries(userId: 'user_1');
      final dates = result.dataOrNull?.map((e) => e.dateIso).toList();
      expect(dates, ['2026-10-05', '2026-10-01', '2026-09-25']);
    });

    test(
      'returns failures when nextFailure, getFailure, or saveFailure are set',
      () async {
        repository.nextFailure = const NetworkFailure('Network offline');
        final fail1 = await repository.getWeightEntries(userId: 'user_1');
        expect(fail1.isFailure, isTrue);
        expect(fail1.failureOrNull?.message, 'Network offline');

        // nextFailure is one-shot
        final successAfter = await repository.getWeightEntries(
          userId: 'user_1',
        );
        expect(successAfter.isSuccess, isTrue);

        repository.saveFailure = const ServerFailure('Database error');
        final saveResult = await repository.saveWeightEntry(
          userId: 'user_1',
          entry: WeightEntryEntity(
            dateIso: '2026-10-10',
            date: DateTime.utc(2026, 10, 10),
            weightKg: 80.0,
            updatedAt: DateTime.utc(2026, 10, 10),
          ),
        );
        expect(saveResult.isFailure, isTrue);
        expect(saveResult.failureOrNull?.message, 'Database error');
      },
    );

    test('reset clears entries and failures', () async {
      repository.seedEntries('user_1', [
        WeightEntryEntity(
          dateIso: '2026-10-10',
          date: DateTime.utc(2026, 10, 10),
          weightKg: 80.0,
          updatedAt: DateTime.utc(2026, 10, 10),
        ),
      ]);
      repository.getFailure = const ServerFailure('Error');

      repository.reset();

      final result = await repository.getWeightEntries(userId: 'user_1');
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isEmpty);
    });
  });

  group('FakeWeightRepository.deleteWeightEntry', () {
    final oldEntry = WeightEntryEntity(
      dateIso: '2000-02-29',
      date: DateTime.utc(2000, 2, 29),
      weightKg: 80,
      updatedAt: DateTime.utc(2000, 2, 29),
    );
    final recentEntry = WeightEntryEntity(
      dateIso: '2026-10-10',
      date: DateTime.utc(2026, 10, 10),
      weightKg: 82,
      updatedAt: DateTime.utc(2026, 10, 10),
    );

    setUp(() {
      repository.seedEntries('user_1', [oldEntry, recentEntry]);
      repository.seedEntries('user_2', [oldEntry]);
    });

    test(
      'deletes an old entry while preserving other dates and accounts',
      () async {
        final result = await repository.deleteWeightEntry(
          userId: 'user_1',
          dateIso: oldEntry.dateIso,
        );
        expect(result.isSuccess, isTrue);
        expect(repository.getEntriesForUser('user_1'), [recentEntry]);
        expect(repository.getEntriesForUser('user_2'), [oldEntry]);
      },
    );

    test(
      'succeeds for absent dates and accounts and repeated deletion',
      () async {
        for (final userId in ['user_1', 'user_1', 'unknown']) {
          final result = await repository.deleteWeightEntry(
            userId: userId,
            dateIso: oldEntry.dateIso,
          );
          expect(result.isSuccess, isTrue);
        }
        expect(repository.getEntriesForUser('user_1'), [recentEntry]);
        expect(repository.getEntriesForUser('user_2'), [oldEntry]);
        expect(repository.getEntriesForUser('unknown'), isEmpty);
      },
    );

    test(
      'rejects invalid input without changing entries or consuming failures',
      () async {
        repository.nextFailure = const NetworkFailure('Offline');
        for (final input in [
          ('', oldEntry.dateIso),
          ('   ', oldEntry.dateIso),
          ('user_1', ''),
          ('user_1', '2026-02-30'),
          ('user_1', ' 2000-02-29'),
          ('user_1', '2000-02-29 '),
          ('user_1', '2000-2-29'),
          ('user_1', '2000-02-29/other'),
        ]) {
          final result = await repository.deleteWeightEntry(
            userId: input.$1,
            dateIso: input.$2,
          );
          expect(result.failureOrNull, isA<ValidationFailure>());
        }
        expect(repository.nextFailure, const NetworkFailure('Offline'));
        expect(repository.getEntriesForUser('user_1'), [recentEntry, oldEntry]);
        expect(repository.getEntriesForUser('user_2'), [oldEntry]);
      },
    );

    test(
      'delete failure persists, preserves entries and permits retry',
      () async {
        repository.deleteFailure = const ServerFailure('Delete failed');
        for (var attempt = 0; attempt < 2; attempt++) {
          final result = await repository.deleteWeightEntry(
            userId: 'user_1',
            dateIso: oldEntry.dateIso,
          );
          expect(result.failureOrNull, const ServerFailure('Delete failed'));
          expect(repository.getEntriesForUser('user_1'), [
            recentEntry,
            oldEntry,
          ]);
        }
        expect(
          (await repository.getWeightEntries(userId: 'user_1')).isSuccess,
          isTrue,
        );
        repository.deleteFailure = null;
        expect(
          (await repository.deleteWeightEntry(
            userId: 'user_1',
            dateIso: oldEntry.dateIso,
          )).isSuccess,
          isTrue,
        );
        expect(repository.getEntriesForUser('user_1'), [recentEntry]);
        expect(repository.getEntriesForUser('user_2'), [oldEntry]);
      },
    );

    test('nextFailure takes precedence and is consumed once', () async {
      repository.nextFailure = const NetworkFailure('Offline');
      repository.deleteFailure = const ServerFailure('Delete failed');
      final first = await repository.deleteWeightEntry(
        userId: 'user_1',
        dateIso: oldEntry.dateIso,
      );
      expect(first.failureOrNull, const NetworkFailure('Offline'));
      expect(repository.nextFailure, isNull);
      final second = await repository.deleteWeightEntry(
        userId: 'user_1',
        dateIso: oldEntry.dateIso,
      );
      expect(second.failureOrNull, const ServerFailure('Delete failed'));
      expect(repository.getEntriesForUser('user_1'), [recentEntry, oldEntry]);
    });

    test('reset clears every failure and all account entries', () async {
      repository.nextFailure = const NetworkFailure('Offline');
      repository.getFailure = const ServerFailure('Read failed');
      repository.saveFailure = const ServerFailure('Save failed');
      repository.deleteFailure = const ServerFailure('Delete failed');
      repository.reset();
      expect(repository.nextFailure, isNull);
      expect(repository.getFailure, isNull);
      expect(repository.saveFailure, isNull);
      expect(repository.deleteFailure, isNull);
      expect(repository.getEntriesForUser('user_1'), isEmpty);
      expect(repository.getEntriesForUser('user_2'), isEmpty);
      expect(
        (await repository.deleteWeightEntry(
          userId: 'user_1',
          dateIso: oldEntry.dateIso,
        )).isSuccess,
        isTrue,
      );
    });
  });
}
