import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:bulk_tempo/app/router/app_router.dart';
import 'package:bulk_tempo/core/router/route_paths.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_state.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:bulk_tempo/features/auth/presentation/views/home_shell_screen.dart';
import 'package:bulk_tempo/features/auth/presentation/views/login_screen.dart';
import 'package:bulk_tempo/features/auth/presentation/views/register_screen.dart';
import 'package:bulk_tempo/features/auth/presentation/views/splash_screen.dart';

import '../../test_helpers/fakes/fake_auth_repository.dart';

class FakeAuthViewModel extends AuthViewModel {
  final AuthState initialState;
  FakeAuthViewModel(this.initialState);

  @override
  AuthState build() => initialState;
}

void main() {
  group('AppRouter redirect guards', () {
    late FakeAuthRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeAuthRepository();
    });

    tearDown(() {
      fakeRepo.dispose();
    });

    testWidgets(
      'redirects to / and shows SplashScreen when auth is initializing',
      (tester) async {
        late GoRouter router;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(fakeRepo),
              authViewModelProvider.overrideWith(
                () => FakeAuthViewModel(const AuthState(isInitializing: true)),
              ),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                router = ref.watch(appRouterProvider);
                return MaterialApp.router(routerConfig: router);
              },
            ),
          ),
        );
        await tester.pump();

        expect(router.state.matchedLocation, equals(RoutePaths.splash));
        expect(find.byType(SplashScreen), findsOneWidget);

        // Attempting to navigate elsewhere during initialization redirects to splash
        router.go(RoutePaths.home);
        await tester.pump();
        expect(router.state.matchedLocation, equals(RoutePaths.splash));
      },
    );

    testWidgets(
      'redirects to /login and shows LoginScreen when unauthenticated attempting /home',
      (tester) async {
        late GoRouter router;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
            child: Consumer(
              builder: (context, ref, _) {
                router = ref.watch(appRouterProvider);
                return MaterialApp.router(routerConfig: router);
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(router.state.matchedLocation, equals(RoutePaths.login));
        expect(find.byType(LoginScreen), findsOneWidget);

        // Attempting to access protected /home redirects back to /login
        router.go(RoutePaths.home);
        await tester.pumpAndSettle();

        expect(router.state.matchedLocation, equals(RoutePaths.login));
        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );

    testWidgets('allows navigating to /register when unauthenticated', (
      tester,
    ) async {
      late GoRouter router;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
          child: Consumer(
            builder: (context, ref, _) {
              router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go(RoutePaths.register);
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, equals(RoutePaths.register));
      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    testWidgets(
      'redirects to /home and shows HomeShellScreen when authenticated',
      (tester) async {
        const user = UserEntity(id: 'u1', email: 'test@example.com');
        final authenticatedRepo = FakeAuthRepository(initialUser: user);
        late GoRouter router;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(authenticatedRepo),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                router = ref.watch(appRouterProvider);
                return MaterialApp.router(routerConfig: router);
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(router.state.matchedLocation, equals(RoutePaths.home));
        expect(find.byType(HomeShellScreen), findsOneWidget);

        // Attempting to access auth routes redirects back to /home
        router.go(RoutePaths.login);
        await tester.pumpAndSettle();
        expect(router.state.matchedLocation, equals(RoutePaths.home));

        router.go(RoutePaths.register);
        await tester.pumpAndSettle();
        expect(router.state.matchedLocation, equals(RoutePaths.home));

        router.go(RoutePaths.splash);
        await tester.pumpAndSettle();
        expect(router.state.matchedLocation, equals(RoutePaths.home));

        authenticatedRepo.dispose();
      },
    );

    testWidgets(
      'reactively redirects to /home upon sign-in and /login upon sign-out',
      (tester) async {
        late GoRouter router;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authRepositoryProvider.overrideWithValue(fakeRepo)],
            child: Consumer(
              builder: (context, ref, _) {
                router = ref.watch(appRouterProvider);
                return MaterialApp.router(routerConfig: router);
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initial state is unauthenticated -> redirected to login
        expect(router.state.matchedLocation, equals(RoutePaths.login));
        expect(find.byType(LoginScreen), findsOneWidget);

        // Sign in user
        const user = UserEntity(id: 'u123', email: 'user@example.com');
        fakeRepo.seedUser(user: user, password: 'password123');
        await fakeRepo.signInWithEmailAndPassword(
          email: 'user@example.com',
          password: 'password123',
        );
        await tester.pumpAndSettle();

        // Reactive redirection automatically moved to /home
        expect(router.state.matchedLocation, equals(RoutePaths.home));
        expect(find.byType(HomeShellScreen), findsOneWidget);

        // Sign out user
        await fakeRepo.signOut();
        await tester.pumpAndSettle();

        // Reactive redirection automatically moved back to /login
        expect(router.state.matchedLocation, equals(RoutePaths.login));
        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );
  });
}
