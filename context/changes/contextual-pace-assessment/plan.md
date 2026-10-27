# Contextual Pace Assessment Implementation Plan

## Overview

Implement the Gemini-powered Contextual Pace Assessment (`S-07` in `context/foundation/roadmap.md`) so users see whether their weekly weight-gain pace is **on target** (`prawidłowe`), **too fast** (`za szybko`), **too slow** (`za wolno`), or **stagnant** (`stagnacja`) in the context of at least two prior recorded weight weeks, their saved weekly gain target, and their imported Hevy workout progression (weights, repetitions, and volume). The assessment is displayed in a dedicated card at the top of the Home Dashboard and opens a detailed multi-section AI report in a modal bottom sheet.

## Current State Analysis

The Dashboard currently composes weight history, Hevy workout progress, and the user's weekly gain target into `DashboardState` (`lib/features/dashboard/presentation/view_models/dashboard_view_model.dart:21-127`), rendering a 2×2 KPI grid (`DashboardKpiRow`) and three `fl_chart` cards (`WeeklyWeightTrendCard`, `WeeklyPaceChartCard`, `WeeklyWorkoutsChartCard`) inside `DashboardView` (`lib/features/dashboard/presentation/views/dashboard_view.dart:43-69`).

However, the existing `WeeklyProgressCalculator` (`lib/features/dashboard/domain/calculators/weekly_progress_calculator.dart:112-152`) only computes a numeric `currentPaceKgPerWeek` when at least 2 total weight weeks exist (rather than the assessed week plus at least 2 prior weeks), `CalendarWeekProgressSlotEntity` only retains `workoutCount` without exercise weights/reps (`lib/features/dashboard/domain/models/weekly_progress_overview_entity.dart:10-20`), and there is no 4-status classification, Gemini integration, RTDB assessment cache, or AI report UI.

### Key Discoveries:

- **Firebase AI Logic & App Check are already initialized at startup**: `pubspec.yaml:25-26` declares `firebase_app_check: ^0.3.2+10` and `firebase_ai: ^2.3.0`, and `lib/main.dart:20-25` activates `FirebaseAppCheck.instance` with `AndroidProvider.debug`/`playIntegrity` and `AppleProvider.debug`/`appAttest`, but `firebase_ai` has zero references in `lib/` or `test/`.
- **`GenerativeModel` is a `final class` and `firebase_ai` exports a conflicting `ServerException`**: In `firebase_ai: ^2.3.0` (`src/generative_model.dart:22`, `firebase_ai.dart:51`), `GenerativeModel` cannot be implemented by `mocktail` mocks directly, and `ServerException` collides with `package:bulk_tempo/core/errors/exceptions.dart:9`. Wrapping `GenerativeModel.generateContent` behind an abstract `GeminiContentGenerator` interface and importing `package:firebase_ai/firebase_ai.dart hide ServerException` keeps data source tests clean and mockable.
- **Rich Hevy workout models already exist in memory**: `WorkoutProgressLoaded` (`lib/features/workout/presentation/view_models/workout_progress_state.dart:27-32`) holds `List<WeeklyWorkoutSummaryEntity>` (`lib/features/workout/domain/models/weekly_workout_summary_entity.dart:12-20`), where each workout exposes `List<WorkoutExerciseEntity>` with `workingSetsCount`, `totalVolumeKg`, and `bestWorkingSet` (`weightKg` and `reps`, `lib/features/workout/domain/models/workout_exercise_entity.dart:25-63`).
- **RTDB per-user rules and data source patterns are established**: `database.rules.json:5-20` scopes reads/writes to `users/$uid`, and `GainTargetRemoteDataSourceImpl` (`lib/features/gain_target/data/datasources/gain_target_remote_data_source.dart:25-113`) establishes the timeout, `FirebaseException` mapping, and DTO serialization pattern for single-object user nodes.
- **Modal bottom sheets use `DraggableScrollableSheet`**: `WorkoutDetailBottomSheet` (`lib/features/workout/presentation/widgets/workout_detail_bottom_sheet.dart:11-173`) establishes the modal bottom sheet layout (`showModalBottomSheet` with `isScrollControlled: true`, `useSafeArea: true`, `DraggableScrollableSheet(initialChildSize: 0.75, minChildSize: 0.45, maxChildSize: 0.92)`).

## Desired End State

When a signed-in user opens the Home Dashboard (`DashboardView`):
1. A dedicated `PaceAssessmentCard` renders at the top of the scroll view (above `DashboardKpiRow`).
2. **Eligibility & Sparse-Data States**:
   - If the user has not saved a weekly gain target (`gainTarget == null`), the card displays a clear unconfigured message prompting them to set a weekly gain target in Profile.
   - If Hevy is unconfigured (`WorkoutProgressUnconfigured`) or has 0 workouts across the entire 12-week window, the card displays a clear message prompting them to connect Hevy and import workouts.
   - If the user lacks a recent assessed weight week (current ISO week with `>= 1` entry or immediately preceding ISO week) plus **at least 2 earlier recorded ISO weeks** in the 12-week window, the card displays an insufficient-weight-history message explaining that the assessed week and at least two prior weeks are required.
3. **Hybrid Classification, RTDB Caching & Gemini Analysis**:
   - When eligible, a pure-Dart calculator builds a `PaceAssessmentInputEntity` containing the saved `GainTargetEntity`, the assessed week and prior recorded weeks in the 12-week window (with `averageWeightKg`, `loggedDaysCount`, `isPartialWeek`, and `paceKgPerWeek`), per-week Hevy workout summaries (including `workoutCount`, `totalWorkingSets`, `totalVolumeKg`, and per-exercise `title`, `exerciseTemplateId`, `workingSetsCount`, `totalVolumeKg`, and `bestWorkingSet` `weightKg` × `reps`, treating 0-workout weeks inside the window as rest/deload context), the deterministic baseline status (`pace <= 0.0` → `stagnant`, `0.0 < pace < min` → `tooSlow`, `min <= pace <= max` → `onTarget`, `pace > max` → `tooFast`), the active locale code (`en` or `pl`), and a deterministic `fingerprint` string.
   - `PaceAssessmentViewModel` checks `users/$uid/pace_assessment` in Firebase Realtime Database first; if a cached assessment exists with a matching `fingerprint`, it renders immediately without calling Gemini.
   - If the fingerprint differs (or on manual retry/refresh), `PaceAssessmentRepositoryImpl` calls `gemini-2.5-flash` via `FirebaseAI.googleAI().generativeModel(...)` with `Schema.object` (`responseMimeType: 'application/json'`), allowing Gemini to confirm or contextually adjust borderline baseline statuses using workout progression and produce localized (`en`/`pl`) `headlineSummary`, `weightTrendAnalysis`, `workoutContextAnalysis`, and `actionableTakeaways` (2–3 items), then caches the result at `users/$uid/pace_assessment`.
