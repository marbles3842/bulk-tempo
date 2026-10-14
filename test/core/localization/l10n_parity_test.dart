import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('L10n Translation Parity', () {
    test('app_en.arb and app_pl.arb contain the exact same translation keys', () {
      final enFile = File('lib/l10n/app_en.arb');
      final plFile = File('lib/l10n/app_pl.arb');

      expect(enFile.existsSync(), isTrue, reason: 'app_en.arb must exist');
      expect(plFile.existsSync(), isTrue, reason: 'app_pl.arb must exist');

      final enJson =
          json.decode(enFile.readAsStringSync()) as Map<String, dynamic>;
      final plJson =
          json.decode(plFile.readAsStringSync()) as Map<String, dynamic>;

      // Filter out metadata entries (keys starting with '@')
      final enKeys = enJson.keys.where((k) => !k.startsWith('@')).toSet();
      final plKeys = plJson.keys.where((k) => !k.startsWith('@')).toSet();

      final missingInPl = enKeys.difference(plKeys);
      final missingInEn = plKeys.difference(enKeys);

      expect(
        missingInPl,
        isEmpty,
        reason:
            'Keys present in app_en.arb but missing in app_pl.arb: $missingInPl',
      );
      expect(
        missingInEn,
        isEmpty,
        reason:
            'Keys present in app_pl.arb but missing in app_en.arb: $missingInEn',
      );
      expect(enKeys, equals(plKeys));
    });
  });
}
