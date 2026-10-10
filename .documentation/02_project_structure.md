# 02. Project Structure & Naming Conventions

This document specifies the folder layout, file organization, and naming standards for **Bulk Tempo**. Following these conventions guarantees consistency, predictable module boundaries, and frictionless code generation by AI agents.

---

## 1. Directory Tree Layout

```text
bulk_tempo/
├── .documentation/                      # Architectural specifications & guidelines
├── lib/
│   ├── app/                             # Application root setup
│   │   ├── app.dart                     # MaterialApp.router configuration
│   │   ├── router/                      # GoRouter instance, auth guards, refresh listenable
│   │   └── app_providers.dart           # Global provider observers / top-level providers
│   ├── core/                            # Shared, cross-cutting infrastructure
│   │   ├── constants/                   # App constants, API endpoints, storage keys
│   │   ├── errors/                      # AppFailure hierarchy and exception mappers
│   │   ├── network/                     # HTTP/Dio client, interceptors, network info
│   │   ├── result/                      # Functional Result<T, E> implementation
│   │   ├── router/                      # Route paths, route names
│   │   ├── theme/                       # Color palettes, typography, ThemeData
│   │   └── utils/                       # General helpers, string & date extensions
│   ├── features/                        # Self-contained feature slices
│   │   └── <feature_name>/
│   │       ├── data/                    # Concrete data implementations
│   │       │   ├── datasources/         # <feature>_remote_data_source.dart, local data sources
│   │       │   ├── models/              # <feature>_dto.dart (serialization / fromJson)
│   │       │   └── repositories/        # <feature>_repository_impl.dart
│   │       ├── domain/                  # Business logic & repository interfaces
│   │       │   ├── models/              # <feature>_entity.dart (business entities)
│   │       │   └── repositories/        # <feature>_repository.dart (abstract interface)
│   │       └── presentation/            # UI components and view models
│   │           ├── view_models/         # <feature>_view_model.dart, <feature>_state.dart
│   │           ├── views/               # <feature>_screen.dart (full-screen views)
│   │           └── widgets/             # Reusable UI widgets scoped to this feature
│   └── main.dart                        # Main entry point (runApp wrapped in ProviderScope)
├── test/                                # Mirrors the lib/ directory 1-to-1
│   ├── app/
│   │   └── router/                      # Routing & navigation tests
│   ├── core/
│   │   └── network/                     # Network client and error parsing tests
│   ├── features/
│   │   └── <feature_name>/
│   │       ├── data/
│   │       │   ├── datasources/         # Unit tests for data sources with mocked HTTP client
│   │       │   └── repositories/        # Unit tests for repository implementation
│   │       ├── domain/                  # Unit tests for business entity logic & validation
│   │       └── presentation/
│   │           ├── view_models/         # Unit tests for ViewModels (ProviderContainer)
│   │           └── views/               # Widget tests for screen rendering and user interactions
│   └── test_helpers/                    # Reusable testing utilities
│       ├── fakes/                       # In-memory fakes for domain repositories
│       ├── fixtures/                    # Mock JSON payloads and fixture readers
│       ├── mocks.dart                   # Mocktail mock class definitions
│       └── pump_app.dart                # Test extension wrapping widgets in ProviderScope
└── pubspec.yaml                         # Project dependencies and environment constraints
```

---

## 2. Step-by-Step Feature Scaffolding Checklist

When creating a new feature (e.g. `auth`), follow this sequence to maintain proper dependency flow:

1. **Domain Layer**:
   - [ ] Define the domain entity in `lib/features/<feature>/domain/models/<entity>_entity.dart`.
   - [ ] Define the repository interface in `lib/features/<feature>/domain/repositories/<feature>_repository.dart`.
2. **Data Layer**:
   - [ ] Create the DTO with `fromJson`, `toJson`, and `toEntity()` in `lib/features/<feature>/data/models/<model>_dto.dart`.
   - [ ] Create the data source in `lib/features/<feature>/data/datasources/<feature>_remote_data_source.dart`.
   - [ ] Implement the repository in `lib/features/<feature>/data/repositories/<feature>_repository_impl.dart`.
   - [ ] Declare Riverpod providers for data source and repository.
3. **Presentation Layer**:
   - [ ] Define immutable UI state in `lib/features/<feature>/presentation/view_models/<feature>_state.dart`.
   - [ ] Implement the `Notifier` or `AsyncNotifier` in `lib/features/<feature>/presentation/view_models/<feature>_view_model.dart`.
   - [ ] Build the screen widget in `lib/features/<feature>/presentation/views/<feature>_screen.dart`.
4. **Routing**:
   - [ ] Register the route path and screen in `lib/app/router/app_router.dart`.
5. **Testing**:
   - [ ] Add repository unit test in `test/features/<feature>/data/repositories/<feature>_repository_impl_test.dart`.
   - [ ] Add ViewModel unit test in `test/features/<feature>/presentation/view_models/<feature>_view_model_test.dart`.
   - [ ] Add screen widget test in `test/features/<feature>/presentation/views/<feature>_screen_test.dart`.
