# Private Account Access — Plan Brief

> Full plan: `context/changes/private-account-access/plan.md`

## What & Why

Bulk Tempo requires individual, isolated user accounts so lifters can track body weight and workout data privately across their devices. This change implements slice S-01 (`private-account-access`), delivering email/password registration, login, session persistence, and logout via Firebase Authentication.

## Starting Point

The Flutter project initializes `firebase_core` and `firebase_auth` in `lib/main.dart`, but displays only a placeholder "Hello World!" screen. No auth domain entities, data sources, ViewModels, or routes exist yet, and core architectural primitives (`Result<S, F>`, `GoRouter`) are not yet installed.

## Desired End State

Users can launch the app, see an initial splash check, register a new account or log in with email and password, stay logged in across app restarts, and safely log out from an authenticated home shell. All errors (credential errors, duplicates, offline state) display clear, secure user feedback without application crashes.

## Key Decisions Made

| Decision | Choice | Why (1 sentence) | Source |
| --- | --- | --- | --- |
| Password reset | Defer self-service reset | Focuses S-01 strictly on registration, login, and session persistence; resets handled via console. | Plan (Roadmap Q4) |
| Auth UI structure | Dedicated `/login` and `/register` routes | Provides clean GoRouter URLs, predictable deep-links, and clean single-responsibility ViewModels. | Plan |
| Authenticated landing | Authenticated home shell (`/home`) | Confirms session persistence and auth state end-to-end, providing the host scaffold for S-02. | Plan |
| Email verification | Immediate access upon sign-up | Removes onboarding friction for MVP and eliminates external mail link dependencies. | Plan |
| Session restoration | Splash screen holding route (`/`) | Prevents visual flickering or premature login screen flashes during cold launches. | Plan |
| Password validation | Standard min 6 characters | Matches Firebase Auth default requirements with instant client-side feedback. | Plan |
| Error presentation | Mapped banners / SnackBars | Balances security best practices (no user enumeration) with clear feedback. | Plan |
| Test strategy | Mocktail for Repos + Fake for UI | Fast, headless, deterministic tests fully matching `context/documentation/06_testing_strategy.md`. | Plan |
| Logout UX | Confirmation dialog before sign-out | Prevents accidental sign-outs on mobile touch screens. | Plan |
| Android permission | Add release `INTERNET` permission | Fixes verified configuration gap so release APKs can reach Firebase Auth. | Plan |

## Scope

**In scope:**
- Core `Result<S, F>`, `AppFailure`, exceptions, and test helpers (`mocks.dart`, `pump_app.dart`).
- Auth domain (`UserEntity`, `AuthRepository`) and data layer (`UserDto`, `AuthRemoteDataSource`, `AuthRepositoryImpl`).
- Presentation layer (`AuthState`, `AuthViewModel`, `LoginViewModel`, `RegisterViewModel`, `SplashScreen`, `LoginScreen`, `RegisterScreen`, `HomeShellScreen`).
- GoRouter configuration with `RouterRefreshNotifier` and authentication redirect guards.
- Unit and widget tests for all layers.

**Out of scope:**
- Self-service password reset ("Forgot password").
- Mandatory email verification gating before app access.
- Weight history and dashboard features (handled in subsequent slices S-02 and S-06).
- Third-party social providers (Google, Apple) and biometric sign-in.

## Architecture / Approach

Follows Feature-First MVVM + Clean Architecture:
```text
View (Login/Register/Home/Splash)
  └── ViewModel (Notifier / AutoDisposeNotifier)
        └── AuthRepository (Domain Contract)
              └── AuthRepositoryImpl (Data: maps exceptions -> Result<T, AppFailure>)
                    └── AuthRemoteDataSource (wraps FirebaseAuth)
```
GoRouter monitors `authViewModelProvider` via `RouterRefreshNotifier` and automatically redirects unauthenticated users to `/login`, authenticated users to `/home`, and splash during initial session checks.

## Phases at a Glance

| Phase | What it delivers | Key risk |
| --- | --- | --- |
| 1. Dependencies & Core | `go_router`, `mocktail`, `Result<S, F>`, `AppFailure`, test helpers | Dependency version resolution |
| 2. Domain & Data | `UserEntity`, `AuthRepository`, `AuthRemoteDataSource`, `FakeAuthRepository` | Firebase exception mapping edge cases |
| 3. Presentation (MVVM) | ViewModels, form validation, `LoginScreen`, `RegisterScreen`, `HomeShellScreen` | State transitions & error SnackBar listeners |
| 4. Navigation & E2E | `GoRouter` redirect guards, `MaterialApp.router` migration, test suite | Cold start session restoration race |

**Prerequisites:** Active Firebase project with Email/Password provider enabled.
**Estimated effort:** ~4 implementation cycles across 4 phases.

## Open Risks & Assumptions

- **Firebase Console configuration:** Assumes Email/Password authentication provider is enabled in the Firebase Console for project `bulk-tempo`.
- **Local session latency:** Assumes Firebase local token hydration finishes within normal splash screen display window.

## Success Criteria (Summary)

- User can register, log in, and log out with email and password via Firebase Auth.
- Session persists across app restarts without flashing the login screen.
- All unit, widget, and router redirect tests pass with zero analyzer warnings.
