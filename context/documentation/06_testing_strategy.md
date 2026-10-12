# 06. Testing Strategy & Quality Assurance

This document defines the testing architecture, layout conventions, and concrete examples for **Bulk Tempo**. It details how to write unit tests for ViewModels and Repositories, and widget tests for Views using `flutter_test` and `mocktail`.

---

## 1. Testing Architecture & Directory Mirroring

### A. Directory Structure
The `test/` directory mirrors `lib/` for functional application code:

```text
test/
├── core/
│   ├── network/
│   └── router/
├── features/
│   └── <feature_name>/
│       ├── data/
│       │   ├── datasources/<feature>_remote_data_source_test.dart
│       │   └── repositories/<feature>_repository_impl_test.dart
│       └── presentation/
│           ├── view_models/<feature>_view_model_test.dart
│           └── views/<feature>_screen_test.dart
└── test_helpers/
    ├── fakes/
    ├── fixtures/
    ├── mocks.dart
    └── pump_app.dart
```

### B. What NOT to Test (Strict Exclusions)

> [!IMPORTANT]
> **Never write dedicated unit tests for DTOs, Entities, or UI State Data Classes.**
> - Models annotated with **`@freezed`** (Entities, DTOs, Form States, and Presentation States) have their behavioral contracts (`copyWith`, `operator ==`, `hashCode`, `toString()`, and serialization) guaranteed by code generation.
> - Writing tests solely to assert value equality, property getters, or `copyWith` behavior on data classes is **strictly prohibited**.
> - Conversion and serialization logic (`toEntity`, `fromEntity`, `fromJson`) must be verified through **Data Source** and **Repository** tests where data actually flows.

---

## 2. Test Helpers Setup

### A. Shared Mocks (`test/test_helpers/mocks.dart`)
Define all `mocktail` mock classes in a centralized file:

```dart
import 'package:mocktail/mocktail.dart';
import 'package:bulk_tempo/features/items/domain/repositories/items_repository.dart';
import 'package:bulk_tempo/features/items/data/datasources/items_remote_data_source.dart';

class MockItemsRepository extends Mock implements ItemsRepository {}
class MockItemsRemoteDataSource extends Mock implements ItemsRemoteDataSource {}
```

### B. Widget Test Pump Helper (`test/test_helpers/pump_app.dart`)
Wraps tested widgets in a `ProviderScope` and `MaterialApp`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

extension PumpAppExtension on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const [],
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          home: widget,
        ),
      ),
    );
  }
}
```

---

## 3. ViewModel Unit Testing (Headless via `ProviderContainer`)

ViewModels must be tested **without a widget tree** using Riverpod's `ProviderContainer`. This provides instant execution.

```dart
// test/features/items/presentation/view_models/items_view_model_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/result/result.dart';
import 'package:bulk_tempo/features/items/data/repositories/items_repository_impl.dart';
import 'package:bulk_tempo/features/items/domain/models/item_entity.dart';
import 'package:bulk_tempo/features/items/domain/repositories/items_repository.dart';
import 'package:bulk_tempo/features/items/presentation/view_models/items_state.dart';
import 'package:bulk_tempo/features/items/presentation/view_models/items_view_model.dart';
import '../../../../test_helpers/mocks.dart';

