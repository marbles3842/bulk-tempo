# Auth Design System Migration Implementation Plan

## Overview

Migrate all widgets and views in `lib/features/auth/presentation/` (`AuthButton`, `AuthTextField`, `SplashScreen`, `LoginScreen`, `RegisterScreen`, and `HomeShellScreen` including its logout confirmation dialog and Profile tab) to the Bulk Tempo design system (`package:bulk_tempo/core/design_system.dart`). This completes the `auth` feature rollout specified in `context/documentation/07_design_system.md`, replacing raw Material controls, hardcoded dimensions, and raw `Colors.white` / `SnackBar` / `AlertDialog` usage with semantic tokens and 3-tier platform-adaptive primitives (`AdaptivePlatformMode.material`, `cupertinoClassic`, and `cupertinoLiquidGlass`), backed by comprehensive widget tests and a Widgetbook 7-state catalog.

## Current State Analysis

The `auth` presentation layer (`lib/features/auth/presentation/`) was built in slice `S-01` (`private-account-access`) prior to the core design system and still constructs raw Material widgets and local styling tokens:

- **`AuthButton` (`lib/features/auth/presentation/widgets/auth_button.dart:3-35`)**: Wraps a raw `FilledButton` with a hardcoded `minimumSize: const Size.fromHeight(48)` (`:19`), a raw `CircularProgressIndicator(strokeWidth: 2, color: Colors.white)` (`:24-27`), and `const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)` (`:31`).
- **`AuthTextField` (`lib/features/auth/presentation/widgets/auth_text_field.dart:3-53`)**: Wraps a raw Material `TextField` (`:35-51`) with `InputDecoration(..., border: const OutlineInputBorder())` (`:44-50`) instead of `AppTextField`.
- **`SplashScreen` (`lib/features/auth/presentation/views/splash_screen.dart:5-28`)**: Uses a raw `const Icon(Icons.fitness_center, size: 72)` (`:15`), `const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)` (`:19`), raw `SizedBox(height: 16 / 24)` (`:16, 21`), and a Material-only `const CircularProgressIndicator()` (`:22`).
- **`LoginScreen` (`lib/features/auth/presentation/views/login_screen.dart:12-169`) & `RegisterScreen` (`lib/features/auth/presentation/views/register_screen.dart:10-165`)**:
  - Constrain forms to `BoxConstraints(maxWidth: 400)` (`login_screen.dart:88`, `register_screen.dart:84`) instead of `AppSpacing.formMaxWidth` (`480.0`), with raw `EdgeInsets.symmetric(horizontal: 24.0)` and `SizedBox` gaps (`8`, `16`, `24`, `32`).
  - Use raw `const Icon(Icons.fitness_center, size: 56)` (`login_screen.dart:93`, `register_screen.dart:89`) and raw `IconButton` with `Icons.visibility_outlined` / `Icons.visibility_off_outlined` (`login_screen.dart:132-146`, `register_screen.dart:128-142`) for password visibility toggling.
  - Show submission errors only via raw `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(...), backgroundColor: Theme.of(context).colorScheme.error))` (`login_screen.dart:58-63, 70-75`, `register_screen.dart:60-65`) without an inline `AppFeedbackBanner` for persistent screen-reader and static state-matrix visibility.
  - Keep text fields and secondary navigation buttons (`TextButton` with `Key('login_to_register_button')` / `Key('register_to_login_button')`) enabled during `FormStatus.submitting`.
  - `RegisterScreen` uses a Material-only `AppBar` with a leading `IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goToLogin)` (`register_screen.dart:73-78`) lacking a tooltip and Cupertino adaptation.
- **`HomeShellScreen` (`lib/features/auth/presentation/views/home_shell_screen.dart:13-329`)**:
  - Renders a raw `Scaffold` + `AppBar` + `NavigationBar` (`:275-327`) instead of `AppNavigationShell` (`lib/core/widgets/app_navigation_shell.dart:65-293`).
  - Presents a raw `AlertDialog` with two `TextButton` actions (`:23-47`) for logout confirmation instead of `AppDialog.showConfirm` (`lib/core/widgets/app_dialog.dart:48-165`).
  - Uses raw `ScaffoldMessenger.of(context).showSnackBar` (`:248-253`) on sign-out failure instead of `AppFeedback.showSnackBar`.
  - Builds the inline Profile tab (`_buildProfileTab`, `:49-182`, and `_buildLanguageCard`, `:184-241`) using raw `Card` widgets with `BorderRadius.circular(12)`, raw `FilledButton.tonal`, `OutlinedButton`, `OutlinedButton.icon`, `SegmentedButton<String>`, raw `Icons.*`, and raw `EdgeInsets` / `SizedBox` values.
- **Widgetbook Catalog (`widgetbook/widgetbook_app.dart:16-22`)**: Exports `tokensCategory`, `primitivesCategory`, `overlaysAndShellCategory`, `dashboardCategory`, and `gainTargetCategory`, with no `authCategory` or `widgetbook/use_cases/auth_use_cases.dart`.

## Desired End State

All 6 files in `lib/features/auth/presentation/` consume the design system exclusively via `package:bulk_tempo/core/design_system.dart`, with zero raw color literals (`Color(...)`, `Colors.*`), zero direct `AppPalette` references, and zero direct `adaptive_platform_ui` imports:

