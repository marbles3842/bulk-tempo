# Dated Weight History — Plan Brief

> Full plan: `context/changes/dated-weight-history/plan.md`

## What & Why

Lifters tracking a lean bulk need to record daily morning body weights (including historical backfills), see weekly averages rather than noisy daily fluctuations, and access their history across devices. This change implements slice `S-02` (`dated-weight-history`) and resolves `F-01` (`private-data-verification`), adding private cloud weight storage, an `fl_chart` weekly-average trend chart, and a week-grouped expandable history list.

## Starting Point

The Flutter app has completed `S-01` (`private-account-access`) with email/password authentication and routes authenticated users to a placeholder `HomeShellScreen` (`/home`). `pubspec.yaml` and `firebase_options.dart` already configure Firebase Realtime Database (`europe-west1`), but `database.rules.json`, `fl_chart`, and the `weight` feature module do not exist yet.

## Desired End State

Authenticated users can navigate to the `Weights` tab in `/home`, log today's or historical weights (`20.0–300.0 kg`, up to 365 days back) with same-day overwrite confirmation, and view an `fl_chart` line chart of their weekly averages (up to 12 most recent logged weeks, oldest-to-newest) directly above an expandable list of ISO Monday–Sunday weeks showing each week's average and inputted daily measurements, with actionable Empty States and resilient Error States across both the tab and entry sheet.

## Key Decisions Made

| Decision | Choice | Why (1 sentence) |
| --- | --- | --- |
| Database service (`F-01`) | Firebase Realtime Database (`firebase_database`) | Matches existing `pubspec.yaml`, `firebase_options.dart` (`europe-west1`), and `firebase.json` with `database.rules.json`. |
| Week boundaries & gaps | ISO Mon–Sun, logged weeks only | Aligns with Sunday end-of-week reviews in the PRD and avoids cluttering the chart/list with empty skipped weeks. |
| Same-day entries | 1 entry per `YYYY-MM-DD` with overwrite confirm | Matches the daily morning weigh-in rule and prevents accidental overwrites when picking historical dates. |
| Chart data & range | Last 12 logged weeks, oldest-to-newest | Plots only weekly averages across a 3-month trend window while keeping mobile X-axis labels legible (plus a 1-week hint state). |
| Chart library | `fl_chart` (`LineChart`) | Provides built-in line rendering, axis titles, and touch tooltips for weekly averages. |
| Weekly list layout | Expandable cards, logged days only | Displays weekly average and `N/7 days` badge on each card (newest week expanded by default) and reveals inputted daily weights. |
| App shell placement | 3-tab bottom `NavigationBar` (`Home`, `Weights`, `Profile`) | Hosts `Home`, `Weights` (with `add_weight_fab`), and `Profile` while preserving all existing `S-01` logout keys and widget tests. |
| Empty & error states | Actionable empty view, full/transient errors & inline banner | Guides first-time users, provides retry on initial load failure, keeps loaded data visible on refresh failure, and preserves form input on save error. |
| Validation & precision | `20.0–300.0 kg`, 2 decimals, `365d` lookback | Prevents chart-distorting typos and preserves 2-decimal precision needed for `0.15–0.25 kg` weekly gain targets (`FR-007`). |
| Sync model | Fetch on load + refresh on save & pull-to-refresh | Follows `context/documentation/03_state_management_mvvm.md` and `04_data_and_domain.md` (`Future<Result<T, AppFailure>>`) for deterministic states and unit/widget testing. |

## Scope

**In scope:**
- `fl_chart` dependency, `bulk_tempo/database.rules.json` (`users/$uid/weight_entries/$date`), and core validators / ISO week utilities (`WeightValidators`, `WeekDateUtils`).
- Weight domain (`WeightEntryEntity`, `WeeklyWeightSummaryEntity`, `WeightRepository`) and data layer (`WeightEntryDto`, `WeightRemoteDataSource`, `WeightRepositoryImpl`, `FakeWeightRepository`).
- Presentation layer (`WeightHistoryViewModel`, `WeightEntryViewModel`, `WeeklyWeightChart`, `WeeklyWeightCard`, `WeightHistoryView` with Empty/Error/Refresh-Error states, `WeightEntryBottomSheet` with validation/save error banner).
- 3-tab `HomeShellScreen` integration (`Home`, `Weights`, `Profile`) and unit/widget tests across all layers.

**Out of scope:**
- Standalone edit/delete actions on existing list entries (`S-03: correct-weight-entry`).
- Multiple intraday measurements per calendar day or empty placeholder rows for unlogged weeks/days.
- Target gain range (`S-04`), Hevy workout import (`S-05`), and weekly pace dashboard (`S-06`/`S-07`).

## Architecture / Approach

Follows Feature-First MVVM + Clean Architecture:
```text
HomeShellScreen (Weights Tab) -> WeightHistoryView & WeightEntryBottomSheet
  └── WeightHistoryViewModel / WeightEntryViewModel (Pure Dart Riverpod Notifiers)
        └── WeeklyWeightSummaryEntity.groupEntriesByIsoWeek (ISO Mon–Sun + 2-decimal avg)
        └── WeightRepository (Domain Contract)
              └── WeightRepositoryImpl (Maps AppException -> Result<T, AppFailure>)
                    └── WeightRemoteDataSource (FirebaseDatabase: users/$uid/weight_entries/$date)
```

## Phases at a Glance

| Phase | What it delivers | Key risk |
| --- | --- | --- |
| 1. Core & Security Rules | `fl_chart`, `database.rules.json`, `WeightValidators`, `WeekDateUtils` | Timezone/DST edge cases in ISO week math |
| 2. Domain & Data Layer | Entities, ISO week grouping, RTDB data source, repository & fake | RTDB numeric type casting (`int` vs `double`) |
| 3. Presentation (MVVM & UI) | ViewModels, `fl_chart` weekly chart, expandable week cards, empty/error states | `fl_chart` single-week edge case & non-destructive refresh errors |
| 4. Home Shell & E2E Tests | 3-tab `HomeShellScreen` (`Home`, `Weights`, `Profile`), `add_weight_fab`, tests | Preserving `S-01` test compatibility on tab 0 |

**Prerequisites:** Completed `S-01` (`private-account-access`) and active Firebase Realtime Database (`europe-west1`).
**Estimated effort:** ~4 implementation cycles across 4 phases.

## Open Risks & Assumptions

- **Firebase RTDB rules deployment:** Assumes `bulk_tempo/database.rules.json` is deployed (`firebase deploy --only database`) so authenticated users can read/write `users/$uid/weight_entries`.
- **Device clock accuracy:** Historical date validation (`[today - 365 days, today]`) relies on the client's local calendar date for `today`.

## Success Criteria (Summary)

- Authenticated users can log today's or historical weights (`20.0–300.0 kg`, up to 365 days back) with same-day overwrite confirmation and read them across devices.
- The `Weights` tab displays an `fl_chart` weekly-average trend chart (up to 12 weeks, oldest-to-newest) above expandable ISO Mon–Sun week cards showing each week's 2-decimal average and inputted daily measurements, with complete Empty and Error state handling.
- All unit and widget tests pass with zero `flutter analyze` warnings.
