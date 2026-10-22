import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/design_system.dart';
import 'package:bulk_tempo/features/auth/presentation/widgets/auth_text_field.dart';

import '../../../../test_helpers/pump_app.dart';

void main() {
  testWidgets(
    'renders label, hint, errorText and forwards fieldKey on Material',
    (tester) async {
      await tester.pumpApp(
        const AuthTextField(
          fieldKey: Key('test_field_key'),
          label: 'Email Address',
          hint: 'user@example.com',
          errorText: 'Invalid email',
        ),
      );

      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('user@example.com'), findsOneWidget);
      expect(find.text('Invalid email'), findsOneWidget);
      expect(find.byKey(const Key('test_field_key')), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    },
  );

  testWidgets(
    'forwards fieldKey and renders CupertinoTextField on cupertinoClassic',
    (tester) async {
      await tester.pumpApp(
        const AuthTextField(
          fieldKey: Key('test_field_key'),
          label: 'Email Address',
          hint: 'user@example.com',
        ),
        capabilities: const PresentationCapabilities(
          targetPlatform: TargetPlatform.iOS,
        ),
      );

      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('user@example.com'), findsOneWidget);
      expect(find.byKey(const Key('test_field_key')), findsOneWidget);
      expect(find.byType(CupertinoTextField), findsOneWidget);
    },
  );

  testWidgets(
    'renders Material IconButton with tooltip and taps trigger onToggleObscureText',
    (tester) async {
      var toggled = false;
      await tester.pumpApp(
        AuthTextField(
          label: 'Password',
          obscureText: true,
          toggleObscureTooltip: 'Show password',
          onToggleObscureText: () => toggled = true,
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byTooltip('Show password'), findsOneWidget);

      await tester.tap(find.byTooltip('Show password'));
      await tester.pumpAndSettle();

      expect(toggled, isTrue);
    },
  );

  testWidgets(
    'renders CupertinoButton with Tooltip and taps trigger onToggleObscureText on cupertinoClassic',
    (tester) async {
      var toggled = false;
      await tester.pumpApp(
        AuthTextField(
          label: 'Password',
          obscureText: true,
          toggleObscureTooltip: 'Show password',
          onToggleObscureText: () => toggled = true,
        ),
        capabilities: const PresentationCapabilities(
          targetPlatform: TargetPlatform.iOS,
        ),
      );

      expect(find.byType(CupertinoButton), findsOneWidget);
      expect(find.byTooltip('Show password'), findsOneWidget);

      await tester.tap(find.byTooltip('Show password'));
      await tester.pumpAndSettle();

      expect(toggled, isTrue);
    },
  );

  testWidgets('disables toggle button and field when enabled is false', (
    tester,
  ) async {
    var toggled = false;
    await tester.pumpApp(
      AuthTextField(
        fieldKey: const Key('disabled_field'),
        label: 'Password',
        enabled: false,
        obscureText: true,
        toggleObscureTooltip: 'Show password',
        onToggleObscureText: () => toggled = true,
      ),
    );

    final textField = tester.widget<TextField>(
      find.byKey(const Key('disabled_field')),
    );
    expect(textField.enabled, isFalse);

    await tester.tap(find.byTooltip('Show password'), warnIfMissed: false);
    await tester.pump();

    expect(toggled, isFalse);
  });

  testWidgets(
    'renders custom suffixIcon when provided instead of toggle button',
    (tester) async {
      await tester.pumpApp(
        const AuthTextField(
          label: 'Search',
          suffixIcon: Icon(Icons.clear, key: Key('custom_suffix')),
        ),
      );

      expect(find.byKey(const Key('custom_suffix')), findsOneWidget);
      expect(find.byType(IconButton), findsNothing);
    },
  );
}
