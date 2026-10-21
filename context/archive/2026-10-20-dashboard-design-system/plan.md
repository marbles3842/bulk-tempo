# Dashboard Design System Migration Implementation Plan

## Overview

Migrate the Home dashboard presentation layer (`lib/features/dashboard/presentation/`) to Bulk Tempo's shared design system (`lib/core/design_system.dart`), replacing raw Material `Card`s, bespoke status containers, `FittedBox` metric shrinking, and hardcoded `fl_chart` colors/styles with `AppCard`, `AppStatusBadge`, `AppButton`, `AppSpacing`, `AppIcons`, `AppChartTheme`, responsive breakpoints, and screen-reader semantics. In addition, deliver a dedicated widget and accessibility test suite under `test/features/dashboard/presentation/` and a `Dashboard` feature category in `widgetbook/`.

## Current State Analysis

The Home dashboard (`lib/features/dashboard/`) was implemented in slice S-06 (`weekly-progress-overview`, PR #37) before the shared design system (`feature/design-system`, PR #38) existed. While `DashboardViewModel` (`lib/features/dashboard/presentation/view_models/dashboard_view_model.dart:21-179`) and `WeeklyProgressCalculator` (`lib/features/dashboard/domain/calculators/weekly_progress_calculator.dart:6-154`) are pure-Dart and already follow `03_state_management_mvvm.md`, the five presentation files under `lib/features/dashboard/presentation/` bypass `lib/core/design_system.dart` entirely:

- `DashboardView` (`lib/features/dashboard/presentation/views/dashboard_view.dart:43-69`) uses a non-adaptive `RefreshIndicator` and `ListView(padding: EdgeInsets.symmetric(vertical: 8))` with no max-width constraint (`AppSpacing.dashboardMaxWidth = 1120.0`) and no responsive outer page gutters (`AppSpacing.pageInsetCompact = 16.0`, `AppSpacing.pageInsetWide = 24.0`), leaving individual cards to apply their own horizontal margins.
- `DashboardCardShell` (`lib/features/dashboard/presentation/widgets/dashboard_card_shell.dart:52-189`) builds a raw `Card(elevation: 2, margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))`, renders its `isOutdated` pill with a bespoke `Container(color: theme.colorScheme.errorContainer)`, locks `loading`/`error`/`empty`/`unconfigured` bodies inside a fixed `SizedBox(height: contentHeight)` (`220px`), uses a Material-only `CircularProgressIndicator()`, and renders retry actions with a raw `FilledButton.tonal`.
- `DashboardKpiRow` (`lib/features/dashboard/presentation/widgets/dashboard_kpi_row.dart:18-261`) hardcodes a `2×2` grid with `EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0)`, builds `_StatTile` with a raw `Card(elevation: 1, borderRadius: 12)`, uses `titleLarge` instead of `headlineMedium` (tabular figures), shrinks numbers with `FittedBox(fit: BoxFit.scaleDown)` (`dashboard_kpi_row.dart:232-240`), fixes subtitle height to `SizedBox(height: 18)` with `maxLines: 1` (`dashboard_kpi_row.dart:243-255`), and renders `dashboard_incomplete_week_badge` as plain `onSurfaceVariant` text (`dashboard_kpi_row.dart:96-106`).
- `WeeklyWeightTrendCard` (`lib/features/dashboard/presentation/widgets/weekly_weight_trend_card.dart:31-131`), `WeeklyPaceChartCard` (`lib/features/dashboard/presentation/widgets/weekly_pace_chart_card.dart:44-180`), and `WeeklyWorkoutsChartCard` (`lib/features/dashboard/presentation/widgets/weekly_workouts_chart_card.dart:28-131`) all hardcode `Theme.of(context).colorScheme.primary` (including workouts, instead of `AppChartTheme.seriesWorkouts` / `tertiary`), `const TextStyle(fontSize: 10)` axis labels with fixed `reservedSize`, and `Colors.white` tooltip text on default `fl_chart` tooltip backgrounds. `WeeklyPaceChartCard` colors its target band with `colorScheme.tertiary.withValues(alpha: 0.18)` instead of `chartTheme.targetFill` and omits the dashed `chartTheme.targetBoundary` lines (`targetDashPattern`). None of the three charts expose a localized `Semantics` summary or reduce X-axis tick density under enlarged text.
- `test/features/dashboard/presentation/` contains no test files; dashboard UI is only covered indirectly by `test/features/auth/presentation/views/home_shell_screen_test.dart:125-284`.

### Key Discoveries:

- **Branch dependency**: `lib/core/design_system.dart` (`lib/core/theme/*`, `lib/core/widgets/*`, `lib/core/platform/*`, and `widgetbook/*`) lives on `feature/design-system` (`d41fc7d`, PR #38). Work for this change starts on a new branch created from `feature/design-system` and targets `feature/design-system` as its base.
- **`AppCard` header contract (`lib/core/widgets/app_card.dart:22-264`)**: `AppCard` already accepts `cardKey`, `title`, `subtitle`, `subtitleKey`, `leadingIcon` (`AppIcon?`), `headerTrailing` (`Widget?`), `variant` (`AppCardVariant.grouped`), `padding`, and `margin`, and automatically stacks its header vertically when `MediaQuery.textScalerOf(context).scale(1.0) >= 1.4` (`app_card.dart:195-243`).
- **`home_shell_screen_test.dart` invariants (`test/features/auth/presentation/views/home_shell_screen_test.dart:134-283`)**: Existing integration tests assert the presence of `Key('dashboard_kpi_pace_tile')`, `Key('dashboard_kpi_average_tile')`, `Key('dashboard_kpi_total_gain_tile')`, `Key('dashboard_kpi_workouts_tile')`, `Key('dashboard_weight_trend_card')`, `Key('dashboard_weekly_pace_card')`, `Key('dashboard_weekly_workouts_card')`, `Key('dashboard_pace_target_subtitle')`, `Key('weekly_pace_outdated_badge')`, and `Key('weight_trend_outdated_badge')`, and inspect `paceChart.data.rangeAnnotations.horizontalRangeAnnotations.single` (`y1: 0.1`, `y2: 0.3`).
- **`widgetbook_smoke_test.dart` invariant (`test/widgetbook/widgetbook_smoke_test.dart:49-130`)**: Every `WidgetbookUseCase` registered in `widgetbookDirectories` (`widgetbook/widgetbook_app.dart:14-18`) is automatically pumped under `(Locale('en'), AppTheme.light())`, `(Locale('pl'), AppTheme.dark())`, and `TextScaler.linear(2.0)` without Firebase initialized, so any `DashboardView` use case must wrap itself in a local `ProviderScope` with fake/static overrides.

## Desired End State

- `DashboardView` renders inside a `RefreshIndicator.adaptive` and centers its scrollable content within `ConstrainedBox(constraints: BoxConstraints(maxWidth: AppSpacing.dashboardMaxWidth))` (`1120px`) using responsive horizontal page gutters (`AppSpacing.pageInsetCompact = 16px` when `< 600px`, `AppSpacing.pageInsetWide = 24px` when `>= 600px`) and `AppSpacing.relatedGap` (`12px`) vertical spacing between sections.
- `DashboardCardShell` delegates its surface and header rendering to `AppCard(variant: AppCardVariant.grouped)`, places `AppStatusBadge(badgeKey: outdatedBadgeKey, label: context.l10n.dashboardOutdatedBadge, tone: AppFeedbackTone.warning, icon: AppIcon.warning)` in `headerTrailing` when `isOutdated` is true, constrains non-chart states (`loading`, `error`, `empty`, `unconfigured`) with `BoxConstraints(minHeight: contentHeight)` so `2.0x` scaled text never overflows, renders a platform-adaptive spinner (`CupertinoActivityIndicator` on iOS modes, `CircularProgressIndicator` on Material), and uses `AppButton(key: retryButtonKey, label: context.l10n.retry, variant: AppButtonVariant.tonal, icon: AppIcon.retry, onPressed: onRetry)` for error recovery.
- `DashboardKpiRow` builds each metric tile with `AppCard(variant: AppCardVariant.grouped)`, displays metric values with `theme.textTheme.headlineMedium` (tabular figures) without `FittedBox`, allows titles and subtitles to wrap naturally without a fixed `18px` `SizedBox`, highlights `dashboard_incomplete_week_badge` with `AppStatusBadge(tone: AppFeedbackTone.info)` and workout sync errors with `AppStatusBadge(tone: AppFeedbackTone.error)`, and adapts its grid across 3 layout tiers: `1×4` vertical stack when `textScale >= 1.4` or width `< 360px`, `2×2` equal-height rows (`IntrinsicHeight`) when `< 840px`, and `4×1` equal-height row (`IntrinsicHeight`) when `>= 840px` and `textScale < 1.4`.
- `WeeklyWeightTrendCard`, `WeeklyPaceChartCard`, and `WeeklyWorkoutsChartCard` pass `AppIcon.weight`, `AppIcon.target`, and `AppIcon.workout` to `DashboardCardShell.leadingIcon`, consume `AppChartTheme.of(context)` for series colors (`seriesWeight`, `seriesPace`, `seriesWorkouts`), stroke/bar widths (`lineStrokeWidth`, `barWidth`), grid lines (`gridLine`), axis labels (`axisLabel` with `textTheme.labelSmall`), and tooltips (`tooltipSurface` / `onTooltipSurface`), render `WeeklyPaceChartCard`'s target band with `chartTheme.targetFill` (`withValues(alpha: 0.55)`) plus dashed `HorizontalLine` boundaries (`chartTheme.targetBoundary`, `chartTheme.targetDashPattern`), scale axis `reservedSize` and step bottom X-axis ticks from every 2nd week to every 4th week when `textScale >= 1.3`, and wrap each chart in a localized `Semantics` summary.
- `test/features/dashboard/presentation/` contains dedicated widget and accessibility tests, and `widgetbook/` includes a `Dashboard` category (`widgetbook/use_cases/dashboard_use_cases.dart`) verified by `test/widgetbook/widgetbook_smoke_test.dart`.

## What We're NOT Doing

- Not modifying `HomeShellScreen` (`lib/features/auth/presentation/views/home_shell_screen.dart`) or Profile/Weights/Workouts tab views (scoped to their own feature migrations).
- Not modifying `WeeklyProgressCalculator`, `WeeklyProgressOverviewEntity`, `DashboardState`, or `DashboardViewModel` business logic.
- Not introducing pace status classification verdicts (`"prawidłowe"`, `"za szybkie"`, `"za wolne"`, `"stagnacja"`) or green/red bar coloring (blocked roadmap slice S-07).
- Not placing any Widgetbook files or `widgetbook` imports inside `lib/` (per `context/foundation/lessons.md`).
- Not adding new ARB localization keys unless strictly required; chart semantics reuse existing localized `AppLocalizations` getters and `WeekDateUtils` formatters.

## Implementation Approach

We execute the migration in three incremental phases on a branch created from `feature/design-system`. Phase 1 migrates the layout container (`DashboardView`), card shell (`DashboardCardShell`), and KPI grid (`DashboardKpiRow`) to `lib/core/design_system.dart` tokens and primitives while preserving all existing widget keys required by `home_shell_screen_test.dart`. Phase 2 migrates the three `fl_chart` cards (`WeeklyWeightTrendCard`, `WeeklyPaceChartCard`, `WeeklyWorkoutsChartCard`) to `AppChartTheme`, adds dashed target-range boundaries, dynamic axis sizing/tick stepping for enlarged text, and screen-reader `Semantics` summaries. Phase 3 adds comprehensive widget/accessibility tests in `test/features/dashboard/presentation/` and registers `dashboardCategory` in `widgetbook/`.

## Critical Implementation Details

- **Branch baseline**: Before making any code edits in Phase 1, create and switch to a new branch based on `feature/design-system` (e.g., `git checkout -b feature/dashboard-design-system feature/design-system`) because `lib/core/design_system.dart` and `widgetbook/` do not exist on `main` (`1229a4f`) yet.
- **Target band compatibility with `home_shell_screen_test.dart`**: `test/features/auth/presentation/views/home_shell_screen_test.dart:279-282` inspects `paceChart.data.rangeAnnotations.horizontalRangeAnnotations.single` and checks `y1 == 0.1` and `y2 == 0.3`. Keep `HorizontalRangeAnnotation(y1: target.minWeeklyGainKg, y2: target.maxWeeklyGainKg, color: chartTheme.targetFill.withValues(alpha: 0.55))` inside `rangeAnnotations.horizontalRangeAnnotations` and add the two dashed boundary lines (`minWeeklyGainKg`, `maxWeeklyGainKg`) inside `extraLinesData: ExtraLinesData(horizontalLines: [...])`.
- **Self-contained Widgetbook use cases**: `test/widgetbook/widgetbook_smoke_test.dart` pumps every `WidgetbookUseCase` in `widgetbookDirectories` inside `tester.pumpApp(...)` with no Firebase or repository overrides. Any use case in `widgetbook/use_cases/dashboard_use_cases.dart` that mounts `DashboardView` must wrap it in a local `ProviderScope` overriding `dashboardViewModelProvider` with a deterministic static notifier so smoke tests never touch `FirebaseAuth` or `FirebaseDatabase`.

## Phase 1: Dashboard Card Shell, KPI Header & Responsive View Layout

### Overview

Create the working branch from `feature/design-system` and migrate `DashboardCardShell`, `DashboardKpiRow`, and `DashboardView` to `lib/core/design_system.dart` tokens and adaptive primitives (`AppCard`, `AppStatusBadge`, `AppButton`, `AppSpacing`, `AppIcons`, `PresentationCapabilities`, and `RefreshIndicator.adaptive`).

### Changes Required:

#### 1. Dashboard Card Shell

**File**: `lib/features/dashboard/presentation/widgets/dashboard_card_shell.dart`

**Intent**: Replace the bespoke Material `Card`, header `Row`, `errorContainer` outdated pill, fixed `220px` non-chart `SizedBox`, and raw `FilledButton.tonal` with `AppCard`, `AppStatusBadge` (`AppFeedbackTone.warning`), platform-adaptive activity indicator, `ConstrainedBox(minHeight: contentHeight)`, and `AppButton`.

**Contract**:
- Add optional `final AppIcon? leadingIcon;` field to `DashboardCardShell` and forward `cardKey`, `title`, `subtitle`, `subtitleKey`, `leadingIcon`, and `headerTrailing` to `AppCard(variant: AppCardVariant.grouped)`.
- Omit outer horizontal/vertical card margins (`margin: EdgeInsets.zero`) so `DashboardView` owns outer page gutters and vertical item spacing (`07_design_system.md` §5).
- When `isOutdated` is true, pass `AppStatusBadge(badgeKey: outdatedBadgeKey, label: context.l10n.dashboardOutdatedBadge, tone: AppFeedbackTone.warning, icon: AppIcon.warning)` as `AppCard.headerTrailing`.
- In `_buildBody(BuildContext context)`:
  - `DashboardCardStatus.loading`: wrap in `ConstrainedBox(constraints: BoxConstraints(minHeight: contentHeight))` with centered `CupertinoActivityIndicator` when `PresentationCapabilities.resolve(context).platformMode != AdaptivePlatformMode.material` and `CircularProgressIndicator` otherwise.
  - `DashboardCardStatus.error`: wrap in `ConstrainedBox(constraints: BoxConstraints(minHeight: contentHeight))` with centered `Column` containing `Icon(AppIcons.resolve(context, AppIcon.error), color: theme.colorScheme.error, size: AppIcons.normalSize)`, `Text(errorMessage ?? '', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error))`, and (when `onRetry != null`) `AppButton(key: retryButtonKey, label: context.l10n.retry, variant: AppButtonVariant.tonal, icon: AppIcon.retry, onPressed: onRetry)`.
  - `DashboardCardStatus.empty` and `DashboardCardStatus.unconfigured`: wrap in `ConstrainedBox(constraints: BoxConstraints(minHeight: contentHeight))` with centered `Text` (`emptyMessageKey` / `unconfiguredMessageKey`) styled with `theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)`.
  - `DashboardCardStatus.loaded`: return `child`.

#### 2. Dashboard KPI Row & Stat Tiles

**File**: `lib/features/dashboard/presentation/widgets/dashboard_kpi_row.dart`

**Intent**: Migrate `_StatTile` and `DashboardKpiRow` to `AppCard`, `textTheme.headlineMedium` (tabular figures), semantic `AppStatusBadge` pills for incomplete-week and sync-error states, and a 3-tier responsive layout (`1×4`, `2×2`, `4×1`) without `FittedBox` or fixed `18px` subtitle height.

**Contract**:
- Remove outer `Padding(padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0))` from `DashboardKpiRow` so `DashboardView` owns outer page gutters.
- Change `_buildPaceTile`, `_buildAverageTile`, `_buildTotalGainTile`, and `_buildWorkoutsTile` parameter types from `dynamic overview` to `WeeklyProgressOverviewEntity overview`.
- In `_buildAverageTile`: when `overview.isLatestWeekIncomplete` is true, set `subtitleWidget` to `AppStatusBadge(badgeKey: const Key('dashboard_incomplete_week_badge'), label: context.l10n.dashboardKpiAverageSubtitleIncomplete(overview.latestWeekLoggedDays), tone: AppFeedbackTone.info)`. Keep complete-week and date-range subtitles as `Text(..., style: theme.textTheme.bodyMedium)`.
- In `_buildWorkoutsTile`: when `state.workoutStatus == DashboardCardStatus.error`, set `subtitleWidget` to `AppStatusBadge(label: context.l10n.dashboardKpiWorkoutsSyncError, tone: AppFeedbackTone.error)`. Keep `loaded` and `unconfigured` subtitles as `Text(..., style: theme.textTheme.bodyMedium)`.
- In `_StatTile`:
  - Replace raw `Card` with `AppCard(cardKey: key, variant: AppCardVariant.grouped, padding: const EdgeInsets.all(AppSpacing.cardPadding), child: ...)` (preserving `Key('dashboard_kpi_pace_tile')`, `Key('dashboard_kpi_average_tile')`, `Key('dashboard_kpi_total_gain_tile')`, `Key('dashboard_kpi_workouts_tile')`).
  - Render `title` with `theme.textTheme.bodyMedium` (`colorScheme.onSurfaceVariant`), up to 2 lines (`maxLines: 2, overflow: TextOverflow.ellipsis`).
  - Render `value` directly with `theme.textTheme.headlineMedium` (which already includes `FontFeature.tabularFigures()` in `AppTheme`) with NO `FittedBox`.
  - Render `subtitle` directly below `const SizedBox(height: AppSpacing.space1)` with `DefaultTextStyle.merge(style: theme.textTheme.bodyMedium!)` and NO fixed `SizedBox(height: 18)`.
- Use `LayoutBuilder` + `MediaQuery.textScalerOf(context)` in `DashboardKpiRow`:
  - Tier 1 (`textScaler.scale(1.0) >= 1.4 || constraints.maxWidth < 360`): single-column `Column` of the 4 tiles separated by `const SizedBox(height: AppSpacing.relatedGap)`.
  - Tier 2 (`constraints.maxWidth >= AppSpacing.expandedBreakpoint`, i.e. `>= 840px`, and `textScale < 1.4`): single `IntrinsicHeight` `Row` of all 4 `Expanded` tiles separated by `const SizedBox(width: AppSpacing.relatedGap)`.
  - Tier 3 (default `< 840px` and `textScale < 1.4`): `Column` of two `IntrinsicHeight` `Row`s (`2×2` grid) separated by `AppSpacing.relatedGap` (`12px`), with `CrossAxisAlignment.stretch` on each `Row` so paired tiles match height.

#### 3. Dashboard View Responsive Container & Adaptive Refresh

**File**: `lib/features/dashboard/presentation/views/dashboard_view.dart`

**Intent**: Wrap the dashboard scroll view in `RefreshIndicator.adaptive`, enforce the `1120px` (`AppSpacing.dashboardMaxWidth`) content cap, and apply responsive outer page gutters (`AppSpacing.pageInsetCompact` vs `AppSpacing.pageInsetWide`) and `AppSpacing.relatedGap` section spacing.

**Contract**:
- Replace `RefreshIndicator(` with `RefreshIndicator.adaptive(`.
- Use `LayoutBuilder` to compute horizontal inset: `final horizontalInset = constraints.maxWidth >= AppSpacing.compactBreakpoint ? AppSpacing.pageInsetWide : AppSpacing.pageInsetCompact;`.
- Keep `ListView(key: const Key('dashboard_scroll_view'), physics: const AlwaysScrollableScrollPhysics(), ...)` and constrain its children within a centered `ConstrainedBox(constraints: const BoxConstraints(maxWidth: AppSpacing.dashboardMaxWidth))` (or dynamic horizontal padding `math.max(horizontalInset, (constraints.maxWidth - AppSpacing.dashboardMaxWidth) / 2 + horizontalInset)` on `ListView.padding` so the full viewport width remains scrollable while content is capped at `1120px` and padded by `horizontalInset` and `vertical: AppSpacing.space4`).
- Separate `DashboardKpiRow`, `WeeklyWeightTrendCard`, `WeeklyPaceChartCard`, and `WeeklyWorkoutsChartCard` by `const SizedBox(height: AppSpacing.relatedGap)`.

### Success Criteria:

#### Automated Verification:

- Branch is based on `feature/design-system` (`git merge-base --is-ancestor feature/design-system HEAD`)
- Static analysis passes with zero warnings: `flutter analyze`
- Code formatting check passes: `dart format --output=none --set-exit-if-changed lib test widgetbook`
- Existing Home shell and dashboard tests pass: `flutter test test/features/auth/presentation/views/home_shell_screen_test.dart test/features/dashboard/`

#### Manual Verification:

- Inspect Home tab on compact (`<600px`) and wide (`>=840px`) viewports: KPI tiles switch cleanly between `2×2` and `4×1` equal-height rows, and stack into `1×4` when text scale is `>=1.4x` with zero `FittedBox` shrinking or subtitle clipping.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Phase 2: Dashboard `fl_chart` Cards Tokenization, Target Band & Accessibility

### Overview

Migrate `WeeklyWeightTrendCard`, `WeeklyPaceChartCard`, and `WeeklyWorkoutsChartCard` to `AppChartTheme.of(context)` and `AppIcons`, add dashed `targetBoundary` lines to the pace chart, dynamically adapt axis `reservedSize` and bottom tick intervals under enlarged text (`textScale >= 1.3`), and wrap each chart in a localized `Semantics` summary.

### Changes Required:

#### 1. Shared Chart Axis, Tooltip & Semantics Helpers (or per-card alignment)

**File**: `lib/features/dashboard/presentation/widgets/weekly_weight_trend_card.dart`

**Intent**: Migrate `WeeklyWeightTrendCard` to `AppChartTheme.of(context)`, pass `leadingIcon: AppIcon.weight` to `DashboardCardShell`, replace hardcoded `fontSize: 10` and `Colors.white` tooltip styles with theme tokens, scale axis reserved space and bottom tick density with `TextScaler`, and add a localized `Semantics` wrapper.

**Contract**:
- Resolve `final chartTheme = AppChartTheme.of(context);`, `final textTheme = Theme.of(context).textTheme;`, and `final textScale = MediaQuery.textScalerOf(context).scale(1.0);`.
- Pass `leadingIcon: AppIcon.weight` to `DashboardCardShell`.
- Set `gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: chartTheme.gridLine, strokeWidth: 1))`.
- Style axis labels with `textTheme.labelSmall?.copyWith(color: chartTheme.axisLabel)`.
- Scale bottom `reservedSize` (`32.0 * math.min(textScale, 1.8)`) and left `reservedSize` (`48.0 * math.min(textScale, 1.6)`). When `textScale >= 1.3`, render bottom X-axis labels every 4th week (`index % 4 == 0`) instead of every 2nd week (`index.isEven`).
- Configure `LineTouchTooltipData(getTooltipColor: (_) => chartTheme.tooltipSurface, ...)` with tooltip text styled using `textTheme.labelSmall?.copyWith(color: chartTheme.onTooltipSurface, fontWeight: FontWeight.w600)`.
- Configure `LineChartBarData` with `color: chartTheme.seriesWeight` and `barWidth: chartTheme.lineStrokeWidth`.
- Wrap the `SizedBox(height: 220, child: LineChart(...))` in a `Semantics(container: true, label: ...)` summarizing the chart title and each logged week's date range and formatted weight (`context.l10n.dashboardWeightMetric`).

#### 2. Weekly Pace Chart Card

**File**: `lib/features/dashboard/presentation/widgets/weekly_pace_chart_card.dart`

**Intent**: Migrate `WeeklyPaceChartCard` to `AppChartTheme.of(context)`, pass `leadingIcon: AppIcon.target`, render the target range with `chartTheme.targetFill` plus dashed `chartTheme.targetBoundary` lines (`targetDashPattern`), adapt axis sizing/tick density for enlarged text, and expose a localized `Semantics` summary.

**Contract**:
- Resolve `final chartTheme = AppChartTheme.of(context);`, `final textTheme = Theme.of(context).textTheme;`, and `final textScale = MediaQuery.textScalerOf(context).scale(1.0);`.
- Pass `leadingIcon: AppIcon.target` to `DashboardCardShell`.
- Set `gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: chartTheme.gridLine, strokeWidth: 1))`.
- Keep `rangeAnnotations` with `HorizontalRangeAnnotation(y1: target.minWeeklyGainKg, y2: target.maxWeeklyGainKg, color: chartTheme.targetFill.withValues(alpha: 0.55))` when `target != null`.
- Add `extraLinesData: ExtraLinesData(horizontalLines: [HorizontalLine(y: 0, color: chartTheme.gridLine, strokeWidth: 1), if (target != null) ...[HorizontalLine(y: target.minWeeklyGainKg, color: chartTheme.targetBoundary, strokeWidth: 1.5, dashArray: chartTheme.targetDashPattern), HorizontalLine(y: target.maxWeeklyGainKg, color: chartTheme.targetBoundary, strokeWidth: 1.5, dashArray: chartTheme.targetDashPattern)]])`.
- Style axis labels with `textTheme.labelSmall?.copyWith(color: chartTheme.axisLabel)`, scale bottom `reservedSize` (`32.0 * math.min(textScale, 1.8)`) and left `reservedSize` (`58.0 * math.min(textScale, 1.6)`), and step bottom ticks by `index % 4 == 0` when `textScale >= 1.3` (`index.isEven` otherwise).
- Configure `BarTouchTooltipData(getTooltipColor: (_) => chartTheme.tooltipSurface, ...)` with `chartTheme.onTooltipSurface` text.
- Configure `BarChartRodData` with `color: chartTheme.seriesPace`, `width: weeks[i].paceKgPerWeek == null ? 0 : chartTheme.barWidth`, and `borderRadius: const BorderRadius.vertical(top: Radius.circular(4), bottom: Radius.circular(4))`.
- Wrap the chart in a `Semantics(container: true, label: ...)` summarizing the chart title, target range subtitle (if configured), and each logged week's date range and formatted pace (`context.l10n.dashboardPaceMetric`).

#### 3. Weekly Workouts Chart Card

**File**: `lib/features/dashboard/presentation/widgets/weekly_workouts_chart_card.dart`

**Intent**: Migrate `WeeklyWorkoutsChartCard` to `AppChartTheme.of(context)` (`seriesWorkouts` / `tertiary`), pass `leadingIcon: AppIcon.workout`, adapt axis sizing/tick density for enlarged text, and wrap in a localized `Semantics` summary.

**Contract**:
- Resolve `final chartTheme = AppChartTheme.of(context);`, `final textTheme = Theme.of(context).textTheme;`, and `final textScale = MediaQuery.textScalerOf(context).scale(1.0);`.
- Pass `leadingIcon: AppIcon.workout` to `DashboardCardShell`.
- Set `gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: chartTheme.gridLine, strokeWidth: 1))`.
- Style axis labels with `textTheme.labelSmall?.copyWith(color: chartTheme.axisLabel)`, scale bottom `reservedSize` (`32.0 * math.min(textScale, 1.8)`) and left `reservedSize` (`28.0 * math.min(textScale, 1.6)`), and step bottom ticks by `index % 4 == 0` when `textScale >= 1.3` (`index.isEven` otherwise).
- Configure `BarTouchTooltipData(getTooltipColor: (_) => chartTheme.tooltipSurface, ...)` with `chartTheme.onTooltipSurface` text.
- Configure `BarChartRodData` with `color: chartTheme.seriesWorkouts`, `width: chartTheme.barWidth`, and `borderRadius: const BorderRadius.vertical(top: Radius.circular(4))`.
- Wrap the chart in a `Semantics(container: true, label: ...)` summarizing the chart title and weekly workout counts (`context.l10n.dashboardWorkoutsTooltip`).

### Success Criteria:

#### Automated Verification:

- Static analysis passes: `flutter analyze`
- Code formatting check passes: `dart format --output=none --set-exit-if-changed lib test widgetbook`
- Home shell and dashboard tests pass (including `rangeAnnotations` assertion at `home_shell_screen_test.dart:279-282`): `flutter test test/features/auth/presentation/views/home_shell_screen_test.dart`

#### Manual Verification:

- Inspect the 3 dashboard charts in Light, Dark, and High-Contrast themes: Weight Trend and Weekly Pace use `seriesWeight`/`seriesPace` (`primary`), Workouts per Week uses `seriesWorkouts` (`tertiary`), Weekly Pace shows the `targetFill` band with dashed `targetBoundary` lines, tooltips use `tooltipSurface`/`onTooltipSurface`, and `2.0x` text scale steps bottom ticks to every 4th week without label collision.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Phase 3: Dashboard Widget/Accessibility Test Suite & Widgetbook Catalog

### Overview

Populate `test/features/dashboard/presentation/` with widget and accessibility tests covering `DashboardCardShell`, `DashboardKpiRow`, `WeeklyWeightTrendCard`, `WeeklyPaceChartCard`, `WeeklyWorkoutsChartCard`, and `DashboardView`, and add a `Dashboard` category to `widgetbook/` (`widgetbook/use_cases/dashboard_use_cases.dart` and `widgetbook/widgetbook_app.dart`).

### Changes Required:

#### 1. Dashboard Card Shell & KPI Row Widget Tests

**File**: `test/features/dashboard/presentation/widgets/dashboard_card_shell_and_kpi_row_test.dart`

**Intent**: Verify `DashboardCardShell` and `DashboardKpiRow` contracts across all async states, status badges, 3 platform modes (`material`, `cupertinoClassic`, `cupertinoLiquidGlass`), English/Polish locales, `2.0x` `TextScaler`, and `<600px` / `>=840px` responsive breakpoints.

**Contract**:
- Test `DashboardCardShell` across `loading` (`CircularProgressIndicator` on Material, `CupertinoActivityIndicator` on Cupertino modes), `error` (`AppButton` retry callback + `androidMinTapTarget` / `iosMinTapTarget` size), `empty`, `unconfigured`, and `loaded` (with `isOutdated: true` rendering `AppStatusBadge` in `warning` tone and `leadingIcon`).
- Test `DashboardKpiRow` across populated, incomplete current week (`Key('dashboard_incomplete_week_badge')` rendered as `AppStatusBadge` with `AppFeedbackTone.info`), empty (`Log 2+ weeks`), workout `unconfigured`, and workout `error` (`AppStatusBadge` with `AppFeedbackTone.error`) states.
- Verify `headlineMedium` tabular figures (`no FittedBox`), `1×4` single-column reflow at `TextScaler.linear(2.0)` in Polish (`Locale('pl')`) with zero overflow exceptions, `2×2` grid at `400px` width, and `4×1` single-row layout at `960px` width.

#### 2. Dashboard Chart Cards & View Widget Tests

**File**: `test/features/dashboard/presentation/views/dashboard_view_and_charts_test.dart`

**Intent**: Verify `WeeklyWeightTrendCard`, `WeeklyPaceChartCard`, `WeeklyWorkoutsChartCard`, and `DashboardView` token binding (`AppChartTheme`), target-band + dashed boundary lines, dynamic tick density at `2.0x` text scale, screen-reader `Semantics` labels, `RefreshIndicator.adaptive`, and `1120px` max-width layout.

**Contract**:
- Assert `WeeklyWeightTrendCard` binds `chartTheme.seriesWeight`, `chartTheme.lineStrokeWidth`, `chartTheme.gridLine`, and `chartTheme.tooltipSurface`, and exposes a non-empty `Semantics` label containing formatted weekly weights.
- Assert `WeeklyPaceChartCard` binds `chartTheme.seriesPace`, `chartTheme.barWidth`, `chartTheme.targetFill` on `HorizontalRangeAnnotation`, and two dashed `HorizontalLine`s (`chartTheme.targetBoundary`, `chartTheme.targetDashPattern`) in `extraLinesData.horizontalLines` when `gainTarget` is present.
- Assert `WeeklyWorkoutsChartCard` binds `chartTheme.seriesWorkouts` (`colorScheme.tertiary`, distinct from `primary`) and `chartTheme.barWidth`.
- Assert bottom axis tick count drops from 6 ticks (`index.isEven`) at `1.0x` text scale to 3 ticks (`index % 4 == 0`) at `TextScaler.linear(2.0)` with zero layout exceptions.
- Assert `DashboardView` renders `RefreshIndicator` (`RefreshIndicator.adaptive`), triggers `refreshAll()` on pull-to-refresh, and caps content width at `AppSpacing.dashboardMaxWidth` (`1120.0`).

#### 3. Widgetbook Dashboard Category & Smoke Test Registration

**File**: `widgetbook/use_cases/dashboard_use_cases.dart` and `widgetbook/widgetbook_app.dart`

**Intent**: Add a `Dashboard` category to the Widgetbook catalog showcasing `DashboardKpiRow`, `DashboardCardShell` async states, the 3 `fl_chart` cards, and the full responsive `DashboardView` with interactive knobs and self-contained `ProviderScope` overrides.

**Contract**:
- Create `widgetbook/use_cases/dashboard_use_cases.dart` exporting `final dashboardCategory = WidgetbookCategory(name: 'Dashboard', children: [...])` with components for `DashboardKpiRow`, `DashboardCardShell`, `Dashboard Charts`, and `DashboardView`.
- For the `DashboardView` use case, wrap `DashboardView` in a local `ProviderScope` overriding `dashboardViewModelProvider` (using a static `DashboardViewModel` subclass returning a deterministic `DashboardState` driven by Widgetbook knobs) so `test/widgetbook/widgetbook_smoke_test.dart` runs cleanly without Firebase.
- Register `dashboardCategory` in `widgetbookDirectories` in `widgetbook/widgetbook_app.dart:14-18`.

### Success Criteria:

#### Automated Verification:

- Static analysis passes: `flutter analyze`
- Code formatting check passes: `dart format --output=none --set-exit-if-changed lib test widgetbook`
- Dashboard presentation widget and accessibility tests pass: `flutter test test/features/dashboard/`
- Widgetbook smoke tests pass across EN/PL, Light/Dark, and `2.0x` text scale: `flutter test test/widgetbook/widgetbook_smoke_test.dart`
- Full repository test suite passes: `flutter test`

#### Manual Verification:

- Run `flutter run -t widgetbook/main_widgetbook.dart -d chrome` and verify the new `Dashboard` category renders `DashboardKpiRow`, `DashboardCardShell`, the 3 chart cards, and `DashboardView` across Light/Dark/High-Contrast themes, English/Polish locales, `1.0x`–`2.0x` text scales, and the 3 platform capability modes.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Testing Strategy

### Unit & Widget Tests:

- `test/features/dashboard/presentation/widgets/dashboard_card_shell_and_kpi_row_test.dart`:
  - `DashboardCardShell` rendering across `loading` (Material vs Cupertino activity indicators), `error` (`AppButton` retry + tap target size), `empty`, `unconfigured`, and `loaded` (`AppCard` + `AppStatusBadge` warning pill when `isOutdated: true` + `leadingIcon`).
  - `DashboardKpiRow` rendering of `headlineMedium` tabular figures, `AppStatusBadge` for `dashboard_incomplete_week_badge` (`info`) and workout sync error (`error`), and responsive layout transitions (`1×4` at `2.0x` text scale or `<360px`, `2×2` at `<840px`, `4×1` at `>=840px`).
- `test/features/dashboard/presentation/views/dashboard_view_and_charts_test.dart`:
  - `AppChartTheme` token assertions on `WeeklyWeightTrendCard` (`seriesWeight`), `WeeklyPaceChartCard` (`seriesPace`, `targetFill`, dashed `targetBoundary` lines), and `WeeklyWorkoutsChartCard` (`seriesWorkouts` / `tertiary`).
  - Dynamic bottom X-axis tick density (`6` ticks at `1.0x` scale vs `3` ticks at `2.0x` scale) and screen-reader `Semantics` summary strings in EN and PL.
  - `DashboardView` pull-to-refresh (`RefreshIndicator.adaptive`), `1120px` max-width constraint, and responsive `16px`/`24px` page gutters.

### Integration & Smoke Tests:

- `test/features/auth/presentation/views/home_shell_screen_test.dart`: verifies end-to-end Home tab rendering, tab switching, and stale target-band refresh behavior.
- `test/widgetbook/widgetbook_smoke_test.dart`: verifies all `dashboardCategory` use cases pump without exceptions under `(en, light)`, `(pl, dark)`, and `TextScaler.linear(2.0)`.

### Manual Testing Steps:

1. Launch Widgetbook (`flutter run -t widgetbook/main_widgetbook.dart -d chrome`) and open the `Dashboard` category.
2. Toggle Theme (`Light`, `Dark`, `High Contrast Light`, `High Contrast Dark`), Locale (`en`, `pl`), Text Scale (`1.0`, `1.3`, `1.6`, `2.0`), and Platform Mode (`Material 3`, `Cupertino Classic`, `Cupertino Liquid Glass`).
3. Resize the browser viewport across `<600px`, `600–839px`, and `>=840px` (`>1120px`) to confirm responsive gutters, `4×1` KPI header at `>=840px`, `1×4` KPI stack at `>=1.4x` text scale, and `1120px` dashboard content cap.

## Performance Considerations

- Dashboard charts and KPI cards remain opaque (`AppCardVariant.grouped` using `surfaceContainerLow`) with zero blur shaders or platform views per card (`07_design_system.md` §7), avoiding GPU overdraw or platform-view scrolling overhead.
- `IntrinsicHeight` is used only on the 1 or 2 KPI header rows (at most 4 lightweight `AppCard` text tiles) and never on `fl_chart` canvases or long lists.

## Migration Notes

- Remove any leftover `.DS_Store` files in `test/features/dashboard/presentation/` when adding the new test files.
- Keep all existing widget `Key`s in `DashboardView`, `DashboardCardShell`, `DashboardKpiRow`, and the three chart cards intact so existing integration tests require zero key changes.

## References

- Change identity: `context/changes/dashboard-design-system/change.md`
- Design system specification: `context/documentation/07_design_system.md`
- Design system implementation plan: `context/changes/design-system/plan.md`
- Prior dashboard slice archive: `context/archive/2026-10-12-weekly-progress-overview/plan.md`
- Team lessons: `context/foundation/lessons.md`

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands. Do not rename step titles. See `references/progress-format.md`.

### Phase 1: Dashboard Card Shell, KPI Header & Responsive View Layout

#### Automated

- [x] 1.1 Branch is based on `feature/design-system` (`git merge-base --is-ancestor feature/design-system HEAD`) — 760a380
- [x] 1.2 Static analysis passes with zero warnings: `flutter analyze` — 760a380
- [x] 1.3 Code formatting check passes: `dart format --output=none --set-exit-if-changed lib test widgetbook` — 760a380
- [x] 1.4 Existing Home shell and dashboard tests pass: `flutter test test/features/auth/presentation/views/home_shell_screen_test.dart test/features/dashboard/` — 760a380

#### Manual

- [x] 1.5 Inspect Home tab on compact (`<600px`) and wide (`>=840px`) viewports: KPI tiles switch cleanly between `2×2` and `4×1` equal-height rows, and stack into `1×4` when text scale is `>=1.4x` with zero `FittedBox` shrinking or subtitle clipping. — 760a380

### Phase 2: Dashboard `fl_chart` Cards Tokenization, Target Band & Accessibility

#### Automated

- [x] 2.1 Static analysis passes: `flutter analyze` — d468f25
- [x] 2.2 Code formatting check passes: `dart format --output=none --set-exit-if-changed lib test widgetbook` — d468f25
- [x] 2.3 Home shell and dashboard tests pass (including `rangeAnnotations` assertion at `home_shell_screen_test.dart:279-282`): `flutter test test/features/auth/presentation/views/home_shell_screen_test.dart` — d468f25

#### Manual

- [x] 2.4 Inspect the 3 dashboard charts in Light, Dark, and High-Contrast themes: Weight Trend and Weekly Pace use `seriesWeight`/`seriesPace` (`primary`), Workouts per Week uses `seriesWorkouts` (`tertiary`), Weekly Pace shows the `targetFill` band with dashed `targetBoundary` lines, tooltips use `tooltipSurface`/`onTooltipSurface`, and `2.0x` text scale steps bottom ticks to every 4th week without label collision. — d468f25

### Phase 3: Dashboard Widget/Accessibility Test Suite & Widgetbook Catalog

#### Automated

- [x] 3.1 Static analysis passes: `flutter analyze` — e6c161d
- [x] 3.2 Code formatting check passes: `dart format --output=none --set-exit-if-changed lib test widgetbook` — e6c161d
- [x] 3.3 Dashboard presentation widget and accessibility tests pass: `flutter test test/features/dashboard/` — e6c161d
- [x] 3.4 Widgetbook smoke tests pass across EN/PL, Light/Dark, and `2.0x` text scale: `flutter test test/widgetbook/widgetbook_smoke_test.dart` — e6c161d
- [x] 3.5 Full repository test suite passes: `flutter test` — e6c161d

#### Manual

- [x] 3.6 Run `flutter run -t widgetbook/main_widgetbook.dart -d chrome` and verify the new `Dashboard` category renders `DashboardKpiRow`, `DashboardCardShell`, the 3 chart cards, and `DashboardView` across Light/Dark/High-Contrast themes, English/Polish locales, `1.0x`–`2.0x` text scales, and the 3 platform capability modes. — e6c161d
