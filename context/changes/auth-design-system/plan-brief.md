# Auth Design System Migration — Plan Brief

> Full plan: `context/changes/auth-design-system/plan.md`

## What & Why

Migrate all 6 presentation files in `lib/features/auth/presentation/` (`AuthButton`, `AuthTextField`, `SplashScreen`, `LoginScreen`, `RegisterScreen`, and `HomeShellScreen`) to the Bulk Tempo design system (`package:bulk_tempo/core/design_system.dart`). Today, the auth feature still uses raw Material controls (`FilledButton`, `TextField`, `AlertDialog`, `SnackBar`, `NavigationBar`, `Card`), hardcoded dimensions (`maxWidth: 400`, `fontSize: 16/28`), and raw `Colors.white` spinners, preventing 3-tier platform adaptation (`material`, `cupertinoClassic`, `cupertinoLiquidGlass`) and consistent semantic styling.

## Starting Point

The core design system tokens (`AppSpacing`, `AppShape`, `AppIcons`, `AppSemanticColors`, `AppTheme`) and shared primitives (`AppButton`, `AppTextField`, `AppCard`, `AppDialog`, `AppFeedback`, `AppNavigationShell`) are already implemented in `lib/core/` and proven in `dashboard-design-system` and `gain-target-design-system`. `lib/features/auth/presentation/` has not yet adopted these wrappers and has no Widgetbook catalog coverage under `widgetbook/`.

## Desired End State

All auth screens and widgets render through `package:bulk_tempo/core/design_system.dart` with zero raw color literals or direct `adaptive_platform_ui` imports. `AuthButton` and `AuthTextField` delegate to `AppButton` and `AppTextField` with an adaptive password visibility toggle; `LoginScreen` and `RegisterScreen` display both inline `AppFeedbackBanner`s and paired-token `AppFeedback.showSnackBar`s while locking inputs during submission; `HomeShellScreen` runs on `AppNavigationShell`, `AppDialog.showConfirm`, `AppCard`, and an adaptive language control; and all states are cataloged in `widgetbook/use_cases/auth_use_cases.dart`.

## Key Decisions Made

| Decision | Choice | Why (1 sentence) |
| --- | --- | --- |
| Screen scope | All 4 views (`SplashScreen`, `LoginScreen`, `RegisterScreen`, `HomeShellScreen` + Profile tab) | Completes the entire `lib/features/auth/presentation/` directory and activates `AppNavigationShell` and `AppDialog.showConfirm`. |
| `AuthButton` & `AuthTextField` | Retain as thin delegating wrappers over `AppButton` and `AppTextField` | Satisfies `07_design_system.md:197-198` ("AppButton backs AuthButton", "AppTextField backs AuthTextField") and centralizes auth field/button defaults. |
| Password visibility & icons | Adaptive trailing toggle (`IconButton` on Material, `CupertinoButton` on iOS) with `AppIcon.visibility` / `visibilityOff`, no prefix icons | Preserves native feel and `find.byTooltip` compatibility without sacrificing horizontal input width on `320px` screens at `2.0x` text scale. |
| Form error & busy UX | Inline `AppFeedbackBanner(tone: AppFeedbackTone.error)` + `AppFeedback.showSnackBar` + disable inputs/links during `FormStatus.submitting` | Provides persistent error visibility for screen readers and Widgetbook's 7-state matrix while keeping existing `SnackBar` tests passing and preventing mid-flight edits. |
| Form surface & Register top bar | Open form on `Scaffold` (`AppSpacing.formMaxWidth = 480.0`, `pageInsetWide = 24.0`) + title-free adaptive top bar on `RegisterScreen` | Avoids nested card padding on narrow screens and keeps `find.text('Create Account')` count at 2 (heading + submit button). |
| Hero icon & `SplashScreen` | `AppIcons.resolve(context, AppIcon.workout, selected: true)` (`colorScheme.primary`) + capability-aware spinner | Eliminates raw `Icons.fitness_center` and `TextStyle(fontSize: 28)` literals while adapting the spinner to `CupertinoActivityIndicator` on iOS. |
| `HomeShellScreen` Profile tab | `AppCard(variant: AppCardVariant.outlined)` + `AppButton` + `SegmentedButton` on Material / `CupertinoSlidingSegmentedControl` on Cupertino | Migrates all Profile cards and actions while preserving `home_shell_screen_test.dart`'s `SegmentedButton<String>` cast on Material. |
| Widgetbook & governance | `widgetbook/use_cases/auth_use_cases.dart` (7-state matrices + Splash/HomeShell) + `AGENTS.md` raw-color prohibition | Matches the catalog, smoke-test, and governance contract of `gain-target-design-system` and `dashboard-design-system`. |

