import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/theme/app_spacing.dart';
import 'package:bulk_tempo/core/widgets/app_sheet_frame.dart';

import '../../test_helpers/pump_app.dart';

void main() {
  group('AppSheetFrame - Header and Structure', () {
    testWidgets('renders title, subtitle, summaryText, and child content', (
      tester,
    ) async {
      await tester.pumpApp(
        const Scaffold(
          body: AppSheetFrame(
            sheetKey: Key('test_sheet'),
            title: 'Sheet Title',
            subtitle: 'Sheet Subtitle',
            summaryText: 'Summary info',
            child: Text('Sheet Body Content'),
          ),
        ),
      );

      expect(find.byKey(const Key('test_sheet')), findsOneWidget);
      expect(find.text('Sheet Title'), findsOneWidget);
      expect(find.text('Sheet Subtitle'), findsOneWidget);
      expect(find.text('Summary info'), findsOneWidget);
      expect(find.text('Sheet Body Content'), findsOneWidget);
    });

    testWidgets('renders close button with custom key and tooltip', (
      tester,
    ) async {
      const closeKey = Key('custom_close_button');
      await tester.pumpApp(
        const Scaffold(
          body: AppSheetFrame(
            title: 'Close Test',
            closeButtonKey: closeKey,
            closeTooltip: 'Dismiss Sheet',
            child: SizedBox(),
          ),
        ),
      );

      expect(find.byKey(closeKey), findsOneWidget);
      final iconButton = tester.widget<IconButton>(find.byKey(closeKey));
      expect(iconButton.tooltip, 'Dismiss Sheet');
    });
  });

  group('AppSheetFrame - Dismissal Guards and Callbacks', () {
    testWidgets(
      'triggers onDismissRequested and blocks dismissal when canPop is false',
      (tester) async {
        var dismissRequestedCount = 0;
        const closeKey = Key('close_button');

        await tester.pumpApp(
          Scaffold(
            body: AppSheetFrame(
              title: 'Guarded Sheet',
              closeButtonKey: closeKey,
              canPop: false,
              onDismissRequested: () => dismissRequestedCount++,
              child: const SizedBox(height: 100),
            ),
          ),
        );

        // Tap close button
        await tester.tap(find.byKey(closeKey));
        await tester.pump();
        expect(dismissRequestedCount, 1);

        // System back attempt via popRoute
        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(dismissRequestedCount, 2);
      },
    );

    testWidgets(
      'triggers onDismissRequested on vertical drag downward (>100px)',
      (tester) async {
        var dismissRequestedCount = 0;
        const sheetKey = Key('drag_sheet');

        await tester.pumpApp(
          Scaffold(
            body: AppSheetFrame(
              sheetKey: sheetKey,
              title: 'Swipe Down',
              canPop: false,
              onDismissRequested: () => dismissRequestedCount++,
              child: const SizedBox(height: 200),
            ),
          ),
        );

        // Perform downward swipe > 100px
        await tester.drag(find.byKey(sheetKey), const Offset(0, 150));
        await tester.pump();

        expect(dismissRequestedCount, 1);
      },
    );

    testWidgets(
      'triggers onDismissRequested on downward drag with velocity (>250)',
      (tester) async {
        var dismissRequestedCount = 0;
        const sheetKey = Key('fling_sheet');

        await tester.pumpApp(
          Scaffold(
            body: AppSheetFrame(
              sheetKey: sheetKey,
              title: 'Fling Sheet',
              canPop: false,
              onDismissRequested: () => dismissRequestedCount++,
              child: const SizedBox(height: 200),
            ),
          ),
        );

        // Fling downwards
        await tester.fling(find.byKey(sheetKey), const Offset(0, 50), 800.0);
        await tester.pump();

        expect(dismissRequestedCount, 1);
      },
    );

    testWidgets(
      'blocks dismissal and disables close button when isBusy is true',
      (tester) async {
        var dismissRequestedCount = 0;
        const closeKey = Key('busy_close_btn');
        const sheetKey = Key('busy_sheet');

        await tester.pumpApp(
          Scaffold(
            body: AppSheetFrame(
              sheetKey: sheetKey,
              title: 'Busy Sheet',
              closeButtonKey: closeKey,
              isBusy: true,
              canPop: false,
              onDismissRequested: () => dismissRequestedCount++,
              child: const SizedBox(height: 200),
            ),
          ),
        );

        final closeButton = tester.widget<IconButton>(find.byKey(closeKey));
        expect(closeButton.onPressed, isNull);

        // Attempt vertical drag
        await tester.drag(find.byKey(sheetKey), const Offset(0, 200));
        await tester.pump();

        // Attempt system back
        await tester.binding.handlePopRoute();
        await tester.pump();

        expect(dismissRequestedCount, 0);
      },
    );
  });

  group('AppSheetFrame - Keyboard Clearance & Draggable Mode', () {
    testWidgets('pads bottom inset dynamically for keyboard clearance', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: 250.0);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      const sheetKey = Key('keyboard_sheet');

      await tester.pumpApp(
        const AppSheetFrame(
          sheetKey: sheetKey,
          title: 'Keyboard Test',
          child: Text('Inputs here'),
        ),
      );

      final container = tester.widget<Container>(find.byKey(sheetKey));
      final padding = container.padding as EdgeInsets;

      expect(padding.bottom, 250.0 + AppSpacing.sheetInset);
      expect(padding.top, AppSpacing.sheetInset);
      expect(padding.left, AppSpacing.sheetInset);
      expect(padding.right, AppSpacing.sheetInset);
    });

    testWidgets('renders DraggableScrollableSheet when isDraggable is true', (
      tester,
    ) async {
      await tester.pumpApp(
        Scaffold(
          body: AppSheetFrame(
            title: 'Draggable Sheet',
            isDraggable: true,
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.85,
            scrollableBuilder: (context, controller) {
              return ListView.builder(
                controller: controller,
                itemCount: 20,
                itemBuilder: (context, index) => Text('Item $index'),
              );
            },
          ),
        ),
      );

      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      final draggable = tester.widget<DraggableScrollableSheet>(
        find.byType(DraggableScrollableSheet),
      );
      expect(draggable.initialChildSize, 0.6);
      expect(draggable.minChildSize, 0.3);
      expect(draggable.maxChildSize, 0.85);
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('AppSheetFrame.show presents modal bottom sheet', (
      tester,
    ) async {
      await tester.pumpApp(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                AppSheetFrame.show<void>(
                  context,
                  builder: (sheetContext) {
                    return const AppSheetFrame(
                      title: 'Presented Sheet',
                      child: Text('Inside Modal'),
                    );
                  },
                );
              },
              child: const Text('Show Sheet'),
            );
          },
        ),
      );

      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Presented Sheet'), findsOneWidget);
      expect(find.text('Inside Modal'), findsOneWidget);
    });
  });
}
