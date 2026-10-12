# Weekly Progress Overview Implementation Plan

## Overview

Replace the placeholder welcome text, email, and quick-action/logout buttons on the Home tab (`lib/features/auth/presentation/views/home_shell_screen.dart:47-96`) with a weekly progress dashboard powered by `fl_chart`. This delivers roadmap slice **S-06** (`weekly-progress-overview`, PRD `FR-008` and `US-01`): the user sees their current weekly weight-change pace (`kg/week`), latest weekly average weight (with an explicit incomplete-week indicator when the ongoing week has fewer than 7 weigh-ins), total weight gain across all logged history, this week's workout count, and three synchronized 12-calendar-week `fl_chart` charts (Weekly Average Weight `LineChart`, Weekly Pace `BarChart` with an optional shaded gain-target band, and Workouts per Week `BarChart`). Each card manages its own loading, error, empty/unconfigured, and outdated-refresh states independently.

## Current State Analysis

- **Home Tab Placeholder**: `HomeShellScreen._buildHomeTab` (`lib/features/auth/presentation/views/home_shell_screen.dart:47-96`) renders a centered `Column` with `Icons.account_circle_outlined`, `'Welcome to Bulk Tempo'`, the user's email, `'Go to Weights'` (`Key('home_go_to_weights_button')`), `'Go to Workouts'` (`Key('home_go_to_workouts_button')`), and `'Log Out'` (`Key('home_logout_button')`).
- **Existing Domain Summaries**:
  - `WeeklyWeightSummaryEntity.groupEntriesByIsoWeek` (`lib/features/weight/domain/models/weekly_weight_summary_entity.dart:46-113`) groups daily `WeightEntryEntity` records by UTC-normalized ISO Monday–Sunday (`WeekDateUtils.startOfIsoWeekUtc`, `endOfIsoWeekUtc`), computes `averageWeightKg` rounded to 2 decimals, excludes empty weeks, and sorts newest week first.
  - `WeeklyWorkoutSummaryEntity.groupWorkoutsByIsoWeek` (`lib/features/workout/domain/models/weekly_workout_summary_entity.dart:56-127`) groups Hevy workouts by ISO Monday of `workout.localDate`, computes `workoutCount`, `totalWorkingSets`, and `totalVolumeKg`, excludes empty weeks, and sorts newest week first.
  - `GainTargetEntity` (`lib/features/gain_target/domain/models/gain_target_entity.dart:2-59`) stores `minWeeklyGainKg` and `maxWeeklyGainKg` in `kg/week`.
- **Source ViewModels & Lifecycles**:
  - `weightHistoryViewModelProvider` (`lib/features/weight/presentation/view_models/weight_history_view_model.dart:8-11`) is an `AutoDisposeNotifierProvider` that starts in `WeightHistoryInitial` and requires an explicit `loadEntries()` call; background refresh failures populate `WeightHistoryLoaded.refreshErrorMessage`.
  - `workoutProgressViewModelProvider` (`lib/features/workout/presentation/view_models/workout_progress_view_model.dart:9-12`) is a session-cached `NotifierProvider` with `ensureInitialized()` (`L41-45`); background refresh failures populate `WorkoutProgressLoaded.refreshErrorMessage`.
  - `gainTargetViewModelProvider` (`lib/features/gain_target/presentation/view_models/gain_target_view_model.dart:8-11`) is a session-cached `NotifierProvider` that starts with `GainTargetState(userId: _userId)` and requires an explicit `loadTarget()` call; refresh failures populate `GainTargetState.refreshErrorMessage`.
- **Existing Tests Coupled to Home Placeholder**:
  - 9 widget tests in `test/features/auth/presentation/views/home_shell_screen_test.dart` (`L112-124`, `L126-143`, `L145-162`, `L164-181`, `L199-216`, `L218-254`, `L257-284`, `L555-580`, `L582-609`) assert `'Welcome to Bulk Tempo'`, `Key('home_logout_button')`, `Key('home_go_to_weights_button')`, or `Key('home_go_to_workouts_button')`.
  - Several tests in `test/features/auth/presentation/views/home_shell_screen_test.dart` (`L112-388`, `L433-523`) and `test/app/router/app_router_test.dart` (`L127-166`, `L169-211`, `L214-246`) pump `HomeShellScreen` without overriding all three data repositories (`weightRepositoryProvider`, `workoutRepositoryProvider`, `gainTargetRepositoryProvider`).

## Desired End State

Opening the app on the Home tab (Tab 0) displays `DashboardView` inside `HomeShellScreen`:
1. **No placeholder text or navigation buttons on Home**: `'Welcome to Bulk Tempo'`, the user's email text, `'Go to Weights'`, `'Go to Workouts'`, and `'Log Out'` inside the Home body are gone. The AppBar `'Log Out'` icon button (`Key('home_app_bar_logout_button')`) and the Profile tab `'Log Out'` button (`Key('profile_logout_button')`) remain intact.
2. **Headline KPI Stat Tiles**: Four compact stat cards/tiles above the charts showing:
   - **Current Pace (`bieżące tempo`)**: `(latestLoggedWeek.averageWeightKg - previousLoggedWeek.averageWeightKg) / weeksBetween` rounded to 2 decimals (e.g. `+0.20 kg/wk` when W1 avg is `80.00 kg`, W2–W3 are unlogged, and W4 avg is `80.60 kg`). Shows `'—'` with subtitle `'Log 2+ weeks'` when fewer than 2 logged weight weeks exist across all history.
   - **Latest Average (`ostatnia średnia`)**: `latestLoggedWeek.averageWeightKg` formatted to 2 decimals (`'80.60 kg'`), using the current ISO week if it has $\ge 1$ entry. When the latest logged week is the ongoing current ISO week and `loggedDaysCount < 7`, displays an incomplete badge/subtitle `'This week · X/7 days logged'`; when `loggedDaysCount == 7` in the current week, displays `'This week · 7/7 days logged'`; when the current week has 0 entries, shows the most recent historical logged week with its date range label.
   - **Total Gain (`łączny przyrost`)**: `latestLoggedWeek.averageWeightKg - earliestLoggedWeek.averageWeightKg` across all recorded weight history (not restricted to the 12-week chart window), rounded to 2 decimals. Shows `'—'` with subtitle `'Log 2+ weeks'` when fewer than 2 logged weight weeks exist.
   - **Workouts This Week**: `workoutCount` for the current ISO week when Hevy is connected and loaded (`0` if no workouts logged this week), or `'—'` with status subtitle (`'Not connected'`, `'Loading...'`, or `'Sync error'`) when unavailable.
