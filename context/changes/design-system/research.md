---
date: 2026-10-15T21:56:10+02:00
researcher: Codex
git_commit: 1229a4fcecaaa95f2c6482025359eb0d3469a64a
branch: main
repository: bulk_tempo
topic: "Propose a Flutter design system with tokens and platform-adaptive controls"
tags: [research, design-system, flutter, accessibility, liquid-glass, material]
status: complete
last_updated: 2026-10-15
last_updated_by: Codex
last_updated_note: "Initial repository and primary-source research; documentation proposal saved"
---

# Research: Bulk Tempo design system

**Evidence snapshot:** 2026-10-15T21:56:10+02:00. **Researcher:** Codex. **Repository:** bulk_tempo, branch `main`, commit `1229a4fcecaaa95f2c6482025359eb0d3469a64a`. The working tree already contained a user modification to `AGENTS.md`; it was read and preserved. References below are local file/line anchors rather than unverified remote commit links.

## Research question

What design system should this Flutter app use for colors, spacing tokens, icons, typography, components, and platform behavior, with partial Liquid Glass adoption on iOS and an appropriate current Android direction? The requested first deliverable is documentation in `context/documentation`, not runtime implementation.

## Summary

Recommend shared semantic tokens and component behavior, Material 3 with selective official Expressive adoption on Android, and Cupertino-oriented iOS controls with a native-glass prototype for navigation. Opaque content surfaces are the proposed default for charts, metrics, and forms. The concrete contract is [07_design_system.md](../../documentation/07_design_system.md).

