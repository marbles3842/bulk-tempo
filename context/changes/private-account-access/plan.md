# Private Account Access Implementation Plan

## Overview

Implement **S-01: Private Account Access (`private-account-access`)** for Bulk Tempo following Feature-First Clean Architecture and MVVM with Riverpod and GoRouter. Users will be able to register a private account with email and password, log in, persist their session across app restarts, and log out securely via Firebase Authentication.

## Current State Analysis

- **Firebase SDKs**: `firebase_core` (3.12.1) and `firebase_auth` (5.5.1) are installed in `pubspec.yaml`, initialized in `lib/main.dart`, and configured for Android, iOS, and Web via `lib/firebase_options.dart`.
- **UI & Navigation**: The application currently renders a single placeholder `MainApp` with "Hello World!" in `lib/main.dart:15`. There are no feature screens or routes.
- **Architectural Foundations**: The project specifications in `.documentation/` prescribe Feature-First MVVM with functional `Result<T, AppFailure>`, `GoRouter` redirect guards with `RouterRefreshNotifier`, and headless Riverpod ViewModel tests. None of these core utilities exist yet in `lib/core/` or `test/test_helpers/`.
- **Package Gaps**: `go_router` and `mocktail` are missing from `pubspec.yaml`.
- **Platform Gaps**: `android/app/src/main/AndroidManifest.xml` lacks `android.permission.INTERNET` for release builds.

## Desired End State

After this plan is complete:
1. Users can launch the app, see an initial splash check, and if unauthenticated, be routed to `/login`.
2. Users without an account can navigate to `/register`, enter an email and password (minimum 6 characters), and immediately create an account and be logged into the app.
3. Users with existing accounts can enter their email and password on `/login` to sign in.
4. Active sessions persist across app restarts (cold launches bypass `/login` and redirect to the authenticated shell).
5. On the authenticated shell (`/home`), the user sees their email address and a logout button. Tapping logout displays a confirmation dialog; confirming signs out the user and GoRouter redirects back to `/login`.
6. Failed sign-ins, duplicate registration emails, and offline connection errors display clear, user-friendly error banners/SnackBars without leaking account enumeration or crashing.
7. The codebase has comprehensive unit tests for domain, data, and presentation layers, plus widget tests and router redirect tests, passing `flutter analyze` and `flutter test`.

### Key Discoveries:

- `bulk_tempo/lib/main.dart:10` already runs `await Firebase.initializeApp(...)` before `runApp`.
- `bulk_tempo/.documentation/05_navigation.md:121-195` specifies the exact `RouterRefreshNotifier` pattern connecting Riverpod auth state to GoRouter's `refreshListenable` and `redirect`.
- `bulk_tempo/.documentation/03_state_management_mvvm.md:40-82` provides the composite form state pattern using `copyWith` and `_sentinel`.
- `bulk_tempo/.documentation/04_data_and_domain.md:7-71` provides the functional `Result<S, F>` and `AppFailure` definitions.
- `bulk_tempo/.documentation/06_testing_strategy.md:76-155` provides the headless `ProviderContainer` testing pattern for ViewModels.

## What We're NOT Doing

- **Self-service password reset ("Forgot password")**: Deferred to a subsequent iteration per Roadmap Open Question #4 and user decision. Users who lose credentials in MVP will be assisted via Firebase Console.
- **Email verification gating**: No blocking verification link; users receive immediate access upon registration.
- **Weight logging or dashboard features**: S-02 (weight history) and S-06 (dashboard) remain separate future slices; S-01 builds only the authenticated shell with user email and logout.
- **Third-party / OAuth login**: Google Sign-In, Apple Sign-In, and biometric auth are out of scope for MVP; PRD FR-001 specifies email and password.
- **Multi-user account switching or profile editing**: Out of scope for S-01.

## Implementation Approach

