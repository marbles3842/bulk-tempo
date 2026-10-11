# Import Workout Progress Implementation Plan

## Overview

Implement slice `S-05` (`import-workout-progress`) and resolve foundation item `F-02` (`workout-source-proof`) so authenticated users can connect their personal Hevy Pro API key (`https://api.hevyapp.com/docs/`), pre-validate it via `GET /v1/workouts/count`, store it encrypted on their device per user account (`flutter_secure_storage`), fetch the last 12 ISO weeks of workouts live via `GET /v1/workouts`, compute weekly workout progression metrics from working sets only (`normal`, `failure`, `dropset`), and inspect expandable ISO Monday–Sunday weekly workout cards with full exercise and set drill-downs in a dedicated `Workouts` tab alongside `Profile` key management.

## Current State Analysis

- **Authentication & Shell Navigation (`S-01` & `S-02`)**: `HomeShellScreen` (`lib/features/auth/presentation/views/home_shell_screen.dart:14-196`) renders a 3-tab bottom `NavigationBar` (`0: Home`, `1: Weights`, `2: Profile`) and preserves widget test keys verified by `test/features/auth/presentation/views/home_shell_screen_test.dart:28-366`.
- **ISO Week Grouping (`S-02`)**: `WeekDateUtils` (`lib/core/utils/week_date_utils.dart:2-117`) and `WeeklyWeightSummaryEntity` (`lib/features/weight/domain/models/weekly_weight_summary_entity.dart:5-149`) establish UTC-normalized ISO Monday–Sunday week math (`startOfIsoWeekUtc`, `endOfIsoWeekUtc`, `formatWeekRange`, `roundToTwoDecimals`).
- **Legacy Personal Key Config (`HeavyEnv`)**: `lib/core/constants/heavy_env.dart:1-13` and `README.md:7-40` currently define compile-time `HEAVY_BASE_URL` and `HEAVY_API_KEY` via `--dart-define-from-file=env.json`. Per `context/deployment/deploy-plan.md:28` and user decision, `HeavyEnv` must be deleted so the author's personal key is never bundled or shared across users.
- **Missing Capabilities**: `pubspec.yaml:9-20` has neither an HTTP client package (`http`) nor encrypted local storage (`flutter_secure_storage`), and no `lib/features/workout/` module exists yet.

## Desired End State

An authenticated user can navigate to the `Workouts` tab (`Key('nav_workouts_tab')`) or `Profile` tab (`Key('nav_profile_tab')`) in `HomeShellScreen`:
1. **Per-User Hevy API Key Setup & Pre-Validation (`F-02`)**:
   - `lib/core/constants/heavy_env.dart` is deleted and `README.md` no longer instructs bundling `HEAVY_API_KEY`.
   - When no key is stored for the active `user.id`, the `Workouts` tab renders an inline `Connect Hevy Account` setup card (`Key('workout_unconfigured_state')`) where the user pastes their Hevy UUID API key.
   - Saving a key validates the UUID format (`8-4-4-4-12` hex) locally, pre-validates the key against `GET https://api.hevyapp.com/v1/workouts/count` (`api-key` header), and persists it to `flutter_secure_storage` under `hevy_api_key_$userId` **only** if Hevy returns HTTP `200`.
   - The `Profile` tab displays a Hevy Integration card showing the connection status (masked key, e.g., `••••••••-••••-••••-••••-123456789abc`), a button to update/replace the key via a modal sheet, and a button to disconnect/remove the key.
2. **Live 12-Week Paginated Fetch & Session Caching (`FR-006`)**:
   - Workouts are fetched live from `GET https://api.hevyapp.com/v1/workouts?page=<page>&pageSize=10` (never migrated or copied into Firebase Realtime Database).
   - Pagination stops as soon as a workout's local calendar date (`DateTime.parse(startTime).toLocal()`) is earlier than Monday 11 weeks before the current ISO week's Monday (`cutoffMonday`, covering 12 ISO weeks total, matching `WeeklyWeightChart`), when `page >= page_count`, or when the **15-page safety cap** (150 workouts max) is reached. Workouts earlier than `cutoffMonday` on the boundary page are filtered out.
   - `WorkoutProgressViewModel` caches the loaded 12-week state across tab switches for the active authenticated user session and re-fetches only on pull-to-refresh, `Refresh` button tap, API key change, or user switch/logout.
3. **Working-Set Progression Metrics & Expandable Weekly UI (`PRD` Q2)**:
   - Each `WorkoutEntity` retains all sets (`warmup`, `normal`, `failure`, `dropset`), while weekly and exercise progression metrics use **working sets only** (`type != 'warmup'`): weekly workout count, weekly working set count, weekly total volume in kg ($\sum (\text{weightKg} \times \text{reps})$ for working sets with non-null `weightKg` and `reps`, rounded to 2 decimals), and per-exercise best working set (highest `weightKg`, tie-broken by highest `reps`; or highest `reps` for bodyweight sets).
   - The `Workouts` tab renders expandable ISO Monday–Sunday week cards (`WeeklyWorkoutCard`, newest week expanded by default) that list each workout in that week and expand/drill down to show every exercise's working sets (`weight_kg × reps`), warmup tags, and best working set.
4. **Resilient Error & Empty Handling**:
   - If any page fails during initial load, fail-fast into `WorkoutProgressError` with a `Retry` button (`Key('workout_progress_retry_button')`) so truncated partial weeks are never shown as complete data.
   - If a page fails during pull-to-refresh while workouts are already loaded, preserve the existing 12-week data on screen and emit a transient `refreshErrorMessage` displayed in a `SnackBar` (`Key('workout_progress_refresh_error_snackbar')`).

### Key Discoveries:

- **Hevy API pagination & auth contract**: `https://api.hevyapp.com/docs/swagger-ui-init.js` specifies `api-key` (UUID) in request headers, `GET /v1/workouts/count` returning `200 { "workout_count": 42 }`, and `GET /v1/workouts` accepting `page` (`>= 1`) and `pageSize` (max `10`; `> 10` returns `400`).
- **Strict Clean Architecture & MVVM boundaries**: `context/documentation/01_architecture_overview.md:49-57` and `03_state_management_mvvm.md:85-92` require `domain/` to remain pure Dart (importing only `core/result/` and `core/errors/`) and `ViewModel` classes to avoid `package:flutter/material.dart` and `BuildContext`.
- **Preserving `HomeShellScreen` tests**: `test/features/auth/presentation/views/home_shell_screen_test.dart:53-365` tests `Home` (index 0), `Weights` (index 1), and `Profile` (via `Key('nav_profile_tab')`). Keying destinations by `Key('nav_home_tab')`, `Key('nav_weights_tab')`, `Key('nav_workouts_tab')`, and `Key('nav_profile_tab')` keeps all existing tests passing without index-fragile breaks.

