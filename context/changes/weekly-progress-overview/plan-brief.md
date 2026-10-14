# Weekly Progress Overview — Plan Brief

> Full plan: `context/changes/weekly-progress-overview/plan.md`

## What & Why

Replace the static welcome text, email, and navigation/logout buttons on the Home tab with a weekly progress dashboard built on `fl_chart`. This delivers roadmap slice **S-06** (`weekly-progress-overview`, PRD `FR-008` and `US-01`), combining weekly weight averages, weekly rate of gain, total bulk gain, and weekly workout counts in one view while explicitly flagging incomplete weeks and outdated cached data.

## Starting Point

`HomeShellScreen._buildHomeTab` (`lib/features/auth/presentation/views/home_shell_screen.dart:47-96`) currently shows a placeholder icon, `'Welcome to Bulk Tempo'`, the user's email, and buttons to jump to Weights, Workouts, or Log Out. Weekly domain summaries (`WeeklyWeightSummaryEntity`, `WeeklyWorkoutSummaryEntity`), `GainTargetEntity`, and `fl_chart ^0.70.2` are already implemented in their respective feature slices.

## Desired End State

Opening the Home tab renders `DashboardView` with no welcome text or navigation buttons: a 4-tile KPI header (Current Pace, Latest Average with `'This week · X/7 days logged'` when incomplete, Total Gain, and Workouts This Week) above three synchronized 12-calendar-week `fl_chart` cards (Weekly Weight Trend `LineChart`, Weekly Pace `BarChart` with a shaded target-range band, and Workouts per Week `BarChart`). Each card independently handles loading, error, empty/unconfigured, and `'Outdated · last refresh failed'` states.

## Key Decisions Made

| Decision | Choice | Why (1 sentence) |
| --- | --- | --- |
| Current pace (`bieżące tempo`) | `(latestAvg - prevAvg) / weeksBetween` in `kg/week` (e.g. W1 `80.00`, W4 `80.60` $\rightarrow$ `+0.20 kg/wk`) | Aligns directly with `kg/week` gain targets without inflating pace when intermediate weeks are missed. |
| Latest average week | Newest logged week including the ongoing current ISO week, flagged `'This week · X/7 days logged'` when `< 7` days | Surfaces the freshest data immediately while satisfying the PRD guardrail to explicitly mark incomplete data. |
| Total gain (`łączny przyrost`) | `latestLoggedWeek.averageWeightKg - earliestLoggedWeek.averageWeightKg` across all history (`null` if `< 2` weeks) | Uses noise-smoothed weekly averages across the user's full history without requiring a new bulk-start setting. |
| Charts on Home | 3 `fl_chart` cards: Weight Trend (`LineChart`), Weekly Pace (`BarChart`), and Workouts per Week (`BarChart`) | Covers weight trend, historical pace context, and weekly workout frequency using `fl_chart` exclusively. |
| Target range on Pace chart | Shaded horizontal band (`minWeeklyGainKg`–`maxWeeklyGainKg`) with neutral bar colors and no qualitative verdict | Gives visual target context for `US-01` without preempting blocked slice **S-07**'s four-status classification formula. |
| Shared chart X-axis | Fixed 12 consecutive ISO calendar weeks ending at the current week (`0..11`), with gaps for missing weight weeks and `0` bars for zero-workout weeks | Aligns all three charts week-for-week and makes unlogged weeks visibly obvious rather than hiding gaps. |
| Missing / failing sources | Independent per-card states plus an `'Outdated · last refresh failed'` badge on cached cards when refresh fails | Prevents a disconnected Hevy key or single network error from blanking out the rest of the dashboard. |
| Empty-card UX | Text-only guidance inside empty/unconfigured cards (no navigation buttons on Home; only error states have `'Retry'`) | Matches the requirement to remove buttons from Home while keeping bottom navigation one tap away. |
| Data & refresh architecture | Pure-Dart `WeeklyProgressCalculator` + `DashboardViewModel` composing existing ViewModels; `ensureInitialized()` on open, `refreshAll()` on pull-to-refresh | Preserves a single source of truth across tabs and avoids duplicate Hevy API pagination calls on tab switches. |
| Testing scope | Unit tests for `WeeklyProgressCalculator` plus migrating broken/affected tests in `home_shell_screen_test.dart` and `app_router_test.dart` | Focuses automated verification on the metric math and existing navigation/shell regressions. |

