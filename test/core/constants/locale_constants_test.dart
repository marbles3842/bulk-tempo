import 'dart:ui';
import 'package:bulk_tempo/core/constants/locale_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocaleConstants', () {
    test('defines expected language code and special selector constants', () {
      expect(LocaleConstants.system, 'system');
      expect(LocaleConstants.english, 'en');
      expect(LocaleConstants.polish, 'pl');
      expect(LocaleConstants.defaultLocale, const Locale('en'));
      expect(LocaleConstants.englishLocale, const Locale('en'));
      expect(LocaleConstants.polishLocale, const Locale('pl'));
      expect(LocaleConstants.supportedLocales, const [
        Locale('en'),
        Locale('pl'),
      ]);
    });

    group('toSelectionCode', () {
      test('maps null locale to system', () {
        expect(LocaleConstants.toSelectionCode(null), 'system');
      });

      test('maps Polish locale to pl', () {
        expect(LocaleConstants.toSelectionCode(const Locale('pl')), 'pl');
        expect(LocaleConstants.toSelectionCode(const Locale('pl', 'PL')), 'pl');
      });

      test('maps English locale to en', () {
        expect(LocaleConstants.toSelectionCode(const Locale('en')), 'en');
        expect(LocaleConstants.toSelectionCode(const Locale('en', 'US')), 'en');
      });

      test('defaults other or unknown locales to English selection', () {
        expect(LocaleConstants.toSelectionCode(const Locale('de')), 'en');
      });
    });

    group('fromSelectionCode', () {
      test('maps system to null', () {
        expect(LocaleConstants.fromSelectionCode('system'), isNull);
      });

      test('maps pl to Polish Locale', () {
        expect(LocaleConstants.fromSelectionCode('pl'), const Locale('pl'));
      });

      test('maps en to English Locale', () {
        expect(LocaleConstants.fromSelectionCode('en'), const Locale('en'));
      });

      test('maps unrecognized code to null', () {
        expect(LocaleConstants.fromSelectionCode('unknown'), isNull);
      });
    });
  });
}