3. **Three Synchronized 12-Calendar-Week `fl_chart` Cards**:
   - All three charts share the exact same horizontal axis: the 12 consecutive ISO calendar weeks ending at the current ISO week (`index 0..11`, oldest on the left, current ISO week at index `11`), labeled with `WeekDateUtils.formatShortWeekLabel(slot.weekStartMonday)`.
   - **Weekly Weight Trend Card** (`LineChart`): Plots `averageWeightKg` at each slot index `i` where weight data exists (`FlSpot(i.toDouble(), slot.averageWeightKg!)`). Empty calendar weeks are omitted from spots or separated so missing weeks appear as visible gaps along the 12-week calendar axis.
   - **Weekly Pace Card** (`BarChart`): Plots `paceKgPerWeek` (positive or negative `BarChartRodData` from `0` to `paceKgPerWeek`) at each slot index `i` that has a computed pace, using a neutral theme color (`colorScheme.primary` / `secondary`) with a zero baseline (`FlLine` at `y = 0`). When a saved `GainTargetEntity` is loaded, renders a shaded horizontal target band (`HorizontalRangeAnnotation(y1: target.minWeeklyGainKg, y2: target.maxWeeklyGainKg)`) behind the bars and a subtitle `'Target: X.XX–Y.YY kg/week'`. Does **not** render qualitative status verdicts (`prawidłowe` / `za szybko` / `za wolno` / `stagnacja`) or green/amber evaluation colors (deferred to S-07).
   - **Workouts per Week Card** (`BarChart`): Plots `workoutCount` (`0..N`) for all 12 calendar week slots when Hevy workouts are loaded, so weeks with zero workouts explicitly show a `0`-height slot on the shared 12-week axis.
4. **Independent Per-Card States & Outdated Indicators**:
   - Each card independently renders loading, error (with in-card `'Retry'` button), empty/unconfigured (text-only guidance, no navigation buttons), and loaded states.
   - If a background refresh (`pull-to-refresh`) fails while cached data is present, the affected card(s) remain visible and display an `'Outdated · last refresh failed'` badge (`Key('weight_trend_outdated_badge')`, `Key('weekly_pace_outdated_badge')`, `Key('weekly_workouts_outdated_badge')`).

### Key Discoveries:

- `WeeklyWeightSummaryEntity.groupEntriesByIsoWeek` (`lib/features/weight/domain/models/weekly_weight_summary_entity.dart:46-113`) returns **all** logged weeks in history sorted newest-first, whereas `WeightHistoryLoaded.chartSummaries` (`lib/features/weight/presentation/view_models/weight_history_view_model.dart:55-57`) truncates to 12 logged weeks. Reading `WeightHistoryLoaded.weeklySummaries` directly gives the calculator full history for **Total Gain** and for looking up the prior logged week just before the 12-calendar-week window.
- `weightHistoryViewModelProvider` (`lib/features/weight/presentation/view_models/weight_history_view_model.dart:8-11`) is an `AutoDisposeNotifierProvider` without `ref.keepAlive()`, whereas `workoutProgressViewModelProvider` (`workout_progress_view_model.dart:9-12`) and `gainTargetViewModelProvider` (`gain_target_view_model.dart:8-11`) are non-autoDispose `NotifierProvider`s. Calling `ref.keepAlive()` inside `WeightHistoryViewModel.build()` and adding `ensureInitialized()` to both `WeightHistoryViewModel` and `GainTargetViewModel` preserves the provider type while caching loaded state across tab switches.
- `WorkoutRepositoryImpl.getWorkoutsForLastWeeks` (`lib/features/workout/data/repositories/workout_repository_impl.dart:142`) uses `now` (`DateTime.now()` by default) to compute the 12-week cutoff. Introducing an injectable `clockProvider` (`Provider<DateTime Function()>`) in `lib/core/providers/clock_provider.dart` allows deterministic calendar-week axis generation in unit and widget tests.

## What We're NOT Doing

- **No S-07 pace evaluation verdict**: We are NOT classifying pace into `"tempo prawidłowe"`, `"tempo za szybkie"`, `"tempo za wolne"`, or `"stagnacja"`, and we are NOT coloring pace bars green/amber/red against the target range. That decision engine belongs to blocked slice **S-07** (`contextual-pace-assessment`).
- **No "bulk start date" or "starting weight" setting**: Total gain uses the earliest vs. latest logged weekly average in the user's history. No new database paths, DTOs, or Profile settings are added.
- **No training volume chart or exercise-level charts on Home**: Detailed workout sets, volume, and per-exercise progressions remain on the Workouts tab (`WorkoutProgressView`). Home displays only the 12-week workouts-per-week count `BarChart` and this week's workout count stat tile.
- **No navigation buttons inside empty/unconfigured Home cards**: Empty weight cards and the unconfigured Hevy workout card display text-only guidance (`'No weights logged yet — add one on the Weights tab'`, `'Hevy not connected — connect in Profile'`). Only error states include an in-place `'Retry'` button.
- **No golden (screenshot) tests or standalone per-card widget test suites**: Per the confirmed test scope, automated testing covers exhaustive unit tests for the domain calculator (`weekly_progress_calculator_test.dart`) plus updating/migrating existing tests in `home_shell_screen_test.dart` and `app_router_test.dart`.

## Implementation Approach

We introduce a presentation-and-domain feature slice under `lib/features/dashboard/` (no `data/` layer is needed because all persistence is owned by `weight`, `workout`, and `gain_target`):
1. **Domain Layer (`lib/features/dashboard/domain/`)**: Pure Dart entities (`CalendarWeekProgressSlotEntity`, `WeeklyProgressOverviewEntity`) and a stateless calculator (`WeeklyProgressCalculator.calculate(...)`) that takes:
   - `List<WeeklyWeightSummaryEntity> allWeightWeeks` (sorted newest-first from `WeightHistoryLoaded.weeklySummaries`),
   - `List<WeeklyWorkoutSummaryEntity> workoutWeeks` (from `WorkoutProgressLoaded.weeklySummaries`),
   - `DateTime referenceDate` (normalized to UTC Monday via `WeekDateUtils.startOfIsoWeekUtc`).
   It builds the 12 consecutive ISO calendar weeks `[currentMonday - 11 weeks .. currentMonday]`, maps weight averages and workout counts onto those 12 slots, computes gap-adjusted `paceKgPerWeek` for each logged weight week against its immediately preceding logged week in `allWeightWeeks`, and derives the headline KPI metrics (`currentPaceKgPerWeek`, `latestAverageWeightKg`, `latestWeekStartMonday`, `latestWeekEndSunday`, `latestWeekLoggedDays`, `isLatestWeekCurrentWeek`, `isLatestWeekIncomplete`, `totalGainKg`, `currentWeekWorkoutCount`, `loggedWeightWeeksCount`).
