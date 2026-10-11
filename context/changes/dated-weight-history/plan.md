# Dated Weight History Implementation Plan

## Overview

Implement slice `S-02` (`dated-weight-history`) and resolve foundation item `F-01` (`private-data-verification`) so authenticated users can log today's or historical daily body weight measurements (`FR-002`, `FR-005`), persist and read them across devices from their private Firebase Realtime Database node (`FR-012`), view their measurements grouped by ISO Monday–Sunday weeks with each week's 2-decimal average and expandable daily entries, and inspect a weekly-average trend line chart (`fl_chart`) above the weekly list on the same screen.

## Current State Analysis

- **Authentication & Routing (`S-01`)**: `bulk_tempo` implements email/password registration, login, session persistence, and logout (`bulk_tempo/lib/features/auth/`), routing authenticated users to `/home` (`HomeShellScreen` in `bulk_tempo/lib/features/auth/presentation/views/home_shell_screen.dart:6-100`).
- **Database Configuration (`F-01`)**: `bulk_tempo/pubspec.yaml:14` declares `firebase_database: ^11.3.1`, `bulk_tempo/lib/firebase_options.dart:55-77` configures the `europe-west1` Realtime Database URL (`https://bulk-tempo-default-rtdb.europe-west1.firebasedatabase.app`), and `bulk_tempo/firebase.json:2-4` points to `database.rules.json` (which does not yet exist on disk).
- **Missing Capabilities**: No weight domain models, data sources, repositories, view models, screens, or charting packages (`fl_chart`) exist in `bulk_tempo/lib/` or `bulk_tempo/test/`.

## Desired End State

An authenticated user can switch to the `Weights` tab in `HomeShellScreen` (`/home`), add a weight measurement for today or any past date within the last 365 days (`20.0–300.0 kg`, up to 2 decimal places), confirm before overwriting an existing measurement on the same calendar date (`YYYY-MM-DD`), and immediately see:
1. A **weekly-average trend chart** (`fl_chart` `LineChart`) at the top of the screen plotting up to the 12 most recent logged ISO weeks chronologically left-to-right (oldest to newest) using only each week's 2-decimal average weight (with a single-point + helper hint state when only 1 week is logged).
2. A **weekly history list** below the chart ordered newest week first, where each week card shows the Monday–Sunday date range, the week's 2-decimal average weight (`XX.XX kg`), and an entry count badge (`N/7 days`), and expands (newest week expanded by default) to list the individual daily measurements inputted in that week.
3. Explicit **Empty States** (an actionable empty view with an `'Add First Weight'` CTA and pull-to-refresh when no entries exist, plus a single-week chart hint when only 1 week is logged) and **Error States** (full-screen error view with `'Retry'` on initial load failure, non-destructive `SnackBar` error notification if a background/pull refresh fails while data is already on screen, and an inline error banner inside the entry bottom sheet if saving fails).
4. Full cross-device persistence under `users/$uid/weight_entries/$date` protected by owner-scoped Firebase Realtime Database rules (`database.rules.json`).

### Key Discoveries:

- `bulk_tempo/pubspec.yaml:14` and `bulk_tempo/lib/firebase_options.dart:55-77` already configure Firebase Realtime Database (`europe-west1`), resolving `roadmap.md:60,205` (`F-01`) in favor of Realtime Database over Firestore.
- `context/documentation/01_architecture_overview.md:49-57` and `03_state_management_mvvm.md:85-92` enforce strict layer boundaries: `Domain` imports only pure Dart + `core/{result,errors}`, and `ViewModel` classes never import `package:flutter/material.dart` or accept a `BuildContext`.
- `bulk_tempo/test/features/auth/presentation/views/home_shell_screen_test.dart:33-175` asserts `Welcome to Bulk Tempo`, `user.email`, `Key('home_logout_button')`, `Key('home_app_bar_logout_button')`, and `Key('confirm_logout_button')` on the initial `/home` view, so keeping tab index 0 as the `Home` overview preserves 100% of `S-01` tests.

## What We're NOT Doing

- **Editing or deleting arbitrary historical entries from the list (`S-03` / `FR-003` / `FR-004`)**: Standalone edit and delete actions on existing list rows belong to slice `S-03` (`correct-weight-entry`). In `S-02`, same-day updates happen only when submitting a weight for an already-logged date via the overwrite confirmation dialog.
- **Multiple intraday measurements per calendar day**: Each calendar date (`YYYY-MM-DD`) stores at most one morning fasted weight measurement.
- **Empty placeholder weeks for unlogged weeks**: Weeks with zero logged measurements are omitted from the weekly list and weekly-average chart rather than interpolated or rendered as empty rows.
- **Unlogged placeholder days inside a week**: Expanding a week card displays only the days in that week for which the user inputted a measurement.
- **Target gain range (`S-04`), Hevy workout import (`S-05`), weekly dashboard (`S-06`), and pace status evaluation (`S-07`)**: Handled in subsequent roadmap slices.
- **Realtime `onValue` stream subscriptions**: Weight history uses explicit fetch-on-load, refresh-on-save, and pull-to-refresh (`Future<Result<List<WeightEntryEntity>, AppFailure>>`).

## Implementation Approach

