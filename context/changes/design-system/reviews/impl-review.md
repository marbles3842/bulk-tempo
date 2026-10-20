<!-- IMPL-REVIEW-REPORT -->
# Implementation Review: Shared Flutter Design System with Platform-Adaptive Controls

- **Plan**: `context/changes/design-system/plan.md`
- **Scope**: Full plan (Phases 1–4)
- **Reviewed phases**: 1, 2, 3, 4
- **Date**: 2026-10-19
- **Verdict**: APPROVED
- **Findings**: 0 critical, 2 warnings, 3 observations

## Verdicts

| Dimension | Verdict |
|-----------|---------|
| Plan Adherence | PASS |
| Scope Discipline | PASS |
| Safety & Quality | PASS |
| Architecture | PASS |
| Pattern Consistency | WARNING |
| Success Criteria | PASS |

## Findings

### F1 — Potential ScrollController conflict in non-draggable AppSheetFrame

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Pattern Consistency
- **Location**: `lib/core/widgets/app_sheet_frame.dart:268`
- **Detail**: In non-draggable mode (`isDraggable == false`), `AppSheetFrame` wraps its body in a `SingleChildScrollView(controller: _scrollController, ...)` and invokes `widget.scrollableBuilder!(context, _scrollController)`. If a caller supplies a scrollable widget that attaches this same `_scrollController`, Flutter throws `"ScrollController attached to multiple scroll views"`.
- **Fix**: When `isDraggable == false` and `scrollableBuilder != null`, render `widget.scrollableBuilder!(context, _scrollController)` directly without the outer `SingleChildScrollView`.
- **Decision**: FIXED (rendered scrollableBuilder directly without outer SingleChildScrollView)

### F2 — widgetbook in dev_dependencies while catalog resides in widgetbook/

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Pattern Consistency
- **Location**: `pubspec.yaml:36`, `widgetbook/main_widgetbook.dart:1`
- **Detail**: `widgetbook: ^3.25.0` is declared under `dev_dependencies` while the standalone catalog lives at root-level `widgetbook/` outside `lib/`.
- **Fix**: Retain the current suppressed setup as planned, or relocate `lib/widgetbook/` to root-level `widgetbook/` in a future chore.
- **Decision**: FIXED + ACCEPTED-AS-RULE: Separate Dev Tooling and Component Catalogs from Production lib/

### F3 — AppDialogAction defined but not consumed by AppDialog.showConfirm

- **Severity**: 💡 OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Pattern Consistency
- **Location**: `lib/core/widgets/app_dialog.dart:7`
- **Detail**: `AppDialogAction` is defined as a public data model with properties (`label`, `isDestructive`, `isDefaultAction`, etc.), but `AppDialog` only exposes `showConfirm`, which takes individual `confirmLabel`/`cancelLabel` strings.
- **Fix**: Retain `AppDialogAction` as a foundation model for multi-action dialogs in future feature migrations.
- **Decision**: ACCEPTED (retained as foundational model for upcoming multi-action dialogs)

### F4 — AppNavigationShell wide-screen layout only implemented for Material

- **Severity**: 💡 OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Pattern Consistency
- **Location**: `lib/core/widgets/app_navigation_shell.dart:200`
- **Detail**: Material mode adaptively renders `NavigationRail` for viewports `>= 840px` and `NavigationBar` for `< 840px`. Cupertino modes render a bottom tab bar across all widths.
- **Fix**: Consider adding a split-view or sidebar navigation rail for wide iPad viewports if tablet support is prioritized.
- **Decision**: ACCEPTED (phone-first navigation is sufficient for current scope)

### F5 — AppButton label single-line truncation under extreme text scaling

- **Severity**: 💡 OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Pattern Consistency
- **Location**: `lib/core/widgets/app_button.dart:183`
- **Detail**: `AppButton` labels use `maxLines: 1` with `TextOverflow.ellipsis`. On narrow 320px screens at `>2.0x` text scaling with long localized Polish phrases, text truncates with ellipsis rather than wrapping.
- **Fix**: Allow `maxLines: 2` or provide accessible tooltip / semantics announcement when text scaling is high.
- **Decision**: ACCEPTED (single-line button text with accessible Semantics is standard)