2. **Presentation State & ViewModel (`lib/features/dashboard/presentation/view_models/`)**:
   - Add `ensureInitialized()` and `ref.keepAlive()` to `WeightHistoryViewModel` (`lib/features/weight/presentation/view_models/weight_history_view_model.dart`) and `ensureInitialized()` + `hasLoadedOnce` tracking to `GainTargetViewModel` (`lib/features/gain_target/presentation/view_models/gain_target_view_model.dart` and `gain_target_state.dart`).
   - `DashboardViewModel` (`AutoDisposeNotifier<DashboardState>`) watches `weightHistoryViewModelProvider`, `workoutProgressViewModelProvider`, `gainTargetViewModelProvider`, and `clockProvider`, and derives an immutable `DashboardState` with independent section statuses (`weightStatus`, `workoutStatus`, `gainTargetStatus`), outdated flags (`isWeightOutdated`, `isWorkoutOutdated`, `isGainTargetOutdated`), error messages, `savedTarget`, and the computed `WeeklyProgressOverviewEntity`.
   - `DashboardViewModel` exposes `ensureInitialized()` (calls `ensureInitialized()` on all three source ViewModels), `refreshAll()` (runs `loadEntries(showLoading: false)`, `loadWorkouts(showLoading: false)`, and `loadTarget(showLoading: false, isRefresh: true)` in parallel via `Future.wait`), `retryWeights()`, and `retryWorkouts()`.
3. **Presentation Views & Widgets (`lib/features/dashboard/presentation/`)**:
   - `DashboardView` wraps a `RefreshIndicator` around a `ListView` containing the KPI stat tiles row (`DashboardKpiRow`) and three chart cards (`WeeklyWeightTrendCard`, `WeeklyPaceChartCard`, `WeeklyWorkoutsChartCard`).
   - `HomeShellScreen._buildHomeTab` is replaced with `const DashboardView()`.

## Critical Implementation Details

- **Timing & lifecycle of source ViewModels**: `WeightHistoryViewModel` currently uses `AutoDisposeNotifierProvider` without `ref.keepAlive()`. Without `ref.keepAlive()`, switching from Home (Tab 0) to Workouts (Tab 2) or Profile (Tab 3) would dispose `weightHistoryViewModelProvider` and force a full reload on return. Calling `ref.keepAlive()` in `WeightHistoryViewModel.build()` keeps weight state cached for the session while still resetting automatically when `authViewModelProvider.select((s) => s.user?.id)` or `weightRepositoryProvider` changes, and still disposing cleanly when `ProviderContainer` is disposed in tests.
- **Test repository overrides on `HomeShellScreen` mount**: Because `DashboardView` is the default tab (index `0`) of `HomeShellScreen` and calls `ensureInitialized()` in a post-frame callback on mount, any widget test that pumps `HomeShellScreen` must override `weightRepositoryProvider`, `workoutRepositoryProvider`, and `gainTargetRepositoryProvider` in addition to `authRepositoryProvider`. Otherwise, `FirebaseDatabase.instance` is accessed in tests that previously only rendered the static Home placeholder.

## Phase 1: Domain Weekly Progress Calculator

### Overview

Create the pure-Dart domain models and `WeeklyProgressCalculator` that compute the 12 calendar-week slots and headline metrics (gap-adjusted pace, latest average with incomplete-week detection, total gain across all history, and current-week workout count), along with unit tests covering all formula and boundary cases.

### Changes Required:

#### 1. Injectable Clock Provider

**File**: `lib/core/providers/clock_provider.dart`

**Intent**: Provide an injectable current-time function (`DateTime Function()`) defaulting to `DateTime.now` so the 12-calendar-week window and current-week detection are deterministic in tests.

**Contract**: `final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);`

#### 2. Calendar Week Slot & Overview Entities

**File**: `lib/features/dashboard/domain/models/weekly_progress_overview_entity.dart`

**Intent**: Represent each of the 12 consecutive ISO calendar weeks and the aggregated headline overview metrics in immutable pure-Dart value objects with value equality (`==` and `hashCode`).

**Contract**:
- `CalendarWeekProgressSlotEntity`:
  - `final String weekStartIso` (`YYYY-MM-DD`)
  - `final DateTime weekStartMonday` (UTC midnight)
  - `final DateTime weekEndSunday` (UTC midnight)
  - `final double? averageWeightKg` (`null` if no weight entries in that calendar week)
  - `final int loggedWeightDaysCount` (`0..7`)
  - `final double? paceKgPerWeek` (`null` if `averageWeightKg == null` or no earlier logged weight week exists in history)
  - `final int workoutCount` (`0` if no workouts in that calendar week)
  - `final bool isCurrentWeek` (`true` for slot index `11`)
- `WeeklyProgressOverviewEntity`:
  - `final List<CalendarWeekProgressSlotEntity> calendarWeeks` (always length `12`, chronological oldest at index `0` to current week at index `11`)
  - `final double? currentPaceKgPerWeek` (pace of the newest logged weight week against its immediately preceding logged weight week across all history; `null` if `< 2` logged weight weeks exist)
  - `final double? latestAverageWeightKg` (`averageWeightKg` of the newest logged weight week; `null` if `0` logged weight weeks exist)
  - `final String? latestWeekStartIso`
  - `final DateTime? latestWeekStartMonday`
  - `final DateTime? latestWeekEndSunday`
  - `final int latestWeekLoggedDays` (`0..7`)
  - `final bool isLatestWeekCurrentWeek` (`true` when `latestWeekStartIso == calendarWeeks.last.weekStartIso`)
  - `final bool isLatestWeekIncomplete` (`true` when `isLatestWeekCurrentWeek && latestWeekLoggedDays > 0 && latestWeekLoggedDays < 7`)
  - `final double? totalGainKg` (`latestLoggedWeek.averageWeightKg - earliestLoggedWeek.averageWeightKg` rounded to 2 decimals across all history; `null` if `< 2` logged weight weeks exist)
  - `final int currentWeekWorkoutCount` (`workoutCount` of the current calendar week slot, index `11`)
  - `final int loggedWeightWeeksCount` (total number of logged weight weeks in history)