1. **Foundations First**: Add missing dependencies (`go_router`, `mocktail`), add the Android release internet permission, and create core infrastructure (`Result`, `AppFailure`, `exceptions`, test helpers).
2. **Domain & Data**: Build pure Dart `UserEntity` and abstract `AuthRepository`, implement `UserDto`, `AuthRemoteDataSource` (wrapping `FirebaseAuth`), `AuthRepositoryImpl` with mapped exceptions, and create `FakeAuthRepository` for testing.
3. **Presentation & MVVM**: Implement `AuthState`/`AuthViewModel` (session tracking), form states (`LoginFormState`, `RegisterFormState`), ViewModels, UI screens (`SplashScreen`, `LoginScreen`, `RegisterScreen`, `HomeShellScreen`), and reusable widgets.
4. **Navigation & Verification**: Wire `GoRouter` with `RouterRefreshNotifier` and auth redirect guard, migrate `main.dart` to `MaterialApp.router`, add router tests, and execute full test/analyze suite.

## Critical Implementation Details

- **Session Initialization Race**: On cold app launch, `FirebaseAuth.currentUser` may initially be null while Firebase initializes the local session from secure storage. `AuthState` must maintain an `isInitializing` state so `SplashScreen` displays until `authStateChanges()` emits the restored user, preventing a momentary flash of the login screen.
- **Router Refresh Listener Lifecycle**: `RouterRefreshNotifier` must properly dispose its listener on disposal (`ref.onDispose(refreshNotifier.dispose)`) to avoid memory leaks during app reloads or testing.
- **Error Mapping Security**: `FirebaseAuthException` error codes (`user-not-found`, `wrong-password`, `invalid-credential`) must map to a unified user message ("Invalid email or password") to prevent email enumeration, while `email-already-in-use` explicitly guides returning users to sign in.

---

## Phase 1: Dependencies, Core Architecture Foundations & Test Harness

### Overview

Add missing project dependencies, configure Android release internet permissions, implement the core functional `Result<S, F>` pattern and `AppFailure` hierarchy, and create foundational test helpers.

### Changes Required:

#### 1. Dependencies Update
**File**: `bulk_tempo/pubspec.yaml`
**Intent**: Add `go_router` for declarative navigation and `mocktail` for test mocking.
**Contract**:
- `dependencies`: add `go_router: ^14.8.1`
- `dev_dependencies`: add `mocktail: ^1.0.4`

#### 2. Android Release Internet Permission
**File**: `bulk_tempo/android/app/src/main/AndroidManifest.xml`
**Intent**: Allow Android release builds to make network requests to Firebase Auth.
**Contract**: Add `<uses-permission android:name="android.permission.INTERNET"/>` inside `<manifest>`.

#### 3. Core Functional Result Pattern
**File**: `bulk_tempo/lib/core/result/result.dart`
**Intent**: Pure Dart functional Result type eliminating unhandled exceptions in accordance with `.documentation/04_data_and_domain.md`.
**Contract**: Sealed class `Result<S, F>` with `Success<S, F>`, `Failure<S, F>`, and `when<R>({required R Function(S) success, required R Function(F) failure})`.

#### 4. Core Failures Hierarchy
**File**: `bulk_tempo/lib/core/errors/failures.dart`
**Intent**: Typed failure domain hierarchy representing system, network, and auth failures.
**Contract**: Sealed class `AppFailure(this.message, {this.statusCode})` extended by `ServerFailure`, `NetworkFailure`, `AuthFailure`, `ValidationFailure`, `UnknownFailure`.

#### 5. Core Exceptions Hierarchy
**File**: `bulk_tempo/lib/core/errors/exceptions.dart`
**Intent**: Low-level exceptions thrown by data sources before repository translation.
**Contract**: `AppException`, `ServerException`, `NetworkException`, `AuthException(this.code, this.message)`.

#### 6. Test Helpers Setup
**File**: `bulk_tempo/test/test_helpers/pump_app.dart`
**Intent**: Reusable `pumpApp` extension on `WidgetTester` wrapping tested widgets in `ProviderScope` and `MaterialApp`.
**Contract**: `extension PumpAppExtension on WidgetTester { Future<void> pumpApp(Widget widget, {List<Override> overrides = const []}); }`.

