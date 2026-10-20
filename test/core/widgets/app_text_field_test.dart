import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/platform/presentation_capabilities.dart';
import 'package:bulk_tempo/core/theme/app_icons.dart';
import 'package:bulk_tempo/core/widgets/app_text_field.dart';

import '../../test_helpers/pump_app.dart';

void main() {
  const materialCaps = PresentationCapabilities(
    targetPlatform: TargetPlatform.android,
  );

  const cupertinoClassicCaps = PresentationCapabilities(
    targetPlatform: TargetPlatform.iOS,
    iosMajorVersion: 18,
    supportsNativeIosViews: true,
  );

  const cupertinoLiquidGlassCaps = PresentationCapabilities(
    targetPlatform: TargetPlatform.iOS,
    iosMajorVersion: 26,
    supportsNativeIosViews: true,
    reduceTransparency: false,
  );

  group('AppTextField - Material dispatch', () {
    testWidgets('renders Material TextField with label and hint', (
      tester,
    ) async {
      await tester.pumpApp(
        const AppTextField(label: 'Weight', hint: 'Enter your weight'),
        capabilities: materialCaps,
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('Enter your weight'), findsOneWidget);
    });

    testWidgets('calls onChanged and onSubmitted callbacks', (tester) async {
      var changedValue = '';
      var submittedValue = '';

      await tester.pumpApp(
        AppTextField(
          fieldKey: const ValueKey('weight_field'),
          label: 'Weight',
          onChanged: (val) => changedValue = val,
          onSubmitted: (val) => submittedValue = val,
        ),
        capabilities: materialCaps,
      );

      await tester.enterText(
        find.byKey(const ValueKey('weight_field')),
        '82.5',
      );
      expect(changedValue, '82.5');

      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(submittedValue, '82.5');
    });

    testWidgets('displays helper text and suffix text', (tester) async {
      await tester.pumpApp(
        const AppTextField(
          label: 'Weight',
          helperText: 'Morning weight after waking up',
          suffixText: 'kg',
        ),
        capabilities: materialCaps,
      );

      expect(find.text('Morning weight after waking up'), findsOneWidget);
      expect(find.text('kg'), findsOneWidget);
    });

    testWidgets('renders validation error text and overrides helperText', (
      tester,
    ) async {
      await tester.pumpApp(
        const AppTextField(
          label: 'Weight',
          helperText: 'Helper text',
          errorText: 'Value must be positive',
        ),
        capabilities: materialCaps,
      );

      expect(find.text('Value must be positive'), findsOneWidget);
      expect(find.text('Helper text'), findsNothing);
    });

    testWidgets('renders prefix and suffix icons', (tester) async {
      await tester.pumpApp(
        const AppTextField(
          label: 'Weight',
          prefixIcon: AppIcon.weight,
          suffixIcon: Icon(Icons.clear),
        ),
        capabilities: materialCaps,
      );

      expect(find.byIcon(Icons.monitor_weight_outlined), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('supports obscureText for passwords', (tester) async {
      await tester.pumpApp(
        const AppTextField(
          fieldKey: ValueKey('api_key_field'),
          label: 'API Key',
          obscureText: true,
        ),
        capabilities: materialCaps,
      );

      final textField = tester.widget<TextField>(
        find.byKey(const ValueKey('api_key_field')),
      );
      expect(textField.obscureText, isTrue);
    });

    testWidgets('handles disabled state', (tester) async {
      await tester.pumpApp(
        const AppTextField(
          fieldKey: ValueKey('disabled_field'),
          label: 'Disabled Field',
          enabled: false,
        ),
        capabilities: materialCaps,
      );

      final textField = tester.widget<TextField>(
        find.byKey(const ValueKey('disabled_field')),
      );
      expect(textField.enabled, isFalse);
    });
  });

  group('AppTextField - Cupertino Classic dispatch', () {
    testWidgets('renders CupertinoTextField with label and placeholder', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpApp(
          const AppTextField(label: 'Rate of Gain', hint: 'e.g. 0.25'),
          capabilities: cupertinoClassicCaps,
        );

        expect(find.byType(CupertinoTextField), findsOneWidget);
        expect(find.text('Rate of Gain'), findsOneWidget);
        expect(find.text('e.g. 0.25'), findsOneWidget);
        expect(find.bySemanticsLabel('Rate of Gain'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('displays suffixText and helperText', (tester) async {
      await tester.pumpApp(
        const AppTextField(
          label: 'Pace',
          helperText: 'Recommended: 0.25 - 0.5 kg/wk',
          suffixText: 'kg/wk',
        ),
        capabilities: cupertinoClassicCaps,
      );

      expect(find.text('Recommended: 0.25 - 0.5 kg/wk'), findsOneWidget);
      expect(find.text('kg/wk'), findsOneWidget);
    });

    testWidgets('displays errorText row with error icon', (tester) async {
      await tester.pumpApp(
        const AppTextField(
          label: 'Target',
          errorText: 'Target must be greater than starting weight',
        ),
        capabilities: cupertinoClassicCaps,
      );

      expect(
        find.text('Target must be greater than starting weight'),
        findsOneWidget,
      );
      expect(
        find.byIcon(CupertinoIcons.exclamationmark_circle),
        findsOneWidget,
      );
    });

    testWidgets('accepts text input on Cupertino', (tester) async {
      var entered = '';
      await tester.pumpApp(
        AppTextField(
          fieldKey: const ValueKey('ios_field'),
          label: 'Notes',
          onChanged: (val) => entered = val,
        ),
        capabilities: cupertinoClassicCaps,
      );

      await tester.enterText(
        find.byKey(const ValueKey('ios_field')),
        'Leg day went well',
      );
      expect(entered, 'Leg day went well');
    });
  });

  group('AppTextField - Cupertino Liquid Glass dispatch', () {
    testWidgets('renders labeled CupertinoTextField when active', (
      tester,
    ) async {
      await tester.pumpApp(
        const AppTextField(
          label: 'Liquid Field',
          hint: 'Type here',
          suffixText: 'reps',
        ),
        capabilities: cupertinoLiquidGlassCaps,
      );

      expect(find.byType(CupertinoTextField), findsOneWidget);
      expect(find.text('Liquid Field'), findsOneWidget);
      expect(find.text('reps'), findsOneWidget);
    });
  });

  group('AppTextField - Theme and Controller', () {
    testWidgets('renders in dark mode cleanly', (tester) async {
      await tester.pumpApp(
        const AppTextField(
          label: 'Dark Mode Field',
          hint: 'Hint',
          helperText: 'Helper',
        ),
        capabilities: materialCaps,
        themeMode: ThemeMode.dark,
      );

      expect(find.text('Dark Mode Field'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('syncs with external TextEditingController', (tester) async {
      final controller = TextEditingController(text: 'Initial');
      addTearDown(controller.dispose);

      await tester.pumpApp(
        AppTextField(controller: controller, label: 'Controller Field'),
        capabilities: materialCaps,
      );

      expect(find.text('Initial'), findsOneWidget);
      controller.text = 'Updated';
      await tester.pump();
      expect(find.text('Updated'), findsOneWidget);
    });
  });
}