#### 3. Weekly Progress Calculator

**File**: `lib/features/dashboard/domain/calculators/weekly_progress_calculator.dart`

**Intent**: Implement the pure calculation rules agreed during planning for the 12-calendar-week axis, gap-adjusted weekly pace, latest weekly average (including partial current week), total gain across all history, and weekly workout counts.

**Contract**:
```dart
class WeeklyProgressCalculator {
  static const int windowWeeks = 12;

  static WeeklyProgressOverviewEntity calculate({
    required List<WeeklyWeightSummaryEntity> allWeightSummaries,
    required List<WeeklyWorkoutSummaryEntity> workoutSummaries,
    required DateTime now,
  });
}
```
Calculation invariants:
- Normalize `now` to `currentMonday = WeekDateUtils.startOfIsoWeekUtc(now)`. Generate 12 Mondays: `DateTime.utc(currentMonday.year, currentMonday.month, currentMonday.day - (7 * (11 - i)))` for `i` in `0..11`.
- Sort a copy of `allWeightSummaries` ascending by `weekStartIso` (oldest first).
- For every logged weight week at sorted index `k >= 1`, compute its gap-adjusted pace against sorted index `k - 1`:
  `weeksBetween = sorted[k].weekStartMonday.difference(sorted[k - 1].weekStartMonday).inDays ~/ 7`
  `paceKgPerWeek = WeekDateUtils.roundToTwoDecimals((sorted[k].averageWeightKg - sorted[k - 1].averageWeightKg) / weeksBetween)` (when `weeksBetween >= 1`). For `k == 0`, `paceKgPerWeek = null`.
- Map each of the 12 calendar weeks by `weekStartIso` to its matching `WeeklyWeightSummaryEntity` (if any), precomputed `paceKgPerWeek` (note: a week at the start of the 12-week window still gets a valid `paceKgPerWeek` if an older logged week exists before the 12-week window), and `WeeklyWorkoutSummaryEntity.workoutCount` (defaulting to `0`).
- `latestLoggedWeek` is `sorted.last` (if non-empty); `earliestLoggedWeek` is `sorted.first`.
- If `sorted.length >= 2`, `currentPaceKgPerWeek` is the pace of `sorted.last`, and `totalGainKg = WeekDateUtils.roundToTwoDecimals(sorted.last.averageWeightKg - sorted.first.averageWeightKg)`. Otherwise both are `null`.

#### 4. Calculator Unit Tests

**File**: `test/features/dashboard/domain/calculators/weekly_progress_calculator_test.dart`

**Intent**: Verify all metric definitions, calendar-week alignment, gap-week division, partial current week flags, historical lookback beyond 12 weeks, and `< 2` weeks boundary behavior.

**Contract**: Unit tests covering:
- Empty weights and empty workouts produces 12 calendar slots ending at current ISO week, all `averageWeightKg: null`, `paceKgPerWeek: null`, `workoutCount: 0`, `currentPaceKgPerWeek: null`, `latestAverageWeightKg: null`, `totalGainKg: null`, `isLatestWeekIncomplete: false`.
- Single logged weight week in current week with 2 entries (`2/7 days`) sets `latestAverageWeightKg`, `isLatestWeekCurrentWeek: true`, `isLatestWeekIncomplete: true`, `latestWeekLoggedDays: 2`, and keeps `currentPaceKgPerWeek: null` and `totalGainKg: null`.
- Single logged weight week in current week with 7 entries (`7/7 days`) sets `isLatestWeekCurrentWeek: true` and `isLatestWeekIncomplete: false`.
- Latest logged weight week in a past week (0 entries in current week) sets `isLatestWeekCurrentWeek: false` and `isLatestWeekIncomplete: false`.
- Gap-adjusted pace: W1 (`2026-09-21`) avg `80.00 kg`, W2–W3 unlogged, W4 (`2026-10-12`) avg `80.60 kg` (`weeksBetween = 3`) yields `currentPaceKgPerWeek == 0.20` and slot 11 `paceKgPerWeek == 0.20`, while slots for W2 and W3 have `averageWeightKg: null` and `paceKgPerWeek: null`.
- Negative pace and negative total gain are preserved with sign (e.g. `-0.35`).
- Total gain and first-visible-slot pace use full history older than 12 calendar weeks (e.g. an entry 16 weeks ago at `75.00 kg` and current week at `78.50 kg` yields `totalGainKg == 3.50`, and a slot at index `0` computes pace against a week 13+ weeks ago).
- Workout counts map onto matching calendar weeks and default to `0` on weeks without workouts.

### Success Criteria:

#### Automated Verification:

- Calculator unit tests pass: `flutter test test/features/dashboard/domain/calculators/weekly_progress_calculator_test.dart`
- Static analysis passes with zero issues: `flutter analyze`

#### Manual Verification:

- Confirm `WeeklyProgressCalculator` has zero Flutter widget imports and handles the W1=`80.00` to W4=`80.60` (`+0.20 kg/week`) example identically to the agreed specification.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Phase 2: Dashboard ViewModel & Per-Card State

### Overview

Add `ensureInitialized()` and session-retention support to the weight and gain-target ViewModels, and implement `DashboardState` and `DashboardViewModel` to compose the three feature states into independent per-card statuses, outdated flags, and calculated overview data.

### Changes Required:

#### 1. WeightHistoryViewModel Session Retention & `ensureInitialized()`

**File**: `lib/features/weight/presentation/view_models/weight_history_view_model.dart`

**Intent**: Keep loaded weight history alive across bottom-navigation tab switches within an authenticated session and provide an idempotent `ensureInitialized()` method matching `WorkoutProgressViewModel.ensureInitialized()`.

**Contract**:
- Call `ref.keepAlive()` inside `WeightHistoryViewModel.build()` (`L24-38`).
- Add `Future<void> ensureInitialized() async` that calls `await loadEntries()` only when `state is WeightHistoryInitial`.

#### 2. GainTargetState & GainTargetViewModel `ensureInitialized()`

**File**: `lib/features/gain_target/presentation/view_models/gain_target_state.dart`

**Intent**: Track whether the gain target has completed at least one load attempt in the current session so opening Home does not redundantly re-fetch when the user has no saved target (`savedTarget == null`).

