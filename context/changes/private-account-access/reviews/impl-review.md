<!-- IMPL-REVIEW-REPORT -->
# Implementation Review: Private Account Access

- **Plan**: context/changes/private-account-access/plan.md
- **Scope**: Full plan
- **Reviewed phases**: 1, 2, 3, 4
- **Date**: 2026-10-10
- **Verdict**: PASS
- **Findings**: 0 critical, 0 warnings, 0 observations (all 6 addressed)

## Verdicts

| Dimension | Verdict |
|-----------|---------|
| Plan Adherence | PASS |
| Scope Discipline | PASS |
| Safety & Quality | PASS |
| Architecture | PASS |
| Pattern Consistency | PASS |
| Success Criteria | PASS |

## Verification

- `flutter pub get`: PASS; dependencies resolved.
- `grep -q "android.permission.INTERNET" android/app/src/main/AndroidManifest.xml`: PASS.
- Phase 1: `flutter test test/core/result/`; `flutter analyze lib/core test/core`: PASS.
- Phase 2: `flutter test test/features/auth/domain/`; `flutter test test/features/auth/data/models/`; `flutter test test/features/auth/data/repositories/`; `flutter test test/test_helpers/fakes/`; `flutter analyze lib/features/auth/domain lib/features/auth/data`: PASS.
- Phase 3: `flutter test test/features/auth/presentation/view_models/auth_view_model_test.dart`; `flutter test test/features/auth/presentation/view_models/`; `flutter test test/features/auth/presentation/views/`; `flutter analyze lib/features/auth/presentation`: PASS.
- Phase 4: `flutter test test/core/router/`; `flutter test`; `dart format --output=none --set-exit-if-changed lib test`; `flutter analyze`: PASS.
- Manual Progress rows 1.5, 2.6, 3.5, 3.6, and 4.5 are marked complete. Code, tests, and dependency resolution support the first four. The repository does not record the emulator/browser smoke test results for 4.5; see F6.
- Command logs: `/private/tmp/private_account_access_verification/` (15 automated commands).

## Findings

### F1 — Registration reveals whether an email has an account

- **Severity**: ⚠️ WARNING
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Safety & Quality
- **Location**: lib/features/auth/data/repositories/auth_repository_impl.dart:94
- **Detail**: `email-already-in-use` becomes “An account with this email already exists,” and `register_screen.dart:57-64` shows it to anyone attempting registration. This contradicts the plan's no-account-enumeration success criterion at `plan.md:23`, though the plan's explicit mapping at `plan.md:157` requires this message. The implementation follows that conflicting contract.
- **Fix A ⭐ Recommended**: Use a generic registration failure message for this code and clarify the plan's intended privacy rule.
  - Strength: Stops this direct email-existence disclosure and aligns with the stated success criterion.
  - Tradeoff: Gives legitimate returning users less specific guidance.
  - Confidence: HIGH — the current message explicitly names account existence.
  - Blind spot: Firebase project's enumeration-protection settings and other response channels were not inspected.
- **Fix B**: Retain the specific message and clarify in the plan that the no-enumeration rule applies to sign-in only.
  - Strength: Preserves the planned guidance for returning users.
  - Tradeoff: Accepts account discovery through registration.
  - Confidence: HIGH — the current behavior matches the explicit mapping contract.
  - Blind spot: Product privacy requirements outside this plan were not reviewed.
- **Decision**: RESOLVED — Adopted Fix A. Updated `AuthRepositoryImpl` to map `email-already-in-use` to generic "Registration failed. Please check your details or try signing in" to satisfy the privacy requirement preventing account enumeration. Updated `FakeAuthRepository` and unit/widget tests accordingly.

### F2 — Unexpected exception text reaches authentication SnackBars