1. **`AuthButton` and `AuthTextField`** remain as thin delegating wrappers over `AppButton` and `AppTextField`, fulfilling `context/documentation/07_design_system.md:197-198` and providing platform-adaptive password visibility toggle support with accessible tap targets and localized tooltips.
2. **`SplashScreen`, `LoginScreen`, and `RegisterScreen`** use `AppSpacing`, `AppIcons.resolve(context, AppIcon.workout, selected: true)`, semantic typography (`Theme.of(context).textTheme`), `AppFeedbackBanner(tone: AppFeedbackTone.error)` + `AppFeedback.showSnackBar(tone: AppFeedbackTone.error)`, `AppButton(variant: AppButtonVariant.text)`, input/button disabling during `FormStatus.submitting`, and an adaptive top navigation bar on `RegisterScreen`.
3. **`HomeShellScreen`** delegates its scaffold, top toolbar (`Key('home_app_bar_logout_button')`), and 4-tab navigation (`Key('nav_home_tab')`, `Key('nav_weights_tab')`, `Key('nav_workouts_tab')`, `Key('nav_profile_tab')`) to `AppNavigationShell`, its logout confirmation modal to `AppDialog.showConfirm(..., isDestructive: true, confirmButtonKey: const Key('confirm_logout_button'))`, its sign-out error toast to `AppFeedback.showSnackBar(..., tone: AppFeedbackTone.error)`, and its Profile tab cards and controls to `AppCard(variant: AppCardVariant.outlined)`, `AppButton`, `AppSpacing`, `AppIcons`, and a platform-adaptive language selector (`SegmentedButton<String>` on Material, `CupertinoSlidingSegmentedControl<String>` on Cupertino).
4. **Tests & Widgetbook**: All existing widget, router, and localization tests pass alongside new Cupertino fallback (`AdaptivePlatformMode.cupertinoClassic`), `2.0x` text-scaling, and narrow-viewport tests; `widgetbook/use_cases/auth_use_cases.dart` catalogs the 7-state matrices for `LoginScreen` and `RegisterScreen` plus `SplashScreen` and `HomeShellScreen`/Profile use cases; and `AGENTS.md` forbids raw colors across all `lib/features/auth/presentation/` files.

### Key Discoveries:

- **`AppTextField` key forwarding (`lib/core/widgets/app_text_field.dart:36, 112, 229`)**: `AppTextField.fieldKey` is passed directly to the inner `TextField` on Material and `CupertinoTextField` on Cupertino, preserving `tester.enterText(find.byKey(const Key('login_email_field')), ...)` without test breakage.
- **`AppNavigationShell` destination and toolbar keys (`lib/core/widgets/app_navigation_shell.dart:118-195, 200-252, 254-292`)**: `AppNavigationDestinationItem.key` and `AppToolbarAction.key` attach directly to the rendered destination and toolbar buttons across Material (`NavigationBar` `<840px` and `NavigationRail` `>=840px`) and Cupertino (`CupertinoNavigationBar` + `CupertinoTabBar`).
- **`AppDialog.showConfirm` destructive action (`lib/core/widgets/app_dialog.dart:48-165`)**: Renders an `AlertDialog` with a destructive `FilledButton` (`key: confirmButtonKey`) on Material and a `CupertinoAlertDialog` with `CupertinoDialogAction(key: confirmButtonKey, isDestructiveAction: true)` on `cupertinoClassic`.
- **`SegmentedButton` test contract (`test/features/auth/presentation/views/home_shell_screen_test.dart:874, 883`)**: Existing Profile tab tests look up `tester.widget<SegmentedButton<String>>(find.byKey(const Key('profile_language_selector')))` under default Material test capabilities; keeping `SegmentedButton<String>` on `AdaptivePlatformMode.material` while rendering `CupertinoSlidingSegmentedControl<String>` on Cupertino modes satisfies both the existing test contract and platform adaptation.
- **Widgetbook smoke test lookup (`test/widgetbook/widgetbook_smoke_test.dart:138-140`)**: The existing smoke test calls `allUseCases.singleWhere((item) => item.name == 'Kitchen Sink — State Matrix')`; new Auth state-matrix use cases must use distinct names (e.g., `'Login — State Matrix'`, `'Register — State Matrix'`) and/or scope the lookup so `singleWhere` never collides.

## What We're NOT Doing

- **No auth domain, data, or ViewModel validation rule changes**: `AuthRepository`, `AuthViewModel`, `LoginViewModel`, and `RegisterViewModel` business logic and English validation strings (`'Email is required'`, `'Please enter a valid email address'`, `'Password is required'`, `'Password must be at least 6 characters'`) remain unchanged so existing ViewModel and screen validation tests stay intact.
- **No self-service password reset (`ForgotPasswordScreen`)**: Explicitly deferred in `context/foundation/roadmap.md:106, 204` and `context/changes/private-account-access/plan.md:36`.
- **No wrapping of Login/Register forms inside `AppCard`**: Per user decision, `LoginScreen` and `RegisterScreen` remain open forms directly on the `Scaffold` surface constrained to `AppSpacing.formMaxWidth` (`480.0`) with `AppSpacing.pageInsetWide` (`24.0`) horizontal padding.
- **No prefix icons (`email`/`lock`) on auth text fields**: Per user decision, auth text fields omit prefix icons to preserve horizontal text space on narrow `320px` viewports at `2.0x` text scale.
- **No changes to `WeightHistoryView` or `WorkoutProgressView` internals**: Those feature views are rendered inside `HomeShellScreen` tabs 1 and 2 and belong to their respective feature modules.

## Implementation Approach

Follow the 3-phase migration structure established in `dashboard-design-system` and `gain-target-design-system`:

1. **Phase 1** upgrades the shared auth form primitives (`AuthButton`, `AuthTextField`) to delegate to `AppButton` and `AppTextField`, and migrates the unauthenticated screens (`SplashScreen`, `LoginScreen`, `RegisterScreen`) along with their unit/widget tests across Material and `cupertinoClassic`.
2. **Phase 2** migrates the authenticated shell (`HomeShellScreen`), replacing the raw navigation bar with `AppNavigationShell`, the raw logout dialog with `AppDialog.showConfirm`, the raw error snackbar with `AppFeedback.showSnackBar`, and the inline Profile tab cards/controls with `AppCard`, `AppButton`, `AppSpacing`, `AppIcons`, and an adaptive language control.
3. **Phase 3** adds the `Auth` Widgetbook category (`widgetbook/use_cases/auth_use_cases.dart`) with deterministic `ProviderScope` overrides covering the 7-state matrices for `LoginScreen` and `RegisterScreen` plus `SplashScreen` and `HomeShellScreen`/Profile use cases, extends `test/widgetbook/widgetbook_smoke_test.dart`, and updates `AGENTS.md` to prohibit raw colors across all `lib/features/auth/presentation/` files.

## Critical Implementation Details

- **Password visibility toggle in `AuthTextField` / `AppTextField`**: When `AuthTextField` (or `LoginScreen` / `RegisterScreen` via `AuthTextField`) renders a trailing password visibility toggle, it must resolve `AppIcons.resolve(context, obscureText ? AppIcon.visibility : AppIcon.visibilityOff)`, expose the localized tooltip (`showPasswordTooltip` / `hidePasswordTooltip`) so `find.byTooltip('Show password')` and `find.byTooltip('Pokaż hasło')` match in both Material (`IconButton`) and Cupertino (`Tooltip` + `CupertinoButton` with `minSize: AppSpacing.iosMinTapTarget`), and disable when `enabled == false`.
- **Inline error banner + snackbar coordination on `LoginScreen` and `RegisterScreen`**: Both `LoginScreen` and `RegisterScreen` keep their `ref.listen` hooks calling `AppFeedback.showSnackBar(context, message: ..., tone: AppFeedbackTone.error)` on failure transitions (so existing `find.byType(SnackBar)` tests pass), and also render an inline `AppFeedbackBanner(bannerKey: const Key('login_error_banner') / Key('register_error_banner'), message: errorMessage, tone: AppFeedbackTone.error)` above the submit button when `formState.status == FormStatus.failure && formState.errorMessage != null` (or `authState.errorMessage != null` on `LoginScreen`). To avoid duplicate `find.text(errorMessage)` collisions in existing tests that assert `expect(find.text('Invalid email or password'), findsOneWidget)` while the `SnackBar` is visible, verify whether existing tests use `findsOneWidget` on the error message text:
  - In `test/features/auth/presentation/views/login_screen_test.dart:126`: `expect(find.text('Invalid email or password'), findsOneWidget);`
  - In `test/features/auth/presentation/views/register_screen_test.dart:132-135`: `expect(find.text('Registration failed. Please check your details or try signing in'), findsOneWidget);`
  - Because `find.text(...)` matches every `Text` widget in the tree, rendering the exact same `errorMessage` string simultaneously in both an inline `AppFeedbackBanner` and a live `SnackBar` would cause `find.text(...)` to match **2** widgets (`findsOneWidget` would fail in `login_screen_test.dart:126` and `register_screen_test.dart:135` unless updated or coordinated)! Therefore, update those two test assertions to verify both `find.byKey(const Key('login_error_banner'))` / `find.byKey(const Key('register_error_banner'))` and `find.byType(SnackBar)` (or `findsAtLeastNWidgets(1)`).
- **`RegisterScreen` title vs submit button text in `register_screen_test.dart:37`**: In English and Polish, `registerTitle` and `registerButton` have the same string (`'Create Account'` / `'Utwórz konto'`), and `register_screen_test.dart:37` and `polish_rendering_test.dart:74` assert `expect(find.text('Create Account'), findsNWidgets(2))`. Therefore, `RegisterScreen`'s adaptive top bar must remain title-free (only a back button, matching the current `AppBar(leading: ...)` at `register_screen.dart:73-78`) so a third `'Create Account'` `Text` widget is not added.

---

## Phase 1: Migrate Auth Widgets & Unauthenticated Screens

### Overview

Refactor `AuthButton` and `AuthTextField` to delegate to `AppButton` and `AppTextField` with adaptive password visibility toggling, migrate `SplashScreen`, `LoginScreen`, and `RegisterScreen` to `package:bulk_tempo/core/design_system.dart`, and add/update widget tests for both Material and `cupertinoClassic` modes.

### Changes Required:

#### 1. `AuthButton` Wrapper Migration

**File**: `lib/features/auth/presentation/widgets/auth_button.dart`

**Intent**: Replace the raw `FilledButton`, hardcoded `48px` height, `TextStyle(fontSize: 16)`, and raw `Colors.white` `CircularProgressIndicator` with `AppButton` from `package:bulk_tempo/core/design_system.dart`.

**Contract**:
- Keep `AuthButton({super.key, required this.text, required this.onPressed, this.isLoading = false, this.isEnabled = true, this.variant = AppButtonVariant.primary, this.icon})`.
- Delegate `build` to `AppButton(label: text, onPressed: onPressed, isBusy: isLoading, isEnabled: isEnabled, variant: variant, icon: icon, expand: true)`.

#### 2. `AuthTextField` Wrapper & Adaptive Password Toggle Migration

**File**: `lib/features/auth/presentation/widgets/auth_text_field.dart`

**Intent**: Replace the raw Material `TextField` and `OutlineInputBorder` with `AppTextField`, and support a platform-adaptive password visibility toggle button using `AppIcons.resolve(context, AppIcon.visibility / AppIcon.visibilityOff)` so `LoginScreen` and `RegisterScreen` do not construct raw Material `IconButton`s directly.