**Contract**:
- Add `final bool hasLoadedOnce;` (default `false`) to `GainTargetState`, include it in `copyWith`, `==`, `hashCode`, and `toString`.

**File**: `lib/features/gain_target/presentation/view_models/gain_target_view_model.dart`

**Intent**: Mark `hasLoadedOnce: true` when `loadTarget()` or `saveTarget()` succeeds, and expose `ensureInitialized()` so Home only triggers a load when the target has not yet been fetched for the current user.

**Contract**:
- In `loadTarget()` success branch (`L90-118`) and `saveTarget()` success branch (`L234-248`), set `hasLoadedOnce: true`.
- Add `Future<void> ensureInitialized() async` that calls `await loadTarget()` only when `!state.hasLoadedOnce && !state.isLoading && !state.isSubmitting`.

#### 3. Dashboard State Model

**File**: `lib/features/dashboard/presentation/view_models/dashboard_state.dart`

**Intent**: Model the independent per-card states, outdated flags, error messages, optional gain target, and calculated `WeeklyProgressOverviewEntity` in an immutable pure-Dart class.

**Contract**:
- `enum DashboardCardStatus { loading, error, unconfigured, empty, loaded }`
- `class DashboardState`:
  - `final DashboardCardStatus weightStatus` (`loading` for `WeightHistoryInitial`/`WeightHistoryLoading`, `error` for `WeightHistoryError`, `empty` for `WeightHistoryLoaded` with `weeklySummaries.isEmpty`, `loaded` for `WeightHistoryLoaded` with `weeklySummaries.isNotEmpty`)
  - `final DashboardCardStatus workoutStatus` (`loading` for `WorkoutProgressInitial`/`WorkoutProgressLoading`, `unconfigured` for `WorkoutProgressUnconfigured`, `error` for `WorkoutProgressError`, ` loaded` for `WorkoutProgressLoaded` — note: when `WorkoutProgressLoaded` has `0` workouts, the workouts chart still renders 12 calendar weeks of `0` bars or an empty-workouts message; see Phase 3)
  - `final bool isWeightOutdated` (`true` when `WeightHistoryLoaded.refreshErrorMessage != null`)
  - `final bool isWorkoutOutdated` (`true` when `WorkoutProgressLoaded.refreshErrorMessage != null`)
  - `final bool isGainTargetOutdated` (`true` when `GainTargetState.refreshErrorMessage != null`)
  - `final String? weightErrorMessage` (from `WeightHistoryError.message` or `WeightHistoryLoaded.refreshErrorMessage`)
  - `final String? workoutErrorMessage` (from `WorkoutProgressError.message` or `WorkoutProgressLoaded.refreshErrorMessage`)
  - `final GainTargetEntity? gainTarget` (from `GainTargetState.savedTarget`)
  - `final WeeklyProgressOverviewEntity overview`
  - `final bool hasAnyWorkoutInWindow` (`true` when `WorkoutProgressLoaded` has `weeklySummaries.isNotEmpty`)

#### 4. Dashboard ViewModel

**File**: `lib/features/dashboard/presentation/view_models/dashboard_view_model.dart`

**Intent**: Reactively compose `weightHistoryViewModelProvider`, `workoutProgressViewModelProvider`, `gainTargetViewModelProvider`, and `clockProvider` into `DashboardState`, and coordinate initial loading, pull-to-refresh across all three sources, and per-card retries.

**Contract**:
- `final dashboardViewModelProvider = AutoDisposeNotifierProvider<DashboardViewModel, DashboardState>(DashboardViewModel.new);`
- `build()` watches `weightHistoryViewModelProvider`, `workoutProgressViewModelProvider`, `gainTargetViewModelProvider`, and `clockProvider`, and synchronously returns the derived `DashboardState` via `WeeklyProgressCalculator.calculate(...)`.
- `Future<void> ensureInitialized()`: invokes `ensureInitialized()` concurrently on `weightHistoryViewModelProvider.notifier`, `workoutProgressViewModelProvider.notifier`, and `gainTargetViewModelProvider.notifier` via `Future.wait`.
- `Future<void> refreshAll()`: invokes `loadEntries(showLoading: false)`, `loadWorkouts(showLoading: false)` (only if workout state is not `WorkoutProgressUnconfigured`; if `WorkoutProgressUnconfigured`, calls `loadWorkouts(showLoading: false)` which re-checks the key cleanly), and `loadTarget(showLoading: false, isRefresh: true)` via `Future.wait`.
- `Future<void> retryWeights()`: calls `ref.read(weightHistoryViewModelProvider.notifier).loadEntries()`.
- `Future<void> retryWorkouts()`: calls `ref.read(workoutProgressViewModelProvider.notifier).loadWorkouts()`.

### Success Criteria:

#### Automated Verification:

- Existing weight and gain-target ViewModel unit tests continue to pass: `flutter test test/features/weight/presentation/view_models/ test/features/gain_target/presentation/view_models/`
- Static analysis passes with zero issues: `flutter analyze`

#### Manual Verification:

- Verify `DashboardViewModel` and `DashboardState` contain zero `package:flutter/material.dart` imports and derive state purely from the watched providers.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Phase 3: Home Tab `fl_chart` UI, Wiring & Test Migration

### Overview

Build `DashboardView` and its KPI row and three `fl_chart` chart cards (`WeeklyWeightTrendCard`, `WeeklyPaceChartCard`, `WeeklyWorkoutsChartCard`), wire `DashboardView` into `HomeShellScreen`, remove all legacy Home buttons and welcome text, and migrate the affected tests in `home_shell_screen_test.dart` and `app_router_test.dart`.

### Changes Required:

#### 1. Shared Outdated Badge & Card Header Helper

**File**: `lib/features/dashboard/presentation/widgets/dashboard_card_shell.dart`

**Intent**: Provide a consistent `Card` layout with title, optional subtitle, optional `'Outdated · last refresh failed'` chip/badge, and body slot for loading, error (with `'Retry'` button), empty/unconfigured text-only guidance, or chart content.

**Contract**:
- Renders an outdated badge with the provided `outdatedBadgeKey` and text `'Outdated · last refresh failed'` whenever `isOutdated == true`.
- Never renders navigation buttons in empty or unconfigured states; only renders a `'Retry'` `FilledButton.tonal` / `TextButton` when `status == DashboardCardStatus.error`.

