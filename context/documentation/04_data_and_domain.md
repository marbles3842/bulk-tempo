# 04. Data and Domain Layers

This document outlines the data persistence, business logic modeling, serialization conventions, and typed error handling standards for **Bulk Tempo**. All domain entities and data transfer objects (DTOs) strictly rely on **Freezed** to eliminate boilerplate code (`copyWith`, `operator ==`, `hashCode`, `toString`) and ensure immutable, robust models.

---

## 1. Functional `Result` Pattern & Error Handling

Instead of throwing uncaught exceptions that cause unpredictable app crashes, the repository layer wraps all return values in a lightweight, pure Dart **`Result<T, AppFailure>`** type.

### The `Result` Type (`lib/core/result/result.dart`):

```dart
sealed class Result<S, F> {
  const Result();

  const factory Result.success(S data) = Success<S, F>;
  const factory Result.failure(F failure) = Failure<S, F>;

  R when<R>({
    required R Function(S data) success,
    required R Function(F failure) failure,
  }) {
    return switch (this) {
      Success(data: final d) => success(d),
      Failure(failure: final f) => failure(f),
    };
  }
}

class Success<S, F> extends Result<S, F> {
  final S data;
  const Success(this.data);
}

class Failure<S, F> extends Result<S, F> {
  final F failure;
  const Failure(this.failure);
}
```

### The `AppFailure` Hierarchy (`lib/core/errors/failures.dart`):

```dart
sealed class AppFailure {
  final String message;
  final int? statusCode;

  const AppFailure(this.message, {this.statusCode});
}

class ServerFailure extends AppFailure {
  const ServerFailure(super.message, {super.statusCode});
}

class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message);
}

class CacheFailure extends AppFailure {
  const CacheFailure(super.message);
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

class UnknownFailure extends AppFailure {
  const UnknownFailure(super.message);
}
```

---

## 2. Domain Layer Specifications

### A. Domain Entity (`domain/models/<entity>_entity.dart`)
Pure Dart model utilizing **Freezed** for immutable state, automatic value equality (`==`), `hashCode`, and `copyWith`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_entity.freezed.dart';

@freezed
class ItemEntity with _$ItemEntity {
  // Private constructor enables defining custom methods/getters if needed
  const ItemEntity._();

  const factory ItemEntity({
    required String id,
    required String title,
    required bool isCompleted,
  }) = _ItemEntity;
}
```

> **Domain Layer Rules:**
> - Domain entities must **never** include serialization logic (`fromJson`/`toJson` or `*.g.dart`).
> - Always declare `const <Entity>._();` if domain getters or business methods are needed on the class.

### B. Repository Contract (`domain/repositories/<feature>_repository.dart`)
Abstract interface defining expected behavior:

```dart
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/result/result.dart';
import 'package:bulk_tempo/features/items/domain/models/item_entity.dart';

abstract class ItemsRepository {
  Future<Result<List<ItemEntity>, AppFailure>> getItems();
  Future<Result<ItemEntity, AppFailure>> getItemById(String id);
  Future<Result<void, AppFailure>> toggleItemStatus(String id);
}
```

---

## 3. Data Layer Specifications

### A. Data Transfer Object (`data/models/<model>_dto.dart`)
DTOs handle external API/database JSON serialization and deserialization, built with **Freezed** and **`json_serializable`**:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bulk_tempo/features/items/domain/models/item_entity.dart';

part 'item_dto.freezed.dart';
part 'item_dto.g.dart';

@freezed
class ItemDto with _$ItemDto {
  const ItemDto._();

  const factory ItemDto({
    required String id,
    required String title,
    @Default(false) bool completed,
  }) = _ItemDto;

  factory ItemDto.fromJson(Map<String, dynamic> json) =>
      _$ItemDtoFromJson(json);

  ItemEntity toEntity() {
    return ItemEntity(
      id: id,
      title: title,
      isCompleted: completed,
    );
  }

  factory ItemDto.fromEntity(ItemEntity entity) {
    return ItemDto(
      id: entity.id,
      title: entity.title,
      completed: entity.isCompleted,
    );
  }
}
```