#### 7. Core Result Unit Tests
**File**: `bulk_tempo/test/core/result/result_test.dart`
**Intent**: Unit test `Result.success` and `Result.failure` behavior and pattern matching.
**Contract**: Unit tests verifying `when` calls appropriate callback with correct payload.

### Success Criteria:

#### Automated Verification:
- Core Result type and pattern matching unit tests pass: `flutter test test/core/result/`
- Dependencies resolve cleanly: `flutter pub get`
- Android manifest includes release internet permission: `grep -q "android.permission.INTERNET" android/app/src/main/AndroidManifest.xml`
- Static analysis of core files passes without errors: `flutter analyze lib/core test/core`

#### Manual Verification:
- Verify pubspec dependencies and versions resolve without version conflicts

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Phase 2: Auth Domain & Data Layers

### Overview

Implement the domain models and repository contracts, followed by the Firebase-backed data source, DTOs, repository implementation with error translation, and a fake repository test fixture.

### Changes Required:

#### 1. Domain User Entity
**File**: `bulk_tempo/lib/features/auth/domain/models/user_entity.dart`
**Intent**: Pure Dart business entity representing an authenticated user.
**Contract**: `UserEntity({required String id, required String email, String? displayName})` with value equality (`==`), `hashCode`, and `copyWith`. No Flutter or Firebase dependencies.

#### 2. Domain Auth Repository Interface
**File**: `bulk_tempo/lib/features/auth/domain/repositories/auth_repository.dart`
**Intent**: Abstract contract defining all authentication operations required by the domain.
**Contract**:
```dart
abstract class AuthRepository {
  Stream<UserEntity?> authStateChanges();
  Future<Result<UserEntity, AppFailure>> signInWithEmailAndPassword({required String email, required String password});
  Future<Result<UserEntity, AppFailure>> signUpWithEmailAndPassword({required String email, required String password});
  Future<Result<void, AppFailure>> signOut();
  UserEntity? get currentUser;
}
```

#### 3. Data User DTO
**File**: `bulk_tempo/lib/features/auth/data/models/user_dto.dart`
**Intent**: DTO mapping between Firebase `User` instance and domain `UserEntity`.
**Contract**: `UserDto({required String id, required String email, String? displayName})` with `UserDto.fromFirebaseUser(User user)` and `toEntity() -> UserEntity`.

#### 4. Auth Remote Data Source
**File**: `bulk_tempo/lib/features/auth/data/datasources/auth_remote_data_source.dart`
**Intent**: Direct interface and implementation communicating with `firebase_auth`.
**Contract**: `AuthRemoteDataSource` contract and `AuthRemoteDataSourceImpl(FirebaseAuth)` catching `FirebaseAuthException` / socket errors and throwing typed `AuthException` / `NetworkException`. Exposes `authRemoteDataSourceProvider`.

#### 5. Auth Repository Implementation
**File**: `bulk_tempo/lib/features/auth/data/repositories/auth_repository_impl.dart`
**Intent**: Concrete `AuthRepository` translating data source exceptions into `Result<T, AppFailure>`.
**Contract**: `AuthRepositoryImpl(AuthRemoteDataSource)` implementing `AuthRepository`. Translates `AuthException` codes (`user-not-found`, `wrong-password`, `invalid-credential` -> "Invalid email or password", `email-already-in-use` -> "An account with this email already exists", `too-many-requests` -> "Too many attempts. Please try again later") to `AuthFailure`, and network exceptions to `NetworkFailure`. Exposes `authRepositoryProvider`.

#### 6. Mocktail Mocks Registry
**File**: `bulk_tempo/test/test_helpers/mocks.dart`
**Intent**: Central registry of mocktail mocks for tests.
**Contract**: `class MockFirebaseAuth extends Mock implements FirebaseAuth {}`, `class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}`, `class MockUser extends Mock implements User {}`.

#### 7. In-Memory Fake Auth Repository
**File**: `bulk_tempo/test/test_helpers/fakes/fake_auth_repository.dart`
**Intent**: Fast, deterministic in-memory fake repository for headless ViewModel and Widget tests without external dependencies.
**Contract**: Implements `AuthRepository` with an internal `StreamController<UserEntity?>`, simulated user map, and controllable error triggers.