#### 2. Headline KPI Stat Tiles Row

**File**: `lib/features/dashboard/presentation/widgets/dashboard_kpi_row.dart`

**Intent**: Render the 4 headline metrics above the charts in a responsive 2×2 grid of compact stat tiles: Current Pace, Latest Average (with incomplete-week subtitle), Total Gain, and Workouts This Week.

**Contract**:
- Keys for testability:
  - `Key('dashboard_kpi_pace_tile')`: shows formatted `currentPaceKgPerWeek` (e.g. `'+0.20 kg/wk'` or `'-0.15 kg/wk'`), or `'—'` with `'Log 2+ weeks'` when `null`.
  - `Key('dashboard_kpi_average_tile')`: shows formatted `latestAverageWeightKg` (e.g. `'80.60 kg'`), with subtitle `'This week · X/7 days logged'` when `isLatestWeekCurrentWeek` is true (flagged with `Key('dashboard_incomplete_week_badge')` when `isLatestWeekIncomplete` is true), or the formatted week range when from a prior week, or `'—'` when no weights exist.
  - `Key('dashboard_kpi_total_gain_tile')`: shows formatted `totalGainKg` with sign (e.g. `'+1.40 kg'`), or `'—'` with `'Log 2+ weeks'` when `null`.
  - `Key('dashboard_kpi_workouts_tile')`: shows `'${overview.currentWeekWorkoutCount}'` with subtitle `'This week'` when `workoutStatus == DashboardCardStatus.loaded`, `'—'` with `'Not connected'` when `unconfigured`, `'—'` with `'Sync error'` when `error`, or `'...'` when `loading`.

#### 3. Weekly Weight Trend `LineChart` Card

**File**: `lib/features/dashboard/presentation/widgets/weekly_weight_trend_card.dart`

**Intent**: Display the 12-calendar-week average weight `LineChart` using `fl_chart`, aligned to the shared 12-week axis `0..11`.

**Contract**:
- Card key: `Key('dashboard_weight_trend_card')`; outdated badge key: `Key('weight_trend_outdated_badge')`; retry button key: `Key('dashboard_weight_retry_button')`.
- States:
  - `loading`: centered `CircularProgressIndicator`.
  - `error`: error message + `'Retry'` button calling `onRetry`.
  - `empty`: text-only message `'No weights logged yet — add one on the Weights tab'`.
  - `loaded`: `LineChart` with `minX: 0`, `maxX: 11`, bottom axis labels for slots `0..11` via `WeekDateUtils.formatShortWeekLabel(slot.weekStartMonday)` (with `interval: 2` or `1` to avoid label overlap), left axis in `kg`, and spots at each slot `i` where `slot.averageWeightKg != null`. Consecutive logged weeks are connected; missing calendar weeks break the line segment (or use `FlSpot.nullSpot` between gaps) so missing weeks are visibly represented as gaps.

#### 4. Weekly Pace `BarChart` Card with Target Band

**File**: `lib/features/dashboard/presentation/widgets/weekly_pace_chart_card.dart`

**Intent**: Display the 12-calendar-week `paceKgPerWeek` `BarChart` using `fl_chart`, with a shaded horizontal target band from `GainTargetEntity` (`minWeeklyGainKg` to `maxWeeklyGainKg`) when configured, and neutral bar colors without an S-07 pace verdict.

**Contract**:
- Card key: `Key('dashboard_weekly_pace_card')`; outdated badge key: `Key('weekly_pace_outdated_badge')`.
- States:
  - `loading`: centered `CircularProgressIndicator`.
  - `error`: error message + `'Retry'` button.
  - `empty` (or `loggedWeightWeeksCount < 2` and no slot in the 12-week window has a pace): text-only message (`'No weights logged yet — add one on the Weights tab'` when `0` weeks, or `'Log weights in at least 2 weeks to see weekly pace'` when `< 2` weeks).
  - `loaded` (when at least 1 slot has `paceKgPerWeek != null`): `BarChart` with 12 `BarChartGroupData(x: i, ...)` for `i` in `0..11`. Slots with `paceKgPerWeek != null` render a single `BarChartRodData(fromY: 0, toY: slot.paceKgPerWeek!, color: Theme.of(context).colorScheme.primary, width: 12)`; slots with `null` render an empty rod (`toY: 0`, `width: 0` or `show: false`).
  - When `gainTarget != null`, sets `rangeAnnotations: RangeAnnotations(horizontalRangeAnnotations: [HorizontalRangeAnnotation(y1: gainTarget.minWeeklyGainKg, y2: gainTarget.maxWeeklyGainKg, color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.18))])`, expands `[minY, maxY]` to include `[0, gainTarget.minWeeklyGainKg, gainTarget.maxWeeklyGainKg]` plus bar values with padding, and shows subtitle `'Target: ${gainTarget.formattedTarget}'` (`Key('dashboard_pace_target_subtitle')`).

#### 5. Workouts per Week `BarChart` Card

**File**: `lib/features/dashboard/presentation/widgets/weekly_workouts_chart_card.dart`

**Intent**: Display the 12-calendar-week `workoutCount` `BarChart` using `fl_chart`, with independent unconfigured, loading, error, and outdated states.

**Contract**:
- Card key: `Key('dashboard_weekly_workouts_card')`; outdated badge key: `Key('weekly_workouts_outdated_badge')`; retry button key: `Key('dashboard_workouts_retry_button')`.
- States:
  - `loading`: centered `CircularProgressIndicator`.
  - `unconfigured`: text-only message `'Hevy not connected — connect in Profile'` (`Key('dashboard_workouts_unconfigured_text')`).
  - `error`: error message + `'Retry'` button calling `onRetry`.
  - `loaded`: `BarChart` with 12 `BarChartGroupData(x: i, ...)` for `i` in `0..11`, plotting `slot.workoutCount.toDouble()` (including `0` bars for weeks with zero workouts), integer left-axis interval (`>= 1`), and tooltip showing the week range and `'${slot.workoutCount} workouts'`.

#### 6. DashboardView & HomeShellScreen Wiring

**File**: `lib/features/dashboard/presentation/views/dashboard_view.dart`

**Intent**: Assemble the Home tab view with post-frame `ensureInitialized()`, `RefreshIndicator` calling `refreshAll()`, the KPI row, and the three `fl_chart` cards.

