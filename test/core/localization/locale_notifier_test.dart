import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bulk_tempo/core/localization/locale_notifier.dart';
import 'package:bulk_tempo/core/localization/locale_provider.dart';
import 'package:bulk_tempo/l10n/app_localizations.dart';

import '../../test_helpers/mocks.dart';

void main() {
  late MockFlutterSecureStorage mockSecureStorage;

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
  });

  ProviderContainer createContainer({
    String? initialStoredLocale,
    Exception? readException,
  }) {
    if (readException != null) {
      when(
        () => mockSecureStorage.read(key: LocaleNotifier.storageKey),
      ).thenThrow(readException);
    } else {
      when(
        () => mockSecureStorage.read(key: LocaleNotifier.storageKey),
      ).thenAnswer((_) async => initialStoredLocale);
    }

    when(
      () => mockSecureStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockSecureStorage.delete(key: any(named: 'key')),
    ).thenAnswer((_) async {});

    return ProviderContainer(
      overrides: [secureStorageProvider.overrideWithValue(mockSecureStorage)],
    );
  }

  group('LocaleNotifier', () {
    test('initial state follows System when no locale is stored', () async {
      final container = createContainer(initialStoredLocale: null);
      addTearDown(container.dispose);

      final notifier = container.read(localeProvider.notifier);
      expect(container.read(localeProvider), isNull);
      await notifier.loadPersistedLocale();

      expect(container.read(localeProvider), isNull);
      verify(
        () => mockSecureStorage.read(key: LocaleNotifier.storageKey),
      ).called(greaterThanOrEqualTo(1));
    });

    test('empty storage follows System', () async {
      final container = createContainer(initialStoredLocale: '');
      addTearDown(container.dispose);

      await container.read(localeProvider.notifier).loadPersistedLocale();

      expect(container.read(localeProvider), isNull);
    });

    test('stored English remains an explicit override', () async {
      final container = createContainer(initialStoredLocale: 'en');
      addTearDown(container.dispose);

      await container.read(localeProvider.notifier).loadPersistedLocale();

      expect(container.read(localeProvider), const Locale('en'));
    });

    test('selecting System clears the stored override', () async {
      final container = createContainer(initialStoredLocale: 'en');
      addTearDown(container.dispose);
      final notifier = container.read(localeProvider.notifier);
      await notifier.loadPersistedLocale();

      final update = notifier.setLocale(null);
      expect(container.read(localeProvider), isNull);
      await update;

      verify(
        () => mockSecureStorage.delete(key: LocaleNotifier.storageKey),
      ).called(1);
      await notifier.setLocale(const Locale('en'));
      expect(container.read(localeProvider), const Locale('en'));
    });

    test(
      'a delayed storage read cannot replace a manual selection or System',
      () async {
        final container = createContainer();
        addTearDown(container.dispose);
        final storedLocale = Completer<String?>();
        when(
          () => mockSecureStorage.read(key: LocaleNotifier.storageKey),
        ).thenAnswer((_) => storedLocale.future);
        final notifier = container.read(localeProvider.notifier);
        final load = notifier.loadPersistedLocale();

        await notifier.setLocale(const Locale('en'));
        await notifier.setLocale(null);
        storedLocale.complete('pl');
        await load;

        expect(container.read(localeProvider), isNull);
      },
    );

    test(
      'concurrent selections persist in order while state updates immediately',
      () async {
        final container = createContainer();
        addTearDown(container.dispose);
        final notifier = container.read(localeProvider.notifier);
        await notifier.loadPersistedLocale();
        final firstWrite = Completer<void>();
        final firstWriteStarted = Completer<void>();
        final operations = <String>[];
        String? persistedLocale;
        when(
          () => mockSecureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((invocation) async {
          final value = invocation.namedArguments[#value] as String;
          operations.add(value);
          if (value == 'pl') {
            firstWriteStarted.complete();
            await firstWrite.future;
          }
          persistedLocale = value;
        });
        when(
          () => mockSecureStorage.delete(key: LocaleNotifier.storageKey),
        ).thenAnswer((_) async {
          operations.add('system');
          persistedLocale = null;
        });

        final polish = notifier.setLocale(const Locale('pl'));
        await firstWriteStarted.future;
        final system = notifier.setLocale(null);
        expect(container.read(localeProvider), isNull);
        final english = notifier.setLocale(const Locale('en'));
        expect(container.read(localeProvider), const Locale('en'));
        expect(operations, ['pl']);

        firstWrite.complete();
        await Future.wait([polish, system, english]);

        expect(operations, ['pl', 'system', 'en']);
        expect(persistedLocale, 'en');
      },
    );

    test('a failed write does not block later queued selections', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      final notifier = container.read(localeProvider.notifier);
      when(
        () => mockSecureStorage.write(
          key: LocaleNotifier.storageKey,
          value: 'pl',
        ),
      ).thenThrow(Exception('Write failed'));

      final polish = notifier.setLocale(const Locale('pl'));
      final english = notifier.setLocale(const Locale('en'));
      await Future.wait([polish, english]);

      expect(container.read(localeProvider), const Locale('en'));
      verify(
        () => mockSecureStorage.write(
          key: LocaleNotifier.storageKey,
          value: 'en',
        ),
      ).called(1);
    });

    test('initial state reads persisted locale when code is stored', () async {
      final container = createContainer(initialStoredLocale: 'pl');
      addTearDown(container.dispose);

      final notifier = container.read(localeProvider.notifier);
      await notifier.loadPersistedLocale();

      expect(container.read(localeProvider), const Locale('pl'));
    });

    test('initial state parses persisted locale with country code', () async {
      final container = createContainer(initialStoredLocale: 'en_GB');
      addTearDown(container.dispose);

      final notifier = container.read(localeProvider.notifier);
      await notifier.loadPersistedLocale();

      expect(container.read(localeProvider), const Locale('en', 'GB'));
    });

    test('handles hyphen-separated locale codes gracefully', () async {
      final container = createContainer(initialStoredLocale: 'en-US');
      addTearDown(container.dispose);

      final notifier = container.read(localeProvider.notifier);
      await notifier.loadPersistedLocale();

      expect(container.read(localeProvider), const Locale('en', 'US'));
    });

    test(
      'gracefully handles exception when reading from secure storage',
      () async {
        final container = createContainer(
          readException: Exception('Secure storage unavailable'),
        );
        addTearDown(container.dispose);

        final notifier = container.read(localeProvider.notifier);
        await notifier.loadPersistedLocale();

        expect(container.read(localeProvider), isNull);
      },
    );

    test(
      'setLocale(Locale("pl")) updates state and persists to storage',
      () async {
        final container = createContainer(initialStoredLocale: null);
        addTearDown(container.dispose);

        await container
            .read(localeProvider.notifier)
            .setLocale(const Locale('pl'));

        expect(container.read(localeProvider), const Locale('pl'));
        verify(
          () => mockSecureStorage.write(
            key: LocaleNotifier.storageKey,
            value: 'pl',
          ),
        ).called(1);
      },
    );

    test(
      'setLocale with country code persists language and country code',
      () async {
        final container = createContainer(initialStoredLocale: null);
        addTearDown(container.dispose);

        await container
            .read(localeProvider.notifier)
            .setLocale(const Locale('en', 'US'));

        expect(container.read(localeProvider), const Locale('en', 'US'));
        verify(
          () => mockSecureStorage.write(
            key: LocaleNotifier.storageKey,
            value: 'en_US',
          ),
        ).called(1);
      },
    );

    test('setLocale survives storage write failure without crashing', () async {
      final container = createContainer(initialStoredLocale: null);
      addTearDown(container.dispose);

      when(
        () => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenThrow(Exception('Write failed'));

      await container
          .read(localeProvider.notifier)
          .setLocale(const Locale('pl'));

      expect(container.read(localeProvider), const Locale('pl'));
    });
  });

  group('BuildContext.l10n extension', () {
    testWidgets('provides AppLocalizations instance', (tester) async {
      late AppLocalizations localizations;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              localizations = context.l10n;
              return Text(localizations.appTitle);
            },
          ),
        ),
      );

      expect(localizations, isNotNull);
      expect(find.text('Bulk Tempo'), findsOneWidget);
    });
  });
}