## What We're NOT Doing

- **Migrating or storing Hevy workouts in Firebase Realtime Database**: Workouts are fetched live from the Hevy API and cached in session memory; `database.rules.json` is not modified.
- **Bundling any shared or personal Hevy API key in the client binary**: `HeavyEnv` (`lib/core/constants/heavy_env.dart`) is deleted; every user supplies their own key stored locally in `flutter_secure_storage` (`hevy_api_key_$userId`).
- **Incremental delta sync via `/v1/workouts/events` or workout creation/mutation (`POST`/`PUT /v1/workouts`)**: Bulk Tempo is strictly a read-only consumer of the last 12 ISO weeks via `GET /v1/workouts/count` and `GET /v1/workouts`.
- **Displaying truncated partial workout history on mid-pagination errors**: Initial load fails fast if any page in the 12-week fetch errors.
- **Combined weight + workout dashboard (`S-06`) and pace status evaluation (`S-07`)**: `S-05` exposes the workout domain models, weekly summaries, and `WorkoutProgressViewModel` state that `S-06` and `S-07` will consume later.

## Implementation Approach

We follow the Feature-First Clean Architecture + Riverpod MVVM structure (`context/documentation/02_project_structure.md`):
1. **Core cleanup & validators**: Delete `lib/core/constants/heavy_env.dart`, update `README.md`, add `http` and `flutter_secure_storage` to `pubspec.yaml`, and add pure-Dart `HevyApiConstants` and `HevyKeyValidators` in `lib/core/`.
2. **Domain & Data layers (`lib/features/workout/{domain,data}/`)**: Model workouts, exercises, sets, and ISO weekly summaries (`WeeklyWorkoutSummaryEntity`) in pure Dart; implement `HevyKeyLocalDataSource` (`FlutterSecureStorage`), `WorkoutRemoteDataSource` (`http.Client` with `GET /v1/workouts/count` and paginated `GET /v1/workouts`), `WorkoutRepositoryImpl`, and `FakeWorkoutRepository`.
3. **Presentation layer (`lib/features/workout/presentation/`)**: Implement a session-cached `WorkoutProgressViewModel` (`NotifierProvider` watching `authViewModelProvider.select((s) => s.user?.id)`) and an `AutoDisposeNotifierProvider` `HevyKeyFormViewModel` for key validation/saving, paired with `WorkoutProgressView`, `WeeklyWorkoutCard`, `WorkoutDetailBottomSheet`, and `HevyKeyBottomSheet`.
4. **Shell & Profile integration (`lib/features/auth/presentation/views/home_shell_screen.dart`)**: Add the 4th `Workouts` tab, a `Go to Workouts` button on `Home` Tab 0, and a Hevy API key management section on the `Profile` tab.

## Critical Implementation Details

- **Session-cached `WorkoutProgressViewModel` & safe `HomeShellScreen` mounting**: `workoutProgressViewModelProvider` uses `NotifierProvider<WorkoutProgressViewModel, WorkoutProgressState>` (not `autoDispose`) so switching between `Home`, `Weights`, `Workouts`, and `Profile` tabs does not re-trigger 3–5 paginated Hevy HTTP calls. Inside `build()`, it watches `authViewModelProvider.select((s) => s.user?.id)` and `workoutRepositoryProvider`, returning `const WorkoutProgressInitial()` whenever the user logs out or switches accounts. In `Profile` tab, read the key status from `workoutProgressViewModelProvider` (and trigger `ensureInitialized()` safely when `Profile` or `Workouts` is opened, with a no-op fallback if unconfigured) so existing `HomeShellScreen` tests on Tab 0 never trigger unmocked storage or network calls.
- **12-Week local-date cutoff & pagination stopping rule**: Given `now` (injected clock, defaulting to `DateTime.now()`), compute `currentWeekMonday = WeekDateUtils.startOfIsoWeekUtc(DateTime.utc(now.year, now.month, now.day))` and `cutoffMonday = currentWeekMonday.subtract(const Duration(days: 11 * 7))` (12 ISO weeks inclusive). For each workout returned by `GET /v1/workouts?page=p&pageSize=10`, parse `start_time` via `DateTime.parse(startTime).toLocal()`, normalize to `localDateUtc = DateTime.utc(local.year, local.month, local.day)`, include the workout if `!localDateUtc.isBefore(cutoffMonday)`, and stop fetching further pages as soon as any workout on the page has `localDateUtc.isBefore(cutoffMonday)`, `workouts.isEmpty`, `page >= pageCount`, or `page >= 15`.

## Phase 1: Core Cleanup, Dependencies & Hevy Key Validators

### Overview

Delete `HeavyEnv` (`lib/core/constants/heavy_env.dart`), remove client-bundled API key instructions from `README.md`, add `http` and `flutter_secure_storage` to `pubspec.yaml`, and implement `HevyApiConstants` and `HevyKeyValidators` with unit tests.

### Changes Required:

#### 1. Remove Legacy `HeavyEnv` & Update `README.md`

**File**: `lib/core/constants/heavy_env.dart` (delete) and `README.md`

**Intent**: Eliminate the compile-time `HEAVY_API_KEY` / `HEAVY_BASE_URL` configuration so the developer's personal Hevy API key is never compiled into binaries or shared with other users, and document the per-user in-app Hevy API key flow in `README.md`.

**Contract**: Delete `lib/core/constants/heavy_env.dart` completely and replace the `Environment Configuration (env.json)` section in `README.md` with a concise `Hevy API Integration` section explaining that each user enters their personal Hevy Pro API key (`https://hevy.com/settings?developer`) inside the app (`Workouts` or `Profile` tab), where it is stored locally in encrypted device storage.

#### 2. Add HTTP & Secure Storage Dependencies

**File**: `pubspec.yaml`