**Contract**:
- `DashboardView` (`ConsumerStatefulWidget`, `Key('dashboard_view')`):
  - In `initState()`, schedules `addPostFrameCallback` calling `ref.read(dashboardViewModelProvider.notifier).ensureInitialized()`.
  - Also listens to `authViewModelProvider.select((s) => s.user?.id)` so user changes re-trigger `ensureInitialized()`.
  - Body is a `RefreshIndicator` (`onRefresh: () => ref.read(dashboardViewModelProvider.notifier).refreshAll()`) wrapping a `ListView` (`Key('dashboard_scroll_view')`, `physics: const AlwaysScrollableScrollPhysics()`) containing `DashboardKpiRow`, `WeeklyWeightTrendCard`, `WeeklyPaceChartCard`, and `WeeklyWorkoutsChartCard`.

**File**: `lib/features/auth/presentation/views/home_shell_screen.dart`

**Intent**: Replace `_buildHomeTab` with `const DashboardView()` and remove the unused placeholder method and keys (`home_go_to_weights_button`, `home_go_to_workouts_button`, `home_logout_button`, `'Welcome to Bulk Tempo'`).

**Contract**:
- Delete `_buildHomeTab(BuildContext context, String? email)` (`L47-96`).
- In `build()` (`L250-260`), cases `0` and `default` assign `body = const DashboardView();`.
- Keep `_showLogoutDialog`, `home_app_bar_logout_button` in the `AppBar`, and `_buildProfileTab` unchanged.

#### 7. Migrate Broken / Affected Widget Tests

**File**: `test/features/auth/presentation/views/home_shell_screen_test.dart`

**Intent**: Update the 9 Home-tab-coupled tests and ensure every `HomeShellScreen` pump in `home_shell_screen_test.dart` overrides all 4 repository providers (`authRepositoryProvider`, `weightRepositoryProvider`, `workoutRepositoryProvider`, `gainTargetRepositoryProvider`).

**Contract**:
- Add all 4 repository overrides (`authRepositoryProvider`, `weightRepositoryProvider`, `workoutRepositoryProvider`, `gainTargetRepositoryProvider`) to every `tester.pumpApp(const HomeShellScreen(), ...)` call in the file (or via a local helper `buildOverrides()`).
- Replace `'renders welcome message and authenticated user email'` (`L112-124`) with `'renders DashboardView with KPI tiles and fl_chart cards on Home tab'`, asserting `find.byType(DashboardView)`, `find.byKey(const Key('dashboard_kpi_pace_tile'))`, `find.byKey(const Key('dashboard_kpi_average_tile'))`, `find.byKey(const Key('dashboard_kpi_total_gain_tile'))`, `find.byKey(const Key('dashboard_kpi_workouts_tile'))`, `find.byKey(const Key('dashboard_weight_trend_card'))`, `find.byKey(const Key('dashboard_weekly_pace_card'))`, `find.byKey(const Key('dashboard_weekly_workouts_card'))`, and `findsNothing` for `'Welcome to Bulk Tempo'`, `Key('home_go_to_weights_button')`, `Key('home_go_to_workouts_button')`, and `Key('home_logout_button')`.
- Update the 5 logout dialog/error tests (`L126-143`, `L145-162`, `L164-181`, `L199-216`, `L218-254`) to trigger logout via `Key('home_app_bar_logout_button')` instead of the removed `Key('home_logout_button')` (removing the duplicate `'tapping app bar logout icon also shows confirmation dialog'` at `L183-197` or repurposing it to verify Home renders seeded `fl_chart` `LineChart` and `BarChart` widgets with a target band and outdated badge on refresh failure).
- Delete `'tapping quick-action button on Home tab switches to Weights tab'` (`L257-284`) and `'tapping quick-action button on Home tab switches to Workouts tab'` (`L582-609`), and remove the `expect(find.byKey(const Key('home_go_to_workouts_button')), findsOneWidget)` assertion from `'renders 4 navigation destinations...'` (`L555-580`).

**File**: `test/app/router/app_router_test.dart`

**Intent**: Supply fake `weightRepositoryProvider`, `workoutRepositoryProvider`, and `gainTargetRepositoryProvider` overrides in the 3 tests (`L127-166`, `L169-211`, `L214-246`) that navigate to `/home` and mount `HomeShellScreen`.

**Contract**:
- Instantiate `FakeWeightRepository`, `FakeWorkoutRepository`, and `FakeGainTargetRepository` in `setUp` (and reset in `tearDown`) of `app_router_test.dart`, and include their provider overrides in the `ProviderScope` of tests that render `/home`.

### Success Criteria:

#### Automated Verification:

- Full test suite passes: `flutter test`
- Static analysis passes with zero issues: `flutter analyze`
- Code formatting passes cleanly: `dart format --output=none --set-exit-if-changed lib test`

#### Manual Verification:

- Launch the app (`flutter run -d chrome` or mobile target), sign in, and confirm the Home tab has no welcome text, email, or navigation/logout buttons, and renders the 4 KPI stat tiles plus the Weight Trend, Weekly Pace, and Workouts per Week cards.
- With weights logged across $\ge 2$ weeks and a saved weekly gain target on Profile, verify the Weekly Weight Trend `LineChart` and Weekly Pace `BarChart` (with shaded target band) render on Home, and that logging a weight in the current partial week shows `'This week · X/7 days logged'`.
- Verify that when Hevy is disconnected, the Weight Trend and Weekly Pace charts still render normally while the Workouts per Week card displays `'Hevy not connected — connect in Profile'`, and pulling down on Home refreshes all cards.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Testing Strategy

### Unit Tests:

- `test/features/dashboard/domain/calculators/weekly_progress_calculator_test.dart`:
  - Empty history (0 weight weeks, 0 workout weeks) -> 12 calendar slots, all nullable metrics `null`, `currentWeekWorkoutCount == 0`.
  - 1 logged weight week (ongoing partial week with 2/7 days vs complete 7/7 days vs past week) -> `latestAverageWeightKg` populated, `isLatestWeekIncomplete` flag accuracy, `currentPaceKgPerWeek == null`, `totalGainKg == null`.
  - Multi-week history with missed calendar weeks (e.g. W1 = `80.00 kg`, W2–W3 missing, W4 = `80.60 kg`) -> gap-adjusted pace `+0.20 kg/week` (`0.60 / 3`), `null` weight and pace in empty slots W2–W3.
  - History spanning $> 12$ weeks -> `totalGainKg` uses earliest week in full history (not slot 0 of the 12-week window), and slot 0 computes its pace against the immediately preceding logged week before the 12-week window.
  - Negative pace and negative total gain rounding to 2 decimal places.
  - Workout counts mapped across the 12 calendar slots with `0` for weeks without workouts.

