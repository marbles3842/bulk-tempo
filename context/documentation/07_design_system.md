# 07. Design System — Proposal

Status: proposed, documentation only. Researched on 2026-10-15 and updated on 2026-10-16. This is the recommended contract for a later implementation, not a description of components already shipped. Supporting observations, source versions, and package evaluations are in [design-system research](../changes/design-system/research.md) and [adaptive tooling recommendation](../../exa-results/flutter-design-system-2026-10-16/recommendation.md).

## 1. Direction

Build a calm, readable progress tracker: purple accents, quiet tonal surfaces, clear numerical hierarchy, and familiar platform interactions. Share semantic tokens and component behavior across platforms; adapt navigation, controls, dialogs, and motion where platform conventions help.

- **Android:** Material 3, using official Flutter Material 3 controls.
- **iOS:** Cupertino-oriented navigation and interaction, with genuine Liquid Glass on suitable navigation/toolbar and control surfaces (iOS 26+) and classic Cupertino fallback on older iOS versions (iOS 15–25) via `adaptive_platform_ui`. Keep charts, history, metric cards, and form content opaque.
- **Existing web target:** retain functional Material-based rendering, responsive widths, keyboard focus, and accessible labels. This does not expand the PRD's mobile product scope.

Preserve purple as the provisional brand direction because the app already uses it. Exact visual approval should happen on the dashboard and weight-entry sheet; research alone does not establish that a palette looks right in context.

## 2. Platform and SDK boundary

The app uses standard Flutter SDK imports (`package:flutter/material.dart` and `package:flutter/cupertino.dart`), with local SDK at Flutter 3.47.6 / Dart 3.13.5 and iOS deployment target `15.0`.

To deliver genuine Liquid Glass on iOS 26+, classic Cupertino on older iOS, and Material 3 on Android, the project adopts **`adaptive_platform_ui`** as the single adaptive library, placed strictly behind app-owned wrapper widgets.

## 3. Token architecture

Use three levels with a single ownership point:

| Level | Purpose | Examples | Consumers |
| --- | --- | --- | --- |
| Reference | Raw design inputs | Purple seed, spacing scale, radius scale | Theme/token factories |
| Semantic | Meaning independent of a specific view | `surface`, `onSurface`, `warningContainer`, `pageInset` | Shared widgets and feature presentation |
| Component | Deliberate application of semantic roles | Card padding, input shape, button states | Component themes or component implementation |