4. **Detailed AI Report Bottom Sheet**:
   - Tapping "View Full AI Report" on `PaceAssessmentCard` opens `PaceAssessmentReportBottomSheet` (`DraggableScrollableSheet`), displaying the status badge, assessed week range (and partial-week note if `< 7` days logged), baseline vs. final status context, `weightTrendAnalysis`, `workoutContextAnalysis`, and `actionableTakeaways`.

## What We're NOT Doing

- **No custom Firebase Cloud Functions or backend proxy**: All Gemini calls go through client-side `FirebaseAI.googleAI()` protected by `FirebaseAppCheck`.
- **No weight-only AI fallback when Hevy or Gain Target is missing**: Per user decisions, assessment requires all three inputs (eligible weight weeks, saved gain target, and Hevy connected with `>= 1` workout in the 12-week window).
- **No full set-by-set raw workout dump in the Gemini prompt**: Warmup sets and individual set logs are aggregated into weekly totals plus per-exercise working volume and `bestWorkingSet` (`weightKg × reps`).
- **No Markdown parser dependency or new GoRouter sub-routes**: The detailed report uses structured JSON fields rendered in native Flutter cards inside a `DraggableScrollableSheet` modal bottom sheet.
- **No automated diet/calorie macro calculation**: Takeaways focus on interpreting weight pace and training progression against the user's target range.

## Implementation Approach

We follow the repository's strict four-layer Clean Architecture (`Domain` → `Data` → `Presentation ViewModel` → `Presentation UI`):
1. **Domain Layer (`lib/features/dashboard/domain/`)**: Add pure-Dart `@freezed` entities for the assessment status, input context (including weekly exercise summaries), and output report, a pure-Dart `PaceAssessmentCalculator` for eligibility, deterministic baseline status, exercise aggregation, and canonical fingerprinting, plus the `PaceAssessmentRepository` interface.
2. **Data Layer (`lib/features/dashboard/data/` + `database.rules.json`)**: Implement `PaceAssessmentDto` (`@Freezed(toJson: true)`), `PaceAssessmentCacheDataSource` (RTDB `users/$uid/pace_assessment`), `PaceAssessmentAiDataSource` (`FirebaseAI.googleAI()` with `gemini-2.5-flash` and `Schema.object` behind a mockable `GeminiContentGenerator`), and `PaceAssessmentRepositoryImpl` coordinating cache lookup, AI generation, hybrid status validation, and cache persistence.
3. **Presentation State & ViewModel (`lib/features/dashboard/presentation/view_models/`)**: Create `PaceAssessmentState` and `PaceAssessmentViewModel` to manage async evaluation, fingerprint deduplication, account isolation, and manual retry/refresh without putting side effects inside `DashboardViewModel.build()`. Expose the composed assessment state through `DashboardState` and coordinate lifecycle hooks (`ensureInitialized`, `refreshAll`, `retryPaceAssessment`) in `DashboardViewModel`.
4. **Presentation UI & Localization (`lib/features/dashboard/presentation/widgets/`, `lib/l10n/`)**: Add English and Polish ARB translations, build `PaceAssessmentCard` at the top of `DashboardView`, and build `PaceAssessmentReportBottomSheet` for the full AI report.

## Critical Implementation Details

- **`GenerativeModel` mocking & exception name collision**: `GenerativeModel` in `package:firebase_ai/firebase_ai.dart` is a `final class` and cannot be implemented by `Mock` in `mocktail`. Define an abstract `GeminiContentGenerator` interface in `pace_assessment_ai_data_source.dart` whose production implementation calls `FirebaseAI.googleAI().generativeModel(...)`, and mock `GeminiContentGenerator` in unit tests. Always import `package:firebase_ai/firebase_ai.dart hide ServerException;` so `ServerException` resolves to `package:bulk_tempo/core/errors/exceptions.dart`.
- **State sequencing between `DashboardViewModel` and `PaceAssessmentViewModel`**: `DashboardViewModel.build()` is synchronous and must never trigger network requests directly. Instead, `PaceAssessmentViewModel` watches the upstream providers (`authViewModelProvider`, `weightHistoryViewModelProvider`, `workoutProgressViewModelProvider`, `gainTargetViewModelProvider`, `localeProvider`), computes eligibility and `fingerprint`, and schedules an async `evaluateIfNeeded()` via `Future.microtask` only when eligible and the current `fingerprint` differs from the last evaluated/in-flight fingerprint.
- **Strict testing exclusion for `@freezed` models**: Per `context/documentation/06_testing_strategy.md:32-39`, do **not** create standalone unit test files for `@freezed` Entities, DTOs, or UI State classes; test DTO serialization and entity conversion through DataSource, Calculator, Repository, and ViewModel tests.

---

## Phase 1: Domain Models, Eligibility & Hybrid Baseline Calculator

### Overview

Define the pure-Dart domain models, repository contract, and `PaceAssessmentCalculator` that determine assessment eligibility, aggregate weekly Hevy exercise performance (`bestWorkingSet` weight × reps and working volume), compute the deterministic baseline status, and produce a canonical data+locale fingerprint.

### Changes Required:

#### 1. Pace Assessment Domain Entities

