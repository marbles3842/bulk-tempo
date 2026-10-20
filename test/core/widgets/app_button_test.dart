import 'dart:ui';

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/platform/presentation_capabilities.dart';
import 'package:bulk_tempo/core/theme/app_icons.dart';
import 'package:bulk_tempo/core/theme/app_spacing.dart';
import 'package:bulk_tempo/core/widgets/app_button.dart';

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

  group('AppButton - Material dispatch', () {
    testWidgets(
      'renders FilledButton for primary variant and responds to tap',
      (tester) async {
        var tapped = false;
        await tester.pumpApp(
          AppButton(
            label: 'Save',
            onPressed: () => tapped = true,
            variant: AppButtonVariant.primary,
          ),
          capabilities: materialCaps,
        );

        expect(find.text('Save'), findsOneWidget);
        expect(find.byType(FilledButton), findsOneWidget);

        await tester.tap(find.text('Save'));
        await tester.pump();
        expect(tapped, isTrue);
      },
    );

    testWidgets('renders OutlinedButton for outlined variant', (tester) async {
      await tester.pumpApp(
        AppButton(
          label: 'Cancel',
          onPressed: () {},
          variant: AppButtonVariant.outlined,
        ),
        capabilities: materialCaps,
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('renders TextButton for text variant', (tester) async {
      await tester.pumpApp(
        AppButton(
          label: 'Skip',
          onPressed: () {},
          variant: AppButtonVariant.text,
        ),
        capabilities: materialCaps,
      );

      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('renders FilledButton.tonal for tonal & secondary variants', (
      tester,
    ) async {
      await tester.pumpApp(
        const Column(
          children: [
            AppButton(label: 'Tonal', variant: AppButtonVariant.tonal),
            AppButton(label: 'Secondary', variant: AppButtonVariant.secondary),
          ],
        ),
        capabilities: materialCaps,
      );

      expect(find.text('Tonal'), findsOneWidget);
      expect(find.text('Secondary'), findsOneWidget);
    });

    testWidgets('does not fire onPressed when disabled', (tester) async {
      var tapped = false;
      await tester.pumpApp(
        AppButton(
          label: 'Disabled',
          isEnabled: false,
          onPressed: () => tapped = true,
        ),
        capabilities: materialCaps,
      );

      await tester.tap(find.text('Disabled'));
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets(
      'shows progress indicator and ignores taps when busy on Material',
      (tester) async {
        var tapped = false;
        await tester.pumpApp(
          AppButton(
            label: 'Busy',
            isBusy: true,
            onPressed: () => tapped = true,
            variant: AppButtonVariant.primary,
          ),
          capabilities: materialCaps,
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.tap(find.byType(AppButton));
        await tester.pump();
        expect(tapped, isFalse);
      },
    );

    testWidgets('renders leading icon alongside label', (tester) async {
      await tester.pumpApp(
        const AppButton(label: 'Add Entry', icon: AppIcon.addMeasurement),
        capabilities: materialCaps,
      );

      expect(find.text('Add Entry'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('respects expand property to fill width', (tester) async {
      await tester.pumpApp(
        const Center(
          child: SizedBox(
            width: 300,
            child: AppButton(label: 'Expand', expand: true),
          ),
        ),
        capabilities: materialCaps,
      );

      final buttonSize = tester.getSize(find.byType(AppButton));
      expect(buttonSize.width, 300.0);
      expect(
        buttonSize.height,
        greaterThanOrEqualTo(AppSpacing.androidMinTapTarget),
      );
    });
  });

  group('AppButton - Cupertino Classic dispatch', () {
    testWidgets('renders CupertinoButton and responds to taps', (tester) async {
      var tapped = false;
      await tester.pumpApp(
        AppButton(
          label: 'Done',
          onPressed: () => tapped = true,
          variant: AppButtonVariant.primary,
        ),
        capabilities: cupertinoClassicCaps,
      );

      expect(find.text('Done'), findsOneWidget);
      expect(find.byType(CupertinoButton), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('shows CupertinoActivityIndicator when busy', (tester) async {
      var tapped = false;
      await tester.pumpApp(
        AppButton(
          label: 'Syncing',
          isBusy: true,
          onPressed: () => tapped = true,
        ),
        capabilities: cupertinoClassicCaps,
      );

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      await tester.tap(find.byType(AppButton));
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets('enforces iOS min tap target (44px)', (tester) async {
      await tester.pumpApp(
        const AppButton(label: 'Touch', variant: AppButtonVariant.primary),
        capabilities: cupertinoClassicCaps,
      );

      final buttonSize = tester.getSize(find.byType(AppButton));
      expect(
        buttonSize.height,
        greaterThanOrEqualTo(AppSpacing.iosMinTapTarget),
      );
      expect(
        buttonSize.width,
        greaterThanOrEqualTo(AppSpacing.iosMinTapTarget),
      );
    });
  });

  group('AppButton - Cupertino Liquid Glass dispatch', () {
    testWidgets('renders AdaptiveButton when active', (tester) async {
      var tapped = false;
      await tester.pumpApp(
        AppButton(
          label: 'Liquid',
          onPressed: () => tapped = true,
          variant: AppButtonVariant.primary,
        ),
        capabilities: cupertinoLiquidGlassCaps,
      );

      expect(find.text('Liquid'), findsOneWidget);
      expect(find.byType(AdaptiveButton), findsOneWidget);

      await tester.tap(find.text('Liquid'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('uses deterministic non-native spinner when busy', (
      tester,
    ) async {
      await tester.pumpApp(
        const AppButton(
          label: 'Liquid Busy',
          isBusy: true,
          variant: AppButtonVariant.primary,
        ),
        capabilities: cupertinoLiquidGlassCaps,
      );

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    });
  });

  group('AppButton - Theme and Semantics', () {
    testWidgets('renders correctly in dark mode', (tester) async {
      await tester.pumpApp(
        const AppButton(
          label: 'Dark Mode',
          variant: AppButtonVariant.destructive,
        ),
        capabilities: materialCaps,
        themeMode: ThemeMode.dark,
      );

      expect(find.text('Dark Mode'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('announces accessible semantics when busy and enabled', (
      tester,
    ) async {
      await tester.pumpApp(
        const AppButton(
          label: 'Submit',
          semanticLabel: 'Submit Weight Entry',
          isBusy: true,
        ),
        capabilities: materialCaps,
      );

      final busySemantics = tester.getSemantics(find.byType(AppButton));
      expect(busySemantics.label, 'Submit Weight Entry');
      expect(busySemantics.flagsCollection.isButton, isTrue);
      expect(busySemantics.flagsCollection.isEnabled, Tristate.isFalse);
      expect(
        busySemantics.getSemanticsData().hasAction(SemanticsAction.tap),
        isFalse,
      );

      await tester.pumpApp(
        AppButton(
          label: 'Submit',
          semanticLabel: 'Submit Weight Entry',
          onPressed: () {},
        ),
        capabilities: materialCaps,
      );

      final enabledSemantics = tester.getSemantics(find.byType(AppButton));
      expect(enabledSemantics.label, 'Submit Weight Entry');
      expect(enabledSemantics.flagsCollection.isButton, isTrue);
      expect(enabledSemantics.flagsCollection.isEnabled, Tristate.isTrue);
      expect(
        enabledSemantics.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
    });
  });
}
