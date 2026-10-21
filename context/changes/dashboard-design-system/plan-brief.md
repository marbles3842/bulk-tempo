# Dashboard Design System Migration — Plan Brief

> Full plan: `context/changes/dashboard-design-system/plan.md`

## What & Why

We are migrating the Home dashboard (`lib/features/dashboard/presentation/`) onto Bulk Tempo's shared design system (`lib/core/design_system.dart`) and cataloging its components and states in `widgetbook/` and `test/features/dashboard/presentation/`. This replaces bespoke Material `Card`s, `errorContainer` stale pills, `FittedBox` metric shrinking, fixed `18px` subtitle boxes, and hardcoded `fl_chart` colors/styles with semantic tokens (`AppSpacing`, `AppChartTheme`, `AppIcons`) and adaptive primitives (`AppCard`, `AppStatusBadge`, `AppButton`).

## Starting Point

`DashboardView`, `DashboardCardShell`, `DashboardKpiRow`, and the three `fl_chart` cards (`WeeklyWeightTrendCard`, `WeeklyPaceChartCard`, `WeeklyWorkoutsChartCard`) were built in slice S-06 before `lib/core/design_system.dart` existed on `feature/design-system` (PR #38). Today they use raw elevated `Card`s, shrink KPI values with `FittedBox`, clip scaled subtitles inside a `SizedBox(height: 18)`, color all chart series with `colorScheme.primary` and `Colors.white` tooltips, and have no dedicated widget tests in `test/features/dashboard/presentation/`.

## Desired End State

Opening the Home tab (or the new `Dashboard` category in Widgetbook) renders a `1120px`-capped, responsive dashboard with `RefreshIndicator.adaptive`, `16px`/`24px` page gutters, `AppCard`-backed KPI tiles using `headlineMedium` tabular figures (`4×1` at `>=840px`, `2×2` at `<840px`, `1×4` at `>=1.4x` text scale), `AppCard`-backed chart shells with warning `AppStatusBadge` stale indicators and adaptive loading/retry states, and `AppChartTheme`-styled charts with dashed pace target boundaries, large-text tick stepping, and localized screen-reader `Semantics`.

## Key Decisions Made

| Decision | Choice | Why (1 sentence) |
| --- | --- | --- |
| Branch baseline | Start a new branch from `feature/design-system` (targeting `feature/design-system`) | `lib/core/design_system.dart` and `widgetbook/` live on `feature/design-system` (`d41fc7d`) and are not yet on `main`. |
| Feature scope boundary | `lib/features/dashboard/presentation/**`, `widgetbook/`, and `test/features/dashboard/**` only | Keeps the migration cohesive within the dashboard module without cross-feature churn in `HomeShellScreen`. |
| Responsive dashboard layout | `1120px` max width + `16px`/`24px` page gutters + `4×1` KPIs at `>=840px` + stacked chart cards | Gives wide screens a 4-across KPI header while keeping 12-week chart X-axes uncrowded. |
| KPI tile typography & reflow | `AppCard` + `headlineMedium` (tabular figures) + `IntrinsicHeight` rows + `1×4` reflow at `>=1.4x` scale | Satisfies `07_design_system.md` §6 by removing `FittedBox` and fixed `18px` subtitle boxes without mid-number wrapping. |
| `DashboardCardShell` composition | Wrap `AppCard(grouped)` + `AppStatusBadge(warning)` in `headerTrailing` + chart `leadingIcon`s | Eliminates duplicate card/header code, uses warning-amber for stale data, and distinguishes Weight, Pace, and Workouts cards. |
| `DashboardCardShell` async states | `ConstrainedBox(minHeight: contentHeight)` + adaptive spinner + tonal `AppButton` retry | Prevents vertical overflow at `2.0x` text scale, adapts spinners to iOS/Android, and preserves existing widget keys. |
| KPI status indicators | `AppStatusBadge(info)` for `dashboard_incomplete_week_badge` and `AppStatusBadge(error)` for workout sync error | Visually flags partial current-week averages and sync failures per PRD guardrails while preserving `Key('dashboard_incomplete_week_badge')`. |
| Pace chart target band | `chartTheme.targetFill` (`0.55` alpha) range annotation + dashed `chartTheme.targetBoundary` lines | Implements the `07_design_system.md` §4 contract (`secondaryContainer` fill + dashed `onSecondaryContainer` bounds) while keeping `home_shell_screen_test.dart` green. |
| Chart typography & accessibility | `AppChartTheme` tokens + scaled `reservedSize` + every-4th-week ticks at `>=1.3x` scale + `Semantics` summary | Removes hardcoded `fontSize: 10` and `Colors.white`, prevents scaled label collisions, and exposes per-week values to screen readers. |
| Pull-to-refresh adaptation | `RefreshIndicator.adaptive` wrapping `ListView(key: Key('dashboard_scroll_view'))` | Provides native Cupertino refresh physics/spinner on iOS and Material refresh on Android/web without breaking `RefreshIndicator` test finders. |
| Verification & cataloging | Dedicated tests in `test/features/dashboard/presentation/` + `Dashboard` category in `widgetbook/` | Fills the empty dashboard presentation test directory and enables interactive inspection across all themes, locales, and platform modes. |

## Scope

**In scope:** `lib/features/dashboard/presentation/views/dashboard_view.dart`, `lib/features/dashboard/presentation/widgets/{dashboard_card_shell,dashboard_kpi_row,weekly_weight_trend_card,weekly_pace_chart_card,weekly_workouts_chart_card}.dart`, `widgetbook/use_cases/dashboard_use_cases.dart`, `widgetbook/widgetbook_app.dart`, and new widget/accessibility tests in `test/features/dashboard/presentation/`.

**Out of scope:** `HomeShellScreen` (`lib/features/auth/presentation/views/home_shell_screen.dart`), domain calculators/entities, `DashboardViewModel` business logic, S-07 pace classification verdicts, and placing any Widgetbook files inside `lib/`.

## Architecture / Approach

`DashboardViewModel` continues to emit pure-Dart `DashboardState`. In the presentation layer, `DashboardView` owns the `1120px` max-width constraint, responsive page gutters (`16px` / `24px`), and vertical section gaps (`12px`). `DashboardKpiRow` and `DashboardCardShell` compose `AppCard`, `AppStatusBadge`, and `AppButton` from `lib/core/design_system.dart`, while the three chart cards resolve `AppChartTheme.of(context)` for series colors, grid lines, tooltips, and target-band styling.

## Phases at a Glance

| Phase | What it delivers | Key risk |
| --- | --- | --- |
| 1. Dashboard Card Shell, KPI Header & Responsive View Layout | Branch from `feature/design-system`; migrate `DashboardCardShell`, `DashboardKpiRow`, and `DashboardView` | Preserving all existing KPI and card `Key`s expected by `home_shell_screen_test.dart` |
| 2. Dashboard `fl_chart` Cards Tokenization, Target Band & Accessibility | Migrate 3 chart cards to `AppChartTheme`, add dashed target bounds, dynamic tick stepping, and `Semantics` | Keeping `HorizontalRangeAnnotation` intact alongside `extraLinesData` for `home_shell_screen_test.dart:279-282` |
| 3. Dashboard Widget/Accessibility Test Suite & Widgetbook Catalog | Add `test/features/dashboard/presentation/**` tests and `widgetbook/use_cases/dashboard_use_cases.dart` | Providing local `ProviderScope` overrides in Widgetbook so `widgetbook_smoke_test.dart` runs without Firebase |

**Prerequisites:** Branch created from `feature/design-system` (`d41fc7d`, PR #38).
**Estimated effort:** ~1–2 sessions across 3 phases.

## Open Risks & Assumptions

- `DashboardView` use cases in `widgetbook/` must override `dashboardViewModelProvider` locally because `test/widgetbook/widgetbook_smoke_test.dart` pumps every catalog use case without Firebase initialized.
- The working branch must be created from `feature/design-system` (and later merged back into `feature/design-system` or `main` after PR #38 lands).

## Success Criteria (Summary)

- All dashboard cards and KPI tiles render through `AppCard`, `AppStatusBadge`, `AppButton`, and `AppChartTheme` with responsive `1×4` / `2×2` / `4×1` KPI reflow, `1120px` max width, dashed pace target boundaries, and zero overflow at `2.0x` text scale in English and Polish.
- `dart format --output=none --set-exit-if-changed lib test widgetbook`, `flutter analyze`, and `flutter test` pass, including the new `test/features/dashboard/presentation/` suite and `test/widgetbook/widgetbook_smoke_test.dart`.