Keep standard Material roles in `ColorScheme`, text roles in `TextTheme`, and standard widget styling in `ThemeData` component themes. Add immutable `ThemeExtension` types for app-specific colors and any values that vary by theme, and project the same semantic tokens into `CupertinoThemeData`. Implement `copyWith` and `lerp` for extensions. Fixed spacing can be a small `const` token class; it does not need a provider, remote configuration, or a JSON generation pipeline. [ThemeExtension](https://api.flutter.dev/flutter/material/ThemeExtension-class.html), [ThemeData](https://api.flutter.dev/flutter/material/ThemeData/ThemeData.html).

Proposed structure, consistent with the existing architecture:

```text
lib/core/theme/
  app_theme.dart                 # light/dark/high-contrast Material & Cupertino factories
  app_palette.dart               # seed and semantic color definitions
  app_semantic_colors.dart       # success, warning, info, achievement extension
  app_chart_theme.dart           # chart roles, strokes, tooltip appearance
  app_spacing.dart               # fixed scale and layout aliases
  app_shape.dart                 # shared content shapes
  app_motion.dart                # app-owned motion policy
  app_icons.dart                 # semantic identifiers and platform mapping
lib/core/widgets/
  app_button.dart
  app_text_field.dart
  app_card.dart
  app_feedback.dart
  app_dialog.dart
  app_sheet_frame.dart
  app_navigation_shell.dart
lib/core/platform/
  presentation_capabilities.dart # platform, OS version, and accessibility adapter boundary
```

These names describe responsibilities, not a requirement to create unused files. `core` must not import features. A navigation component receives destinations, labels, selection, toolbar actions, and callbacks; it does not know about dashboard providers or route destinations. Feature ViewModels continue to expose business state, without `Color`, `IconData`, or `BuildContext`. Feature views map that state to presentation tokens and call app-owned widget contracts (`AppButton`, `AppTextField`, `AppSheetFrame`, etc.) without exposing shader parameters or UIKit-specific options.

Keep a single application root and GoRouter configuration. Initially retain `MaterialApp.router` in `lib/app/app.dart` (installing `AdaptiveToolbarHost` if required by `adaptive_platform_ui`) and apply a coordinated Cupertino theme at iOS presentation boundaries. Avoid switching the root directly to `AdaptiveApp.router` until audited: making the iOS root `CupertinoApp` removes ancestor `Material` `ThemeData` and `ScaffoldMessenger`, which requires providing app tokens through an app-owned `InheritedTheme` and routing all snackbars, dialogs, and sheets through shared wrappers first.

For migrated code, raw colors belong in token definitions; repeated layout values belong in spacing/shape definitions. Domain-specific chart geometry is allowed in feature widgets when named and explained. Do not introduce an abstraction for each numeric literal.

## 4. Color system

### Brand and standard roles

Proposed initial seed: **`#673AB7`**, preserving the existing deep-purple direction. Generate separate light and dark schemes with `ColorScheme.fromSeed`, explicitly choosing `DynamicSchemeVariant.tonalSpot`. Treat the seed as an input: the generated `primary` need not equal that hex. Avoid hand-authoring an unrelated dark palette. [ColorScheme.fromSeed](https://api.flutter.dev/flutter/material/ColorScheme/ColorScheme.fromSeed.html).

| Meaning | Role pairing / usage |
| --- | --- |
| Primary action, selected destination | `primary` / `onPrimary` |
| Quiet selected region | `primaryContainer` / `onPrimaryContainer` |
| Page background | `surface` / `onSurface` |
| Grouped cards | `surfaceContainerLow` / `onSurface` |
| Raised sheet/menu content | `surfaceContainerHigh` / `onSurface` |
| Secondary text | `onSurfaceVariant` on a verified surface |
| Input boundary or meaningful divider | `outline`; decorative separation may use `outlineVariant` |
| Invalid input, failed action, destructive action | `error` / `onError`, or `errorContainer` / `onErrorContainer` |

Use matching foreground/background pairs. In particular, a loading button must resolve its spinner against its actual busy/disabled background, rather than assume white. Keep tooltips as explicit surface/foreground pairs. Theme the snackbar, input, button, navigation, dialog, sheet, and card families centrally before overriding individual widgets.

### Additional semantic palette

The following are proposed opaque **foreground/container pairs**, not extra replacements for `ColorScheme`. In `AppSemanticColors`, name them `onSuccessContainer`/`successContainer`, etc.

| Meaning | Light foreground / container | Dark foreground / container |
| --- | --- | --- |
| Success: operation completed | `#146C43` / `#D9F2E3` | `#A0D4B4` / `#113826` |
| Warning: stale data or attention needed | `#7A4D00` / `#FFEDC2` | `#FFD58A` / `#402D08` |
| Information: neutral explanation | `#175B9B` / `#DFECFF` | `#A8C8FF` / `#132F50` |
| Achievement: best workout set | `#92400E` / `#FEF3C7` | `#FCD34D` / `#452B0B` |

The achievement pair keeps the existing light gold motif; it has separate names and iconography from warning. Disabled presentation should use the component's resolved state styling, not a global opacity applied to an entire subtree.

For these exact opaque pairs, calculated sRGB text contrast exceeds 4.5:1; the research records inputs and results. That does not validate composited glass, generated schemes, arbitrary role combinations, or final rendered screens. Recheck the rendered pairs when implementing.

### Charts and product meaning

Define chart roles separately from feedback colors: `seriesWeight`, `seriesPace`, `seriesWorkouts`, `targetFill`, `targetBoundary`, `axisLabel`, `gridLine`, `tooltipSurface`, and `onTooltipSurface`.

Initial proposal: weight and pace use `primary`; workouts use `tertiary` in their separate chart; target fill uses a quiet `secondaryContainer` with a labeled, dashed `onSecondaryContainer` boundary. Tooltips use `inverseSurface`/`onInverseSurface`. If series later share a plot, distinguish them by markers/strokes and labels as well as color, and check contrast against the actual plot surface.

Missing measurements remain missing, with gaps and localized explanations. Zero workouts and unavailable workout data are different states. Do not turn positive weight change green or negative change red. The contextual assessment's classification rules remain unresolved in the product roadmap; tokens must not invent those rules. Keep existing pace charts neutral until that feature provides a defined status.

### Theme selection and personalization

Wire the theme factories into `theme`, `darkTheme`, `highContrastTheme`, and `highContrastDarkTheme` at the application root, defaulting to `ThemeMode.system`; add explicit user selection only if needed. Verify custom semantic colors under high contrast as well. For a proposed high-contrast factory, `contrastLevel: 1.0` is a starting input, not evidence of full accessibility compliance.

Start with a deterministic brand scheme. Android wallpaper colors can later personalize action/surface roles with a brand fallback; keep status meanings and chart interpretation stable. The Material-published `dynamic_color` package exposes nullable schemes for supported platforms. Treat it as a later dependency decision, not a prerequisite for tokens. [Dynamic color package](https://pub.dev/packages/dynamic_color).

## 5. Spacing, shape, and layout

These values are **Bulk Tempo proposals in Flutter logical pixels**, not asserted platform mandates. Use a 4-unit rhythm with a small set of explicit exceptions for strokes and optical alignment.

| Reference token | Value | Typical purpose |
| --- | --- | --- |
| `space0` | 0 | No separation |
| `space1` | 4 | Label to supporting text |
| `space2` | 8 | Icon to label, related controls |
| `space3` | 12 | Compact group spacing |
| `space4` | 16 | Card padding and compact page inset |
| `space6` | 24 | Section gap and sheet padding |
| `space8` | 32 | Major group separation |
| `space12` | 48 | Spacious empty-state separation |

Expose layout aliases: `inlineGap = 8`, `relatedGap = 12`, `cardPadding = 16`, `sectionGap = 24`, `pageInsetCompact = 16`, `pageInsetWide = 24`, `sheetInset = 24`. This allows later tuning without changing the meaning of a reference value. Prefer `EdgeInsetsDirectional` and direction-aware alignment.

Page containers own outer gutters; cards own inner padding. Avoid nested page/card margins that accidentally double the inset. Compute keyboard and system-bar clearance from `viewInsets`, safe-area padding, and the actual navigation height; those are runtime inputs, not fixed spacing tokens.

Proposed shared content radii: `small = 8` for badges, `card = 16`, `sheet = 24`. Let platform controls retain their native/framework shape; do not apply the card radius to navigation or every button. Prefer tonal surface separation to decorative shadows. Use a flat content-card default and reserve elevation for floating/overlay elements.

Use available constraints, not device names, to choose layouts. Proposed starting ranges: below 600 logical pixels, a single main column; from 600, permit paired cards when their content fits; from 840, evaluate a navigation rail for the Material shell. Cap forms at 480 and dashboard content at 1120 logical pixels. These are tuning points, not a rule to force columns at large text sizes. [Flutter adaptive guidance](https://docs.flutter.dev/ui/adaptive-responsive/best-practices).

## 6. Typography, icons, and motion

Use system-appropriate fonts initially, with semantic text roles rather than per-screen font declarations. Define these app roles on the platform text theme:

| App role | Material mapping | Usage |
| --- | --- | --- |
| Page title | `headlineSmall` | Main screen heading |
| Section title | `titleMedium` | Card or form group title |
| Metric | `headlineMedium` + tabular figures | Primary weight/pace value |
| Body | `bodyLarge` | Form and main explanatory text |
| Supporting | `bodyMedium` | Dates, units, descriptions |
| Compact label | `labelLarge` | Actions, badges, chart labels |

Map equivalent iOS hierarchy through the Cupertino theme/native controls without forcing identical font metrics. Use tabular figures for changing numbers where the selected font supports them. Preserve localized number/date formatting and unit labels.

Respect system `TextScaler`, bold text, and natural line height. Reflow metric tiles and wrap Polish labels before reducing text size. Do not globally clamp scaling, shrink essential numbers with `FittedBox`, or fix a subtitle's height. Reduce chart tick density or offer data rows when labels no longer fit; do not solve this with tiny text. [Flutter text scaling and accessibility](https://docs.flutter.dev/ui/accessibility/ui-design-and-styling).

Use semantic icon identifiers such as `home`, `weight`, `workout`, `profile`, `addMeasurement`, `edit`, `delete`, `retry`, and `achievement`. Android/web can initially map to consistent bundled Material outlined/filled icons. Material Symbols are a separate asset family; adopting them requires an intentional asset/package choice. [Google Symbols guide](https://developers.google.com/fonts/docs/material_symbols).

iOS adapters can map to Cupertino icons or native SF Symbols. Keep SF Symbols inside supported Apple contexts and check symbol availability/restrictions; do not repurpose them as the app logo. Bundle any required Cupertino font dependency explicitly. Prefer a 24-unit normal icon and 20-unit compact icon as app defaults, independent of the larger hit target. Localized labels/tooltips describe actions; decorative icons should not duplicate screen-reader announcements. [Apple symbol guidance](https://developer.apple.com/design/human-interface-guidelines/sf-symbols).

Use framework/platform motion for standard controls and routes. For custom transitions, proposed durations are 120 ms for small state feedback and 200 ms for content transitions. Avoid animating numbers in ways that imply unmeasured intermediate values. Reduce app-owned motion when requested, retain clear state changes, and avoid haptics on automatic refreshes.

On the inspected Flutter API, iOS `AccessibilityFeatures.reduceMotion` is distinct from `MediaQuery.disableAnimations`. Normalize both signals in the presentation adapter and observe preference changes. Do not put this platform logic in domain ViewModels. [Flutter Reduce Motion API](https://api.flutter.dev/flutter/dart-ui/AccessibilityFeatures/reduceMotion.html).

## 7. Liquid Glass contract and `adaptive_platform_ui`

Use glass sparingly in the layer for navigation and floating controls. Prefer regular glass for controls over changing content; keep Bulk Tempo's data layer (weight charts, workout summaries, KPI cards, and forms) opaque. Apple describes glass as a distinct functional layer above content, with built-in adaptations for accessibility preferences. A Flutter blur effect is an approximation and must not be represented as Apple's native material. [Apple Liquid Glass session](https://developer.apple.com/videos/play/wwdc2025/219/), [Apple: Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass).

Recommended first trial target: `HomeShellScreen` (both its top app bar/toolbar and four-destination bottom navigation bar) behind an `AppNavigationShell` interface, plus the `WeightEntryBottomSheet` flow. Keep tab selection, routing, and feature state in Flutter. Preserve content clearance, keyboard handling, focus order, and the same destination labels across all platforms and fallbacks.

| UI responsibility | Android | iOS 26+ (Liquid Glass) | Older supported iOS (15–25) / fallback | Web |
| --- | --- | --- | --- | --- |
| Navigation shell & toolbar | Material 3 | Native system glass navigation/toolbar | Classic Cupertino opaque navigation/toolbar | Material fallback; no native glass runtime dependency |
| Buttons, menus, selectors, dialogs | Material controls | Native iOS controls where useful | Cupertino controls | Material controls |
| Forms, sheets, and pickers | Material conventions | iOS conventions; glass only on appropriate chrome | Cupertino conventions | Material conventions |
| Charts, history, and KPI cards | Shared structure with Material surface tokens | Shared structure with iOS opaque surface tokens | Same readable opaque content | Shared structure with Material surface tokens |
| Reduce Transparency / Increase Contrast | Standard Material contrast adaptation | Respect native UIKit adaptation; opaque fallback for app-painted surfaces | Respect Cupertino contrast; opaque surfaces | Standard Material contrast adaptation |
| Reduce Motion | Simplify app-owned animation | Simplify app-owned animation; preserve system setting in native controls | Simplify app-owned animation | Simplify app-owned animation |

### Adaptive library implementation: `adaptive_platform_ui`

The design system adopts **[`adaptive_platform_ui`](https://pub.dev/packages/adaptive_platform_ui)** as the single adaptive library. Its platform matrix matches native iOS 26+ Liquid Glass, classic Cupertino on older iOS (matching the project's iOS `15.0` deployment target), and Material 3 on Android.

- **Encapsulation:** Keep all third-party adaptive components strictly behind app-owned wrappers in `lib/core/widgets/` (`AppNavigationShell`, `AppButton`, `AppDialog`, `AppSheetFrame`, `AppTextField`). Feature screens and ViewModels must never import `adaptive_platform_ui` directly.
- **Routing & Toolbars:** Supports GoRouter and `AdaptiveToolbarHost`.
- **Theming:** Allows coordinated Material 3 and Cupertino themes while preserving app semantic tokens.

For any app-painted translucency, obtain Reduce Transparency through an iOS adapter and observe changes; high contrast is not a substitute. If that capability is unavailable, choose opaque rendering. [Apple preference API](https://developer.apple.com/documentation/uikit/uiaccessibility/isreducetransparencyenabled).

Before committing to the library app-wide, verify the trial flow (`HomeShellScreen` + `WeightEntryBottomSheet`) on physical hardware and simulators:
- Tab selection, state preservation, auth redirects, push/pop, and interactive back behavior.
- Native toolbar/tab visibility and z-order layering when modal sheets or dialogs are open, and chart scrolling beneath the bars (specifically testing for UIKit view occlusion).
- Weight entry with keyboard open, validation, submission/loading, `PopScope` dismissal guards, and safe-area handling.
- VoiceOver and TalkBack labels, focus order, large text, Reduce Motion, and Reduce Transparency.
- Profile-mode scrolling and transitions on both a recent iPhone and an older supported iOS baseline. Do not replicate a native view in each list row or add full-screen blur behind the charts. [Flutter platform views](https://docs.flutter.dev/platform-integration/ios/platform-views).

## 8. Component scope and states

Start by extracting stable presentation from existing widgets. Prefer component themes for appearance; add wrappers where they own behavior, accessibility, or platform adaptation.

| Component | Shared responsibility | What stays feature-owned |
| --- | --- | --- |
| `AppButton` | Primary/secondary/destructive variants, busy label/progress, disabled behavior (backs `AuthButton` and feature actions) | Validation and submission action |
| `AppTextField` | Label, error/help layout, focus/border states, adaptive keyboard/field chrome (backs `AuthTextField` and sheet inputs) | Controllers, units, parsing, validators |
| `AppCard` | Opaque content surface, shape, inner padding, heading layout | Dashboard status (`DashboardCardStatus`) and data composition |
| `AppFeedback` / status badge | Success/warning/info/error presentation, snackbar/banner routing, and semantics | Error recovery and stale-data decisions |
| `AppDialog` | Platform-adaptive confirmation and destructive alert presentation (e.g., logout confirmation) | Action callbacks and state transitions |
| `AppSheetFrame` | Insets, keyboard clearance, safe area, title/actions, scrolling frame | Dirty-state (`PopScope`) and submission dismissal guards |
| `AppNavigationShell` | Platform top toolbar/app bar and bottom tab bar rendering, selected state, labels | Destination composition, tab bodies, and routing |

Keep metric tiles, chart widgets, weekly rows, and the achievement badge feature-local until reuse warrants extraction. In particular, `DashboardCardShell` currently imports `DashboardCardStatus`: move its neutral surface/header pieces into `AppCard`, keeping the domain-specific status switch in `dashboard`. Preserve weight-entry `PopScope` protections when introducing `AppSheetFrame`.

Document applicable states in component examples: default, pressed, focused, hovered, disabled, busy, and error. For asynchronous content, additionally cover loading, loaded, empty, unconfigured, error/retry, and stale content. Mark non-applicable states explicitly. A stale banner should preserve readable previous data and distinguish freshness from a failed write. Busy controls prevent duplicate actions while retaining an accessible action name.

## 9. Accessibility, cataloging, and acceptance

Adopt a house minimum hit area of **48 × 48 logical pixels** for app-owned controls, while allowing native controls to follow their platform's accessible metrics. The platform guideline tests distinguish Android's 48-unit and iOS's 44-unit targets. Keep visible icon size separate from hit area. [Flutter accessibility testing](https://docs.flutter.dev/ui/accessibility/accessibility-testing).

Target at least 4.5:1 for normal text and 3:1 for qualifying large text; meaningful control boundaries and chart marks should meet the applicable 3:1 non-text contrast requirement. Labels, shapes, patterns, or icons accompany color meanings. Test actual composited backgrounds. [Flutter styling guidance](https://docs.flutter.dev/ui/accessibility/ui-design-and-styling), [W3C non-text contrast](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html).

Provide charts with localized summaries and accessible per-week values, including missing-data and target-range explanations. Touched tooltips are an enhancement, not the sole way to obtain a value. Support keyboard access in the existing web build and meaningful TalkBack/VoiceOver reading order.

Use **[Widgetbook](https://pub.dev/packages/widgetbook)** for the component catalog (pinning documentation and usage consistently to either stable `3.25.x` or `4.0.0-beta`). Cover default, pressed/focused, disabled, loading/busy, empty, error, and populated states across English and Polish, light and dark themes, long labels, and enlarged text.

For implementation acceptance:

1. Render Widgetbook use cases and the dashboard/weight sheet in light/dark, English/Polish, narrow/wide, and large-text conditions; inspect screenshots.
2. Update `test/test_helpers/pump_app.dart` to supply the production theme, and exercise component contracts, fallback selection, focus, labels, contrast, and tap targets in widget tests.
3. Combine Flutter golden tests (for Flutter-rendered surfaces) with native iOS simulator/device integration checks and screenshots (for UIKit-backed controls, since web Widgetbook and Flutter goldens cannot validate native platform views).
4. Validate glass on supported (iOS 26+) and fallback (older iOS) environments, including accessibility settings and physical-device profile-mode scrolling. Record frame-time and memory observations rather than promising a frame rate before measurement.
5. Run the repository's format, analysis, and test checks (`dart format lib test`, `flutter analyze`, `flutter test`) after code changes; preserve existing business behavior and localization tests.

## 10. Adoption and outstanding choices

Recommended incremental adoption order:

1. **Tokens & themes on current SDK imports:** Extract color, spacing, radius, typography, and chart tokens using `package:flutter/material.dart` and `package:flutter/cupertino.dart`. Introduce light, dark, and high-contrast themes and update `pump_app.dart`.
2. **Shared primitives:** Implement app-owned wrappers (`AppButton`, `AppTextField`, `AppCard`, `AppFeedback`, `AppDialog`, `AppSheetFrame`, `AppNavigationShell`) encapsulating `adaptive_platform_ui`.
3. **Focused adaptive trial:** Trial `adaptive_platform_ui` on `HomeShellScreen` and `WeightEntryBottomSheet` across Android, iOS 26+ (Liquid Glass), and older iOS 15+ (Cupertino fallback), retaining `MaterialApp.router` at the root initially (with `AdaptiveToolbarHost` if required) and preserving Riverpod/GoRouter behavior.
4. **Catalog & feature rollout:** Add Widgetbook use cases and migrate remaining views (`auth`, `dashboard`, `weight`, `workout`, `gain_target`) through the shared interfaces using the repository's `/10x-ui` workflow.

The proposed defaults are sufficient for planning. Remaining choices are visual acceptance of purple and content density, and passing the physical-device trial for `adaptive_platform_ui`. Product assessment thresholds remain outside this design-system decision. No runtime code, dependency, or platform setting is changed by this document.
