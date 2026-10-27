# Contextual Pace Assessment — Plan Brief

> Full plan: `context/changes/contextual-pace-assessment/plan.md`
> Research: `context/changes/contextual-pace-assessment/research.md`

## What & Why

Build the Gemini-powered Contextual Pace Assessment (`S-07`) so lifters can see at a glance whether their weekly weight gain is **on target**, **too fast**, **too slow**, or **stagnant** relative to their saved target range, at least two prior recorded weight weeks, and their imported Hevy workout progression. This completes the core product promise of Bulk Tempo by combining bodyweight trends with lift progression (`bestWorkingSet` weight × reps and volume) into a single weekly verdict and detailed AI report.

## Starting Point

The app already initializes `FirebaseAppCheck` (`lib/main.dart:20-25`), declares `firebase_ai: ^2.3.0` (`pubspec.yaml:26`), and composes weight history, Hevy workout summaries, and weekly gain targets in `DashboardViewModel` (`lib/features/dashboard/presentation/view_models/dashboard_view_model.dart:21-127`). However, `WeeklyProgressCalculator` only requires 2 total weight weeks, `CalendarWeekProgressSlotEntity` only stores workout counts, and no Gemini integration, 4-state status classification, or AI report UI exists yet.

## Desired End State

When a user opens the Home Dashboard, a dedicated `PaceAssessmentCard` at the top (above `DashboardKpiRow`) either guides them to complete missing prerequisites (set a gain target, connect Hevy with `>= 1` workout in the 12-week window, or log a recent weight week plus `>= 2` prior weight weeks) or displays one of the 4 pace statuses alongside a 1–2 sentence AI headline summary. Tapping "View Full AI Report" opens a `DraggableScrollableSheet` modal bottom sheet with structured sections for Weight Trend Analysis, Workout & Strength Context, and Actionable Takeaways in the active app language (`en` or `pl`), cached per data+locale fingerprint in Firebase Realtime Database (`users/$uid/pace_assessment`).

## Key Decisions Made

| Decision | Choice | Why (1 sentence) | Source |
| --- | --- | --- | --- |
| AI integration path | Client-side `FirebaseAI.googleAI()` (`gemini-2.5-flash`) + mobile App Check | Avoids custom Cloud Functions while protecting API calls with Play Integrity / App Attest. | Research / Plan |
| Weight history eligibility | Recent week (current with `>= 1` entry or previous week) + `>= 2` earlier recorded weeks in 12w window | Satisfies the PRD's 2-prior-weeks requirement without penalizing a skipped week or mid-week check-in. | Plan |
| Hevy workout requirement | Require Hevy connected with `>= 1` workout in 12w window; allow 0-workout weeks as rest context | Guarantees real training context is present without breaking when a user takes a deload week. | Plan |
| Gain target requirement | Require a saved `GainTargetEntity` (`gainTarget != null`); show setup prompt if unset | Prevents judging a user's bulk against arbitrary default bounds they never chose. | Plan |
| Status classification authority | Hybrid: deterministic Dart baseline status (`<= 0` stagnant, `< min` tooSlow, `min..max` onTarget, `> max` tooFast) + Gemini contextual adjustment | Provides a predictable mathematical anchor while allowing lift progression to inform borderline weeks. | Plan |
| Workout payload granularity | Weekly totals (`workoutCount`, `totalWorkingSets`, `totalVolumeKg`) + per-exercise `bestWorkingSet` (`weightKg × reps`) and volume | Captures progressive overload on lifts (`PRD FR-006/FR-008`) in a compact, low-token JSON payload. | Plan |
| Detailed AI report format | Structured JSON (`status`, `headlineSummary`, `weightTrendAnalysis`, `workoutContextAnalysis`, `actionableTakeaways`) | Renders cleanly in native Flutter widgets without adding Markdown parsing dependencies. | Plan |
| Dashboard UX & navigation | Dedicated `PaceAssessmentCard` above `DashboardKpiRow` + `DraggableScrollableSheet` modal bottom sheet | Surfaces the weekly verdict immediately on app open and matches `WorkoutDetailBottomSheet` conventions. | Plan |
| Triggering & caching | Auto-assess on `(weights, workouts, target, locale)` fingerprint change + cache in RTDB (`users/$uid/pace_assessment`) | Syncs the latest AI report across devices (`FR-012`) and avoids redundant Gemini calls when data is unchanged. | Plan |
| Localization (`en` / `pl`) | Pass active `localeProvider` language (`en`/`pl`) to Gemini prompt and localize UI chrome/status badges via ARB files | Keeps the AI narrative and UI badges consistent with the user's selected language. | Plan |

