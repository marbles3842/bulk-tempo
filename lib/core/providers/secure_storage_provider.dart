import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Canonical provider for [FlutterSecureStorage] across all features.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final secureStorageWritesProvider = Provider((ref) => SecureStorageWrites());

/// Tracks entire operations that can eventually write to secure storage.
class SecureStorageWrites {
  final _pending = <Future<void>>{};
  int _pauses = 0;

  bool get isPaused => _pauses > 0;

  /// Returns null when logout has paused new writes.
  Future<T?> run<T>(Future<T> Function() operation) async {
    if (isPaused) return null;

    final completed = Completer<void>();
    _pending.add(completed.future);
    try {
      return await operation();
    } finally {
      _pending.remove(completed.future);
      completed.complete();
    }
  }

  Future<void> pauseAndDrain() async {
    _pauses++;
    await Future.wait(_pending);
  }

  void resume() {
    _pauses--;
  }
}
