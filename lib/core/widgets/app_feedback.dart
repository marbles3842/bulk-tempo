import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/platform/presentation_capabilities.dart';
import 'package:bulk_tempo/core/theme/app_icons.dart';
import 'package:bulk_tempo/core/theme/app_semantic_colors.dart';
import 'package:bulk_tempo/core/theme/app_shape.dart';
import 'package:bulk_tempo/core/theme/app_spacing.dart';

/// Semantic tone for inline banners, status badges, and snackbars.
enum AppFeedbackTone { success, warning, info, error, achievement }

/// Compact inline feedback banner using paired container/foreground tokens from
/// [AppSemanticColors] and [ColorScheme].
class AppFeedbackBanner extends ConsumerWidget {
  const AppFeedbackBanner({
    super.key,
    this.bannerKey,
    required this.message,
    this.tone = AppFeedbackTone.info,
    this.icon,
    this.actionLabel,
    this.actionKey,
    this.onAction,
  });

  /// Optional [Key] passed directly to the container.
  final Key? bannerKey;

  /// The feedback message to display.
  final String message;

  /// Semantic tone determining paired colors and fallback icon.
  final AppFeedbackTone tone;

  /// Explicit semantic [AppIcon]. If null, resolves default icon for [tone].
  final AppIcon? icon;

  /// Optional label for inline action button (e.g., 'Retry').
  final String? actionLabel;

  /// Optional [Key] assigned to the action button.
  final Key? actionKey;

  /// Optional callback executed when action button is tapped.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final semanticColors = AppSemanticColors.of(context);
    final colors = _resolveFeedbackColors(
      colorScheme: theme.colorScheme,
      semanticColors: semanticColors,
      tone: tone,
    );

    final effectiveIcon = icon ?? _defaultIconForTone(tone);
    final resolvedIcon = AppIcons.resolve(context, effectiveIcon);

    return Container(
      key: bannerKey,
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: colors.container,
        borderRadius: AppShape.smallRadius,
        border: colors.border != null
            ? Border.all(color: colors.border!, width: 1.0)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            resolvedIcon,
            size: AppIcons.compactSize,
            color: colors.onContainer,
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: AppSpacing.space2),
            TextButton(
              key: actionKey,
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: colors.onContainer,
                minimumSize: const Size(
                  AppSpacing.androidMinTapTarget,
                  AppSpacing.androidMinTapTarget,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                ),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact pill/badge component for status chips, count badges, and achievement flags.
class AppStatusBadge extends ConsumerWidget {
  const AppStatusBadge({
    super.key,
    this.badgeKey,
    required this.label,
    this.tone = AppFeedbackTone.info,
    this.icon,
    this.iconData,
  });

  /// Optional [Key] passed directly to the container.
  final Key? badgeKey;

  /// Text label rendered inside the badge.
  final String label;

  /// Semantic tone determining paired container and text colors.
  final AppFeedbackTone tone;

  /// Optional semantic [AppIcon].
  final AppIcon? icon;

  /// Optional direct [IconData] (takes precedence over [icon]).
  final IconData? iconData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final semanticColors = AppSemanticColors.of(context);
    final colors = _resolveFeedbackColors(
      colorScheme: theme.colorScheme,
      semanticColors: semanticColors,
      tone: tone,
    );

    final resolvedIcon =
        iconData ?? (icon != null ? AppIcons.resolve(context, icon!) : null);

    return Container(
      key: badgeKey,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: colors.container,
        borderRadius: AppShape.smallRadius,
        border: colors.border != null
            ? Border.all(color: colors.border!, width: 1.0)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (resolvedIcon != null) ...[
            Icon(resolvedIcon, size: 14, color: colors.onContainer),
            const SizedBox(width: AppSpacing.space1),
          ],
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Feedback presentation helper for transient snackbars.
abstract final class AppFeedback {
  /// Presents a paired-color floating [SnackBar] or native [AdaptiveSnackBar].
  static void showSnackBar(
    BuildContext context, {
    Key? snackBarKey,
    required String message,
    AppFeedbackTone tone = AppFeedbackTone.info,
    String? actionLabel,
    Key? actionKey,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final capabilities = PresentationCapabilities.resolve(context);

    if (capabilities.platformMode ==
            AdaptivePlatformMode.cupertinoLiquidGlass &&
        snackBarKey == null) {
      final AdaptiveSnackBarType adaptiveType;
      switch (tone) {
        case AppFeedbackTone.success:
          adaptiveType = AdaptiveSnackBarType.success;
        case AppFeedbackTone.warning:
          adaptiveType = AdaptiveSnackBarType.warning;
        case AppFeedbackTone.error:
          adaptiveType = AdaptiveSnackBarType.error;
        case AppFeedbackTone.info:
        case AppFeedbackTone.achievement:
          adaptiveType = AdaptiveSnackBarType.info;
      }

      AdaptiveSnackBar.show(
        context,
        message: message,
        type: adaptiveType,
        duration: duration,
        action: actionLabel,
        onActionPressed: onAction,
      );
      return;
    }

    final theme = Theme.of(context);
    final semanticColors = AppSemanticColors.of(context);
    final colors = _resolveFeedbackColors(
      colorScheme: theme.colorScheme,
      semanticColors: semanticColors,
      tone: tone,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: snackBarKey,
        backgroundColor: colors.container,
        duration: duration,
        shape: AppShape.smallBorder,
        behavior: SnackBarBehavior.floating,
        content: Text(
          message,
          style: TextStyle(
            color: colors.onContainer,
            fontWeight: FontWeight.w500,
          ),
        ),
        action: actionLabel != null
            ? SnackBarAction(
                key: actionKey,
                label: actionLabel,
                textColor: colors.onContainer,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }
}

class _FeedbackColors {
  const _FeedbackColors({
    required this.container,
    required this.onContainer,
    this.border,
  });

  final Color container;
  final Color onContainer;
  final Color? border;
}

_FeedbackColors _resolveFeedbackColors({
  required ColorScheme colorScheme,
  required AppSemanticColors semanticColors,
  required AppFeedbackTone tone,
}) {
  switch (tone) {
    case AppFeedbackTone.success:
      return _FeedbackColors(
        container: semanticColors.successContainer,
        onContainer: semanticColors.onSuccessContainer,
      );
    case AppFeedbackTone.warning:
      return _FeedbackColors(
        container: semanticColors.warningContainer,
        onContainer: semanticColors.onWarningContainer,
      );
    case AppFeedbackTone.info:
      return _FeedbackColors(
        container: semanticColors.infoContainer,
        onContainer: semanticColors.onInfoContainer,
      );
    case AppFeedbackTone.error:
      return _FeedbackColors(
        container: colorScheme.errorContainer,
        onContainer: colorScheme.onErrorContainer,
      );
    case AppFeedbackTone.achievement:
      return _FeedbackColors(
        container: semanticColors.achievementContainer,
        onContainer: semanticColors.onAchievementContainer,
        border: semanticColors.achievementBorder,
      );
  }
}

AppIcon _defaultIconForTone(AppFeedbackTone tone) {
  switch (tone) {
    case AppFeedbackTone.success:
      return AppIcon.check;
    case AppFeedbackTone.warning:
      return AppIcon.warning;
    case AppFeedbackTone.info:
      return AppIcon.info;
    case AppFeedbackTone.error:
      return AppIcon.error;
    case AppFeedbackTone.achievement:
      return AppIcon.achievement;
  }
}