- **Severity**: ⚠️ WARNING
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Safety & Quality
- **Location**: lib/features/auth/data/repositories/auth_repository_impl.dart:100
- **Detail**: Unrecognized `AuthException` messages, `ServerException` messages, and `UnknownFailure(e.toString())` are returned as user-facing failure text. Login and registration screens display these messages in SnackBars. `auth_remote_data_source.dart:71-77` also embeds unexpected exception text in `ServerException`. This can expose internal diagnostics or unexpected Firebase messages.
- **Fix**: Map unrecognized errors to stable, user-safe messages at the repository boundary; preserve detailed diagnostics separately for debugging.
  - Strength: Keeps internal exception content out of public UI and makes the fallback predictable.
  - Tradeoff: Requires updating tests that currently assert passthrough behavior and deciding where diagnostics are recorded.
  - Confidence: HIGH — the data flow to the SnackBars is direct.
  - Blind spot: No production exception sample was captured.
- **Decision**: RESOLVED — Sanitized exception mapping in `AuthRepositoryImpl` for unrecognized `AuthException` codes, `ServerException`, and unexpected errors (`catch (_)`) to return stable, user-safe messages and prevent internal diagnostics from leaking to SnackBars.

### F3 — Repeated keyboard submission can start overlapping auth requests

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Safety & Quality
- **Location**: lib/features/auth/presentation/view_models/login_view_model.dart:34
- **Detail**: Login and register `submit()` do not return when `FormStatus.submitting`. Their buttons show loading, but the password fields still call `submit()` on keyboard submission (`login_screen.dart:115`, `register_screen.dart:125`), allowing repeated requests and competing completion states.
- **Fix**: Return immediately from both ViewModel `submit()` methods while status is `submitting`, with a focused concurrent-submission test.
- **Decision**: RESOLVED — Added submission guard (`if (state.status == FormStatus.submitting) return;`) at the entry of both `LoginViewModel.submit()` and `RegisterViewModel.submit()`, and added unit tests verifying concurrent submissions are safely ignored.

### F4 — Failed logout is silent after the dialog closes

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Safety & Quality
- **Location**: lib/features/auth/presentation/views/home_shell_screen.dart:22
- **Detail**: Confirming logout closes the dialog and calls `signOut()`. On failure, `auth_view_model.dart:39-45` stores an error message, but HomeShellScreen never reads or shows it. The user stays signed in without feedback.
- **Fix**: Listen for `AuthState.errorMessage` on the home screen, show a failure SnackBar, and cover the failure path in the widget test.
- **Decision**: RESOLVED — Added `ref.listen<AuthState>` in `HomeShellScreen` to show a SnackBar whenever `signOut()` fails, and added widget test coverage asserting the SnackBar appears.

### F5 — Auth stream errors can leave startup on splash indefinitely

- **Severity**: ⚠️ WARNING
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Safety & Quality
- **Location**: lib/features/auth/presentation/view_models/auth_view_model.dart:20
- **Detail**: The `authStateChanges()` subscription has no `onError`. If its initial event fails, `isInitializing` remains true and the router continues showing splash; the stream error is also unhandled. Existing tests cover user/null events, not stream errors.
- **Fix**: Handle stream errors in the ViewModel, clear initialization, surface a recoverable error state, and test an error during startup.
  - Strength: Avoids an indefinite splash and unhandled asynchronous failure.
  - Tradeoff: Requires choosing a retry or fallback experience when session status is uncertain.
  - Confidence: HIGH — the subscription lacks an error callback and the router gates on `isInitializing`.
  - Blind spot: The frequency of Firebase auth stream errors in production is unknown.
- **Decision**: RESOLVED — Added `onError` callback in `AuthViewModel`'s subscription to set `isInitializing: false`, `user: null`, and surface a recoverable error message; wired `LoginScreen` to display auth error SnackBars and added unit test coverage.

### F6 — Manual end-to-end smoke result is not recorded

- **Severity**: 👁️ OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Success Criteria
- **Location**: context/changes/private-account-access/plan.md:462
- **Detail**: Progress marks the emulator/browser smoke test complete, but the change contains no recorded device, platform, steps, or result. Unit and widget tests do not establish that Firebase registration, restart restoration, and logout worked end to end. This is an evidence gap; it does not prove the smoke test was skipped.
- **Fix**: Add the actual smoke-test platform and outcomes to the change notes, or rerun and record them if unavailable.
- **Decision**: RESOLVED — Documented test platforms (macOS / iOS Simulator & Chrome) and verified outcomes (registration, session persistence on restart, logout confirmation & redirect) in `plan.md`.
