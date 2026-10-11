# Correct Weight Entry Implementation Plan

## Overview

Implement roadmap slice S-03 (`correct-weight-entry`), satisfying FR-003 and FR-004: an authenticated user can open an existing daily measurement, correct its weight while retaining its date, or explicitly confirm its deletion. Every confirmed change updates the visible daily history, weekly averages, counts, and chart, including when a subsequent refresh fails.

Planning completed on 2026-10-11 against `bulk_tempo` revision `547b470`. The user answered eight substantive questions and approved the three phases below. Paths are relative to the workspace root (`/Users/dimi/Desktop/10xdevs`); Flutter commands run inside `bulk_tempo`. The workspace root contains the context artifacts; the Git checkout is `bulk_tempo/`.

## Current State Analysis

- S-02 already supplies Add Weight, one entry per calendar date, explicit same-day overwrite confirmation, owner-scoped Firebase Realtime Database storage, ISO weekly aggregation, and a chart of the 12 most recent logged weeks. Its accepted behavior is documented in `context/changes/dated-weight-history/plan-brief.md:19`.
- Daily rows have no correction action (`bulk_tempo/lib/features/weight/presentation/widgets/weekly_weight_card.dart:70`). `WeightEntryBottomSheet` currently takes no entry argument and initializes one auto-disposed form provider (`bulk_tempo/lib/features/weight/presentation/widgets/weight_entry_bottom_sheet.dart:11`).
- `WeightRepository` has fetch and save operations only (`bulk_tempo/lib/features/weight/domain/repositories/weight_repository.dart:6`). Saving performs an unconditional set at `users/$userId/weight_entries/$date` (`bulk_tempo/lib/features/weight/data/datasources/weight_remote_data_source.dart:101`).
- The Add form validates dates against a 365-day window and treats an existing date as an overwrite conflict (`bulk_tempo/lib/features/weight/presentation/view_models/weight_entry_view_model.dart:56`). Reads retain older entries; correcting an existing entry must not reuse this Add-only age restriction or prompt to overwrite itself.
- After saving, the form currently waits for a reload. A failed reload preserves the previous history, which could leave a deleted entry or outdated weight visible (`bulk_tempo/lib/features/weight/presentation/view_models/weight_history_view_model.dart:30`).
- Weight tests use repository fakes and mocked Firebase references. No executable Firebase rules test suite was found. Local rules and deployed rules must be distinguished during final manual verification.

## Desired End State

1. Tapping a daily row or its accessible edit affordance opens a fresh prefilled correction sheet. The saved date is visible and read-only; weight accepts the existing 20.00–300.00 kg range, at most two decimal places, and dot or comma input.
2. Any retained entry can be corrected or deleted, including entries older than 365 days. Add Weight keeps its current date window and overwrite-confirmation behavior.
3. Save applies the weight to the original date without an overwrite-self prompt. Delete asks for confirmation showing the original date and original saved weight, even if the user has typed another weight. Cancel preserves the draft; confirmed deletion discards it. There is no Undo.
4. Closing a changed edit through the close control, Back, outside tap, or swipe-down asks whether to discard or continue editing. Unchanged edits close directly. This new dirty-edit confirmation applies to correction mode; the Add flow retains its existing unsaved-input policy.
5. During an actual save/delete request, the sheet displays the relevant pending state, disables editing and further mutations, and blocks every voluntary dismissal route until the operation succeeds or reports a failure. A connection interruption can extend this wait. Failures retain the draft and allow retry.
6. Server acknowledgement completes the mutation. The confirmed result immediately updates local history and derived weekly/chart data; a separate refresh can then reconcile other-device changes. A refresh failure shows a warning with Retry and retains the corrected history.
7. Last accepted action wins across devices. A stale save may replace a newer value or recreate an entry deleted elsewhere; a stale delete may remove a newer value. Deleting an already absent entry succeeds. These are accepted semantics, not missing conflict detection.
8. Account changes or disposal cannot apply a previous account's pending result to the current UI or cause a new request using another account's ID. Already submitted requests remain associated with their captured original account.

