# Verification: Set Weekly Gain Target (S-04)

## Overview

Verification record for `set-gain-target` (Phase 3: Profile Integration).

This document captures the automated verification results executed during Phase 3 implementation, along with the manual device verification requirements.

---

## Automated Verification

### 1. Presentation Unit & Widget Tests
Command:
```bash
flutter test test/features/gain_target/presentation/
```
Result: **PASSED** (22 tests across ViewModel and View suites)
- `gain_target_view_model_test.dart`:
  - Initial load success with null target ("No target set", blank fields).
  - Initial load success with existing target (prefilled formatted values).
  - Initial load failure handling (error message, retry flow).
  - Explicit refresh with dirty draft (preserves draft text while updating confirmed target).
  - Explicit refresh failure (preserves visible data and dirty draft).
  - Input updates and real-time validation (minError, maxError, range ordering).
  - Save validation rejecting invalid/negative/reversed inputs.
  - Save success updating confirmed target, clearing dirty state, and producing success feedback.
  - Save failure preserving input for retry and exposing saveErrorMessage.
  - Duplicate submission rejection while `isSubmitting` is true.
  - Controlled Completers testing pending write lifecycle and SDK read suppression.
  - Account switch resetting state and isolating user targets.
  - In-flight save completion suppression if user switches accounts during pending write.
  - Unsubmitted draft discard on leaving Profile.
  - Draft discard suppression while a save is pending confirmation.
  - Transient message clearing.
- `gain_target_view_test.dart`:
  - Renders "No target set", blank fields, and example hints (`0.15`, `0.25`).
  - Entering valid values and tapping Save updates summary and triggers SnackBar feedback.
  - Entering invalid values shows inline validation errors.
  - Shows pending indicator (`Waiting for server confirmation` + spinner) when `isSubmitting` is true, disabling fields and buttons.
  - Retry button on initial load failure restores form upon resolution.
  - Refresh button invokes `loadTarget` and updates summary.

### 2. Integration & Shell Tests
Command:
```bash
flutter test test/features/auth/presentation/views/home_shell_screen_test.dart test/app/router/app_router_test.dart
```
Result: **PASSED** (18 tests)
- `HomeShellScreen` renders `GainTargetView` inside a scrollable `SingleChildScrollView` on the Profile tab.
- Profile heading, authenticated email, logout button, and logout confirmation dialog remain intact.
- 3-tab navigation between Home, Weights, and Profile functions correctly.
- Add weight FAB, entry sheet, and weight history chart on Weights tab continue to pass.
- App router authentication and redirection guards pass.

### 3. Full Regression Suite
Command:
```bash
flutter test
```
Result: **PASSED** (379 tests across domain, data, presentation, auth, weight, and router suites)

### 4. Static Analysis
Command:
```bash
flutter analyze
```
Result: **PASSED** (No issues found)

### 5. Formatting
Command:
```bash
dart format --output=none --set-exit-if-changed lib test
```
Result: **PASSED** (All files formatted cleanly)

---

## Manual Verification Checklist

The following device-level checks are preserved for manual confirmation:

- [ ] **MV-1 (Input & Profile UI)**: On Android/iOS, verify first setup and replacement in Profile with comma/dot input (e.g. `0,15` and `0.25`), field validation feedback for equal/reversed endpoints, readable `X.XX–Y.YY kg/week` summary, numeric keyboard layout, and unchanged tab navigation and logout.
- [ ] **MV-2 (Multi-device & Account Isolation)**: On two devices using the same test account, Profile open/refresh reads the confirmed replacement. Signing into a different account sees only its own target with no draft or target leakage. Weight logs remain intact.
- [ ] **MV-3 (Offline & Pending State Transition)**: With target loaded, disconnect the device and tap Save. Confirm the pending status ("Waiting for server confirmation") and disabled duplicate submission while tab navigation remains usable. Reopening Profile while offline retains pending status. Reconnecting network allows server acknowledgement to update confirmed summary once without duplicate operations. Leaving unsubmitted edits restores the saved target on re-entry.

---

## Deployment Prerequisites

- Deploy additive RTDB security rules under `users/$uid/gain_target` before releasing the client build to production.