**Intent**: Add `http` for calling the Hevy REST API (`https://api.hevyapp.com`) and `flutter_secure_storage` for storing each user's Hevy API key encrypted on the device.

**Contract**: Under `dependencies:` in `pubspec.yaml`, add `http: ^1.3.0` (or latest compatible `^1.x`) and `flutter_secure_storage: ^9.2.4` (or latest compatible `^9.x`).

#### 3. Hevy API Constants

**File**: `lib/core/constants/hevy_api_constants.dart`

**Intent**: Centralize Hevy Public API URLs, headers, pagination limits, lookback window constants, and key-storage prefix.

**Contract**: `abstract final class HevyApiConstants` defining:
- `static const String baseUrl = 'https://api.hevyapp.com';`
- `static const String workoutsPath = '/v1/workouts';`
- `static const String workoutsCountPath = '/v1/workouts/count';`
- `static const String apiKeyHeader = 'api-key';`
- `static const int pageSize = 10;`
- `static const int maxPages = 15;`
- `static const int lookbackWeeks = 12;`
- `static const String storageKeyPrefix = 'hevy_api_key_';`
- `static String storageKeyForUser(String userId) => '$storageKeyPrefix$userId';`

#### 4. Hevy API Key Validators & Masking Utility

**File**: `lib/core/utils/hevy_key_validators.dart`

**Intent**: Validate candidate Hevy API keys as canonical UUIDs (`8-4-4-4-12` hex format per the Hevy OpenAPI spec) before making a network call, and format saved keys into a masked display string for the `Profile` tab.

**Contract**: `abstract final class HevyKeyValidators` exposing:
- `static String normalizeKey(String rawInput)` — trims whitespace.
- `static bool isValidUuid(String rawInput)` — matches case-insensitive regex `^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$` on trimmed input.
- `static String? validateKeyInput(String rawInput)` — returns `'Hevy API key is required'` when empty, `'Enter a valid Hevy API key (UUID format)'` when `!isValidUuid(rawInput)`, or `null` when valid.
- `static String maskApiKey(String apiKey)` — returns `'••••••••-••••-••••-••••-${trimmed.substring(trimmed.length - 12)}'` for valid 36-char UUIDs (or `'••••••••'` fallback for shorter strings).

#### 5. Unit Tests for Hevy Key Validators

**File**: `test/core/utils/hevy_key_validators_test.dart`

**Intent**: Verify UUID validation, whitespace normalization, error messages, and key masking across valid and invalid inputs.

**Contract**: Unit tests covering empty/whitespace strings, malformed UUIDs, valid uppercase/lowercase UUIDs with surrounding whitespace, and `maskApiKey` output formatting.

### Success Criteria:

#### Automated Verification:

- Legacy `HeavyEnv` file is removed: `test ! -f lib/core/constants/heavy_env.dart`
- Dependencies resolve cleanly: `flutter pub get`
- Hevy key validator unit tests pass: `flutter test test/core/utils/hevy_key_validators_test.dart`
- Static analysis passes with zero warnings: `flutter analyze`
- Code formatting check passes: `dart format --output=none --set-exit-if-changed lib test`

#### Manual Verification:

- Inspect `README.md` and `pubspec.yaml` to confirm no personal API key or `HEAVY_API_KEY` `--dart-define` instructions remain.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Phase 2: Workout Domain & Data Layer (Hevy REST API & Local Key Storage)

### Overview

Build the pure-Dart workout domain models (`WorkoutSetEntity`, `WorkoutExerciseEntity`, `WorkoutEntity`, `WeeklyWorkoutSummaryEntity`) and `WorkoutRepository` contract, followed by the data layer DTOs, `HevyKeyLocalDataSource` (`flutter_secure_storage`), `WorkoutRemoteDataSource` (`package:http`), `WorkoutRepositoryImpl`, `FakeWorkoutRepository`, and comprehensive unit tests.

### Changes Required:

#### 1. Workout Domain Entities & Weekly Grouping Logic

**File**:
- `lib/features/workout/domain/models/workout_set_entity.dart`
- `lib/features/workout/domain/models/workout_exercise_entity.dart`
- `lib/features/workout/domain/models/workout_entity.dart`
- `lib/features/workout/domain/models/weekly_workout_summary_entity.dart`

**Intent**: Represent Hevy workouts, exercises, and sets in pure Dart, filter working sets (`normal`, `failure`, `dropset`; excluding `warmup`), compute volume and per-exercise best sets, and group workouts into ISO Monday–Sunday weeks using each workout's local calendar date.

**Contract**:
- `WorkoutSetEntity`: `index` (`int`), `type` (`String`: `'warmup' | 'normal' | 'failure' | 'dropset'`), `weightKg` (`double?`), `reps` (`int?`), `distanceMeters` (`double?`), `durationSeconds` (`int?`), `rpe` (`double?`). Exposes `bool get isWorkingSet => type != 'warmup'` and `double get volumeKg => (isWorkingSet && weightKg != null && reps != null && weightKg! > 0 && reps! > 0) ? WeekDateUtils.roundToTwoDecimals(weightKg! * reps!) : 0.0`.
- `WorkoutExerciseEntity`: `index` (`int`), `title` (`String`), `exerciseTemplateId` (`String`), `notes` (`String?`), `supersetId` (`int?`), `sets` (`List<WorkoutSetEntity>`). Exposes:
  - `List<WorkoutSetEntity> get workingSets`
  - `int get workingSetsCount`
  - `double get totalVolumeKg` (rounded to 2 decimals)
  - `WorkoutSetEntity? get bestWorkingSet`: selects the working set with the highest `weightKg` (treating `null` as `-1.0`), tie-broken by highest `reps` (treating `null` as `0`); returns `null` if `workingSets` is empty or no working set has `weightKg != null || reps != null`.
