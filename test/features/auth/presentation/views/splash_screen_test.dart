import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/features/auth/presentation/views/splash_screen.dart';

import '../../../../test_helpers/pump_app.dart';

void main() {
  testWidgets('renders Bulk Tempo title, icon, and progress indicator', (
    tester,
  ) async {
    await tester.pumpApp(const SplashScreen());

    expect(find.text('Bulk Tempo'), findsOneWidget);
    expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
