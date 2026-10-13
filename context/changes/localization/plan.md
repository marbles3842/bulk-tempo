# Localization Support Implementation Plan

## Overview

Refactor Bulk Tempo's user interface to support multiple languages using Flutter's official internationalization tooling (`gen-l10n` and ARB files). Currently, UI elements and user-facing validation messages across all features (Auth, Weight Tracking, Workout Progress, and Gain Target) use hardcoded English strings. This plan establishes the localization architecture, extracts all strings into English (`app_en.arb`) and Polish (`app_pl.arb`) resource bundles, introduces persistent locale state management via Riverpod, adds a Language Selector in the Profile tab, updates core date/validation formatting, and ensures complete test verification.

## Current State Analysis

- **Internationalization Setup**: `pubspec.yaml` contains `flutter_localizations: sdk: flutter`, but lacks `intl` as a direct dependency and `generate: true` under `flutter:`. No `l10n.yaml` exists.
- **Root Configuration**: `lib/app/app.dart` hardcodes `locale: const Locale('en', 'GB')` and `supportedLocales: const [Locale('en', 'GB'), Locale('en', 'US')]` on `MaterialApp.router` with only default framework delegates, omitting `AppLocalizations.delegate`.
- **UI Strings**: All four feature domains hardcode English strings directly inside presentation widgets:
  - Auth: `lib/features/auth/presentation/views/login_screen.dart`, `register_screen.dart`, `home_shell_screen.dart`, `splash_screen.dart`.
  - Weight: `lib/features/weight/presentation/views/weight_history_view.dart`, `weight_entry_bottom_sheet.dart`, `weekly_weight_card.dart`, `weekly_weight_chart.dart`.
  - Workout: `lib/features/workout/presentation/views/workout_progress_view.dart`, `hevy_key_bottom_sheet.dart`, `workout_detail_bottom_sheet.dart`, `weekly_workout_card.dart`.
  - Gain Target: `lib/features/gain_target/presentation/views/gain_target_view.dart`.
- **Validation Messages & Core Utilities**:
  - `WeightValidators` (`lib/core/utils/weight_validators.dart`) and `HevyKeyValidators` (`lib/core/utils/hevy_key_validators.dart`) return hardcoded English error strings.
  - `WeekDateUtils` (`lib/core/utils/week_date_utils.dart`) maintains static arrays of English month (`_months`) and weekday (`_weekdays`) names.
- **Testing**: `test/test_helpers/pump_app.dart` configures a hardcoded `en_GB` locale without `AppLocalizations.delegate`.

## Desired End State

- The application supports English (`en`, default/fallback) and Polish (`pl`).
- Official Flutter `gen-l10n` generates `AppLocalizations` from `lib/l10n/app_en.arb` and `lib/l10n/app_pl.arb`.
- `MaterialApp.router` uses a reactive `locale` managed by Riverpod `LocaleNotifier` with persistent storage in `FlutterSecureStorage`.
- Users can switch language manually between English and Polish from a Language Selector in the Profile tab (`HomeShellScreen`), or keep system default.
- Pure Dart validators and domain models remain decoupled from `BuildContext`, returning typed validation failure codes or keys, which presentation views map to localized messages.
- `WeekDateUtils` uses `intl`'s `DateFormat` parameterized by the current locale.
- `test/test_helpers/pump_app.dart` includes `AppLocalizations.delegate`, and dedicated tests verify Polish translations and locale state switching.

### Key Discoveries:

- `pubspec.yaml:12`: `flutter_localizations` is already declared, but `generate: true` is missing at `pubspec.yaml:35`.
- `lib/app/app.dart:19-25`: Hardcoded locale and supported locales list must be wired to dynamic provider and `AppLocalizations.supportedLocales` / `localizationsDelegates`.
- `lib/core/utils/week_date_utils.dart:3-16`: Static English month/weekday lists should be replaced with `intl` `DateFormat.E(locale)` and `DateFormat.MMM(locale)`.
- `test/test_helpers/pump_app.dart:17-21`: Pump helper replicates `app.dart` configuration and must include `AppLocalizations.delegate` to prevent missing localizations exceptions during widget tests.

## What We're NOT Doing

- Not adding third-party localization packages (`easy_localization`, `slang`, etc.); staying strictly with Flutter official `gen-l10n`.
- Not supporting runtime-downloaded dynamic language packs (OTA translations).
- Not translating dynamic backend data (e.g. exercise names or workout titles returned from the external Hevy API).
- Not altering existing unit tests for data sources or repositories.

