# Gain Target Design System Migration Implementation Plan

## Overview

Migrate the existing `GainTargetView` to Bulk Tempo's shared design system. Preserve its current content hierarchy, localized copy, validation, save/refresh lifecycle, and account behavior while replacing feature-local Material styling with app-owned adaptive components and semantic theme tokens.

## Current State Analysis

`GainTargetView` is one Profile-embedded presentation widget at `lib/features/gain_target/presentation/views/gain_target_view.dart`. It owns text controllers and listens to `GainTargetViewModel`, which already supplies the loading, saved/empty, refresh, validation, submission, success, and failure states. This change should remain in the presentation layer; no domain, repository, database, routing, or Profile-shell work is needed.

The shared design system already exists under `lib/core/`. `AppCard`, `AppTextField`, `AppButton`, `AppFeedback`, `AppFeedbackBanner`, and semantic token classes cover the target view's primary needs. `DashboardCardShell` is a nearby example of using `AppCard`, semantic feedback, and `AppButton` for loaded/loading/error/empty content.

### Key Discoveries:

- `gain_target_view.dart:104-112` builds a card with local border, radius, and padding instead of `AppCard`.
- `gain_target_view.dart:242-269` creates both numeric fields directly with `TextField` and `InputDecoration`, bypassing `AppTextField`'s Material/Cupertino dispatch.
- `gain_target_view.dart:70-98` sends success and errors through locally styled `SnackBar`s; success uses `Colors.green.shade700` instead of the semantic success pair exposed by `AppFeedback`.
- `gain_target_view.dart:126-140,183-190,276-283` uses direct Material actions; `AppButton` covers labeled save/retry actions, while the shared theme and semantic icon tokens should style the icon-only refresh control.
- The view contains local spacing, radius, and icon values (for example `gain_target_view.dart:107-111,144-147,204-219,241-295`) where `AppSpacing`, `AppShape`, and `AppIcons` already provide app-level values.
- `lib/features/dashboard/presentation/widgets/dashboard_card_shell.dart:50-132` demonstrates the existing shared-component pattern. `lib/core/widgets/app_feedback.dart:192-235` supplies paired-color snackbars, and `lib/core/widgets/app_button.dart` and `app_text_field.dart` supply adaptive controls.
- `test/features/gain_target/presentation/views/gain_target_view_test.dart` covers the main form states, server confirmation, error handling, and Polish formatting. Some assertions target Material widget types and will need to assert the app-owned component contract after migration.
- The root `widgetbook/` catalog contains dashboard and primitive examples but no gain-target use cases. There is no separate screenshot-test or kitchen-sink harness in the repository.

## Desired End State

The gain-target card uses the existing design-system components and semantic tokens, with no local color literals or duplicated card/form/button styling. The current information order and behavior remain intact, and native controls use the documented platform dispatch. Tests and catalog examples make the target's key user states reviewable in English and Polish, with visual checks at desktop and mobile widths.

### Verification

The target widget tests cover the existing save, refresh, validation, pending, and error contracts after switching assertions to app-owned components. A gain-target catalog example exposes the seven-state matrix, and its rendered states are inspected in supported theme/platform modes. The normal repository checks are run during implementation; this plan-writing step does not run them.

## What We're NOT Doing

- Changing `GainTargetViewModel`, validation rules, entities, repositories, persistence, or network behavior.
- Reordering the Profile screen, restyling its shell, or changing the neighboring Hevy integration card.
- Adding a new adaptive dependency, general-purpose component, global token, theme, or Profile setting.
- Changing gain-target copy, English/Polish localization, units, sample values, snackbar messages, refresh semantics, or save-pending semantics.
- Introducing a new screenshot-testing dependency or modifying unrelated feature screens.

## Implementation Approach

Use the existing design-system contract as the source of truth. First map each audited charge to an existing token or wrapper. Then migrate only `GainTargetView`: use `AppCard` for the outer surface, `AppTextField` for the two numeric inputs, `AppButton` for labeled save/retry actions, `AppFeedback.showSnackBar` for success/error feedback, and existing spacing/shape/icon/theme roles for remaining local composition. Keep the summary strip and refresh action feature-local where no shared component matches, but style them exclusively through existing tokens and the centrally themed control family. Add no token or dependency unless implementation proves the current contract cannot express a required state.

