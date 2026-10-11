# Import Workout Progress — Plan Brief

> Full plan: `context/changes/import-workout-progress/plan.md`

## What & Why

Lifters tracking a lean bulk need to review their weekly weight trends alongside their actual gym progression (workout count, working sets, volume, and per-exercise weights and reps). This change implements slice `S-05` (`import-workout-progress`) and resolves `F-02` (`workout-source-proof`) by integrating the Hevy Public API (`https://api.hevyapp.com/docs/`) with per-user encrypted local key storage (`flutter_secure_storage`) and expandable ISO Monday–Sunday weekly workout summaries.

## Starting Point

The app has completed `S-01` (`private-account-access`) and `S-02` (`dated-weight-history`) with a 3-tab `HomeShellScreen` (`Home`, `Weights`, `Profile`) and `WeekDateUtils` ISO Monday–Sunday helpers. However, `lib/core/constants/heavy_env.dart` currently exposes compile-time `HEAVY_API_KEY` defines (which must be removed so a personal key is never shared), `pubspec.yaml` lacks HTTP and secure storage packages, and no workout feature module exists yet.

## Desired End State

`HeavyEnv` is removed, and authenticated users can connect their personal Hevy Pro API key in the new `Workouts` tab or `Profile` tab (pre-validated via `GET /v1/workouts/count` and saved encrypted on the device under `hevy_api_key_$userId`). Opening `Workouts` automatically fetches the last 12 ISO weeks of workouts live from `GET /v1/workouts` once per session, displaying expandable ISO Monday–Sunday week cards (workout count, working sets, and volume kg) with drill-down bottom sheets showing every exercise's working sets (`weight_kg × reps`), warmup tags, and best working set.

## Key Decisions Made

| Decision | Choice | Why (1 sentence) |
| --- | --- | --- |
| Hevy credentials (`F-02`) | Per-user key, delete `HeavyEnv` | Prevents bundling the author's personal Hevy key and lets each user supply their own Hevy Pro API key. |
| Workout persistence | Live Hevy API fetch only (no RTDB migration) | Avoids duplicating external Hevy workout data into Firebase Realtime Database. |
| API key storage | Device-local `flutter_secure_storage` (`hevy_api_key_$userId`) | Keeps each user's Hevy Pro API key encrypted on the local device and out of Firebase RTDB. |
| Key validation on save | UUID check + `GET /v1/workouts/count` pre-validation | Guarantees an unauthorized or non-Pro Hevy API key is never written to device storage. |
| Import lookback window | Last 12 ISO weeks cutoff (`pageSize=10`, max 15 pages) | Matches `WeeklyWeightChart`'s 12-week window and satisfies `FR-008`/`FR-009` ($\ge 2$ prior weeks) while bounding HTTP calls. |
| Progress metrics (`PRD` Q2) | Working sets only (`normal`, `failure`, `dropset`) | Excludes `warmup` sets from weekly set count, total volume ($\sum \text{weightKg} \times \text{reps}$), and best set (highest `weightKg`, tie-broken by `reps`) while keeping warmups visible in workout details. |
| Week assignment timezone | Local calendar date of `start_time` (`.toLocal()`) | Matches `S-02` daily weigh-in local date handling and keeps late Sunday evening workouts in the expected ISO week. |
| Session fetch lifecycle | Fetch once per session + manual refresh | Caches the 12-week workouts across tab switches in a user-scoped `NotifierProvider` and re-fetches only on pull-to-refresh, button tap, or key/user change. |
| UI layout & navigation | 4th `Workouts` tab + `Profile` key management | Mirrors `WeeklyWeightCard` expandable ISO week cards (`S-02`) and lets users connect, update, or disconnect their key in `Profile`. |
| Pagination error handling | Fail-fast on initial load, preserve state on refresh | Prevents rendering truncated partial weeks as complete data (`PRD` guardrail) while showing a non-destructive `SnackBar` on refresh failure. |
| Packages added | `http` + `flutter_secure_storage` | Standard Flutter packages for mockable REST requests and encrypted OS keystore/keychain storage. |

## Scope