## Implementation Approach

1. **Tooling & Code Generation**: Configure Flutter's built-in `gen-l10n` generator (`l10n.yaml`, `pubspec.yaml`, `app_en.arb`, `app_pl.arb`), run code generation, and wire generated delegates to `MaterialApp.router`.
2. **Locale State & Profile Switching**: Create `localeProvider` and `LocaleNotifier` using Riverpod with `FlutterSecureStorage` persistence. Add a language selector tile to the Profile tab.
3. **Core Utilities & Validation Refactor**: Modernize `WeekDateUtils` to format dates with `intl` based on active locale. Refactor validators to return clean error identifiers or translation keys for Views to resolve.
4. **Presentation View Localization**: Systematically replace hardcoded text across Auth, Weight, Workout, and Gain Target views with `context.l10n.*` or `AppLocalizations.of(context)!.*`.
5. **Testing & QA**: Update `pump_app.dart` and add tests for locale switching and Polish string coverage.

---

## Phase 1: Localization Infrastructure & Code Generation Setup

### Overview

Establish Flutter's official `gen-l10n` toolchain, configure `l10n.yaml`, add the `intl` dependency, declare base translation resources (`app_en.arb` and `app_pl.arb`), generate `AppLocalizations`, and integrate the delegates into `MaterialApp.router`.

### Changes Required:

#### 1. Manifest & L10n Configuration

**File**: `pubspec.yaml`
**Intent**: Add `intl` dependency and enable Flutter localization code generation.
**Contract**: Add `intl: ^0.20.2` under `dependencies:`. Add `generate: true` under `flutter:`.

**File**: `l10n.yaml`
**Intent**: Configure Flutter localization generator paths and settings.
**Contract**: Root-level configuration specifying `arb-dir: lib/l10n`, `template-arb-file: app_en.arb`, and `output-localization-file: app_localizations.dart`.

#### 2. Resource ARB Files

**File**: `lib/l10n/app_en.arb`
**Intent**: Create English template ARB resource file containing initial app strings, navigation labels, and common buttons.
**Contract**: JSON format with `@metadata` descriptions and message keys.

**File**: `lib/l10n/app_pl.arb`
**Intent**: Create Polish ARB resource file matching all keys defined in `app_en.arb`.
**Contract**: JSON format translating keys into Polish.

#### 3. Root Application Wiring

**File**: `lib/app/app.dart`
**Intent**: Wire generated `AppLocalizations` delegates and supported locales into `MaterialApp.router`.
**Contract**: Import `package:flutter_gen/gen_l10n/app_localizations.dart`. Register `AppLocalizations.delegate` in `localizationsDelegates` and configure `supportedLocales: AppLocalizations.supportedLocales`.

### Success Criteria:

#### Automated Verification:

- Dependencies resolved successfully: `flutter pub get`
- Localization code generation completes without errors: `flutter gen-l10n`
- Static analysis passes: `flutter analyze`
- Existing test suite passes: `flutter test`

#### Manual Verification:

- App compiles and runs displaying the default English strings.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to the next phase.

---

## Phase 2: Locale State Management & Profile Language Selector

### Overview

Implement a reactive Riverpod state notifier to manage the active locale with device system-default detection and `FlutterSecureStorage` persistence. Add a Language Selector UI widget in the Profile tab.

### Changes Required:

#### 1. Locale State Notifier & Provider

**File**: `lib/core/localization/locale_notifier.dart`
**Intent**: Manage app `Locale?` (null representing system default, or explicit `Locale('en')` / `Locale('pl')`) with persistence to secure storage.
**Contract**: `Notifier<Locale?>` with `setLocale(Locale? locale)` saving `'app_locale'` key in `FlutterSecureStorage`.

**File**: `lib/core/localization/locale_provider.dart`
**Intent**: Expose `localeNotifierProvider` and a helper extension `BuildContext.l10n` for convenient string access.
**Contract**: `final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);` and `extension AppLocalizationsX on BuildContext { AppLocalizations get l10n => AppLocalizations.of(this)!; }`.

#### 2. App Root Binding

**File**: `lib/app/app.dart`
**Intent**: Watch `localeProvider` to set `MaterialApp.router`'s `locale` property dynamically.
**Contract**: `final currentLocale = ref.watch(localeProvider);` passed to `locale: currentLocale`.