We follow the repository's Feature-First Clean Architecture + MVVM pattern (`context/documentation/02_project_structure.md`):
1. **Core utilities & security rules**: Add `fl_chart` to `pubspec.yaml`, define `bulk_tempo/database.rules.json` for `users/$uid/weight_entries/$date`, and create pure-Dart validators (`WeightValidators`) and ISO Monday–Sunday week/date helpers (`WeekDateUtils`) in `lib/core/utils/`.
2. **Domain & Data layers (`lib/features/weight/{domain,data}/`)**: Model daily entries (`WeightEntryEntity`) and ISO weekly aggregates (`WeeklyWeightSummaryEntity` with static grouping/averaging over `List<WeightEntryEntity>`), implement `WeightEntryDto`, `WeightRemoteDataSource` (wrapping `FirebaseDatabase`), `WeightRepositoryImpl` (mapping exceptions to `Result<T, AppFailure>`), and `FakeWeightRepository`.
3. **Presentation layer (`lib/features/weight/presentation/`)**: Implement pure-Dart `WeightHistoryViewModel` (loads entries, derives descending `List<WeeklyWeightSummaryEntity>` for the list and chronological last-12-weeks slice for the chart, and handles both initial load errors and non-destructive refresh errors) and `WeightEntryViewModel` (validates inputs, checks same-day conflicts, requires explicit overwrite confirmation, and surfaces save errors), plus `WeeklyWeightChart` (`fl_chart`), `WeeklyWeightCard`, `WeightHistoryView`, and `WeightEntryBottomSheet`.
4. **Navigation shell integration**: Upgrade `HomeShellScreen` into a 3-tab `NavigationBar` (`Home`, `Weights`, `Profile`) with a `FloatingActionButton` (`Key('add_weight_fab')`) on the `Weights` tab.

## Critical Implementation Details

- **ISO week grouping & rounding invariant**: Every calendar date (`YYYY-MM-DD`) maps to its ISO week Monday (`date.subtract(Duration(days: date.weekday - DateTime.monday))` in UTC/date-only arithmetic to avoid DST off-by-one shifts) and Sunday (`monday.add(const Duration(days: 6))`). Weekly average is rounded to 2 decimal places (`(sum / entries.length * 100).round() / 100`).
- **Chart vs. list ordering**: `WeightHistoryState` exposes `weeklySummaries` sorted **newest week first** (for the expandable `ListView` where index 0 is expanded by default) and `chartSummaries` containing up to the **12 most recent logged weeks sorted oldest week first** (left-to-right on the `fl_chart` X-axis).
- **Empty & error state resilience**: When `WeightHistoryViewModel.loadEntries(showLoading: false)` is called during pull-to-refresh or after saving an entry while `state` is already `WeightHistoryLoaded`, a repository failure must **not** replace the loaded list/chart with a blank screen; instead, it emits `WeightHistoryLoaded` with a transient `refreshErrorMessage` (cleared via `clearRefreshError()`) so `WeightHistoryView` can display an error `SnackBar` while keeping existing data visible. Initial load failures (when no prior data is loaded) emit `WeightHistoryError(message)` and render a dedicated error state with a `Retry` button.
- **Preserving `S-01` widget test compatibility**: When `HomeShellScreen` builds, `WeightHistoryView` is only mounted when the `Weights` tab (index 1) is selected (or `weightRepositoryProvider` defaults cleanly), ensuring existing `home_shell_screen_test.dart` and `app_router_test.dart` tests that only override `authRepositoryProvider` never trigger unmocked `FirebaseDatabase.instance` calls on tab 0.

## Phase 1: Dependencies, RTDB Security Rules & Core Utilities

### Overview

Add `fl_chart` to `bulk_tempo/pubspec.yaml`, create owner-scoped Firebase Realtime Database security rules in `bulk_tempo/database.rules.json` (`F-01`), and implement pure-Dart weight/date validation and ISO Monday–Sunday week utilities with unit tests.

### Changes Required:

#### 1. Chart Dependency

**File**: `bulk_tempo/pubspec.yaml`

**Intent**: Add `fl_chart` to runtime dependencies so the presentation layer can render the weekly-average line chart.

**Contract**: Add `fl_chart: ^0.70.2` (or latest SDK-compatible `^0.70.0` / `^1.0.0` resolved by `flutter pub get`) under `dependencies:`.

#### 2. Firebase Realtime Database Security Rules (`F-01`)

**File**: `bulk_tempo/database.rules.json`

**Intent**: Enforce per-user data isolation (`FR-012`, `F-01`) and server-side schema validation for weight entries keyed by `YYYY-MM-DD` under `users/$uid/weight_entries/$date`.

**Contract**: JSON rules matching `bulk_tempo/firebase.json:2-4`:
```json
{
  "rules": {
    ".read": false,
    ".write": false,
    "users": {
      "$uid": {
        ".read": "auth != null && auth.uid == $uid",
        ".write": "auth != null && auth.uid == $uid",
        "weight_entries": {
          "$date": {
            ".validate": "newData.hasChildren(['date', 'weightKg', 'updatedAt']) && newData.child('date').isString() && newData.child('date').val() == $date && newData.child('date').val().matches(/^\\d{4}-\\d{2}-\\d{2}$/) && newData.child('weightKg').isNumber() && newData.child('weightKg').val() >= 20.0 && newData.child('weightKg').val() <= 300.0 && newData.child('updatedAt').isString()"
          }
        }
      }
    }
  }
}
```

#### 3. Weight & Historical Date Validators

**File**: `bulk_tempo/lib/core/utils/weight_validators.dart`

**Intent**: Provide pure-Dart parsing and validation for weight inputs (`20.0–300.0 kg`, up to 2 decimal places accepting `.` or `,`) and entry dates (`[today - 365 days, today]`, no future dates).

**Contract**: `abstract final class WeightValidators` exposing:
- `static const double minWeightKg = 20.0;`
- `static const double maxWeightKg = 300.0;`
- `static const int maxLookbackDays = 365;`
- `static double? parseWeightKg(String rawInput)` — trims, normalizes `,` to `.`, validates regex `^\d+(\.\d{1,2})?$`, and returns `double?`.
- `static String? validateWeightInput(String rawInput)` — returns `null` when valid (`20.0 <= value <= 300.0` and at most 2 decimals) or a clear user-facing error message.
- `static String? validateEntryDate(DateTime date, {required DateTime now})` — compares calendar dates (`DateTime.utc(y, m, d)`), rejecting dates after `now` ("Date cannot be in the future") or earlier than `now - 365 days` ("Date cannot be more than 365 days in the past").

#### 4. ISO Week & Date Formatting Utilities

