---
date: 2026-10-24T18:45:55+02:00
researcher: Codex
git_commit: 5c64c7fcdf1930549df5c000be2911f1405b60d5
branch: main
repository: bulk_tempo
topic: "Contextual pace assessment with Firebase AI Logic and mobile App Check"
tags: [research, codebase, dashboard, firebase-ai-logic, app-check]
status: complete
last_updated: 2026-10-24
last_updated_by: Codex
---

# Research: Contextual pace assessment with Firebase AI Logic and mobile App Check

**Date**: 2026-10-24T18:45:55+02:00  
**Researcher**: Codex  
**Git Commit**: `5c64c7fcdf1930549df5c000be2911f1405b60d5`  
**Branch**: `main`  
**Repository**: `bulk_tempo`

## Research Question

How can this Flutter app show whether weight-gain pace is on target, too fast, too slow, or stagnant using at least two prior weeks and workout context, with Gemini through Firebase AI Logic, no custom Firebase Functions, and production App Check registration for Android and iOS only? The user reports that the Firebase AI Logic Console setup is already done.

## Summary

Firebase's [Flutter AI Logic quickstart](https://firebase.google.com/docs/ai-logic/get-started?api=dev) documents app-side `firebase_ai` calls through the Gemini Developer API and adds `firebase_app_check`; this supports the requested no-custom-Functions integration. The inspected app currently initializes Firebase Core but does not declare either plugin (`lib/main.dart:11-18`, `pubspec.yaml:13-26`). Console AI Logic setup and App Check enforcement cannot be verified from these repository files.

The dashboard already combines weight, workout, and target data (`lib/features/dashboard/presentation/view_models/dashboard_view_model.dart:39-55,113-125`). Its current pace requires two *recorded* weight weeks and therefore does not meet the requested assessed week plus at least two prior weeks (`lib/features/dashboard/domain/calculators/weekly_progress_calculator.dart:112-152`). The existing display shows numeric pace and a target band, without the four labels or a workout-based explanation (`lib/features/dashboard/presentation/widgets/weekly_pace_chart_card.dart:23-39,149-179`; `lib/features/dashboard/presentation/widgets/dashboard_kpi_row.dart:52-79`).

## Detailed Findings

### Existing pace and workout inputs

- Recorded daily weights are grouped into ISO Monday–Sunday weeks, with the arithmetic mean of recorded entries and the number of logged days (`lib/features/weight/domain/models/weekly_weight_summary_entity.dart:20-89`). The current calculator takes adjacent *recorded* weeks and divides their average-weight difference by the calendar-week gap; it rounds the result to two decimals (`lib/features/dashboard/domain/calculators/weekly_progress_calculator.dart:43-75`). This inspected path has no minimum logged-day threshold.
- The current pace is available when there are at least two recorded weight weeks and the latest is the current or previous calendar week. A current week with one to six logged days is marked incomplete yet still contributes to pace (`lib/features/dashboard/domain/calculators/weekly_progress_calculator.dart:112-152`). A separate assessment eligibility rule is needed for the user's at-least-two-*prior*-weeks condition.
- The dashboard watches weight, workout, and target states; its calendar slot retains a workout count, but not weights and repetitions (`lib/features/dashboard/presentation/view_models/dashboard_view_model.dart:39-55`; `lib/features/dashboard/domain/models/weekly_progress_overview_entity.dart:10-20`). The loaded workout state retains individual workouts and weekly summaries; those summaries include count, working sets, and volume, and exercise data retains sets with weight and repetitions (`lib/features/workout/presentation/view_models/workout_progress_state.dart:27-32`; `lib/features/workout/domain/models/weekly_workout_summary_entity.dart:12-20`; `lib/features/workout/domain/models/workout_exercise_entity.dart:12-23`; `lib/features/workout/domain/models/workout_set_entity.dart:12-23`). With its default argument, the Hevy repository fetches a last-12-ISO-week window (`lib/features/workout/data/repositories/workout_repository_impl.dart:120-151`; `lib/core/constants/hevy_api_constants.dart:9`).
- A missing workout week becomes a zero in the calendar slot, while the dashboard separately distinguishes loading, unconfigured, error, and loaded workout states (`lib/features/dashboard/domain/calculators/weekly_progress_calculator.dart:99-108`; `lib/features/dashboard/presentation/view_models/dashboard_view_model.dart:67-73`). The assessment must use that availability state before treating zero as observed workout inactivity.
- The saved gain target is the existing minimum/maximum kg-per-week range (`lib/features/gain_target/domain/models/gain_target_entity.dart:5-13`; `lib/features/dashboard/presentation/view_models/dashboard_view_model.dart:123`). Weight records are read under the signed-in user's Realtime Database path (`lib/features/weight/data/datasources/weight_remote_data_source.dart:35-41`).

### Firebase AI Logic and mobile App Check

