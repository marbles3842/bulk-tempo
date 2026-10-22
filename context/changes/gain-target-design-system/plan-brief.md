# Gain Target Design System Migration — Plan Brief

> Full plan: `context/changes/gain-target-design-system/plan.md`

## What & Why

This change migrates the existing gain-target card and form to Bulk Tempo's shared design system. It removes one-off Material styling while keeping the current target, form behavior, localized copy, and save/refresh states familiar to users.

## Starting Point

`GainTargetView` is embedded in Profile and directly creates its Card, TextFields, FilledButtons, and SnackBars. The app already has adaptive card, field, button, feedback, token, and theme primitives, plus widget tests for the main target states.

## Desired End State

The gain-target view uses existing semantic tokens and adaptive components while preserving its layout and ViewModel behavior. Tests and catalog examples expose the saved, empty, loading, error, validation, and busy states, with desktop/mobile and accessibility checks.

## Key Decisions Made

| Decision | Choice | Why (1 sentence) |
| --- | --- | --- |
| Migration boundary | `GainTargetView` only | Keeps the request focused and leaves the Profile shell and neighboring cards unchanged. |
| Layout | Preserve current information order and form layout | This is a design-system migration, so the existing user flow remains stable as styling changes. |
| Components and tokens | Reuse existing app-owned wrappers and semantic tokens | The design system already defines adaptive platform controls and shared presentation roles. |
| Dependencies and global tokens | Add none unless a concrete design-system gap is found | Avoids expanding the foundation for a single feature view. |
| Visual verification | Widgetbook states plus desktop/mobile inspection | The repo has a Widgetbook catalog but no dedicated screenshot-testing framework. |

## Scope

**In scope:** `GainTargetView`, its focused widget tests, a gain-target Widgetbook use case, catalog/smoke coverage, a local design-system rule in `AGENTS.md`, and a dependency-free raw-color CI guard scoped to the view. Preserve current validation, localization, pending-save, refresh, and feedback behavior.

**Out of scope:** Profile-shell redesign, neighboring cards, ViewModel/domain/data changes, new dependencies, broad theme/token changes, and other feature views.

## Architecture / Approach

Keep the current feature state flow and change only presentation. Use `AppCard`, `AppTextField`, `AppButton`, `AppFeedback`, and existing theme tokens; keep feature-local composition only where no shared primitive fits. Use deterministic test/catalog overrides for Material and Cupertino-classic modes, and reserve UIKit-backed Liquid Glass checks for a supported iOS runtime.

## Phases at a Glance

| Phase | What it delivers | Key risk |
| --- | --- | --- |
| 1. Map Existing Tokens and Components | A charge-to-token/component map with no unnecessary global changes | Missing a real visual role and leaving one-off styling behind |
| 2. Migrate the Gain-target View | Adaptive shared components with existing state behavior and widget tests | Wrapper differences can break test assumptions or lose field/error semantics |
| 3. Cover States and Verify the Visual Result | Seven-state catalog examples, a repository usage rule, and accessibility/visual checks | Native UIKit rendering cannot be validated in headless tests |

**Prerequisites:** The shared design-system primitives and the existing gain-target feature are present.
**Estimated effort:** About 1–2 implementation sessions across 3 phases.

## Open Risks & Assumptions

- `AppTextField` and `AppButton` may expose inner platform widgets differently from the current test assertions; tests should target the app-owned contracts.
- UIKit-backed Liquid Glass rendering requires a supported iOS runtime; Flutter tests and web Widgetbook can verify the classic fallback and shared behavior only.
- The gain-target summary strip has no exact shared component match; keep it local and use existing opaque semantic tokens rather than extracting a new primitive.

## Success Criteria (Summary)

- The gain-target view uses existing app tokens and wrappers without changing its state, localization, or save/refresh behavior.
- Existing feature tests and new catalog/state coverage verify empty, saved, loading, error, validation, busy, focus, and disabled behavior.
- Desktop/mobile renders remain readable in English and Polish, light/dark themes, and enlarged text; supported iOS adaptive rendering is checked on device/simulator.