- `WorkoutEntity`: `id` (`String`), `title` (`String`), `description` (`String?`), `startTime` (`DateTime`), `endTime` (`DateTime`), `localDate` (`DateTime` normalized UTC `DateTime.utc(local.year, local.month, local.day)`), `localDateIso` (`String` `YYYY-MM-DD`), `exercises` (`List<WorkoutExerciseEntity>`). Exposes `int get workingSetsCount` and `double get totalVolumeKg`.
- `WeeklyWorkoutSummaryEntity`: `weekStartIso` (`String`), `weekStartMonday` (`DateTime`), `weekEndSunday` (`DateTime`), `workouts` (`List<WorkoutEntity>`), `workoutCount` (`int`), `totalWorkingSets` (`int`), `totalVolumeKg` (`double`). Provides `static List<WeeklyWorkoutSummaryEntity> groupWorkoutsByIsoWeek(List<WorkoutEntity> workouts)`:
  - Deduplicates workouts by `id` (keeping the latest `startTime`), groups by `WeekDateUtils.startOfIsoWeekUtc(workout.localDate)`, sorts workouts within each week descending by `startTime` (newest first), sums `totalWorkingSets` and `totalVolumeKg` (rounded via `WeekDateUtils.roundToTwoDecimals`), and returns non-empty weeks sorted descending by `weekStartIso` (newest week first).

#### 2. Workout Repository Interface

**File**: `lib/features/workout/domain/repositories/workout_repository.dart`

**Intent**: Define the domain contract for managing the user's local Hevy API key and fetching the 12-week workout history.

**Contract**:
```dart
abstract class WorkoutRepository {
  Future<Result<String?, AppFailure>> getSavedApiKey({required String userId});
  Future<Result<void, AppFailure>> validateAndSaveApiKey({
    required String userId,
    required String apiKey,
  });
  Future<Result<void, AppFailure>> clearApiKey({required String userId});
  Future<Result<List<WorkoutEntity>, AppFailure>> getWorkoutsForLastWeeks({
    required String userId,
    int weeks = 12,
    DateTime? now,
  });
}
```

#### 3. Workout Data Transfer Objects (`WorkoutDto`)

**File**: `lib/features/workout/data/models/workout_dto.dart`

**Intent**: Parse Hevy `/v1/workouts` JSON payloads (`Workout`, `Exercise`, `Set`) safely into DTOs and map them to domain entities using the local calendar date of `start_time`.

**Contract**: `WorkoutSetDto`, `WorkoutExerciseDto`, `WorkoutDto`, and `PaginatedWorkoutsResponseDto({required int page, required int pageCount, required List<WorkoutDto> workouts})` with `fromJson(Map<String, dynamic>)` and `toEntity()`. In `WorkoutDto.toEntity()`, parse `start_time` and `end_time` via `DateTime.parse(...)`, derive `final localStart = startTime.toLocal()`, and compute `localDate = DateTime.utc(localStart.year, localStart.month, localStart.day)` and `localDateIso = WeekDateUtils.toIsoDateString(localDate)`.

#### 4. Local Data Source for Encrypted Hevy API Key

**File**: `lib/features/workout/data/datasources/hevy_key_local_data_source.dart`

**Intent**: Persist, read, and delete each user's personal Hevy API key in device-local encrypted storage (`FlutterSecureStorage`) keyed by `hevy_api_key_$userId`.

**Contract**: `flutterSecureStorageProvider`, `hevyKeyLocalDataSourceProvider`, and `abstract class HevyKeyLocalDataSource` with `readApiKey({required String userId})`, `writeApiKey({required String userId, required String apiKey})`, and `deleteApiKey({required String userId})`, wrapping storage failures in `CacheException`.

#### 5. Remote Data Source for Hevy Public API

**File**: `lib/features/workout/data/datasources/workout_remote_data_source.dart`

**Intent**: Execute authenticated HTTP requests against `https://api.hevyapp.com/v1/workouts/count` and `https://api.hevyapp.com/v1/workouts` using `package:http`.

**Contract**: `httpClientProvider`, `workoutRemoteDataSourceProvider`, and `abstract class WorkoutRemoteDataSource` with:
- `Future<int> fetchWorkoutCount({required String apiKey})` — sends `GET /v1/workouts/count` with header `api-key: apiKey` and `accept: application/json`; throws `AuthException('invalid-api-key', 'Invalid or unauthorized Hevy API key')` on `401`/`403`, `ServerException` on other non-200 status codes, and `NetworkException` on socket/client transport errors.
- `Future<PaginatedWorkoutsResponseDto> fetchWorkoutsPage({required String apiKey, required int page, int pageSize = HevyApiConstants.pageSize})` — sends `GET /v1/workouts?page=$page&pageSize=$pageSize` with header `api-key: apiKey`.

#### 6. Workout Repository Implementation

**File**: `lib/features/workout/data/repositories/workout_repository_impl.dart`

**Intent**: Coordinate local key lookup/storage, pre-validate candidate keys via `fetchWorkoutCount` before saving, and paginate `fetchWorkoutsPage` up to the 12-ISO-week cutoff (capped at 15 pages).

**Contract**: `workoutRepositoryProvider` and `WorkoutRepositoryImpl`:
```dart
// Key pagination loop in getWorkoutsForLastWeeks:
final referenceLocal = (now ?? DateTime.now()).toLocal();
final todayUtc = DateTime.utc(
  referenceLocal.year,
  referenceLocal.month,
  referenceLocal.day,
);
final currentWeekMonday = WeekDateUtils.startOfIsoWeekUtc(todayUtc);
final cutoffMonday = currentWeekMonday.subtract(
  Duration(days: (weeks - 1) * 7),
);

final List<WorkoutEntity> collected = [];
int currentPage = 1;
while (currentPage <= HevyApiConstants.maxPages) {
  final pageDto = await _remoteDataSource.fetchWorkoutsPage(
    apiKey: apiKey,
    page: currentPage,
    pageSize: HevyApiConstants.pageSize,
  );
  if (pageDto.workouts.isEmpty) break;

  bool reachedCutoff = false;
  for (final dto in pageDto.workouts) {
    final entity = dto.toEntity();
    if (entity.localDate.isBefore(cutoffMonday)) {
      reachedCutoff = true;
    } else {
      collected.add(entity);
    }
  }
  if (reachedCutoff || currentPage >= pageDto.pageCount) break;
  currentPage++;
}
```
If `getSavedApiKey` returns `null`/empty during `getWorkoutsForLastWeeks`, return `Result.failure(const AuthFailure('Hevy API key is not configured'))`. Map `AuthException` to `AuthFailure`, `NetworkException` to `NetworkFailure`, `CacheException` to `CacheFailure`, and `ServerException` to `ServerFailure`.

#### 7. Test Helpers, Mocks, Fake Repository & Unit Tests

