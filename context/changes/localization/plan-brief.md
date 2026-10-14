# Localization Support — Plan Brief

> Full plan: `context/changes/localization/plan.md`

## What & Why

Bulk Tempo currently hardcodes all user-facing UI text, labels, and validation messages in English. This change introduces internationalization (i18n) support for multiple languages—starting with English and Polish—allowing users to seamlessly switch languages or follow their device's system settings.

## Starting Point

The app uses Flutter with Riverpod MVVM architecture. `flutter_localizations` is installed in `pubspec.yaml`, but Flutter's code generation (`gen-l10n`) is not enabled, and no `.arb` translation files exist. `MaterialApp.router` in `lib/app/app.dart` hardcodes the locale to `en_GB`.

## Desired End State

Users can run Bulk Tempo in English or Polish, with all screens, dialogs, cards, charts, and error states dynamically localized. The user can change their preferred language at any time in the Profile tab, with their preference securely persisted across app launches.

## Key Decisions Made

| Decision | Choice | Why (1 sentence) |
| --- | --- | --- |
| Localization Tooling | Official Flutter `gen-l10n` & ARB | Standard built-in Flutter tool with zero third-party overhead and compile-time type safety. |
| Supported Locales | English (`en`, fallback) & Polish (`pl`) | Covers primary user base and establishes multi-language architecture. |
| Locale Selection & Persistence | Riverpod `LocaleNotifier` + `FlutterSecureStorage` | Allows system default detection with manual override in Profile tab persisted safely. |
| Validation Messages | Typed error keys in pure Dart utilities | Keeps Domain/Core independent of `BuildContext` while allowing Views to resolve localized messages. |
| Date Formatting | `intl` `DateFormat` with dynamic locale | Localizes calendar month and weekday names across cards and charts cleanly. |
| Test Strategy | Update `pump_app.dart` + dedicated Polish & parity tests | Keeps existing widget tests green without churn while verifying translation completeness. |

## Scope

**In scope:**
- Setup of `l10n.yaml`, `app_en.arb`, and `app_pl.arb` with full key coverage.
- Riverpod `LocaleNotifier` with secure storage persistence and Profile tab language switcher.
- Localization of all UI views in Auth, Weight, Workout, and Gain Target features.
- Refactoring `WeekDateUtils`, `WeightValidators`, and `HevyKeyValidators` for localization.
- ARB key parity tests and Polish rendering tests.

**Out of scope:**
- External API backend data (exercise names or remote workout titles).
- Dynamic runtime translation downloading (OTA).
- Additional languages beyond English and Polish for this milestone.

## Architecture / Approach

The application uses standard Flutter `gen-l10n` to generate type-safe `AppLocalizations`. `MaterialApp.router` listens to Riverpod's `localeProvider`, which defaults to system locale and restores any user override saved in `FlutterSecureStorage`. Views access translations via a convenient extension `context.l10n.<key>`.

```
[FlutterSecureStorage] <---> [LocaleNotifier (Riverpod)]
                                      |
                                      v
                             [MaterialApp.router]
                                      |
                         +------------+------------+
                         |                         |
                 [AppLocalizations]        [Language Picker]
                  (en / pl .arb)             (Profile tab)
```

## Phases at a Glance

| Phase | What it delivers | Key risk |
| --- | --- | --- |
| 1. Infrastructure Setup | `l10n.yaml`, `intl`, ARB scaffolding, `AppLocalizations` delegates wired | Generator config misalignments |
| 2. Locale State & Switching | `LocaleNotifier`, persistent storage, Profile UI switcher | State race during startup |
| 3. Core Utilities & Validators | Localized `WeekDateUtils` and typed validator error keys | Breaking date formatting tests |
| 4. UI Widgets Migration | 100% hardcoded strings migrated across all features | Missed strings or UI overflow |
| 5. Testing & Verification | `pump_app.dart` update, parity tests, Polish rendering test | Missing keys in Polish ARB |

**Prerequisites:** Working Flutter environment with dependencies installed.
**Estimated effort:** ~1-2 implementation sessions across 5 phases.

## Open Risks & Assumptions

- **Text Overflow**: Polish text can be 20-30% longer than English; views must accommodate expanded label lengths without overflow.
- **Transitive Intl Version**: `intl` dependency must match `flutter_localizations` SDK constraints (resolved with `^0.20.2`).

## Success Criteria (Summary)

- Complete translation parity between `app_en.arb` and `app_pl.arb`.
- Switching language in the Profile tab immediately re-renders all UI elements in the selected language.
- All unit, widget, and static analysis checks pass cleanly.