#### 8. Domain and Data Unit Tests
**Files**:
- `bulk_tempo/test/features/auth/domain/models/user_entity_test.dart`
- `bulk_tempo/test/features/auth/data/models/user_dto_test.dart`
- `bulk_tempo/test/features/auth/data/repositories/auth_repository_impl_test.dart`
**Intent**: Unit test entity value equality, DTO conversion, and repository error mapping.
**Contract**: Tests asserting success returns `Success<UserEntity>` and failure cases return corresponding `Failure<AppFailure>`.

### Success Criteria:

#### Automated Verification:
- UserEntity domain unit tests pass: `flutter test test/features/auth/domain/`
- UserDto serialization and mapping unit tests pass: `flutter test test/features/auth/data/models/`
- AuthRepositoryImpl repository unit tests with exception mapping pass: `flutter test test/features/auth/data/repositories/`
- FakeAuthRepository passes contract sanity tests: `flutter test test/test_helpers/fakes/`
- Static analysis of auth domain and data layers passes: `flutter analyze lib/features/auth/domain lib/features/auth/data`

#### Manual Verification:
- Inspect exception-to-failure mapping table ensuring FirebaseAuthException codes map cleanly

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Phase 3: Auth Presentation Layer (MVVM & UI Screens)

### Overview

Build the presentation layer: session state management (`AuthState`, `AuthViewModel`), form states and ViewModels (`LoginViewModel`, `RegisterViewModel`), reusable UI widgets, and full screens (`SplashScreen`, `LoginScreen`, `RegisterScreen`, `HomeShellScreen`), backed by headless ViewModel unit tests and widget tests.

### Changes Required:

#### 1. Global Session Auth State & ViewModel
**Files**:
- `bulk_tempo/lib/features/auth/presentation/view_models/auth_state.dart`
- `bulk_tempo/lib/features/auth/presentation/view_models/auth_view_model.dart`
**Intent**: Track app-level authentication state to drive route guards and session lifecycle.
**Contract**:
- `AuthState({required UserEntity? user, required bool isInitializing, String? errorMessage})` with `bool get isAuthenticated => user != null;`.
- `AuthViewModel extends Notifier<AuthState>` listening to `authRepository.authStateChanges()` on `build()`, providing `Future<void> signOut()`. Exposes `authViewModelProvider`.

#### 2. Login Form State & ViewModel
**Files**:
- `bulk_tempo/lib/features/auth/presentation/view_models/login_form_state.dart`
- `bulk_tempo/lib/features/auth/presentation/view_models/login_view_model.dart`
**Intent**: Manage login screen form inputs, client-side validation, and sign-in submission.
**Contract**:
- `LoginFormState({String email = '', String password = '', FormStatus status = FormStatus.initial, String? errorMessage})` using `_sentinel` in `copyWith`.
- `LoginViewModel extends AutoDisposeNotifier<LoginFormState>` with `updateEmail`, `updatePassword`, `Future<void> submit()`.

#### 3. Register Form State & ViewModel
**Files**:
- `bulk_tempo/lib/features/auth/presentation/view_models/register_form_state.dart`
- `bulk_tempo/lib/features/auth/presentation/view_models/register_view_model.dart`
**Intent**: Manage registration inputs, client-side validation (email format regex, password length >= 6), and account creation.
**Contract**:
- `RegisterFormState({String email = '', String password = '', FormStatus status = FormStatus.initial, String? errorMessage})`.
- `RegisterViewModel extends AutoDisposeNotifier<RegisterFormState>` with `updateEmail`, `updatePassword`, `Future<void> submit()`.

#### 4. Reusable Auth UI Widgets
**Files**:
- `bulk_tempo/lib/features/auth/presentation/widgets/auth_text_field.dart`
- `bulk_tempo/lib/features/auth/presentation/widgets/auth_button.dart`
**Intent**: Shared form input fields with validation and styled primary button with loading indicator.
**Contract**: Standard presentation widgets receiving callbacks, without direct repository dependencies.