**File**: `bulk_tempo/lib/core/utils/week_date_utils.dart`

**Intent**: Centralize timezone-safe calendar date (`YYYY-MM-DD`) parsing/formatting, ISO Monday–Sunday week boundary calculation, and human-readable week/day labels without external `intl` locale initialization issues.

**Contract**: `abstract final class WeekDateUtils` exposing:
- `static DateTime normalizeDateUtc(DateTime date)` — returns `DateTime.utc(date.year, date.month, date.day)`.
- `static String toIsoDateString(DateTime date)` — formats as `YYYY-MM-DD`.
- `static DateTime? tryParseIsoDate(String value)` — strictly parses `YYYY-MM-DD` into `DateTime.utc(y, m, d)`, rejecting invalid calendar dates (e.g., `2026-02-30`).
- `static DateTime startOfIsoWeekUtc(DateTime date)` — returns the Monday (`weekday == DateTime.monday`) of `date`'s ISO week in UTC.
- `static DateTime endOfIsoWeekUtc(DateTime date)` — returns the Sunday (`startOfIsoWeekUtc(date).add(const Duration(days: 6))`) in UTC.
- `static String formatWeekRange(DateTime weekStartMonday, DateTime weekEndSunday)` — e.g., `"Oct 5 – Oct 11, 2026"` or `"Sep 28 – Oct 4, 2026"`.
- `static String formatShortWeekLabel(DateTime weekStartMonday)` — compact label for chart X-axis, e.g., `"Oct 5"`.
- `static String formatDayWithWeekday(DateTime date)` — e.g., `"Mon, Oct 5, 2026"`.
- `static double roundToTwoDecimals(double value)` — returns `(value * 100).roundToDouble() / 100`.

#### 5. Unit Tests for Validators and Week Utilities

**File**: `bulk_tempo/test/core/utils/weight_validators_test.dart`, `bulk_tempo/test/core/utils/week_date_utils_test.dart`

**Intent**: Verify boundary values (`20.0`, `300.0`, `19.99`, `300.01`, `.` and `,` separators, `>2` decimals, future dates, `365`-day lookback boundary) and ISO Monday–Sunday week math across month/year boundaries and leap years.

**Contract**: Pure Dart unit tests covering all public methods of `WeightValidators` and `WeekDateUtils`.

### Success Criteria:

#### Automated Verification:

- Dependencies resolve cleanly: `cd bulk_tempo && flutter pub get`
- RTDB security rules JSON is valid and enforces `$uid` ownership and weight/date bounds: `python3 -m json.tool bulk_tempo/database.rules.json > /dev/null`
- Core validator and week utility unit tests pass: `cd bulk_tempo && flutter test test/core/utils/weight_validators_test.dart test/core/utils/week_date_utils_test.dart`
- Static analysis passes with zero warnings: `cd bulk_tempo && flutter analyze`
- Code formatting check passes: `cd bulk_tempo && dart format --output=none --set-exit-if-changed lib test`

#### Manual Verification:

- Inspect `bulk_tempo/database.rules.json` and confirm `.read`/`.write` are restricted to `auth != null && auth.uid == $uid` and `.validate` enforces `weightKg >= 20 && weightKg <= 300`.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Phase 2: Weight Domain & Data Layer

### Overview

Implement the weight domain models (`WeightEntryEntity`, `WeeklyWeightSummaryEntity` with ISO Monday–Sunday grouping and 2-decimal weekly average calculation), repository contract (`WeightRepository`), Firebase Realtime Database data layer (`WeightEntryDto`, `WeightRemoteDataSource`, `WeightRepositoryImpl`), and `FakeWeightRepository` with unit tests.

### Changes Required:

#### 1. Domain Entities (`WeightEntryEntity` & `WeeklyWeightSummaryEntity`)

**File**: `bulk_tempo/lib/features/weight/domain/models/weight_entry_entity.dart`, `bulk_tempo/lib/features/weight/domain/models/weekly_weight_summary_entity.dart`

**Intent**: Represent individual daily weight measurements and ISO Monday–Sunday weekly aggregates in pure Dart with zero external dependencies.

**Contract**:
- `WeightEntryEntity`:
  - Fields: `final String dateIso` (`YYYY-MM-DD`), `final DateTime date` (normalized UTC date), `final double weightKg`, `final DateTime updatedAt`.
  - Value equality (`operator ==`, `hashCode`), `copyWith`, and `toString`.
- `WeeklyWeightSummaryEntity`:
  - Fields:
    - `final String weekStartIso` (`YYYY-MM-DD` of Monday)
    - `final DateTime weekStartMonday`
    - `final DateTime weekEndSunday`
    - `final double averageWeightKg` (rounded to 2 decimal places)
    - `final List<WeightEntryEntity> entries` (logged days within that week, sorted newest date first)
  - Computed getter: `int get loggedDaysCount => entries.length;`
  - Static domain aggregation method: `static List<WeeklyWeightSummaryEntity> groupEntriesByIsoWeek(List<WeightEntryEntity> entries)`:
    - Deduplicates by `dateIso` (keeping latest if duplicates exist in input), groups entries by `WeekDateUtils.startOfIsoWeekUtc(entry.date)`, excludes any week with 0 entries, sorts each week's `entries` descending by `dateIso`, computes `averageWeightKg = WeekDateUtils.roundToTwoDecimals(sum / entries.length)`, and returns the list of `WeeklyWeightSummaryEntity` sorted descending by `weekStartIso` (newest week first).

#### 2. Domain Repository Contract

**File**: `bulk_tempo/lib/features/weight/domain/repositories/weight_repository.dart`

**Intent**: Define the domain boundary for fetching and saving user-scoped daily weight entries returning `Result<T, AppFailure>`.

**Contract**:
- `abstract class WeightRepository`:
  - `Future<Result<List<WeightEntryEntity>, AppFailure>> getWeightEntries({required String userId});`
  - `Future<Result<WeightEntryEntity, AppFailure>> saveWeightEntry({required String userId, required WeightEntryEntity entry});`

