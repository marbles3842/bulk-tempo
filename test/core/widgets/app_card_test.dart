import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/platform/presentation_capabilities.dart';
import 'package:bulk_tempo/core/theme/app_icons.dart';
import 'package:bulk_tempo/core/theme/app_shape.dart';
import 'package:bulk_tempo/core/theme/app_spacing.dart';
import 'package:bulk_tempo/core/widgets/app_card.dart';

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

  group('AppCard - Material dispatch', () {
    testWidgets('renders Card with content and default grouped variant', (
      tester,
    ) async {
      await tester.pumpApp(
        const AppCard(
          cardKey: ValueKey('test_card'),
          child: Text('Card Content'),
        ),
        capabilities: materialCaps,
      );

      expect(find.byKey(const ValueKey('test_card')), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Card Content'), findsOneWidget);

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 0);
      final shape = card.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, AppShape.cardRadius);
    });

    testWidgets(
      'renders full header with title, subtitle, icon, and trailing',
      (tester) async {
        await tester.pumpApp(
          const AppCard(
            title: 'Weight Trend',
            subtitle: 'Last 30 days',
            subtitleKey: ValueKey('card_subtitle'),
            leadingIcon: AppIcon.weight,
            headerTrailing: Icon(Icons.more_vert),
            child: Text('Chart Placeholder'),
          ),
          capabilities: materialCaps,
        );

        expect(find.text('Weight Trend'), findsOneWidget);
        expect(find.byKey(const ValueKey('card_subtitle')), findsOneWidget);
        expect(find.text('Last 30 days'), findsOneWidget);
        expect(find.byIcon(Icons.monitor_weight_outlined), findsOneWidget);
        expect(find.byIcon(Icons.more_vert), findsOneWidget);
        expect(find.text('Chart Placeholder'), findsOneWidget);
      },
    );

    testWidgets('supports variants (grouped, outlined, tinted)', (
      tester,
    ) async {
      await tester.pumpApp(
        const Column(
          children: [
            AppCard(
              cardKey: ValueKey('grouped_card'),
              variant: AppCardVariant.grouped,
              child: Text('Grouped'),
            ),
            AppCard(
              cardKey: ValueKey('outlined_card'),
              variant: AppCardVariant.outlined,
              child: Text('Outlined'),
            ),
            AppCard(
              cardKey: ValueKey('tinted_card'),
              variant: AppCardVariant.tinted,
              child: Text('Tinted'),
            ),
          ],
        ),
        capabilities: materialCaps,
      );

      final groupedCard = tester.widget<Card>(
        find.byKey(const ValueKey('grouped_card')),
      );
      final outlinedCard = tester.widget<Card>(
        find.byKey(const ValueKey('outlined_card')),
      );
      final tintedCard = tester.widget<Card>(
        find.byKey(const ValueKey('tinted_card')),
      );

      expect(groupedCard.color, isNotNull);
      expect(outlinedCard.color, isNotNull);
      expect(tintedCard.color, isNotNull);

      final outlinedShape = outlinedCard.shape as RoundedRectangleBorder;
      expect(outlinedShape.side.style, BorderStyle.solid);
    });

    testWidgets('handles onTap callback with InkWell and Semantics', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpApp(
        AppCard(onTap: () => tapped = true, child: const Text('Tappable Card')),
        capabilities: materialCaps,
      );

      expect(find.byType(InkWell), findsOneWidget);
      await tester.tap(find.text('Tappable Card'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('applies custom padding and margin', (tester) async {
      const customPadding = EdgeInsets.all(AppSpacing.space8);
      const customMargin = EdgeInsets.all(AppSpacing.space4);

      await tester.pumpApp(
        const AppCard(
          padding: customPadding,
          margin: customMargin,
          child: Text('Padded Card'),
        ),
        capabilities: materialCaps,
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.margin, customMargin);

      final paddingWidget = tester.widget<Padding>(
        find
            .ancestor(
              of: find.text('Padded Card'),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(paddingWidget.padding, customPadding);
    });
  });

  group('AppCard - Cupertino Classic dispatch', () {
    testWidgets('renders opaque Container and responds to onTap', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpApp(
        AppCard(
          cardKey: const ValueKey('cupertino_card'),
          title: 'Workout History',
          onTap: () => tapped = true,
          child: const Text('Past Workouts'),
        ),
        capabilities: cupertinoClassicCaps,
      );

      expect(find.byKey(const ValueKey('cupertino_card')), findsOneWidget);
      expect(find.text('Workout History'), findsOneWidget);
      expect(find.byType(GestureDetector), findsWidgets);

      await tester.tap(find.text('Past Workouts'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });

  group('AppCard - Cupertino Liquid Glass dispatch', () {
    testWidgets('maintains opaque non-glass surface on iOS 26+', (
      tester,
    ) async {
      await tester.pumpApp(
        const AppCard(
          cardKey: ValueKey('liquid_card'),
          variant: AppCardVariant.tinted,
          child: Text('Never Glass Data Card'),
        ),
        capabilities: cupertinoLiquidGlassCaps,
      );

      expect(find.byKey(const ValueKey('liquid_card')), findsOneWidget);
      expect(find.text('Never Glass Data Card'), findsOneWidget);

      final container = tester.widget<Container>(
        find.byKey(const ValueKey('liquid_card')),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNotNull);
      expect(decoration.borderRadius, AppShape.cardRadius);
    });
  });

  group('AppCard - Theme variations', () {
    testWidgets('renders correctly in dark mode', (tester) async {
      await tester.pumpApp(
        const AppCard(
          title: 'Dark Card',
          subtitle: 'Subtitle',
          variant: AppCardVariant.grouped,
          child: Text('Dark Content'),
        ),
        capabilities: materialCaps,
        themeMode: ThemeMode.dark,
      );

      expect(find.text('Dark Card'), findsOneWidget);
      expect(find.text('Dark Content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