**In scope:**
- Deleting `lib/core/constants/heavy_env.dart`, updating `README.md`, adding `http` and `flutter_secure_storage` to `pubspec.yaml`, and creating `HevyApiConstants` and `HevyKeyValidators`.
- Workout domain (`WorkoutSetEntity`, `WorkoutExerciseEntity`, `WorkoutEntity`, `WeeklyWorkoutSummaryEntity`, `WorkoutRepository`) and data layer (`WorkoutDto`, `HevyKeyLocalDataSource`, `WorkoutRemoteDataSource`, `WorkoutRepositoryImpl`, `FakeWorkoutRepository`).
- Presentation layer (`WorkoutProgressViewModel`, `HevyKeyViewModel`, `WorkoutProgressView`, `WeeklyWorkoutCard`, `WorkoutDetailBottomSheet`, `HevyKeyBottomSheet`).
- 4-tab `HomeShellScreen` (`Home`, `Weights`, `Workouts`, `Profile`) with `Profile` Hevy key management and unit/widget tests across all layers.

**Out of scope:**
- Storing or migrating workouts or Hevy API keys in Firebase Realtime Database (`database.rules.json` unchanged).
- Creating/editing workouts in Hevy (`POST`/`PUT /v1/workouts`) or `/v1/workouts/events` delta cursor syncing.
- Combined weight + workout overview (`S-06`) and pace assessment (`S-07`).

## Architecture / Approach

```text
HomeShellScreen (Workouts Tab & Profile Tab) -> WorkoutProgressView & HevyKeyBottomSheet
  └── WorkoutProgressViewModel (Session Notifier) / HevyKeyViewModel (Form AutoDisposeNotifier)
        └── WeeklyWorkoutSummaryEntity.groupWorkoutsByIsoWeek (ISO Mon–Sun, working-set metrics)
        └── WorkoutRepository (Domain Contract)
              └── WorkoutRepositoryImpl (Maps AppException -> Result<T, AppFailure>)
                    ├── HevyKeyLocalDataSource (FlutterSecureStorage: hevy_api_key_$userId)
                    └── WorkoutRemoteDataSource (http.Client: GET /v1/workouts/count & /v1/workouts)
```

## Phases at a Glance

| Phase | What it delivers | Key risk |
| --- | --- | --- |
| 1. Core Cleanup & Validators | Delete `HeavyEnv`, update `README.md`, add packages, `HevyKeyValidators` | Leaving stale `HeavyEnv` references |
| 2. Domain & Data Layer | Workout entities, ISO week grouping, local key store, Hevy HTTP pagination | Cutoff filtering on boundary page (`pageSize=10`, max 15 pages) |
| 3. Presentation Layer | Session-cached ViewModel, key setup, expandable week cards & detail sheet | Keeping session state cached across tabs while resetting on logout |
| 4. Shell & Profile Integration | 4-tab `HomeShellScreen` (`Workouts` tab + `Profile` key card) & E2E tests | Preserving all `S-01` and `S-02` widget test keys |

**Prerequisites:** Completed `S-01` (`private-account-access`) and `S-02` (`dated-weight-history`), plus a Hevy Pro API key for manual end-to-end verification.
**Estimated effort:** ~4 implementation cycles across 4 phases.

## Open Risks & Assumptions

- **Hevy Pro requirement:** The Hevy Public API (`https://api.hevyapp.com/docs/`) requires each user to have an active Hevy Pro subscription to generate an `api-key` at `https://hevy.com/settings?developer`.
- **Browser CORS on Flutter Web:** Direct client calls to `https://api.hevyapp.com` target Android (the MVP platform in `prd.md`); running in Chrome (`-d chrome`) depends on Hevy's CORS headers.

## Success Criteria (Summary)

- `HeavyEnv` is removed, and authenticated users can pre-validate (`GET /v1/workouts/count`) and save/update/disconnect their personal Hevy API key in device-local encrypted storage (`hevy_api_key_$userId`).
- The `Workouts` tab fetches the last 12 ISO weeks of workouts from `GET /v1/workouts` once per session and renders expandable Monday–Sunday week cards (workout count, working sets, volume kg) with exercise/set drill-downs (`weight_kg × reps`, warmup badges, best working set).
- All unit and widget tests pass with zero `flutter analyze` warnings.
