# Set Weekly Gain Target — Plan Brief

> Full plan: [plan.md](plan.md)

## What & Why

Users need to save their own weekly gain range before Bulk Tempo can compare progress against it. This change delivers S-04 / FR-007 and FR-012: a private target that can be set, replaced, and read across devices.

## Starting Point

Authentication, dated weight history, and per-account Firebase Realtime Database access already exist. Profile currently shows account details and logout; no target model, storage, form, or emulator rules-test harness exists.

## Desired End State

Profile shows the saved target and an editable minimum/maximum form in kg/week. New accounts see “No target set,” blank fields, and example hints; setup is optional. Saving `0,15` and `0.25` produces `0.15–0.25 kg/week` after server confirmation, and another device retrieves it on opening or refreshing Profile.

## Key Decisions Made

| Decision | Choice | Why |
| --- | --- | --- |
| Valid range | `0 < minimum < maximum` | A gain range excludes zero, negative, and exact-value targets. |
| Input limits | Up to 2 decimals; comma/dot; finite values; no product cap | Matches existing input conventions without inventing a maximum. |
| Target history | One current range; replacements overwrite it | S-04 needs setting and reading, without dated versions. |
| First use | Blank optional form; examples are hints only | No default is mistaken for a user-selected target. |
| Clearing | Edit only; no Clear action/API | Keeps this slice focused on the accepted scope. |
| Location | Saved summary and form in Profile | Reuses the existing settings space and navigation. |
| Other-device updates | Fetch on Profile entry or explicit refresh | Matches weight history without live subscriptions. |
| Concurrent edits | Last complete server-accepted range wins | User considers simultaneous device use unlikely. |
| Offline save | Pending until acknowledgement; navigation allowed | Avoids claiming a queued write has already saved. |
| Unsubmitted edits | Discard on leaving, without a dialog | Keeps form lifetime simple; submitted pending writes are distinct. |

## Scope

**In scope:** target domain/validation, RTDB DTO and repository, owner/schema rule tests, Profile UI/state, pending-save handling, and account-switch protection.

**Out of scope:** pace evaluation/dashboard work, target history or deletion UI, automatic defaults, mandatory onboarding, live sync, conflict resolution, persistent offline drafts, weight feature refactoring, and production deployment.

## Architecture / Approach

A separate `gain_target` feature follows the existing View → Riverpod ViewModel → domain repository → Firebase data-source pattern. It stores one pair of numeric kg/week endpoints at `users/$uid/gain_target`. Shared Firebase injection moves out of the weight feature. Input syntax enforces two decimal places; storage rules enforce required numeric fields, positive ordering, and account isolation.

The UI keeps confirmed values, editable text, and submitted values distinct. Pending writes survive same-account tab navigation during the app session; stale async completions cannot populate another account. Refresh preserves dirty text, failed saves preserve visible input, and failed reads never become “No target set.”

## Phases at a Glance

| Phase | What it delivers | Key risk |
| --- | --- | --- |
| 1. Domain and Validation | Entity, nullable read/save contracts, input tests | Accidentally accepting zero/equal bounds or introducing a cap |
| 2. Persistence and Security | Singleton storage, shared provider, rules and emulator tests | Confusing absence/errors or testing only fake security |
| 3. Profile Integration | Form, refresh, pending operation tracking, lifecycle and UI tests | Losing pending state or exposing stale account data |

**Prerequisites:** Completed S-01/F-01, the existing Flutter/Firebase setup, and Node plus a Firebase-emulator-compatible Java runtime for rules tests; test accounts/devices for manual verification.
**Estimated effort:** Roughly 3 implementation sessions, one per phase; emulator setup and device verification may need additional time.

## Open Risks & Assumptions

- Unusually large finite inputs remain valid by choice; `5.00–6.00` is a deliberate no-cap regression case, not a recommended target.
- Pending writes can take time and are not cancelled by leaving Profile. Process-termination recovery is outside scope; a new session reads what reached the server.
- A cached read is not proof of a fresh server sync. Rules must reach the approved test/release environment before relying on their validation there.
- Prior targets cannot be recovered after replacement; simultaneous edits may overwrite each other under the accepted simple policy.

## Success Criteria (Summary)

- Optional setup and replacement work in Profile; invalid input is rejected, saved values persist, and other accounts remain isolated.
- Pending, failed, absent, and saved states are distinguishable; leaving drafts and leaving submitted saves follow their different agreed rules.
- Domain/data/UI tests, real emulator rules tests, full regression checks, and the documented Android/cross-device checks pass before implementation is marked complete.

## References

- [Full plan and verification criteria](plan.md); [PRD](../../foundation/prd.md), FR-007/FR-012; [Roadmap](../../foundation/roadmap.md), S-04.
- Existing patterns: `bulk_tempo/lib/features/weight/`, `bulk_tempo/lib/features/auth/presentation/views/home_shell_screen.dart`, and `bulk_tempo/.documentation/`.
