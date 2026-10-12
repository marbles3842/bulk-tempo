import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/result/result.dart';
import 'package:bulk_tempo/features/auth/data/models/user_dto.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';

import '../../../../test_helpers/mocks.dart';

void main() {
  late MockAuthRemoteDataSource mockDataSource;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(mockDataSource);
  });

  const testDto = UserDto(
    id: 'u_123',
    email: 'user@test.com',
    displayName: 'Test User',
  );

  const testEntity = UserEntity(
    id: 'u_123',
    email: 'user@test.com',
    displayName: 'Test User',
  );

  group('signInWithEmailAndPassword', () {
    test('returns Success with UserEntity when data source succeeds', () async {
      when(
        () => mockDataSource.signInWithEmailAndPassword(
          email: 'user@test.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => testDto);

      final result = await repository.signInWithEmailAndPassword(
        email: 'user@test.com',
        password: 'password123',
      );

      expect(result, isA<Success<UserEntity, AppFailure>>());
      expect((result as Success).data, equals(testEntity));
      verify(
        () => mockDataSource.signInWithEmailAndPassword(
          email: 'user@test.com',
          password: 'password123',
        ),
      ).called(1);
    });

    test('maps user-not-found to AuthFailure with friendly message', () async {
      when(
        () => mockDataSource.signInWithEmailAndPassword(
          email: 'user@test.com',
          password: 'wrong',
        ),
      ).thenThrow(const AuthException('user-not-found', 'Not found'));

      final result = await repository.signInWithEmailAndPassword(
        email: 'user@test.com',
        password: 'wrong',
      );

      expect(result, isA<Failure<UserEntity, AppFailure>>());
      final failure = (result as Failure).failure;
      expect(failure, isA<AuthFailure>());
      expect(failure.message, 'Invalid email or password');
    });

    test('maps wrong-password to AuthFailure with friendly message', () async {
      when(
        () => mockDataSource.signInWithEmailAndPassword(
          email: 'user@test.com',
          password: 'wrong',
        ),
      ).thenThrow(const AuthException('wrong-password', 'Wrong password'));

      final result = await repository.signInWithEmailAndPassword(
        email: 'user@test.com',
        password: 'wrong',
      );

      expect(result, isA<Failure<UserEntity, AppFailure>>());
      final failure = (result as Failure).failure;
      expect(failure, isA<AuthFailure>());
      expect(failure.message, 'Invalid email or password');
    });

    test(
      'maps invalid-credential to AuthFailure with friendly message',
      () async {
        when(
          () => mockDataSource.signInWithEmailAndPassword(
            email: 'user@test.com',
            password: 'wrong',
          ),
        ).thenThrow(
          const AuthException('invalid-credential', 'Invalid credential'),
        );

        final result = await repository.signInWithEmailAndPassword(
          email: 'user@test.com',
          password: 'wrong',
        );

        expect(result, isA<Failure<UserEntity, AppFailure>>());
        final failure = (result as Failure).failure;
        expect(failure, isA<AuthFailure>());
        expect(failure.message, 'Invalid email or password');
      },
    );

    test(
      'maps too-many-requests to AuthFailure with friendly message',
      () async {
        when(
          () => mockDataSource.signInWithEmailAndPassword(
            email: 'user@test.com',
            password: 'wrong',
          ),
        ).thenThrow(
          const AuthException('too-many-requests', 'Too many requests'),
        );

        final result = await repository.signInWithEmailAndPassword(
          email: 'user@test.com',
          password: 'wrong',
        );

        expect(result, isA<Failure<UserEntity, AppFailure>>());
        final failure = (result as Failure).failure;
        expect(failure, isA<AuthFailure>());
        expect(failure.message, 'Too many attempts. Please try again later');
      },
    );

    test('maps generic AuthException to safe fallback message', () async {
      when(
        () => mockDataSource.signInWithEmailAndPassword(
          email: 'user@test.com',
          password: 'wrong',
        ),
      ).thenThrow(
        const AuthException('operation-not-allowed', 'Operation not allowed'),
      );

      final result = await repository.signInWithEmailAndPassword(
        email: 'user@test.com',
        password: 'wrong',
      );

      expect(result, isA<Failure<UserEntity, AppFailure>>());
      final failure = (result as Failure).failure;
      expect(failure, isA<AuthFailure>());
      expect(failure.message, 'Authentication failed. Please try again.');
    });

    test('maps empty message AuthException to safe fallback message', () async {
      when(
        () => mockDataSource.signInWithEmailAndPassword(
          email: 'user@test.com',
          password: 'wrong',
        ),
      ).thenThrow(const AuthException('unknown', ''));

      final result = await repository.signInWithEmailAndPassword(
        email: 'user@test.com',
        password: 'wrong',
      );

      expect(result, isA<Failure<UserEntity, AppFailure>>());
      final failure = (result as Failure).failure;
      expect(failure, isA<AuthFailure>());
      expect(failure.message, 'Authentication failed. Please try again.');
    });

    test('maps NetworkException to NetworkFailure', () async {
      when(
        () => mockDataSource.signInWithEmailAndPassword(
          email: 'user@test.com',
          password: 'password',
        ),
      ).thenThrow(const NetworkException('No connection'));

      final result = await repository.signInWithEmailAndPassword(
        email: 'user@test.com',
        password: 'password',
      );

      expect(result, isA<Failure<UserEntity, AppFailure>>());
      final failure = (result as Failure).failure;
      expect(failure, isA<NetworkFailure>());
      expect(failure.message, 'Network error. Please check your connection.');
    });

    test('maps ServerException to ServerFailure with safe message', () async {
      when(
        () => mockDataSource.signInWithEmailAndPassword(
          email: 'user@test.com',
          password: 'password',
        ),
      ).thenThrow(
        const ServerException(message: 'Server error', statusCode: 500),
      );

      final result = await repository.signInWithEmailAndPassword(
        email: 'user@test.com',
        password: 'password',
      );

      expect(result, isA<Failure<UserEntity, AppFailure>>());
      final failure = (result as Failure).failure;
      expect(failure, isA<ServerFailure>());
      expect(
        failure.message,
        'A server error occurred. Please try again later.',
      );
      expect((failure as ServerFailure).statusCode, 500);
    });

    test(
      'maps unexpected exception to UnknownFailure with safe message',
      () async {
        when(
          () => mockDataSource.signInWithEmailAndPassword(
            email: 'user@test.com',
            password: 'password',
          ),
        ).thenThrow(Exception('Unexpected crash'));

        final result = await repository.signInWithEmailAndPassword(
          email: 'user@test.com',
          password: 'password',
        );

        expect(result, isA<Failure<UserEntity, AppFailure>>());
        final failure = (result as Failure).failure;
        expect(failure, isA<UnknownFailure>());
        expect(
          failure.message,
          'An unexpected error occurred. Please try again.',
        );
      },
    );
  });

  group('signUpWithEmailAndPassword', () {
    test('returns Success with UserEntity when data source succeeds', () async {
      when(
        () => mockDataSource.signUpWithEmailAndPassword(
          email: 'user@test.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => testDto);

      final result = await repository.signUpWithEmailAndPassword(
        email: 'user@test.com',
        password: 'password123',
      );

      expect(result, isA<Success<UserEntity, AppFailure>>());
      expect((result as Success).data, equals(testEntity));
    });

    test(
      'maps email-already-in-use to AuthFailure with friendly message',
      () async {
        when(
          () => mockDataSource.signUpWithEmailAndPassword(
            email: 'user@test.com',
            password: 'password',
          ),
        ).thenThrow(
          const AuthException('email-already-in-use', 'Email exists'),
        );

        final result = await repository.signUpWithEmailAndPassword(
          email: 'user@test.com',
          password: 'password',
        );

        expect(result, isA<Failure<UserEntity, AppFailure>>());
        final failure = (result as Failure).failure;
        expect(failure, isA<AuthFailure>());
        expect(
          failure.message,
          'Registration failed. Please check your details or try signing in',
        );
      },
    );

    test('maps too-many-requests on signup to friendly message', () async {
      when(
        () => mockDataSource.signUpWithEmailAndPassword(
          email: 'user@test.com',
          password: 'password',
        ),
      ).thenThrow(
        const AuthException('too-many-requests', 'Too many requests'),
      );

      final result = await repository.signUpWithEmailAndPassword(
        email: 'user@test.com',
        password: 'password',
      );

      expect(result, isA<Failure<UserEntity, AppFailure>>());
      final failure = (result as Failure).failure;
      expect(failure, isA<AuthFailure>());
      expect(failure.message, 'Too many attempts. Please try again later');
    });

    test('maps NetworkException on signup to NetworkFailure', () async {
      when(
        () => mockDataSource.signUpWithEmailAndPassword(
          email: 'user@test.com',
          password: 'password',
        ),
      ).thenThrow(const NetworkException('Network unavailable'));

      final result = await repository.signUpWithEmailAndPassword(
        email: 'user@test.com',
        password: 'password',
      );

      expect(result, isA<Failure<UserEntity, AppFailure>>());
      final failure = (result as Failure).failure;
      expect(failure, isA<NetworkFailure>());
      expect(failure.message, 'Network error. Please check your connection.');
    });
  });

  group('signOut', () {
    test('returns Success(null) when data source succeeds', () async {
      when(() => mockDataSource.signOut()).thenAnswer((_) async {});

      final result = await repository.signOut();

      expect(result, isA<Success<void, AppFailure>>());
      expect((result as Success).data, isNull);
      verify(() => mockDataSource.signOut()).called(1);
    });

    test('maps AuthException to AuthFailure with safe message', () async {
      when(
        () => mockDataSource.signOut(),
      ).thenThrow(const AuthException('signout-failed', 'Failed to sign out'));

      final result = await repository.signOut();

      expect(result, isA<Failure<void, AppFailure>>());
      final failure = (result as Failure).failure;
      expect(failure, isA<AuthFailure>());
      expect(failure.message, 'Authentication failed. Please try again.');
    });

    test('maps NetworkException to NetworkFailure', () async {
      when(
        () => mockDataSource.signOut(),
      ).thenThrow(const NetworkException('Network lost'));

      final result = await repository.signOut();

      expect(result, isA<Failure<void, AppFailure>>());
      final failure = (result as Failure).failure;
      expect(failure, isA<NetworkFailure>());
      expect(failure.message, 'Network error. Please check your connection.');
    });

    test('maps ServerException to ServerFailure with safe message', () async {
      when(
        () => mockDataSource.signOut(),
      ).thenThrow(const ServerException(message: 'Sign out server error'));

      final result = await repository.signOut();

      expect(result, isA<Failure<void, AppFailure>>());
      final failure = (result as Failure).failure;
      expect(failure, isA<ServerFailure>());
      expect(
        failure.message,
        'A server error occurred. Please try again later.',
      );
    });

    test(
      'maps unexpected exception to UnknownFailure with safe message',
      () async {
        when(() => mockDataSource.signOut()).thenThrow(Exception('Crash'));

        final result = await repository.signOut();

        expect(result, isA<Failure<void, AppFailure>>());
        final failure = (result as Failure).failure;
        expect(failure, isA<UnknownFailure>());
        expect(
          failure.message,
          'An unexpected error occurred. Please try again.',
        );
      },
    );
  });

  group('currentUser', () {
    test('returns UserEntity when data source returns UserDto', () {
      when(() => mockDataSource.currentUser).thenReturn(testDto);

      expect(repository.currentUser, equals(testEntity));
    });

    test('returns null when data source returns null', () {
      when(() => mockDataSource.currentUser).thenReturn(null);

      expect(repository.currentUser, isNull);
    });
  });

  group('authStateChanges', () {
    test('maps UserDto stream to UserEntity stream', () async {
      when(
        () => mockDataSource.authStateChanges(),
      ).thenAnswer((_) => Stream.fromIterable([null, testDto, null]));

      final stream = repository.authStateChanges();

      expect(stream, emitsInOrder([isNull, equals(testEntity), isNull]));
    });
  });
}
