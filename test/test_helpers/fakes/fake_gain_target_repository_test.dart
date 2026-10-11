import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';

import 'fake_gain_target_repository.dart';

void main() {
  late FakeGainTargetRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeGainTargetRepository();
  });

  group('FakeGainTargetRepository', () {
    const target1 = GainTargetEntity(
      minWeeklyGainKg: 0.15,
      maxWeeklyGainKg: 0.25,
    );
    const target2 = GainTargetEntity(
      minWeeklyGainKg: 0.2,
      maxWeeklyGainKg: 0.4,
    );

    test('returns null when no target is set for user', () async {
      final result = await fakeRepo.getGainTarget(userId: 'user_a');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isNull);
    });

    test('isolates targets per userId', () async {
      await fakeRepo.saveGainTarget(userId: 'user_a', target: target1);
      await fakeRepo.saveGainTarget(userId: 'user_b', target: target2);

      final resultA = await fakeRepo.getGainTarget(userId: 'user_a');
      final resultB = await fakeRepo.getGainTarget(userId: 'user_b');

      expect(resultA.dataOrNull, equals(target1));
      expect(resultB.dataOrNull, equals(target2));
      expect(fakeRepo.getTargetForUser('user_a'), equals(target1));
      expect(fakeRepo.getTargetForUser('user_b'), equals(target2));
    });

    test('seedTarget seeds data without save call', () async {
      fakeRepo.seedTarget('user_seeded', target1);

      final result = await fakeRepo.getGainTarget(userId: 'user_seeded');
      expect(result.dataOrNull, equals(target1));
    });

    test('getFailure triggers failure on getGainTarget', () async {
      fakeRepo.getFailure = const ServerFailure('Database error');

      final result = await fakeRepo.getGainTarget(userId: 'user_a');
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());

      // Persistent failure until cleared
      final result2 = await fakeRepo.getGainTarget(userId: 'user_a');
      expect(result2.isFailure, isTrue);
    });

    test('saveFailure triggers failure on saveGainTarget', () async {
      fakeRepo.saveFailure = const NetworkFailure('No connection');

      final result = await fakeRepo.saveGainTarget(
        userId: 'user_a',
        target: target1,
      );
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('nextFailure triggers once and resets', () async {
      fakeRepo.nextFailure = const AuthFailure('Unauthorized');

      final result1 = await fakeRepo.getGainTarget(userId: 'user_a');
      expect(result1.isFailure, isTrue);
      expect(result1.failureOrNull, isA<AuthFailure>());

      final result2 = await fakeRepo.getGainTarget(userId: 'user_a');
      expect(result2.isSuccess, isTrue);
    });

    test('reset clears targets and failures', () async {
      fakeRepo.seedTarget('user_a', target1);
      fakeRepo.getFailure = const ServerFailure('Error');
      fakeRepo.saveFailure = const NetworkFailure('Error');
      fakeRepo.nextFailure = const AuthFailure('Error');

      fakeRepo.reset();

      expect(fakeRepo.getTargetForUser('user_a'), isNull);
      final result = await fakeRepo.getGainTarget(userId: 'user_a');
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isNull);
    });
  });
}