**File**: `lib/features/dashboard/domain/models/pace_assessment_entity.dart`

**Intent**: Represent the 4 pace statuses, the structured AI assessment result (with both baseline and final status, headline summary, and 3 report sections), the weekly exercise summary, and the complete evaluation input context in pure Dart.

**Contract**:
- `enum PaceAssessmentStatus { onTarget, tooFast, tooSlow, stagnant }`
- `enum PaceAssessmentIneligibilityReason { unauthenticated, missingGainTarget, workoutUnconfigured, noWorkoutsInWindow, insufficientWeightWeeks }`
- `@freezed abstract class WeeklyExercisePerformanceEntity` with fields: `String exerciseTemplateId`, `String title`, `int workingSetsCount`, `double totalVolumeKg`, `double? bestWeightKg`, `int? bestReps`.
- `@freezed abstract class AssessedWeekContextEntity` with fields: `String weekStartIso`, `DateTime weekStartMonday`, `DateTime weekEndSunday`, `double? averageWeightKg`, `int loggedWeightDaysCount`, `bool isCurrentWeek`, `bool isPartialWeek`, `double? paceKgPerWeek`, `int workoutCount`, `int totalWorkingSets`, `double totalVolumeKg`, `List<WeeklyExercisePerformanceEntity> exercises`.
- `@freezed abstract class PaceAssessmentInputEntity` with fields: `String fingerprint`, `String localeCode`, `GainTargetEntity gainTarget`, `PaceAssessmentStatus baselineStatus`, `double currentPaceKgPerWeek`, `AssessedWeekContextEntity assessedWeek`, `List<AssessedWeekContextEntity> priorWeeks`.
- `@freezed abstract class PaceAssessmentEntity` with fields: `PaceAssessmentStatus status`, `PaceAssessmentStatus baselineStatus`, `String headlineSummary`, `String weightTrendAnalysis`, `String workoutContextAnalysis`, `List<String> actionableTakeaways`, `String assessedWeekStartIso`, `bool isAssessedWeekPartial`, `double currentPaceKgPerWeek`, `double targetMinKgPerWeek`, `double targetMaxKgPerWeek`, `int priorWeightWeeksCount`, `String localeCode`, `String fingerprint`, `DateTime generatedAt`.

#### 2. Eligibility, Exercise Aggregation & Hybrid Baseline Calculator

**File**: `lib/features/dashboard/domain/calculators/pace_assessment_calculator.dart`

**Intent**: Deterministically evaluate whether the user's current weight, workout, and target data qualify for assessment, compute the baseline status from `currentPaceKgPerWeek` and `GainTargetEntity`, aggregate weekly Hevy exercises, and compute a deterministic fingerprint string.

**Contract**:
- `sealed class PaceAssessmentEligibilityResult` with `PaceAssessmentEligible(PaceAssessmentInputEntity input)` and `PaceAssessmentIneligible(PaceAssessmentIneligibilityReason reason, {int recordedWeightWeeksCount, int priorWeightWeeksCount})`.
- `abstract final class PaceAssessmentCalculator`:
  - `static PaceAssessmentStatus computeBaselineStatus({required double paceKgPerWeek, required GainTargetEntity target})`:
    - `paceKgPerWeek <= 0.0` → `PaceAssessmentStatus.stagnant`
    - `paceKgPerWeek > 0.0 && paceKgPerWeek < target.minWeeklyGainKg` → `PaceAssessmentStatus.tooSlow`
    - `paceKgPerWeek >= target.minWeeklyGainKg && paceKgPerWeek <= target.maxWeeklyGainKg` → `PaceAssessmentStatus.onTarget`
    - `paceKgPerWeek > target.maxWeeklyGainKg` → `PaceAssessmentStatus.tooFast`
  - `static PaceAssessmentEligibilityResult evaluateEligibility({required List<WeeklyWeightSummaryEntity> weightSummaries, required List<WeeklyWorkoutSummaryEntity> workoutSummaries, required bool isWorkoutConfigured, required GainTargetEntity? gainTarget, required String localeCode, required DateTime now})`:
    - Checks in order:
      1. `gainTarget == null || !gainTarget.isValid` → `missingGainTarget`
      2. `!isWorkoutConfigured` → `workoutUnconfigured`
      3. No workouts in the 12-week window (`workoutSummaries` in window has total `workoutCount == 0`) → `noWorkoutsInWindow`
      4. Weight eligibility in the 12-ISO-week window ending at `WeekDateUtils.startOfIsoWeekUtc(now)`: the latest recorded weight week in the window must be the current ISO week (`>= 1` entry; marked `isPartialWeek = loggedDaysCount < 7`) or the immediately preceding ISO week, AND there must be **at least 2 earlier recorded ISO weeks** in the 12-week window before the assessed week (`priorWeightWeeksCount >= 2`). Otherwise → `insufficientWeightWeeks`.
    - Aggregates per-week Hevy workouts into `List<WeeklyExercisePerformanceEntity>` (grouped by `exerciseTemplateId` or normalized `title`, summing `workingSetsCount` and `totalVolumeKg`, and selecting the best working set across the week by highest `weightKg` tie-broken by highest `reps`).
    - Computes a deterministic `fingerprint` string from canonicalized `(localeCode, gainTarget.minWeeklyGainKg, gainTarget.maxWeeklyGainKg, evaluated week weight averages/loggedDays, weekly workout counts/sets/volumes/best sets)`.

#### 3. Pace Assessment Repository Contract

**File**: `lib/features/dashboard/domain/repositories/pace_assessment_repository.dart`

**Intent**: Define the domain boundary for obtaining or refreshing a contextual pace assessment.

**Contract**:
- `abstract class PaceAssessmentRepository`:
  - `Future<Result<PaceAssessmentEntity, AppFailure>> getOrGenerateAssessment({required String userId, required PaceAssessmentInputEntity input, bool forceRefresh = false});`

#### 4. Calculator Unit Tests

**File**: `test/features/dashboard/domain/calculators/pace_assessment_calculator_test.dart`