**Contract**:
- Keep existing constructor parameters (`super.key`, `required this.label`, `this.hint`, `this.errorText`, `this.obscureText = false`, `this.keyboardType = TextInputType.text`, `this.textInputAction`, `this.onChanged`, `this.onSubmitted`, `this.controller`, `this.suffixIcon`, `this.enabled = true`, `this.fieldKey`) and add optional `VoidCallback? onToggleObscureText` and `String? toggleObscureTooltip`.
- When `onToggleObscureText != null` (and `suffixIcon == null`), build a platform-adaptive trailing toggle control:
  - On `AdaptivePlatformMode.material`: `IconButton(tooltip: toggleObscureTooltip, onPressed: enabled ? onToggleObscureText : null, icon: Icon(AppIcons.resolve(context, obscureText ? AppIcon.visibility : AppIcon.visibilityOff)))`.
  - On Cupertino modes (`cupertinoClassic` / `cupertinoLiquidGlass`): a `Tooltip(message: toggleObscureTooltip ?? '', child: CupertinoButton(padding: EdgeInsets.zero, minimumSize: const Size(AppSpacing.iosMinTapTarget, AppSpacing.iosMinTapTarget), onPressed: enabled ? onToggleObscureText : null, child: Icon(AppIcons.resolve(context, obscureText ? AppIcon.visibility : AppIcon.visibilityOff), size: AppIcons.compactSize, color: Theme.of(context).colorScheme.onSurfaceVariant)))`.
- Delegate to `AppTextField` with `autocorrect: !obscureText && keyboardType != TextInputType.emailAddress` and `enableSuggestions: !obscureText`.

#### 3. `SplashScreen` Migration

**File**: `lib/features/auth/presentation/views/splash_screen.dart`

**Intent**: Migrate `SplashScreen` from raw `Icons.fitness_center`, hardcoded `TextStyle(fontSize: 28)`, raw `SizedBox` values, and Material-only `CircularProgressIndicator` to design-system tokens and capability-aware progress feedback.

**Contract**:
- Import `package:bulk_tempo/core/design_system.dart` and `package:flutter/cupertino.dart`.
- Resolve the hero icon via `Icon(AppIcons.resolve(context, AppIcon.workout, selected: true), size: 72, color: Theme.of(context).colorScheme.primary)`.
- Style `context.l10n.appTitle` with `Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)`.
- Replace raw `SizedBox(height: 16)` and `SizedBox(height: 24)` with `AppSpacing.space4` and `AppSpacing.space6`.
- Render `CupertinoActivityIndicator` when `PresentationCapabilities.resolve(context).platformMode != AdaptivePlatformMode.material`, and `CircularProgressIndicator` on `AdaptivePlatformMode.material`.

#### 4. `LoginScreen` Migration

**File**: `lib/features/auth/presentation/views/login_screen.dart`

**Intent**: Migrate `LoginScreen` to use `AppSpacing.formMaxWidth` (`480.0`), `AppSpacing.pageInsetWide` (`24.0`), `AppIcons.resolve(context, AppIcon.workout, selected: true)`, `AppFeedback.showSnackBar`, an inline `AppFeedbackBanner` for error states, `AppButton(variant: AppButtonVariant.text)` for the register navigation link, and disable inputs/navigation while `FormStatus.submitting` is active.

**Contract**:
- Replace `ScaffoldMessenger.of(context).showSnackBar(...)` in both `ref.listen` callbacks with `AppFeedback.showSnackBar(context, message: ..., tone: AppFeedbackTone.error)`.
- Compute `final isSubmitting = formState.status == FormStatus.submitting;` and `final activeErrorMessage = (formState.status == FormStatus.failure ? formState.errorMessage : null) ?? authState.errorMessage;`.
- Constrain the form column with `ConstrainedBox(constraints: const BoxConstraints(maxWidth: AppSpacing.formMaxWidth))` inside `SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageInsetWide, vertical: AppSpacing.space6))`.
- Render `Icon(AppIcons.resolve(context, AppIcon.workout, selected: true), size: 56, color: Theme.of(context).colorScheme.primary)`.
- Pass `enabled: !isSubmitting` to both `AuthTextField` widgets, and pass `onToggleObscureText` + `toggleObscureTooltip` to the password `AuthTextField`.
- When `activeErrorMessage != null`, render `AppFeedbackBanner(bannerKey: const Key('login_error_banner'), message: activeErrorMessage, tone: AppFeedbackTone.error)` with `AppSpacing.space4` spacing above `AuthButton`.
- Replace the raw `TextButton` (`Key('login_to_register_button')`) with `AppButton(key: const Key('login_to_register_button'), label: context.l10n.dontHaveAccountButton, variant: AppButtonVariant.text, isEnabled: !isSubmitting, onPressed: _goToRegister)`.

#### 5. `RegisterScreen` Migration

**File**: `lib/features/auth/presentation/views/register_screen.dart`

**Intent**: Migrate `RegisterScreen` to match `LoginScreen`'s design-system tokens, inline `AppFeedbackBanner` + `AppFeedback.showSnackBar`, busy state locking, and provide a platform-adaptive top bar with an accessible back button.

**Contract**:
- Replace the raw `AppBar` with a platform-adaptive top bar (`AppBar` on Material, `CupertinoNavigationBar` with transparent border/surface background on Cupertino) containing a back button (`Key('register_back_button')`) with `tooltip: MaterialLocalizations.of(context).backButtonTooltip`, disabled while `isSubmitting` is true, calling `_goToLogin`. Do not add a title to the top bar so `find.text('Create Account')` / `find.text('Utwórz konto')` continues to match exactly 2 widgets (heading + submit button).
- Route failure notifications through `AppFeedback.showSnackBar(context, message: next.errorMessage!, tone: AppFeedbackTone.error)` and render `AppFeedbackBanner(bannerKey: const Key('register_error_banner'), message: formState.errorMessage!, tone: AppFeedbackTone.error)` when `formState.status == FormStatus.failure && formState.errorMessage != null`.
- Constrain the form to `AppSpacing.formMaxWidth` with `AppSpacing.pageInsetWide` padding, `AppIcons.resolve(context, AppIcon.workout, selected: true)` (`color: colorScheme.primary`), `enabled: !isSubmitting` on both `AuthTextField`s, `onToggleObscureText` + `toggleObscureTooltip` on the password field, and `AppButton(key: const Key('register_to_login_button'), label: context.l10n.alreadyHaveAccountButton, variant: AppButtonVariant.text, isEnabled: !isSubmitting, onPressed: _goToLogin)`.