## Scope

**In scope:**
- Refactoring `AuthButton` and `AuthTextField` to wrap `AppButton` and `AppTextField` with adaptive password visibility toggling.
- Migrating `SplashScreen`, `LoginScreen`, `RegisterScreen`, and `HomeShellScreen` (navigation shell, logout confirmation dialog, error snackbars, and Profile tab cards/controls) to `package:bulk_tempo/core/design_system.dart`.
- Updating and expanding widget/accessibility tests (`test/features/auth/**`, `test/widgetbook/widgetbook_smoke_test.dart`) across Material and `cupertinoClassic` modes, Polish locale, and `2.0x` text scale.
- Adding `widgetbook/use_cases/auth_use_cases.dart`, registering `authCategory` in `widgetbook/widgetbook_app.dart`, and updating `AGENTS.md`.

**Out of scope:**
- Changes to `AuthRepository`, `AuthViewModel`, `LoginViewModel`, or `RegisterViewModel` validation rules/strings.
- Self-service password reset (`ForgotPasswordScreen`, deferred in `roadmap.md`).
- Internal migration of `WeightHistoryView` or `WorkoutProgressView`.

## Architecture / Approach

All `lib/features/auth/presentation/` files import `package:bulk_tempo/core/design_system.dart`. `AuthButton` and `AuthTextField` act as thin adapters over `AppButton(expand: true)` and `AppTextField`. `LoginScreen` and `RegisterScreen` bind their existing `LoginViewModel` / `RegisterViewModel` states to semantic tokens, inline `AppFeedbackBanner`s, and `AppFeedback.showSnackBar`. `HomeShellScreen` delegates shell rendering to `AppNavigationShell` and confirmation modals to `AppDialog.showConfirm`.

## Phases at a Glance

| Phase | What it delivers | Key risk |
| --- | --- | --- |
| 1. Migrate Auth Widgets & Unauthenticated Screens | `AuthButton`, `AuthTextField`, `SplashScreen`, `LoginScreen`, `RegisterScreen` + Material/Cupertino widget tests | Inline error banner + `SnackBar` sharing the same error text in `login_screen_test.dart` / `register_screen_test.dart` |
| 2. Migrate `HomeShellScreen`, Logout Dialog & Profile Tab | `AppNavigationShell`, `AppDialog.showConfirm`, Profile `AppCard`s/`AppButton`s, adaptive language control + shell tests | Preserving all 4 tab keys, `confirm_logout_button` key, and Material `SegmentedButton` test cast |
| 3. Widgetbook Catalog, Accessibility & Governance | `widgetbook/use_cases/auth_use_cases.dart` 7-state matrices, smoke/accessibility tests, and `AGENTS.md` rule update | Avoiding `WidgetbookUseCase` name collision with `GainTargetView` in `widgetbook_smoke_test.dart` |

**Prerequisites:** Branch `feature/auth-design-system` checked out from `feature/design-system`.
**Estimated effort:** ~1–2 sessions across 3 phases.

## Open Risks & Assumptions

- Headless `flutter test` cannot mount native iOS 26+ `UiKitView`s (`AdaptiveScaffold` / `AdaptiveAlertDialog`), so automated iOS widget tests target `AdaptivePlatformMode.cupertinoClassic` (`iosMajorVersion: 18, supportsNativeIosViews: false`).
- Adding inline `AppFeedbackBanner` alongside `AppFeedback.showSnackBar` renders the failure text twice while the snackbar is active; `login_screen_test.dart` and `register_screen_test.dart` will assert on `Key('login_error_banner')` / `Key('register_error_banner')` and `SnackBar`.

## Success Criteria (Summary)

- Zero raw `Color(...)`, `Colors.*`, `AppPalette.*`, or `adaptive_platform_ui` references in `lib/features/auth/presentation/`.
- All unit, widget, router, localization, and Widgetbook smoke tests pass (`flutter analyze && flutter test`) across Material and `cupertinoClassic` modes, `en`/`pl` locales, and `2.0x` text scaling.
- `Auth` category in Widgetbook renders deterministic 7-state matrices for `LoginScreen` and `RegisterScreen` plus `SplashScreen` and `HomeShellScreen`/Profile use cases.