**Intent**: Verify all eligibility rules, baseline status boundaries, weekly exercise best-set/volume aggregation, rest-week handling, and deterministic fingerprint changes.

**Contract**:
- Tests covering: `missingGainTarget`, `workoutUnconfigured`, `noWorkoutsInWindow`, fewer than 2 prior recorded weight weeks (`insufficientWeightWeeks`), stale latest weight week (>1 week old), eligible current partial week (`loggedDaysCount < 7`) + 2 non-adjacent prior weight weeks + 0-workout rest week in window, all 4 `computeBaselineStatus` boundaries (`<= 0`, `< min`, `min..max`, `> max`), per-exercise `bestWorkingSet` tie-breaking across multiple workouts in the same week, and fingerprint stability vs. sensitivity to weight, workout, target, and locale changes.

### Success Criteria:

#### Automated Verification:

- Code generation succeeds: `dart run build_runner build --delete-conflicting-outputs`
- Calculator unit tests pass: `flutter test test/features/dashboard/domain/calculators/pace_assessment_calculator_test.dart`
- Static analysis passes with zero warnings: `flutter analyze`

#### Manual Verification:

- Confirm domain files under `lib/features/dashboard/domain/` have zero imports from `data/`, `presentation/`, `package:flutter/*`, or `package:firebase_ai/*`.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Phase 2: Firebase AI Logic, RTDB Cache Data Sources & Repository

### Overview

Implement the data layer: `PaceAssessmentDto` for JSON serialization, `PaceAssessmentCacheDataSource` for reading/writing `users/$uid/pace_assessment` in Firebase Realtime Database (with `database.rules.json` validation), `PaceAssessmentAiDataSource` calling `gemini-2.5-flash` via `FirebaseAI.googleAI()` with a structured `Schema.object`, and `PaceAssessmentRepositoryImpl` orchestrating cache hits, AI generation, hybrid status reconciliation, and error mapping.

### Changes Required:

#### 1. Realtime Database Security Rules

**File**: `database.rules.json`

**Intent**: Add schema validation for `users/$uid/pace_assessment` so cached assessments stored per user are validated on write while preserving per-user read/write isolation.

**Contract**:
- Under `users/$uid`, add `"pace_assessment"` validation rule requiring `status`, `baselineStatus`, `headlineSummary`, `weightTrendAnalysis`, `workoutContextAnalysis`, `actionableTakeaways`, `assessedWeekStartIso`, `isAssessedWeekPartial`, `currentPaceKgPerWeek`, `targetMinKgPerWeek`, `targetMaxKgPerWeek`, `priorWeightWeeksCount`, `localeCode`, `fingerprint`, and `generatedAt` with appropriate string/number/boolean checks and `$other: { ".validate": false }`.

#### 2. Pace Assessment DTO

**File**: `lib/features/dashboard/data/models/pace_assessment_dto.dart`

**Intent**: Serialize and deserialize `PaceAssessmentEntity` to/from Firebase Realtime Database maps and validate Gemini's structured JSON response fields.

**Contract**:
- `@Freezed(toJson: true) abstract class PaceAssessmentDto with _$PaceAssessmentDto`
- `factory PaceAssessmentDto.fromRtdbMap(Map<Object?, Object?> map)` (validates required fields, non-empty strings, valid `PaceAssessmentStatus` enum names, and `List<String>` takeaways; throws `FormatException` if malformed).
- `factory PaceAssessmentDto.fromEntity(PaceAssessmentEntity entity)` and `PaceAssessmentEntity toEntity()`.

#### 3. RTDB Cache Data Source

**File**: `lib/features/dashboard/data/datasources/pace_assessment_cache_data_source.dart`

**Intent**: Read and write the user's cached `PaceAssessmentDto` at `users/$userId/pace_assessment` in Firebase Realtime Database following `GainTargetRemoteDataSourceImpl` conventions.

**Contract**:
- `final paceAssessmentCacheDataSourceProvider = Provider<PaceAssessmentCacheDataSource>(...)`
- `abstract class PaceAssessmentCacheDataSource`:
  - `Future<PaceAssessmentDto?> getCachedAssessment({required String userId});`
  - `Future<void> saveCachedAssessment({required String userId, required PaceAssessmentDto dto});`
- `PaceAssessmentCacheDataSourceImpl(FirebaseDatabase _database)` using `.ref('users/$userId/pace_assessment')` with 15-second timeout and standard `FirebaseException` → `AuthException`/`NetworkException`/`ServerException` mapping (and returning `null` if cached data is missing or malformed so a fresh Gemini call can heal the cache).

#### 4. Firebase AI Logic Data Source & Mockable Generator

**File**: `lib/features/dashboard/data/datasources/pace_assessment_ai_data_source.dart`

**Intent**: Build the structured prompt and `Schema.object` for `gemini-2.5-flash` via `FirebaseAI.googleAI()`, execute content generation through a mockable `GeminiContentGenerator` adapter, and parse the JSON response.

**Contract**:
- `abstract class GeminiContentGenerator { Future<String?> generateJson({required String prompt, required Schema responseSchema, String? systemInstruction}); }`
- `class FirebaseAiContentGenerator implements GeminiContentGenerator` using `FirebaseAI.googleAI(auth: FirebaseAuth.instance, appCheck: FirebaseAppCheck.instance).generativeModel(model: 'gemini-2.5-flash', generationConfig: GenerationConfig(responseMimeType: 'application/json', responseSchema: responseSchema), systemInstruction: systemInstruction != null ? Content.system(systemInstruction) : null)`.
- `abstract class PaceAssessmentAiDataSource`:
  - `Future<PaceAssessmentDto> generateAssessment({required PaceAssessmentInputEntity input, required DateTime now});`
