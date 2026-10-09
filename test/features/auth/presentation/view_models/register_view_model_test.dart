import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/form_status.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/register_view_model.dart';

import '../../../../test_helpers/fakes/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository fakeRepository;
  late ProviderContainer container;

  setUp(() {
    fakeRepository = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );
  });

  tearDown(() {
    container.dispose();
    fakeRepository.dispose();
  });

  test('initial state has empty fields and initial status', () {
    final state = container.read(registerViewModelProvider);
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
      final notifier = container.read(registerViewModelProvider.notifier);

      notifier.updateEmail('new@example.com');
      expect(
        container.read(registerViewModelProvider).email,
        equals('new@example.com'),
      );

      notifier.updatePassword('newsecret');
      expect(
        container.read(registerViewModelProvider).password,
        equals('newsecret'),
      );
    },
  );

  test('submit sets emailError when email is empty', () async {
    final notifier = container.read(registerViewModelProvider.notifier);
    notifier.updatePassword('password123');

    await notifier.submit();

    final state = container.read(registerViewModelProvider);
    expect(state.status, equals(FormStatus.failure));
    expect(state.emailError, equals('Email is required'));
  });

  test('submit sets emailError when email format is invalid', () async {
    final notifier = container.read(registerViewModelProvider.notifier);
    notifier.updateEmail('not-an-email');
    notifier.updatePassword('password123');

    await notifier.submit();

    final state = container.read(registerViewModelProvider);
    expect(state.status, equals(FormStatus.failure));
    expect(state.emailError, equals('Please enter a valid email address'));
  });

  test('submit sets passwordError when password is empty', () async {
    final notifier = container.read(registerViewModelProvider.notifier);
    notifier.updateEmail('test@example.com');

    await notifier.submit();

    final state = container.read(registerViewModelProvider);
    expect(state.status, equals(FormStatus.failure));
    expect(state.passwordError, equals('Password is required'));
  });

  test(
    'submit sets passwordError when password is shorter than 6 characters',
    () async {
      final notifier = container.read(registerViewModelProvider.notifier);
      notifier.updateEmail('test@example.com');
      notifier.updatePassword('12345');

      await notifier.submit();

      final state = container.read(registerViewModelProvider);
      expect(state.status, equals(FormStatus.failure));
      expect(
        state.passwordError,
        equals('Password must be at least 6 characters'),
      );
    },
  );

  test('submit creates user and transitions to success when valid', () async {
    final notifier = container.read(registerViewModelProvider.notifier);
    notifier.updateEmail('fresh@example.com');
    notifier.updatePassword('securePass123');

    await notifier.submit();

    final state = container.read(registerViewModelProvider);
    expect(state.status, equals(FormStatus.success));
    expect(state.errorMessage, isNull);
    expect(fakeRepository.currentUser?.email, equals('fresh@example.com'));
  });

  test('submit transitions to failure when email is already in use', () async {
    fakeRepository.seedUser(
      user: const UserEntity(id: 'existing', email: 'existing@example.com'),
      password: 'password123',
    );

    final notifier = container.read(registerViewModelProvider.notifier);
    notifier.updateEmail('existing@example.com');
    notifier.updatePassword('password123');

    await notifier.submit();

    final state = container.read(registerViewModelProvider);
    expect(state.status, equals(FormStatus.failure));
    expect(
      state.errorMessage,
      equals('An account with this email already exists'),
    );
  });

  test('submit transitions to failure on network failure', () async {
    fakeRepository.signUpFailure = const NetworkFailure(
      'Network connection failed',
    );
    final notifier = container.read(registerViewModelProvider.notifier);
    notifier.updateEmail('fresh@example.com');
    notifier.updatePassword('password123');

    await notifier.submit();

    final state = container.read(registerViewModelProvider);
    expect(state.status, equals(FormStatus.failure));
    expect(state.errorMessage, equals('Network connection failed'));
  });
}
