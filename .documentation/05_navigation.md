# 05. Navigation & Routing

This document defines the routing and navigation architecture for **Bulk Tempo** using **GoRouter** (`go_router`).

---

## 1. Routing Architecture

Routing is centralized in `lib/core/router/` to maintain clean navigation boundaries and support deep linking for mobile platforms:

```text
lib/core/router/
├── app_router.dart          # GoRouter instance and Riverpod provider
├── route_names.dart         # Static string constants for route names
└── route_paths.dart         # Static string constants for URL paths
```

---

## 2. Route Definitions & Constants

Routes must always be referenced via typed constants to avoid stringly-typed bugs.

### A. Route Constants (`lib/core/router/route_paths.dart` & `route_names.dart`):

```dart
// lib/core/router/route_paths.dart
abstract class RoutePaths {
  static const String splash = '/';
  static const String login = '/login';
  static const String items = '/items';
  static const String itemDetailsSubPath = ':id';
  static const String itemDetails = '/items/:id';
}

// lib/core/router/route_names.dart
abstract class RouteNames {
  static const String splash = 'splash';
  static const String login = 'login';
  static const String items = 'items';
  static const String itemDetails = 'itemDetails';
}
```

### B. Router Provider (`lib/core/router/app_router.dart`):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bulk_tempo/core/router/route_names.dart';
import 'package:bulk_tempo/core/router/route_paths.dart';
import 'package:bulk_tempo/features/items/presentation/views/item_details_screen.dart';
import 'package:bulk_tempo/features/items/presentation/views/items_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.items,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: RoutePaths.items,
        name: RouteNames.items,
        builder: (context, state) => const ItemsScreen(),
        routes: [
          GoRoute(
            path: RoutePaths.itemDetailsSubPath,
            name: RouteNames.itemDetails,
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return ItemDetailsScreen(itemId: id);
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri.toString()}'),
      ),
    ),
  );
});
```

---

## 3. Navigation Best Practices

### A. Named Navigation
Always prefer `goNamed` or `pushNamed` with named parameters:

```dart
// Navigating to a detail screen with parameters
context.pushNamed(
  RouteNames.itemDetails,
  pathParameters: {'id': item.id},
);
```

- Use `context.goNamed(...)` when transitioning top-level destinations (replaces history stack).
- Use `context.pushNamed(...)` when pushing a detail screen that can be popped back.

### B. Triggering Navigation from MVVM
- **View-Driven Navigation**: If navigation occurs directly on a tap (e.g. clicking an item in a list), call `context.pushNamed(...)` directly in the View's `onTap` handler.
- **State-Driven Navigation**: If navigation depends on an asynchronous operation (e.g. logging in, submitting a form), listen to the ViewModel state inside the View:

```dart
// Inside ConsumerWidget.build:
ref.listen<LoginState>(loginViewModelProvider, (previous, next) {
  if (next is LoginSuccess) {
    context.goNamed(RouteNames.items);
  }
});
```

**CRITICAL RULE**: The ViewModel must NEVER perform navigation or reference `BuildContext`.

---

## 4. Redirect Guards (e.g. Auth Guards)

GoRouter's `redirect` callback only executes on navigation transitions by default. To make routing reactively respond to asynchronous Riverpod state changes (such as logging in, logging out, or session expiration), wire a `refreshListenable` bridge:

### A. Reactive Listenable Bridge (`lib/core/router/router_refresh_notifier.dart`)

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';

/// Bridges Riverpod state updates to GoRouter's [refreshListenable].
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }
}
```

### B. Wiring `refreshListenable` & `redirect` in `app_router.dart`

```dart
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: RoutePaths.items,
    refreshListenable: refreshNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authNotifierProvider);
      final isLoggingIn = state.matchedLocation == RoutePaths.login;

      // Unauthenticated users are redirected to login
      if (!authState.isAuthenticated && !isLoggingIn) {
        return RoutePaths.login;
      }

      // Authenticated users trying to access login are redirected to home
      if (authState.isAuthenticated && isLoggingIn) {
        return RoutePaths.items;
      }

      return null; // No redirection
    },
    routes: [
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.items,
        name: RouteNames.items,
        builder: (context, state) => const ItemsScreen(),
        routes: [
          GoRoute(
            path: RoutePaths.itemDetailsSubPath,
            name: RouteNames.itemDetails,
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return ItemDetailsScreen(itemId: id);
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri.toString()}'),
      ),
    ),
  );
});
```