- Prompt & Schema rules in `PaceAssessmentAiDataSourceImpl`:
  - `Schema.object` requiring:
    - `status`: `Schema.enumString(enumValues: ['onTarget', 'tooFast', 'tooSlow', 'stagnant'])`
    - `headlineSummary`: `Schema.string()`
    - `weightTrendAnalysis`: `Schema.string()`
    - `workoutContextAnalysis`: `Schema.string()`
    - `actionableTakeaways`: `Schema.array(items: Schema.string(), minItems: 2, maxItems: 4)`
  - Prompt passes the user's `localeCode` (`en` → English, `pl` → Polish), `gainTarget` range, `baselineStatus`, `assessedWeek` (noting `isPartialWeek` and `loggedWeightDaysCount`), `priorWeeks` weight averages/paces, and weekly Hevy exercise summaries (`workoutCount`, `totalWorkingSets`, `totalVolumeKg`, and per-exercise `bestWeightKg × bestReps` + `totalVolumeKg`, noting 0-workout weeks as rest/deload weeks).
  - Hybrid status guardrail: instructs Gemini to start from `baselineStatus` and only adjust borderline cases when multi-week trend and workout progression strongly justify it (e.g., distinguishing `stagnant` vs `tooSlow` based on whether strength/volume is progressing or stalled); in Dart parsing, if the returned status string is unknown, fallback to `input.baselineStatus`.

#### 5. Pace Assessment Repository Implementation

**File**: `lib/features/dashboard/data/repositories/pace_assessment_repository_impl.dart`

**Intent**: Coordinate RTDB cache lookup by `fingerprint`, invoke `PaceAssessmentAiDataSource` on cache miss or `forceRefresh`, persist the new assessment to RTDB (treating cache-write failures as non-fatal if AI generation succeeded), and return `Result<PaceAssessmentEntity, AppFailure>`.

**Contract**:
- `final paceAssessmentRepositoryProvider = Provider<PaceAssessmentRepository>(...)`
- `class PaceAssessmentRepositoryImpl implements PaceAssessmentRepository`

#### 6. Data Layer Mocks & Unit Tests

**Files**:
- `test/test_helpers/mocks.dart`
- `test/features/dashboard/data/datasources/pace_assessment_cache_data_source_test.dart`
- `test/features/dashboard/data/datasources/pace_assessment_ai_data_source_test.dart`
- `test/features/dashboard/data/repositories/pace_assessment_repository_impl_test.dart`

**Intent**: Register `MockGeminiContentGenerator`, `MockPaceAssessmentCacheDataSource`, `MockPaceAssessmentAiDataSource`, and `MockPaceAssessmentRepository` in `test/test_helpers/mocks.dart` and unit-test RTDB cache reads/writes, prompt/schema generation and JSON parsing, hybrid status fallback, and repository cache hit/miss/forceRefresh/error flows.

**Contract**:
- 100% unit test coverage of cache hit (matching fingerprint skips AI call), cache miss (mismatched fingerprint calls AI and writes cache), `forceRefresh: true` (bypasses cache read), malformed AI JSON handling, and network/auth/server failure mapping.

### Success Criteria:

#### Automated Verification:

- Code generation succeeds: `dart run build_runner build --delete-conflicting-outputs`
- Data source and repository unit tests pass: `flutter test test/features/dashboard/data/`
- Static analysis passes: `flutter analyze`

#### Manual Verification:

- Verify `database.rules.json` is valid JSON and `pace_assessment` rules sit cleanly under `users/$uid` alongside `weight_entries` and `gain_target`.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Phase 3: Pace Assessment State Management & Dashboard ViewModel Integration

### Overview

Create `PaceAssessmentState` and `PaceAssessmentViewModel` to manage eligibility transitions, fingerprint-deduplicated automatic evaluation, pull-to-refresh, manual retry, and user session isolation, and expose the state through `DashboardState` and `DashboardViewModel`.

### Changes Required:

#### 1. Pace Assessment State

**File**: `lib/features/dashboard/presentation/view_models/pace_assessment_state.dart`

**Intent**: Represent all presentation states of the pace assessment card and report without UI imports.

**Contract**:
- `enum PaceAssessmentViewStatus { loading, ineligible, error, loaded }`
- `@freezed abstract class PaceAssessmentState with _$PaceAssessmentState` with fields:
  - `@Default(PaceAssessmentViewStatus.loading) PaceAssessmentViewStatus status`
  - `PaceAssessmentEntity? assessment`
  - `PaceAssessmentIneligibilityReason? ineligibilityReason`
  - `@Default(0) int recordedWeightWeeksCount`
  - `@Default(0) int priorWeightWeeksCount`
  - `@Default(false) bool isRefreshing`
  - `@Default(false) bool isOutdated`
  - `String? errorMessage`
  - `String? refreshErrorMessage`
  - `String? lastEvaluatedFingerprint`

#### 2. Pace Assessment ViewModel

**File**: `lib/features/dashboard/presentation/view_models/pace_assessment_view_model.dart`

**Intent**: Watch upstream weight, workout, gain target, auth, clock, and locale providers, compute `PaceAssessmentCalculator.evaluateEligibility`, and automatically fetch/generate the assessment when eligible and the fingerprint changes.

**Contract**:
- `final paceAssessmentViewModelProvider = AutoDisposeNotifierProvider<PaceAssessmentViewModel, PaceAssessmentState>(PaceAssessmentViewModel.new);`
- Behavior in `PaceAssessmentViewModel`:
  - Watches `authViewModelProvider.select((s) => s.user?.id)`, `weightHistoryViewModelProvider`, `workoutProgressViewModelProvider`, `gainTargetViewModelProvider`, `localeProvider`, and `clockProvider`.
  - While any upstream dependency is still in its initial loading state (and no prior assessment is loaded), emits `PaceAssessmentViewStatus.loading`.
  - If an upstream dependency is in an error state (e.g., weight history failed to load, gain target failed to load, or workout progress failed to load) and no assessment is loaded, emits `PaceAssessmentViewStatus.error` with the upstream error message.
  - Runs `PaceAssessmentCalculator.evaluateEligibility(...)`. If `PaceAssessmentIneligible`, emits `PaceAssessmentViewStatus.ineligible` with `ineligibilityReason`, `recordedWeightWeeksCount`, and `priorWeightWeeksCount`.
  - If `PaceAssessmentEligible(input)`:
    - If `state.assessment?.fingerprint == input.fingerprint`, emits `PaceAssessmentViewStatus.loaded` immediately.
    - Otherwise schedules `_evaluate(input)` via `Future.microtask` (guarded by generation counter, user ID check, and `_inFlightFingerprint` deduplication so rapid rebuilds never fire duplicate requests).
  - Exposes `Future<void> refresh({bool forceRefresh = false})` and `Future<void> retry()` for pull-to-refresh and error recovery. If a refresh fails while a previous `assessment` is already displayed, keeps `status: loaded`, sets `isOutdated: true`, and populates `refreshErrorMessage`.

