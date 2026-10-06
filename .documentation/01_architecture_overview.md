# 01. Architecture Overview

This document describes the high-level architecture for **Bulk Tempo**. The system is built on **Feature-First Model-View-ViewModel (MVVM)** augmented with **Clean Architecture boundaries**, specifically optimized for maintainability and AI agent skill generation.

---

## 1. Layer Breakdown & Responsibilities

### A. Presentation Layer (`lib/features/<feature>/presentation/`)
- **View (`views/`, `widgets/`)**:
  - Implemented as `ConsumerWidget` or `ConsumerStatefulWidget`.
  - Responsible strictly for rendering UI and forwarding user gestures to the ViewModel.
  - Contains **no** business logic, data formatting logic, or direct network/database calls.
- **ViewModel (`view_models/`)**:
  - Implemented as a Riverpod `Notifier<State>` or `AsyncNotifier<State>`.
  - Manages and transforms UI state.
  - Interacts only with Domain repository interfaces injected via Riverpod providers.
  - Must never import `dart:ui` or `package:flutter/material.dart` directly (with rare exceptions like `Color` or `IconData` when strictly necessary, though styling should remain in the View).
  - Must never accept or retain a `BuildContext`.
- **UI State**:
  - Pure Dart immutable class or sealed class hierarchy representing all potential visual states: *Initial*, *Loading*, *Success*, *Error*.

### B. Domain Layer (`lib/features/<feature>/domain/`)
- Represents the core business logic and rules of the feature.
- **Entities (`models/`)**: Pure Dart business models containing attributes and domain validations. Independent of database schemas or API response formats.
- **Repository Interfaces (`repositories/`)**: Abstract contracts defining operations the domain expects the data layer to fulfill (e.g. `Future<Result<UserProfile, AppFailure>> fetchProfile()`).
- **Dependencies**: **Zero external dependencies**. The domain layer must NEVER import the data layer, presentation layer, or Flutter framework packages.

### C. Data Layer (`lib/features/<feature>/data/`)
- Responsible for data retrieval, persistence, and synchronization.
- **Data Transfer Objects (`models/`)**: DTOs that handle serialization (`fromJson`, `toJson`) and mapping to/from Domain Entities (`toEntity()`, `fromEntity()`).
- **Data Sources (`datasources/`)**:
  - `RemoteDataSource`: Direct communication with external APIs using HTTP/Dio.
  - `LocalDataSource`: Local persistence using SQLite, SecureStorage, or SharedPreferences.
- **Repository Implementations (`repositories/`)**: Implements the abstract repository defined in the domain layer. Catches data source exceptions and transforms them into typed `Result<T, AppFailure>` values.

### D. Core Layer (`lib/core/`)
- Cross-cutting concerns shared across features:
  - Network clients and HTTP interceptors.
  - Functional `Result<T, E>` pattern and standard `AppFailure` types.
  - Global router configuration (`go_router`).
  - App-wide theme and design system tokens.
  - General utility extensions (dates, strings, formatting).

---

## 2. Strict Dependency & Import Rules

To prevent architectural erosion, all code written in this repository must comply with the following boundary constraints:

| Layer | Can Import | MUST NEVER Import |
| :--- | :--- | :--- |
| **Domain** | Pure Dart standard libraries (`dart:core`, `dart:async`), `package:bulk_tempo/core/result/`, `package:bulk_tempo/core/errors/` | `presentation/`, `data/`, `package:flutter/*`, external packages |
| **Presentation** | `domain/`, `core/`, `package:flutter/*`, `package:flutter_riverpod/*`, `data/repositories/` (repository providers only) | Concrete datasources or DTOs from `data/` |
| **Data** | `domain/`, `core/`, external network/database packages | `presentation/` |
| **Core** | Pure Dart, Flutter framework utilities | Any `features/` directory (Core must remain feature-agnostic) |

---

## 3. Unidirectional Data Flow in Action

1. **User Action**: The user taps a button in `ProfileScreen` (`View`).
2. **Action Dispatch**: The View calls `ref.read(profileViewModelProvider.notifier).loadUserProfile(userId)`.
3. **State Transition**: The `ProfileViewModel` immediately emits a `ProfileLoadingState` to signal to the View to display a progress indicator.
4. **Repository Invocation**: The ViewModel calls `await _profileRepository.getProfile(userId)`.
5. **Data Source Query**: The `ProfileRepositoryImpl` queries `ProfileRemoteDataSource.fetchProfileJson(userId)`.
6. **Data Mapping**: The DataSource returns a `ProfileDto`, which the repository maps to a clean `ProfileEntity`.
7. **Result Delivery**: The repository returns `Result.success(profileEntity)` (or `Result.failure(networkFailure)`).
8. **UI State Update**: The ViewModel receives the `Result` and emits `ProfileSuccessState(profileEntity)`.
9. **Re-render**: The `ProfileScreen` automatically rebuilds with the user's data.
