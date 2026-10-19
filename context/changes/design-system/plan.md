# Shared Flutter Design System Implementation Plan

## Overview

Implement Bulk Tempo's foundational design system as specified in `context/documentation/07_design_system.md`: semantic color, chart, spacing, shape, motion, and icon tokens (`lib/core/theme/`), a deterministic platform and accessibility capability boundary (`lib/core/platform/presentation_capabilities.dart`), seven app-owned adaptive component wrappers encapsulating `adaptive_platform_ui` (`lib/core/widgets/`), root Material 3 and Cupertino theme wiring (`lib/app/app.dart` and `test/test_helpers/pump_app.dart`), and a manual Widgetbook 3.25.x catalog (`lib/widgetbook/main_widgetbook.dart`) with automated verification—without modifying existing feature screens under `lib/features/**`.

## Current State Analysis

The application currently uses an inline `ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true)` in `lib/app/app.dart:21-24` with no dark theme, high-contrast theme, `CupertinoThemeData` projection, or `ThemeExtension` registrations. Neither `lib/core/theme/`, `lib/core/platform/`, `lib/core/widgets/`, nor `lib/widgetbook/` exists yet, and `pubspec.yaml:9-34` does not include `adaptive_platform_ui`, `cupertino_icons`, or `widgetbook`.

### Key Discoveries:

- **Root & Test Harness Theme Gaps**: `BulkTempoApp` (`lib/app/app.dart:19-34`) configures only a light Material theme. `PumpAppExtension.pumpApp` (`test/test_helpers/pump_app.dart:8-24`, called 76 times across 9 test files) and `test/app/router/app_router_test.dart:70,98,128,162,207,261` mount a bare `MaterialApp` / `MaterialApp.router` without production themes or extensions.
- **Strict Clean Architecture & Linter Rules**: `context/documentation/01_architecture_overview.md:56` prohibits `lib/core/` from importing any `lib/features/` file. `analysis_options.yaml:1-15` enables `flutter_lints` (`strict-casts`, `strict-inference`, `strict-raw-types`, and `depend_on_referenced_packages` for files under `lib/`).
- **Platform & Accessibility Detection**: `ios/Runner/AppDelegate.swift:4-16` uses `FlutterImplicitEngineDelegate` with no custom platform channel, and `ios/Runner.xcodeproj/project.pbxproj:476` sets `IPHONEOS_DEPLOYMENT_TARGET = 15.0`. Flutter exposes iOS Reduce Motion on `WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.reduceMotion` separately from `MediaQuery.disableAnimationsOf(context)`.
- **Future Feature Migration Seams**: `HomeShellScreen` (`lib/features/auth/presentation/views/home_shell_screen.dart:23-47,275-327`), `WeightEntryBottomSheet` (`lib/features/weight/presentation/widgets/weight_entry_bottom_sheet.dart:309-350`), `WorkoutDetailBottomSheet` (`lib/features/workout/presentation/widgets/workout_detail_bottom_sheet.dart:88-172,221-255`), and `DashboardCardShell` (`lib/features/dashboard/presentation/widgets/dashboard_card_shell.dart:10-190`) require `AppSheetFrame` to support `PopScope` + overscroll/drag dismissal guards and optional draggable sheets, and `AppNavigationShell` to support 4 destinations, toolbar actions, optional `floatingActionButton` clearance, and a `>=840` logical-pixel `NavigationRail` layout.

## Desired End State

