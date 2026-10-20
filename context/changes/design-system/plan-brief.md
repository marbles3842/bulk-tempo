# Shared Flutter Design System — Plan Brief

> Full plan: `context/changes/design-system/plan.md`
> Research: `context/changes/design-system/research.md`
> Design System Contract: `context/documentation/07_design_system.md`

## What & Why

We are implementing Bulk Tempo's foundational design system (`lib/core/theme/`, `lib/core/platform/`, `lib/core/widgets/`, and `widgetbook/`) to establish a single source of truth for semantic colors, chart roles, spacing, shapes, motion, icons, and platform-adaptive controls (Material 3 on Android/web, classic Cupertino on iOS 15–25, and Liquid Glass on iOS 26+ via `adaptive_platform_ui`). Building and cataloging the foundation first in `core` and `widgetbook` without touching existing feature screens eliminates risk to existing feature flows while making subsequent `/10x-ui` screen migrations drop-in replacements.

## Starting Point

`BulkTempoApp` (`lib/app/app.dart:19-34`) currently passes an inline light-only `ColorScheme.fromSeed(seedColor: Colors.deepPurple)` to `MaterialApp.router` with no dark/high-contrast themes, no `CupertinoThemeData` coordination, and no `ThemeExtension`s, while `pumpApp` (`test/test_helpers/pump_app.dart:8-24`) mounts an unstyled `MaterialApp`. Neither `lib/core/theme/`, `lib/core/platform/`, `lib/core/widgets/`, nor `widgetbook/` exists yet.

## Desired End State

`BulkTempoApp` and `pumpApp` provide coordinated light, dark, and high-contrast Material 3 and Cupertino themes (`ThemeMode.system` in production, `ThemeMode.light` default in tests). Developers and AI agents have seven tested adaptive primitives in `lib/core/widgets/` (`AppButton`, `AppTextField`, `AppCard`, `AppFeedback`, `AppDialog`, `AppSheetFrame`, `AppNavigationShell`), a pure-Dart `PresentationCapabilities` adapter in `lib/core/platform/`, and a runnable Widgetbook 3.25.x catalog (`widgetbook/main_widgetbook.dart`) covering the 7-state matrix in English and Polish.

## Key Decisions Made

| Decision | Choice | Why (1 sentence) | Source |
| --- | --- | --- | --- |
| Adaptive package & boundary | `adaptive_platform_ui` strictly behind `lib/core/widgets/` | Delivers iOS 26+ Liquid Glass, iOS 15–25 Cupertino, and Android Material 3 without leaking third-party types into features. | Research |
| Color & token architecture | `#673AB7` `tonalSpot` seed + `AppSemanticColors` & `AppChartTheme` extensions | Preserves brand direction, guarantees `>=4.5:1` opaque semantic pairs, and separates chart roles from status feedback. | Research |
| Rollout scope for this change | Core tokens, primitives, root/test theme wiring & Widgetbook only | Zero risk to existing feature widget tests during initial setup; feature migrations follow via `/10x-ui`. | Plan |
| Theme mode control | `ThemeMode.system` only (`light`, `dark`, `highContrastLight`, `highContrastDark`) | Matches `07_design_system.md` §4 without adding extra Profile UI or storage state. | Plan |
| Widgetbook structure & version | Stable `widgetbook: ^3.25.0` at `widgetbook/main_widgetbook.dart` (manual use cases) | Avoids sub-package maintenance and `build_runner` conflicts with Freezed 3.0 while keeping use cases testable in `flutter test`. | Plan |
| Platform capability detection | Pure-Dart OS version parser + overridable `presentationCapabilitiesProvider` | Avoids native Swift `MethodChannel` maintenance in `AppDelegate.swift` while making all platform/accessibility states deterministic in tests. | Plan |
| Root theme coordination | `MaterialApp.router` + `CupertinoTheme` injected via `MaterialApp.builder` | Preserves `ThemeData` extensions and `ScaffoldMessenger` while providing coordinated `CupertinoThemeData` to iOS controls. | Plan |
| Wrapper platform branching | 3-tier dispatch (`material`, `cupertinoClassic`, `cupertinoLiquidGlass`) | Ensures interactive visual rendering in web Widgetbook and headless widget tests while using `adaptive_platform_ui` on iOS 26+ runtime. | Plan |
| Icon resolution | Add `cupertino_icons: ^1.0.8` + map `AppIcon` to Material `Icons`, `CupertinoIcons`, and SF Symbols | Prevents missing-glyph boxes in Cupertino previews while supplying native SF Symbol names for iOS 26+ bars. | Plan |
| Sheet & shell contracts | Full `PopScope`/drag dismissal guards on `AppSheetFrame` + FAB & `>=840px` `NavigationRail` on `AppNavigationShell` | Makes both components drop-in ready for `WeightEntryBottomSheet`, `WorkoutDetailBottomSheet`, and `HomeShellScreen`. | Plan |
| Automated test gate | Token contrast + 3-mode widget + `AccessibilityGuideline` + `2.0x` `TextScaler` + Widgetbook smoke tests | Enforces `07_design_system.md` §9 contracts deterministically across macOS and Linux CI without flaky cross-OS golden PNG diffs. | Plan |