#### 6. Unit & Widget Tests for Auth Widgets and Unauthenticated Views

**Files**:
- `test/features/auth/presentation/widgets/auth_button_test.dart` (new)
- `test/features/auth/presentation/widgets/auth_text_field_test.dart` (new)
- `test/features/auth/presentation/views/splash_screen_test.dart`
- `test/features/auth/presentation/views/login_screen_test.dart`
- `test/features/auth/presentation/views/register_screen_test.dart`

**Intent**: Add dedicated widget tests for `AuthButton` and `AuthTextField` across Material and `cupertinoClassic` modes, and update/expand `splash_screen_test.dart`, `login_screen_test.dart`, and `register_screen_test.dart` to verify inline error banners, busy input locking, and Cupertino fallback rendering.

**Contract**:
- `auth_button_test.dart`: Verifies `AppButton` delegation, full-width expansion, busy spinner (`CircularProgressIndicator` on Material, `CupertinoActivityIndicator` on Cupertino), and disabled state.
- `auth_text_field_test.dart`: Verifies `AppTextField` delegation, `fieldKey` forwarding, password visibility toggle tooltip and tap behavior on both Material (`IconButton`) and `cupertinoClassic` (`CupertinoButton`), and disabled state.
- `splash_screen_test.dart`: Preserves existing Material test (`Icons.fitness_center`, `CircularProgressIndicator`) and adds a `cupertinoClassic` test verifying `CupertinoIcons.sportscourt_fill` and `CupertinoActivityIndicator`.
- `login_screen_test.dart` & `register_screen_test.dart`: Verify `Key('login_error_banner')` / `Key('register_error_banner')` alongside `SnackBar` on submission failure, verify inputs and mode-switch buttons are disabled during `FormStatus.submitting`, and verify `cupertinoClassic` rendering (`CupertinoTextField`, `CupertinoButton`, `CupertinoActivityIndicator`).

### Success Criteria:

#### Automated Verification:

- AuthButton and AuthTextField unit/widget tests pass across Material and Cupertino modes: `flutter test test/features/auth/presentation/widgets/`
- Splash, Login, and Register widget tests pass across Material and Cupertino modes: `flutter test test/features/auth/presentation/views/splash_screen_test.dart test/features/auth/presentation/views/login_screen_test.dart test/features/auth/presentation/views/register_screen_test.dart`
- Router and localization tests pass with migrated auth screens: `flutter test test/app/router/app_router_test.dart test/features/localization/polish_rendering_test.dart test/widget_test.dart`
- Formatting and static analysis pass with zero issues: `dart format --output=none --set-exit-if-changed lib test && flutter analyze`

#### Manual Verification:

- Verify SplashScreen, LoginScreen, and RegisterScreen in English and Polish across light and dark themes, confirming password visibility toggle, inline error banner + snackbar feedback, and disabled inputs while submitting

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Phase 2: Migrate HomeShellScreen, Logout Dialog & Profile Tab

### Overview

Migrate `HomeShellScreen` (`lib/features/auth/presentation/views/home_shell_screen.dart`) to use `AppNavigationShell`, `AppDialog.showConfirm`, `AppFeedback.showSnackBar`, `AppCard`, `AppButton`, `AppSpacing`, `AppIcons`, and a platform-adaptive language selector on the Profile tab, and update `test/features/auth/presentation/views/home_shell_screen_test.dart`.

### Changes Required:

#### 1. `HomeShellScreen` Navigation Shell, Logout Dialog & Profile Tab Migration

**File**: `lib/features/auth/presentation/views/home_shell_screen.dart`

**Intent**: Replace the raw `Scaffold` + `AppBar` + `NavigationBar`, raw `AlertDialog`, raw error `SnackBar`, and raw Profile tab `Card`s and buttons with design-system components from `package:bulk_tempo/core/design_system.dart`.

**Contract**:
- **Shell & Top Bar**: Replace `Scaffold(appBar: ..., body: ..., bottomNavigationBar: NavigationBar(...))` with `AppNavigationShell`:
  - `title: context.l10n.appTitle`
  - `selectedIndex: _selectedIndex`
  - `onDestinationSelected`: updates `_selectedIndex` and calls `ensureInitialized()` when `index == 3`
  - `toolbarActions`: `[AppToolbarAction(key: const Key('home_app_bar_logout_button'), tooltip: context.l10n.logoutButton, icon: AppIcon.logout, onPressed: () => _showLogoutDialog(context))]`
  - `destinations`: 4 `AppNavigationDestinationItem`s with `Key('nav_home_tab')` (`AppIcon.home`), `Key('nav_weights_tab')` (`AppIcon.weight`), `Key('nav_workouts_tab')` (`AppIcon.workout`), and `Key('nav_profile_tab')` (`AppIcon.profile`).
- **Logout Confirmation Dialog (`_showLogoutDialog`)**: Replace `showDialog<void>` + `AlertDialog` with `AppDialog.showConfirm<bool>`:
  - `dialogKey: const Key('logout_confirm_dialog')`
  - `title: context.l10n.logoutDialogTitle`
  - `message: context.l10n.logoutDialogContent`
  - `cancelLabel: context.l10n.cancel`
  - `confirmLabel: context.l10n.logoutDialogConfirm`
  - `confirmButtonKey: const Key('confirm_logout_button')`
  - `isDestructive: true`
  - `onConfirm: () => ref.read(authViewModelProvider.notifier).signOut()`