**File**:
- `test/test_helpers/mocks.dart`
- `test/test_helpers/fakes/fake_workout_repository.dart`
- `test/test_helpers/fakes/fake_workout_repository_test.dart`
- `test/features/workout/domain/models/weekly_workout_summary_entity_test.dart`
- `test/features/workout/data/models/workout_dto_test.dart`
- `test/features/workout/data/datasources/hevy_key_local_data_source_test.dart`
- `test/features/workout/data/datasources/workout_remote_data_source_test.dart`
- `test/features/workout/data/repositories/workout_repository_impl_test.dart`

**Intent**: Provide reusable mocks and an in-memory `FakeWorkoutRepository` isolated by `userId`, and unit-test all domain calculations, DTO parsing, local storage, HTTP calls, and 12-week pagination/error edge cases.

**Contract**:
- Add `MockHttpClient`, `MockFlutterSecureStorage`, `MockHevyKeyLocalDataSource`, `MockWorkoutRemoteDataSource`, and `MockWorkoutRepository` to `test/test_helpers/mocks.dart`.
- `FakeWorkoutRepository` isolates saved API keys and seeded `List<WorkoutEntity>` per `userId`, supports controllable failures (`getKeyFailure`, `saveKeyFailure`, `clearKeyFailure`, `getWorkoutsFailure`), and filters seeded workouts by the 12-week `cutoffMonday` window.

### Success Criteria:

#### Automated Verification:

- Workout domain entity and weekly grouping unit tests pass: `flutter test test/features/workout/domain/`
- Workout DTO, data sources, repository, and FakeWorkoutRepository unit tests pass: `flutter test test/features/workout/data/ test/test_helpers/fakes/fake_workout_repository_test.dart`
- Static analysis passes with zero warnings: `flutter analyze`
- Code formatting check passes: `dart format --output=none --set-exit-if-changed lib test`

#### Manual Verification:

- Verify `lib/features/workout/domain/` has zero imports from `package:flutter/`, `data/`, `presentation/`, `http`, or `flutter_secure_storage`.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Phase 3: Workout Presentation Layer (ViewModels, Key Setup & Weekly UI)

### Overview

Implement the pure-Dart `WorkoutProgressViewModel` (session-cached across tab switches) and `HevyKeyFormViewModel` (UUID check + `/v1/workouts/count` pre-validation), along with `WorkoutProgressView`, `WeeklyWorkoutCard`, `WorkoutDetailBottomSheet`, `HevyKeyBottomSheet`, and full ViewModel/widget tests.

### Changes Required:

#### 1. Workout Progress State & Session-Cached ViewModel

**File**:
- `lib/features/workout/presentation/view_models/workout_progress_state.dart`
- `lib/features/workout/presentation/view_models/workout_progress_view_model.dart`

**Intent**: Represent all visual states of the workout progress feature and cache loaded 12-week workouts across tab switches during the user's authenticated session while resetting automatically when the user logs out or changes.

**Contract**:
- Sealed `WorkoutProgressState`:
  - `WorkoutProgressInitial` — before initial key check.
  - `WorkoutProgressUnconfigured` — no Hevy API key saved for the current user (`maskedApiKey == null`).
  - `WorkoutProgressLoading({String? maskedApiKey})` — initial load in progress.
  - `WorkoutProgressLoaded({required String maskedApiKey, required List<WorkoutEntity> workouts, required List<WeeklyWorkoutSummaryEntity> weeklySummaries, String? refreshErrorMessage})` — key is configured and 12-week workouts are loaded (with `weeklySummaries` sorted newest week first).
  - `WorkoutProgressError({required String message, String? maskedApiKey})` — initial fetch failed; includes `maskedApiKey` so the `Profile` tab still knows a key is saved and the user can retry or update the key.
- `workoutProgressViewModelProvider = NotifierProvider<WorkoutProgressViewModel, WorkoutProgressState>(WorkoutProgressViewModel.new)`:
  - `build()` watches `authViewModelProvider.select((s) => s.user?.id)` and `workoutRepositoryProvider`, returning `const WorkoutProgressInitial()`.
  - `Future<void> ensureInitialized()` — calls `loadWorkouts()` only when `state is WorkoutProgressInitial`.
  - `Future<void> loadWorkouts({bool showLoading = true})` — reads `getSavedApiKey(userId: user.id)`; if `null`, emits `const WorkoutProgressUnconfigured()`; otherwise masks the key via `HevyKeyValidators.maskApiKey`, fetches `getWorkoutsForLastWeeks(userId: user.id)`, groups via `WeeklyWorkoutSummaryEntity.groupWorkoutsByIsoWeek`, and emits `WorkoutProgressLoaded`. On failure when `!showLoading && state is WorkoutProgressLoaded`, preserves loaded data and sets `refreshErrorMessage: failure.message`; otherwise emits `WorkoutProgressError(message: failure.message, maskedApiKey: maskedKey)`.
  - `Future<bool> disconnectApiKey()` — calls `clearApiKey(userId: user.id)` and transitions state to `const WorkoutProgressUnconfigured()`.
  - `void clearRefreshError()` — clears `refreshErrorMessage` on `WorkoutProgressLoaded`.

#### 2. Hevy API Key Form State & ViewModel

**File**:
- `lib/features/workout/presentation/view_models/hevy_key_form_state.dart`
- `lib/features/workout/presentation/view_models/hevy_key_view_model.dart`

**Intent**: Manage the Hevy API key input form (both inline on the unconfigured `Workouts` tab and inside `HevyKeyBottomSheet`), validating the UUID locally and pre-validating via `WorkoutRepository.validateAndSaveApiKey` before triggering `workoutProgressViewModelProvider.notifier.loadWorkouts()`.

**Contract**:
- `HevyKeyFormState`: `rawKey` (`String`), `status` (`FormStatus`), `validationError` (`String?`), `submitErrorMessage` (`String?`).
- `hevyKeyViewModelProvider = AutoDisposeNotifierProvider<HevyKeyViewModel, HevyKeyFormState>(HevyKeyViewModel.new)` with `updateKey(String value)` and `Future<bool> submitKey()`:
  - Validates via `HevyKeyValidators.validateKeyInput(state.rawKey)`.
  - Calls `workoutRepository.validateAndSaveApiKey(userId: user.id, apiKey: normalizedKey)`.
  - On success, triggers `ref.read(workoutProgressViewModelProvider.notifier).loadWorkouts(showLoading: true)`, sets `FormStatus.success`, and returns `true`.
  - On failure, keeps `rawKey` intact, sets `FormStatus.failure` and `submitErrorMessage: failure.message`, and returns `false`.