#### 3. Data Transfer Object (`WeightEntryDto`)

**File**: `bulk_tempo/lib/features/weight/data/models/weight_entry_dto.dart`

**Intent**: Serialize and deserialize weight entries between Firebase Realtime Database JSON maps and `WeightEntryEntity`.

**Contract**:
- `WeightEntryDto` with `date` (`String`), `weightKg` (`double`), `updatedAt` (`String` ISO-8601 timestamp).
- `factory WeightEntryDto.fromJson(Map<Object?, Object?> json, {String? keyDate})` (handles `int` or `double` `num` values from RTDB for `weightKg`).
- `Map<String, dynamic> toJson()`, `WeightEntryEntity toEntity()`, and `factory WeightEntryDto.fromEntity(WeightEntryEntity entity)`.

#### 4. Firebase Realtime Database Remote Data Source

**File**: `bulk_tempo/lib/features/weight/data/datasources/weight_remote_data_source.dart`

**Intent**: Read and write `WeightEntryDto` records under `users/$userId/weight_entries/$date` in Firebase Realtime Database and translate Firebase/network errors into `AppException`s.

**Contract**:
- Providers: `firebaseDatabaseProvider` (`Provider<FirebaseDatabase>`) and `weightRemoteDataSourceProvider` (`Provider<WeightRemoteDataSource>`).
- `abstract class WeightRemoteDataSource`:
  - `Future<List<WeightEntryDto>> getWeightEntries({required String userId});`
  - `Future<WeightEntryDto> saveWeightEntry({required String userId, required WeightEntryDto dto});`
- `WeightRemoteDataSourceImpl(FirebaseDatabase)`:
  - Reads snapshot via `_database.ref('users/$userId/weight_entries').get()`, parses child maps into `List<WeightEntryDto>`, and sorts descending by `date`.
  - Writes via `_database.ref('users/$userId/weight_entries/${dto.date}').set(dto.toJson())`.
  - Maps `FirebaseException` (`permission-denied` -> `AuthException`, network codes -> `NetworkException`, others -> `ServerException`).

#### 5. Weight Repository Implementation

**File**: `bulk_tempo/lib/features/weight/data/repositories/weight_repository_impl.dart`

**Intent**: Implement `WeightRepository`, validating `userId` and entry bounds and translating `AppException`s into `Result<T, AppFailure>`.

**Contract**:
- `weightRepositoryProvider` (`Provider<WeightRepository>`).
- `WeightRepositoryImpl(WeightRemoteDataSource)` returning `Result.success(...)` or mapped `AuthFailure`, `NetworkFailure`, `ServerFailure`, `ValidationFailure`, `UnknownFailure`.

#### 6. Test Helpers & Unit Tests for Domain and Data Layers

**File**: `bulk_tempo/test/test_helpers/mocks.dart`, `bulk_tempo/test/test_helpers/fakes/fake_weight_repository.dart`, `bulk_tempo/test/test_helpers/fakes/fake_weight_repository_test.dart`, `bulk_tempo/test/features/weight/domain/models/weight_entry_entity_test.dart`, `bulk_tempo/test/features/weight/domain/models/weekly_weight_summary_entity_test.dart`, `bulk_tempo/test/features/weight/data/models/weight_entry_dto_test.dart`, `bulk_tempo/test/features/weight/data/datasources/weight_remote_data_source_test.dart`, `bulk_tempo/test/features/weight/data/repositories/weight_repository_impl_test.dart`

**Intent**: Provide in-memory `FakeWeightRepository` (isolating entries per `userId` to test cross-account isolation) and `mocktail` mocks, and unit-test ISO week grouping, 2-decimal averaging, skipped-week omission, DTO parsing, data source calls, and repository error mapping.

**Contract**: Unit tests covering 1-day weeks, 7-day weeks, skipped empty weeks between logged weeks, week boundary transitions (Sunday vs Monday), and per-user data isolation.

### Success Criteria:

#### Automated Verification:

- Domain entity and weekly grouping unit tests pass: `cd bulk_tempo && flutter test test/features/weight/domain/models/weight_entry_entity_test.dart test/features/weight/domain/models/weekly_weight_summary_entity_test.dart`
- DTO, RemoteDataSource, Repository, and FakeWeightRepository unit tests pass: `cd bulk_tempo && flutter test test/features/weight/data/ test/test_helpers/fakes/fake_weight_repository_test.dart`
- Static analysis passes with zero warnings: `cd bulk_tempo && flutter analyze`
- Code formatting check passes: `cd bulk_tempo && dart format --output=none --set-exit-if-changed lib test`

#### Manual Verification:

- Verify `bulk_tempo/lib/features/weight/domain/` has zero imports from `package:flutter/`, `data/`, or `presentation/`.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Phase 3: Weight Presentation Layer (MVVM, `fl_chart` Trend & Expandable Weekly List)

### Overview

Implement the pure-Dart MVVM states and ViewModels (`WeightHistoryState`/`WeightHistoryViewModel` and `WeightEntryFormState`/`WeightEntryViewModel`), the `WeeklyWeightChart` widget using `fl_chart` (plotting up to the 12 most recent weekly averages chronologically left-to-right), the expandable `WeeklyWeightCard` widget (showing weekly average and logged daily measurements), `WeightHistoryView`, and `WeightEntryBottomSheet` with same-day overwrite confirmation.

### Changes Required:

#### 1. Weight History State & ViewModel

**File**: `bulk_tempo/lib/features/weight/presentation/view_models/weight_history_state.dart`, `bulk_tempo/lib/features/weight/presentation/view_models/weight_history_view_model.dart`

**Intent**: Manage loading, refreshing, and grouping the authenticated user's weight entries into weekly summaries for the list and the 12-week chronological slice for the chart, while distinguishing initial load errors from non-destructive refresh errors.

