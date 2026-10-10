import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/features/auth/data/datasources/auth_remote_data_source.dart';

import '../../../../test_helpers/mocks.dart';

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockFirebaseUser;
  late MockUserCredential mockCredential;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockFirebaseUser = MockUser();
    mockCredential = MockUserCredential();
    dataSource = AuthRemoteDataSourceImpl(mockFirebaseAuth);

    when(() => mockFirebaseUser.uid).thenReturn('uid_123');
    when(() => mockFirebaseUser.email).thenReturn('test@domain.com');
    when(() => mockFirebaseUser.displayName).thenReturn('Tester');
    when(() => mockCredential.user).thenReturn(mockFirebaseUser);
  });

  group('signInWithEmailAndPassword', () {
    test('returns UserDto on successful authentication', () async {
      when(
        () => mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@domain.com',
          password: 'password',
        ),
      ).thenAnswer((_) async => mockCredential);

      final result = await dataSource.signInWithEmailAndPassword(
        email: 'test@domain.com',
        password: 'password',
      );

      expect(result.id, 'uid_123');
      expect(result.email, 'test@domain.com');
      expect(result.displayName, 'Tester');
    });

    test('throws AuthException if user is null in credential', () async {
      final emptyCredential = MockUserCredential();
      when(() => emptyCredential.user).thenReturn(null);
      when(
        () => mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@domain.com',
          password: 'password',
        ),
      ).thenAnswer((_) async => emptyCredential);

      expect(
        () => dataSource.signInWithEmailAndPassword(
          email: 'test@domain.com',
          password: 'password',
        ),
        throwsA(
          isA<AuthException>().having((e) => e.code, 'code', 'user-not-found'),
        ),
      );
    });

    test(
      'throws NetworkException on network-request-failed FirebaseAuthException',
      () async {
        when(
          () => mockFirebaseAuth.signInWithEmailAndPassword(
            email: 'test@domain.com',
            password: 'password',
          ),
        ).thenThrow(
          FirebaseAuthException(
            code: 'network-request-failed',
            message: 'Network unreachable',
          ),
        );

        expect(
          () => dataSource.signInWithEmailAndPassword(
            email: 'test@domain.com',
            password: 'password',
          ),
          throwsA(
            isA<NetworkException>().having(
              (e) => e.message,
              'message',
              'Network unreachable',
            ),
          ),
        );
      },
    );

    test('throws AuthException on other FirebaseAuthException', () async {
      when(
        () => mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@domain.com',
          password: 'password',
        ),
      ).thenThrow(
        FirebaseAuthException(code: 'user-not-found', message: 'No user found'),
      );

      expect(
        () => dataSource.signInWithEmailAndPassword(
          email: 'test@domain.com',
          password: 'password',
        ),
        throwsA(
          isA<AuthException>().having((e) => e.code, 'code', 'user-not-found'),
        ),
      );
    });

    test(
      'throws NetworkException on socket/network error in catch block',
      () async {
        when(
          () => mockFirebaseAuth.signInWithEmailAndPassword(
            email: 'test@domain.com',
            password: 'password',
          ),
        ).thenThrow(Exception('SocketException: OS error'));

        expect(
          () => dataSource.signInWithEmailAndPassword(
            email: 'test@domain.com',
            password: 'password',
          ),
          throwsA(isA<NetworkException>()),
        );
      },
    );

    test('throws ServerException on other unknown exceptions', () async {
      when(
        () => mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@domain.com',
          password: 'password',
        ),
      ).thenThrow(Exception('Unknown unexpected error'));

      expect(
        () => dataSource.signInWithEmailAndPassword(
          email: 'test@domain.com',
          password: 'password',
        ),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('signUpWithEmailAndPassword', () {
    test('returns UserDto on successful sign up', () async {
      when(
        () => mockFirebaseAuth.createUserWithEmailAndPassword(
          email: 'test@domain.com',
          password: 'password',
        ),
      ).thenAnswer((_) async => mockCredential);

      final result = await dataSource.signUpWithEmailAndPassword(
        email: 'test@domain.com',
        password: 'password',
      );

      expect(result.id, 'uid_123');
      expect(result.email, 'test@domain.com');
    });

    test(
      'throws AuthException if user is null in credential on sign up',
      () async {
        final emptyCredential = MockUserCredential();
        when(() => emptyCredential.user).thenReturn(null);
        when(
          () => mockFirebaseAuth.createUserWithEmailAndPassword(
            email: 'test@domain.com',
            password: 'password',
          ),
        ).thenAnswer((_) async => emptyCredential);

        expect(
          () => dataSource.signUpWithEmailAndPassword(
            email: 'test@domain.com',
            password: 'password',
          ),
          throwsA(
            isA<AuthException>().having((e) => e.code, 'code', 'unknown'),
          ),
        );
      },
    );

    test(
      'throws NetworkException on network-request-failed during sign up',
      () async {
        when(
          () => mockFirebaseAuth.createUserWithEmailAndPassword(
            email: 'test@domain.com',
            password: 'password',
          ),
        ).thenThrow(FirebaseAuthException(code: 'network-request-failed'));

        expect(
          () => dataSource.signUpWithEmailAndPassword(
            email: 'test@domain.com',
            password: 'password',
          ),
          throwsA(isA<NetworkException>()),
        );
      },
    );

    test(
      'throws AuthException on FirebaseAuthException during sign up',
      () async {
        when(
          () => mockFirebaseAuth.createUserWithEmailAndPassword(
            email: 'test@domain.com',
            password: 'password',
          ),
        ).thenThrow(
          FirebaseAuthException(
            code: 'email-already-in-use',
            message: 'Email in use',
          ),
        );

        expect(
          () => dataSource.signUpWithEmailAndPassword(
            email: 'test@domain.com',
            password: 'password',
          ),
          throwsA(
            isA<AuthException>().having(
              (e) => e.code,
              'code',
              'email-already-in-use',
            ),
          ),
        );
      },
    );
  });

  group('signOut', () {
    test('calls firebaseAuth.signOut successfully', () async {
      when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async {});

      await dataSource.signOut();

      verify(() => mockFirebaseAuth.signOut()).called(1);
    });

    test('throws NetworkException on network error during signOut', () async {
      when(() => mockFirebaseAuth.signOut())
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      expect(() => dataSource.signOut(), throwsA(isA<NetworkException>()));
    });

    test(
      'throws AuthException on FirebaseAuthException during signOut',
      () async {
        when(() => mockFirebaseAuth.signOut()).thenThrow(
          FirebaseAuthException(code: 'sign-out-failed', message: 'Failed'),
        );

        expect(() => dataSource.signOut(), throwsA(isA<AuthException>()));
      },
    );
  });

  group('currentUser and authStateChanges', () {
    test('currentUser returns UserDto when user is logged in', () {
      when(() => mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);

      final user = dataSource.currentUser;

      expect(user?.id, 'uid_123');
      expect(user?.email, 'test@domain.com');
    });

    test('currentUser returns null when no user is logged in', () {
      when(() => mockFirebaseAuth.currentUser).thenReturn(null);

      expect(dataSource.currentUser, isNull);
    });

    test('authStateChanges streams mapped UserDto', () async {
      when(
        () => mockFirebaseAuth.authStateChanges(),
      ).thenAnswer((_) => Stream.fromIterable([null, mockFirebaseUser, null]));

      final stream = dataSource.authStateChanges();

      expect(stream, emitsInOrder([isNull, isNotNull, isNull]));
    });
  });
}
