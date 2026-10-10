import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_state.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:bulk_tempo/features/auth/presentation/views/home_shell_screen.dart';

import '../../../../test_helpers/fakes/fake_auth_repository.dart';
import '../../../../test_helpers/pump_app.dart';

class FakeAuthViewModel extends AuthViewModel {
  final AuthState initialState;
  FakeAuthViewModel(this.initialState);

  @override
  AuthState build() => initialState;
}

void main() {
  late FakeAuthRepository fakeRepository;
  const testUser = UserEntity(id: 'u1', email: 'athlete@example.com');

  setUp(() {
    fakeRepository = FakeAuthRepository(initialUser: testUser);
  });

  tearDown(() {
    fakeRepository.dispose();
  });

  testWidgets('renders welcome message and authenticated user email', (
    tester,
  ) async {
    await tester.pumpApp(
      const HomeShellScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Bulk Tempo'), findsOneWidget);
    expect(find.text('athlete@example.com'), findsOneWidget);
    expect(find.byKey(const Key('home_logout_button')), findsOneWidget);
  });

  testWidgets(
    'tapping logout button shows confirmation dialog with Cancel and Log Out actions',
    (tester) async {
      await tester.pumpApp(
        const HomeShellScreen(),
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('home_logout_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Are you sure you want to log out?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byKey(const Key('confirm_logout_button')), findsOneWidget);
    },
  );

  testWidgets('tapping Cancel dismisses dialog without logging out', (
    tester,
  ) async {
    await tester.pumpApp(
      const HomeShellScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_logout_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(fakeRepository.currentUser, equals(testUser));
  });

  testWidgets('confirming logout signs out user from repository', (
    tester,
  ) async {
    await tester.pumpApp(
      const HomeShellScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_logout_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('confirm_logout_button')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(fakeRepository.currentUser, isNull);
  });

  testWidgets('tapping app bar logout icon also shows confirmation dialog', (
    tester,
  ) async {
    await tester.pumpApp(
      const HomeShellScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_app_bar_logout_button')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Are you sure you want to log out?'), findsOneWidget);
  });

  testWidgets('displays error SnackBar when logout fails', (tester) async {
    fakeRepository.signOutFailure = const ServerFailure('Sign out failed');

    await tester.pumpApp(
      const HomeShellScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_logout_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('confirm_logout_button')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Sign out failed'), findsOneWidget);
  });
}
