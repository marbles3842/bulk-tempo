# 04. Data and Domain Layers

This document outlines the data persistence, business logic modeling, serialization conventions, and typed error handling standards for **Bulk Tempo**.

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
Pure Dart class without serialization logic:

```dart
class ItemEntity {
  final String id;
  final String title;
  final bool isCompleted;

  const ItemEntity({
    required this.id,
    required this.title,
    required this.isCompleted,
  });

  ItemEntity copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return ItemEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ isCompleted.hashCode;
}
```

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
Handles pure Dart JSON parsing and entity conversion without `build_runner`:

```dart
import 'package:bulk_tempo/features/items/domain/models/item_entity.dart';

class ItemDto {
  final String id;
  final String title;
  final bool completed;

  const ItemDto({
    required this.id,
    required this.title,
    required this.completed,
  });

  factory ItemDto.fromJson(Map<String, dynamic> json) {
    return ItemDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
    };
  }

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
