abstract final class HeavyEnv {
  static const String baseUrl = String.fromEnvironment(
    'HEAVY_BASE_URL',
    defaultValue: '',
  );

  static const String apiKey = String.fromEnvironment(
    'HEAVY_API_KEY',
    defaultValue: '',
  );

  static bool get isConfigured => baseUrl.isNotEmpty && apiKey.isNotEmpty;
}
