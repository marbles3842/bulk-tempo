import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/platform/presentation_capabilities.dart';
import 'package:bulk_tempo/core/theme/app_icons.dart';
import 'package:bulk_tempo/core/widgets/app_feedback.dart';

import '../../test_helpers/pump_app.dart';

void main() {
  const materialCaps = PresentationCapabilities(
    targetPlatform: TargetPlatform.android,
  );

  const cupertinoLiquidGlassCaps = PresentationCapabilities(
    targetPlatform: TargetPlatform.iOS,
    iosMajorVersion: 26,
    supportsNativeIosViews: true,
    reduceTransparency: false,
  );

  group('AppFeedbackBanner', () {
    testWidgets('renders all tones with correct fallback icons', (
      tester,
    ) async {
      await tester.pumpApp(
        const Column(
          children: [
            AppFeedbackBanner(
              message: 'Success Message',
              tone: AppFeedbackTone.success,
            ),
            AppFeedbackBanner(
              message: 'Warning Message',
              tone: AppFeedbackTone.warning,
            ),
            AppFeedbackBanner(
              message: 'Info Message',
              tone: AppFeedbackTone.info,
            ),
            AppFeedbackBanner(
              message: 'Error Message',
              tone: AppFeedbackTone.error,
            ),
            AppFeedbackBanner(
              message: 'Achievement Message',
              tone: AppFeedbackTone.achievement,
            ),
          ],
        ),
        capabilities: materialCaps,
      );

      expect(find.text('Success Message'), findsOneWidget);
      expect(find.text('Warning Message'), findsOneWidget);
      expect(find.text('Info Message'), findsOneWidget);
      expect(find.text('Error Message'), findsOneWidget);
      expect(find.text('Achievement Message'), findsOneWidget);

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
    });

    testWidgets('triggers onAction callback when action button is tapped', (
      tester,
    ) async {
      var actionTriggered = false;
      await tester.pumpApp(
        AppFeedbackBanner(
          bannerKey: const ValueKey('retry_banner'),
          message: 'Failed to sync with Hevy',
          tone: AppFeedbackTone.error,
          actionLabel: 'Retry',
          actionKey: const ValueKey('retry_button'),
          onAction: () => actionTriggered = true,
        ),
        capabilities: materialCaps,
      );

      expect(find.byKey(const ValueKey('retry_banner')), findsOneWidget);
      expect(find.byKey(const ValueKey('retry_button')), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('retry_button')));
      await tester.pump();
      expect(actionTriggered, isTrue);
    });

    testWidgets('renders custom icon override', (tester) async {
      await tester.pumpApp(
        const AppFeedbackBanner(
          message: 'Target Achieved',
          tone: AppFeedbackTone.success,
          icon: AppIcon.target,
        ),
        capabilities: materialCaps,
      );

      expect(find.byIcon(Icons.track_changes), findsOneWidget);
    });

    testWidgets('renders in dark mode without error', (tester) async {
      await tester.pumpApp(
        const AppFeedbackBanner(
          message: 'Dark Banner',
          tone: AppFeedbackTone.warning,
        ),
        capabilities: materialCaps,
        themeMode: ThemeMode.dark,
      );

      expect(find.text('Dark Banner'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('AppStatusBadge', () {
    testWidgets('renders label and tone styling', (tester) async {
      await tester.pumpApp(
        const Column(
          children: [
            AppStatusBadge(
              badgeKey: ValueKey('badge_info'),
              label: 'Active',
              tone: AppFeedbackTone.info,
            ),
            AppStatusBadge(
              badgeKey: ValueKey('badge_pr'),
              label: 'PR Best Set',
              tone: AppFeedbackTone.achievement,
              icon: AppIcon.achievement,
            ),
          ],
        ),
        capabilities: materialCaps,
      );

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('PR Best Set'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
    });

    testWidgets('supports direct iconData override', (tester) async {
      await tester.pumpApp(
        const AppStatusBadge(label: 'Custom Icon', iconData: Icons.bolt),
        capabilities: materialCaps,
      );

      expect(find.text('Custom Icon'), findsOneWidget);
      expect(find.byIcon(Icons.bolt), findsOneWidget);
    });
  });

  group('AppFeedback.showSnackBar', () {
    testWidgets('shows themed SnackBar on Material scaffold', (tester) async {
      var actionFired = false;
      await tester.pumpApp(
        Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                AppFeedback.showSnackBar(
                  context,
                  snackBarKey: const ValueKey('test_snackbar'),
                  message: 'Weight entry saved',
                  tone: AppFeedbackTone.success,
                  actionLabel: 'Undo',
                  actionKey: const ValueKey('undo_action'),
                  onAction: () => actionFired = true,
                );
              },
              child: const Text('Show SnackBar'),
            ),
          ),
        ),
        capabilities: materialCaps,
      );

      await tester.tap(find.text('Show SnackBar'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('test_snackbar')), findsOneWidget);
      expect(find.text('Weight entry saved'), findsOneWidget);
      expect(find.byKey(const ValueKey('undo_action')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('undo_action')));
      await tester.pump();
      expect(actionFired, isTrue);
    });

    testWidgets(
      'delegates to AdaptiveSnackBar on Liquid Glass without custom key',
      (tester) async {
        await tester.pumpApp(
          Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppFeedback.showSnackBar(
                    context,
                    message: 'Liquid Glass Alert',
                    tone: AppFeedbackTone.warning,
                  );
                },
                child: const Text('Show Liquid SnackBar'),
              ),
            ),
          ),
          capabilities: cupertinoLiquidGlassCaps,
        );

        await tester.tap(find.text('Show Liquid SnackBar'));
        await tester.pumpAndSettle();

        expect(find.text('Liquid Glass Alert'), findsOneWidget);
      },
    );
  });
}