### Integration / Widget Tests:

- `test/features/auth/presentation/views/home_shell_screen_test.dart`:
  - Home tab renders `DashboardView`, the 4 KPI tiles, and the 3 chart cards, and no longer renders `'Welcome to Bulk Tempo'`, `home_go_to_weights_button`, `home_go_to_workouts_button`, or `home_logout_button`.
  - Seeded multi-week weights, workouts, and gain target render `LineChart` and `BarChart` widgets on Home.
  - Logout confirmation and error SnackBar flows work via `home_app_bar_logout_button`.
- `test/app/router/app_router_test.dart`:
  - Authenticated `/home` redirection and sign-out redirection pass with `DashboardView` mounted inside `HomeShellScreen`.

### Manual Testing Steps:

1. Sign in with an account that has no weights and no Hevy key: verify text-only empty states on all three cards and `'—'` on KPI tiles, with no buttons on Home.
2. Add weights in two different weeks on the Weights tab and switch to Home: verify KPI tiles show Current Pace, Latest Average (`'This week · X/7 days logged'` if in the current partial week), and Total Gain, and both the Weight Trend `LineChart` and Weekly Pace `BarChart` render immediately without needing a manual refresh.
3. Set a weekly gain target (e.g. `0.15–0.25 kg/week`) on Profile and switch to Home: verify the shaded horizontal band and `'Target: 0.15–0.25 kg/week'` subtitle appear on the Weekly Pace chart.
4. Connect a Hevy API key on Profile or Workouts and switch to Home: verify the Workouts per Week `BarChart` renders 12 calendar weeks (with `0` bars on empty weeks) and the Workouts This Week KPI tile shows the current week's count.
5. Simulate a network failure during pull-to-refresh on Home while data is loaded: verify the `'Outdated · last refresh failed'` badge appears on the affected cards while preserving the cached charts.

## Performance Considerations

- **Zero redundant Hevy API calls on tab switches**: By adding `ref.keepAlive()` to `WeightHistoryViewModel` and `ensureInitialized()` to `WeightHistoryViewModel` and `GainTargetViewModel` (matching `WorkoutProgressViewModel.ensureInitialized()`), switching between Home, Weights, Workouts, and Profile reuses in-memory state and never triggers Hevy's multi-page fetch (`up to 15 pages`) unless the user explicitly pulls to refresh on Home or Workouts.
- **O(N log N) pure-Dart calculation**: `WeeklyProgressCalculator.calculate` operates on pre-grouped weekly summaries (`WeeklyWeightSummaryEntity` and `WeeklyWorkoutSummaryEntity`), taking microseconds per rebuild.

## Migration Notes

- No database schema, Firebase security rules, or local storage changes are required.
- Existing widget tests that mount `HomeShellScreen` without overriding `weightRepositoryProvider`, `workoutRepositoryProvider`, and `gainTargetRepositoryProvider` are updated in Phase 3 so they do not hit `FirebaseDatabase.instance` when `DashboardView` initializes on Tab 0.

## References

- Roadmap slice **S-06** (`weekly-progress-overview`): `context/foundation/roadmap.md:51, 159-169`
- PRD requirements `FR-008`, `FR-009`, `US-01`, `§Business Logic`: `context/foundation/prd.md:48-60, 77-80, 93-100`
- Existing `fl_chart` usage: `lib/features/weight/presentation/widgets/weekly_weight_chart.dart:1-203`
- Weekly summary entities: `lib/features/weight/domain/models/weekly_weight_summary_entity.dart:1-150`, `lib/features/workout/domain/models/weekly_workout_summary_entity.dart:1-168`
- Home shell screen: `lib/features/auth/presentation/views/home_shell_screen.dart:1-317`
- Architecture & MVVM rules: `context/documentation/01_architecture_overview.md`, `context/documentation/02_project_structure.md`, `context/documentation/03_state_management_mvvm.md`

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands. Do not rename step titles. See `references/progress-format.md`.

### Phase 1: Domain Weekly Progress Calculator

#### Automated

- [x] 1.1 Calculator unit tests pass: `flutter test test/features/dashboard/domain/calculators/weekly_progress_calculator_test.dart` — e16bcb7
- [x] 1.2 Static analysis passes with zero issues: `flutter analyze` — e16bcb7

#### Manual

- [x] 1.3 Confirm `WeeklyProgressCalculator` has zero Flutter widget imports and handles the W1=`80.00` to W4=`80.60` (`+0.20 kg/week`) example identically to the agreed specification. — e16bcb7

### Phase 2: Dashboard ViewModel & Per-Card State

#### Automated

- [x] 2.1 Existing weight and gain-target ViewModel unit tests continue to pass: `flutter test test/features/weight/presentation/view_models/ test/features/gain_target/presentation/view_models/` — 6ab9d92
- [x] 2.2 Static analysis passes with zero issues: `flutter analyze` — 6ab9d92

#### Manual

- [x] 2.3 Verify `DashboardViewModel` and `DashboardState` contain zero `package:flutter/material.dart` imports and derive state purely from the watched providers. — 6ab9d92

### Phase 3: Home Tab `fl_chart` UI, Wiring & Test Migration

#### Automated

- [x] 3.1 Full test suite passes: `flutter test` — f016ba6
- [x] 3.2 Static analysis passes with zero issues: `flutter analyze` — f016ba6
- [x] 3.3 Code formatting passes cleanly: `dart format --output=none --set-exit-if-changed lib test` — f016ba6

#### Manual

- [x] 3.4 Launch the app (`flutter run -d chrome` or mobile target), sign in, and confirm the Home tab has no welcome text, email, or navigation/logout buttons, and renders the 4 KPI stat tiles plus the Weight Trend and Workouts per Week cards. — f016ba6
- [x] 3.5 With weights logged across $\ge 2$ weeks, verify the Weekly Weight Trend `LineChart` renders on Home and Current Pace tile shows the computed pace, and that logging a weight in the current partial week shows `'This week · X/7 days logged'`. — f016ba6
- [x] 3.6 Verify that when Hevy is disconnected, the Weight Trend chart still renders normally while the Workouts per Week card displays `'Hevy not connected — connect in Profile'`, and pulling down on Home refreshes all cards. — f016ba6