- The [Firebase AI Logic Flutter guide](https://firebase.google.com/docs/ai-logic/get-started?api=dev) instructs adding `firebase_ai` and `firebase_app_check`, initializing Firebase, selecting the Gemini Developer API through `FirebaseAI.googleAI()`, creating a model, and calling `generateContent`. Its Gemini Developer API path does not require an app-embedded Gemini API key. These documented client calls establish a route without a custom Cloud Function. The current inspected `pubspec.yaml:13-26` and `lib/main.dart:11-18` do not yet implement it.
- The [AI Logic App Check guide](https://firebase.google.com/docs/ai-logic/app-check) says to inspect **Security → App Check → APIs → Firebase AI Logic** in Console and enforce that API if it remains unenforced. It describes registering production apps with an attestation provider before end-user release. The user's reported AI Logic Console setup does not establish the current App Check enforcement or registration state; those are separate Console checks. Firebase states that App Check enforcement for AI Logic becomes required on **2026-11-02** in that guide.
- For the requested mobile scope, Firebase's [Flutter App Check guide](https://firebase.google.com/docs/app-check/flutter/default-providers) lists Play Integrity for Android and DeviceCheck or App Attest for Apple. Activation follows `Firebase.initializeApp()` and precedes Firebase service use. The [Android Play Integrity guide](https://firebase.google.com/docs/app-check/android/play-integrity-provider) requires linking the Play Integrity API to the same Cloud/Firebase project and registering the Android app with its **release-signing SHA-256**. This checkout's Android release build currently uses debug signing (`android/app/build.gradle.kts:33-38`), so the actual production signing fingerprint is not established here. The [Apple App Attest guide](https://firebase.google.com/docs/app-check/ios/app-attest-provider) requires registration in Console and the App Attest capability/production entitlement; [DeviceCheck](https://firebase.google.com/docs/app-check/ios/devicecheck-provider) instead requires an Apple-generated private key in Console.
- Firebase documents App Check debug providers for local emulators/simulators and warns to keep debug tokens private and out of released builds ([AI Logic App Check guide](https://firebase.google.com/docs/ai-logic/app-check)). If the app uses AI Logic only on Android/iOS, the existing web Firebase registration (`lib/firebase_options.dart:18-26,49-59`) does not itself require a web AI feature or web App Check provider. The AI call/activation path should be scoped to supported mobile targets during planning.
- The [structured-output guide](https://firebase.google.com/docs/ai-logic/generate-structured-output) supports a Dart JSON schema through `GenerationConfig(responseMimeType: 'application/json', responseSchema: ...)`. That can constrain the four labels and explanation shape, but app-side parsing and consistency checks remain necessary before showing a model response as an assessment. This is a design inference from the SDK capability, not an observed app behavior.

### Existing requirements and conflicts

- The current PRD marks AI guidance optional and says the base decision should work without AI (`context/foundation/prd.md:83-84,109-110`). For this change, the user's explicit Gemini-through-Firebase requirement supersedes that historical assumption. The PRD still requires comparing training weights/repetitions across the assessed and at least two earlier weeks (`context/foundation/prd.md:73-79,91-99`).
- The roadmap marks S-07 blocked on the four status thresholds and behavior when measurements or two prior weeks are missing (`context/foundation/roadmap.md:171-183,199-203`). The current user request settles the integration route and mobile-only attestation scope, but it does not define those classification and sparse-data rules. Research does not assign thresholds or let Gemini silently invent them.

## Code References

- `lib/features/dashboard/domain/calculators/weekly_progress_calculator.dart:43-75,112-152` — existing gap-adjusted pace and recency rule.
- `lib/features/dashboard/presentation/view_models/dashboard_view_model.dart:39-55,67-73,113-125` — state composition and workout availability.
- `lib/features/workout/domain/models/weekly_workout_summary_entity.dart:12-20` — richer weekly workout context.
- `lib/main.dart:11-18`; `pubspec.yaml:13-26` — Firebase initialization and dependency boundary.
- `android/app/build.gradle.kts:20,33-38`; `ios/Runner.xcodeproj/project.pbxproj:683,705` — mobile identifiers and signing context.

## Architecture Insights

The app uses a Riverpod ViewModel to compose repository-backed data into dashboard state (`lib/features/dashboard/presentation/view_models/dashboard_view_model.dart:14-55`). A future assessment can consume the existing domain summaries and loaded-state signals through that boundary; the existing numeric chart calculation does not need to become a network caller. The established feature layout and dependency direction are documented in `context/documentation/01_architecture_overview.md` and `context/documentation/03_state_management_mvvm.md`.

## Historical Context

The PRD's AI-optional statement is **superseded for this change** by the user's current Gemini requirement (`context/foundation/prd.md:83-84,109-110`; `context/changes/contextual-pace-assessment/change.md:12`). The PRD's weight/repetition comparison is **still applicable** (`context/foundation/prd.md:73-79,91-99`). The roadmap's missing status and sparse-data rules remain **open** (`context/foundation/roadmap.md:171-183`). Earlier workout-import work established the Hevy client source for workout data (`context/changes/import-workout-progress/plan.md:5,45`).

## Related Research

No other research artifact was needed to answer this change's integration and code-path questions.

## Open Questions

1. What exact pace window, stagnation threshold, and precedence among on-target, too-fast, too-slow, and stagnant should the model output obey? Should a deterministic target comparison validate the model's label? The PRD and roadmap leave this open (`context/foundation/prd.md:114-118`; `context/foundation/roadmap.md:179-182`).
2. Which weight-log minimum and continuity rule qualifies each prior week, and what should the UI show when fewer than two prior weeks qualify or the current week is partial? The current calculator's two-recorded-week condition is weaker (`lib/features/dashboard/domain/calculators/weekly_progress_calculator.dart:127-149`).
3. Which comparable training measure should be sent to Gemini: session count, working sets/volume, or matched exercises' weights and repetitions? The PRD specifically names weights and repetitions (`context/foundation/prd.md:73-79`). What should happen if Hevy is unconfigured, failed, or stale (`lib/features/dashboard/presentation/view_models/dashboard_view_model.dart:67-83`)?
4. In the actual Firebase Console, is **Firebase AI Logic** currently enforced under App Check, and are Android and iOS registered with production providers? What are the intended Android release signing SHA-256 and Apple provider/entitlement credentials? Local repository evidence cannot answer Console or production-signing state (`android/app/build.gradle.kts:33-38`).
