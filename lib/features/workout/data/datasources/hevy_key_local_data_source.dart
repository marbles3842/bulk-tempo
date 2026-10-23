import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bulk_tempo/core/constants/hevy_api_constants.dart';
import 'package:bulk_tempo/core/errors/exceptions.dart';
import 'package:bulk_tempo/core/providers/secure_storage_provider.dart';

@Deprecated(
  'Use secureStorageProvider from core/providers/secure_storage_provider.dart instead',
)
final flutterSecureStorageProvider = secureStorageProvider;

final hevyKeyLocalDataSourceProvider = Provider<HevyKeyLocalDataSource>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return HevyKeyLocalDataSourceImpl(storage);
});

abstract class HevyKeyLocalDataSource {
  Future<String?> readApiKey({required String userId});
  Future<void> writeApiKey({required String userId, required String apiKey});
  Future<void> deleteApiKey({required String userId});
}

class HevyKeyLocalDataSourceImpl implements HevyKeyLocalDataSource {
  final FlutterSecureStorage _secureStorage;

  HevyKeyLocalDataSourceImpl(this._secureStorage);

  @override
  Future<String?> readApiKey({required String userId}) async {
    try {
      final key = HevyApiConstants.storageKeyForUser(userId);
      final value = await _secureStorage.read(key: key);
      if (value == null || value.trim().isEmpty) {
        return null;
      }
      return value.trim();
    } on AppException {
      rethrow;
    } catch (e) {
      throw CacheException('Failed to read Hevy API key: $e');
    }
  }

  @override
  Future<void> writeApiKey({
    required String userId,
    required String apiKey,
  }) async {
    try {
      final key = HevyApiConstants.storageKeyForUser(userId);
      await _secureStorage.write(key: key, value: apiKey.trim());
    } on AppException {
      rethrow;
    } catch (e) {
      throw CacheException('Failed to save Hevy API key: $e');
    }
  }

  @override
  Future<void> deleteApiKey({required String userId}) async {
    try {
      final key = HevyApiConstants.storageKeyForUser(userId);
      await _secureStorage.delete(key: key);
    } on AppException {
      rethrow;
    } catch (e) {
      throw CacheException('Failed to delete Hevy API key: $e');
    }
  }
}
