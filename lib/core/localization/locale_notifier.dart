import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Provider for [FlutterSecureStorage] used by locale persistence.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Riverpod notifier managing the active [Locale].
///
/// Defaults to English (`Locale('en')`).
class LocaleNotifier extends Notifier<Locale> {
  static const String storageKey = 'app_locale';
  static const Locale defaultLocale = Locale('en');

  int _loadToken = 0;

  @override
  Locale build() {
    initializeDateFormatting('en', null);
    initializeDateFormatting('pl', null);
    Intl.defaultLocale = defaultLocale.languageCode;
    loadPersistedLocale();
    return defaultLocale;
  }

  /// Reads persisted locale from [FlutterSecureStorage] and updates [state].
  Future<void> loadPersistedLocale() async {
    final currentToken = ++_loadToken;
    final storage = ref.read(secureStorageProvider);
    try {
      final code = await storage.read(key: storageKey);
      if (currentToken == _loadToken) {
        if (code != null && code.isNotEmpty) {
          state = _parseLocale(code);
        } else {
          state = defaultLocale;
        }
        Intl.defaultLocale = state.languageCode;
      }
    } catch (_) {
      // Storage read failure gracefully keeps default locale
    }
  }

  /// Updates the active locale and persists the selection to secure storage.
  Future<void> setLocale(Locale locale) async {
    ++_loadToken;
    state = locale;
    Intl.defaultLocale = locale.languageCode;
    final storage = ref.read(secureStorageProvider);
    try {
      final value = locale.countryCode != null && locale.countryCode!.isNotEmpty
          ? '${locale.languageCode}_${locale.countryCode}'
          : locale.languageCode;
      await storage.write(key: storageKey, value: value);
    } catch (_) {
      // Storage write failure should not disrupt in-memory state
    }
  }

  static Locale _parseLocale(String code) {
    if (code.contains('_')) {
      final parts = code.split('_');
      return Locale(parts[0], parts[1]);
    } else if (code.contains('-')) {
      final parts = code.split('-');
      return Locale(parts[0], parts[1]);
    }
    return Locale(code);
  }
}
