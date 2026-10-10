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
}
