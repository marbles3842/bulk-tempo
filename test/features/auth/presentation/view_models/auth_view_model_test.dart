import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';

import '../../../../test_helpers/fakes/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository fakeRepository;
  late ProviderContainer container;

  const testUser = UserEntity(id: 'u1', email: 'test@example.com');

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

  test('initial state has isInitializing true', () {
    final state = container.read(authViewModelProvider);
    expect(state.isInitializing, isTrue);
    expect(state.user, isNull);
    expect(state.isAuthenticated, isFalse);
  });

  test(
    'updates user and isInitializing when repository emits auth state',
    () async {
      // Read the provider to subscribe
      container.read(authViewModelProvider);

      // Emit a user via repository
      fakeRepository.setCurrentUser(testUser);
      // Allow stream microtasks to pump
      await Future<void>.delayed(Duration.zero);

      final state = container.read(authViewModelProvider);
      expect(state.isInitializing, isFalse);
      expect(state.user, equals(testUser));
      expect(state.isAuthenticated, isTrue);
    },
  );

  test('signOut clears user and updates auth state on success', () async {
    fakeRepository.setCurrentUser(testUser);
    container.read(authViewModelProvider);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(authViewModelProvider).user, equals(testUser));

    await container.read(authViewModelProvider.notifier).signOut();
    await Future<void>.delayed(Duration.zero);

    final state = container.read(authViewModelProvider);
    expect(state.user, isNull);
    expect(state.isAuthenticated, isFalse);
    expect(state.errorMessage, isNull);
  });

  test('signOut sets errorMessage on failure', () async {
    fakeRepository.setCurrentUser(testUser);
    container.read(authViewModelProvider);
    await Future<void>.delayed(Duration.zero);

    fakeRepository.signOutFailure = const ServerFailure('Sign out failed');

    await container.read(authViewModelProvider.notifier).signOut();

    final state = container.read(authViewModelProvider);
    expect(state.errorMessage, equals('Sign out failed'));
  });

  test('clearError resets errorMessage to null', () async {
    fakeRepository.setCurrentUser(testUser);
    container.read(authViewModelProvider);
    await Future<void>.delayed(Duration.zero);

    fakeRepository.signOutFailure = const ServerFailure('Sign out failed');
    await container.read(authViewModelProvider.notifier).signOut();

    expect(
      container.read(authViewModelProvider).errorMessage,
      equals('Sign out failed'),
    );

    container.read(authViewModelProvider.notifier).clearError();
    expect(container.read(authViewModelProvider).errorMessage, isNull);
  });
}