**Contract**:
- `sealed class WeightHistoryState`:
  - `WeightHistoryInitial()`
  - `WeightHistoryLoading()`
  - `WeightHistoryLoaded({required List<WeightEntryEntity> entries, required List<WeeklyWeightSummaryEntity> weeklySummaries, required List<WeeklyWeightSummaryEntity> chartSummaries, String? refreshErrorMessage})`
    - `weeklySummaries`: all logged weeks sorted **newest week first**.
    - `chartSummaries`: up to `maxChartWeeks = 12` most recent logged weeks sorted **oldest week first** (left-to-right).
    - `refreshErrorMessage`: nullable transient error message populated when a pull-to-refresh or background reload fails while data is already loaded.
    - Helper `bool hasEntryForDate(String dateIso)` for same-day overwrite detection.
  - `WeightHistoryError(String message)`
- `weightHistoryViewModelProvider` (`AutoDisposeNotifierProvider<WeightHistoryViewModel, WeightHistoryState>`):
  - Watches `authViewModelProvider` for current `user?.id` and `weightRepositoryProvider`.
  - `Future<void> loadEntries({bool showLoading = true})` fetches entries, computes `WeeklyWeightSummaryEntity.groupEntriesByIsoWeek(entries)`, and emits `WeightHistoryLoaded`. If the repository returns a failure when `state` is already `WeightHistoryLoaded` and `showLoading == false`, preserves the existing `WeightHistoryLoaded` data and sets `refreshErrorMessage: failure.message`; otherwise emits `WeightHistoryError(failure.message)`.
  - `void clearRefreshError()` — clears `refreshErrorMessage` on `WeightHistoryLoaded`.

#### 2. Weight Entry Form State & ViewModel

**File**: `bulk_tempo/lib/features/weight/presentation/view_models/weight_entry_form_state.dart`, `bulk_tempo/lib/features/weight/presentation/view_models/weight_entry_view_model.dart`

**Intent**: Manage the Add Weight form (weight text, selected date, validation errors, same-day overwrite confirmation prompt, and submission error state) in pure Dart without `BuildContext`.

**Contract**:
- `WeightEntryFormState`:
  - Fields: `String weightInput`, `DateTime selectedDate`, `FormStatus status`, `String? weightError`, `String? dateError`, `String? errorMessage`, `bool requiresOverwriteConfirmation`, `WeightEntryEntity? existingEntryForDate`.
- `weightEntryViewModelProvider` (`AutoDisposeNotifierProvider<WeightEntryViewModel, WeightEntryFormState>`):
  - `void onWeightChanged(String value)`
  - `void onDateChanged(DateTime date)`
  - `Future<bool> submit({bool confirmOverwrite = false})`:
    - Validates `weightInput` and `selectedDate` via `WeightValidators`.
    - Checks if an entry already exists for `WeekDateUtils.toIsoDateString(selectedDate)` in `weightHistoryViewModelProvider`. If it exists and `!confirmOverwrite`, sets `requiresOverwriteConfirmation: true` and returns `false` so the View can present the confirmation dialog.
    - When confirmed (or no conflict), saves via `WeightRepository.saveWeightEntry`, triggers `ref.read(weightHistoryViewModelProvider.notifier).loadEntries(showLoading: false)` on success, emits `FormStatus.success`, and returns `true`. On repository failure, emits `FormStatus.failure` with `errorMessage: failure.message` and returns `false`.
  - `void cancelOverwriteConfirmation()` — resets `requiresOverwriteConfirmation: false`.

#### 3. Weekly Average Trend Chart Widget (`fl_chart`)

**File**: `bulk_tempo/lib/features/weight/presentation/widgets/weekly_weight_chart.dart`

**Intent**: Render the weekly-average dynamic chart above the weekly list using `fl_chart`'s `LineChart`, taking into account **only the average of each week** (`chartSummaries`, oldest to newest, up to 12 weeks).

**Contract**:
- `WeeklyWeightChart({super.key, required List<WeeklyWeightSummaryEntity> chartSummaries})`:
  - Key: `const Key('weekly_weight_chart_card')`.
  - Plot points: `FlSpot(index.toDouble(), summary.averageWeightKg)` for each week in `chartSummaries`.
  - Single-week state (`chartSummaries.length == 1`): displays the single plotted weekly average point on the `LineChart` along with a visible helper banner (`Key('single_week_chart_hint')`: `"Log weights in at least 2 weeks to see a multi-week trend line"`).
  - Multi-week state (`chartSummaries.length >= 2`): renders curved/connected `LineChartBarData` with visible dots, padded Y-axis min/max bounds around the weekly averages, bottom X-axis labels showing `WeekDateUtils.formatShortWeekLabel(summary.weekStartMonday)`, and touch tooltips displaying the week's date range and `XX.XX kg avg`.

#### 4. Expandable Weekly Weight Card Widget

**File**: `bulk_tempo/lib/features/weight/presentation/widgets/weekly_weight_card.dart`

**Intent**: Display a single ISO week summary row with its average weight and expand to reveal the daily weight measurements inputted by the user for that week.

**Contract**:
- `WeeklyWeightCard({super.key, required WeeklyWeightSummaryEntity summary, required bool initiallyExpanded})`:
  - Uses `Card` + `ExpansionTile` (`key: Key('week_card_${summary.weekStartIso}')`, `initiallyExpanded: initiallyExpanded`).
  - Header displays:
    - Week date range (`WeekDateUtils.formatWeekRange(summary.weekStartMonday, summary.weekEndSunday)`)
    - Weekly average (`"${summary.averageWeightKg.toStringAsFixed(2)} kg avg"`)
    - Entry count badge (`"${summary.loggedDaysCount}/7 days"`)
  - Expanded children list each `WeightEntryEntity` in `summary.entries` (`Key('daily_entry_${entry.dateIso}')`), showing `WeekDateUtils.formatDayWithWeekday(entry.date)` and `"${entry.weightKg.toStringAsFixed(2)} kg"`.