- **Error Feedback**: In `ref.listen<AuthState>(authViewModelProvider, ...)`, replace `ScaffoldMessenger.of(context).showSnackBar(...)` with `AppFeedback.showSnackBar(context, message: next.errorMessage!, tone: AppFeedbackTone.error)` before calling `clearError()`.
- **Profile Tab (`_buildProfileTab` & `_buildLanguageCard`)**:
  - Constrain content inside `Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: AppSpacing.dashboardMaxWidth), child: ...))` with `EdgeInsets.all(AppSpacing.pageInsetWide)`.
  - Profile avatar icon: `Icon(AppIcons.resolve(context, AppIcon.profile), size: 72, color: Theme.of(context).colorScheme.primary)`, spacing via `AppSpacing.space4`, `AppSpacing.space2`, `AppSpacing.sectionGap`, `AppSpacing.space8`.
  - **Hevy Integration Card**: Replace raw `Card(key: const Key('profile_hevy_card'), ...)` with `AppCard(cardKey: const Key('profile_hevy_card'), variant: AppCardVariant.outlined, title: context.l10n.hevyIntegrationTitle, leadingIcon: AppIcon.workout, child: ...)`. Replace `FilledButton.tonal` (`Key('profile_connect_or_update_hevy_key_button')`) with `AppButton(key: const Key('profile_connect_or_update_hevy_key_button'), label: ..., variant: AppButtonVariant.tonal, onPressed: ...)` and `OutlinedButton` (`Key('profile_disconnect_hevy_key_button')`) with `AppButton(key: const Key('profile_disconnect_hevy_key_button'), label: context.l10n.disconnectButton, variant: AppButtonVariant.outlined, onPressed: ...)`. Wrap the two buttons in a responsive layout (`Column` when narrow or `textScaler >= AppSpacing.enlargedTextScaleThreshold`, `Row` otherwise) so Polish labels never overflow at `2.0x` text scale.
  - **Language Card**: Replace raw `Card(key: const Key('profile_language_card'), ...)` with `AppCard(cardKey: const Key('profile_language_card'), variant: AppCardVariant.outlined, title: context.l10n.languageLabel, leadingIcon: AppIcon.language, child: ...)`. On `AdaptivePlatformMode.material`, render `SegmentedButton<String>(key: const Key('profile_language_selector'), ...)`; on Cupertino modes, render `CupertinoSlidingSegmentedControl<String>(key: const Key('profile_language_selector'), groupValue: LocaleConstants.toSelectionCode(currentLocale), children: {...}, onValueChanged: ...)`.
  - **Profile Logout Button**: Replace `OutlinedButton.icon(key: const Key('profile_logout_button'), ...)` with `AppButton(key: const Key('profile_logout_button'), label: context.l10n.logoutButton, icon: AppIcon.logout, variant: AppButtonVariant.outlined, onPressed: () => _showLogoutDialog(context))`.

#### 2. `HomeShellScreen` Widget Tests

**File**: `test/features/auth/presentation/views/home_shell_screen_test.dart`

**Intent**: Verify all existing `HomeShellScreen` navigation, logout dialog, error snackbar, Hevy card, and language selector flows pass, and add tests covering `cupertinoClassic` mode (`CupertinoNavigationBar`, `CupertinoTabBar`, `CupertinoAlertDialog`, `CupertinoSlidingSegmentedControl`) and wide (`>=840px`) `NavigationRail` layout.

**Contract**:
- Keep all existing Material test assertions passing (`AlertDialog`, `Key('confirm_logout_button')`, `Key('profile_hevy_card')`, `Key('profile_language_card')`, `SegmentedButton<String>`).
- Add widget tests for:
  - `AdaptivePlatformMode.cupertinoClassic` (`TargetPlatform.iOS`, `iosMajorVersion: 18`, `supportsNativeIosViews: false`): verifies `CupertinoNavigationBar`, `CupertinoTabBar`, `CupertinoAlertDialog` on logout button tap, and `CupertinoSlidingSegmentedControl<String>` language switching on the Profile tab.
  - Wide viewport (`1024×768`) on Material: verifies `AppNavigationShell` switches from `NavigationBar` to `NavigationRail` while preserving all 4 tab keys.

### Success Criteria:

#### Automated Verification:

- HomeShellScreen widget tests pass across Material and Cupertino modes: `flutter test test/features/auth/presentation/views/home_shell_screen_test.dart`
- Full auth test suite passes: `flutter test test/features/auth/`
- Formatting and static analysis pass with zero issues: `dart format --output=none --set-exit-if-changed lib test && flutter analyze`

#### Manual Verification:

- Verify HomeShellScreen navigation bar/rail switching (<840px vs >=840px), destructive logout confirmation dialog, and Profile tab cards and language selector in Material and Cupertino modes

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before proceeding to the next phase. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Phase 3: Widgetbook Catalog, Accessibility Verification & Governance

### Overview

Add the `Auth` category to Widgetbook (`widgetbook/use_cases/auth_use_cases.dart` and `widgetbook/widgetbook_app.dart`) with deterministic `ProviderScope`-backed 7-state matrices for `LoginScreen` and `RegisterScreen` plus `SplashScreen` and `HomeShellScreen`/Profile use cases, expand `test/widgetbook/widgetbook_smoke_test.dart` and accessibility/text-scale tests, and update `AGENTS.md` to forbid raw color literals in all `lib/features/auth/presentation/` files.

### Changes Required:

#### 1. Auth Widgetbook Use Cases

**File**: `widgetbook/use_cases/auth_use_cases.dart` (new)

**Intent**: Provide deterministic, Firebase-free `ProviderScope`-backed Widgetbook stories for all auth views and states following `widgetbook/use_cases/gain_target_use_cases.dart` and `widgetbook/use_cases/dashboard_use_cases.dart`.

