# Clean Up Local Storage on Logout Implementation Plan

## Overview

When a user logs out of Bulk Tempo, all locally stored data, credentials, and in-memory caches must be thoroughly cleared. Currently, logging out only signs the user out of Firebase Auth; the user's Hevy API key and other local keys persist indefinitely in `FlutterSecureStorage` on the device.

This plan consolidates `FlutterSecureStorage` access into a single canonical provider in `lib/core/providers/secure_storage_provider.dart`, updates `AuthViewModel.signOut()` to execute a fail-open `deleteAll()` on secure storage, invalidates all active in-memory Riverpod feature caches and locale state, and validates the entire flow with automated unit and widget tests.

## Current State Analysis

- **Storage Mechanisms**: `FlutterSecureStorage` is the only persistent local storage mechanism in the application (no SQLite, Drift, Hive, or SharedPreferences exist).
- **Persistent Keys**:
  - `hevy_api_key_$userId` stored via `HevyKeyLocalDataSourceImpl` (`lib/features/workout/data/datasources/hevy_key_local_data_source.dart:48`).
  - `app_locale` stored via `LocaleNotifier` (`lib/core/localization/locale_notifier.dart:17`).
- **Logout Behavior**: `HomeShellScreen._showLogoutDialog` calls `AuthViewModel.signOut()` (`lib/features/auth/presentation/view_models/auth_view_model.dart:45-58`), which only calls `FirebaseAuth.instance.signOut()`. It never deletes the Hevy API key from secure storage.
- **Provider Duplication**: Both `lib/core/localization/locale_notifier.dart` (`secureStorageProvider`) and `lib/features/workout/data/datasources/hevy_key_local_data_source.dart` (`flutterSecureStorageProvider`) define independent `FlutterSecureStorage` providers.

## Desired End State

After this plan is complete:
1. `FlutterSecureStorage` is accessed through a single canonical provider in `lib/core/providers/secure_storage_provider.dart`.
2. When the user confirms logout:
   - `FlutterSecureStorage.deleteAll()` is executed to wipe all stored credentials (including Hevy API keys) and preferences fail-open.
   - All in-memory feature caches (`workoutProgressViewModelProvider`, `hevyKeyViewModelProvider`, `weightHistoryViewModelProvider`, `weightEntryViewModelProvider`, `gainTargetViewModelProvider`, `dashboardViewModelProvider`) and `localeNotifierProvider` are explicitly invalidated.
   - Firebase Auth sign-out is executed, triggering unauthenticated routing to `/login`.
3. If storage deletion throws an exception, the failure is caught and logged, allowing sign-out and redirect to proceed cleanly without locking the user in the session.
4. Comprehensive unit and widget tests verify storage deletion, fail-open behavior, cache invalidation, and UI logout dialog interaction.

### Key Discoveries:

- `lib/features/workout/data/datasources/hevy_key_local_data_source.dart:6-8`: Duplicate `flutterSecureStorageProvider` declaration.
- `lib/core/localization/locale_notifier.dart:9-11`: Duplicate `secureStorageProvider` declaration.
- `lib/features/auth/presentation/view_models/auth_view_model.dart:45-58`: `signOut()` only calls `repository.signOut()` without storage cleanup.
- `test/test_helpers/mocks.dart:44`: `MockFlutterSecureStorage` already exists and is ready for reuse in unit and widget tests.

## What We're NOT Doing

- Introducing SQLite, Drift, or Hive database wipe utilities, as no local SQL/NoSQL databases exist in this project.
- Deleting remote user data in Firebase Realtime Database on logout (user data in RTDB persists for the account; only local device storage and RAM caches are wiped).
- Building a complex multi-layered `SignOutCoordinator` or use-case service; coordination is kept directly in `AuthViewModel.signOut()` per repository MVVM patterns.

## Implementation Approach

1. **Centralize Secure Storage**: Create `lib/core/providers/secure_storage_provider.dart` exporting `secureStorageProvider`. Point `HevyKeyLocalDataSourceImpl` and `LocaleNotifier` to this provider.
2. **Orchestrate Cleanup in AuthViewModel**:
   - In `AuthViewModel.signOut()`:
     1. Call `await ref.read(secureStorageProvider).deleteAll()` inside a `try/catch` block (logging any error to avoid trapping users).
     2. Invalidate user-scoped in-memory feature caches and locale state via `ref.invalidate(...)`.
     3. Await `repository.signOut()`.
3. **Verify with Unit & Widget Tests**:
   - Unit tests in `test/features/auth/presentation/view_models/auth_view_model_test.dart` to verify `deleteAll()` invocation, fail-open handling on exception, and provider invalidation.
   - Widget tests in `test/features/auth/presentation/views/home_shell_screen_test.dart` to verify that UI logout triggers clean storage wipe and unauthenticated state.

## Critical Implementation Details