The state and repository contracts remain unchanged. Tests and Widgetbook force supported presentation capabilities for deterministic Material and classic Cupertino rendering; native iOS Liquid Glass behavior is checked on supported iOS hardware/simulator because headless Flutter tests cannot validate UIKit-backed rendering.

## Phase 1: Map Existing Tokens and Components

### Overview

Record the view's UI charges, apply existing tokens to its local composition, and map the remaining controls to shared components. Confirm that the current palette, shape, spacing, icon, feedback, and adaptive APIs cover the view without expanding global scope.

### Changes Required:

#### 1. Tokenized local composition

**File**: `lib/features/gain_target/presentation/views/gain_target_view.dart`

**Intent**: Map local spacing, shape, icon, and summary-surface styling to the existing tokens, and begin applying those tokens to feature-local composition that has no matching shared primitive.

**Contract**: Use `AppSpacing`, `AppShape`, `AppIcons`, and semantic theme roles for local layout, summary, loading, and error composition. Replace the semi-transparent summary fill with an opaque semantic surface. Do not change content order or introduce a feature-only primitive. The audited lines and user effects are listed in Current State Analysis; any charge left unchanged must be marked deferred with a reason.

#### 2. Design-system references

**Files**: `context/documentation/07_design_system.md`, `lib/core/design_system.dart`, `lib/core/theme/`, `lib/core/widgets/`

**Intent**: Use the documented app-owned adaptive wrappers and semantic tokens rather than duplicating presentation policy inside the feature.

**Contract**: Preserve the Material 3 Android/web and Cupertino iOS dispatch behind `lib/core/widgets/`; maintain opaque, token-based content surfaces, semantic foreground/container feedback pairs, and direction-aware spacing where applicable.

### Success Criteria:

#### Automated Verification:

- Existing gain-target view tests pass after feature-local spacing, shape, icon, and summary/error/loading styling move to existing tokens.

#### Manual Verification:

- The current summary and card hierarchy remain readable with the opaque semantic summary surface.

## Phase 2: Migrate the Gain-target View

### Overview

Replace direct Material presentation with the shared design system while retaining the existing state wiring, text-controller lifecycle, visible copy, content order, and keys used by tests and assistive technology.

### Changes Required:

#### 1. Gain-target card and summary

**File**: `lib/features/gain_target/presentation/views/gain_target_view.dart`

**Intent**: Replace the locally styled outer `Card` with `AppCard`; use existing theme, spacing, shape, and icon roles for the title, summary strip, refresh action, and loading/error layouts.

**Contract**: Keep the `GainTargetView` public API and Profile embedding unchanged. Retain `gain_target_summary`, `gain_target_refresh_button`, and `gain_target_loading_indicator` keys. Keep the current target summary, no-target state, content order, refresh tooltip, and refresh-disabled-while-submitting behavior. Keep the summary strip feature-local if needed, using opaque semantic surfaces rather than translucent or literal colors.

#### 2. Adaptive inputs, actions, and feedback

**File**: `lib/features/gain_target/presentation/views/gain_target_view.dart`

**Intent**: Use `AppTextField` for minimum/maximum input, `AppButton` for save/retry, and `AppFeedback.showSnackBar` with success/error tones for transient feedback.

**Contract**: Preserve keys `gain_target_min_field`, `gain_target_max_field`, `gain_target_save_button`, and `gain_target_retry_button`; preserve controllers, decimal keyboard, hints, unit suffixes, validation messages, and `onChanged` calls. Save remains disabled and inputs remain non-editable while submitting; the pending server-confirmation indicator remains visible. Successful reads/writes, refresh failures, and save failures continue to clear ViewModel messages after presentation. Keep the icon-only refresh accessible by its existing localized tooltip and centrally themed; do not create an app-wide icon-button primitive for this one view.

#### 3. Gain-target widget tests

**File**: `test/features/gain_target/presentation/views/gain_target_view_test.dart`

