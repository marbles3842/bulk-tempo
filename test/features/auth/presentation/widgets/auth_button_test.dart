import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/design_system.dart';
import 'package:bulk_tempo/features/auth/presentation/widgets/auth_button.dart';

import '../../../../test_helpers/pump_app.dart';

void main() {
  testWidgets('renders label and triggers onPressed when tapped', (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpApp(
      AuthButton(text: 'Sign In', onPressed: () => pressed = true),
    );

    expect(find.text('Sign In'), findsOneWidget);
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(pressed, isTrue);
  });

  testWidgets('delegates to AppButton with full width expand', (tester) async {
    await tester.pumpApp(AuthButton(text: 'Full Width', onPressed: () {}));

    final appButton = tester.widget<AppButton>(find.byType(AppButton));
    expect(appButton.label, equals('Full Width'));
    expect(appButton.expand, isTrue);
  });

  testWidgets('renders CircularProgressIndicator when isLoading on Material', (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpApp(
      AuthButton(
        text: 'Submitting',
        isLoading: true,
        onPressed: () => pressed = true,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(AuthButton), warnIfMissed: false);
    await tester.pump();

    expect(pressed, isFalse);
  });

  testWidgets(
    'renders CupertinoActivityIndicator when isLoading on cupertinoClassic',
    (tester) async {
      await tester.pumpApp(
        AuthButton(text: 'Submitting', isLoading: true, onPressed: () {}),
        capabilities: const PresentationCapabilities(
          targetPlatform: TargetPlatform.iOS,
        ),
      );

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    },
  );

  testWidgets('does not trigger onPressed when isEnabled is false', (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpApp(
      AuthButton(
        text: 'Disabled',
        isEnabled: false,
        onPressed: () => pressed = true,
      ),
    );

    await tester.tap(find.text('Disabled'));
    await tester.pumpAndSettle();

    expect(pressed, isFalse);
  });

  testWidgets('forwards variant and icon to AppButton', (tester) async {
    await tester.pumpApp(
      AuthButton(
        text: 'Custom',
        variant: AppButtonVariant.secondary,
        icon: AppIcon.workout,
        onPressed: () {},
      ),
    );

    final appButton = tester.widget<AppButton>(find.byType(AppButton));
    expect(appButton.variant, equals(AppButtonVariant.secondary));
    expect(appButton.icon, equals(AppIcon.workout));
  });
}