- **Ordering & Lifecycle**: Storage wipe (`deleteAll()`) and in-memory cache invalidation must be initiated *before* calling `repository.signOut()`. This ensures sensitive credentials and user records in RAM are destroyed prior to GoRouter redirecting to the unauthenticated route.
- **Fail-Open Invariant**: Hardware Keystore/Keychain errors or corruption must never trap a user inside an authenticated session. The `deleteAll()` call must be wrapped in `try/catch` so that even if local storage deletion throws, `repository.signOut()` still executes and navigation completes.

---

## Phase 1: Consolidate Secure Storage Provider

### Overview

Create a canonical `secureStorageProvider` in `lib/core/providers/` and update references in `LocaleNotifier` and `HevyKeyLocalDataSourceImpl` to eliminate duplicate providers and provide a unified injection point for storage management.

### Changes Required:

#### 1. Canonical Secure Storage Provider

**File**: `lib/core/providers/secure_storage_provider.dart`

**Intent**: Introduce the canonical Riverpod provider for `FlutterSecureStorage` in core so all features share the same injection point.

**Contract**:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});
```

#### 2. Update LocaleNotifier

**File**: `lib/core/localization/locale_notifier.dart`

**Intent**: Remove local `secureStorageProvider` declaration and import the canonical provider from `lib/core/providers/secure_storage_provider.dart`.

**Contract**: Replace internal provider definition with import, preserving `secureStorageProvider` re-export if needed for backwards compatibility.

#### 3. Update HevyKeyLocalDataSourceImpl

**File**: `lib/features/workout/data/datasources/hevy_key_local_data_source.dart`

**Intent**: Update `hevyKeyLocalDataSourceProvider` to watch the canonical `secureStorageProvider` from `lib/core/providers/secure_storage_provider.dart`.

**Contract**: Replace `ref.watch(flutterSecureStorageProvider)` with `ref.watch(secureStorageProvider)` and keep `flutterSecureStorageProvider` as a deprecated alias pointing to `secureStorageProvider`.

### Success Criteria:

#### Automated Verification:

- New provider created: `lib/core/providers/secure_storage_provider.dart` exists and exports `secureStorageProvider`.
- Code compiles cleanly: `flutter analyze` reports zero errors or warnings in `lib/core/` and `lib/features/workout/data/datasources/`.
- Existing tests pass: `flutter test test/core/localization/locale_notifier_test.dart test/widget_test.dart`.

#### Manual Verification:

- Verify imports in IDE resolve cleanly without circular dependencies.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Phase 2: Implement Storage Cleanup & Cache Invalidation in AuthViewModel

### Overview

Update `AuthViewModel.signOut()` to wipe `FlutterSecureStorage` via `deleteAll()`, invalidate all in-memory feature caches, and then sign out from Firebase Auth.

### Changes Required:

#### 1. AuthViewModel Sign-Out Orchestration

**File**: `lib/features/auth/presentation/view_models/auth_view_model.dart`

**Intent**: Orchestrate storage wipe, cache invalidation, and auth sign-out with fail-open exception handling.

**Contract**:
- In `signOut()`:
  - Read `secureStorageProvider` via `ref.read(secureStorageProvider)`.
  - Execute `await storage.deleteAll();` wrapped in a `try/catch` block.
  - Invalidate in-memory providers:
    - `ref.invalidate(workoutProgressViewModelProvider);`
    - `ref.invalidate(hevyKeyViewModelProvider);`
    - `ref.invalidate(weightHistoryViewModelProvider);`
    - `ref.invalidate(weightEntryViewModelProvider);`
    - `ref.invalidate(gainTargetViewModelProvider);`
    - `ref.invalidate(dashboardViewModelProvider);`
    - `ref.invalidate(localeNotifierProvider);`
  - Await `repository.signOut()` and handle the result as previously implemented.

### Success Criteria:

#### Automated Verification:

- Code compiles cleanly: `flutter analyze` passes with zero issues across `lib/features/auth/`.
- Unit tests run: `flutter test test/features/auth/presentation/view_models/auth_view_model_test.dart`.

#### Manual Verification:

- Code review: verify `deleteAll()` is called within a `try/catch` fail-open block before provider invalidations and Firebase sign-out.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Phase 3: Comprehensive Unit & Widget Testing

### Overview

Add and update unit tests for `AuthViewModel` covering successful storage wipe, fail-open error handling, and provider invalidations, and verify the `HomeShellScreen` widget test suite for logout.

### Changes Required:

#### 1. AuthViewModel Unit Tests

**File**: `test/features/auth/presentation/view_models/auth_view_model_test.dart`

**Intent**: Add unit tests verifying `AuthViewModel.signOut()`:
1. Calls `storage.deleteAll()` during sign-out.
2. Continues sign-out cleanly if `storage.deleteAll()` throws (fail-open).
3. Invalidates associated feature state providers.

**Contract**: Tests use `ProviderContainer` with `MockFlutterSecureStorage` and `FakeAuthRepository`.

#### 2. HomeShellScreen Widget Tests

**File**: `test/features/auth/presentation/views/home_shell_screen_test.dart`

**Intent**: Ensure `HomeShellScreen` logout dialog confirmation triggers `signOut()` and cleanly updates state with mock secure storage in overrides.

**Contract**: Update `buildOverrides()` in `home_shell_screen_test.dart` to include `secureStorageProvider.overrideWithValue(mockStorage)` and assert storage cleanup on logout.

### Success Criteria:

#### Automated Verification:

- AuthViewModel tests pass: `flutter test test/features/auth/presentation/view_models/auth_view_model_test.dart`.
- HomeShellScreen widget tests pass: `flutter test test/features/auth/presentation/views/home_shell_screen_test.dart`.
- Full project test suite passes: `flutter test`.
- Static analysis clean: `flutter analyze` reports 0 issues.
- Code formatted: `dart format --output=none --set-exit-if-changed lib test`.

#### Manual Verification:

- Manual verification on device/simulator: log in, add Hevy API key, log out, confirm key is wiped from storage and login screen appears with fresh unauthenticated state.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Testing Strategy

### Unit Tests:

- `test/features/auth/presentation/view_models/auth_view_model_test.dart`:
  - `signOut calls storage.deleteAll() and clears user state on success`
  - `signOut proceeds with sign-out even if storage.deleteAll() throws (fail-open)`
  - `signOut invalidates workout, weight, target, dashboard, and locale providers`

### Integration / Widget Tests:

- `test/features/auth/presentation/views/home_shell_screen_test.dart`:
  - `confirming logout signs out user from repository and clears secure storage`

### Manual Testing Steps:

1. Launch app and sign in.
2. Navigate to Profile tab and enter a Hevy API key.
3. Verify workouts load on the Workout tab.
4. Tap the logout button in AppBar or Profile tab, and confirm in dialog.
5. Verify redirection to `/login`.
6. Sign in again (or sign in as a different user) and verify that the Hevy API key is not present (prompting for API key connection).

## Performance Considerations

- `FlutterSecureStorage.deleteAll()` is an asynchronous operation taking 5-25ms. Performing it before Firebase sign-out introduces virtually zero perceived latency to the user while guaranteeing clean session teardown.

## Migration Notes

- Existing users' persisted Hevy API keys remain functional until they explicitly log out or disconnect the key.
- No database migrations or schema adjustments are required.

## References

- Existing logout implementation: [`lib/features/auth/presentation/view_models/auth_view_model.dart:45-58`](file:///Users/dimi/Desktop/10xdevs/bulk_tempo/lib/features/auth/presentation/view_models/auth_view_model.dart#L45-L58)
- Existing Hevy key storage: [`lib/features/workout/data/datasources/hevy_key_local_data_source.dart:15-68`](file:///Users/dimi/Desktop/10xdevs/bulk_tempo/lib/features/workout/data/datasources/hevy_key_local_data_source.dart#L15-L68)
- Mock storage helper: [`test/test_helpers/mocks.dart:44`](file:///Users/dimi/Desktop/10xdevs/bulk_tempo/test/test_helpers/mocks.dart#L44)

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands. Do not rename step titles. See `references/progress-format.md`.

### Phase 1: Consolidate Secure Storage Provider

#### Automated

- [x] 1.1 New provider created: `lib/core/providers/secure_storage_provider.dart` exists and exports `secureStorageProvider` — 3d83b6e
- [x] 1.2 Code compiles cleanly: `flutter analyze` reports zero errors or warnings in `lib/core/` and `lib/features/workout/data/datasources/` — 3d83b6e
- [x] 1.3 Existing tests pass: `flutter test test/core/localization/locale_notifier_test.dart test/widget_test.dart` — 3d83b6e

#### Manual

- [x] 1.4 Verify imports in IDE resolve cleanly without circular dependencies — 3d83b6e

### Phase 2: Implement Storage Cleanup & Cache Invalidation in AuthViewModel

#### Automated

- [x] 2.1 Code compiles cleanly: `flutter analyze` passes with zero issues across `lib/features/auth/` — eca77a3
- [x] 2.2 Unit tests run: `flutter test test/features/auth/presentation/view_models/auth_view_model_test.dart` — eca77a3

#### Manual

- [x] 2.3 Code review: verify `deleteAll()` is called within a `try/catch` fail-open block before provider invalidations and Firebase sign-out — eca77a3

### Phase 3: Comprehensive Unit & Widget Testing

#### Automated

- [x] 3.1 AuthViewModel tests pass: `flutter test test/features/auth/presentation/view_models/auth_view_model_test.dart` — 311e8de
- [x] 3.2 HomeShellScreen widget tests pass: `flutter test test/features/auth/presentation/views/home_shell_screen_test.dart` — 311e8de
- [x] 3.3 Full project test suite passes: `flutter test` — 311e8de
- [x] 3.4 Static analysis clean: `flutter analyze` reports 0 issues — 311e8de
- [x] 3.5 Code formatted: `dart format --output=none --set-exit-if-changed lib test` — 311e8de

#### Manual

- [ ] 3.6 Manual verification on device/simulator: log in, add Hevy API key, log out, confirm key is wiped from storage
