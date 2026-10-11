/// Constants for the Hevy Public REST API and local API key storage.
abstract final class HevyApiConstants {
  static const String baseUrl = 'https://api.hevyapp.com';
  static const String workoutsPath = '/v1/workouts';
  static const String workoutsCountPath = '/v1/workouts/count';
  static const String apiKeyHeader = 'api-key';
  static const int pageSize = 10;
  static const int maxPages = 15;
  static const int lookbackWeeks = 12;
  static const String storageKeyPrefix = 'hevy_api_key_';

  static String storageKeyForUser(String userId) => '$storageKeyPrefix$userId';
}