## Scope

**In scope:** `pubspec.yaml` dependencies (`adaptive_platform_ui`, `cupertino_icons`, `widgetbook`), `lib/core/platform/presentation_capabilities.dart`, `lib/core/theme/*`, `lib/core/widgets/*`, `lib/core/design_system.dart`, root theme wiring in `lib/app/app.dart` and `test/test_helpers/pump_app.dart` (plus `test/app/router/app_router_test.dart`), `widgetbook/main_widgetbook.dart` catalog, and unit/widget/accessibility/smoke tests in `test/core/` and `test/widgetbook/`.

**Out of scope:** Modifying existing feature views/widgets under `lib/features/**`, Profile theme-switcher UI, native Swift `MethodChannel`s in `ios/Runner/AppDelegate.swift`, `dynamic_color`, standalone `material_ui`/`cupertino_ui` migration, and OS-specific PNG golden files.

## Architecture / Approach

`PresentationCapabilities` inspects the ambient `TargetPlatform`, pure-Dart OS version string, and `MediaQuery`/`AccessibilityFeatures` flags (or a test/Widgetbook override) to select `material`, `cupertinoClassic`, or `cupertinoLiquidGlass`. `AppTheme` generates four Material `ThemeData` variants (`light`, `dark`, `highContrastLight`, `highContrastDark`) with `AppSemanticColors` and `AppChartTheme` extensions and projects them into `CupertinoThemeData` inside `MaterialApp.builder`. Seven wrappers in `lib/core/widgets/` consume these tokens and dispatch to Material 3, classic Cupertino, or `adaptive_platform_ui` controls.

## Phases at a Glance

| Phase | What it delivers | Key risk |
| --- | --- | --- |
| 1. Design Tokens, Theme Factories & Platform Capabilities | `pubspec.yaml`, `presentation_capabilities.dart`, `lib/core/theme/*`, `app.dart`, `pump_app.dart`, token & capability unit tests | Existing router/widget tests missing theme extensions if `app_router_test.dart` or `.of(context)` fallback is omitted |
| 2. Shared Adaptive Form & Surface Primitives | `AppButton`, `AppTextField`, `AppCard`, `AppFeedback` + 3-mode widget & accessibility guideline tests | Busy spinner contrast and `48×48` / `44×44` tap target enforcement across platforms |
| 3. Shared Adaptive Overlay & Shell Primitives | `AppDialog`, `AppSheetFrame`, `AppNavigationShell`, `design_system.dart` + 3-mode widget tests | Preserving `PopScope`/overscroll/drag dismissal guards and `<840px` vs `>=840px` navigation layout |
| 4. Widgetbook Component Catalog & Verification Gate | `widgetbook/main_widgetbook.dart` (7-state matrix, EN/PL, themes, text scale, platform knobs) + `widgetbook_smoke_test.dart` | Keeping `widgetbook/` at the repository root outside `lib/` so `widgetbook` remains a pure dev dependency |

**Prerequisites:** Flutter 3.47.x / Dart 3.13.x SDK (`>=3.11.0 <4.0.0`), `context/documentation/07_design_system.md` contract.
**Estimated effort:** ~2–3 sessions across 4 phases.

## Open Risks & Assumptions

- `adaptive_platform_ui` native UIKit platform views (`UiKitView`) cannot render pixels in headless `flutter test` or Chrome; `PresentationCapabilities` safely routes web and headless widget tests to `cupertinoClassic` unless native view mode is explicitly enabled.
- Physical-device verification of iOS 26+ Liquid Glass z-order and scrolling remains part of the subsequent `HomeShellScreen` + `WeightEntryBottomSheet` feature migration trial.

## Success Criteria (Summary)

- `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, and `flutter test` pass with all existing tests and new token, 3-mode widget, accessibility guideline (`48×48` / `44×44` tap targets, contrast, `2.0x` `TextScaler`), and Widgetbook smoke tests green.
- Running `flutter run -t widgetbook/main_widgetbook.dart -d chrome` renders all token and component use cases interactively across the 7-state matrix, English and Polish locales, light/dark/high-contrast themes, and platform capability modes.