#### 3. Weekly Workout Card, Detail Bottom Sheet & Key Setup Modal

**File**:
- `lib/features/workout/presentation/widgets/weekly_workout_card.dart`
- `lib/features/workout/presentation/widgets/workout_detail_bottom_sheet.dart`
- `lib/features/workout/presentation/widgets/hevy_key_bottom_sheet.dart`

**Intent**: Render expandable ISO Monday–Sunday weekly workout cards (`WeeklyWorkoutCard`) matching `WeeklyWeightCard`'s design, a drill-down bottom sheet (`WorkoutDetailBottomSheet`) showing every exercise's working sets (`weight_kg × reps`), warmup tags, and best set, and a reusable bottom sheet (`HevyKeyBottomSheet`) for updating/connecting a Hevy API key.

**Contract**:
- `WeeklyWorkoutCard`: `ExpansionTile` (`Key('workout_week_card_${summary.weekStartIso}')`, `initiallyExpanded: index == 0`) displaying `WeekDateUtils.formatWeekRange(...)`, a workout count badge (`'${summary.workoutCount} ${summary.workoutCount == 1 ? "workout" : "workouts"}'`), subtitle `'${summary.totalWorkingSets} working sets • ${summary.totalVolumeKg.toStringAsFixed(2)} kg volume'`, and children `ListTile` rows (`Key('workout_item_${workout.id}')`) showing the workout title, formatted local date, exercise/working-set summary, and opening `WorkoutDetailBottomSheet.show(context, workout)` on tap.
- `WorkoutDetailBottomSheet`: Displays workout title, date/duration, and a list of exercises (`Key('workout_exercise_${exercise.index}')`), each showing its best working set badge (e.g. `'Best: 100.00 kg × 8'`) and all sets (`Key('workout_set_${exercise.index}_${set.index}')`) with `'Warmup'` vs working set badges (`normal`, `failure`, `dropset`) and formatted `weight_kg × reps` (or reps/duration fallback when `weightKg == null`).
- `HevyKeyBottomSheet`: Modal bottom sheet with `TextField` (`Key('hevy_key_sheet_input_field')`), inline error banner (`Key('hevy_key_sheet_error_banner')`), and `Save & Connect` button (`Key('hevy_key_sheet_save_button')`).

#### 4. Workout Progress View (`Workouts` Tab Body)

**File**: `lib/features/workout/presentation/views/workout_progress_view.dart`

**Intent**: Render the complete `Workouts` tab UI across unconfigured, loading, empty, populated, refresh-error, and initial-error states.

**Contract**: `WorkoutProgressView` (`ConsumerStatefulWidget`):
- Calls `ref.read(workoutProgressViewModelProvider.notifier).ensureInitialized()` in `initState` `addPostFrameCallback`.
- Listens for `WorkoutProgressLoaded.refreshErrorMessage` via `ref.listen` to show `SnackBar` (`Key('workout_progress_refresh_error_snackbar')`) and call `clearRefreshError()`.
- Switches over `WorkoutProgressState`:
  - `WorkoutProgressInitial` / `WorkoutProgressLoading`: `CircularProgressIndicator(key: Key('workout_progress_loading_indicator'))`.
  - `WorkoutProgressUnconfigured`: Renders `Key('workout_unconfigured_state')` with instructions on getting a Hevy Pro API key (`https://hevy.com/settings?developer`), an inline `TextField` (`Key('hevy_key_inline_input_field')`), inline error display, and a `Connect Hevy` button (`Key('hevy_key_inline_connect_button')`).
  - `WorkoutProgressError`: Renders `Key('workout_progress_error_state')` with error message, `Retry` button (`Key('workout_progress_retry_button')`), and an `Update API Key` button (`Key('workout_error_update_key_button')`) opening `HevyKeyBottomSheet`.
  - `WorkoutProgressLoaded`: Wraps content in `RefreshIndicator` calling `loadWorkouts(showLoading: false)`. When `weeklySummaries.isEmpty`, renders `Key('workout_progress_empty_state')` (`'No workouts in the last 12 weeks'`) with a `Refresh Workouts` button (`Key('workout_empty_refresh_button')`). When populated, renders a top summary/sync bar with a manual `Refresh` action (`Key('workout_refresh_button')`) followed by `WeeklyWorkoutCard` items.

#### 5. Presentation Layer Unit & Widget Tests

**File**:
- `test/features/workout/presentation/view_models/workout_progress_view_model_test.dart`
- `test/features/workout/presentation/view_models/hevy_key_view_model_test.dart`
- `test/features/workout/presentation/views/workout_progress_view_test.dart`

**Intent**: Verify all state transitions in `WorkoutProgressViewModel` and `HevyKeyViewModel` headlessly, and widget-test `WorkoutProgressView`, `WeeklyWorkoutCard`, `WorkoutDetailBottomSheet`, and `HevyKeyBottomSheet`.

**Contract**: Tests covering unconfigured state, inline key validation & save, initial load success/error, session caching across `ensureInitialized()` calls, non-destructive pull-to-refresh error `SnackBar`, empty 12-week state, expandable week cards, and exercise/set drill-down sheet rendering.

### Success Criteria:

#### Automated Verification:

- WorkoutProgressViewModel and HevyKeyViewModel unit tests pass: `flutter test test/features/workout/presentation/view_models/`
- WorkoutProgressView, WeeklyWorkoutCard, and bottom sheet widget tests pass: `flutter test test/features/workout/presentation/views/`
- Static analysis passes with zero warnings: `flutter analyze`
- Code formatting check passes: `dart format --output=none --set-exit-if-changed lib test`

#### Manual Verification:

- Verify `WorkoutProgressViewModel` and `HevyKeyViewModel` contain zero `package:flutter/material.dart` imports or `BuildContext` references.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Phase 4: HomeShellScreen 4-Tab Integration & Profile Key Management

### Overview

