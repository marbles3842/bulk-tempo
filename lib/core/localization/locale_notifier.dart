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
/// A null locale follows the system setting until an override is selected.
class LocaleNotifier extends Notifier<Locale?> {
  static const String storageKey = 'app_locale';

  int _loadToken = 0;
  Future<void> _pendingWrite = Future<void>.value();

  @override
  Locale? build() {
    initializeDateFormatting('en', null);
    initializeDateFormatting('pl', null);
    Intl.defaultLocale = null;
    loadPersistedLocale();
    return null;
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
          state = null;
        }
        Intl.defaultLocale = state?.languageCode;
      }
    } catch (_) {
      // Storage read failure keeps the current locale preference.
    }
  }

  /// Updates the active locale and persists the selection to secure storage.
  /// A null selection clears the override and follows the system locale.
  Future<void> setLocale(Locale? locale) {
    ++_loadToken;
    state = locale;
    Intl.defaultLocale = locale?.languageCode;
    final storage = ref.read(secureStorageProvider);
    _pendingWrite = _pendingWrite.then((_) async {
      try {
        if (locale == null) {
          await storage.delete(key: storageKey);
        } else {
          final value =
              locale.countryCode != null && locale.countryCode!.isNotEmpty
              ? '${locale.languageCode}_${locale.countryCode}'
              : locale.languageCode;
          await storage.write(key: storageKey, value: value);
        }
      } catch (_) {
        // Storage write failure should not disrupt in-memory state.
      }
    });
    return _pendingWrite;
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