#### 3. Profile Tab Language Selector

**File**: `lib/features/auth/presentation/views/home_shell_screen.dart`
**Intent**: Add a language selection section in the Profile tab allowing the user to select English, Polish, or System Default.
**Contract**: A ListTile or segmented selector in `_buildProfileTab(context)` dispatching `setLocale()` on `localeProvider.notifier`.

### Success Criteria:

#### Automated Verification:

- Unit test for `LocaleNotifier` passes: `flutter test test/core/localization/locale_notifier_test.dart`
- Static analysis passes: `flutter analyze`

#### Manual Verification:

- In the Profile tab, changing the language immediately switches the application locale between English and Polish.
- Restarting the app persists the chosen language setting.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to the next phase.

---

## Phase 3: Core Utilities & Validation Error Localization

### Overview

Refactor date utilities and input validators so that pure-Dart logic does not depend on hardcoded English text. `WeekDateUtils` will format dates according to the active locale using `intl`, while validators will produce typed error keys that views resolve via `AppLocalizations`.

### Changes Required:

#### 1. Localized WeekDateUtils

**File**: `lib/core/utils/week_date_utils.dart`
**Intent**: Replace static English month and weekday lists with locale-aware `intl.DateFormat`.
**Contract**: Update `formatWeekRange`, `formatShortWeekLabel`, and `formatDayWithWeekday` to accept an optional `String? locale` parameter (or use default Intl locale) formatting with `DateFormat.MMM(locale)` and `DateFormat.E(locale)`.

#### 2. Localized Input Validation Contracts

**File**: `lib/core/utils/weight_validators.dart`
**Intent**: Refactor weight validation methods to return typed error enums or string keys (`WeightValidationError`) rather than hardcoded English strings.
**Contract**: `enum WeightValidationError { empty, invalidFormat, outOfBounds, futureDate, lookbackExceeded }`.

**File**: `lib/core/utils/hevy_key_validators.dart`
**Intent**: Refactor Hevy key validation to return typed error enums (`HevyKeyValidationError`) rather than hardcoded English strings.
**Contract**: `enum HevyKeyValidationError { empty, invalidUuid }`.

#### 3. ARB Entries for Validation & Date Strings

**Files**: `lib/l10n/app_en.arb`, `lib/l10n/app_pl.arb`
**Intent**: Add localization keys for all validator error messages, day labels, and month formats.
**Contract**: ARB definitions for validation messages with parameter interpolation (e.g. min/max bounds).

### Success Criteria:

#### Automated Verification:

- Unit tests for `WeightValidators` and `HevyKeyValidators` pass: `flutter test test/core/utils/`
- Unit tests for `WeekDateUtils` pass with both `en` and `pl` locales: `flutter test test/core/utils/week_date_utils_test.dart`
- Static analysis passes: `flutter analyze`

#### Manual Verification:

- Dates in charts and list headers correctly format in Polish (e.g., abbreviated Polish weekdays/months) when the Polish locale is active.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to the next phase.

---

## Phase 4: Full Presentation View & Widget String Migration

### Overview

Migrate all remaining hardcoded UI strings across all screens, modals, snackbars, and dialogs into `app_en.arb` and `app_pl.arb`, consuming them via `context.l10n`.

### Changes Required:

#### 1. Complete ARB Resource Definition

**Files**: `lib/l10n/app_en.arb`, `lib/l10n/app_pl.arb`
**Intent**: Populate comprehensive English and Polish dictionaries covering all features.
**Contract**: Keys categorized with descriptive prefixes:
- Auth: `loginTitle`, `loginSubtitle`, `emailLabel`, `passwordLabel`, `loginButton`, `registerButton`, `logoutDialogTitle`, `logoutDialogConfirm`, etc.
- Weight: `weightsTab`, `logWeightTitle`, `editWeightTitle`, `saveWeightButton`, `deleteWeightButton`, `overwriteDialogTitle`, `discardDialogTitle`, etc.
- Workout: `workoutsTab`, `connectHevyTitle`, `hevyKeyInputLabel`, `saveAndConnectButton`, `workingSetsLabel`, etc.
- Gain Target: `gainTargetTitle`, `minWeeklyGainLabel`, `maxWeeklyGainLabel`, `saveTargetButton`, etc.

#### 2. Auth Screens Migration

