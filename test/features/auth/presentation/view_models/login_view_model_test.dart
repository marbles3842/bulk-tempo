import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/form_status.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/login_view_model.dart';

import '../../../../test_helpers/fakes/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository fakeRepository;
  late ProviderContainer container;

  const testUser = UserEntity(id: 'u1', email: 'test@example.com');
  const testPassword = 'password123';

  setUp(() {
    fakeRepository = FakeAuthRepository();
    fakeRepository.seedUser(user: testUser, password: testPassword);
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );
  });

  tearDown(() {
    container.dispose();
    fakeRepository.dispose();
  });

  test('initial state has empty fields and initial status', () {
    final state = container.read(loginViewModelProvider);
    expect(state.email, isEmpty);
    expect(state.password, isEmpty);
    expect(state.status, equals(FormStatus.initial));
    expect(state.errorMessage, isNull);
    expect(state.emailError, isNull);
    expect(state.passwordError, isNull);
  });

  test(
    'updateEmail and updatePassword update state values and clear errors',
    () {
      final notifier = container.read(loginViewModelProvider.notifier);

      notifier.updateEmail('hello@example.com');
      expect(
        container.read(loginViewModelProvider).email,
        equals('hello@example.com'),
      );

      notifier.updatePassword('secret');
      expect(container.read(loginViewModelProvider).password, equals('secret'));
    },
  );

  test('submit sets emailError when email is empty', () async {
    final notifier = container.read(loginViewModelProvider.notifier);
    notifier.updatePassword('password123');

    await notifier.submit();

    final state = container.read(loginViewModelProvider);
    expect(state.status, equals(FormStatus.failure));
    expect(state.emailError, equals('Email is required'));
  });

  test('submit sets emailError when email format is invalid', () async {
    final notifier = container.read(loginViewModelProvider.notifier);
    notifier.updateEmail('invalid-email');
    notifier.updatePassword('password123');

    await notifier.submit();

    final state = container.read(loginViewModelProvider);
    expect(state.status, equals(FormStatus.failure));
    expect(state.emailError, equals('Please enter a valid email address'));
  });

  test('submit sets passwordError when password is empty', () async {
    final notifier = container.read(loginViewModelProvider.notifier);
    notifier.updateEmail('test@example.com');

    await notifier.submit();

    final state = container.read(loginViewModelProvider);
    expect(state.status, equals(FormStatus.failure));
    expect(state.passwordError, equals('Password is required'));
  });

  test(
    'submit sets passwordError when password is shorter than 6 characters',
    () async {
      final notifier = container.read(loginViewModelProvider.notifier);
      notifier.updateEmail('test@example.com');
      notifier.updatePassword('12345');

      await notifier.submit();

      final state = container.read(loginViewModelProvider);
      expect(state.status, equals(FormStatus.failure));
      expect(
        state.passwordError,
        equals('Password must be at least 6 characters'),
      );
    },
  );

  test('submit transitions to success when credentials are valid', () async {
    final notifier = container.read(loginViewModelProvider.notifier);
    notifier.updateEmail('test@example.com');
    notifier.updatePassword('password123');

    await notifier.submit();

    final state = container.read(loginViewModelProvider);
    expect(state.status, equals(FormStatus.success));
    expect(state.errorMessage, isNull);
    expect(fakeRepository.currentUser, equals(testUser));
  });

  test('submit transitions to failure when credentials are invalid', () async {
    final notifier = container.read(loginViewModelProvider.notifier);
    notifier.updateEmail('test@example.com');
    notifier.updatePassword('wrongpassword');

    await notifier.submit();

    final state = container.read(loginViewModelProvider);
    expect(state.status, equals(FormStatus.failure));
    expect(state.errorMessage, equals('Invalid email or password'));
  });

  test('submit transitions to failure on network failure', () async {
    fakeRepository.signInFailure = const NetworkFailure(
      'Network connection failed',
    );
    final notifier = container.read(loginViewModelProvider.notifier);
    notifier.updateEmail('test@example.com');
    notifier.updatePassword('password123');

    await notifier.submit();

    final state = container.read(loginViewModelProvider);
    expect(state.status, equals(FormStatus.failure));
    expect(state.errorMessage, equals('Network connection failed'));
  });

  test('ignores submit when status is submitting', () async {
    final notifier = container.read(loginViewModelProvider.notifier);
    notifier.updateEmail('test@example.com');
    notifier.updatePassword('password123');

    final future1 = notifier.submit();
    final future2 = notifier.submit();

    await Future.wait([future1, future2]);

    final state = container.read(loginViewModelProvider);
    expect(state.status, equals(FormStatus.success));
  });
}