#### 5. Weight Entry Bottom Sheet & Overwrite Dialog

**File**: `bulk_tempo/lib/features/weight/presentation/widgets/weight_entry_bottom_sheet.dart`

**Intent**: Provide a modal bottom sheet for entering a weight measurement (`FR-002`) and picking today or a historical date up to 365 days ago (`FR-005`), prompting for confirmation before overwriting an existing same-day measurement and surfacing inline validation and submission errors.

**Contract**:
- `WeightEntryBottomSheet` (`ConsumerStatefulWidget`):
  - Weight `TextField` (`Key('weight_input_field')`) displaying `state.weightError` when empty/invalid, Date picker selector (`Key('weight_date_picker_button')`) displaying `state.dateError` when out of bounds, and Save button (`Key('save_weight_button')`).
  - Renders a visible error banner (`Key('weight_entry_error_banner')`) inside the bottom sheet when `state.errorMessage != null` (e.g., network/server failure during save) while keeping the user's input intact for retry.
  - Listens to `weightEntryViewModelProvider`:
    - When `requiresOverwriteConfirmation` becomes `true`, shows an `AlertDialog` (`Key('overwrite_weight_dialog')`) asking to confirm replacing the existing weight for that date, with `Cancel` and `Replace` (`Key('confirm_overwrite_weight_button')`) actions.
    - When `status == FormStatus.success`, closes the bottom sheet and shows a confirmation `SnackBar`.

#### 6. Weight History View (Including Empty & Error States)

**File**: `bulk_tempo/lib/features/weight/presentation/views/weight_history_view.dart`

**Intent**: Render the complete Weights tab content combining the `WeeklyWeightChart` at the top and the scrollable list of expandable `WeeklyWeightCard` items below, with comprehensive Empty, Loading, Initial Error, and Refresh Error states.

**Contract**:
- `WeightHistoryView` (`ConsumerStatefulWidget`):
  - Triggers `loadEntries()` on first initialization if state is `WeightHistoryInitial`.
  - Listens to `weightHistoryViewModelProvider` for `WeightHistoryLoaded.refreshErrorMessage`: when non-null, displays an error `SnackBar` (`Key('weight_history_refresh_error_snackbar')`) and calls `clearRefreshError()`.
  - Renders:
    - `WeightHistoryLoading`: centered `CircularProgressIndicator` (`Key('weight_history_loading_indicator')`).
    - `WeightHistoryError(message)`: dedicated error view (`Key('weight_history_error_state')`) showing `Icons.error_outline`, `message`, and a `FilledButton.icon` (`Key('weight_history_retry_button')`, label `'Retry'`) calling `loadEntries()`.
    - `WeightHistoryLoaded` when `weeklySummaries.isEmpty`: scrollable `RefreshIndicator` wrapping a centered empty state (`Key('weight_history_empty_state')`) with `Icons.monitor_weight_outlined`, title `'No weight entries yet'`, helper subtitle, and an `'Add First Weight'` button (`Key('empty_state_add_weight_button')`) that opens `WeightEntryBottomSheet`.
    - `WeightHistoryLoaded` when non-empty: `RefreshIndicator` wrapping a `ListView` containing `WeeklyWeightChart(chartSummaries: state.chartSummaries)` at the top followed by `WeeklyWeightCard` items for each week in `state.weeklySummaries` (with `initiallyExpanded: index == 0`).

#### 7. Presentation Unit & Widget Tests

**File**: `bulk_tempo/test/features/weight/presentation/view_models/weight_history_view_model_test.dart`, `bulk_tempo/test/features/weight/presentation/view_models/weight_entry_view_model_test.dart`, `bulk_tempo/test/features/weight/presentation/views/weight_history_view_test.dart`

**Intent**: Test ViewModel state transitions, 12-week chart slicing, empty state, initial load error + retry, non-destructive refresh error `SnackBar`, same-day conflict detection, overwrite confirmation flow, save error banner, `WeeklyWeightChart` rendering (1-week and multi-week), and expandable `WeeklyWeightCard` daily rows.

**Contract**: Headless `ProviderContainer` tests for both ViewModels and `tester.pumpApp` widget tests for `WeightHistoryView` and `WeightEntryBottomSheet`.

### Success Criteria:

#### Automated Verification:

- WeightHistoryViewModel and WeightEntryViewModel unit tests pass: `cd bulk_tempo && flutter test test/features/weight/presentation/view_models/weight_history_view_model_test.dart test/features/weight/presentation/view_models/weight_entry_view_model_test.dart`
- WeightHistoryView, WeeklyWeightChart, WeeklyWeightCard, and WeightEntryBottomSheet widget tests pass: `cd bulk_tempo && flutter test test/features/weight/presentation/views/weight_history_view_test.dart`
- Static analysis passes with zero warnings: `cd bulk_tempo && flutter analyze`
- Code formatting check passes: `cd bulk_tempo && dart format --output=none --set-exit-if-changed lib test`

#### Manual Verification:

- Verify `WeightHistoryViewModel` and `WeightEntryViewModel` contain zero `flutter/material.dart` imports or `BuildContext` references.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Phase 4: Home Shell 3-Tab Integration & Verification

### Overview

Integrate `WeightHistoryView` and `WeightEntryBottomSheet` into `HomeShellScreen` via a 3-tab bottom `NavigationBar` (`Home`, `Weights`, `Profile`) with an Add Weight `FloatingActionButton` on the `Weights` tab, update widget tests, and synchronize `context/foundation/roadmap.md`.

### Changes Required:

#### 1. 3-Tab `HomeShellScreen` with `Weights` Tab & FAB

**File**: `bulk_tempo/lib/features/auth/presentation/views/home_shell_screen.dart`

