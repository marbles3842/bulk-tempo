import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/platform/presentation_capabilities.dart';
import 'package:bulk_tempo/core/widgets/app_dialog.dart';

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

  group('AppDialog - Material dispatch', () {
    testWidgets('renders AlertDialog with preserved keys, title, and message', (
      tester,
    ) async {
      const dialogKey = Key('test_dialog_key');
      const cancelKey = Key('test_cancel_button_key');
      const confirmKey = Key('test_confirm_button_key');

      await tester.pumpApp(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                AppDialog.showConfirm<bool>(
                  context,
                  dialogKey: dialogKey,
                  title: 'Delete Item?',
                  message: 'This cannot be undone.',
                  cancelLabel: 'Cancel',
                  cancelButtonKey: cancelKey,
                  confirmLabel: 'Delete',
                  confirmButtonKey: confirmKey,
                  isDestructive: true,
                  cancelResult: false,
                  confirmResult: true,
                );
              },
              child: const Text('Open Dialog'),
            );
          },
        ),
        capabilities: materialCaps,
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byKey(dialogKey), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Delete Item?'), findsOneWidget);
      expect(find.text('This cannot be undone.'), findsOneWidget);
      expect(find.byKey(cancelKey), findsOneWidget);
      expect(find.byKey(confirmKey), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('returns confirmResult and invokes onConfirm on confirm tap', (
      tester,
    ) async {
      bool? dialogResult;
      var confirmCalled = false;
      var cancelCalled = false;

      await tester.pumpApp(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                dialogResult = await AppDialog.showConfirm<bool>(
                  context,
                  title: 'Confirm Action',
                  message: 'Are you sure?',
                  cancelLabel: 'No',
                  onCancel: () => cancelCalled = true,
                  confirmLabel: 'Yes',
                  onConfirm: () => confirmCalled = true,
                  cancelResult: false,
                  confirmResult: true,
                );
              },
              child: const Text('Open'),
            );
          },
        ),
        capabilities: materialCaps,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(dialogResult, isTrue);
      expect(confirmCalled, isTrue);
      expect(cancelCalled, isFalse);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('returns cancelResult and invokes onCancel on cancel tap', (
      tester,
    ) async {
      bool? dialogResult;
      var confirmCalled = false;
      var cancelCalled = false;

      await tester.pumpApp(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                dialogResult = await AppDialog.showConfirm<bool>(
                  context,
                  title: 'Confirm Action',
                  message: 'Are you sure?',
                  cancelLabel: 'No',
                  onCancel: () => cancelCalled = true,
                  confirmLabel: 'Yes',
                  onConfirm: () => confirmCalled = true,
                  cancelResult: false,
                  confirmResult: true,
                );
              },
              child: const Text('Open'),
            );
          },
        ),
        capabilities: materialCaps,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();

      expect(dialogResult, isFalse);
      expect(confirmCalled, isFalse);
      expect(cancelCalled, isTrue);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('applies error color styling when isDestructive is true', (
      tester,
    ) async {
      await tester.pumpApp(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                AppDialog.showConfirm<void>(
                  context,
                  title: 'Destructive',
                  message: 'Will be deleted.',
                  cancelLabel: 'Back',
                  confirmLabel: 'Remove',
                  isDestructive: true,
                );
              },
              child: const Text('Open'),
            );
          },
        ),
        capabilities: materialCaps,
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final filledButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Remove'),
      );
      final theme = Theme.of(tester.element(find.byType(AlertDialog)));
      final style = filledButton.style;
      expect(style?.backgroundColor?.resolve({}), theme.colorScheme.error);
      expect(style?.foregroundColor?.resolve({}), theme.colorScheme.onError);
    });
  });

  group('AppDialog - Cupertino Classic dispatch', () {
    testWidgets(
      'renders CupertinoAlertDialog with preserved keys, title, and actions',
      (tester) async {
        const dialogKey = Key('cupe_dialog_key');
        const cancelKey = Key('cupe_cancel_key');
        const confirmKey = Key('cupe_confirm_key');

        await tester.pumpApp(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppDialog.showConfirm<int>(
                    context,
                    dialogKey: dialogKey,
                    title: 'Cupertino Title',
                    message: 'Cupertino Message',
                    cancelLabel: 'Dismiss',
                    cancelButtonKey: cancelKey,
                    confirmLabel: 'Confirm',
                    confirmButtonKey: confirmKey,
                    isDestructive: true,
                    cancelResult: 0,
                    confirmResult: 1,
                  );
                },
                child: const Text('Open Cupertino'),
              );
            },
          ),
          capabilities: cupertinoClassicCaps,
        );

        await tester.tap(find.text('Open Cupertino'));
        await tester.pumpAndSettle();

        expect(find.byKey(dialogKey), findsOneWidget);
        expect(find.byType(CupertinoAlertDialog), findsOneWidget);
        expect(find.text('Cupertino Title'), findsOneWidget);
        expect(find.text('Cupertino Message'), findsOneWidget);
        expect(find.byKey(cancelKey), findsOneWidget);
        expect(find.byKey(confirmKey), findsOneWidget);

        final actions = tester.widgetList<CupertinoDialogAction>(
          find.byType(CupertinoDialogAction),
        );
        expect(actions.length, 2);
        final confirmAction = actions.firstWhere((a) => a.key == confirmKey);
        expect(confirmAction.isDestructiveAction, isTrue);
      },
    );

    testWidgets(
      'returns confirmResult and invokes onConfirm on Cupertino action tap',
      (tester) async {
        int? result;
        var confirmed = false;

        await tester.pumpApp(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await AppDialog.showConfirm<int>(
                    context,
                    title: 'Confirm',
                    message: 'Proceed?',
                    cancelLabel: 'Cancel',
                    confirmLabel: 'Proceed',
                    onConfirm: () => confirmed = true,
                    cancelResult: 0,
                    confirmResult: 42,
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
          capabilities: cupertinoClassicCaps,
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Proceed'));
        await tester.pumpAndSettle();

        expect(result, 42);
        expect(confirmed, isTrue);
        expect(find.byType(CupertinoAlertDialog), findsNothing);
      },
    );
  });

  group('AppDialogAction', () {
    test('instantiates with expected default and specified properties', () {
      const action = AppDialogAction(
        label: 'Delete',
        key: Key('delete_action'),
        isDestructive: true,
        isDefaultAction: false,
        resultValue: 'deleted',
      );

      expect(action.label, 'Delete');
      expect(action.key, const Key('delete_action'));
      expect(action.isDestructive, isTrue);
      expect(action.isDefaultAction, isFalse);
      expect(action.resultValue, 'deleted');
    });
  });
}