#### 3. Dashboard State & ViewModel Integration

**Files**:
- `lib/features/dashboard/presentation/view_models/dashboard_state.dart`
- `lib/features/dashboard/presentation/view_models/dashboard_view_model.dart`

**Intent**: Expose `PaceAssessmentState` on `DashboardState` and coordinate refresh/retry methods on `DashboardViewModel`.

**Contract**:
- Add `@Default(PaceAssessmentState()) PaceAssessmentState paceAssessment` to `DashboardState`.
- In `DashboardViewModel.build()`, watch `paceAssessmentViewModelProvider` and pass it into `DashboardState`.
- In `DashboardViewModel.refreshAll()`, after refreshing weights, workouts, and gain target, call `ref.read(paceAssessmentViewModelProvider.notifier).refresh()`.
- Add `Future<void> retryPaceAssessment()` on `DashboardViewModel` which retries any failed upstream data sources and triggers `ref.read(paceAssessmentViewModelProvider.notifier).retry()`.

#### 4. ViewModel Unit Tests

**Files**:
- `test/features/dashboard/presentation/view_models/pace_assessment_view_model_test.dart`
- `test/features/dashboard/presentation/view_models/dashboard_view_model_test.dart`

**Intent**: Verify automatic assessment when eligible, fingerprint deduplication, locale switch re-evaluation, ineligibility states (`missingGainTarget`, `workoutUnconfigured`, `noWorkoutsInWindow`, `insufficientWeightWeeks`), error/outdated handling, account switch isolation, and `DashboardViewModel` coordination.

**Contract**:
- Headless `ProviderContainer` tests covering all state transitions and race/disposal guards.

### Success Criteria:

#### Automated Verification:

- Code generation succeeds: `dart run build_runner build --delete-conflicting-outputs`
- ViewModel unit tests pass: `flutter test test/features/dashboard/presentation/view_models/`
- Static analysis passes: `flutter analyze`

#### Manual Verification:

- Confirm neither `pace_assessment_view_model.dart` nor `pace_assessment_state.dart` imports `package:flutter/material.dart` or `dart:ui`.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Phase 4: Dashboard Assessment Card, Detailed Report Bottom Sheet & Localization

### Overview

Add English and Polish localization strings, build `PaceAssessmentCard` at the top of `DashboardView` (above `DashboardKpiRow`), build `PaceAssessmentReportBottomSheet` (`DraggableScrollableSheet`) to display the full AI report, and add comprehensive widget tests.

### Changes Required:

#### 1. English & Polish Localization Keys

**Files**:
- `lib/l10n/app_en.arb`
- `lib/l10n/app_pl.arb`

**Intent**: Provide localized strings in English and Polish for the 4 pace statuses (`onTarget` / "On target" / "Tempo prawidłowe", `tooFast` / "Too fast" / "Tempo za szybkie", `tooSlow` / "Too slow" / "Tempo za wolne", `stagnant` / "Stagnation" / "Stagnacja"), card titles, sparse-data/ineligibility messages, partial-week note, and detailed report section headers.

**Contract**:
- Add ARB keys:
  - `dashboardAssessmentCardTitle` ("AI Pace Assessment" / "Ocena tempa AI")
  - `paceStatusOnTarget` ("On target" / "Tempo prawidłowe")
  - `paceStatusTooFast` ("Too fast" / "Tempo za szybkie")
  - `paceStatusTooSlow` ("Too slow" / "Tempo za wolne")
  - `paceStatusStagnant` ("Stagnation" / "Stagnacja")
  - `paceAssessmentMissingTarget` ("Set your weekly gain target in Profile to unlock AI pace assessment." / "Ustaw docelowy zakres przyrostu w Profilu, aby odblokować ocenę tempa AI.")
  - `paceAssessmentMissingHevy` ("Connect your Hevy API key in Profile to include workout context in your pace assessment." / "Połącz klucz API Hevy w Profilu, aby uwzględnić treningi w ocenie tempa.")
  - `paceAssessmentNoWorkouts` ("Log or import at least one workout in the last 12 weeks to assess your pace in training context." / "Zapisz lub zaimportuj co najmniej jeden trening z ostatnich 12 tygodni, aby ocenić tempo w kontekście treningowym.")
  - `paceAssessmentInsufficientWeights` ("Log weight entries in the current (or previous) week and at least 2 earlier weeks (`{priorWeeks}/2` prior weeks logged) to unlock pace assessment." / "Zapisz pomiary wagi w bieżącym (lub poprzednim) tygodniu oraz w co najmniej 2 wcześniejszych tygodniach (zapisano `{priorWeeks}/2` wcześniejszych tygodni), aby odblokować ocenę tempa.")
  - `paceAssessmentPartialWeekBadge` ("Partial week ({loggedDays}/7 days)" / "Niepełny tydzień ({loggedDays}/7 dni)")
  - `paceAssessmentViewReportButton` ("View Full AI Report" / "Zobacz pełny raport AI")
  - `paceAssessmentRefreshTooltip` ("Refresh AI assessment" / "Odśwież ocenę AI")
  - `paceReportTitle` ("AI Pace Assessment Report" / "Raport oceny tempa AI")
  - `paceReportWeightTrendSection` ("Weight Trend vs. Target" / "Trend masy względem celu")
  - `paceReportWorkoutContextSection` ("Workout & Strength Context" / "Kontekst treningowy i siłowy")
  - `paceReportTakeawaysSection` ("Actionable Takeaways" / "Wskazówki na kolejny tydzień")
  - `paceReportBaselineLabel` ("Baseline pace status: {status}" / "Bazowy status z wagi: {status}")

