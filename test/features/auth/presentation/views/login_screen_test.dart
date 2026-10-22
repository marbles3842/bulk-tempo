import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/design_system.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/login_form_state.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/login_view_model.dart';
import 'package:bulk_tempo/features/auth/presentation/views/login_screen.dart';
import 'package:bulk_tempo/features/auth/presentation/widgets/auth_button.dart';

import '../../../../test_helpers/fakes/fake_auth_repository.dart';
import '../../../../test_helpers/pump_app.dart';

class FakeLoginViewModel extends LoginViewModel {
  final LoginFormState initialState;
  FakeLoginViewModel(this.initialState);

  @override
  LoginFormState build() => initialState;
}

void main() {
  late FakeAuthRepository fakeRepository;

  setUp(() {
    fakeRepository = FakeAuthRepository();
  });

  tearDown(() {
    fakeRepository.dispose();
  });

  testWidgets('renders all initial login screen elements', (tester) async {
    await tester.pumpApp(
      const LoginScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to access your workout logs'), findsOneWidget);
    expect(find.byKey(const Key('login_email_field')), findsOneWidget);
    expect(find.byKey(const Key('login_password_field')), findsOneWidget);
    expect(find.byTooltip('Show password'), findsOneWidget);
    expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
    expect(find.byKey(const Key('login_to_register_button')), findsOneWidget);
  });

  testWidgets('tapping submit with empty fields triggers validation errors', (
    tester,
  ) async {
    await tester.pumpApp(
      const LoginScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );

    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets(
    'entering invalid email and short password shows validation errors',
    (tester) async {
      await tester.pumpApp(
        const LoginScreen(),
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
      );

      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'invalid-email',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        '123',
      );

      await tester.tap(find.byKey(const Key('login_submit_button')));
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
      const LoginScreen(),
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepository),
        loginViewModelProvider.overrideWith(
          () => FakeLoginViewModel(
            const LoginFormState(status: FormStatus.submitting),
          ),
        ),
      ],
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
    'displays error SnackBar and inline banner on submission failure',
    (tester) async {
      await tester.pumpApp(
        const LoginScreen(),
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
      );

      // Enter non-existent user credentials
      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        'nobody@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'password123',
      );

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byKey(const Key('login_error_banner')), findsOneWidget);
      expect(find.text('Invalid email or password'), findsNWidgets(2));
    },
  );

  testWidgets('disables inputs and buttons during FormStatus.submitting', (
    tester,
  ) async {
    await tester.pumpApp(
      const LoginScreen(),
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepository),
        loginViewModelProvider.overrideWith(
          () => FakeLoginViewModel(
            const LoginFormState(status: FormStatus.submitting),
          ),
        ),
      ],
    );

    final emailField = tester.widget<TextField>(
      find.byKey(const Key('login_email_field')),
    );
    final passwordField = tester.widget<TextField>(
      find.byKey(const Key('login_password_field')),
    );
    final submitButton = tester.widget<AuthButton>(
      find.byKey(const Key('login_submit_button')),
    );
    final registerButton = tester.widget<AppButton>(
      find.byKey(const Key('login_to_register_button')),
    );

    expect(emailField.enabled, isFalse);
    expect(passwordField.enabled, isFalse);
    expect(submitButton.isEnabled, isFalse);
    expect(submitButton.isLoading, isTrue);
    expect(registerButton.isEnabled, isFalse);
  });

  testWidgets('renders cupertinoClassic controls when on iOS platform', (
    tester,
  ) async {
    await tester.pumpApp(
      const LoginScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
      capabilities: const PresentationCapabilities(
        targetPlatform: TargetPlatform.iOS,
      ),
    );

    expect(find.byType(CupertinoTextField), findsNWidgets(2));
    expect(find.byType(CupertinoButton), findsAtLeastNWidgets(2));
  });

  testWidgets('navigates to register when sign up link is tapped', (
    tester,
  ) async {
    var registerNavigated = false;

    await tester.pumpApp(
      LoginScreen(onNavigateToRegister: () => registerNavigated = true),
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );

    await tester.tap(find.byKey(const Key('login_to_register_button')));
    await tester.pumpAndSettle();

    expect(registerNavigated, isTrue);
  });

  testWidgets('successful sign in updates repository state', (tester) async {
    fakeRepository.seedUser(
      user: const UserEntity(id: 'u1', email: 'valid@example.com'),
      password: 'validpassword',
    );

    await tester.pumpApp(
      const LoginScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
    );

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'valid@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'validpassword',
    );

    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(fakeRepository.currentUser?.email, equals('valid@example.com'));
  });

  group('LoginScreen Accessibility & 2.0x Text-Scale Reflow', () {
    testWidgets(
      'renders without overflow at 2.0x text scale in Polish (390x844)',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpApp(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              textScaler: TextScaler.linear(2.0),
            ),
            child: const LoginScreen(),
          ),
          locale: const Locale('pl'),
          theme: AppTheme.dark(),
          overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'interactive buttons satisfy 48x48 tap target on Android and 44x44 on iOS',
      (tester) async {
        // 1. Android
        await tester.pumpApp(
          const LoginScreen(),
          locale: const Locale('pl'),
          overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
          capabilities: const PresentationCapabilities(
            targetPlatform: TargetPlatform.android,
          ),
        );
        await tester.pumpAndSettle();

        final submitBtnAndroid = tester.getSize(
          find.byKey(const Key('login_submit_button')),
        );
        final registerBtnAndroid = tester.getSize(
          find.byKey(const Key('login_to_register_button')),
        );
        expect(submitBtnAndroid.width, greaterThanOrEqualTo(48));
        expect(submitBtnAndroid.height, greaterThanOrEqualTo(48));
        expect(registerBtnAndroid.width, greaterThanOrEqualTo(48));
        expect(registerBtnAndroid.height, greaterThanOrEqualTo(48));

        // 2. iOS
        await tester.pumpApp(
          const LoginScreen(),
          locale: const Locale('pl'),
          overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
          capabilities: const PresentationCapabilities(
            targetPlatform: TargetPlatform.iOS,
            iosMajorVersion: 18,
            supportsNativeIosViews: false,
          ),
        );
        await tester.pumpAndSettle();

        final submitBtnIos = tester.getSize(
          find.byKey(const Key('login_submit_button')),
        );
        final registerBtnIos = tester.getSize(
          find.byKey(const Key('login_to_register_button')),
        );
        expect(submitBtnIos.width, greaterThanOrEqualTo(44));
        expect(submitBtnIos.height, greaterThanOrEqualTo(44));
        expect(registerBtnIos.width, greaterThanOrEqualTo(44));
        expect(registerBtnIos.height, greaterThanOrEqualTo(44));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
