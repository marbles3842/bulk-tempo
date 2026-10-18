import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bulk_tempo/core/platform/presentation_capabilities.dart';

/// Configuration for an action button in an [AppDialog].
class AppDialogAction {
  const AppDialogAction({
    required this.label,
    this.key,
    this.isDestructive = false,
    this.isDefaultAction = false,
    this.onPressed,
    this.resultValue,
  });

  /// The button label text.
  final String label;

  /// Optional [Key] assigned to the underlying button widget.
  final Key? key;

  /// True when this action performs a destructive/irreversible operation.
  final bool isDestructive;

  /// True when this action is the default affirmative action (e.g. bolded in Cupertino).
  final bool isDefaultAction;

  /// Callback executed when the button is pressed.
  final VoidCallback? onPressed;

  /// The value returned when the dialog is dismissed via this action.
  final Object? resultValue;
}

/// Unified platform-adaptive alert and confirmation dialog presenter.
///
/// Dispatches to:
/// - Material 3 [AlertDialog] on Android and web.
/// - Classic [CupertinoAlertDialog] on iOS 15–25 (and widget tests without native views).
/// - [AdaptiveAlertDialog.show] on iOS 26+ Liquid Glass.
abstract final class AppDialog {
  /// Presents a platform-adaptive confirmation or destructive alert dialog.
  ///
  /// Returns [confirmResult] when the confirm action is pressed, [cancelResult]
  /// when the cancel action is pressed, or `null` if the dialog is dismissed
  /// via barrier tap (where supported).
  static Future<T?> showConfirm<T>(
    BuildContext context, {
    Key? dialogKey,
    required String title,
    required String message,
    required String cancelLabel,
    Key? cancelButtonKey,
    VoidCallback? onCancel,
    required String confirmLabel,
    Key? confirmButtonKey,
    VoidCallback? onConfirm,
    bool isDestructive = false,
    T? cancelResult,
    T? confirmResult,
  }) async {
    final capabilities = PresentationCapabilities.resolve(context);

    switch (capabilities.platformMode) {
      case AdaptivePlatformMode.cupertinoLiquidGlass:
        T? selectedResult;
        await AdaptiveAlertDialog.show(
          context: context,
          title: title,
          message: message,
          actions: [
            AlertAction(
              title: cancelLabel,
              style: AlertActionStyle.cancel,
              onPressed: () {
                selectedResult = cancelResult;
                onCancel?.call();
              },
            ),
            AlertAction(
              title: confirmLabel,
              style: isDestructive
                  ? AlertActionStyle.destructive
                  : AlertActionStyle.primary,
              onPressed: () {
                selectedResult = confirmResult;
                onConfirm?.call();
              },
            ),
          ],
        );
        return selectedResult;

      case AdaptivePlatformMode.cupertinoClassic:
        return showCupertinoDialog<T>(
          context: context,
          builder: (dialogContext) {
            return CupertinoAlertDialog(
              key: dialogKey,
              title: Text(title),
              content: Text(message),
              actions: [
                CupertinoDialogAction(
                  key: cancelButtonKey,
                  onPressed: () {
                    Navigator.of(dialogContext).pop(cancelResult);
                    onCancel?.call();
                  },
                  child: Text(cancelLabel),
                ),
                CupertinoDialogAction(
                  key: confirmButtonKey,
                  isDestructiveAction: isDestructive,
                  isDefaultAction: !isDestructive,
                  onPressed: () {
                    Navigator.of(dialogContext).pop(confirmResult);
                    onConfirm?.call();
                  },
                  child: Text(confirmLabel),
                ),
              ],
            );
          },
        );

      case AdaptivePlatformMode.material:
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return showDialog<T>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              key: dialogKey,
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                  key: cancelButtonKey,
                  onPressed: () {
                    Navigator.of(dialogContext).pop(cancelResult);
                    onCancel?.call();
                  },
                  child: Text(cancelLabel),
                ),
                FilledButton(
                  key: confirmButtonKey,
                  style: isDestructive
                      ? FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                        )
                      : null,
                  onPressed: () {
                    Navigator.of(dialogContext).pop(confirmResult);
                    onConfirm?.call();
                  },
                  child: Text(confirmLabel),
                ),
              ],
            );
          },
        );
    }
  }
}
