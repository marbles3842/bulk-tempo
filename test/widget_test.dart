import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/app/app.dart';
import 'package:bulk_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bulk_tempo/features/auth/presentation/views/login_screen.dart';

import 'test_helpers/fakes/fake_auth_repository.dart';

void main() {
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