Integrate `WorkoutProgressView` as the 3rd tab (`index 2`, `Workouts`) in `HomeShellScreen` (`0: Home`, `1: Weights`, `2: Workouts`, `3: Profile`), add a `Go to Workouts` button on `Home` Tab 0, add a Hevy Integration management card to the `Profile` tab (masked key status, update/replace via `HevyKeyBottomSheet`, and disconnect/remove), update roadmap status, and verify with end-to-end widget tests.

### Changes Required:

#### 1. 4-Tab `HomeShellScreen` & `Profile` Hevy Key Management

**File**: `lib/features/auth/presentation/views/home_shell_screen.dart`

**Intent**: Expose the `Workouts` tab in the main navigation bar and allow users to view, update, or disconnect their personal Hevy API key from the `Profile` tab while preserving all existing `S-01` and `S-02` widget test keys.

**Contract**:
- Update `HomeShellScreen`:
  - On `Home` Tab 0 (`_buildHomeTab`), add a `FilledButton.tonalIcon` with `Key('home_go_to_workouts_button')` (`'Go to Workouts'`, sets `_selectedIndex = 2`) below `Key('home_go_to_weights_button')`, keeping all existing `S-01`/`S-02` keys (`home_logout_button`, `home_app_bar_logout_button`, `confirm_logout_button`, `home_go_to_weights_button`) intact.
  - Expand `NavigationBar.destinations` to 4 items:
    - Index `0`: `Key('nav_home_tab')` (`Home`)
    - Index `1`: `Key('nav_weights_tab')` (`Weights` -> `WeightHistoryView`)
    - Index `2`: `Key('nav_workouts_tab')` (`Workouts` -> `WorkoutProgressView`, icon `Icons.fitness_center_outlined` / `Icons.fitness_center`)
    - Index `3`: `Key('nav_profile_tab')` (`Profile` -> `_buildProfileTab`)
  - In `_buildProfileTab`, trigger `ensureInitialized()` on `workoutProgressViewModelProvider.notifier` when the `Profile` tab is first displayed, and render a `Card` (`Key('profile_hevy_card')`) showing:
    - Connection status (`'Not connected'` vs masked key string `Key('profile_hevy_masked_key')`).
    - `Key('profile_connect_or_update_hevy_key_button')` (`'Connect Hevy Key'` or `'Update Key'`) opening `HevyKeyBottomSheet.show(context)`.
    - When a key is saved (`maskedApiKey != null`), a `Disconnect` button (`Key('profile_disconnect_hevy_key_button')`) that calls `ref.read(workoutProgressViewModelProvider.notifier).disconnectApiKey()`.

#### 2. End-to-End Shell & Navigation Widget Tests

**File**: `test/features/auth/presentation/views/home_shell_screen_test.dart`

**Intent**: Verify 4-tab navigation (`Home`, `Weights`, `Workouts`, `Profile`), quick-action navigation from `Home` to `Workouts`, inline Hevy API key connection in `Workouts`, weekly workout card rendering, and updating/disconnecting the Hevy key from `Profile`, while confirming zero regressions in existing `S-01` and `S-02` tests.

**Contract**: Add a `'4-Tab Navigation, Workouts & Profile Hevy Key Integration'` test group to `test/features/auth/presentation/views/home_shell_screen_test.dart` overriding `workoutRepositoryProvider` with `FakeWorkoutRepository`.

### Success Criteria:

#### Automated Verification:

- Updated HomeShellScreen and AppRouter widget tests pass: `flutter test test/features/auth/presentation/views/home_shell_screen_test.dart test/app/router/app_router_test.dart`
- Full test suite passes across all features: `flutter test`
- Static analysis passes with zero warnings: `flutter analyze`
- Code formatting check passes: `dart format --output=none --set-exit-if-changed lib test`

#### Manual Verification:

- Launch the app (`flutter run`), sign in, open the `Workouts` tab (`nav_workouts_tab`), enter a personal Hevy Pro API key, verify pre-validation via `/v1/workouts/count` and automatic import of the last 12 ISO weeks of workouts, expand a week card and tap a workout to inspect its exercises and working sets (`weight_kg × reps`), switch between tabs to confirm the session cache does not re-fetch, pull to refresh, and verify masked key display and disconnect/update in the `Profile` tab.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Testing Strategy

### Unit Tests:

- `hevy_key_validators_test.dart`: UUID format validation, whitespace trimming, validation error messages, and masked key formatting.
- `weekly_workout_summary_entity_test.dart`: Working-set filtering (`warmup` excluded from metrics, `normal`/`failure`/`dropset` included), null `weightKg`/`reps` handling (bodyweight/duration sets), 2-decimal volume rounding, best-set tie-breaking (`weightKg` then `reps`), local-date ISO Monday–Sunday week bucketing, and descending week/workout ordering.
- `workout_dto_test.dart`: Parsing Hevy `/v1/workouts` JSON payloads with nullable set fields (`weight_kg`, `reps`, `rpe`, `distance_meters`, `duration_seconds`) and timezone conversion (`start_time` -> local calendar date).
- `hevy_key_local_data_source_test.dart`: Per-user key isolation (`hevy_api_key_$userId`) and `CacheException` mapping.
- `workout_remote_data_source_test.dart`: `GET /v1/workouts/count` and `GET /v1/workouts?page=X&pageSize=10` headers (`api-key`), HTTP `200` parsing, `401`/`403` -> `AuthException`, `400`/`500` -> `ServerException`, and transport errors -> `NetworkException`.
- `workout_repository_impl_test.dart`: Pre-validation via `fetchWorkoutCount` before writing to local storage, 12-week cutoff stopping condition across multi-page responses, boundary-page workout filtering, 15-page safety cap, and mid-pagination fail-fast error handling.
- `workout_progress_view_model_test.dart` & `hevy_key_view_model_test.dart`: Session cache behavior, user-switch state reset, initial vs refresh error handling, and key save/disconnect flows.

### Integration / Widget Tests:

- `workout_progress_view_test.dart`: Rendering of unconfigured inline form, loading indicator, empty 12-week state, populated expandable `WeeklyWorkoutCard` list, `WorkoutDetailBottomSheet` exercise/set drill-down, non-destructive refresh error `SnackBar`, and error retry.
- `home_shell_screen_test.dart`: 4-tab navigation (`Home`, `Weights`, `Workouts`, `Profile`), `home_go_to_workouts_button`, `Profile` Hevy key management card (connect, update, disconnect), and full backward compatibility with `S-01` and `S-02` widget tests.