**Files**:
- `lib/features/auth/presentation/views/splash_screen.dart`
- `lib/features/auth/presentation/views/login_screen.dart`
- `lib/features/auth/presentation/views/register_screen.dart`
- `lib/features/auth/presentation/views/home_shell_screen.dart`
- `lib/features/auth/presentation/widgets/auth_text_field.dart`
- `lib/features/auth/presentation/widgets/auth_button.dart`
**Intent**: Replace all hardcoded strings and tooltips with `context.l10n`.

#### 3. Weight Tracking Views Migration

**Files**:
- `lib/features/weight/presentation/views/weight_history_view.dart`
- `lib/features/weight/presentation/widgets/weight_entry_bottom_sheet.dart`
- `lib/features/weight/presentation/widgets/weekly_weight_card.dart`
- `lib/features/weight/presentation/widgets/weekly_weight_chart.dart`
**Intent**: Replace all labels, confirmation dialogs, snackbar alerts, and empty states with `context.l10n`.

#### 4. Workout Views Migration

**Files**:
- `lib/features/workout/presentation/views/workout_progress_view.dart`
- `lib/features/workout/presentation/widgets/hevy_key_bottom_sheet.dart`
- `lib/features/workout/presentation/widgets/workout_detail_bottom_sheet.dart`
- `lib/features/workout/presentation/widgets/weekly_workout_card.dart`
**Intent**: Replace Hevy integration prompts, workout cards, set/rep breakdown labels, and pluralizations with `context.l10n`.

#### 5. Gain Target View Migration

**File**: `lib/features/gain_target/presentation/views/gain_target_view.dart`
**Intent**: Replace target form labels, helper text, current target status, and snackbar messages with `context.l10n`.

### Success Criteria:

#### Automated Verification:

- Code generation creates up-to-date localizations: `flutter gen-l10n`
- Code formatting check passes: `dart format --output=none --set-exit-if-changed lib test`
- Static analysis clean: `flutter analyze`
- Test suite passes: `flutter test`

#### Manual Verification:

- Navigating through Login, Register, Home, Weights, Workouts, and Profile in Polish shows 100% Polish copy with no untranslated English strings or placeholder artifacts.
- Dialogs (Log out, Overwrite weight, Delete weight, Discard changes) display correctly in Polish.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to the next phase.

---

## Phase 5: Test Infrastructure & Verification

### Overview

Update test helpers to support `AppLocalizations`, add dedicated localization tests verifying full key parity between English and Polish ARB files, and ensure all existing widget tests pass cleanly.

### Changes Required:

#### 1. Test Pump Helper

**File**: `test/test_helpers/pump_app.dart`
**Intent**: Register `AppLocalizations.delegate` in `MaterialApp` localizations delegates.
**Contract**: Add `AppLocalizations.delegate` and `supportedLocales: AppLocalizations.supportedLocales` to `PumpAppExtension.pumpApp`.

#### 2. ARB Translation Parity Unit Test

**File**: `test/core/localization/l10n_parity_test.dart`
**Intent**: Ensure every key present in `app_en.arb` exists in `app_pl.arb` and vice-versa, preventing missing translation regressions.
**Contract**: Pure Dart test parsing ARB files and asserting equal key sets.

#### 3. Polish Widget Rendering Smoke Test

**File**: `test/features/localization/polish_rendering_test.dart`
**Intent**: Verify that widgets render Polish strings correctly when the locale is set to `Locale('pl')`.
**Contract**: Widget test pumping screens with `Locale('pl')` and asserting Polish UI text presence.

### Success Criteria:

#### Automated Verification:

- Code formatting check: `dart format --output=none --set-exit-if-changed lib test`
- Static analysis clean: `flutter analyze`
- All unit and widget tests pass: `flutter test`
- Translation parity test passes: `flutter test test/core/localization/l10n_parity_test.dart`

#### Manual Verification:

- App runs smoothly on emulator/device in both English and Polish without visual overflow or broken layout due to string length differences.

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding.

---

## Testing Strategy

### Unit Tests:
- `test/core/localization/locale_notifier_test.dart`: Test `LocaleNotifier` initial state, setting locale, and persistence with mocked `FlutterSecureStorage`.
- `test/core/localization/l10n_parity_test.dart`: Test that `app_en.arb` and `app_pl.arb` have identical keys.
- `test/core/utils/week_date_utils_test.dart`: Test date formatting in English and Polish locales.
- `test/core/utils/weight_validators_test.dart` & `hevy_key_validators_test.dart`: Verify validation returns expected typed error keys.

