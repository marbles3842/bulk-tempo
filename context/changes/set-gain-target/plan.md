# Set Weekly Gain Target Implementation Plan

## Overview

Implement roadmap slice S-04 (`set-gain-target`, FR-007 and FR-012). An authenticated user can set, replace, and read one private weekly gain range in the Profile tab, including after signing in on another device. The user approved ten planning decisions and the three phases below on 2026-10-11; implementation has not started.

## Current State Analysis

The application at `bulk_tempo` revision `547b47085e0ede0cc4f103f65231a620eab2c119` already implements authentication and dated weight history. Its working tree was clean during discovery. The roadmap's old Baseline section predates these implementations; the source and completed S-01/S-02 slices are the implementation baseline.

- Profile currently contains a heading, email, and logout button; the shell mounts only the selected tab (`bulk_tempo/lib/features/auth/presentation/views/home_shell_screen.dart:86`, `:142`). There is no gain-target feature.
- Weight persistence demonstrates user-scoped RTDB paths, DTOs, repository providers, and typed failures (`bulk_tempo/lib/features/weight/data/datasources/weight_remote_data_source.dart:29`, `bulk_tempo/lib/features/weight/data/repositories/weight_repository_impl.dart:12`). The shared database provider currently lives inside the weight data source.
- `bulk_tempo/database.rules.json:7` already grants access only to the matching authenticated UID. Its only schema validation is for weight entries; no emulator rules-test harness exists.
- Domain interfaces use pure Dart and `Result<T, AppFailure>`; presentation uses immutable Riverpod state and repository interfaces. Follow `.documentation/01_architecture_overview.md` through `06_testing_strategy.md` under `bulk_tempo/`.
- The existing input convention accepts a comma or dot and up to two decimals (`bulk_tempo/lib/core/utils/weight_validators.dart:12`). Its 20–300 kg body-weight limits do not apply to weekly gain.

## Desired End State

Profile shows a “Weekly gain target” section alongside account details and logout. A successfully loaded absent record displays “No target set,” blank minimum/maximum fields, and example hints of `0.15` and `0.25`. Setup is optional and does not block weight logging. Nothing is written until Save is tapped.

Accepted input is a finite positive pair satisfying `0 < minimum < maximum`, in kg/week, with up to two decimal places and either decimal separator. There is no product maximum. Trim surrounding whitespace; reject blanks, negative or zero endpoints, equal/reversed ranges, scientific notation, nonnumeric/nonfinite input, and more than two decimals. For example, `0,15` and `0.25` save a summary of `0.15–0.25 kg/week`; `0.00–0.20`, `0.20–0.20`, and `0.30–0.20` are invalid. `5.00–6.00` remains valid: do not accidentally introduce a cap.

The account has one current target. Saving a replacement atomically replaces the pair; there is no effective date or retained history. There is no Clear action. The target is available on another device after Profile opens or the user refreshes. Concurrent writes use the last complete range accepted by the server; the user considered simultaneous use unlikely and delegated this low-priority choice to the simple behavior.

The form offers explicit Save and refresh actions. A failed initial read has a retry state and is never presented as an absent target. A failed refresh keeps the saved summary and any draft visible; refreshing must not overwrite an edited draft. A failed save keeps input available for retry while the form remains open. During a submitted save, fields and duplicate submission are disabled and the UI says “Waiting for server confirmation.” The user can leave Profile while that operation remains pending in the current app session. Only a successful write acknowledgement updates the confirmed summary and produces save success feedback. Unsubmitted changes are discarded without a dialog when leaving Profile; reopening loads the saved value or blank fields.

### Key Discoveries:

- The shell's Profile tab can host this feature without adding a route (`bulk_tempo/lib/features/auth/presentation/views/home_shell_screen.dart:148`). Preserve existing navigation and logout behavior.
- Auth changes are reactive, but an authenticated A-to-B account switch need not remount the shell (`bulk_tempo/lib/app/router/app_router.dart:29`). New target state and controllers must be scoped to the account and protected against stale async completions.
- Existing weight ViewModels write results after awaiting without lifecycle guards (`bulk_tempo/lib/features/weight/presentation/view_models/weight_history_view_model.dart:44`). Reuse their architectural pattern, while adding guards in the new feature.
- Firebase `get()` may return cached data when the server cannot be reached; a write Future completes when committed. Do not label cached reads as newly synchronized or interpret a slow write as cancelled. [Firebase read/write behavior](https://firebase.google.com/docs/database/flutter/read-and-write)

## What We're NOT Doing

- Weekly pace assessment, target comparisons, dashboard calculations, workout import, or weight-history changes (S-05 through S-07 and S-03 remain separate).
- Zero, negative, or equal-endpoint targets; percentage-based targets, pounds, or automatic target recommendations.
- A product upper limit, automatic default, compulsory onboarding, dated target history, or a Clear target action/API.
- Live target subscriptions, conflict dialogs/versioning, background polling, a durable offline draft queue, or a guarantee that pending writes survive process termination.
- An unsaved-change warning or restoration of unsubmitted drafts after leaving Profile.
- A general auth/weight lifecycle refactor, global security-rules redesign, CI work, production deployment, or commits during planning.

## Implementation Approach

Create a self-contained `lib/features/gain_target/{domain,data,presentation}/` feature. Its domain repository exposes a nullable read and a save of the complete range. Absence is a successful null result, not an error; malformed stored data is an error, not absence. Reuse existing `Result` and `AppFailure` types and injected Firebase access.

Store a singleton at `users/$uid/gain_target` containing only numeric `minWeeklyGainKg` and `maxWeeklyGainKg`. Both are finite and satisfy `0 < minWeeklyGainKg < maxWeeklyGainKg`. The two-decimal restriction is user-input syntax; numeric JSON validation enforces type and ordering rather than depending on exact binary floating-point remainder checks. The DTO does not round, default, or silently repair stored endpoints. No timestamp or revision is needed for the agreed replacement policy.

Separate the confirmed saved value, editable input, and submitted pending value in presentation state. Fetch on entering Profile and explicit refresh, except that returning during an existing pending write must retain its pending state rather than treating an SDK-local echo as confirmation. Keep one submitted operation tracked per account while the app session remains active. Use bounded reads and retain pending write ownership across tab disposal; do not add an application write timeout that pretends to cancel an SDK operation.

## Critical Implementation Details

### Timing & lifecycle

A request belongs to its captured UID and state generation. Ignore completions after disposal, account change, or a superseding load, including A-to-B-to-A switches; reset visible values and text controllers when the account changes. An already submitted Firebase write may still finish for its original UID, but must never update another account's UI or be retargeted to its path.

### State sequencing

Leaving Profile discards only unsubmitted edits. Retain the pending write's submitted pair and Future during same-account navigation until success/failure; do not issue a duplicate write or promote cached data to a confirmed save on re-entry. Ordinary refresh updates the saved summary while preserving a dirty draft, and success notifications are emitted once to the relevant mounted view.

## Phase 1: Domain and Validation

### Overview

Define the target's meaning and repository boundary, then verify the accepted input and rejected boundary cases independently of Flutter UI and Firebase.

### Changes Required:

#### 1. Target entity and validation

**File**: `bulk_tempo/lib/features/gain_target/domain/models/gain_target_entity.dart`, `bulk_tempo/lib/features/gain_target/domain/validation/gain_target_validator.dart`

**Intent**: Represent the weekly kg range and provide consistent validation without importing the body-weight bounds or introducing a product cap.

**Contract**: `GainTargetEntity` is an immutable pure-Dart value with `minWeeklyGainKg` and `maxWeeklyGainKg`. `GainTargetValidator` owns trimmed comma/dot decimal input parsing, at most two decimal places, finite numeric checks, and `0 < minimum < maximum`; errors identify the relevant field or invalid ordering. Do not silently round invalid input. Provide a consistent kg/week display representation for presentation, keeping rendering widgets free of validation logic.

#### 2. Repository interface

**File**: `bulk_tempo/lib/features/gain_target/domain/repositories/gain_target_repository.dart`

**Intent**: Make absent, loaded, failed, and successfully saved targets distinguishable without coupling callers to Firebase.

**Contract**: `GainTargetRepository` exposes `getGainTarget({required String userId})` returning `Future<Result<GainTargetEntity?, AppFailure>>` and `saveGainTarget({required String userId, required GainTargetEntity target})` returning `Future<Result<GainTargetEntity, AppFailure>>`. A successful save means server acknowledgement; there is no clear/delete or history method.

#### 3. Domain verification

**File**: `bulk_tempo/test/features/gain_target/domain/models/gain_target_entity_test.dart`, `bulk_tempo/test/features/gain_target/domain/validation/gain_target_validator_test.dart`

**Intent**: Lock the agreed numerical behavior before storage and UI depend on it.

**Contract**: Cover `0.15–0.25`, comma input, whitespace, integers, `0.01–0.02`, `0.29–0.57`, and uncapped `5.00–6.00`; reject zero/negative/equal/reversed endpoints, blanks, malformed text, `0.151`, `NaN`, infinity, and exponent input. Exercise programmatically supplied nonfinite entity values at the numeric-validation boundary as well as text parsing.

### Success Criteria:

#### Automated Verification:

- Domain and input boundary tests pass: `cd bulk_tempo && flutter test test/features/gain_target/domain/`.
- Static analysis passes: `cd bulk_tempo && flutter analyze`.
- Formatting passes: `cd bulk_tempo && dart format --output=none --set-exit-if-changed lib test`.

**Implementation Note**: This phase has no human-only verification gate. Its automated criteria are tracked in the canonical Progress section.

---

## Phase 2: Persistence and Security

### Overview

Persist the complete range in the existing private RTDB account tree and verify schema enforcement and account isolation against the emulator.

### Changes Required:

#### 1. Shared Firebase provider

**File**: `bulk_tempo/lib/core/providers/firebase_database_provider.dart`, `bulk_tempo/lib/features/weight/data/datasources/weight_remote_data_source.dart`

**Intent**: Let both data features use one injectable database dependency without making gain targets depend on the weight implementation.

**Contract**: Move the existing `firebaseDatabaseProvider` declaration into a feature-independent provider file and import it from both data sources. Keep its behavior unchanged; update any imports that reference its former location. No weight persistence behavior changes belong here.

#### 2. DTO, data source, and repository

**File**: `bulk_tempo/lib/features/gain_target/data/models/gain_target_dto.dart`, `bulk_tempo/lib/features/gain_target/data/datasources/gain_target_remote_data_source.dart`, `bulk_tempo/lib/features/gain_target/data/repositories/gain_target_repository_impl.dart`

**Intent**: Read and replace the account's target through the established DTO/data-source/repository boundary, preserving precise failure semantics.

**Contract**: Read only `users/$userId/gain_target`; save both required numeric fields together at that node with one awaited `set`. Never replace `users/$uid` or write endpoints independently. Accept numeric int/double JSON values and reject strings, missing fields, malformed objects, nonfinite values, and invalid order. Only a nonexistent/null snapshot returns successful absence. Validate nonempty UID and target invariants before I/O; map permission, network, database, and malformed-data errors into existing typed failures with usable messages. Bound read waits to 15 seconds, preserving the distinction between a failed read and no target; a late read must not overwrite newer state. Leave write acknowledgement pending without claiming timeout cancellation. Expose target-specific repository/data-source providers.

#### 3. Additive RTDB validation

**File**: `bulk_tempo/database.rules.json`

**Intent**: Protect the new target schema while retaining the existing owner-only access and weight-entry behavior.

**Contract**: Add validation under `users/$uid/gain_target` requiring both numeric endpoints with `0 < minimum < maximum` and disallowing unexpected fields within the target object. Preserve parent UID ownership and weight rules. Numeric input-format limits belong to the app parser; avoid floating-point modulo-based cent checks in RTDB. Existing owner deletion permission is unchanged; omitting a Clear action is a UI/API scope decision, not a claim that a parent-granted write can be revoked by a child rule. [Firebase rule inheritance](https://firebase.google.com/docs/database/security/core-syntax)

#### 4. Data and rules verification

**File**: `bulk_tempo/test/features/gain_target/data/`, `bulk_tempo/test/test_helpers/mocks.dart`, `bulk_tempo/test/test_helpers/fakes/fake_gain_target_repository.dart`, `bulk_tempo/test/test_helpers/fakes/fake_gain_target_repository_test.dart`, `bulk_tempo/database-rules-tests/package.json`, `bulk_tempo/database-rules-tests/package-lock.json`, `bulk_tempo/database-rules-tests/gain_target.rules.test.mjs`, `bulk_tempo/firebase.json`, `bulk_tempo/.gitignore`

**Intent**: Verify actual Firebase rules as well as local mapping, failure, pending-write, and account-scoping contracts.

**Contract**: Mirror the existing Mocktail data tests and per-user fake repository. Use controlled Futures to prove save cannot succeed before acknowledgement and reads time out without manufacturing absence. Add a small Node test-runner harness using `@firebase/rules-unit-testing`, Firebase client libraries, and a locally pinned Firebase CLI, with a lockfile and a `test:emulator` script. It must launch only the database emulator from the app root using `--project demo-bulk-tempo`, load `database.rules.json`, test authenticated and unauthenticated clients, and clean up. Add only necessary emulator configuration and generated-file ignores; preserve Flutter Firebase configuration. Tests must fail when the emulator is unavailable, never fall through to a live project. [Firebase rules testing](https://firebase.google.com/docs/rules/unit-tests)

### Success Criteria:

#### Automated Verification:

- Target data and fake-repository tests pass: `cd bulk_tempo && flutter test test/features/gain_target/data/ test/test_helpers/fakes/fake_gain_target_repository_test.dart`.
- Emulator harness dependencies install reproducibly: `cd bulk_tempo/database-rules-tests && npm ci`.
- Emulator tests prove owner access, foreign/unauthenticated denial, complete valid replacements, invalid/partial payload rejection, and unchanged weight access: `cd bulk_tempo/database-rules-tests && npm run test:emulator`.
- Existing weight data tests pass after the provider move: `cd bulk_tempo && flutter test test/features/weight/data/`.
- Static analysis and formatting pass: `cd bulk_tempo && flutter analyze && dart format --output=none --set-exit-if-changed lib test`.

**Implementation Note**: Emulator execution is automated verification, not a manual inspection substitute. This phase does not deploy production rules.

---

## Phase 3: Profile Integration

### Overview

Deliver the user flow in Profile, including empty/error states, explicit refresh, session-scoped pending saves, discarded unsubmitted drafts, and account isolation throughout asynchronous work.

### Changes Required:

#### 1. Target state and ViewModel

**File**: `bulk_tempo/lib/features/gain_target/presentation/view_models/gain_target_state.dart`, `bulk_tempo/lib/features/gain_target/presentation/view_models/gain_target_view_model.dart`

**Intent**: Coordinate editing and persistence while making the distinction between saved, unsubmitted, and pending values explicit.

**Contract**: Immutable state covers initial load, loaded nullable target, input strings, field errors, dirty state, refresh/read failure, pending submitted target, save failure, and acknowledged success. Expose load/refresh, field-change, save, and transient-message handling actions through a Riverpod ViewModel without `BuildContext` or Material imports. Load on account-scoped Profile entry; capture UID and request generation for every async action. Reject duplicate submits in the ViewModel, not just through disabled buttons. Preserve dirty text during refresh and failed saves; discard unsubmitted edits on leaving Profile. Retain a submitted operation while pending across same-account tab navigation using provider lifecycle support, and release it after completion; account changes reset visible state. Pending re-entry must show the same operation and suppress reads that could mislabel an SDK-local write as confirmed. After completion, later entries fetch normally. Show success once in the relevant mounted view; do not emit a toast into a different tab/account from a stale callback.

#### 2. Profile target section

**File**: `bulk_tempo/lib/features/gain_target/presentation/views/gain_target_view.dart`, `bulk_tempo/lib/features/auth/presentation/views/home_shell_screen.dart`

**Intent**: Expose the saved range and optional editor in the existing Profile space without blocking other features.

**Contract**: Profile becomes scrollable and mounts `GainTargetView` only when selected. Keep account email, `profile_heading`, `profile_logout_button`, all bottom-tab keys, and logout confirmation intact. The target section includes a saved summary or “No target set,” labelled minimum/maximum inputs with kg/week units and example hints, Save, explicit Refresh, initial-load Retry, field errors, and non-destructive refresh/save feedback. Empty fields are hints, not an automatically saved default. Disable editing, refresh, and duplicate Save while pending; navigation/logout remain usable. Controllers follow loaded values when pristine and reset on account changes; bind them so refresh does not erase dirty edits. Discard unsubmitted text when leaving without a confirmation dialog. Use keyboard-safe scrolling and accessible labels; no new route or navigation destination is required.

#### 3. Presentation, integration, and verification documentation

**File**: `bulk_tempo/test/features/gain_target/presentation/view_models/gain_target_view_model_test.dart`, `bulk_tempo/test/features/gain_target/presentation/views/gain_target_view_test.dart`, `bulk_tempo/test/features/auth/presentation/views/home_shell_screen_test.dart`, `context/changes/set-gain-target/verification.md`

**Intent**: Exercise the accepted user behavior and the lifecycle paths most likely to leak stale values or report a false save.

**Contract**: Use the target fake, auth fake, and controlled Completers. Cover first use, saved prefill, replacement, invalid input, repeat Save, load retry, read timeout, dirty refresh, save failure preserving text, discard/re-entry, pending leave/re-entry, and late completion after disposal. Cover A-to-B and A-to-B-to-A during both loads and saves; neither values nor success messages from obsolete requests may appear in the current session. Extend Profile shell tests with target repository overrides; Home/Weights must not initialize the target data source. Test a small viewport with keyboard insets. Record actual emulator/manual results and any deployment prerequisite in the change's verification file; never mark unrun checks as passed.

### Success Criteria:

#### Automated Verification:

- Target ViewModel and widget tests pass, including controlled pending-write and account-switch cases: `cd bulk_tempo && flutter test test/features/gain_target/presentation/`.
- Profile shell and existing router tests pass: `cd bulk_tempo && flutter test test/features/auth/presentation/views/home_shell_screen_test.dart test/app/router/app_router_test.dart`.
- Full regression suite passes: `cd bulk_tempo && flutter test`.
- Static analysis and formatting pass: `cd bulk_tempo && flutter analyze && dart format --output=none --set-exit-if-changed lib test`.

#### Manual Verification:

- On Android, optional first setup and replacement work in Profile with comma/dot input, validation feedback, readable kg/week summary, usable keyboard layout, and unchanged navigation/logout.
- On two devices using one test account, Profile open/refresh reads the confirmed replacement; a different account sees only its own target and weights remain intact.
- Disconnect, submit, leave and reopen Profile, then reconnect: the save stays pending until acknowledgement and completes once; leaving unsubmitted edits instead restores the saved target on re-entry.

**Implementation Note**: After automated verification, request human confirmation of the manual results before marking those criteria complete. Preserve unchecked manual rows when device verification is unavailable.

---

## Testing Strategy

### Unit Tests:

- Use the Phase 1 examples as a common acceptance matrix for parsing and domain validation; direct repository calls must reject invalid numeric invariants before reaching Firebase.
- Verify strict DTO parsing, explicit successful absence, exact UID/node/payload, failure mapping, read timeout, and pending Future behavior. Do not use a fake's account separation as proof of server security.
- Control async completion order in ViewModel tests, including refresh races, disposal, and A-to-B-to-A. Verify pending saves survive same-account navigation without leaking unsent drafts.

### Integration Tests:

- Against the demo RTDB emulator, exercise unauthenticated and second-user reads/writes at the target path and owner-parent replacement paths. Verify valid whole-pair replacement, missing/string/zero/equal/reversed values, unexpected fields, partial child deletions, and parent updates cannot leave a malformed target. Retain owner deletion behavior and cover valid/invalid weight-entry access as regression cases.
- Widget tests exercise the actual form and Profile composition via injected repositories; real SDK connectivity/acknowledgement is verified separately on devices.

### Manual Testing Steps:

1. Apply the reviewed rules to the agreed test environment before device verification. Production rules deployment remains a separate release action. Sign in to an account with no target, open Profile, and confirm blank fields, example hints, and “No target set.” Weight logging must remain usable.
2. Save `0,15` and `0.25`; after server confirmation expect `0.15–0.25 kg/week`. Replace with `0.20` and `0.30`; expect `0.20–0.30 kg/week`. Reopen Profile and confirm prefilled values and no Clear action.
3. Try zero, equal, reversed, malformed, and three-decimal inputs; confirm specific feedback and no write. Verify `5.00–6.00` is accepted by the software, then restore the intended test target.
4. Edit without saving, switch tabs, and return: the saved pair returns. Edit again and explicitly refresh: the draft survives while the saved summary can update. Simulate read/save failures; confirm retry and retained input rather than a false empty state or success.
5. With a target loaded, disconnect the device and tap Save. Confirm pending status, disabled duplicate submission, and usable tab navigation. Return to Profile while still offline; it must remain pending. Reconnect and verify acknowledgement, one confirmed update, and no duplicate operation. Terminating the app is outside the promised pending-operation lifetime.
6. Open Profile on a second device with the same account; refresh after a replacement on the first. Confirm the new pair. Use another account and verify no target or draft is inherited. Exercise logout during a pending operation and verify no stale success appears for the next account.

## Performance Considerations

Each read/write targets one small record; no weight-history scans, polling, or target history queries are needed. Fetch only on Profile entry and explicit refresh, coalesce redundant loads, and suppress reads during pending saves. A 15-second read timeout provides bounded retry feedback; writes retain honest pending status instead of a fabricated success/failure. No new mobile runtime dependency is required.

## Migration Notes

This is an additive RTDB node. Existing accounts begin unset; there is no backfill, automatic example target, or migration of weights. Deploy the additive validation rules through the project's approved release process before releasing the UI, preserving existing owner and weight rules. Older clients ignore the new node. Rolling back the UI does not require deleting saved targets or removing their validation. The historical Firestore deployment draft is superseded for this feature by the roadmap's RTDB decision and current code.

## References

- Requirements: `context/foundation/prd.md:75` (FR-007), `:85` (FR-012); roadmap `context/foundation/roadmap.md:134` (S-04).
- Prior implementation plan: `context/changes/dated-weight-history/plan.md`; current code takes precedence over its pre-implementation descriptions.
- Profile integration: `bulk_tempo/lib/features/auth/presentation/views/home_shell_screen.dart:86`; shell test: `bulk_tempo/test/features/auth/presentation/views/home_shell_screen_test.dart:330`.
- Persistence examples: `bulk_tempo/lib/features/weight/data/datasources/weight_remote_data_source.dart:100`, `bulk_tempo/lib/features/weight/data/repositories/weight_repository_impl.dart:47`.
- Testing seams: `bulk_tempo/test/test_helpers/fakes/fake_weight_repository.dart:6`, `bulk_tempo/test/test_helpers/fakes/fake_auth_repository.dart:102`.
- Architecture and verification: `bulk_tempo/.documentation/01_architecture_overview.md`, `02_project_structure.md`, `03_state_management_mvvm.md`, `04_data_and_domain.md`, `05_navigation.md`, `06_testing_strategy.md`.
- Official Firebase documentation, checked 2026-10-11: [Flutter reads, writes, and acknowledgement](https://firebase.google.com/docs/database/flutter/read-and-write), [rules syntax and inheritance](https://firebase.google.com/docs/database/security/core-syntax), [emulator rules tests](https://firebase.google.com/docs/rules/unit-tests).

## Progress

> Convention: unchecked rows are pending; checked rows are done. Append a commit SHA when a step lands. Do not rename step titles.

### Phase 1: Domain and Validation

#### Automated

- [x] 1.1 Domain and input boundary tests pass: `cd bulk_tempo && flutter test test/features/gain_target/domain/`.
- [x] 1.2 Static analysis passes: `cd bulk_tempo && flutter analyze`.
- [x] 1.3 Formatting passes: `cd bulk_tempo && dart format --output=none --set-exit-if-changed lib test`.

### Phase 2: Persistence and Security

#### Automated

- [ ] 2.1 Target data and fake-repository tests pass: `cd bulk_tempo && flutter test test/features/gain_target/data/ test/test_helpers/fakes/fake_gain_target_repository_test.dart`.
- [ ] 2.2 Emulator harness dependencies install reproducibly: `cd bulk_tempo/database-rules-tests && npm ci`.
- [ ] 2.3 Emulator tests prove owner access, foreign/unauthenticated denial, complete valid replacements, invalid/partial payload rejection, and unchanged weight access: `cd bulk_tempo/database-rules-tests && npm run test:emulator`.
- [ ] 2.4 Existing weight data tests pass after the provider move: `cd bulk_tempo && flutter test test/features/weight/data/`.
- [ ] 2.5 Static analysis and formatting pass: `cd bulk_tempo && flutter analyze && dart format --output=none --set-exit-if-changed lib test`.

### Phase 3: Profile Integration

#### Automated

- [ ] 3.1 Target ViewModel and widget tests pass, including controlled pending-write and account-switch cases: `cd bulk_tempo && flutter test test/features/gain_target/presentation/`.
- [ ] 3.2 Profile shell and existing router tests pass: `cd bulk_tempo && flutter test test/features/auth/presentation/views/home_shell_screen_test.dart test/app/router/app_router_test.dart`.
- [ ] 3.3 Full regression suite passes: `cd bulk_tempo && flutter test`.
- [ ] 3.4 Static analysis and formatting pass: `cd bulk_tempo && flutter analyze && dart format --output=none --set-exit-if-changed lib test`.

#### Manual

- [ ] 3.5 On Android, optional first setup and replacement work in Profile with comma/dot input, validation feedback, readable kg/week summary, usable keyboard layout, and unchanged navigation/logout.
- [ ] 3.6 On two devices using one test account, Profile open/refresh reads the confirmed replacement; a different account sees only its own target and weights remain intact.
- [ ] 3.7 Disconnect, submit, leave and reopen Profile, then reconnect: the save stays pending until acknowledgement and completes once; leaving unsubmitted edits instead restores the saved target on re-entry.