#### 5. Splash Screen
**File**: `bulk_tempo/lib/features/auth/presentation/views/splash_screen.dart`
**Intent**: Visual holding screen while Firebase initializes and determines session status.
**Contract**: `ConsumerWidget` displaying app branding and a `CircularProgressIndicator`.

#### 6. Login Screen
**File**: `bulk_tempo/lib/features/auth/presentation/views/login_screen.dart`
**Intent**: Login form UI with email and password inputs, submit button, error SnackBar listener, and link to register.
**Contract**: `ConsumerWidget` watching `loginViewModelProvider`, listening for errors, linking to `/register`.

#### 7. Register Screen
**File**: `bulk_tempo/lib/features/auth/presentation/views/register_screen.dart`
**Intent**: Registration form UI with validation, submit button, error SnackBar listener (with explicit conflict message), and link to login.
**Contract**: `ConsumerWidget` watching `registerViewModelProvider`, listening for errors, linking to `/login`.

#### 8. Authenticated Home Shell Screen
**File**: `bulk_tempo/lib/features/auth/presentation/views/home_shell_screen.dart`
**Intent**: Post-login landing view for S-01 displaying user info and a logout button with confirmation dialog.
**Contract**: `ConsumerWidget` displaying `user.email`, welcome message, and an action button opening an `AlertDialog` to confirm logout before calling `ref.read(authViewModelProvider.notifier).signOut()`.

#### 9. ViewModel Unit Tests
**Files**:
- `bulk_tempo/test/features/auth/presentation/view_models/auth_view_model_test.dart`
- `bulk_tempo/test/features/auth/presentation/view_models/login_view_model_test.dart`
- `bulk_tempo/test/features/auth/presentation/view_models/register_view_model_test.dart`
**Intent**: Headless unit tests using `ProviderContainer` and `FakeAuthRepository` to verify state transitions and validation logic.
**Contract**: Verify `submitting` -> `success` / `failure` states and client-side validation rules.

#### 10. Screen Widget Tests
**Files**:
- `bulk_tempo/test/features/auth/presentation/views/login_screen_test.dart`
- `bulk_tempo/test/features/auth/presentation/views/register_screen_test.dart`
- `bulk_tempo/test/features/auth/presentation/views/home_shell_screen_test.dart`
**Intent**: Widget tests verifying screen rendering, text entry, button clicks, and SnackBar error displays.
**Contract**: Widget tests executed via `tester.pumpApp(...)`.

### Success Criteria:

#### Automated Verification:
- AuthViewModel session state unit tests pass: `flutter test test/features/auth/presentation/view_models/auth_view_model_test.dart`
- Login and Register ViewModel form unit tests pass: `flutter test test/features/auth/presentation/view_models/`
- LoginScreen, RegisterScreen, and HomeShellScreen widget tests pass: `flutter test test/features/auth/presentation/views/`
- Static analysis of presentation layer passes: `flutter analyze lib/features/auth/presentation`

#### Manual Verification:
- Verify input validation displays client-side errors for invalid emails or short passwords
- Verify logout confirmation dialog shows Cancel and Log Out actions

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Phase 4: GoRouter Integration, Route Guards & End-to-End Verification

### Overview

Integrate `GoRouter` with `RouterRefreshNotifier` and authentication redirect guards, migrate `main.dart` to `MaterialApp.router`, add router redirect tests, and run end-to-end static analysis and verification.

### Changes Required:

#### 1. Route Constants
**Files**:
- `bulk_tempo/lib/core/router/route_paths.dart`
- `bulk_tempo/lib/core/router/route_names.dart`
**Intent**: Centralized string constants for route paths and names.
**Contract**:
- `RoutePaths`: `splash = '/'`, `login = '/login'`, `register = '/register'`, `home = '/home'`.
- `RouteNames`: `splash = 'splash'`, `login = 'login'`, `register = 'register'`, `home = 'home'`.

#### 2. Router Refresh Notifier Bridge
**File**: `bulk_tempo/lib/core/router/router_refresh_notifier.dart`
**Intent**: Bridge Riverpod auth state changes to GoRouter's `refreshListenable` in accordance with `.documentation/05_navigation.md`.
**Contract**:
```dart
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(authViewModelProvider, (_, __) => notifyListeners());
  }
}
```

