# Repository Guidelines

## Project Structure & Module Organization

This is a Flutter app targeting Android, iOS, and web. Feature code lives under `lib/` and unit/widget tests live under `test/`; keep platform-specific changes in `android/`, `ios/`, or `web/`. Web icons and the favicon are in `web/icons/` and `web/`. The iOS project includes a placeholder XCTest file at `ios/RunnerTests/RunnerTests.swift`.

## Architecture & Technical Documentation

Comprehensive architectural guidelines and specifications are located in `context/documentation/`:

- @context/documentation/01_architecture_overview.md: High-level system architecture, layer responsibilities (Presentation, Domain, Data, Core), strict dependency rules, and unidirectional data flow.
- @context/documentation/02_project_structure.md: Directory tree layout and step-by-step checklist for scaffolding new features.
- @context/documentation/03_state_management_mvvm.md: MVVM state management using Riverpod (immutable states, ViewModels, View binding rules, and anti-patterns).
- @context/documentation/04_data_and_domain.md: Functional `Result<T, AppFailure>` error handling, domain entities, repository contracts, DTOs, and data sources.
- @context/documentation/05_navigation.md: Declarative routing and deep linking using GoRouter, route constants, and navigation patterns.
- @context/documentation/06_testing_strategy.md: Testing structure mirroring, test helpers (`mocktail`, pump helpers), ViewModel unit tests, repository unit tests, and widget tests.
- @context/documentation/07_design_system.md: Design system contract covering semantic tokens, Material 3 (Android) and Liquid Glass / Cupertino (iOS) adaptation (`adaptive_platform_ui`), core widget wrappers, accessibility, and Widgetbook cataloging.

## Build, Test, and Development Commands

From the repository root: `flutter pub get`, `flutter run` (`-d chrome` for web), `flutter analyze`, `flutter build apk`, and `flutter build web`.

Run `dart format lib test` and `flutter test`.