## Scope

**In scope:**
- Pure-Dart `WeeklyProgressOverviewEntity`, `CalendarWeekProgressSlotEntity`, and `WeeklyProgressCalculator` (`lib/features/dashboard/domain/`).
- Session retention (`ref.keepAlive()`) and `ensureInitialized()` on `WeightHistoryViewModel` and `GainTargetViewModel`.
- `DashboardState` and `DashboardViewModel` (`lib/features/dashboard/presentation/view_models/`).
- `DashboardView`, 4 KPI stat tiles, and 3 `fl_chart` cards (`lib/features/dashboard/presentation/`), replacing `HomeShellScreen._buildHomeTab`.
- Calculator unit tests and migration of affected tests in `home_shell_screen_test.dart` and `app_router_test.dart`.

**Out of scope:**
- Pace status verdicts (`"tempo prawidłowe"`, `"za szybkie"`, `"za wolne"`, `"stagnacja"`) and green/amber bar coloring (blocked slice **S-07**).
- Stored "bulk start date" or "starting weight" settings.
- Training volume charts or exercise-level breakdowns on Home (kept on the Workouts tab).
- Standalone widget test suites for individual dashboard cards or golden screenshot tests.

## Architecture / Approach

`DashboardViewModel` (`AutoDisposeNotifier<DashboardState>`) watches `weightHistoryViewModelProvider`, `workoutProgressViewModelProvider`, `gainTargetViewModelProvider`, and `clockProvider`. Whenever any source updates, it invokes `WeeklyProgressCalculator.calculate(...)` to project full weight history and 12-week workout summaries onto the 12 consecutive ISO calendar weeks ending at `now`, producing both the 12 slot models and the 4 headline KPIs.

## Phases at a Glance

| Phase | What it delivers | Key risk |
| --- | --- | --- |
| 1. Domain Weekly Progress Calculator | `clockProvider`, overview entities, `WeeklyProgressCalculator`, and calculator unit tests | Off-by-one week math across missed calendar weeks or history older than 12 weeks |
| 2. Dashboard ViewModel & Per-Card State | `ensureInitialized()` on weight/target ViewModels, `DashboardState`, and `DashboardViewModel` | Keeping `weightHistoryViewModelProvider` cached across tabs without breaking existing ViewModel tests |
| 3. Home Tab `fl_chart` UI, Wiring & Test Migration | `DashboardView`, KPI tiles, 3 `fl_chart` cards, `HomeShellScreen` wiring, and test migration | Existing tests pumping `HomeShellScreen` without all 4 fake repository overrides |

**Prerequisites:** Slices S-02 (`dated-weight-history`), S-04 (`set-gain-target`), and S-05 (`import-workout-progress`) in place in the repository.
**Estimated effort:** ~1–2 sessions across 3 phases.

## Open Risks & Assumptions

- **Historical baseline assumption**: Total gain uses the earliest logged weekly weight average in the account's history; if a user logged pre-bulk weights, those entries anchor total gain unless deleted.
- **Partial current-week volatility**: Because the ongoing week is included in latest average and current pace as soon as 1 weigh-in is logged, early-week pace can fluctuate; the `'This week · X/7 days logged'` label mitigates misinterpretation.

## Success Criteria (Summary)

- Home tab shows the 4 KPI stat tiles and 3 `fl_chart` cards aligned to the last 12 ISO calendar weeks, with all legacy Home buttons and welcome/email text removed.
- Disconnected or failing Hevy data only affects the Workouts card/tile while Weight Trend and Weekly Pace (with the optional target band) still render, and failed background refreshes display `'Outdated · last refresh failed'`.
- `flutter test`, `flutter analyze`, and `dart format --output=none --set-exit-if-changed lib test` pass with zero issues.