**Intent**: Upgrade `HomeShellScreen` to host a 3-tab `NavigationBar` (`Home` at index 0, `Weights` at index 1 rendering `WeightHistoryView`, and `Profile` at index 2) and display a `FloatingActionButton` (`Key('add_weight_fab')`) on the `Weights` tab that opens `WeightEntryBottomSheet`, while keeping all existing `S-01` logout keys and behavior intact.

**Contract**:
- `HomeShellScreen` (`ConsumerStatefulWidget` managing `_selectedIndex`, defaulting to `0`):
  - `AppBar` preserves `Key('home_app_bar_logout_button')`.
  - Tab `0` (`Home`, `Key('nav_home_tab')`): preserves `'Welcome to Bulk Tempo'`, `user?.email ?? 'No email'`, and `Key('home_logout_button')`, plus a quick-action button to jump to `Weights`.
  - Tab `1` (`Weights`, `Key('nav_weights_tab')`): renders `const WeightHistoryView()` and displays `FloatingActionButton.extended` (`Key('add_weight_fab')`, label `'Add Weight'`) opening `WeightEntryBottomSheet`.
  - Tab `2` (`Profile`, `Key('nav_profile_tab')`): displays user email and logout button triggering the confirmation dialog.

#### 2. Home Shell & End-to-End Flow Widget Tests

**File**: `bulk_tempo/test/features/auth/presentation/views/home_shell_screen_test.dart`

**Intent**: Retain all existing `S-01` logout tests and add widget tests verifying tab switching to `Weights`, viewing empty/error/loaded states with the weekly chart and expandable week cards, and logging a new weight via `add_weight_fab`.

**Contract**: Existing 7 tests in `home_shell_screen_test.dart` continue to pass unchanged, plus new tests covering `nav_weights_tab`, `WeeklyWeightChart`, `WeeklyWeightCard`, empty/error states, and `add_weight_fab` modal entry creation using `FakeWeightRepository`.

#### 3. Roadmap Synchronization (`F-01` & `S-02`)

**File**: `context/foundation/roadmap.md`

**Intent**: Record the resolution of `F-01` (`private-data-verification` — Firebase Realtime Database selected with `database.rules.json`) and align `S-01` (`done`) and `S-02` (`dated-weight-history`) status metadata.

**Contract**: Update `## At a glance`, `### F-01`, `### S-02`, and `## Open Roadmap Questions` item #5 in `context/foundation/roadmap.md`.

### Success Criteria:

#### Automated Verification:

- Updated HomeShellScreen and AppRouter widget tests pass: `cd bulk_tempo && flutter test test/features/auth/presentation/views/home_shell_screen_test.dart test/app/router/app_router_test.dart`
- Full test suite passes across all features: `cd bulk_tempo && flutter test`
- Static analysis passes with zero warnings: `cd bulk_tempo && flutter analyze`
- Code formatting check passes: `cd bulk_tempo && dart format --output=none --set-exit-if-changed lib test`

#### Manual Verification:

- Launch the app, sign in, navigate to the `Weights` tab, verify the empty state and error retry behavior, log weights across multiple days and weeks, verify the weekly-average `fl_chart` trend chart above the list and expandable weekly cards with daily entries, test same-day overwrite confirmation, and verify entries persist after logging in on a second device/session.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Testing Strategy

### Unit Tests:

- `weight_validators_test.dart`: Weight bounds (`20.0–300.0 kg`), `.` and `,` decimal separators, max 2 decimal places, date lookback (`365` days), and future-date rejection.
- `week_date_utils_test.dart`: ISO Monday–Sunday calculation for every weekday (Mon–Sun), month/year rollovers, leap years, and 2-decimal rounding.
- `weekly_weight_summary_entity_test.dart`: Grouping daily entries into ISO weeks, computing 2-decimal weekly averages, omitting empty weeks with 0 measurements, sorting weeks newest-first, and sorting daily entries within a week newest-first.
- `weight_entry_dto_test.dart`, `weight_remote_data_source_test.dart`, `weight_repository_impl_test.dart`, `fake_weight_repository_test.dart`: Serialization, RTDB path structure (`users/$uid/weight_entries/$date`), per-user isolation, and exception-to-`AppFailure` mapping.
- `weight_history_view_model_test.dart` & `weight_entry_view_model_test.dart`: Loading state transitions, empty state, initial load error + retry, non-destructive refresh error handling, 12-week chronological chart slicing, same-day conflict detection, overwrite confirmation, and save failure state transitions.

### Integration / Widget Tests:

- `weight_history_view_test.dart`: Actionable empty state (`weight_history_empty_state` + `empty_state_add_weight_button`), loading indicator, initial load error state + retry button (`weight_history_error_state` + `weight_history_retry_button`), refresh error `SnackBar`, 1-week chart hint state, multi-week `fl_chart` `LineChart` rendering, newest week expanded by default showing inputted daily weights, expanding older weeks, and submitting new/overwritten weights or handling save errors via `WeightEntryBottomSheet`.
- `home_shell_screen_test.dart`: Tab navigation between `Home`, `Weights`, and `Profile`, `add_weight_fab` visibility only on `Weights`, and backward compatibility with all `S-01` logout tests.

### Manual Testing Steps:

1. Deploy or apply `bulk_tempo/database.rules.json` to the Firebase Realtime Database (`europe-west1`) instance.
2. Run the app (`cd bulk_tempo && flutter run`), log in, and switch to the `Weights` tab (`nav_weights_tab`). Verify the empty state (`No weight entries yet`) with its `'Add First Weight'` button is shown when no entries exist.
3. Tap `Add Weight` (or `'Add First Weight'`), enter today's weight (e.g., `82.45`), and save. Verify the single-week card is expanded showing today's weight, the weekly average (`82.45 kg avg`, `1/7 days`), and the single-week chart helper hint.
4. Add another weight in the same week (e.g., yesterday `82.15`) and a weight in the previous ISO week (e.g., `81.80`). Verify the current week average updates to `82.30 kg avg` (`2/7 days`) and the `fl_chart` line chart plots both weekly averages (`81.80` -> `82.30`) left-to-right.
5. Attempt to log another weight for today's date; verify the overwrite confirmation dialog appears and updates today's entry only when confirmed.
6. Simulate offline/network failure when loading or saving to confirm the error state with `'Retry'` and the bottom-sheet error banner behave cleanly without losing input or crashing.
7. Log in with the same account on a second device or browser session and confirm the weekly chart and weekly list load identically.