The inspected app root currently supplies a seed-based Material theme without a dark theme or component themes ([app.dart:19](../../../lib/app/app.dart#L19)). Existing feature widgets provide useful starting points, but geometry and feedback styles are repeated. Tokenizing those patterns is a smaller and more appropriate starting point than adopting an unrelated full UI kit.

Native glass feasibility and visual acceptance remain implementation gates. Research establishes an approach and alternatives; it does not establish device performance, final visual quality, or a selected glass dependency.

## Detailed findings

### Current app and reusable seams

- The root uses SDK Material imports and `ColorScheme.fromSeed(seedColor: Colors.deepPurple)` ([app.dart:1](../../../lib/app/app.dart#L1), [app.dart:21](../../../lib/app/app.dart#L21)). Its inspected constructor has no `darkTheme` or app-specific theme extension configuration.
- The shell composes dashboard, weight history, workouts, and profile and renders their destinations in a Material `NavigationBar` ([home_shell_screen.dart:261](../../../lib/features/auth/presentation/views/home_shell_screen.dart#L261), [home_shell_screen.dart:287](../../../lib/features/auth/presentation/views/home_shell_screen.dart#L287)). This is a suitable platform-adaptation seam.
- `DashboardCardShell` sets margin, radius, elevation, and padding locally ([dashboard_card_shell.dart:52](../../../lib/features/dashboard/presentation/widgets/dashboard_card_shell.dart#L52)). Weight and Hevy forms repeat sheet geometry ([weight_entry_bottom_sheet.dart:351](../../../lib/features/weight/presentation/widgets/weight_entry_bottom_sheet.dart#L351), [hevy_key_bottom_sheet.dart:60](../../../lib/features/workout/presentation/widgets/hevy_key_bottom_sheet.dart#L60)). These are concrete spacing/shape consumers.
- The authentication loading spinner uses white ([auth_button.dart:24](../../../lib/features/auth/presentation/widgets/auth_button.dart#L24)); pace tooltip text does too ([weekly_pace_chart_card.dart:158](../../../lib/features/dashboard/presentation/widgets/weekly_pace_chart_card.dart#L158)); gain-target success feedback uses a literal green ([gain_target_view.dart:73](../../../lib/features/gain_target/presentation/views/gain_target_view.dart#L73)). Theme-aware foreground/background pairs would remove those assumptions.
- The best-set badge has an intentional gold style with a separate dark branch ([workout_detail_bottom_sheet.dart:225](../../../lib/features/workout/presentation/widgets/workout_detail_bottom_sheet.dart#L225)). Preserve this as an achievement role, distinct from warning.
- In the inspected KPI widget, essential values use `FittedBox(scaleDown)` and subtitles have fixed height and one-line overflow ([dashboard_kpi_row.dart:223](../../../lib/features/dashboard/presentation/widgets/dashboard_kpi_row.dart#L223)). This is a large-text/localization risk, not a measured rendering failure.
- The pace chart declares small axis labels and touch tooltips but no app-owned accessible data summary in that widget ([weekly_pace_chart_card.dart:129](../../../lib/features/dashboard/presentation/widgets/weekly_pace_chart_card.dart#L129), [weekly_pace_chart_card.dart:149](../../../lib/features/dashboard/presentation/widgets/weekly_pace_chart_card.dart#L149)). Library-generated semantics were not inspected. Propose a textual summary and accessible per-week values.
- The test helper currently constructs a default `MaterialApp` without the production theme ([pump_app.dart:16](../../../test/test_helpers/pump_app.dart#L16)); theme adoption should update that helper.

### Android and current Flutter support

Android's current guidance describes Material 3 Expressive, but its Compose APIs are not evidence of Flutter coverage. [Android Material guide](https://developer.android.com/develop/ui/compose/designsystems/material3).

During this investigation, the official `material_ui` changelog showed version 1.7.0, recorded Expressive `IconButton` support in 1.5.0, and required Flutter 3.47/Dart 3.13 from 1.4.0. The current `StyleVariant` documentation still marks Expressive as under development. Recommend selective use with package resolution recorded and screenshot review on updates. [Changelog](https://pub.dev/packages/material_ui/changelog), [StyleVariant API](https://pub.dev/documentation/material_ui/latest/material_ui/StyleVariant.html).

The inspected machine's `/Users/dimi/flutter/bin/cache/flutter.version.json:2` reports Flutter 3.47.6 and `:11` reports Dart 3.13.5. The repository declares Dart >=3.11 and does not list standalone design packages ([pubspec.yaml:6](../../../pubspec.yaml#L6)); its lockfile's Flutter lower bound is >=3.38.4 ([pubspec.lock:893](../../../pubspec.lock#L893)). CI selects the stable channel rather than an exact release ([ci.yml:30](../../../.github/workflows/ci.yml#L30)). These are different facts: installed capability does not define the team's required baseline.

Flutter's migration guide describes standalone Material/Cupertino packages and their localization changes. A compatibility bridge handles inherited design context but not distinct Dart types in public signatures. A later plan must inspect dependencies such as `fl_chart` before selecting the migration boundary. [Migration guide](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui).

### iOS Liquid Glass

Apple places Liquid Glass in a navigation/control layer above content and describes native accessibility adaptations. For this data-heavy app, the proposed boundary is glass navigation with opaque forms/charts. This is an application of Apple's guidance, not a claim that Apple mandates Bulk Tempo's specific layout. The source was readable as the WWDC transcript. [Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/).

The inspected `cupertino_ui` 1.1.3 changelog does not establish a shipped first-party Liquid Glass widget. Its 1.1.1 entry requires Flutter 3.47/Dart 3.13. Flutter-painted Cupertino styling should not be described as automatically becoming native UIKit glass. [Cupertino changelog](https://pub.dev/packages/cupertino_ui/changelog).

Feasible options are a small owned UIKit adapter, a native-view package, or a Cupertino/opaque fallback. `native_liquid_glass` 0.3.1 was inspected as a candidate: its author documents native UIKit views, iOS 26+ glass, empty widgets on other platforms, and overlay/tab-transition coordination. These are author claims, not app verification. Shader/blur replications are a different fidelity category. [Candidate package](https://pub.dev/packages/native_liquid_glass).

Flutter documents performance and composition limitations for native iOS platform views. Therefore the proposed experiment is a navigation surface over the actual dashboard, not a glass widget per data row. [Platform-view guide](https://docs.flutter.dev/platform-integration/ios/platform-views).

The Xcode project declares deployment target 15.0 ([project.pbxproj:476](../../../ios/Runner.xcodeproj/project.pbxproj#L476)). Preserve that supported range with runtime capability checks unless a separate change raises it. Native-glass implementation must also establish the necessary build SDK/Xcode baseline.

For app-owned motion, iOS Reduce Motion is exposed through `AccessibilityFeatures.reduceMotion`; the local `media_query.dart:663–669` explicitly distinguishes it from `disableAnimations`. For app-painted translucency, bridge Reduce Transparency and updates or choose opaque rendering until supported. [Flutter Reduce Motion](https://api.flutter.dev/flutter/dart-ui/AccessibilityFeatures/reduceMotion.html), [Apple transparency preference](https://developer.apple.com/documentation/uikit/uiaccessibility/isreducetransparencyenabled).

### Colors, typography, spacing, and icons

`ColorScheme.fromSeed` supplies the Material role vocabulary; extensions add app-only roles. Seed input and generated primary are not necessarily identical. Use paired colors, with component themes defining normal interaction states. The proposed additional semantic colors, spacing values, radii, and width thresholds are house choices, not measured current values or platform requirements. [ColorScheme](https://api.flutter.dev/flutter/material/ColorScheme/ColorScheme.fromSeed.html), [ThemeExtension](https://api.flutter.dev/flutter/material/ThemeExtension-class.html).

Dynamic Android color is an optional later feature; the Material-published package exposes schemes and fallback handling. Keep brand tokens deterministic first. [dynamic_color](https://pub.dev/packages/dynamic_color).

Typography should retain system scaling, and layouts should depend on available width. Semantic icons enable platform-specific mapping without putting icon choices in ViewModels. Google's Material Symbols are a separate asset family from the existing bundled icons; migration should be explicit. [Adaptive guidance](https://docs.flutter.dev/ui/adaptive-responsive/best-practices), [Flutter accessible styling](https://docs.flutter.dev/ui/accessibility/ui-design-and-styling), [Material Symbols](https://developers.google.com/fonts/docs/material_symbols).

### Proposed palette calculation

Calculated locally with Node for the exact opaque sRGB foreground/container inputs below, using linearized channels, relative luminance `L = 0.2126R + 0.7152G + 0.0722B`, and contrast `(Llighter + 0.05)/(Ldarker + 0.05)`. Results are displayed rounded to two decimals; acceptance was checked against the unrounded value. These are derived values for proposed tokens, not rendered screenshots. [W3C contrast definition](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html).

| Proposed pair | Foreground | Background | Calculated contrast |
| --- | --- | --- | --- |
| Success, light | #146C43 | #D9F2E3 | 5.45:1 |
| Success, dark | #A0D4B4 | #113826 | 7.77:1 |
| Warning, light | #7A4D00 | #FFEDC2 | 6.28:1 |
| Warning, dark | #FFD58A | #402D08 | 9.48:1 |
| Information, light | #175B9B | #DFECFF | 5.85:1 |
| Information, dark | #A8C8FF | #132F50 | 7.98:1 |
| Achievement, light | #92400E | #FEF3C7 | 6.37:1 |
| Achievement, dark | #FCD34D | #452B0B | 9.08:1 |

For these eight opaque pairs, each result exceeds 4.5:1. No equivalent claim is made for alpha overlays, glass, arbitrary pairings, chart series, generated Material schemes, or high-contrast mode. Those require implementation-stage checks. The same inputs appear in the proposal; no companion JSON was requested or produced.

## Architecture insights

The architecture assigns shared theme/tokens to `core` and prohibits core imports from features ([01_architecture_overview.md:37](../../documentation/01_architecture_overview.md#L37), [01_architecture_overview.md:56](../../documentation/01_architecture_overview.md#L56)). The proposed design system follows that boundary. Extract neutral card/sheet presentation while leaving dashboard statuses, calculations, and submission behavior in features.

For example, the current dashboard shell imports dashboard state ([dashboard_card_shell.dart:3](../../../lib/features/dashboard/presentation/widgets/dashboard_card_shell.dart#L3)); moving it wholesale into core would violate the boundary. Weight entry owns dismissal protections through `PopScope` ([weight_entry_bottom_sheet.dart:309](../../../lib/features/weight/presentation/widgets/weight_entry_bottom_sheet.dart#L309)); a shared sheet frame must preserve those caller-owned safeguards.

## Historical context and requirements

- **Supported:** the archived weekly-overview plan deliberately called for neutral pace bars without a contextual verdict ([plan.md:352](../../archive/2026-10-12-weekly-progress-overview/plan.md#L352)). Current bars use the theme primary color ([weekly_pace_chart_card.dart:44](../../../lib/features/dashboard/presentation/widgets/weekly_pace_chart_card.dart#L44)). Do not silently add positive/negative success/error meaning.
- **Still unresolved in inspected documents:** assessment thresholds are an open PRD question ([prd.md:116](../../foundation/prd.md#L116)); roadmap S-07 is blocked ([roadmap.md:52](../../foundation/roadmap.md#L52)). Research does not choose the business classification.
- **Preserve existing data behavior:** missing weight weeks use `FlSpot.nullSpot` ([weekly_weight_trend_card.dart:123](../../../lib/features/dashboard/presentation/widgets/weekly_weight_trend_card.dart#L123)); design changes should keep absence distinct from zero.
- **Scope difference:** the PRD specifies mobile ([prd.md:112](../../foundation/prd.md#L112)), while repository guidance includes web. The proposal keeps the existing web target functional without adding a new desktop/web product initiative.
- No `context/foundation/lessons.md` was present during discovery. No existing design-system change or research artifact was found in the inspected active/archive paths.

## Code references and related research

Anchors are attached to the findings above. The main implementation seams are the app root, home navigation shell, dashboard card/KPI/chart widgets, authentication controls, weight/Hevy sheets, and production test pump helper. The companion [design-system proposal](../../documentation/07_design_system.md) is the planning contract; there was no earlier dedicated design-system research to reconcile.

## Coverage, limitations, and planning handoff

Completed parallel read-only investigations covered repository UI/contracts, iOS/native glass, and Android/Flutter tokens. The primary investigation read the architecture documentation, checked decisive source paths and primary web sources, calculated proposed color contrast, and synthesized the proposal. No app build, dependency change, screenshot capture, or device test was part of research.

Settled recommendations: shared semantic roles; central component themes; fixed spacing scale with meaningful aliases; separate chart/feedback/achievement roles; opaque data surfaces; platform-adaptive controls; localization and accessibility acceptance criteria.

Open implementation checks:

1. Confirm standalone-package compatibility, including `fl_chart` type coupling, and pin SDK/package versions before migration.
2. Compare a small owned UIKit adapter with the candidate native package on the dashboard; verify OS/build requirements, overlays, accessibility, and physical-device performance before selecting it.
3. Visually accept the purple palette, content density, typography, and spacing on representative screens. The document provides proposed defaults rather than requesting brand decisions prematurely.
4. Decide later whether Android dynamic color is desirable. It does not block the base system.

The research question is answered; these checks gate implementation choices rather than conceal missing proof of an already-shipped feature. The next planning input is `/10x-plan design-system`. Existing-screen visual changes should follow the repository's `/10x-ui` entry point.
