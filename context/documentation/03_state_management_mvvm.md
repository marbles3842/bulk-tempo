# 03. State Management & MVVM Pattern

This document defines the MVVM presentation layer standards for **Bulk Tempo** using **Riverpod** (`flutter_riverpod`). It covers pure Dart UI state modeling, ViewModel lifecycle, View binding, and side-effect handling.

---

## 1. Modeling UI State (Freezed)

All UI State classes must be **immutable** and modeled using **`@freezed`**. This guarantees value equality, hashing, readable string formatting, and a type-safe `copyWith` that natively supports resetting nullable fields to `null` without awkward `_sentinel` objects or `clear...` flags.

Two patterns are supported depending on screen requirements:

### Pattern A: Freezed Sealed Union Hierarchy (Mutually Exclusive States)
Ideal for screens that transition strictly through distinct operational phases (e.g. initial, loading, loaded, error):

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bulk_tempo/features/items/domain/models/item_entity.dart';

part 'items_state.freezed.dart';

@freezed
sealed class ItemsState with _$ItemsState {
  const factory ItemsState.initial() = ItemsInitial;
  const factory ItemsState.loading() = ItemsLoading;
  const factory ItemsState.loaded(List<ItemEntity> items) = ItemsLoaded;
  const factory ItemsState.error(String message) = ItemsError;
}
```

*Advantage*: Generates pattern matching helpers (`when`, `map`) while maintaining full compatibility with Dart 3 switch expressions (`switch (state)`).

### Pattern B: Freezed Data Class (Composite / Form State)
Ideal for forms or screens with multiple independent fields (e.g. text inputs, validation errors, toggles, filter chips):

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_form_state.freezed.dart';

enum FormStatus { initial, submitting, success, failure }

@freezed
abstract class LoginFormState with _$LoginFormState {
  const LoginFormState._();

  const factory LoginFormState({
    @Default('') String email,
    @Default('') String password,
    @Default(FormStatus.initial) FormStatus status,
    String? errorMessage,
  }) = _LoginFormState;

  bool get isValid =>
      email.trim().isNotEmpty && password.isNotEmpty;
}
```

*Advantage of Freezed `copyWith`*:
Callers can reset nullable fields directly with `state = state.copyWith(errorMessage: null);`. When `errorMessage` is omitted from `copyWith()`, its current value is preserved automatically without requiring custom sentinels or boolean reset flags.

---

## 2. ViewModel Implementation

A ViewModel:
1. Subclasses `AutoDisposeNotifier<T>` or `Notifier<T>`.
2. Emits new states by reassigning `state = ...`.
3. Calls domain repositories and handles returned `Result` types.
4. **Never imports `flutter/material.dart`** or accepts a `BuildContext`.

### Standard ViewModel Template:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/features/items/data/repositories/items_repository_impl.dart';
import 'package:bulk_tempo/features/items/domain/models/item_entity.dart';
import 'package:bulk_tempo/features/items/domain/repositories/items_repository.dart';
import 'package:bulk_tempo/features/items/presentation/view_models/items_state.dart';

final itemsViewModelProvider =
    NotifierProvider.autoDispose<ItemsViewModel, ItemsState>(
  ItemsViewModel.new,
);

class ItemsViewModel extends AutoDisposeNotifier<ItemsState> {
  late final ItemsRepository _repository;

  @override
  ItemsState build() {
    // Inject repository dependency
    _repository = ref.watch(itemsRepositoryProvider);
    return const ItemsInitial();
  }

  Future<void> fetchItems() async {
    state = const ItemsLoading();

    final result = await _repository.getItems();

    result.when(
      success: (items) {
        state = ItemsLoaded(items);
      },
      failure: (failure) {
        state = ItemsError(failure.message);
      },
    );
  }
}
```

---

## 3. View (Widget) Binding Guidelines

Views must be implemented as `ConsumerWidget` (or `ConsumerStatefulWidget` only when managing local animation controllers or text controllers).

### Rules for `ref` interactions:

1. **`ref.watch(provider)`**:
   - Use inside the `build()` method to reactively listen to state changes and trigger rebuilds.
2. **`ref.read(provider.notifier)`**:
   - Use inside user event handlers (`onPressed`, `onChanged`) to dispatch actions to the ViewModel.
   - **Never call `ref.read` directly in the `build()` method.**
3. **`ref.listen(provider, (prev, next) { ... })`**:
   - Use for transient side effects: showing SnackBars, displaying AlertDialogs, or triggering external routing.

### Standard View Template:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/features/items/presentation/view_models/items_state.dart';
import 'package:bulk_tempo/features/items/presentation/view_models/items_view_model.dart';

class ItemsScreen extends ConsumerWidget {
  const ItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Listen for transient notifications (errors, alerts)
    ref.listen<ItemsState>(itemsViewModelProvider, (previous, next) {
      if (next is ItemsError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: Colors.red),
        );
      }
    });

    // 2. Watch current state for UI rendering
    final state = ref.watch(itemsViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Items')),
      body: switch (state) {
        ItemsInitial() => Center(
            child: ElevatedButton(
              onPressed: () =>
                  ref.read(itemsViewModelProvider.notifier).fetchItems(),
              child: const Text('Load Items'),
            ),
          ),
        ItemsLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
        ItemsLoaded(items: final items) => items.isEmpty
            ? const Center(child: Text('No items found.'))
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(items[index].title),
                ),
              ),
        ItemsError(message: final message) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(message),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(itemsViewModelProvider.notifier).fetchItems(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
      },
    );
  }
}
```

---

## 4. Golden Rules & Anti-Patterns

### DO:
- Keep ViewModels completely pure Dart so they execute in microsecond unit tests.
- Model all visual UI permutations inside the state class.
- Use `autoDispose` for screen-level ViewModels so memory is released when leaving the screen.

### DON'T:
- **Never pass `BuildContext` into a ViewModel**. If navigation or a snackbar is required, let the View handle it using `ref.listen`.
- **Never put network, database, or API calls inside the ViewModel**. Delegate all data access to repository interfaces.
- **Never mutate state directly** (`state.items.add(newItem)` is strictly forbidden). Always emit a new instance.
