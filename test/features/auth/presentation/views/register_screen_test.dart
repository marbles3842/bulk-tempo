import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/register_form_state.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/register_view_model.dart';
import 'package:bulk_tempo/features/auth/presentation/views/register_screen.dart';

import '../../../../test_helpers/fakes/fake_auth_repository.dart';
import '../../../../test_helpers/pump_app.dart';

class FakeRegisterViewModel extends RegisterViewModel {
  final RegisterFormState initialState;
  FakeRegisterViewModel(this.initialState);

  @override
  RegisterFormState build() => initialState;
}

void main() {
  late FakeAuthRepository fakeRepository;

  setUp(() {
    fakeRepository = FakeAuthRepository();
  });

  tearDown(() {
    fakeRepository.dispose();
  });

  testWidgets('renders all initial register screen elements', (tester) async {
    await tester.pumpApp(
      const RegisterScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );

    expect(find.text('Create Account'), findsNWidgets(2)); // Title and Button
    expect(find.text('Start tracking your workouts today'), findsOneWidget);
    expect(find.byKey(const Key('register_email_field')), findsOneWidget);
    expect(find.byKey(const Key('register_password_field')), findsOneWidget);
    expect(find.byKey(const Key('register_submit_button')), findsOneWidget);
    expect(find.byKey(const Key('register_to_login_button')), findsOneWidget);
  });

  testWidgets('tapping submit with empty fields triggers validation errors', (
    tester,
  ) async {
    await tester.pumpApp(
      const RegisterScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );

    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets(
    'entering invalid email and short password shows validation errors',
    (tester) async {
      await tester.pumpApp(
        const RegisterScreen(),
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
      );

      await tester.enterText(
        find.byKey(const Key('register_email_field')),
        'not-an-email',
      );
      await tester.enterText(
        find.byKey(const Key('register_password_field')),
        '123',
      );

      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
    },
  );

  testWidgets('renders loading indicator when state is submitting', (
    tester,
  ) async {
    await tester.pumpApp(
      const RegisterScreen(),
      overrides: [
        registerViewModelProvider.overrideWith(
          () => FakeRegisterViewModel(
            const RegisterFormState(status: FormStatus.submitting),
          ),
        ),
      ],
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('displays error SnackBar when email already in use', (
    tester,
  ) async {
    fakeRepository.seedUser(
      user: const UserEntity(id: 'u1', email: 'taken@example.com'),
      password: 'password123',
    );

    await tester.pumpApp(
      const RegisterScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );

    await tester.enterText(
      find.byKey(const Key('register_email_field')),
      'taken@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('register_password_field')),
      'password123',
    );

    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text('An account with this email already exists'),
      findsOneWidget,
    );
  });

  testWidgets('navigates to login when log in link is tapped', (tester) async {
    var loginNavigated = false;

    await tester.pumpApp(
      RegisterScreen(onNavigateToLogin: () => loginNavigated = true),
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );

    await tester.tap(find.byKey(const Key('register_to_login_button')));
    await tester.pumpAndSettle();

    expect(loginNavigated, isTrue);
  });

  testWidgets('successful registration creates user in repository', (
    tester,
  ) async {
    await tester.pumpApp(
      const RegisterScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );

    await tester.enterText(
      find.byKey(const Key('register_email_field')),
      'brandnew@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('register_password_field')),
      'securePassword123',
    );

    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pumpAndSettle();

    expect(fakeRepository.currentUser?.email, equals('brandnew@example.com'));
  });
}
