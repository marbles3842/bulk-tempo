import 'dart:ui';

/// Application locale constants and conversion helpers.
abstract final class LocaleConstants {
  /// Language code for English.
  static const String english = 'en';

  /// Language code for Polish.
  static const String polish = 'pl';

  /// Default application [Locale].
  static const Locale defaultLocale = Locale(english);

  /// English [Locale].
  static const Locale englishLocale = Locale(english);

  /// Polish [Locale].
  static const Locale polishLocale = Locale(polish);

  /// Supported [Locale] list for explicit selection.
  static const List<Locale> supportedLocales = [englishLocale, polishLocale];

  /// Maps an active [Locale] to its selector code.
  static String toSelectionCode(Locale locale) {
    return locale.languageCode == polish ? polish : english;
  }

  /// Maps a selector code to the corresponding [Locale].
  static Locale fromSelectionCode(String code) {
    return code == polish ? polishLocale : englishLocale;
  }
}