**Intent**: Update view-level assertions to verify the new app-owned component contract while preserving coverage of existing user behavior.

**Contract**: Keep repository and auth overrides. Assert keys, enabled/busy states, field values/labels/hints/errors, summary formatting, and feedback messages rather than depending on `FilledButton` or other implementation-only Material types. Continue covering absent/saved targets, valid/invalid input, successful save, pending confirmation, load retry, and Polish formatting.

### Success Criteria:

#### Automated Verification:

- Existing gain-target view tests pass with shared components in the default Material presentation mode.
- Tests confirm current target/no target, validation, save confirmation, pending/disabled controls, retry, and localized formatting remain unchanged.
- No success color literal or duplicated card/field/button styling remains in `GainTargetView`; remaining local composition reads from existing tokens.

#### Manual Verification:

- The Profile-embedded view retains its content order and fits the existing scrolling layout without changing the Profile shell or neighboring card.

## Phase 3: Cover States and Verify the Visual Result

### Overview

Make the view's important states and adaptive behavior easy to review. Add catalog examples and verify the state matrix without adding a screenshot framework or relying only on the happy path.

### Changes Required:

#### 1. Gain-target Widgetbook use cases

**File**: `widgetbook/use_cases/gain_target_use_cases.dart` (new)

**Intent**: Add a focused catalog entry for the migrated view, following the existing root-level Widgetbook conventions.

**Contract**: Provide deterministic examples for default/saved, empty/no target, loading, validation or fetch error, disabled/busy, and success feedback states in a gain-target kitchen-sink use case that renders the state matrix together. Show hover and focus-visible on interactive controls where the platform supports them; mark a state N/A only with a reason. Keep catalog fixtures isolated from production providers and avoid real Firebase/auth access.

#### 2. Widgetbook registration and state coverage

**Files**: `widgetbook/widgetbook_app.dart`, `widgetbook/use_cases/gain_target_use_cases.dart`, `test/widgetbook/` (existing smoke-test location if present)

**Intent**: Make the target cases available to the existing catalog and ensure they render with the same theme/platform controls used for other component examples.

**Contract**: Cover the seven-state matrix (default, hover, focus-visible, disabled, error, empty, loading), with English/Polish copy, light/dark themes, enlarged text, and Material/Cupertino-classic capability overrides. Do not attempt UIKit platform-view rendering in headless widget tests; reserve Liquid Glass verification for supported iOS runtime.

#### 3. Gain-target visual and accessibility verification

**Files**: `test/features/gain_target/presentation/views/gain_target_view_test.dart`, `widgetbook/`

**Intent**: Check layout and control semantics in addition to test assertions, especially states most likely to drift during a component migration.

**Contract**: Capture and inspect the catalog's kitchen-sink render at one desktop and one mobile width. Check focus visibility, readable disabled/busy controls, accessible labels/tooltips, field errors, tap targets, and large-text wrapping. Compare light and dark presentation and confirm the Polish text does not clip. Use existing tooling; do not add a screenshot dependency.

#### 4. Keep the view on the design-system contract

**Files**: `AGENTS.md`, `.github/workflows/ci.yml` (and a small scoped script under `tool/` only if it makes the check clearer)

**Intent**: Make the token/component source easy for future changes to find and catch raw view styling before it returns.

**Contract**: Extend the existing repository rule with the `lib/core/theme/` and `lib/core/widgets/` sources, require checking shared components before creating feature-local styling, and forbid raw colors in the gain-target view. Add a dependency-free CI scan scoped to `gain_target_view.dart`; do not add a linter package or alter unrelated checks.

### Success Criteria:

#### Automated Verification:

- Widgetbook smoke coverage can build the gain-target catalog entry without touching production data providers.
- Widget tests verify semantics, focused/disabled/error states, and Material/Cupertino-classic fallback behavior where representable in Flutter tests.
- Repository guidance names the existing token/component sources, and CI rejects raw color literals in the migrated view without a new dependency.
- `dart format lib test widgetbook`, `flutter analyze`, and `flutter test` pass after implementation.

#### Manual Verification:

- Capture and inspect the full state-matrix kitchen-sink at desktop and mobile widths in light and dark themes, English and Polish, and enlarged text; document any N/A state with its reason.
- Verify Cupertino-classic fallback in the catalog and inspect native adaptive behavior on supported iOS, including Liquid Glass snackbar/control rendering when available.

## Testing Strategy

### Unit Tests:

- No domain or ViewModel behavior changes are planned. Retain existing ViewModel tests as regression coverage; do not modify them unless presentation integration exposes a concrete contract issue.

### Widget Tests:

- Preserve the existing gain-target view cases for no target, saved target, localized range, valid save, invalid range, pending save, and load retry.
- Add/adjust assertions for AppCard/AppTextField/AppButton behavior, semantic feedback, disabled state, focus and labels, and classic Cupertino fallback. Use test overrides for presentation capabilities rather than invoking native UIKit views.
- Add a Widgetbook smoke test for the gain-target category if the current catalog test structure supports category coverage.
- Keep the migration from drifting back by extending `AGENTS.md` and adding the focused raw-color scan to the existing CI verification job; the repository already runs Flutter analysis and tests in `.github/workflows/ci.yml` and has no custom lint or pre-commit hook.

### Manual Testing Steps:

1. Open the gain-target catalog examples in light/dark themes and English/Polish locales; inspect desktop and mobile widths.
2. Check default, no-target, saved, loading, error/retry, validation, and pending states; verify focus/hover where supported, accessible naming, disabled contrast, and large-text wrapping.
3. Open Profile on supported iOS and confirm the adaptive controls/feedback remain readable and do not alter the outer Profile layout; check Liquid Glass behavior only on a runtime that supports it.

## Performance Considerations

This is a local presentation migration with no data-flow, subscription, or dependency changes. The existing ViewModel and provider lifecycle remain in place.

## Migration Notes

There is no persisted-data or API migration. The design-system change affects only the gain-target presentation view, its focused widget tests, and the Widgetbook catalog.

## References

- `context/documentation/07_design_system.md` — design-system component, token, accessibility, catalog, and platform contract.
- `context/changes/design-system/plan-brief.md` — existing shared design-system decisions and supported themes/components.
- `context/changes/set-gain-target/plan-brief.md` — accepted target behavior and current form/save semantics.
- `lib/features/dashboard/presentation/widgets/dashboard_card_shell.dart:50-132` — established use of AppCard, AppButton, and loading/error/empty presentation.
- `lib/core/widgets/app_feedback.dart:192-235`, `lib/core/widgets/app_text_field.dart`, `lib/core/widgets/app_button.dart` — shared adaptive feedback and control APIs.
- `lib/features/gain_target/presentation/views/gain_target_view.dart:54-299` — current state binding and UI to migrate.

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands. Do not rename step titles. See `references/progress-format.md`.

### Phase 1: Map Existing Tokens and Components

#### Automated

- [x] 1.1 Tokenize local spacing, shape, icon, summary, loading, and error composition; keep view tests passing.

#### Manual

- [x] 1.2 Confirm the summary and card hierarchy remain readable with an opaque semantic surface.

### Phase 2: Migrate the Gain-target View

#### Automated

- [x] 2.1 Replace direct styling with shared components and semantic tokens while preserving state behavior.
- [x] 2.2 Update gain-target widget tests to assert the app-owned component contract and existing behavior.
- [x] 2.3 Pass focused gain-target view tests in Material presentation mode.

#### Manual

- [ ] 2.4 Confirm Profile embedding, content order, and scroll layout remain intact.

### Phase 3: Cover States and Verify the Visual Result

#### Automated

- [ ] 3.1 Add deterministic gain-target Widgetbook examples and catalog registration.
- [ ] 3.2 Cover the applicable state matrix and adaptive fallback behavior in tests/catalog.
- [ ] 3.3 Add the local design-system rule and scoped raw-color CI guard.
- [ ] 3.4 Pass format, analysis, and full Flutter test checks.

#### Manual

- [ ] 3.5 Inspect state renders at desktop/mobile widths, across themes/locales and enlarged text.
- [ ] 3.6 Verify native iOS adaptive rendering on a supported runtime when available.