> **Data Layer Rules:**
> - Always include both `part '<model>_dto.freezed.dart';` and `part '<model>_dto.g.dart';`.
> - Use `@Default(...)` to provide safe fallbacks for missing or null JSON fields.
> - Maintain clean bidirectional mapping between the DTO and its corresponding domain entity (`toEntity()` and `fromEntity()`).

### B. Data Source (`data/datasources/<feature>_remote_data_source.dart`)
Calls network/storage directly and throws low-level exceptions:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/core/network/api_client.dart';
import 'package:bulk_tempo/features/items/data/models/item_dto.dart';

final itemsRemoteDataSourceProvider = Provider<ItemsRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ItemsRemoteDataSourceImpl(apiClient);
});

abstract class ItemsRemoteDataSource {
  Future<List<ItemDto>> fetchItems();
  Future<ItemDto> fetchItemById(String id);
  Future<void> toggleItemStatus(String id);
}

class ItemsRemoteDataSourceImpl implements ItemsRemoteDataSource {
  final ApiClient _client;

  ItemsRemoteDataSourceImpl(this._client);

  @override
  Future<List<ItemDto>> fetchItems() async {
    try {
      final response = await _client.get('/items');
      final list = response.data as List<dynamic>;
      return list
          .map((item) => ItemDto.fromJson(item as Map<String, dynamic>))
          .toList();
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ItemDto> fetchItemById(String id) async {
    try {
      final response = await _client.get('/items/$id');
      return ItemDto.fromJson(response.data as Map<String, dynamic>);
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> toggleItemStatus(String id) async {
    try {
      await _client.patch('/items/$id/toggle');
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
```

### C. Repository Implementation (`data/repositories/<feature>_repository_impl.dart`)
Translates raw data and catches exceptions to return `Result`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/result/result.dart';
import 'package:bulk_tempo/features/items/data/datasources/items_remote_data_source.dart';
import 'package:bulk_tempo/features/items/domain/models/item_entity.dart';
import 'package:bulk_tempo/features/items/domain/repositories/items_repository.dart';

final itemsRepositoryProvider = Provider<ItemsRepository>((ref) {
  final remoteDataSource = ref.watch(itemsRemoteDataSourceProvider);
  return ItemsRepositoryImpl(remoteDataSource);
});

class ItemsRepositoryImpl implements ItemsRepository {
  final ItemsRemoteDataSource _remoteDataSource;

  ItemsRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<List<ItemEntity>, AppFailure>> getItems() async {
    try {
      final dtos = await _remoteDataSource.fetchItems();
      final entities = dtos.map((dto) => dto.toEntity()).toList();
      return Result.success(entities);
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<ItemEntity, AppFailure>> getItemById(String id) async {
    try {
      final dto = await _remoteDataSource.fetchItemById(id);
      return Result.success(dto.toEntity());
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, AppFailure>> toggleItemStatus(String id) async {
    try {
      await _remoteDataSource.toggleItemStatus(id);
      return const Result.success(null);
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }
}
```

---

## 4. Code Generation Guidelines (`build_runner`)

Because entities and DTOs rely on **Freezed** and **`json_serializable`**, running `build_runner` is an integral part of the development workflow.

### A. Required Dependencies (`pubspec.yaml`):

```yaml
dependencies:
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0

dev_dependencies:
  build_runner: ^2.4.15
  freezed: ^2.5.7
  json_serializable: ^6.9.4
```

### B. Generation Commands:

- **One-off build** (run after adding or updating entities/DTOs):
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
- **Watch mode** (continuous generation during feature development):
  ```bash
  dart run build_runner watch --delete-conflicting-outputs
  ```

### C. Rules & Best Practices:
1. **Never manually edit generated code**: Files with `.freezed.dart` and `.g.dart` extensions are managed solely by code generation.
2. **Version control**: Generated files should be committed to git to ensure consistent and deterministic CI/CD builds without requiring an extra build step in pipelines.
3. **Always use `--delete-conflicting-outputs`**: This flag automatically resolves stale or conflicting generator artifacts when switching branches or refactoring model fields.