#### 2. Pace Assessment Card Widget

**File**: `lib/features/dashboard/presentation/widgets/pace_assessment_card.dart`

**Intent**: Render the top-of-Dashboard card displaying the loading spinner, ineligibility guidance, error with retry button, or loaded status badge + `headlineSummary` + partial-week indicator + "View Full AI Report" button.

**Contract**:
- `class PaceAssessmentCard extends StatelessWidget` with `final DashboardState state`, `final VoidCallback onRetry`, `final VoidCallback onRefresh`, `final VoidCallback onOpenReport`.
- Uses semantic keys for widget tests:
  - `Key('dashboard_pace_assessment_card')`
  - `Key('pace_assessment_status_badge')`
  - `Key('pace_assessment_partial_week_badge')`
  - `Key('pace_assessment_headline_text')`
  - `Key('pace_assessment_view_report_button')`
  - `Key('pace_assessment_refresh_button')`
  - `Key('pace_assessment_retry_button')`
  - `Key('pace_assessment_ineligible_text')`
  - `Key('pace_assessment_outdated_badge')`

#### 3. Detailed AI Report Modal Bottom Sheet

**File**: `lib/features/dashboard/presentation/widgets/pace_assessment_report_bottom_sheet.dart`

**Intent**: Display the full multi-section AI report inside a `DraggableScrollableSheet` modal bottom sheet matching `WorkoutDetailBottomSheet`.

**Contract**:
- `class PaceAssessmentReportBottomSheet extends StatelessWidget` with `static Future<void> show(BuildContext context, PaceAssessmentEntity assessment)`.
- Renders:
  - Header with title (`context.l10n.paceReportTitle`), evaluated week range, partial-week badge (if `isAssessedWeekPartial`), status pill badge, baseline comparison note (if `status != baselineStatus`), and close button (`Key('pace_report_close_button')`).
  - Scrollable content with three distinct cards/sections:
    - `Key('pace_report_weight_section')`: `weightTrendAnalysis`
    - `Key('pace_report_workout_section')`: `workoutContextAnalysis`
    - `Key('pace_report_takeaways_section')`: bulleted list of `actionableTakeaways`

#### 4. Wire into `DashboardView`

**File**: `lib/features/dashboard/presentation/views/dashboard_view.dart`

**Intent**: Place `PaceAssessmentCard` as the first child of the `ListView` (above `DashboardKpiRow`) and wire its retry, refresh, and open-report callbacks.

**Contract**:
- `ListView` children order in `DashboardView`:
  1. `PaceAssessmentCard(...)`
  2. `DashboardKpiRow(state: state)`
  3. `WeeklyWeightTrendCard(...)`
  4. `WeeklyPaceChartCard(...)`
  5. `WeeklyWorkoutsChartCard(...)`

#### 5. Widget Tests

**Files**:
- `test/features/dashboard/presentation/widgets/pace_assessment_card_test.dart`
- `test/features/dashboard/presentation/widgets/pace_assessment_report_bottom_sheet_test.dart`
- `test/features/dashboard/presentation/views/dashboard_view_test.dart`

**Intent**: Verify rendering of all 4 pace statuses in EN and PL, all ineligibility messages (`missingGainTarget`, `workoutUnconfigured`, `noWorkoutsInWindow`, `insufficientWeightWeeks`), loading/error/outdated states, and opening/closing `PaceAssessmentReportBottomSheet` from `DashboardView`.

**Contract**:
- Widget tests using `WidgetTester` verifying keys, localized text, retry/refresh actions, and bottom sheet modal presentation.

### Success Criteria:

#### Automated Verification:

- Localization generation and code formatting succeed: `flutter gen-l10n && dart format --output=none --set-exit-if-changed lib test`
- All unit and widget tests pass: `flutter test`
- Static analysis passes with zero issues: `flutter analyze`

#### Manual Verification:

- Launch the app (`flutter run`), navigate to the Home tab, and verify `PaceAssessmentCard` appears at the top of the Dashboard above `DashboardKpiRow`.
- Verify that missing target, disconnected Hevy, or `< 2` prior weight weeks show clear, non-misleading setup/empty messages.
- With valid weight history (`>= 2` prior weeks + current/previous week), connected Hevy workouts, and a saved gain target, verify the AI status badge and headline summary load on the Dashboard, and tapping "View Full AI Report" opens the modal bottom sheet with Weight Trend, Workout Context, and Actionable Takeaways in both English and Polish.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Testing Strategy

### Unit Tests:

- `test/features/dashboard/domain/calculators/pace_assessment_calculator_test.dart`:
  - Eligibility checks for `missingGainTarget`, `workoutUnconfigured`, `noWorkoutsInWindow`, and `insufficientWeightWeeks` (0, 1, and 2 total weeks vs. assessed week + 2 prior weeks).
  - Partial current week detection (`loggedDaysCount` 1..6 vs 7) and non-adjacent prior weeks within the 12-week window.
  - Deterministic baseline classification (`stagnant` for `<= 0.0`, `tooSlow` for `0.0 < pace < min`, `onTarget` for `min..max`, `tooFast` for `> max`).
  - Weekly Hevy exercise aggregation (`workingSetsCount`, `totalVolumeKg`, `bestWorkingSet` weight × reps tie-breaking) and 0-workout rest weeks inside the window.
  - Fingerprint determinism and sensitivity to weight, workout, target, and locale changes.
- `test/features/dashboard/data/datasources/pace_assessment_cache_data_source_test.dart`:
  - RTDB `users/$uid/pace_assessment` read/write, malformed cache recovery (`null`), and `FirebaseException` mapping.
- `test/features/dashboard/data/datasources/pace_assessment_ai_data_source_test.dart`:
  - Prompt construction (EN/PL locale, baseline status, partial week flag, exercise best sets), `Schema.object` structure, valid JSON parsing, and hybrid fallback to `baselineStatus` if model output is unexpected.