#### 3. App Router Provider & Redirect Guards
**File**: `bulk_tempo/lib/core/router/app_router.dart`
**Intent**: GoRouter configuration with reactive redirect guards protecting routes.
**Contract**:
- During `authState.isInitializing`: redirect to `RoutePaths.splash`.
- Unauthenticated user attempting to access protected route (e.g. `/home`): redirect to `RoutePaths.login`.
- Authenticated user attempting to access auth routes (`/login`, `/register`, `/splash`): redirect to `RoutePaths.home`.
- Exposes `appRouterProvider = Provider<GoRouter>`.

#### 4. App Root Component
**File**: `bulk_tempo/lib/app/app.dart`
**Intent**: Application root widget configuring `MaterialApp.router` with theme and router provider.
**Contract**: `class BulkTempoApp extends ConsumerWidget` returning `MaterialApp.router(routerConfig: ref.watch(appRouterProvider))`.

#### 5. Main Entry Point Migration
**File**: `bulk_tempo/lib/main.dart`
**Intent**: Replace placeholder `MainApp` with `BulkTempoApp` inside `ProviderScope`.
**Contract**: `runApp(const ProviderScope(child: BulkTempoApp()))`.

#### 6. Router Redirection Unit & Widget Tests
**File**: `bulk_tempo/test/core/router/app_router_test.dart`
**Intent**: Test GoRouter redirect logic under unauthenticated, authenticated, and initializing states.
**Contract**: Tests verifying location equals `/login` when unauthenticated, `/home` when authenticated, and `/` during splash.

#### 7. Update Widget Test Placeholder
**File**: `bulk_tempo/test/widget_test.dart`
**Intent**: Update initial starter widget test to test `BulkTempoApp`.
**Contract**: Clean passing test mounting `BulkTempoApp` with `FakeAuthRepository`.

### Success Criteria:

#### Automated Verification:
- Router redirection unit and widget tests pass: `flutter test test/core/router/`
- Full test suite passes across the entire project: `flutter test`
- Code formatting passes with zero diffs: `dart format --output=none --set-exit-if-changed lib test`
- Static analysis passes with zero warnings or errors: `flutter analyze`

#### Manual Verification:
- End-to-end smoke test on emulator or browser

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Testing Strategy

### Unit Tests:
- `Result<S, F>`: Success, failure, and `.when()` pattern matching.
- `UserEntity`: Equality, hashCode, copyWith.
- `UserDto`: Conversion to/from Firebase User.
- `AuthRepositoryImpl`: Successful sign-in/sign-up/sign-out, and mapped exceptions (`user-not-found`, `wrong-password`, `email-already-in-use`, `NetworkException`).
- `AuthViewModel`: Initializing state, user session synchronization from stream, sign-out transition.
- `LoginViewModel` & `RegisterViewModel`: Email regex validation, password length checks, form submission lifecycle (`initial` -> `submitting` -> `success` / `failure`).

### Integration & Widget Tests:
- `LoginScreen`: Form rendering, text input updates, error SnackBar display, navigation link to register.
- `RegisterScreen`: Form rendering, validation error messages, conflict message with login link.
- `HomeShellScreen`: Displays logged-in user email, shows logout confirmation dialog on tap, executes sign-out on confirm.
- `GoRouter`: Redirects unauthenticated users to `/login`, authenticated users to `/home`, and shows `/` during initialization.

### Manual Testing Steps:
1. Launch app with fresh storage — verify app opens directly to `/login`.
2. Tap "Create an account" — verify transition to `/register`.
3. Try submitting invalid email or 4-character password — verify client-side validation errors prevent submission.
4. Enter valid email and password — tap "Create Account" — verify account is created and user immediately lands on `/home` showing their email.
5. Kill and restart the app — verify app opens splash briefly and automatically restores session to `/home` without showing `/login`.
6. Tap "Log Out" — verify confirmation dialog appears. Tap "Cancel" — verify user stays on `/home`. Tap "Log Out" again and confirm — verify user is signed out and redirected to `/login`.
7. Enter incorrect password on `/login` — verify error SnackBar displays "Invalid email or password".

