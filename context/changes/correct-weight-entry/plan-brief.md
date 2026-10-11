# Correct Weight Entry — Plan Brief

> Full plan: [plan.md](plan.md)

## What & Why

Implement S-03 so users can correct a saved weight or delete a mistaken measurement. Corrections must update daily history and weekly trends reliably, including when the subsequent history refresh fails.

## Starting Point

S-02 already provides a weight/date form, private Firebase storage, same-day overwrite confirmation, an expandable weekly list, and a chart. Daily rows have no correction actions; saving can overwrite an existing date, but deletion and protected edit sessions are missing.

## Desired End State

Open a daily entry to see its saved weight and read-only date, then save a corrected weight or confirm deletion. Entries remain correctable at any age; unsaved edits are protected on dismissal, and an acknowledged correction immediately updates the history, averages, and chart.

## Key Decisions Made

| Decision | Choice | Why |
| --- | --- | --- |
| Editable fields | Weight only; original date stays fixed | Keeps correction within the existing date-based identity; wrong dates require delete and Add. |
| Older entries | Edit/delete any retained entry, including beyond 365 days | Existing history never becomes locked; Add retains its 365-day date limit. |
| Cross-device changes | Last accepted save/delete wins | Preserves simple writes; a stale save may recreate a deleted entry or overwrite a newer value. |
| Access | Tap the daily row/edit affordance to open the prefilled sheet | Reuses the existing form and groups correction actions together. |
| Deletion | Confirm original date and saved weight; no Undo | Makes permanent removal explicit, even when the form contains an unsaved draft. |
| Unsaved edits | Confirm Discard/Keep Editing on close, Back, outside tap, or swipe-down | Protects changed edits; unchanged edits close directly. |
| Pending requests | Keep the sheet open and block actions/dismissal until success or failure | Prevents duplicate actions and ambiguous completion; connection loss may extend the wait. |
| Refresh failure after success | Keep the confirmed correction visible; show warning with Retry | A failed read must not undo the visible result of a successful mutation. |

## Scope

**In scope:**
- Single-entry deletion through the repository, Firebase data source, and test fake.
- Fresh add/edit form sessions, fixed-date correction, delete/discard dialogs, and pending states.
- Acknowledged local history updates, recalculated weekly/chart data, and async/session guards.
- Data, ViewModel, widget, and manual cross-device/access-control verification.

**Out of scope:**
- Date moves, Undo/trash/audit history, conflict/version checks, and bulk changes.
- A new offline outbox, cancellable submitted writes, or dismissing a pending mutation.
- Realtime history subscriptions, schema migration, new runtime dependencies, and other roadmap slices.

## Architecture / Approach

Keep the existing View → Riverpod ViewModel → domain repository → Firebase data source flow. Reuse save for fixed-date edits and add idempotent delete. Apply acknowledged changes locally before a separate guarded refresh; reuse existing weekly aggregation and the 12-logged-week chart window.

## Phases at a Glance

| Phase | What it delivers | Key risk |
| --- | --- | --- |
| 1. Storage Deletion Support | Exact user/date deletion, failure mapping, fake and data tests | Removing the wrong scope or treating mock isolation as proof of server authorization |
| 2. Correction State and History Consistency | Edit/delete state, old-entry support, acknowledged history updates | Obsolete reads or account changes applying stale results |
| 3. Correction UI and End-to-End Verification | Row actions, dialogs, all dismissal guards, complete flow | Swipe/barrier dismissal bypassing dirty or pending protection |

**Prerequisites:** Completed S-02; working Flutter/Firebase setup; disposable test data and access to verify the configured database rules.
**Estimated effort:** Approximately 3–4 focused implementation sessions across 3 phases; this is a planning estimate, with dismissal/lifecycle tests the largest uncertainty.

## Open Risks & Assumptions

- Last-action-wins permits overwriting a newer correction, recreating a remotely deleted entry, or deleting a newer value. This is accepted behavior.
- A pending operation can keep the sheet open during an outage; an application timeout does not cancel the Firebase write.
- Deletion is permanent. Manual recreation uses Add's 365-day limit, so an older deleted measurement cannot be recreated through that form.
- The deployed Firebase rules must be verified during acceptance; repository mocks do not establish server-side protection.

## Success Criteria (Summary)

- Correct or confirm deletion of any retained entry, with its original date fixed and existing weight validation preserved.
- Weekly averages, counts, chart windows, and empty states reflect confirmed changes even when refresh fails; Retry recovers.
- Automated checks pass, all dismissal routes obey the selected policy, and manual second-session/access checks are recorded.

## References

- `context/foundation/prd.md` (FR-003/FR-004); `context/foundation/roadmap.md` (S-03).
- `context/changes/dated-weight-history/plan-brief.md`; [full plan references and verification](plan.md#references).
