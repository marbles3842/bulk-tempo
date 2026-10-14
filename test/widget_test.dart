import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bulk_tempo/core/localization/locale_notifier.dart';
import 'package:bulk_tempo/core/localization/locale_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/app/app.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/presentation/views/login_screen.dart';

import 'test_helpers/fakes/fake_auth_repository.dart';
import 'test_helpers/mocks.dart';

void main() {
  testWidgets(
    'System follows device changes and differs from explicit English',
    (tester) async {
      tester.binding.platformDispatcher.localesTestValue = [const Locale('pl')];
      addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
      final storage = MockFlutterSecureStorage();
      when(
        () => storage.read(key: LocaleNotifier.storageKey),
      ).thenAnswer((_) async => null);
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => storage.delete(key: LocaleNotifier.storageKey),
      ).thenAnswer((_) async {});
      final repository = FakeAuthRepository();
      addTearDown(repository.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repository),
            secureStorageProvider.overrideWithValue(storage),
          ],
          child: const BulkTempoApp(),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(BulkTempoApp)),
      );
      final notifier = container.read(localeProvider.notifier);
      expect(container.read(localeProvider), isNull);
      expect(find.text('Witaj ponownie'), findsOneWidget);

      await notifier.setLocale(const Locale('en'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome Back'), findsOneWidget);

      await notifier.setLocale(null);
      await tester.pumpAndSettle();
      expect(find.text('Witaj ponownie'), findsOneWidget);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
        isNull,
      );

      tester.binding.platformDispatcher.localesTestValue = [const Locale('en')];
      await tester.pumpAndSettle();
      expect(find.text('Welcome Back'), findsOneWidget);
    },
  );

  testWidgets(
    'BulkTempoApp mounts and navigates to LoginScreen when unauthenticated',
    (WidgetTester tester) async {
      final fakeAuthRepository = FakeAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
          ],
          child: const BulkTempoApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);

      fakeAuthRepository.dispose();
    },
  );
}
