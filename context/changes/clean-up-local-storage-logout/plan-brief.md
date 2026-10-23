# Clean Up Local Storage on Logout — Plan Brief

> Full plan: `context/changes/clean-up-local-storage-logout/plan.md`

## What & Why

Ensure all local persistent data, in-memory caches, and especially the user's Hevy API key stored in `FlutterSecureStorage` are wiped completely when logging out. Currently, `AuthViewModel.signOut()` only signs out of Firebase Auth, leaving sensitive API keys stored on the device Keystore/Keychain.

## Starting Point

`FlutterSecureStorage` is the only local persistent storage package in the codebase, holding `hevy_api_key_$userId` and `app_locale`. When a user clicks logout in `HomeShellScreen`, it triggers `AuthViewModel.signOut()`, which calls `FirebaseAuth.instance.signOut()` without deleting the API key or resetting keep-alive Riverpod caches.

## Desired End State

When a user confirms logout:
1. `FlutterSecureStorage.deleteAll()` wipes all stored credentials and preferences fail-open.
2. All in-memory feature caches (workouts, weight logs, targets, dashboard) and locale state are explicitly invalidated.
3. Firebase Auth sign-out is executed, cleanly redirecting the user to `/login`.

## Key Decisions Made

| Decision | Choice | Why (1 sentence) |
| :--- | :--- | :--- |
| **Storage Wipe Scope** | Full wipe (`deleteAll()`) | Guarantees complete credential and cache cleanup on device. |
| **Architecture** | `AuthViewModel` orchestration | Follows existing Riverpod MVVM pattern without extra boilerplate. |
| **Failure Handling** | Best-effort fail-open | Storage exceptions are caught and logged so users are never trapped in a session. |
| **Cache Invalidation** | Invalidate all feature caches + locale | Ensures zero RAM state leakage across user sessions and syncs locale state. |
| **Storage Provider** | Consolidate in `core/providers/` | Eliminates duplicated providers and centralizes storage injection. |
| **Execution Sequencing** | Wipe storage, reset caches, then Firebase signout | Guarantees data destruction before unauthenticated redirect occurs. |
| **Testing Strategy** | Unit tests + widget test | Covers business logic edge cases (fail-open) and UI logout interaction. |

## Scope

**In scope:**
- Consolidating `FlutterSecureStorage` providers into `lib/core/providers/secure_storage_provider.dart`.
- Executing `storage.deleteAll()` and in-memory cache invalidation inside `AuthViewModel.signOut()`.
- Fail-open exception handling for storage operations.
- Unit and widget test coverage for logout cleanup.

**Out of scope:**
- SQLite, Drift, or Hive database operations (none exist in the codebase).
- Deleting remote user data in Firebase Realtime Database.
- Introducing a dedicated multi-layer `SignOutCoordinator` class.

## Architecture / Approach

`AuthViewModel.signOut()` acts as the orchestrator. When invoked, it reads `secureStorageProvider`, executes `await storage.deleteAll()` within a `try/catch` block, explicitly invalidates feature providers (`workoutProgressViewModelProvider`, `weightHistoryViewModelProvider`, `gainTargetViewModelProvider`, `dashboardViewModelProvider`, `hevyKeyViewModelProvider`, `weightEntryViewModelProvider`, `localeNotifierProvider`), and finally calls `repository.signOut()`.

## Phases at a Glance

| Phase | What it delivers | Key risk |
| :--- | :--- | :--- |
| **1. Consolidate Secure Storage Provider** | Canonical `secureStorageProvider` in `core/providers/` | Broken imports in existing tests/features |
| **2. Storage Cleanup & Cache Invalidation** | `AuthViewModel.signOut()` storage wipe & cache reset | Race condition with GoRouter redirect |
| **3. Comprehensive Unit & Widget Testing** | Unit tests for fail-open wipe and widget test for logout | Mocking storage overrides in pump helpers |

**Prerequisites:** None.
**Estimated effort:** ~1 session across 3 phases.

## Open Risks & Assumptions

- **Keychain/Keystore lockup**: Handled via fail-open `try/catch` logging so sign-out is never blocked.
- **Provider invalidation timing**: Handled by awaiting `deleteAll()` and executing invalidations before `repository.signOut()`.

## Success Criteria (Summary)

- Confirming logout clears all keys from `FlutterSecureStorage`.
- RAM state for workouts, weights, and targets is completely flushed.
- Uncaught storage exceptions never prevent sign-out or navigation to login.
- 100% automated test pass rate with zero static analysis warnings.