void main() {
  late MockItemsRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockItemsRepository();
    container = ProviderContainer(
      overrides: [
        itemsRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  const testItems = [
    ItemEntity(id: '1', title: 'Task 1', isCompleted: false),
  ];

  test('initial state should be ItemsInitial', () {
    final state = container.read(itemsViewModelProvider);
    expect(state, isA<ItemsInitial>());
  });

  test('fetchItems emits [ItemsLoading, ItemsLoaded] on repository success', () async {
    when(() => mockRepository.getItems())
        .thenAnswer((_) async => const Result.success(testItems));

    final viewModel = container.read(itemsViewModelProvider.notifier);

    // Act
    final future = viewModel.fetchItems();

    // Assert intermediary loading state
    expect(container.read(itemsViewModelProvider), isA<ItemsLoading>());

    await future;

    // Assert final loaded state
    final finalState = container.read(itemsViewModelProvider);
    expect(finalState, isA<ItemsLoaded>());
    expect((finalState as ItemsLoaded).items, testItems);
    verify(() => mockRepository.getItems()).called(1);
  });

  test('fetchItems emits [ItemsLoading, ItemsError] on repository failure', () async {
    when(() => mockRepository.getItems()).thenAnswer(
      (_) async => const Result.failure(ServerFailure('Server down', statusCode: 500)),
    );

    final viewModel = container.read(itemsViewModelProvider.notifier);

    await viewModel.fetchItems();

    final finalState = container.read(itemsViewModelProvider);
    expect(finalState, isA<ItemsError>());
    expect((finalState as ItemsError).message, 'Server down');
  });
}
```

---

## 4. Repository Unit Testing

Test repository logic, DTO mapping, and exception translation:

```dart
// test/features/items/data/repositories/items_repository_impl_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/features/items/data/models/item_dto.dart';
import 'package:bulk_tempo/features/items/data/repositories/items_repository_impl.dart';
import '../../../../test_helpers/mocks.dart';

void main() {
  late MockItemsRemoteDataSource mockDataSource;
  late ItemsRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockItemsRemoteDataSource();
    repository = ItemsRepositoryImpl(mockDataSource);
  });

  final testDtos = [
    const ItemDto(id: '1', title: 'Test Item', completed: false),
  ];

  test('getItems returns Success with entities when data source succeeds', () async {
    when(() => mockDataSource.fetchItems()).thenAnswer((_) async => testDtos);

    final result = await repository.getItems();

    result.when(
      success: (items) {
        expect(items.length, 1);
        expect(items.first.title, 'Test Item');
      },
      failure: (_) => fail('Should not fail'),
    );
    verify(() => mockDataSource.fetchItems()).called(1);
  });

  test('getItems returns Failure when data source throws ServerException', () async {
    when(() => mockDataSource.fetchItems())
        .thenThrow(const ServerException(message: 'Internal Error', statusCode: 500));

    final result = await repository.getItems();

    result.when(
      success: (_) => fail('Should not succeed'),
      failure: (failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Internal Error');
      },
    );
  });
}
```

---

## 5. Widget Testing (Views)

Test screen presentation by overriding providers with concrete states:

```dart
// test/features/items/presentation/views/items_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/features/items/domain/models/item_entity.dart';
import 'package:bulk_tempo/features/items/presentation/view_models/items_state.dart';
import 'package:bulk_tempo/features/items/presentation/view_models/items_view_model.dart';
import 'package:bulk_tempo/features/items/presentation/views/items_screen.dart';
import '../../../../test_helpers/pump_app.dart';

// Create a Fake ViewModel for deterministic UI testing
class FakeItemsViewModel extends ItemsViewModel {
  final ItemsState initialState;
  FakeItemsViewModel(this.initialState);

  @override
  ItemsState build() => initialState;
}

void main() {
  testWidgets('renders CircularProgressIndicator when state is ItemsLoading', (tester) async {
    await tester.pumpApp(
      const ItemsScreen(),
      overrides: [
        itemsViewModelProvider.overrideWith(
          () => FakeItemsViewModel(const ItemsLoading()),
        ),
      ],
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders list of items when state is ItemsLoaded', (tester) async {
    const items = [
      ItemEntity(id: '1', title: 'Buy milk', isCompleted: false),
      ItemEntity(id: '2', title: 'Walk dog', isCompleted: true),
    ];

    await tester.pumpApp(
      const ItemsScreen(),
      overrides: [
        itemsViewModelProvider.overrideWith(
          () => FakeItemsViewModel(const ItemsLoaded(items)),
        ),
      ],
    );

    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('Walk dog'), findsOneWidget);
  });
}
```

---

## 6. Verification Commands

Before completing any task, run these verification steps from root:

```bash
# 1. Check code formatting
dart format --output=none --set-exit-if-changed lib test

# 2. Run static analysis
flutter analyze

# 3. Execute all unit and widget tests
flutter test
```