## Performance Considerations

- **Headless ViewModel Testing**: ViewModels use pure Dart without `BuildContext` or Flutter widget tree dependencies, executing in microseconds via `ProviderContainer`.
- **Firebase Auth Caching**: Firebase Auth caches the JWT token locally; `authStateChanges()` emits immediately after disk read, keeping the splash display under 200ms on cold starts.
- **AutoDispose ViewModels**: Form ViewModels (`LoginViewModel`, `RegisterViewModel`) use `autoDispose` so their form state is released from memory as soon as the user navigates away from the screen.

## Migration Notes

- **Greenfield Foundation**: This change introduces the core `Result<S, F>`, `AppFailure`, `AppRouter`, and `features/auth/` modules. It replaces the initial `MainApp` placeholder in `lib/main.dart` with `BulkTempoApp`. No existing database data needs migration.

## References

- Upstream roadmap: `context/foundation/roadmap.md` (Slice S-01: `private-account-access`)
- Product requirements: `context/foundation/prd.md` (FR-001, Access Control)
- Tech stack specification: `context/foundation/tech-stack.md` (Flutter, Firebase Auth)
- Architecture overview: `bulk_tempo/.documentation/01_architecture_overview.md`
- State management & MVVM: `bulk_tempo/.documentation/03_state_management_mvvm.md`
- Data & Domain layers: `bulk_tempo/.documentation/04_data_and_domain.md`
- Navigation & Router: `bulk_tempo/.documentation/05_navigation.md`
- Testing strategy: `bulk_tempo/.documentation/06_testing_strategy.md`

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands. Do not rename step titles. See `references/progress-format.md`.

### Phase 1: Dependencies, Core Architecture Foundations & Test Harness

#### Automated

- [x] 1.1 Core Result type and pattern matching unit tests pass — 5cf2ca1
- [x] 1.2 Dependencies resolve cleanly — 5cf2ca1
- [x] 1.3 Android manifest includes release internet permission — 5cf2ca1
- [x] 1.4 Static analysis of core files passes without errors — 5cf2ca1

#### Manual

- [x] 1.5 Verify pubspec dependencies and versions resolve without version conflicts — 5cf2ca1

### Phase 2: Auth Domain & Data Layers

#### Automated

- [x] 2.1 UserEntity domain unit tests pass — 4d5e046
- [x] 2.2 UserDto serialization and mapping unit tests pass — 4d5e046
- [x] 2.3 AuthRepositoryImpl repository unit tests with exception mapping pass — 4d5e046
- [x] 2.4 FakeAuthRepository passes contract sanity tests — 4d5e046
- [x] 2.5 Static analysis of auth domain and data layers passes — 4d5e046

#### Manual

- [x] 2.6 Inspect exception-to-failure mapping table ensuring FirebaseAuthException codes map cleanly — 4d5e046

### Phase 3: Auth Presentation Layer (MVVM & UI Screens)

#### Automated

- [x] 3.1 AuthViewModel session state unit tests pass — f10b429
- [x] 3.2 Login and Register ViewModel form unit tests pass — f10b429
- [x] 3.3 LoginScreen, RegisterScreen, and HomeShellScreen widget tests pass — f10b429
- [x] 3.4 Static analysis of presentation layer passes — f10b429

#### Manual

- [ ] 3.5 Verify input validation displays client-side errors for invalid emails or short passwords
- [ ] 3.6 Verify logout confirmation dialog shows Cancel and Log Out actions

### Phase 4: GoRouter Integration, Route Guards & End-to-End Verification

#### Automated

- [ ] 4.1 Router redirection unit and widget tests pass
- [ ] 4.2 Full test suite passes across the entire project
- [ ] 4.3 Code formatting passes with zero diffs
- [ ] 4.4 Static analysis passes with zero warnings or errors

#### Manual

- [ ] 4.5 End-to-end smoke test on emulator or browser