A complete, tested design system foundation in `lib/core/` and `lib/widgetbook/` where:
1. `BulkTempoApp` (`lib/app/app.dart`) and `pumpApp` (`test/test_helpers/pump_app.dart`) wire `AppTheme.light()`, `AppTheme.dark()`, `AppTheme.highContrastLight()`, and `AppTheme.highContrastDark()` with `ThemeMode.system` (defaulting to `ThemeMode.light` in `pumpApp` for existing test stability) and inject a coordinated `CupertinoTheme` via `MaterialApp.builder`.
2. `lib/core/platform/presentation_capabilities.dart` provides an immutable `PresentationCapabilities` model and Riverpod `presentationCapabilitiesProvider` resolving 3 platform rendering modes (`material`, `cupertinoClassic` for iOS 15–25 or web/headless test previews, and `cupertinoLiquidGlass` for iOS 26+ native views) alongside normalized `reduceMotion`, `highContrast`, and `reduceTransparency` flags.
3. All seven shared primitives (`AppButton`, `AppTextField`, `AppCard`, `AppFeedback`, `AppDialog`, `AppSheetFrame`, `AppNavigationShell`) encapsulate `adaptive_platform_ui` behind app-owned APIs, enforce opaque data surfaces, paired foreground/background colors, and accessible tap targets (`48×48` on Android/web, `44×44` on iOS).
4. `lib/widgetbook/main_widgetbook.dart` catalogs all tokens and primitives across the 7-state matrix (`default`, `pressed`, `focused`, `hovered`, `disabled`, `busy`, `error`, plus async content states for cards/feedback), English and Polish locales, light/dark/high-contrast themes, `2.0x` text scale, and platform capability overrides.
5. `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, and `flutter test` pass with zero warnings or errors.

## What We're NOT Doing

- **No modifications to existing feature screens or widgets (`lib/features/**`)**: Migrating `HomeShellScreen`, `WeightEntryBottomSheet`, `AuthButton`, `AuthTextField`, `DashboardCardShell`, `DashboardKpiRow`, `WorkoutDetailBottomSheet`, or `GainTargetView` is deferred to subsequent `/10x-ui` feature changes.
- **No user-selectable Theme Mode UI or persistence**: `BulkTempoApp` uses `ThemeMode.system` only; no Profile tab theme selector card or `FlutterSecureStorage` theme preference notifier is added.
- **No native Swift `MethodChannel` in `ios/Runner/AppDelegate.swift`**: OS version and capability detection use pure Dart (`Platform.operatingSystemVersion` + `TargetPlatform` + `MediaQuery` / `AccessibilityFeatures`) with Riverpod override support.
- **No standalone `material_ui` / `cupertino_ui` package migration or `dynamic_color` adoption**: The codebase retains standard `package:flutter/material.dart` and `package:flutter/cupertino.dart` SDK imports and a deterministic `#673AB7` `tonalSpot` brand scheme.
- **No committed OS-specific PNG golden files**: Visual and structural verification in `flutter test` uses deterministic token contrast checks, 3-mode widget tests, Flutter `AccessibilityGuideline` assertions, `2.0x` `TextScaler` reflow tests, and a Widgetbook use-case smoke test suite.
- **No contextual pace assessment status thresholds**: Chart tokens remain neutral (`seriesWeight` and `seriesPace` use `primary`; `seriesWorkouts` uses `tertiary`; `targetFill` uses `secondaryContainer` with `onSecondaryContainer` boundary) without inventing positive/negative green/red rules.

## Implementation Approach

Build bottom-up inside `lib/core/` and `lib/widgetbook/` across four incremental phases:
1. Establish the dependency baseline, pure-Dart `PresentationCapabilities` adapter, token classes, `ThemeExtension` types (`AppSemanticColors`, `AppChartTheme`), and Material/Cupertino `AppTheme` factories, wiring them into `lib/app/app.dart`, `test/test_helpers/pump_app.dart`, and `test/app/router/app_router_test.dart`.
2. Build the leaf form, surface, and feedback primitives (`AppButton`, `AppTextField`, `AppCard`, `AppFeedback`) using 3-tier dispatch (`material`, `cupertinoClassic`, `cupertinoLiquidGlass`).
3. Build the composite overlay and navigation shell primitives (`AppDialog`, `AppSheetFrame`, `AppNavigationShell`) with full dismissal-guard, draggable-sheet, FAB clearance, and responsive `NavigationRail` support so future feature migrations are drop-in replacements.
4. Assemble the manual Widgetbook 3.25.x catalog in `lib/widgetbook/` and lock in automated smoke and accessibility verification.

## Critical Implementation Details

- **Linter compatibility for `lib/widgetbook/` (`depend_on_referenced_packages`)**: Because `widgetbook: ^3.25.0` is added under `dev_dependencies` in `pubspec.yaml` while the catalog entrypoint lives at `lib/widgetbook/main_widgetbook.dart`, `package:flutter_lints/flutter.yaml` will flag `depend_on_referenced_packages` on imports of `package:widgetbook/widgetbook.dart` inside `lib/widgetbook/` unless suppressed. Configure `analysis_options.yaml` (or file-level `// ignore_for_file: depend_on_referenced_packages` in `lib/widgetbook/`) so `flutter analyze` passes cleanly without promoting `widgetbook` to production `dependencies`.
- **Headless test & web fallback for `adaptive_platform_ui` native views**: On iOS 26+, `adaptive_platform_ui` renders native UIKit platform views (`UiKitView`) for glass toolbars, tab bars, and buttons. Neither Flutter's headless widget test runner nor Chrome (`flutter run -d chrome`) can instantiate native iOS `UiKitView`s. `PresentationCapabilities` must therefore gate `cupertinoLiquidGlass` on ` isIos26OrNewer && supportsNativeIosPlatformViews` (true on real iOS runtime when `!kIsWeb` and not in headless widget test environment unless `forceNativeIosViews: true` is explicitly passed in a capability override), falling back to `cupertinoClassic` in web Widgetbook and standard widget tests so iOS previews and assertions remain interactive and deterministic.
- **Safe `ThemeExtension` resolution in tests**: Even after updating `pump_app.dart` and `app_router_test.dart` to supply `AppTheme.light()`, provide convenience accessors `AppSemanticColors.of(BuildContext)` and `AppChartTheme.of(BuildContext)` that fall back to the light/dark default extension instance (matched to `Theme.of(context).brightness`) if `Theme.of(context).extension<T>()` is ever null in an isolated test harness.

---

## Phase 1: Design Tokens, Theme Factories & Platform Capabilities

### Overview

Add the required packages (`adaptive_platform_ui`, `cupertino_icons`, `widgetbook`), implement the platform/accessibility capability boundary in `lib/core/platform/presentation_capabilities.dart`, create the complete token and theme system in `lib/core/theme/`, wire production themes into `lib/app/app.dart` and `test/test_helpers/pump_app.dart`, and verify contrast ratios, `ThemeExtension` contracts, and capability parsing in unit tests.

### Changes Required:

#### 1. Dependencies & Analyzer Configuration

**File**: `pubspec.yaml` and `analysis_options.yaml`

**Intent**: Add `adaptive_platform_ui` and `cupertino_icons` as runtime dependencies for adaptive rendering and Cupertino icon glyphs, and add `widgetbook: ^3.25.0` under `dev_dependencies` for the component catalog.

**Contract**:
- `pubspec.yaml` `dependencies`: add `adaptive_platform_ui: ^1.0.2` (or latest compatible `1.x` resolved by `flutter pub get`) and `cupertino_icons: ^1.0.8`.
- `pubspec.yaml` `dev_dependencies`: add `widgetbook: ^3.25.0`.
- `analysis_options.yaml`: keep existing strict language rules (`strict-casts`, `strict-inference`, `strict-raw-types`); allow `lib/widgetbook/**` to import `package:widgetbook/widgetbook.dart` without triggering `depend_on_referenced_packages`.

#### 2. Platform & Accessibility Capability Boundary

**File**: `lib/core/platform/presentation_capabilities.dart`

**Intent**: Centralize platform detection, iOS major version parsing (iOS 26+ vs iOS 15–25), and accessibility flags (`reduceMotion`, `reduceTransparency`, `highContrast`) behind an immutable value object and Riverpod provider so core widgets never inspect `dart:io` or `Platform` directly.

**Contract**:
```dart
enum AdaptivePlatformMode {
  material,
  cupertinoClassic,
  cupertinoLiquidGlass,
}

@immutable
class PresentationCapabilities {
  final TargetPlatform targetPlatform;
  final int? iosMajorVersion;
  final bool isWeb;
  final bool reduceMotion;
  final bool reduceTransparency;
  final bool highContrast;
  final bool supportsNativeIosViews;

  const PresentationCapabilities({
    required this.targetPlatform,
    this.iosMajorVersion,
    this.isWeb = false,
    this.reduceMotion = false,
    this.reduceTransparency = false,
    this.highContrast = false,
    this.supportsNativeIosViews = false,
  });

  bool get isIos => !isWeb && targetPlatform == TargetPlatform.iOS;
  bool get isIos26OrNewer => (iosMajorVersion ?? 0) >= 26;

  AdaptivePlatformMode get platformMode {
    if (targetPlatform != TargetPlatform.iOS) {
      return AdaptivePlatformMode.material;
    }
    if (isIos26OrNewer && supportsNativeIosViews && !reduceTransparency) {
      return AdaptivePlatformMode.cupertinoLiquidGlass;
    }
    return AdaptivePlatformMode.cupertinoClassic;
  }

  static int? parseIosMajorVersion(String operatingSystemVersion);
  static PresentationCapabilities resolve(
    BuildContext context, {
    PresentationCapabilities? override,
  });
}

final presentationCapabilitiesOverrideProvider =
    Provider<PresentationCapabilities?>((ref) => null);
```
- `parseIosMajorVersion` extracts the major integer from strings like `'Version 26.0 (Build 23A344)'`, `'iOS 18.4'`, or `'26.1'`, returning `null` when unparseable.
- `resolve(BuildContext context, {PresentationCapabilities? override})` merges `override` (if provided via `presentationCapabilitiesOverrideProvider` or widget scope) with ambient `Theme.of(context).platform`, `MediaQuery.disableAnimationsOf(context) || WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.reduceMotion`, and `MediaQuery.highContrastOf(context) || WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.highContrast`.

#### 3. Color Palette, Semantic Colors & Chart Theme Extensions

**Files**:
- `lib/core/theme/app_palette.dart`
- `lib/core/theme/app_semantic_colors.dart`
- `lib/core/theme/app_chart_theme.dart`

**Intent**: Define the reference seed (`#673AB7`) and exact opaque semantic foreground/container color pairs from `07_design_system.md` §4, and expose `AppSemanticColors` and `AppChartTheme` as immutable `ThemeExtension` classes with complete `copyWith`, `lerp`, equality, and static `.of(BuildContext)` accessors.

**Contract**:
- `AppPalette`: `seedColor = Color(0xFF673AB7)` plus light/dark/high-contrast constant color tokens for success (`#146C43`/`#D9F2E3` light, `#A0D4B4`/`#113826` dark), warning (`#7A4D00`/`#FFEDC2` light, `#FFD58A`/`#402D08` dark), info (`#175B9B`/`#DFECFF` light, `#A8C8FF`/`#132F50` dark), and achievement (`#92400E`/`#FEF3C7` light, `#FCD34D`/`#452B0B` dark, plus border tokens).
- `AppSemanticColors extends ThemeExtension<AppSemanticColors>`: fields `successContainer`, `onSuccessContainer`, `warningContainer`, `onWarningContainer`, `infoContainer`, `onInfoContainer`, `achievementContainer`, `onAchievementContainer`, `achievementBorder`; factory constructors `.light()`, `.dark()`, `.highContrastLight()`, `.highContrastDark()`, and static `AppSemanticColors of(BuildContext context)`.
- `AppChartTheme extends ThemeExtension<AppChartTheme>`: fields `seriesWeight`, `seriesPace`, `seriesWorkouts`, `targetFill`, `targetBoundary`, `axisLabel`, `gridLine`, `tooltipSurface`, `onTooltipSurface`, `lineStrokeWidth` (`3.0`), `barWidth` (`12.0`), `targetDashPattern` (`const [6, 4]`); factory constructors `.fromColorScheme(ColorScheme scheme)` mapping `seriesWeight` and `seriesPace` to `scheme.primary`, `seriesWorkouts` to `scheme.tertiary`, `targetFill` to `scheme.secondaryContainer`, `targetBoundary` to `scheme.onSecondaryContainer`, `axisLabel` to `scheme.onSurfaceVariant`, `gridLine` to `scheme.outlineVariant`, `tooltipSurface` to `scheme.inverseSurface`, `onTooltipSurface` to `scheme.onInverseSurface`, and static `AppChartTheme of(BuildContext context)`.

#### 4. Spacing, Shape, Motion & Semantic Icons

**Files**:
- `lib/core/theme/app_spacing.dart`
- `lib/core/theme/app_shape.dart`
- `lib/core/theme/app_motion.dart`
- `lib/core/theme/app_icons.dart`

**Intent**: Provide fixed `const` scales and semantic aliases for spacing, border radii, layout breakpoints, motion durations/curves (respecting Reduce Motion), and platform-aware semantic icons (`Material` `Icons`, `CupertinoIcons`, and SF Symbol names).

**Contract**:
- `AppSpacing`: reference scale `space0 = 0`, `space1 = 4`, `space2 = 8`, `space3 = 12`, `space4 = 16`, `space6 = 24`, `space8 = 32`, `space12 = 48`; layout aliases `inlineGap = 8`, `relatedGap = 12`, `cardPadding = 16`, `sectionGap = 24`, `pageInsetCompact = 16`, `pageInsetWide = 24`, `sheetInset = 24`; breakpoints `compactBreakpoint = 600`, `expandedBreakpoint = 840`, `formMaxWidth = 480`, `dashboardMaxWidth = 1120`; tap targets `androidMinTapTarget = 48`, `iosMinTapTarget = 44`.
- `AppShape`: radii `small = 8`, `card = 16`, `sheet = 24`, plus prebuilt `BorderRadius` / `RoundedRectangleBorder` helpers.
- `AppMotion`: `stateFeedbackDuration = Duration(milliseconds: 120)`, `contentTransitionDuration = Duration(milliseconds: 200)`, and `Duration effectiveDuration(BuildContext context, Duration standard)` returning `Duration.zero` when `PresentationCapabilities.resolve(context).reduceMotion` is true.
- `AppIcons`: `enum AppIcon { home, weight, workout, profile, addMeasurement, edit, delete, retry, achievement, close, calendar, apiKey, link, language, logout, visibility, visibilityOff, error, warning, info, check, target, chevronRight }` and helper methods `IconData resolve(BuildContext context, AppIcon icon, {bool selected = false})`, `String sfSymbol(AppIcon icon, {bool selected = false})`, plus `normalSize = 24.0` and `compactSize = 20.0`.

#### 5. Material 3 & Cupertino Theme Factories

**File**: `lib/core/theme/app_theme.dart`

**Intent**: Construct coordinated `light()`, `dark()`, `highContrastLight()`, and `highContrastDark()` Material `ThemeData` instances and `cupertinoFromMaterial(ThemeData)` `CupertinoThemeData` projections with semantic text roles (including tabular figures on `headlineMedium` for the `Metric` role) and centralized component themes.

**Contract**:
- `AppTheme.light()`, `AppTheme.dark()`, `AppTheme.highContrastLight()`, `AppTheme.highContrastDark()`:
  - Generate `ColorScheme.fromSeed(seedColor: AppPalette.seedColor, brightness: ..., dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot, contrastLevel: isHighContrast ? 1.0 : 0.0)`.
  - Configure `TextTheme` with `FontFeature.tabularFigures()` on `headlineMedium` (the `Metric` role).
  - Register `extensions: [AppSemanticColors..., AppChartTheme.fromColorScheme(colorScheme)]`.
  - Configure centralized `cardTheme` (opaque `surfaceContainerLow`, `elevation: 0`, `AppShape.card` `16px` radius), `snackBarTheme`, `inputDecorationTheme` (`OutlineInputBorder`), `filledButtonTheme`, `outlinedButtonTheme`, `dialogTheme`, `bottomSheetTheme` (`surfaceContainerHigh`, top `24px` radius), `navigationBarTheme`, and `navigationRailTheme`.
- `AppTheme.cupertinoFromMaterial(ThemeData materialTheme)` returns a `CupertinoThemeData` mapping `brightness`, `primaryColor` (`colorScheme.primary`), `primaryContrastingColor` (`colorScheme.onPrimary`), `barBackgroundColor` (`colorScheme.surfaceContainerHigh`), `scaffoldBackgroundColor` (`colorScheme.surface`), and `textTheme`.

#### 6. Root App & Test Harness Theme Wiring

**Files**:
- `lib/app/app.dart`
- `test/test_helpers/pump_app.dart`
- `test/app/router/app_router_test.dart`

**Intent**: Wire the four `AppTheme` factories and `CupertinoTheme` coordination into `BulkTempoApp` and test helpers while keeping all 76 existing `tester.pumpApp(...)` calls and router tests green.

**Contract**:
- `lib/app/app.dart`: `MaterialApp.router` sets `theme: AppTheme.light()`, `darkTheme: AppTheme.dark()`, `highContrastTheme: AppTheme.highContrastLight()`, `highContrastDarkTheme: AppTheme.highContrastDark()`, `themeMode: ThemeMode.system`, and `builder: (context, child) => CupertinoTheme(data: AppTheme.cupertinoFromMaterial(Theme.of(context)), child: child ?? const SizedBox.shrink())`.
- `test/test_helpers/pump_app.dart`: extend `pumpApp` with optional `ThemeMode themeMode = ThemeMode.light`, `ThemeData? theme`, and `PresentationCapabilities? capabilities`, supplying `AppTheme.light()`, `AppTheme.dark()`, `AppTheme.highContrastLight()`, `AppTheme.highContrastDark()`, and the `CupertinoTheme` `builder` by default, and overriding `presentationCapabilitiesOverrideProvider` when `capabilities` is passed.
- `test/app/router/app_router_test.dart`: pass `theme: AppTheme.light()` to the test `MaterialApp.router` instances.

#### 7. Phase 1 Unit Tests

**Files**:
- `test/core/theme/app_theme_and_tokens_test.dart`
- `test/core/platform/presentation_capabilities_test.dart`

**Intent**: Verify relative luminance contrast (`>=4.5:1` for text pairs, `>=3.0:1` for non-text boundaries) across light, dark, and high-contrast palettes, test `AppSemanticColors` and `AppChartTheme` `copyWith`/`lerp`, verify tabular figures on `headlineMedium`, and test `PresentationCapabilities` OS version parsing and mode resolution.

**Contract**:
- Assert WCAG relative luminance contrast `>= 4.5` on all four semantic pairs (`success`, `warning`, `info`, `achievement`) in light, dark, and high-contrast themes, and on primary `ColorScheme` surface/foreground pairings.
- Assert `PresentationCapabilities.parseIosMajorVersion` and `platformMode` across Android, Web, iOS 15–25 (`cupertinoClassic`), iOS 26+ (`cupertinoLiquidGlass`), and iOS 26+ with `reduceTransparency: true` (`cupertinoClassic`).

### Success Criteria:

#### Automated Verification:

- Dependencies resolve cleanly and analyzer passes: `flutter pub get && flutter analyze`
- Formatting check passes on modified files: `dart format --output=none --set-exit-if-changed lib test`
- Token contrast, theme extension lerp/copyWith, and platform capability unit tests pass: `flutter test test/core/theme/ test/core/platform/`
- Existing full test suite passes with updated pumpApp and router test themes: `flutter test`

#### Manual Verification:

- Launch the app in light and dark system appearance and confirm BulkTempoApp applies the seeded #673AB7 tonalSpot Material 3 and Cupertino themes without visual regressions on existing screens

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Phase 2: Shared Adaptive Form & Surface Primitives (AppButton, AppTextField, AppCard, AppFeedback)

### Overview

Implement the four leaf primitives in `lib/core/widgets/` (`AppButton`, `AppTextField`, `AppCard`, `AppFeedback`) encapsulating `adaptive_platform_ui` with 3-tier platform dispatch (`material`, `cupertinoClassic`, `cupertinoLiquidGlass`), paired foreground/background busy and status colors, and accessible tap targets and semantics.

### Changes Required:

#### 1. `AppButton`

**File**: `lib/core/widgets/app_button.dart`

**Intent**: Provide a unified button contract supporting `primary`, `secondary`, `tonal`, `outlined`, `text`, and `destructive` variants, optional leading icon (`AppIcon` or `IconData`), full-width layout option, and busy/loading state that resolves its progress indicator color against the actual button foreground/background pair instead of assuming white.

**Contract**:
- `enum AppButtonVariant { primary, secondary, tonal, outlined, text, destructive }`
- `class AppButton extends ConsumerWidget`: parameters `label` (`String`), `onPressed` (`VoidCallback?`), `variant` (`AppButtonVariant = AppButtonVariant.primary`), `icon` (`AppIcon?`), `iconData` (`IconData?`), `isBusy` (`bool = false`), `isEnabled` (`bool = true`), `expand` (`bool = false`), `semanticLabel` (`String?`).
- Enforces minimum hit target (`48×48` on Android/web, `44×44` on iOS), prevents duplicate taps while `isBusy` (`effectiveOnPressed = (isEnabled && !isBusy) ? onPressed : null`), preserves an accessible `Semantics(label: ..., button: true, enabled: ...)` announcement when busy, and dispatches across `AdaptivePlatformMode`:
  - `material`: Material 3 `FilledButton`, `FilledButton.tonal`, `OutlinedButton`, or `TextButton`.
  - `cupertinoClassic`: `CupertinoButton` / `CupertinoButton.filled` with resolved foreground and `CupertinoActivityIndicator` when `isBusy`.
  - `cupertinoLiquidGlass`: `AdaptiveButton` / `AdaptiveButton.child` from `adaptive_platform_ui` (`useNative: !isBusy` so custom busy indicator renders deterministically when busy).

#### 2. `AppTextField`

**File**: `lib/core/widgets/app_text_field.dart`

**Intent**: Provide an adaptive text field wrapper supporting labels, hints, validation error messages, helper text, unit suffix text (e.g., `'kg'`, `'kg/wk'`), prefix/suffix icons, password obscuring, and keyboard configuration without exposing UIKit-specific parameters.

**Contract**:
- `class AppTextField extends ConsumerWidget`: parameters `fieldKey` (`Key?`), `controller` (`TextEditingController?`), `label` (`String`), `hint` (`String?`), `helperText` (`String?`), `errorText` (`String?`), `suffixText` (`String?`), `prefixIcon` (`AppIcon?`), `prefixIconData` (`IconData?`), `suffixIcon` (`Widget?`), `obscureText` (`bool = false`), `enabled` (`bool = true`), `autocorrect` (`bool = true`), `enableSuggestions` (`bool = true`), `keyboardType` (`TextInputType = TextInputType.text`), `textInputAction` (`TextInputAction?`), `onChanged` (`ValueChanged<String>?`), `onSubmitted` (`ValueChanged<String>?`).
- On `material`, renders Material `TextField` with `OutlineInputBorder` and `InputDecoration`.
- On `cupertinoClassic` and `cupertinoLiquidGlass`, renders labeled field column with `AdaptiveTextField` / `CupertinoTextField` (using opaque `surfaceContainerLow` / `surface` fill and `outline` / `error` border), `suffixText` adornment, and accessible error text row with `AppIcon.error` when `errorText != null`.

#### 3. `AppCard`

**File**: `lib/core/widgets/app_card.dart`

**Intent**: Provide an opaque tonal content card surface with optional header (`title`, `subtitle`, `trailing` / status badge slot) and variant styling (`grouped`, `outlined`, `tinted`) that extracts the neutral surface/header layout from `DashboardCardShell` and profile cards without importing feature state.

**Contract**:
- `enum AppCardVariant { grouped, outlined, tinted }`
- `class AppCard extends ConsumerWidget`: parameters `cardKey` (`Key?`), `title` (`String?`), `subtitle` (`String?`), `subtitleKey` (`Key?`), `leadingIcon` (`AppIcon?`), `headerTrailing` (`Widget?`), `variant` (`AppCardVariant = AppCardVariant.grouped`), `padding` (`EdgeInsetsGeometry?`), `margin` (`EdgeInsetsGeometry?`), `onTap` (`VoidCallback?`), `child` (`Widget`).
- Always renders an opaque surface (`surfaceContainerLow` for `grouped`, `surface` with `outlineVariant` border for `outlined`, `surfaceContainerHighest` for `tinted`) with `AppShape.card` (`16px` radius) and `AppSpacing.cardPadding` (`16px` default inner padding) across both Android and iOS (`AdaptiveCard` / `Card`), never applying glass to data cards.

#### 4. `AppFeedback` (Status Banner, Badge & Snackbar Helper)

**File**: `lib/core/widgets/app_feedback.dart`

**Intent**: Centralize `success`, `warning`, `info`, `error`, and `achievement` visual feedback for inline banners, compact status/achievement badges, and transient snackbars/toasts using `AppSemanticColors` and `ColorScheme` error pairs.

**Contract**:
- `enum AppFeedbackTone { success, warning, info, error, achievement }`
- `class AppFeedbackBanner extends ConsumerWidget`: renders an opaque rounded container (`AppShape.small` `8px` radius, `AppSpacing.space3` `12px` padding) with paired container/foreground colors from `AppSemanticColors` (or `errorContainer`/`onErrorContainer` for `error`), accompanying semantic icon (`AppIcons`), message text, and optional retry/action button.
- `class AppStatusBadge extends ConsumerWidget`: compact pill/badge (`AppShape.small` `8px` radius) for outdated badges, count chips, or achievement best-set badges (pairing icon + label with `AppSemanticColors`).
- `class AppFeedback`: static `showSnackBar(BuildContext context, {Key? snackBarKey, required String message, AppFeedbackTone tone = AppFeedbackTone.info, String? actionLabel, Key? actionKey, VoidCallback? onAction})` that presents a themed Material `SnackBar` (or `AdaptiveSnackBar` when `AdaptivePlatformMode.cupertinoLiquidGlass` is active and no custom `snackBarKey` is required) with paired foreground/background and `SnackBarAction(textColor: foregroundColor)`.

#### 5. Phase 2 Widget & Accessibility Tests

**Files**:
- `test/core/widgets/app_button_test.dart`
- `test/core/widgets/app_text_field_test.dart`
- `test/core/widgets/app_card_test.dart`
- `test/core/widgets/app_feedback_test.dart`
- `test/core/widgets/primitives_accessibility_test.dart`

**Intent**: Verify all four primitives across `material`, `cupertinoClassic`, and `cupertinoLiquidGlass` capability overrides, all interactive states (`default`, `disabled`, `busy`, `error`), `2.0x` `TextScaler` reflow without overflow, and Flutter's `androidTapTargetGuideline` (`48×48`), `iOSTapTargetGuideline` (`44×44`), `labeledTapTargetGuideline`, and `textContrastGuideline`.

**Contract**:
- Each primitive test suite exercises light and dark themes and all three `AdaptivePlatformMode` branches via `tester.pumpApp(..., capabilities: ...)`.
- `primitives_accessibility_test.dart` runs `meetsGuideline(...)` and pumps each widget at `MediaQueryData(textScaler: TextScaler.linear(2.0))` on a `320px` narrow width with Polish strings to verify zero `FlutterError` layout overflows.

### Success Criteria:

#### Automated Verification:

- Static analysis and formatting pass with zero warnings: `dart format --output=none --set-exit-if-changed lib test && flutter analyze`
- Form, surface, and feedback widget tests pass across Android Material, iOS 15–25 Cupertino, and iOS 26+ capability branches: `flutter test test/core/widgets/app_button_test.dart test/core/widgets/app_text_field_test.dart test/core/widgets/app_card_test.dart test/core/widgets/app_feedback_test.dart`
- Accessibility guideline and 2.0x TextScaler reflow tests pass for Phase 2 primitives: `flutter test test/core/widgets/primitives_accessibility_test.dart`

#### Manual Verification:

- Verify that AppButton busy spinners, AppTextField validation error chrome, AppCard tonal surfaces, and AppFeedback banners/snackbars render with legible paired foreground/background colors in light and dark modes

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Phase 3: Shared Adaptive Overlay & Shell Primitives (AppDialog, AppSheetFrame, AppNavigationShell)

### Overview

Implement `AppDialog`, `AppSheetFrame`, and `AppNavigationShell` in `lib/core/widgets/`, providing platform-adaptive confirmation/destructive dialogs, modal/draggable bottom sheets with `PopScope` and swipe/overscroll dismissal guards, and the responsive navigation shell (`<600` bottom bar, `>=840` Material `NavigationRail`, iOS 15–25 Cupertino bar, and iOS 26+ `adaptive_platform_ui` Liquid Glass scaffold).

### Changes Required:

#### 1. `AppDialog`

**File**: `lib/core/widgets/app_dialog.dart`

**Intent**: Provide a platform-adaptive confirmation and destructive alert dialog presenter and widget that renders `AlertDialog` on Android/web, `CupertinoAlertDialog` on iOS 15–25 (and in widget tests when keys are asserted), and `AdaptiveAlertDialog.show` on iOS 26+ native mode.

**Contract**:
- `class AppDialogAction`: `label` (`String`), `key` (`Key?`), `isDestructive` (`bool = false`), `isDefaultAction` (`bool = false`), `onPressed` (`VoidCallback?`), `resultValue` (`Object?`).
- `class AppDialog`:
  - `static Future<T?> showConfirm<T>(BuildContext context, {Key? dialogKey, required String title, required String message, required String cancelLabel, Key? cancelButtonKey, VoidCallback? onCancel, required String confirmLabel, Key? confirmButtonKey, VoidCallback? onConfirm, bool isDestructive = false, T? cancelResult, T? confirmResult})`.
  - Dispatches to `AdaptiveAlertDialog.show` when `AdaptivePlatformMode.cupertinoLiquidGlass` is active, `showCupertinoDialog` with `CupertinoAlertDialog` + `CupertinoDialogAction` on `cupertinoClassic`, and `showDialog` with Material 3 `AlertDialog` (`TextButton` cancel + `FilledButton` confirm, using `colorScheme.error` / `onError` when `isDestructive` is true) on `material`.

#### 2. `AppSheetFrame`

**File**: `lib/core/widgets/app_sheet_frame.dart`

**Intent**: Provide an opaque modal sheet container and static `show` presenter that handles `24px` top corner radii, `sheetInset` (`24px`) padding, dynamic `MediaQuery.viewInsetsOf(context).bottom` keyboard clearance, safe-area padding, title + close button header, optional `DraggableScrollableSheet` mode, and caller-controlled `canPop` + `onDismissRequested` guards (`PopScope`, overscroll at top, and vertical swipe-down gesture).

**Contract**:
- `class AppSheetFrame extends ConsumerStatefulWidget`:
  - Parameters: `sheetKey` (`Key?`), `title` (`String`), `subtitle` (`String?`), `summaryText` (`String?`), `closeButtonKey` (`Key?`), `closeTooltip` (`String?`), `canPop` (`bool = true`), `isBusy` (`bool = false`), `onDismissRequested` (`FutureOr<void> Function()?`), `isDraggable` (`bool = false`), `initialChildSize` (`double = 0.75`), `minChildSize` (`double = 0.45`), `maxChildSize` (`double = 0.92`), `maxWidth` (`double = AppSpacing.formMaxWidth`), `child` (`Widget`), `scrollableBuilder` (`Widget Function(BuildContext, ScrollController)?`).
  - Static helper `AppSheetFrame.show<T>(BuildContext context, {required WidgetBuilder builder, bool isScrollControlled = true, bool useSafeArea = true, bool enableDrag = false})` wrapping `showModalBottomSheet<T>` with `backgroundColor: Colors.transparent` and `constraints: BoxConstraints(maxWidth: AppSpacing.formMaxWidth)`.
  - Preserves the exact `PopScope(canPop: canPop && !isBusy, onPopInvokedWithResult: ...)` + `NotificationListener<ScrollNotification>` (overscroll `< -20` at top) + `GestureDetector` (vertical drag `> 100` or velocity `> 250`) dismissal-interception contract used by `WeightEntryBottomSheet`, while keeping the sheet content surface opaque (`colorScheme.surfaceContainerHigh` / `surface`).

#### 3. `AppNavigationShell`

**File**: `lib/core/widgets/app_navigation_shell.dart`

**Intent**: Provide the top app bar/toolbar and multi-destination navigation shell that renders Material 3 (`NavigationBar` below `840px` width, `NavigationRail` from `840px` width) on Android/web, classic Cupertino (`CupertinoPageScaffold` + `CupertinoNavigationBar` + `CupertinoTabBar`) on iOS 15–25, and `AdaptiveScaffold` + `AdaptiveAppBar` + `AdaptiveBottomNavigationBar` from `adaptive_platform_ui` on iOS 26+ Liquid Glass—while remaining completely agnostic of feature providers or routes.

**Contract**:
- `class AppNavigationDestinationItem`: `key` (`Key?`), `label` (`String`), `icon` (`AppIcon`), `badgeText` (`String?`).
- `class AppToolbarAction`: `key` (`Key?`), `tooltip` (`String`), `icon` (`AppIcon`), `onPressed` (`VoidCallback?`).
- `class AppNavigationShell extends ConsumerWidget`:
  - Parameters: `title` (`String`), `destinations` (`List<AppNavigationDestinationItem>`), `selectedIndex` (`int`), `onDestinationSelected` (`ValueChanged<int>`), `toolbarActions` (`List<AppToolbarAction> = const []`), `floatingActionButton` (`Widget?`), `body` (`Widget`).
  - On `AdaptivePlatformMode.material`: uses `LayoutBuilder` to switch between bottom `NavigationBar` (`< 840px`) and leading `NavigationRail` (`>= 840px`), rendering `AppBar` with `toolbarActions` and `floatingActionButton`.
  - On `AdaptivePlatformMode.cupertinoClassic`: renders `Scaffold` with `CupertinoNavigationBar`, body wrapped with bottom clearance for `CupertinoTabBar` and optional `floatingActionButton`, and a `CupertinoTabBar` mapping `AppIcons` and destination `Key`s.
  - On `AdaptivePlatformMode.cupertinoLiquidGlass`: renders `AdaptiveScaffold` with `AdaptiveAppBar(title: title, useNativeToolbar: true, actions: [...])`, `AdaptiveBottomNavigationBar(items: [...], selectedIndex: selectedIndex, onTap: onDestinationSelected)`, `floatingActionButton: floatingActionButton`, and `enableBlur: true`.

#### 4. Barrel Export for Core Design System

**File**: `lib/core/design_system.dart`

**Intent**: Provide a single clean barrel export for `lib/core/platform/presentation_capabilities.dart`, `lib/core/theme/*.dart`, and `lib/core/widgets/*.dart` so Widgetbook and future feature migrations can import the design system with one import line.

**Contract**:
- Exports `presentation_capabilities.dart`, `app_palette.dart`, `app_semantic_colors.dart`, `app_chart_theme.dart`, `app_spacing.dart`, `app_shape.dart`, `app_motion.dart`, `app_icons.dart`, `app_theme.dart`, `app_button.dart`, `app_text_field.dart`, `app_card.dart`, `app_feedback.dart`, `app_dialog.dart`, `app_sheet_frame.dart`, and `app_navigation_shell.dart`. Does not export `package:adaptive_platform_ui/adaptive_platform_ui.dart`.

#### 5. Phase 3 Widget Tests

**Files**:
- `test/core/widgets/app_dialog_test.dart`
- `test/core/widgets/app_sheet_frame_test.dart`
- `test/core/widgets/app_navigation_shell_test.dart`

**Intent**: Verify `AppDialog`, `AppSheetFrame`, and `AppNavigationShell` across platform capability modes, dismissal guards, keyboard insets, and responsive width thresholds (`<600px`, `600–839px`, `>=840px`).

**Contract**:
- `app_dialog_test.dart`: verifies `AppDialog.showConfirm` cancel/confirm results, destructive button styling, key preservation, and Material vs Cupertino dialog rendering.
- `app_sheet_frame_test.dart`: verifies `canPop: false` blocks system back and triggers `onDismissRequested` on close button tap, overscroll, and swipe-down drag; verifies `isBusy: true` blocks dismissal; verifies `viewInsets.bottom` keyboard padding and `isDraggable: true` mode.
- `app_navigation_shell_test.dart`: verifies tab selection callbacks, destination keys, toolbar actions, `floatingActionButton` rendering, `<840px` `NavigationBar` vs `>=840px` `NavigationRail` on Material, and `cupertinoClassic` (`CupertinoTabBar`) / `cupertinoLiquidGlass` (`AdaptiveScaffold`) branches.

### Success Criteria:

#### Automated Verification:

- Static analysis and formatting pass with zero warnings: `dart format --output=none --set-exit-if-changed lib test && flutter analyze`
- Overlay and navigation shell widget tests pass across Android Material, iOS 15–25 Cupertino, iOS 26+ capability branches, and >=840px NavigationRail breakpoint: `flutter test test/core/widgets/app_dialog_test.dart test/core/widgets/app_sheet_frame_test.dart test/core/widgets/app_navigation_shell_test.dart`
- Full repository test suite passes without regressions: `flutter test`

#### Manual Verification:

- Verify AppDialog confirmation/destructive actions, AppSheetFrame PopScope/swipe-down dismissal guards and keyboard clearance, and AppNavigationShell <600px bottom bar vs >=840px rail adaptation

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Phase 4: Widgetbook Component Catalog & Verification Gate

### Overview

Build the manual Widgetbook 3.25.x component catalog at `lib/widgetbook/main_widgetbook.dart` with interactive use cases for all design tokens and shared primitives across the 7-state matrix, English and Polish locales, light/dark/high-contrast themes, text scaling, and platform capability overrides, and add a `test/widgetbook/widgetbook_smoke_test.dart` suite that pumps every use case in `flutter test`.

### Changes Required:

#### 1. Widgetbook Catalog Entrypoint & Addon Configuration

**Files**:
- `lib/widgetbook/main_widgetbook.dart`
- `lib/widgetbook/widgetbook_app.dart`

**Intent**: Configure a runnable Widgetbook 3.25.x application (`flutter run -t lib/widgetbook/main_widgetbook.dart -d chrome`) with `MaterialThemeAddon` (Light, Dark, High Contrast Light, High Contrast Dark + coordinated `CupertinoTheme`), `LocalizationAddon` (`en` and `pl` using `AppLocalizations`), `TextScaleAddon` (`1.0`, `1.3`, `1.6`, `2.0`), and a custom wrapper/knob builder allowing live switching between `AdaptivePlatformMode.material`, `cupertinoClassic` (iOS 15–25), and `cupertinoLiquidGlass` (iOS 26+).

**Contract**:
- `BulkTempoWidgetbookApp` wraps `Widgetbook.material` in a `ProviderScope` and configures `directories` from modular use-case files under `lib/widgetbook/use_cases/`.

#### 2. Token & Component Use Cases (7-State Matrix)

**Files**:
- `lib/widgetbook/use_cases/tokens_use_cases.dart`
- `lib/widgetbook/use_cases/primitives_use_cases.dart`
- `lib/widgetbook/use_cases/overlays_and_shell_use_cases.dart`

**Intent**: Provide structured `WidgetbookCategory` / `WidgetbookComponent` / `WidgetbookUseCase` entries documenting every token family and all 7 shared widgets across interactive and asynchronous states, with explicit notes where a state is non-applicable.

**Contract**:
- `tokens_use_cases.dart`: Color scheme & `AppSemanticColors` swatches (with contrast ratios), `AppChartTheme` preview (`fl_chart` line + bar + dashed target band with accessible summary table), `AppSpacing` & `AppShape` visual scale, Typography roles (`Page title`, `Section title`, `Metric` with tabular figures, `Body`, `Supporting`, `Compact label`), and `AppIcons` side-by-side Material vs Cupertino vs SF Symbol table.
- `primitives_use_cases.dart`:
  - `AppButton`: 7-state matrix showcase (`default`, `pressed`, `focused`, `hovered`, `disabled`, `busy`, and `destructive/error`) across variants (`primary`, `secondary`, `tonal`, `outlined`, `text`, `destructive`) + interactive Knobs use case.
  - `AppTextField`: 7-state matrix showcase (`default`, `focused`, `hovered`, `disabled`, `error` validation, password obscure toggle, and unit suffix `'kg'` / `'kg/wk'`) + interactive Knobs use case.
  - `AppCard`: Surface variants (`grouped`, `outlined`, `tinted`) and asynchronous content states (`loading`, `loaded`, `empty`, `unconfigured`, `error/retry`, `stale/outdated` badge).
  - `AppFeedback`: `AppFeedbackBanner`, `AppStatusBadge` (including `achievement` best-set gold motif), and `AppFeedback.showSnackBar` trigger showcase across all 5 tones (`success`, `warning`, `info`, `error`, `achievement`).
- `overlays_and_shell_use_cases.dart`:
  - `AppDialog`: Confirmation and destructive dialog previews + interactive trigger use case.
  - `AppSheetFrame`: Standard form sheet (with simulated dirty-state guard and keyboard inset knob) and draggable detail sheet use cases.
  - `AppNavigationShell`: 4-destination shell preview across compact (`<600px`), medium (`600–839px`), and expanded (`>=840px` `NavigationRail`) widths and platform modes.

#### 3. Widgetbook Automated Smoke Test Suite

**File**: `test/widgetbook/widgetbook_smoke_test.dart`

**Intent**: Programmatically mount `BulkTempoWidgetbookApp` and pump every registered `WidgetbookUseCase` builder in English and Polish, light and dark themes, and `2.0x` text scale to ensure no catalog entry throws a runtime or layout overflow error.

**Contract**:
- Traverses the `directories` tree exported by `lib/widgetbook/widgetbook_app.dart`, extracts every `WidgetbookUseCase`, and pumps each builder inside `tester.pumpApp` under `(Locale('en'), AppTheme.light())`, `(Locale('pl'), AppTheme.dark())`, and `TextScaler.linear(2.0)`, asserting `tester.takeException()` is `null`.

### Success Criteria:

#### Automated Verification:

- Static analysis and formatting pass across lib and test (including lib/widgetbook/): `dart format --output=none --set-exit-if-changed lib test && flutter analyze`
- Localization parity test and Widgetbook smoke tests pass across EN/PL, light/dark, and 2.0x text scaling: `flutter test test/core/localization/l10n_parity_test.dart test/widgetbook/widgetbook_smoke_test.dart`
- Complete repository test suite passes: `flutter test`

#### Manual Verification:

- Run flutter run -t lib/widgetbook/main_widgetbook.dart -d chrome and inspect all token and component use cases across the 7-state matrix, English and Polish locales, light/dark/high-contrast themes, 2.0x text scale, and Android / iOS 15–25 / iOS 26+ capability knobs

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Testing Strategy

### Unit Tests:

- `test/core/theme/app_theme_and_tokens_test.dart`: Relative luminance contrast calculations (`>=4.5:1` for text/container pairs, `>=3.0:1` for non-text boundaries) across `light`, `dark`, `highContrastLight`, and `highContrastDark` themes; `AppSemanticColors` and `AppChartTheme` `copyWith`, `lerp`, and `.of(context)` fallback behavior; `AppMotion.effectiveDuration` when `reduceMotion` is enabled vs disabled; `AppIcons` resolution across platforms.
- `test/core/platform/presentation_capabilities_test.dart`: `PresentationCapabilities.parseIosMajorVersion` edge cases and `AdaptivePlatformMode` resolution across Android, Web, iOS 15–25, and iOS 26+ (with and without `reduceTransparency` and `supportsNativeIosViews`).

### Integration & Widget Tests:

- `test/core/widgets/app_button_test.dart`, `app_text_field_test.dart`, `app_card_test.dart`, `app_feedback_test.dart`, `app_dialog_test.dart`, `app_sheet_frame_test.dart`, `app_navigation_shell_test.dart`: 3-mode widget tests verifying rendering, callbacks, disabled/busy guards, `PopScope`/drag dismissal interception, and responsive `<840px` vs `>=840px` navigation layout.
- `test/core/widgets/primitives_accessibility_test.dart`: Flutter `AccessibilityGuideline` checks (`androidTapTargetGuideline`, `iOSTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`) and `2.0x` `TextScaler` reflow on a `320px` width in Polish (`Locale('pl')`).
- `test/widgetbook/widgetbook_smoke_test.dart`: Automated traversal and rendering of every registered `WidgetbookUseCase`.

### Manual Testing Steps:

1. Run `flutter run -t lib/widgetbook/main_widgetbook.dart -d chrome` and switch between Light, Dark, High Contrast Light, and High Contrast Dark themes, English (`en`) and Polish (`pl`) locales, and `1.0x`–`2.0x` text scales across all token and component use cases.
2. Toggle the platform capability knob in Widgetbook between Android (`material`), iOS 15–25 (`cupertinoClassic`), and iOS 26+ (`cupertinoLiquidGlass`) to inspect component adaptation.
3. Run the main app (`flutter run`) on simulator/device or web in light and dark system appearance to confirm `BulkTempoApp` applies the new theme foundation cleanly with no regressions on existing screens.

## Performance Considerations

- **Opaque data layer**: `AppCard` and chart theme definitions use opaque surface colors (`surfaceContainerLow`, `surface`) with zero `BackdropFilter` or shader passes over scrolling cards or charts.
- **Scoped native platform views**: `adaptive_platform_ui` native UIKit views are restricted to top-level chrome (`AppNavigationShell`, `AppDialog`, and non-busy `AppButton` on iOS 26+ runtime) and are never instantiated per list row or chart point.
- **Zero-allocation tokens**: `AppSpacing`, `AppShape`, `AppMotion`, and `AppPalette` are compile-time `const` definitions; theme extensions (`AppSemanticColors`, `AppChartTheme`) are allocated once per `ThemeData` creation.

## Migration Notes

- Existing feature views under `lib/features/**` remain untouched in this change. Because `BulkTempoApp` (`lib/app/app.dart`), `pump_app.dart` (`test/test_helpers/pump_app.dart`), and `app_router_test.dart` (`test/app/router/app_router_test.dart`) wire `AppTheme` at the root, existing Material widgets automatically inherit the refined `#673AB7` `tonalSpot` `ColorScheme` and component themes while keeping all existing widget keys and test expectations intact.
- Subsequent feature migrations (starting with the `HomeShellScreen` + `WeightEntryBottomSheet` trial described in `context/documentation/07_design_system.md` §7 and §10) will import `package:bulk_tempo/core/design_system.dart` and follow `/10x-ui`.

## References

- Design system contract: `context/documentation/07_design_system.md`
- Related research: `context/changes/design-system/research.md`
- Adaptive tooling evaluation: `exa-results/flutter-design-system-2026-10-16/recommendation.md`
- Architecture & dependency rules: `context/documentation/01_architecture_overview.md:48-57`
- Testing strategy: `context/documentation/06_testing_strategy.md:56-79`
- Root app & test pump helper: `lib/app/app.dart:10-36`, `test/test_helpers/pump_app.dart:7-25`

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands. Do not rename step titles. See `references/progress-format.md`.

### Phase 1: Design Tokens, Theme Factories & Platform Capabilities

#### Automated

- [x] 1.1 Dependencies resolve cleanly and analyzer passes: `flutter pub get && flutter analyze` — c548b71
- [x] 1.2 Formatting check passes on modified files: `dart format --output=none --set-exit-if-changed lib test` — c548b71
- [x] 1.3 Token contrast, theme extension lerp/copyWith, and platform capability unit tests pass: `flutter test test/core/theme/ test/core/platform/` — c548b71
- [x] 1.4 Existing full test suite passes with updated pumpApp and router test themes: `flutter test` — c548b71

#### Manual

- [x] 1.5 Launch the app in light and dark system appearance and confirm BulkTempoApp applies the seeded #673AB7 tonalSpot Material 3 and Cupertino themes without visual regressions on existing screens — c548b71

### Phase 2: Shared Adaptive Form & Surface Primitives (AppButton, AppTextField, AppCard, AppFeedback)

#### Automated

- [x] 2.1 Static analysis and formatting pass with zero warnings: `dart format --output=none --set-exit-if-changed lib test && flutter analyze` — 143783f
- [x] 2.2 Form, surface, and feedback widget tests pass across Android Material, iOS 15–25 Cupertino, and iOS 26+ capability branches: `flutter test test/core/widgets/app_button_test.dart test/core/widgets/app_text_field_test.dart test/core/widgets/app_card_test.dart test/core/widgets/app_feedback_test.dart` — 143783f
- [x] 2.3 Accessibility guideline and 2.0x TextScaler reflow tests pass for Phase 2 primitives: `flutter test test/core/widgets/primitives_accessibility_test.dart` — 143783f

#### Manual

- [x] 2.4 Verify that AppButton busy spinners, AppTextField validation error chrome, AppCard tonal surfaces, and AppFeedback banners/snackbars render with legible paired foreground/background colors in light and dark modes — 143783f

### Phase 3: Shared Adaptive Overlay & Shell Primitives (AppDialog, AppSheetFrame, AppNavigationShell)

#### Automated

- [x] 3.1 Static analysis and formatting pass with zero warnings: `dart format --output=none --set-exit-if-changed lib test && flutter analyze` — 6aea435
- [x] 3.2 Overlay and navigation shell widget tests pass across Android Material, iOS 15–25 Cupertino, iOS 26+ capability branches, and >=840px NavigationRail breakpoint: `flutter test test/core/widgets/app_dialog_test.dart test/core/widgets/app_sheet_frame_test.dart test/core/widgets/app_navigation_shell_test.dart` — 6aea435
- [x] 3.3 Full repository test suite passes without regressions: `flutter test` — 6aea435

#### Manual

- [x] 3.4 Verify AppDialog confirmation/destructive actions, AppSheetFrame PopScope/swipe-down dismissal guards and keyboard clearance, and AppNavigationShell <600px bottom bar vs >=840px rail adaptation — 6aea435

### Phase 4: Widgetbook Component Catalog & Verification Gate

#### Automated

- [x] 4.1 Static analysis and formatting pass across lib and test (including lib/widgetbook/): `dart format --output=none --set-exit-if-changed lib test && flutter analyze` — 00e4d3c
- [x] 4.2 Localization parity test and Widgetbook smoke tests pass across EN/PL, light/dark, and 2.0x text scaling: `flutter test test/core/localization/l10n_parity_test.dart test/widgetbook/widgetbook_smoke_test.dart` — 00e4d3c
- [x] 4.3 Complete repository test suite passes: `flutter test` — 00e4d3c

#### Manual

- [x] 4.4 Run flutter run -t lib/widgetbook/main_widgetbook.dart -d chrome and inspect all token and component use cases across the 7-state matrix, English and Polish locales, light/dark/high-contrast themes, 2.0x text scale, and Android / iOS 15–25 / iOS 26+ capability knobs — 00e4d3c