## Performance Considerations

- Grouping and averaging up to 365 daily entries in memory (`WeeklyWeightSummaryEntity.groupEntriesByIsoWeek`) is $O(N \log N)$ where $N \le 365$, executing in under 1 millisecond on mobile devices.
- Capping `chartSummaries` at the 12 most recent logged weeks prevents X-axis label collisions and keeps `fl_chart` canvas rendering fast without horizontal scrolling.

## Migration Notes

- No local or cloud data migration is required (`context/foundation/prd.md:108`).
- `bulk_tempo/database.rules.json` should be deployed to Firebase Realtime Database via `firebase deploy --only database` before production use.

## References

- PRD: `context/foundation/prd.md` (`FR-002`, `FR-005`, `FR-012`)
- Roadmap: `context/foundation/roadmap.md` (`F-01`, `S-02`)
- Prior slice plan: `context/changes/private-account-access/plan.md`
- Architecture standards: `context/documentation/01_architecture_overview.md`, `02_project_structure.md`, `03_state_management_mvvm.md`, `04_data_and_domain.md`, `06_testing_strategy.md`

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands. Do not rename step titles. See `references/progress-format.md`.

### Phase 1: Dependencies, RTDB Security Rules & Core Utilities

#### Automated

- [x] 1.1 Dependencies resolve cleanly: `cd bulk_tempo && flutter pub get` — 3dd3a46
- [x] 1.2 RTDB security rules JSON is valid and enforces `$uid` ownership and weight/date bounds: `python3 -m json.tool bulk_tempo/database.rules.json > /dev/null` — 3dd3a46
- [x] 1.3 Core validator and week utility unit tests pass: `cd bulk_tempo && flutter test test/core/utils/weight_validators_test.dart test/core/utils/week_date_utils_test.dart` — 3dd3a46
- [x] 1.4 Static analysis passes with zero warnings: `cd bulk_tempo && flutter analyze` — 3dd3a46
- [x] 1.5 Code formatting check passes: `cd bulk_tempo && dart format --output=none --set-exit-if-changed lib test` — 3dd3a46

#### Manual

- [x] 1.6 Inspect `bulk_tempo/database.rules.json` and confirm `.read`/`.write` are restricted to `auth != null && auth.uid == $uid` and `.validate` enforces `weightKg >= 20 && weightKg <= 300`. — 3dd3a46

### Phase 2: Weight Domain & Data Layer

#### Automated

- [x] 2.1 Domain entity and weekly grouping unit tests pass: `cd bulk_tempo && flutter test test/features/weight/domain/models/weight_entry_entity_test.dart test/features/weight/domain/models/weekly_weight_summary_entity_test.dart` — 78157af
- [x] 2.2 DTO, RemoteDataSource, Repository, and FakeWeightRepository unit tests pass: `cd bulk_tempo && flutter test test/features/weight/data/ test/test_helpers/fakes/fake_weight_repository_test.dart` — 78157af
- [x] 2.3 Static analysis passes with zero warnings: `cd bulk_tempo && flutter analyze` — 78157af
- [x] 2.4 Code formatting check passes: `cd bulk_tempo && dart format --output=none --set-exit-if-changed lib test` — 78157af

#### Manual

- [x] 2.5 Verify `bulk_tempo/lib/features/weight/domain/` has zero imports from `package:flutter/`, `data/`, or `presentation/`. — 78157af

### Phase 3: Weight Presentation Layer (MVVM, `fl_chart` Trend & Expandable Weekly List)

#### Automated

- [x] 3.1 WeightHistoryViewModel and WeightEntryViewModel unit tests pass: `cd bulk_tempo && flutter test test/features/weight/presentation/view_models/weight_history_view_model_test.dart test/features/weight/presentation/view_models/weight_entry_view_model_test.dart` — b8366b6
- [x] 3.2 WeightHistoryView, WeeklyWeightChart, WeeklyWeightCard, and WeightEntryBottomSheet widget tests pass: `cd bulk_tempo && flutter test test/features/weight/presentation/views/weight_history_view_test.dart` — b8366b6
- [x] 3.3 Static analysis passes with zero warnings: `cd bulk_tempo && flutter analyze` — b8366b6
- [x] 3.4 Code formatting check passes: `cd bulk_tempo && dart format --output=none --set-exit-if-changed lib test` — b8366b6

#### Manual

- [x] 3.5 Verify `WeightHistoryViewModel` and `WeightEntryViewModel` contain zero `flutter/material.dart` imports or `BuildContext` references. — b8366b6

### Phase 4: Home Shell 3-Tab Integration & Verification

#### Automated

- [x] 4.1 Updated HomeShellScreen and AppRouter widget tests pass: `cd bulk_tempo && flutter test test/features/auth/presentation/views/home_shell_screen_test.dart test/app/router/app_router_test.dart` — 4aabf96
- [x] 4.2 Full test suite passes across all features: `cd bulk_tempo && flutter test` — 4aabf96
- [x] 4.3 Static analysis passes with zero warnings: `cd bulk_tempo && flutter analyze` — 4aabf96
- [x] 4.4 Code formatting check passes: `cd bulk_tempo && dart format --output=none --set-exit-if-changed lib test` — 4aabf96

#### Manual

- [x] 4.5 Launch the app, sign in, navigate to the `Weights` tab, verify the empty state and error retry behavior, log weights across multiple days and weeks, verify the weekly-average `fl_chart` trend chart above the list and expandable weekly cards with daily entries, test same-day overwrite confirmation, and verify entries persist after logging in on a second device/session. — 4aabf96