## Scope

**In scope:**
- Domain eligibility, weekly exercise best-set/volume aggregation, deterministic baseline status, and canonical fingerprinting (`PaceAssessmentCalculator`).
- Firebase RTDB caching (`users/$uid/pace_assessment` + `database.rules.json`) and `gemini-2.5-flash` structured JSON generation (`PaceAssessmentAiDataSource`).
- `PaceAssessmentViewModel` auto-evaluation, deduplication, error/outdated states, and `DashboardViewModel` integration.
- `PaceAssessmentCard` (top of Dashboard), `PaceAssessmentReportBottomSheet`, and EN/PL ARB translations.

**Out of scope:**
- Custom Firebase Cloud Functions or server-side proxies.
- Weight-only AI assessment fallback when Hevy or Gain Target is unconfigured.
- Raw set-by-set warmup/working set dumps in the AI prompt.
- Automated calorie or macro meal planning.

## Architecture / Approach

`PaceAssessmentCalculator` (Domain) synchronously evaluates upstream weight summaries, Hevy workout summaries, `gainTarget`, and `localeCode` to produce either a specific `PaceAssessmentIneligibilityReason` or a `PaceAssessmentInputEntity` with a deterministic `fingerprint` and `baselineStatus`. `PaceAssessmentViewModel` (Presentation) watches this eligibility result and delegates to `PaceAssessmentRepositoryImpl` (Data), which checks `PaceAssessmentCacheDataSource` (`users/$uid/pace_assessment`) for a matching `fingerprint` before calling `PaceAssessmentAiDataSource` (`FirebaseAI.googleAI()`, `gemini-2.5-flash`, `Schema.object` behind a mockable `GeminiContentGenerator` adapter) and persisting the new result back to RTDB.

## Phases at a Glance

| Phase | What it delivers | Key risk |
| --- | --- | --- |
| 1. Domain Models, Eligibility & Hybrid Baseline Calculator | `PaceAssessmentEntity`, `PaceAssessmentCalculator`, and `PaceAssessmentRepository` contract with unit tests | Edge cases in ISO week recency and exercise best-set aggregation |
| 2. Firebase AI Logic, RTDB Cache Data Sources & Repository | RTDB cache data source + rules, `gemini-2.5-flash` AI data source (`Schema.object`), and repository with unit tests | `GenerativeModel` is a `final class`; mitigated via `GeminiContentGenerator` adapter |
| 3. Pace Assessment State Management & Dashboard ViewModel Integration | `PaceAssessmentState`, `PaceAssessmentViewModel`, and `DashboardViewModel` wiring with unit tests | Avoiding duplicate in-flight Gemini calls on rapid provider rebuilds |
| 4. Dashboard Assessment Card, Detailed Report Bottom Sheet & Localization | EN/PL ARB keys, `PaceAssessmentCard`, `PaceAssessmentReportBottomSheet`, and widget tests | Keeping card states clear across 4 ineligibility reasons and 4 loaded statuses |

**Prerequisites:** `firebase_ai: ^2.3.0` and `firebase_app_check: ^0.3.2+10` in `pubspec.yaml` (already present), plus Firebase AI Logic enabled in Firebase Console.
**Estimated effort:** ~4 focused implementation steps across the 4 phases.

## Open Risks & Assumptions

- **Firebase Console App Check & AI Logic configuration**: Local code cannot verify whether App Check enforcement is toggled on in the Firebase Console or whether production Play Integrity / App Attest credentials are registered for release builds (`context/changes/contextual-pace-assessment/research.md:45-47`).

## Success Criteria (Summary)

- Eligible users immediately see one of the 4 localized pace statuses (`On target`, `Too fast`, `Too slow`, `Stagnation`) and a concise AI summary at the top of the Home Dashboard, backed by an RTDB fingerprint cache.
- Tapping "View Full AI Report" opens the modal bottom sheet showing Weight Trend vs. Target, Workout & Strength Context (referencing Hevy exercises/weights/reps), and Actionable Takeaways in English or Polish.
- Users missing a gain target, connected Hevy workouts, or at least two prior weight weeks see explicit, non-misleading guidance instead of an incomplete or hallucinated assessment.