- `test/features/dashboard/data/repositories/pace_assessment_repository_impl_test.dart`:
  - RTDB fingerprint match (cache hit without calling AI), fingerprint mismatch (calls AI and saves to RTDB), `forceRefresh: true`, and failure propagation.
- `test/features/dashboard/presentation/view_models/pace_assessment_view_model_test.dart`:
  - Auto-evaluation when eligible, deduplication of identical fingerprints, re-evaluation on weight/workout/target/locale change, outdated badge on refresh failure, and user account switch reset.

### Integration Tests:

- Covered via `test/features/dashboard/presentation/views/dashboard_view_test.dart` composing `DashboardViewModel` and `PaceAssessmentViewModel` with mocked repositories to verify end-to-end UI state transitions from loading → ineligible → loaded → modal bottom sheet report.

### Manual Testing Steps:

1. Sign in with an account that has no gain target set; confirm `PaceAssessmentCard` prompts to set a gain target in Profile.
2. Save a gain target (e.g., `0.15–0.25 kg/week`) with Hevy disconnected; confirm `PaceAssessmentCard` prompts to connect Hevy.
3. Connect Hevy and ensure weight entries exist for the current (or previous) week and at least 2 prior weeks; confirm `PaceAssessmentCard` displays the status badge (`On target`, `Too fast`, `Too slow`, or `Stagnation`) and headline summary.
4. Tap "View Full AI Report" and inspect the modal bottom sheet sections; pull to refresh or switch language between English and Polish in Profile and verify the report updates to match the selected language.

## Performance Considerations

- **Fingerprint-Gated Caching in RTDB**: Computing a fast synchronous fingerprint in `PaceAssessmentCalculator` and checking `users/$uid/pace_assessment` prevents redundant `gemini-2.5-flash` calls across widget rebuilds, tab switches, and app restarts when underlying data and locale have not changed.
- **Compact Workout Payload**: Aggregating Hevy workouts by week and exercise (`bestWorkingSet` weight × reps + total working volume) bounds prompt size to a few kilobytes even for users logging 5–6 workouts per week over 12 weeks.

## Migration Notes

- No destructive schema migrations are needed. `users/$uid/pace_assessment` is an additive child node in Firebase Realtime Database validated by `database.rules.json`. If an older or malformed cache entry is encountered, `PaceAssessmentCacheDataSourceImpl` safely returns `null` so a fresh assessment is generated and written.

## References

- Related research: `context/changes/contextual-pace-assessment/research.md`
- Product requirements: `context/foundation/prd.md:30-60,73-100`
- Roadmap item (`S-07`): `context/foundation/roadmap.md:52,171-183`
- Existing Dashboard calculator & ViewModel: `lib/features/dashboard/domain/calculators/weekly_progress_calculator.dart:1-154`, `lib/features/dashboard/presentation/view_models/dashboard_view_model.dart:1-179`
- Similar RTDB data source: `lib/features/gain_target/data/datasources/gain_target_remote_data_source.dart:1-113`
- Similar modal bottom sheet: `lib/features/workout/presentation/widgets/workout_detail_bottom_sheet.dart:1-174`

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands. Do not rename step titles. See `references/progress-format.md`.

### Phase 1: Domain Models, Eligibility & Hybrid Baseline Calculator

#### Automated

- [x] 1.1 Code generation succeeds: `dart run build_runner build --delete-conflicting-outputs`
- [x] 1.2 Calculator unit tests pass: `flutter test test/features/dashboard/domain/calculators/pace_assessment_calculator_test.dart`
- [x] 1.3 Static analysis passes with zero warnings: `flutter analyze`

#### Manual

- [x] 1.4 Confirm domain files under `lib/features/dashboard/domain/` have zero imports from `data/`, `presentation/`, `package:flutter/*`, or `package:firebase_ai/*`.

### Phase 2: Firebase AI Logic, RTDB Cache Data Sources & Repository

#### Automated

- [ ] 2.1 Code generation succeeds: `dart run build_runner build --delete-conflicting-outputs`
- [ ] 2.2 Data source and repository unit tests pass: `flutter test test/features/dashboard/data/`
- [ ] 2.3 Static analysis passes: `flutter analyze`

#### Manual

- [ ] 2.4 Verify `database.rules.json` is valid JSON and `pace_assessment` rules sit cleanly under `users/$uid` alongside `weight_entries` and `gain_target`.

### Phase 3: Pace Assessment State Management & Dashboard ViewModel Integration

#### Automated

- [ ] 3.1 Code generation succeeds: `dart run build_runner build --delete-conflicting-outputs`
- [ ] 3.2 ViewModel unit tests pass: `flutter test test/features/dashboard/presentation/view_models/`
- [ ] 3.3 Static analysis passes: `flutter analyze`

#### Manual

- [ ] 3.4 Confirm neither `pace_assessment_view_model.dart` nor `pace_assessment_state.dart` imports `package:flutter/material.dart` or `dart:ui`.

### Phase 4: Dashboard Assessment Card, Detailed Report Bottom Sheet & Localization

#### Automated

- [ ] 4.1 Localization generation and code formatting succeed: `flutter gen-l10n && dart format --output=none --set-exit-if-changed lib test`
- [ ] 4.2 All unit and widget tests pass: `flutter test`
- [ ] 4.3 Static analysis passes with zero issues: `flutter analyze`

#### Manual

- [ ] 4.4 Launch the app (`flutter run`), navigate to the Home tab, and verify `PaceAssessmentCard` appears at the top of the Dashboard above `DashboardKpiRow`.
- [ ] 4.5 Verify that missing target, disconnected Hevy, or `< 2` prior weight weeks show clear, non-misleading setup/empty messages.
- [ ] 4.6 With valid weight history (`>= 2` prior weeks + current/previous week), connected Hevy workouts, and a saved gain target, verify the AI status badge and headline summary load on the Dashboard, and tapping "View Full AI Report" opens the modal bottom sheet with Weight Trend, Workout Context, and Actionable Takeaways in both English and Polish.