### Manual Testing Steps:

1. Run `flutter run` and log in with a private account.
2. Navigate to the `Workouts` tab and verify the `Connect Hevy Account` setup card is shown.
3. Enter an invalid string (non-UUID) and verify immediate local validation feedback; then enter a valid UUID that is not a valid Hevy Pro key and verify the `/v1/workouts/count` pre-validation error banner appears without saving the key.
4. Enter a valid personal Hevy Pro API key and tap `Connect Hevy`. Verify `/v1/workouts/count` succeeds, the key is saved locally, and the last 12 ISO weeks of workouts load into expandable Monday–Sunday week cards.
5. Expand a week card and tap a workout to verify the exercise list, working set counts, volume in kg, warmup tags, and best working set (`weight_kg × reps`).
6. Switch to `Home` and back to `Workouts` to verify workouts remain cached in memory without re-fetching; pull down to refresh to trigger an explicit re-fetch.
7. Open the `Profile` tab (`nav_profile_tab`), verify the masked Hevy API key is displayed, and test updating or disconnecting the key.

## Performance Considerations

- **Bounded pagination**: Stopping pagination as soon as `localDate.isBefore(cutoffMonday)` (with a hard ceiling of `maxPages = 15`, i.e., 150 workouts at `pageSize = 10`) bounds network latency and respects Hevy's rate guidance.
- **Session-level caching**: Holding `WorkoutProgressLoaded` in a user-scoped `NotifierProvider` avoids repeating multi-page HTTP calls on tab switches inside `HomeShellScreen`.

## Migration Notes

- No database migration is needed because workouts are fetched live from the Hevy API and API keys are stored locally per user via `flutter_secure_storage`.
- Delete any local `env.json` file containing a personal `HEAVY_API_KEY` if desired, as `HeavyEnv` is removed from the codebase.

## References

- PRD: `context/foundation/prd.md` (`FR-006`, `FR-008`, `FR-012`, Open Question #2)
- Roadmap: `context/foundation/roadmap.md` (`F-02`, `S-05`)
- Infrastructure & Deploy Plan: `context/foundation/infrastructure.md`, `context/deployment/deploy-plan.md`
- Hevy API OpenAPI Spec: `https://api.hevyapp.com/docs/` (`https://api.hevyapp.com/docs/swagger-ui-init.js`)
- Prior slice plan: `context/changes/dated-weight-history/plan.md`

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands. Do not rename step titles. See `references/progress-format.md`.

### Phase 1: Core Cleanup, Dependencies & Hevy Key Validators

#### Automated

- [x] 1.1 Legacy `HeavyEnv` file is removed: `test ! -f lib/core/constants/heavy_env.dart` — 47d11a9
- [x] 1.2 Dependencies resolve cleanly: `flutter pub get` — 47d11a9
- [x] 1.3 Hevy key validator unit tests pass: `flutter test test/core/utils/hevy_key_validators_test.dart` — 47d11a9
- [x] 1.4 Static analysis passes with zero warnings: `flutter analyze` — 47d11a9
- [x] 1.5 Code formatting check passes: `dart format --output=none --set-exit-if-changed lib test` — 47d11a9

#### Manual

- [x] 1.6 Inspect `README.md` and `pubspec.yaml` to confirm no personal API key or `HEAVY_API_KEY` `--dart-define` instructions remain. — 47d11a9

### Phase 2: Workout Domain & Data Layer (Hevy REST API & Local Key Storage)

#### Automated

- [x] 2.1 Workout domain entity and weekly grouping unit tests pass: `flutter test test/features/workout/domain/` — 784e0f1
- [x] 2.2 Workout DTO, data sources, repository, and FakeWorkoutRepository unit tests pass: `flutter test test/features/workout/data/ test/test_helpers/fakes/fake_workout_repository_test.dart` — 784e0f1
- [x] 2.3 Static analysis passes with zero warnings: `flutter analyze` — 784e0f1
- [x] 2.4 Code formatting check passes: `dart format --output=none --set-exit-if-changed lib test` — 784e0f1

#### Manual

- [x] 2.5 Verify `lib/features/workout/domain/` has zero imports from `package:flutter/`, `data/`, `presentation/`, `http`, or `flutter_secure_storage`. — 784e0f1

### Phase 3: Workout Presentation Layer (ViewModels, Key Setup & Weekly UI)

#### Automated

- [x] 3.1 WorkoutProgressViewModel and HevyKeyViewModel unit tests pass: `flutter test test/features/workout/presentation/view_models/` — bd48fc4
- [x] 3.2 WorkoutProgressView, WeeklyWorkoutCard, and bottom sheet widget tests pass: `flutter test test/features/workout/presentation/views/` — bd48fc4
- [x] 3.3 Static analysis passes with zero warnings: `flutter analyze` — bd48fc4
- [x] 3.4 Code formatting check passes: `dart format --output=none --set-exit-if-changed lib test` — bd48fc4

#### Manual

- [x] 3.5 Verify `WorkoutProgressViewModel` and `HevyKeyViewModel` contain zero `package:flutter/material.dart` imports or `BuildContext` references. — bd48fc4

### Phase 4: HomeShellScreen 4-Tab Integration & Profile Key Management

#### Automated

- [x] 4.1 Updated HomeShellScreen and AppRouter widget tests pass: `flutter test test/features/auth/presentation/views/home_shell_screen_test.dart test/app/router/app_router_test.dart`
- [x] 4.2 Full test suite passes across all features: `flutter test`
- [x] 4.3 Static analysis passes with zero warnings: `flutter analyze`
- [x] 4.4 Code formatting check passes: `dart format --output=none --set-exit-if-changed lib test`

#### Manual

- [x] 4.5 Launch the app (`flutter run`), sign in, open the `Workouts` tab (`nav_workouts_tab`), enter a personal Hevy Pro API key, verify pre-validation via `/v1/workouts/count` and automatic import of the last 12 ISO weeks of workouts, expand a week card and tap a workout to inspect its exercises and working sets (`weight_kg × reps`), switch between tabs to confirm the session cache does not re-fetch, pull to refresh, and verify masked key display and disconnect/update in the `Profile` tab.