### Key Discoveries:

- `dateIso` is the storage identity; there is no independent entry ID (`bulk_tempo/lib/features/weight/domain/models/weight_entry_entity.dart:3`). Fixing the date during edit lets this slice reuse the existing save schema and operation.
- Weekly averages and counts can be rebuilt using `WeeklyWeightSummaryEntity.groupEntriesByIsoWeek` (`bulk_tempo/lib/features/weight/domain/models/weekly_weight_summary_entity.dart:38`). Stored history is not capped at 365 entries; 365 days restricts new date selection only.
- Owner permissions exist at `users/$uid` (`bulk_tempo/database.rules.json:7`). Firebase skips validation rules for deleted data, so deletion does not require weakening the existing validation rules. See [Firebase rule conditions](https://firebase.google.com/docs/database/security/rules-conditions).
- MVVM boundaries and `Result<T, AppFailure>` remain the architecture contract (`bulk_tempo/.documentation/01_architecture_overview.md`, `03_state_management_mvvm.md`, and `04_data_and_domain.md`).

## What We're NOT Doing

- Editing or moving dates, swapping dates, or introducing entry IDs. Wrong-date corrections use delete and Add, subject to Add's existing 365-day window; that workflow cannot recreate a measurement outside that window.
- Undo, soft deletion, a trash view, audit history, bulk actions, or version/transaction-based conflict protection.
- A new offline outbox, durable pending-operation recovery, cancellation of submitted Firebase writes, or closing the sheet while a user-initiated mutation is pending.
- Realtime history subscriptions, pagination, dashboard/pace assessment, workout import, targets, authentication redesign, or broad unrelated cleanup.
- Changing weight bounds, precision, week definitions, chart ordering, the 12-logged-week limit, or Add date validation.
- Database migration, new runtime dependencies, production deployment, or commits as part of planning.

## Implementation Approach

Extend the existing weight feature through its current layers. Add one deletion contract and reuse the save contract for fixed-date edits. Extend the shared form with an immutable original entry and opening account, an explicit mutation outcome, and edit-specific validation and dirty state. Rebuild loaded history from acknowledged mutations before a guarded background refresh.

Keep input and confirmation rendering in the View; mutation decisions and state belong in ViewModels; Firebase calls remain in the data source. Preserve existing Add entry points and tests. Choose an explicit form-session reset/initialization contract so rapidly reopening one entry, another entry, then Add never leaks inputs or success state.

## Critical Implementation Details

### State sequencing

A confirmed write/delete must update local entries and invalidate older in-flight history reads before initiating its reconciliation refresh. End the form's pending state at mutation acknowledgement, rather than waiting for that refresh; a later refresh failure must neither revert the confirmed change nor report the mutation as failed.

### Timing and lifecycle

Capture account identity and operation generation before awaits, and ignore completions after disposal or account/session invalidation. An SDK write that is pending during connection loss is not cancelled by an application timeout; do not report a definite failure or permit duplicate retry merely because time elapsed. Firebase documents queued writes in [offline capabilities](https://firebase.google.com/docs/database/flutter/offline-capabilities) and completion handling in [read/write guidance](https://firebase.google.com/docs/database/flutter/read-and-write).

### Dismissal paths

The inspected Flutter SDK routes the modal sheet's drag close through `Navigator.pop` (`/Users/dimi/flutter/packages/flutter/lib/src/material/bottom_sheet.dart:769`). A disabled close button or a Back-only guard is insufficient: route close, Back, outside taps, and downward dismissal gestures through the same dirty/pending policy. Replace the built-in drag/barrier dismissal paths where needed so a dirty swipe requests confirmation and a pending swipe cannot dismiss; do not silently drop the approved swipe behavior. See [modal sheet API](https://api.flutter.dev/flutter/material/showModalBottomSheet.html) and [PopScope](https://api.flutter.dev/flutter/widgets/PopScope-class.html).

## Phase 1: Storage Deletion Support

### Overview

Add idempotent deletion of a single user/date entry through the domain and data layers, with meaningful contract tests and matching fake behavior.

### Changes Required:

#### 1. Domain repository contract

**File**: `bulk_tempo/lib/features/weight/domain/repositories/weight_repository.dart`

**Intent**: Let presentation request deletion without knowing Firebase paths or implementation details.

**Contract**: Add `Future<Result<void, AppFailure>> deleteWeightEntry({required String userId, required String dateIso})`. An absent entry is a successful no-op. Preserve existing fetch and unconditional save contracts.

#### 2. Firebase deletion and repository mapping

**File**: `bulk_tempo/lib/features/weight/data/datasources/weight_remote_data_source.dart`; `bulk_tempo/lib/features/weight/data/repositories/weight_repository_impl.dart`

**Intent**: Delete exactly the requested date under the specified user's weight collection and surface failures using established domain types.

**Contract**: The remote data source exposes `Future<void> deleteWeightEntry({required String userId, required String dateIso})` and awaits removal at `users/$userId/weight_entries/$dateIso`. The repository rejects an empty user ID or a noncanonical/invalid ISO date before data access, imposes no age limit, and maps permission, network, server, and unexpected errors consistently with save. Never delete the collection or user node.

#### 3. Fake implementation and data tests

**File**: `bulk_tempo/test/test_helpers/fakes/fake_weight_repository.dart`; `bulk_tempo/test/test_helpers/fakes/fake_weight_repository_test.dart`; `bulk_tempo/test/features/weight/data/datasources/weight_remote_data_source_test.dart`; `bulk_tempo/test/features/weight/data/repositories/weight_repository_impl_test.dart`

**Intent**: Make deletion testable with both exact Firebase-path assertions and behaviorally accurate in-memory storage.

**Contract**: Extend the fake with deletion, deterministic delete failure injection, and reset support. Verify exact single-entry removal, same-date entries in another account remaining untouched, older dates, absent-entry success, invalid date/user rejection before access, failure preserving entries, and established exception mappings. Reuse existing Mocktail declarations unless a new mock is necessary.

### Success Criteria:

#### Automated Verification:

- Data and fake repository tests pass, including deletion contracts: `cd bulk_tempo && flutter test test/features/weight/data/ test/test_helpers/fakes/fake_weight_repository_test.dart`
- Static analysis passes: `cd bulk_tempo && flutter analyze`
- Formatting passes: `cd bulk_tempo && dart format --output=none --set-exit-if-changed lib test`

---

## Phase 2: Correction State and History Consistency

### Overview

Model correction sessions and acknowledged mutations independently of UI, with reliable derived history and protection from obsolete asynchronous results.

### Changes Required:

#### 1. Add/edit form state and session initialization

**File**: `bulk_tempo/lib/features/weight/presentation/view_models/weight_entry_form_state.dart`; `bulk_tempo/lib/features/weight/presentation/view_models/weight_entry_view_model.dart`

**Intent**: Give each sheet opening a clean add or edit session and retain the original identity for all correction actions.

**Contract**: Provide explicit initialization for Add and for an existing `WeightEntryEntity`, capturing the opening user ID. Edit state retains the immutable original entry, exposes its fixed date, prefills a two-decimal weight, and distinguishes saving from deleting and their outcomes. Dirty state compares parsed valid weight to the original value, treating equivalent input such as `80`, `80.00`, and `80,00` as unchanged; a changed invalid or empty draft is dirty. Reset all errors, confirmation flags, and terminal state between openings.

#### 2. Edit and delete commands

**File**: `bulk_tempo/lib/features/weight/presentation/view_models/weight_entry_view_model.dart`

**Intent**: Submit the chosen correction without duplicating writes, applying Add-only restrictions, or misidentifying the target.

**Contract**: Keep `submit({bool confirmOverwrite = false})` compatible with Add. In edit mode it validates the weight, ignores attempts to change the original date, bypasses Add's 365-day validation and overwrite-self prompt, updates `updatedAt`, and saves at the original date. Add a delete command callable only for an initialized edit after the View confirms. It ignores unsaved weight validity and deletes the original date. Both commands capture account/target before awaiting, reject reentrant calls, preserve inputs on failure, and implement the accepted last-action-wins semantics without a stale-version preflight. Read date-only state from the immutable original rather than a mutable field.

#### 3. Acknowledged mutations and refresh ordering

**File**: `bulk_tempo/lib/features/weight/presentation/view_models/weight_history_view_model.dart`; `bulk_tempo/lib/features/weight/presentation/view_models/weight_history_state.dart`

**Intent**: Show a confirmed save/delete immediately and ensure older requests cannot restore stale rows or another account's data.

**Contract**: Expose account-scoped application of a saved entity or a deleted date. Update an immutable entry list, maintain descending dates, and derive weekly summaries and the chronological 12-week chart through one shared path. Applying a mutation invalidates reads started before it. Refreshed data is accepted only for the current account/session and latest eligible request; disposal makes completions inert. Preserve loaded corrected entries on refresh failure and retain the existing transient error notification mechanism. Deleting the last entry in a week removes that week; deleting the last account entry yields loaded-empty state.

#### 4. Mutation completion and reconciliation

**File**: `bulk_tempo/lib/features/weight/presentation/view_models/weight_entry_view_model.dart`; `bulk_tempo/lib/features/weight/presentation/view_models/weight_history_view_model.dart`

**Intent**: Separate successful persistence from the optional failure of a subsequent history read.

**Contract**: On acknowledgement, apply the returned saved entity or deleted date to the current matching history session, then emit the appropriate form success outcome and start a nonblocking guarded refresh. Reuse this completion path for Add saves to keep the shared history consistent. Refresh ownership must survive the form closing while the history is mounted, without retaining a disposed form or accessing its `ref` later. A session change suppresses form/history side effects for that obsolete operation; it does not claim to cancel an already submitted write.

#### 5. ViewModel and regression tests

**File**: `bulk_tempo/test/features/weight/presentation/view_models/weight_entry_view_model_test.dart`; `bulk_tempo/test/features/weight/presentation/view_models/weight_history_view_model_test.dart`; `bulk_tempo/test/test_helpers/fakes/fake_weight_repository.dart`

**Intent**: Verify visible-data invariants and asynchronous ordering with controlled completions rather than timing-dependent sleeps.

**Contract**: Cover prefill/reset, fixed dates, old-entry edits, dirty equivalence, original-target deletion despite invalid draft, repeat-tap suppression, failure/retry, stale saves recreating deleted entries, stale deletes removing changed entries, and absent deletes. Use controlled futures for mutation acknowledgement, failed refresh, pre-mutation reads completing late, latest-read ordering, account switch, and disposal. Verify Add's existing validation, loaded-history gate, and overwrite confirmation remain intact.

### Success Criteria:

#### Automated Verification:

- Correction and history ViewModel tests pass, including controlled asynchronous races: `cd bulk_tempo && flutter test test/features/weight/presentation/view_models/`
- Existing grouping and validation contracts remain green: `cd bulk_tempo && flutter test test/features/weight/domain/ test/core/utils/`
- Static analysis passes: `cd bulk_tempo && flutter analyze`
- Formatting passes: `cd bulk_tempo && dart format --output=none --set-exit-if-changed lib test`

---

## Phase 3: Correction UI and End-to-End Verification

### Overview

Make correction discoverable in daily history and connect all confirmation, dismissal, pending, error, and success states to the approved behavior.

### Changes Required:

#### 1. Daily entry action and stable list identity

**File**: `bulk_tempo/lib/features/weight/presentation/widgets/weekly_weight_card.dart`; `bulk_tempo/lib/features/weight/presentation/views/weight_history_view.dart`

**Intent**: Open the selected measurement for correction without changing the weekly navigation or Add entry points.

**Contract**: Pass an entry callback into the weekly card; a daily row and visible accessible edit affordance invoke it with the selected entity. Preserve `daily_entry_<dateIso>` and existing week/chart keys; use stable outer week identity so removing a week cannot transfer expansion state to a different week. The history view opens the sheet in edit mode and exposes Retry on refresh warnings.

#### 2. Prefilled edit mode and confirmation dialogs

**File**: `bulk_tempo/lib/features/weight/presentation/widgets/weight_entry_bottom_sheet.dart`

**Intent**: Reuse the existing form while making correction, permanent deletion, and draft abandonment explicit.

**Contract**: Extend the sheet constructor and `show` helper with an optional existing entry and initialize exactly once per opening. Add mode remains the default. Edit mode shows a distinct title, prefilled weight, read-only original date, Save and Delete controls, and appropriate saved/deleted success feedback. Delete confirmation names the original date and saved two-decimal weight; cancellation preserves the draft, and confirmation submits only the original target. There is no Undo or overwrite-self dialog. Dirty dismissal uses a single Discard/Keep Editing dialog, including outside taps and swipe-down.

#### 3. Pending, failure, and lifecycle interaction

**File**: `bulk_tempo/lib/features/weight/presentation/widgets/weight_entry_bottom_sheet.dart`; `bulk_tempo/lib/features/weight/presentation/views/weight_history_view.dart`

**Intent**: Prevent accidental loss or duplicate submission while keeping mutation success distinct from a refresh problem.

**Contract**: While submitting, disable inputs, Save, Delete, close, Back, outside-tap and swipe dismissal, and show saving/deleting progress. Report actual mutation failures inline with the input retained and retries enabled. Close only after acknowledgement, without a discard prompt, and display the matching success feedback. A refresh warning keeps the confirmed history visible and provides a Retry action invoking the existing refresh path. An authentication transition dismisses obsolete account UI without asking to preserve its draft; late completions cannot show feedback or pop another route.

#### 4. Widget and whole-app regression coverage

**File**: `bulk_tempo/test/features/weight/presentation/views/weight_history_view_test.dart`; `bulk_tempo/test/features/auth/presentation/views/home_shell_screen_test.dart`; `bulk_tempo/test/app/router/app_router_test.dart`

**Intent**: Verify the complete interaction and its integration with the existing shell and authentication boundary.

**Contract**: Test row/edit affordance targeting, prefill/read-only date, old-entry correction, save without overwrite-self confirmation, delete cancel/confirm with original details, invalid draft deletion, Add-after-edit reset, and correct feedback. Exercise all dismissal routes for unchanged, dirty, and pending edits; Keep Editing retains the draft, Discard leaves storage unchanged. Verify mutation failure/retry, confirmed change plus refresh failure and Retry, last-entry empty state, week removal, and preserved Add/overwrite/logout flows. Extend shell/router tests only for the affected correction/session behavior.

### Success Criteria:

#### Automated Verification:

- Correction UI and integration tests pass: `cd bulk_tempo && flutter test test/features/weight/presentation/views/weight_history_view_test.dart test/features/auth/presentation/views/home_shell_screen_test.dart test/app/router/app_router_test.dart`
- Full Flutter suite passes: `cd bulk_tempo && flutter test`
- Static analysis passes: `cd bulk_tempo && flutter analyze`
- Formatting passes: `cd bulk_tempo && dart format --output=none --set-exit-if-changed lib test`

#### Manual Verification:

- On a supported mobile target, complete edit, delete cancel/confirm, old-entry correction, dirty-dismissal, pending-dismissal blocking, and last-entry empty-state scenarios.
- Verify confirmed corrections remain visible through a failed refresh, Retry recovers, and the same account sees the result after loading or refreshing on a second session.
- Verify owner edit/delete access, foreign-account and unauthenticated denial, and invalid-update rejection using the actual configured Firebase rules and disposable test data.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before marking the change implemented. Phase blocks use plain bullets; the canonical execution checkboxes live only in the Progress section.

---

## Testing Strategy

### Unit Tests:

- Repository/data source: exact user/date path, no broad delete, canonical date validation, empty-user rejection, old dates, idempotency, and error mapping. A fake's per-user separation does not prove Firebase authorization.
- Form: old entries bypass Add age limits while retaining weight validation; original date is immutable; duplicate commands are suppressed; initialization never leaks previous drafts or terminal status.
- History: for 2026-10-05 = 80.00 kg and 2026-10-06 = 82.00 kg, the weekly average is 81.00 kg. Correcting Tuesday to 84.00 yields 82.00; deleting Tuesday leaves 80.00 and 1/7 days; deleting Monday produces the actionable empty state.
- Window boundaries: delete the sole entry in the newest of 13 logged weeks and verify the previously excluded oldest week enters the 12-week chart. Cover 2 weeks to 1 week and 1 week to empty.
- Controlled async ordering: pending, real failure, acknowledgement before refresh, failed reconciliation, obsolete read completion, account/session invalidation, and disposal. Accepted stale-write behavior must have named tests, not accidental coverage.
- Use deterministic dates/clock seams where needed; do not add wall-clock sleeps or rework unrelated test infrastructure.

### Integration Tests:

- Widget tests exercise real presentation ViewModels with controlled repository fakes, preserving existing stable keys and Add flows.
- Test native Back and actual sheet gesture/barrier interactions; invoking only a close callback does not verify dismissal protection.
- Firebase access checks are a separate manual acceptance check against actual rules. No new emulator/CI platform is required for this slice, and mock-based tests must not be reported as deployed-rule verification.

### Manual Testing Steps:

1. Use a disposable account with two measurements in one ISO week and a third in a different week. Open a daily row, inspect the fixed date and prefill, correct the weight, and verify the row, average, count, and chart after save.
2. Change the weight and attempt close, Back, outside tap, and downward sheet dismissal. Choose Keep Editing and then Discard; verify draft preservation or loss as chosen and no database write. Repeat with unchanged input; it closes directly.
3. Type a different or invalid weight, press Delete, and confirm the dialog still names the original saved measurement. Cancel to retain the draft; repeat and confirm to delete. Verify there is no Undo and deleting all entries reaches the Add First Weight state.
4. Seed a disposable valid record older than 365 days through trusted test setup, then verify weight editing and deletion remain available. Confirm Add still rejects dates beyond its 365-day window.
5. Interrupt connectivity during a save/delete. Verify pending feedback and blocked voluntary dismissal without duplicate submission. Restore connectivity, observe acknowledgement and success, and test an actual permission/network failure for retained input and retry.
6. Exercise a confirmed mutation followed by a failed read using controlled test failure injection. Verify the corrected row/averages or removed row remain visible, the warning offers Retry, and retry refreshes normally.
7. Load the same account on a second session and confirm results after refresh. Verify the accepted policy: open an entry on A, modify it on B, then save/delete on A; A's accepted action wins. A stale save after B deletes may recreate the entry. Sign out during a controlled pending completion and check that no old-account content or feedback appears in the new session.
8. Inspect the rules deployed for the configured database and compare them with `bulk_tempo/database.rules.json`. With the Firebase Rules Playground and disposable data, check owner update/delete success, foreign/unauthenticated update/delete denial, and rejection of an invalid weight/date-key update. Record the environment and evidence; do not mark this check complete from mocks or JSON syntax validation alone.

## Performance Considerations

A mutation writes only one date node, followed by the existing account history fetch. Reuse the current grouping/sorting algorithm and cap the chart at 12 logged weeks. History may accumulate beyond a year; make no unmeasured latency claim or assumption that retained entries are capped at 365. No pagination or new performance infrastructure is introduced.

## Migration Notes

The `date`, `weightKg`, and `updatedAt` schema and owner-scoped paths remain unchanged. Existing Firebase rules already authorize owner deletion; no rule relaxation or migration is planned. Verify the deployed rules during acceptance rather than assuming the local file is deployed.

Rolling back the UI/code preserves compatible records but cannot recover permanently deleted measurements; no restoration feature is included. The selected pending behavior can keep a sheet open through a connection outage, and submitted writes are not represented as cancellable. Cross-device last-action-wins behavior is an explicitly accepted risk.

## References

- Product requirements: `context/foundation/prd.md:67` (FR-003/FR-004) and its Access Control section.
- Slice and dependencies: `context/foundation/roadmap.md:122` (S-03; S-02 completed).
- Upstream decisions: `context/changes/dated-weight-history/plan.md` and `plan-brief.md`.
- Architecture: `bulk_tempo/.documentation/01_architecture_overview.md`, `03_state_management_mvvm.md`, `04_data_and_domain.md`, `06_testing_strategy.md`.
- Reusable source contracts and file/line anchors appear in Current State Analysis and Key Discoveries.
- [Firebase read/write operations and completion](https://firebase.google.com/docs/database/flutter/read-and-write); [Firebase offline behavior](https://firebase.google.com/docs/database/flutter/offline-capabilities); [Firebase validation and deletion rules](https://firebase.google.com/docs/database/security/rules-conditions).
- [Flutter modal bottom sheets](https://api.flutter.dev/flutter/material/showModalBottomSheet.html); [Flutter PopScope](https://api.flutter.dev/flutter/widgets/PopScope-class.html).
- Planning decisions: eight answers in this conversation; three-phase structure explicitly approved on 2026-10-11.

## Progress

> Convention: unchecked rows are pending; checked rows are done. Append a commit SHA when a step lands. Do not rename step titles.

### Phase 1: Storage Deletion Support

#### Automated

- [x] 1.1 Data and fake repository tests pass, including deletion contracts: `cd bulk_tempo && flutter test test/features/weight/data/ test/test_helpers/fakes/fake_weight_repository_test.dart` — 34096c0
- [x] 1.2 Static analysis passes: `cd bulk_tempo && flutter analyze` — 34096c0
- [x] 1.3 Formatting passes: `cd bulk_tempo && dart format --output=none --set-exit-if-changed lib test` — 34096c0

### Phase 2: Correction State and History Consistency

#### Automated

- [x] 2.1 Correction and history ViewModel tests pass, including controlled asynchronous races: `cd bulk_tempo && flutter test test/features/weight/presentation/view_models/` — 51ee5e2
- [x] 2.2 Existing grouping and validation contracts remain green: `cd bulk_tempo && flutter test test/features/weight/domain/ test/core/utils/` — 51ee5e2
- [x] 2.3 Static analysis passes: `cd bulk_tempo && flutter analyze` — 51ee5e2
- [x] 2.4 Formatting passes: `cd bulk_tempo && dart format --output=none --set-exit-if-changed lib test` — 51ee5e2

### Phase 3: Correction UI and End-to-End Verification

#### Automated

- [x] 3.1 Correction UI and integration tests pass: `cd bulk_tempo && flutter test test/features/weight/presentation/views/weight_history_view_test.dart test/features/auth/presentation/views/home_shell_screen_test.dart test/app/router/app_router_test.dart` — 6c1ab24
- [x] 3.2 Full Flutter suite passes: `cd bulk_tempo && flutter test` — 6c1ab24
- [x] 3.3 Static analysis passes: `cd bulk_tempo && flutter analyze` — 6c1ab24
- [x] 3.4 Formatting passes: `cd bulk_tempo && dart format --output=none --set-exit-if-changed lib test` — 6c1ab24

#### Manual

- [x] 3.5 On a supported mobile target, complete edit, delete cancel/confirm, old-entry correction, dirty-dismissal, pending-dismissal blocking, and last-entry empty-state scenarios. — 6c1ab24
- [x] 3.6 Verify confirmed corrections remain visible through a failed refresh, Retry recovers, and the same account sees the result after loading or refreshing on a second session. — 6c1ab24
- [x] 3.7 Verify owner edit/delete access, foreign-account and unauthenticated denial, and invalid-update rejection using the actual configured Firebase rules and disposable test data. — 6c1ab24