### Integration / Widget Tests:
- `test/features/localization/polish_rendering_test.dart`: Test UI renders Polish translations under `Locale('pl')`.
- All existing widget tests in `test/features/` updated via `pump_app.dart` to verify zero regression.

### Manual Testing Steps:
1. Open app, switch to Profile tab, select Polish language.
2. Verify all bottom navigation tabs update to Polish.
3. Open "Add Weight" modal, verify labels, date picker, and buttons are in Polish.
4. Trigger validation errors (e.g. invalid weight, invalid email) and verify Polish error messages.
5. Restart the app and verify the selected Polish language is retained.

## Performance Considerations

- `gen-l10n` generates compiled Dart code; string lookups have `O(1)` runtime overhead and no runtime JSON parsing delay.
- Secure storage read is performed once at startup to restore the preferred locale.

## Migration Notes

- No database schema or remote data migration needed.
- Existing user sessions and saved weights/targets remain completely unchanged.

## References

- Architecture Overview: [01_architecture_overview.md](file:///Users/dimi/Desktop/10xdevs/bulk_tempo/context/documentation/01_architecture_overview.md)
- State Management (MVVM): [03_state_management_mvvm.md](file:///Users/dimi/Desktop/10xdevs/bulk_tempo/context/documentation/03_state_management_mvvm.md)
- Testing Strategy: [06_testing_strategy.md](file:///Users/dimi/Desktop/10xdevs/bulk_tempo/context/documentation/06_testing_strategy.md)

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands. Do not rename step titles. See `references/progress-format.md`.

### Phase 1: Localization Infrastructure & Code Generation Setup

#### Automated

- [x] 1.1 Dependencies resolved successfully: `flutter pub get`
- [x] 1.2 Localization code generation completes without errors: `flutter gen-l10n`
- [x] 1.3 Static analysis passes: `flutter analyze`
- [x] 1.4 Existing test suite passes: `flutter test`

#### Manual

- [x] 1.5 App compiles and runs displaying the default English strings

### Phase 2: Locale State Management & Profile Language Selector

#### Automated

- [ ] 2.1 Unit test for `LocaleNotifier` passes: `flutter test test/core/localization/locale_notifier_test.dart`
- [ ] 2.2 Static analysis passes: `flutter analyze`

#### Manual

- [ ] 2.3 In the Profile tab, changing the language immediately switches the application locale between English and Polish
- [ ] 2.4 Restarting the app persists the chosen language setting

### Phase 3: Core Utilities & Validation Error Localization

#### Automated

- [ ] 3.1 Unit tests for `WeightValidators` and `HevyKeyValidators` pass: `flutter test test/core/utils/`
- [ ] 3.2 Unit tests for `WeekDateUtils` pass with both `en` and `pl` locales: `flutter test test/core/utils/week_date_utils_test.dart`
- [ ] 3.3 Static analysis passes: `flutter analyze`

#### Manual

- [ ] 3.4 Dates in charts and list headers correctly format in Polish (e.g., abbreviated Polish weekdays/months) when the Polish locale is active

### Phase 4: Full Presentation View & Widget String Migration

#### Automated

- [ ] 4.1 Code generation creates up-to-date localizations: `flutter gen-l10n`
- [ ] 4.2 Code formatting check passes: `dart format --output=none --set-exit-if-changed lib test`
- [ ] 4.3 Static analysis clean: `flutter analyze`
- [ ] 4.4 Test suite passes: `flutter test`

#### Manual

- [ ] 4.5 Navigating through Login, Register, Home, Weights, Workouts, and Profile in Polish shows 100% Polish copy with no untranslated English strings or placeholder artifacts
- [ ] 4.6 Dialogs (Log out, Overwrite weight, Delete weight, Discard changes) display correctly in Polish

### Phase 5: Test Infrastructure & Verification

#### Automated

- [ ] 5.1 Code formatting check: `dart format --output=none --set-exit-if-changed lib test`
- [ ] 5.2 Static analysis clean: `flutter analyze`
- [ ] 5.3 All unit and widget tests pass: `flutter test`
- [ ] 5.4 Translation parity test passes: `flutter test test/core/localization/l10n_parity_test.dart`

#### Manual

- [ ] 5.5 App runs smoothly on emulator/device in both English and Polish without visual overflow or broken layout due to string length differences