**Contract**:
- Define deterministic catalog ViewModels (`_CatalogAuthViewModel`, `_CatalogLoginViewModel`, `_CatalogRegisterViewModel`, plus stubbed dashboard/weight/workout/gain-target ViewModels for `HomeShellScreen`) that return seeded states and no-op on mutations so Widgetbook smoke tests never touch Firebase.
- Export `final authCategory = WidgetbookCategory(name: 'Auth', children: [...])` with components:
  1. `LoginScreen` -> `WidgetbookUseCase(name: 'Login — State Matrix', ...)` rendering a responsive `Wrap` covering:
     - `Default (empty)`
     - `Populated (ready)`
     - `Validation error` (email + password field errors)
     - `Submission failure` (inline `AppFeedbackBanner` with localized error message)
     - `Submitting / busy` (`FormStatus.submitting` with busy `AuthButton` and disabled inputs)
     - `Auth stream error` (`AuthState(errorMessage: ...)`)
     - `Success feedback` (`AppFeedbackBanner(tone: AppFeedbackTone.success)`)
  2. `RegisterScreen` -> `WidgetbookUseCase(name: 'Register — State Matrix', ...)` rendering the corresponding 7 states side-by-side.
  3. `SplashScreen` -> `WidgetbookUseCase(name: 'Initial Auth Loading', ...)` rendering `SplashScreen`.
  4. `HomeShellScreen` -> `WidgetbookUseCase(name: 'Profile & Navigation Shell', ...)` rendering `HomeShellScreen` with seeded user email, gain target, and Hevy connection state.

#### 2. Register `authCategory` in Widgetbook App

**File**: `widgetbook/widgetbook_app.dart`

**Intent**: Register `authCategory` in `widgetbookDirectories` so it appears in the Widgetbook sidebar and is automatically exercised by `test/widgetbook/widgetbook_smoke_test.dart`.

**Contract**:
- Import `use_cases/auth_use_cases.dart` and add `authCategory` to `widgetbookDirectories`.

#### 3. Widgetbook Smoke Test & Accessibility / 2.0x Text-Scale Tests

**Files**:
- `test/widgetbook/widgetbook_smoke_test.dart`
- `test/features/auth/presentation/views/login_screen_test.dart`
- `test/features/auth/presentation/views/register_screen_test.dart`
- `test/features/auth/presentation/views/home_shell_screen_test.dart`

**Intent**: Ensure all new Auth Widgetbook use cases are smoke-tested across `(Locale('en'), AppTheme.light())`, `(Locale('pl'), AppTheme.dark())`, `TextScaler.linear(2.0)`, and both Material and `cupertinoClassic` modes, and verify `LoginScreen`, `RegisterScreen`, and `HomeShellScreen` Profile tab render without overflow at `2.0x` text scale in Polish (`Locale('pl')`) on a `390×844` viewport.

**Contract**:
- In `test/widgetbook/widgetbook_smoke_test.dart`: add a test verifying `'Login — State Matrix'` and `'Register — State Matrix'` under both `TargetPlatform.android` (`material`) and `TargetPlatform.iOS` (`cupertinoClassic`, `iosMajorVersion: 18`, `supportsNativeIosViews: false`) with zero layout exceptions.
- In `login_screen_test.dart`, `register_screen_test.dart`, and `home_shell_screen_test.dart`: add accessibility tests verifying `Locale('pl')` + `TextScaler.linear(2.0)` on a `390×844` screen renders without overflow (`tester.takeException() == null`) and that interactive buttons meet minimum tap target sizes (`48×48` on Android, `44×44` on iOS).

#### 4. Repository Governance Rule Update

**File**: `AGENTS.md`

**Intent**: Extend the design-system rule in `AGENTS.md:19` so future agents keep `lib/features/auth/presentation/` on app-owned components and semantic theme roles without reintroducing raw color literals or direct palette references.

**Contract**:
- Update the final sentence in `AGENTS.md` under `## Architecture & Technical Documentation` to list `lib/features/auth/presentation/` alongside `lib/features/gain_target/presentation/views/gain_target_view.dart`.

### Success Criteria:

#### Automated Verification:

- Widgetbook smoke and auth state-matrix tests pass: `flutter test test/widgetbook/widgetbook_smoke_test.dart`
- No raw Color, Colors.*, AppPalette.*, or adaptive_platform_ui imports exist in lib/features/auth/presentation/: `! grep -rnE "Colors\.|Color\(0x|AppPalette|adaptive_platform_ui" lib/features/auth/presentation/`
- Full repository formatting, static analysis, and test suite pass: `dart format --output=none --set-exit-if-changed lib test widgetbook && flutter analyze && flutter test`

#### Manual Verification:

- Inspect the Auth category in Widgetbook (Login 7-state matrix, Register 7-state matrix, SplashScreen, and HomeShellScreen/Profile) across light/dark themes, English/Polish locales, and 2.0x text scale

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that the manual testing was successful before completing the change. Phase blocks use plain bullets — the corresponding `- [ ]` checkboxes for these items live in the `## Progress` section at the bottom of the plan.

---

## Testing Strategy

### Unit Tests:

- `test/features/auth/presentation/view_models/auth_view_model_test.dart`, `login_view_model_test.dart`, and `register_view_model_test.dart` remain green with zero regressions.
- New widget-level unit tests in `test/features/auth/presentation/widgets/auth_button_test.dart` and `auth_text_field_test.dart` verify `AppButton` and `AppTextField` delegation, busy states, disabled states, and adaptive password visibility toggle behavior.

### Integration Tests:

- `test/features/auth/presentation/views/login_screen_test.dart`, `register_screen_test.dart`, `splash_screen_test.dart`, and `home_shell_screen_test.dart` verify end-to-end form validation, sign-in/sign-up submission, inline `AppFeedbackBanner` + `SnackBar` error presentation, busy input locking, 4-tab navigation (`NavigationBar` `<840px`, `NavigationRail` `>=840px`, `CupertinoTabBar` on iOS), destructive logout confirmation via `AppDialog.showConfirm`, Profile tab Hevy/Language cards, and `Locale('pl')` + `2.0x` text scaling.
- `test/app/router/app_router_test.dart`, `test/features/localization/polish_rendering_test.dart`, `test/widget_test.dart`, and `test/widgetbook/widgetbook_smoke_test.dart` verify cross-app routing, localization, and Widgetbook catalog rendering.

### Manual Testing Steps:

1. Run `flutter run -d chrome -t widgetbook/main_widgetbook.dart` and inspect the `Auth` category (`LoginScreen`, `RegisterScreen`, `SplashScreen`, `HomeShellScreen`) across Light/Dark/High-Contrast themes, `en`/`pl` locales, `1.0x`–`2.0x` text scales, and Material 3 vs. Cupertino Classic platform modes.
2. Run the main app (`flutter run -d chrome` or simulator), test invalid login/registration inputs, verify the password visibility toggle and busy state during submission, sign in, test the Profile tab's Hevy card and language switcher, and trigger the destructive logout confirmation dialog.

## Performance Considerations

- All auth forms, Profile cards, and banners use opaque theme surfaces (`surface`, `surfaceContainerLow`) without backdrop blur shaders.
- `AppNavigationShell` enables native toolbar/tab glass (`AdaptiveScaffold(enableBlur: true)`) only when `PresentationCapabilities` resolves `AdaptivePlatformMode.cupertinoLiquidGlass` (iOS 26+ with native views enabled), falling back to standard Flutter widgets on Android, web, older iOS, and headless widget tests.

## Migration Notes

- All existing widget `Key`s (`login_email_field`, `login_password_field`, `login_submit_button`, `login_to_register_button`, `register_email_field`, `register_password_field`, `register_submit_button`, `register_to_login_button`, `home_app_bar_logout_button`, `confirm_logout_button`, `nav_home_tab`, `nav_weights_tab`, `nav_workouts_tab`, `nav_profile_tab`, `profile_heading`, `profile_hevy_card`, `profile_hevy_masked_key`, `profile_connect_or_update_hevy_key_button`, `profile_disconnect_hevy_key_button`, `profile_language_card`, `profile_language_selector`, `profile_logout_button`) are preserved verbatim.

## References

- Design system contract: `context/documentation/07_design_system.md`
- Core design system implementation plan: `context/changes/design-system/plan.md`
- Dashboard design system migration: `context/archive/2026-10-20-dashboard-design-system/plan.md`
- Gain target design system migration: `context/changes/gain-target-design-system/plan.md`
- Lessons learned (Widgetbook directory boundary): `context/foundation/lessons.md`

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands. Do not rename step titles. See `references/progress-format.md`.

### Phase 1: Migrate Auth Widgets & Unauthenticated Screens

#### Automated

- [x] 1.1 AuthButton and AuthTextField unit/widget tests pass across Material and Cupertino modes: `flutter test test/features/auth/presentation/widgets/`
- [x] 1.2 Splash, Login, and Register widget tests pass across Material and Cupertino modes: `flutter test test/features/auth/presentation/views/splash_screen_test.dart test/features/auth/presentation/views/login_screen_test.dart test/features/auth/presentation/views/register_screen_test.dart`
- [x] 1.3 Router and localization tests pass with migrated auth screens: `flutter test test/app/router/app_router_test.dart test/features/localization/polish_rendering_test.dart test/widget_test.dart`
- [x] 1.4 Formatting and static analysis pass with zero issues: `dart format --output=none --set-exit-if-changed lib test && flutter analyze`

#### Manual

- [x] 1.5 Verify SplashScreen, LoginScreen, and RegisterScreen in English and Polish across light and dark themes, confirming password visibility toggle, inline error banner + snackbar feedback, and disabled inputs while submitting

### Phase 2: Migrate HomeShellScreen, Logout Dialog & Profile Tab

#### Automated

- [ ] 2.1 HomeShellScreen widget tests pass across Material and Cupertino modes: `flutter test test/features/auth/presentation/views/home_shell_screen_test.dart`
- [ ] 2.2 Full auth test suite passes: `flutter test test/features/auth/`
- [ ] 2.3 Formatting and static analysis pass with zero issues: `dart format --output=none --set-exit-if-changed lib test && flutter analyze`

#### Manual

- [ ] 2.4 Verify HomeShellScreen navigation bar/rail switching (<840px vs >=840px), destructive logout confirmation dialog, and Profile tab cards and language selector in Material and Cupertino modes

### Phase 3: Widgetbook Catalog, Accessibility Verification & Governance

#### Automated

- [ ] 3.1 Widgetbook smoke and auth state-matrix tests pass: `flutter test test/widgetbook/widgetbook_smoke_test.dart`
- [ ] 3.2 No raw Color, Colors.*, AppPalette.*, or adaptive_platform_ui imports exist in lib/features/auth/presentation/: `! grep -rnE "Colors\.|Color\(0x|AppPalette|adaptive_platform_ui" lib/features/auth/presentation/`
- [ ] 3.3 Full repository formatting, static analysis, and test suite pass: `dart format --output=none --set-exit-if-changed lib test widgetbook && flutter analyze && flutter test`

#### Manual

- [ ] 3.4 Inspect the Auth category in Widgetbook (Login 7-state matrix, Register 7-state matrix, SplashScreen, and HomeShellScreen/Profile) across light/dark themes, English/Polish locales, and 2.0x text scale
