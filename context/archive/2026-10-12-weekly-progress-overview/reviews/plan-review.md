<!-- PLAN-REVIEW-REPORT -->
# Plan Review: Weekly Progress Overview Dashboard (S-06)

- **Plan**: context/changes/weekly-progress-overview/plan.md
- **Mode**: Deep
- **Date**: 2026-10-14
- **Verdict**: SOUND (updated after fixes)
- **Findings**: 2 critical (2 fixed), 2 warnings (1 fixed, 1 skipped), 0 observations

## Verdicts

| Dimension | Verdict |
|-----------|---------|
| End-State Alignment | PASS ✅ |
| Lean Execution | PASS ✅ |
| Architectural Fitness | PASS ✅ |
| Blind Spots | PASS ✅ |
| Plan Completeness | PASS ✅ |

## Grounding
Grounding: 6/6 paths ✓, 3/3 symbols ✓, brief↔plan ✓

## Findings

### F1 — Missing Freezed for DashboardState & manual boilerplate on GainTargetState

- **Severity**: ❌ CRITICAL
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Architectural Fitness
- **Location**: Phase 2 — Dashboard ViewModel & Per-Card State (Sections 2 & 3)
- **Detail**: `context/documentation/03_state_management_mvvm.md` mandates that all UI state classes must be immutable and modeled using `@freezed`. Phase 2 specifies `class DashboardState` as a plain Dart class rather than a Freezed data class with `part 'dashboard_state.freezed.dart';`. Additionally, Phase 2 instructs to add `hasLoadedOnce` to `GainTargetState` and "include it in copyWith, ==, hashCode, and toString", even though `GainTargetState` is already `@freezed`. Phase 2 automated verification also omits `dart run build_runner build --delete-conflicting-outputs`.
- **Fix**: Specify `DashboardState` as an `@freezed` class, update `GainTargetState` using `@Default(false) bool hasLoadedOnce` in its Freezed factory constructor, and add `build_runner` code generation to Phase 2.
- **Decision**: FIXED (Fixed in plan)

### F2 — Complete absence of localization support across all dashboard UI components

- **Severity**: ❌ CRITICAL
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Architectural Fitness
- **Location**: Phase 3 — Home Tab fl_chart UI, Wiring & Test Migration (Widgets 1–6)
- **Detail**: Localization was recently merged into `main` (PR #35 & #36), establishing bilingual English and Polish support via `app_en.arb`, `app_pl.arb`, and `context.l10n`. The plan hardcodes all new user-facing dashboard strings in English (e.g. `'Outdated · last refresh failed'`, `'This week · X/7 days logged'`, `'Log 2+ weeks'`, `'No weights logged yet — add one on the Weights tab'`, `'Hevy not connected — connect in Profile'`, `'Target: X.XX–Y.YY kg/week'`), with zero mention of ARB files, `flutter gen-l10n`, or `test/features/localization/polish_rendering_test.dart`.
- **Fix A ⭐ Recommended**: Integrate full localization into Phase 3
  - Strength: Enforces complete consistency with the app's established localization standard; prevents regressions when switching between English and Polish.
  - Tradeoff: Adds ~12 new translation keys and ARB synchronization to Phase 3.
  - Confidence: HIGH — matches the exact pattern used in all other features (`weight`, `workout`, `gain_target`).
  - Blind spot: None significant.
- **Fix B**: Defer localization to a post-slice refactoring PR
  - Strength: Keeps Phase 3 strictly focused on UI layout and chart rendering.
  - Tradeoff: Ships broken Polish localization on the main landing tab; requires modifying all widgets twice.
  - Confidence: LOW — violates repository guidelines to maintain feature parity across locales.
  - Blind spot: Polish rendering smoke tests will fail if they assert Home tab elements.
- **Decision**: FIXED (Fixed via Fix A)

### F3 — Phase 1 entity contract omits Freezed documentation

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Plan Completeness
- **Location**: Phase 1 — Domain Weekly Progress Calculator (Section 2)
- **Detail**: `context/documentation/04_data_and_domain.md` mandates that all domain entities strictly rely on Freezed. In the plan text, `CalendarWeekProgressSlotEntity` and `WeeklyProgressOverviewEntity` are described as "immutable pure-Dart value objects with value equality (== and hashCode)" without mentioning Freezed. Commit `6b15f39` actually implemented them using `@freezed`, leaving documentation drift between the plan and the landed code.
- **Fix**: Update Phase 1 specification in `plan.md` to document that `CalendarWeekProgressSlotEntity` and `WeeklyProgressOverviewEntity` are `@freezed` models.
- **Decision**: SKIPPED (Phase 1 already landed with @freezed)

### F4 — Missing locale-aware number and unit formatting specification

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Blind Spots
- **Location**: Phase 3 — KPI Stat Tiles & fl_chart Cards
- **Detail**: The plan relies on manual string formatting like `'+0.20 kg/wk'` and `'80.60 kg'`. In Polish, decimal separators use commas (e.g. `80,60 kg`) and units should be localized (`kg/tydz.`). Leaving number formatting unspecified leads to mixed dot/comma separators across screens.
- **Fix**: Specify using `NumberFormat.decimalPattern(Localizations.localeOf(context).toString())` or centralized formatting helpers with localized ARB templates for units.
- **Decision**: FIXED (Fixed in plan)
