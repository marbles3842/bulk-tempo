import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/result/result.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';

import 'fake_auth_repository.dart';

void main() {
  late FakeAuthRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeAuthRepository();
  });

  tearDown(() {
    fakeRepo.dispose();
  });

  group('FakeAuthRepository', () {
    test(
      'initial state has null currentUser and emits null on authStateChanges',
      () async {
        expect(fakeRepo.currentUser, isNull);
        expect(await fakeRepo.authStateChanges().first, isNull);
      },
    );

    test(
      'initialUser constructor sets currentUser and emits initialUser',
      () async {
        const initialUser = UserEntity(id: 'u1', email: 'test@example.com');
        final repoWithUser = FakeAuthRepository(initialUser: initialUser);

        expect(repoWithUser.currentUser, initialUser);
        expect(await repoWithUser.authStateChanges().first, initialUser);
        repoWithUser.dispose();
      },
    );

    test(
      'signUpWithEmailAndPassword creates user, updates currentUser and emits',
      () async {
        final emitted = <UserEntity?>[];
        final sub = fakeRepo.authStateChanges().listen(emitted.add);

        final result = await fakeRepo.signUpWithEmailAndPassword(
          email: 'new@example.com',
          password: 'password123',
        );

        expect(result, isA<Success<UserEntity, AppFailure>>());
        final user = (result as Success<UserEntity, AppFailure>).data;
        expect(user.email, 'new@example.com');
        expect(fakeRepo.currentUser, user);

        await pumpEventQueue();
        expect(emitted, contains(user));
        await sub.cancel();
      },
    );

    test('signUpWithEmailAndPassword fails if email already exists', () async {
      await fakeRepo.signUpWithEmailAndPassword(
        email: 'exists@example.com',
        password: 'password123',
      );

      final result = await fakeRepo.signUpWithEmailAndPassword(
        email: 'exists@example.com',
        password: 'newpassword',
      );

      expect(result, isA<Failure<UserEntity, AppFailure>>());
      final failure = (result as Failure<UserEntity, AppFailure>).failure;
      expect(failure, isA<AuthFailure>());
      expect(failure.message, 'An account with this email already exists');
    });

    test(
      'signInWithEmailAndPassword succeeds with valid credentials',
      () async {
        await fakeRepo.signUpWithEmailAndPassword(
          email: 'user@example.com',
          password: 'password123',
        );
        await fakeRepo.signOut();

        final result = await fakeRepo.signInWithEmailAndPassword(
          email: 'user@example.com',
          password: 'password123',
        );

        expect(result, isA<Success<UserEntity, AppFailure>>());
        expect(fakeRepo.currentUser?.email, 'user@example.com');
      },
    );

    test(
      'signInWithEmailAndPassword fails with wrong password or unknown email',
      () async {
        await fakeRepo.signUpWithEmailAndPassword(
          email: 'user@example.com',
          password: 'password123',
        );

        final wrongPassResult = await fakeRepo.signInWithEmailAndPassword(
          email: 'user@example.com',
          password: 'wrongpassword',
        );
        expect(wrongPassResult, isA<Failure<UserEntity, AppFailure>>());
        expect(
          (wrongPassResult as Failure<UserEntity, AppFailure>).failure.message,
          'Invalid email or password',
        );

        final unknownUserResult = await fakeRepo.signInWithEmailAndPassword(
          email: 'nobody@example.com',
          password: 'password123',
        );
        expect(unknownUserResult, isA<Failure<UserEntity, AppFailure>>());
        expect(
          (unknownUserResult as Failure<UserEntity, AppFailure>)
              .failure
              .message,
          'Invalid email or password',
        );
      },
    );

    test('signOut clears currentUser and emits null', () async {
      await fakeRepo.signUpWithEmailAndPassword(
        email: 'user@example.com',
        password: 'password123',
      );
      expect(fakeRepo.currentUser, isNotNull);

      final result = await fakeRepo.signOut();
      expect(result, isA<Success<void, AppFailure>>());
      expect(fakeRepo.currentUser, isNull);
    });

    test('controllable failure triggers override operations', () async {
      const customFailure = ServerFailure('Custom error');
      fakeRepo.nextFailure = customFailure;

      final result = await fakeRepo.signUpWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password',
      );
      expect(result, isA<Failure<UserEntity, AppFailure>>());
      expect(
        (result as Failure<UserEntity, AppFailure>).failure,
        customFailure,
      );

      // nextFailure resets after one use
      fakeRepo.signInFailure = const NetworkFailure('No internet');
      final signInResult = await fakeRepo.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password',
      );
      expect(signInResult, isA<Failure<UserEntity, AppFailure>>());
      expect(
        (signInResult as Failure<UserEntity, AppFailure>).failure,
        isA<NetworkFailure>(),
      );
    });

    test('setCurrentUser updates currentUser and emits', () async {
      const user = UserEntity(id: 'manual_1', email: 'manual@example.com');
      fakeRepo.setCurrentUser(user);

      expect(fakeRepo.currentUser, user);
      expect(await fakeRepo.authStateChanges().first, user);
    });

    test('reset clears all state', () async {
      await fakeRepo.signUpWithEmailAndPassword(
        email: 'reset@example.com',
        password: 'password',
      );
      fakeRepo.reset();

      expect(fakeRepo.currentUser, isNull);
      final result = await fakeRepo.signInWithEmailAndPassword(
        email: 'reset@example.com',
        password: 'password',
      );
      expect(result, isA<Failure<UserEntity, AppFailure>>());
    });
  });
}
