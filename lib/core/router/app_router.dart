import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bulk_tempo/core/router/route_names.dart';
import 'package:bulk_tempo/core/router/route_paths.dart';
import 'package:bulk_tempo/core/router/router_refresh_notifier.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:bulk_tempo/features/auth/presentation/views/home_shell_screen.dart';
import 'package:bulk_tempo/features/auth/presentation/views/login_screen.dart';
import 'package:bulk_tempo/features/auth/presentation/views/register_screen.dart';
import 'package:bulk_tempo/features/auth/presentation/views/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: refreshNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authViewModelProvider);
      final location = state.matchedLocation;

      final isSplash = location == RoutePaths.splash;
      final isLogin = location == RoutePaths.login;
      final isRegister = location == RoutePaths.register;
      final isAuthRoute = isLogin || isRegister || isSplash;

      if (authState.isInitializing) {
        return isSplash ? null : RoutePaths.splash;
      }

      if (!authState.isAuthenticated) {
        return (isLogin || isRegister) ? null : RoutePaths.login;
      }

      if (authState.isAuthenticated && isAuthRoute) {
        return RoutePaths.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => const HomeShellScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
});
