import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/platform/presentation_capabilities.dart';
import 'package:bulk_tempo/core/theme/app_icons.dart';
import 'package:bulk_tempo/core/theme/app_shape.dart';
import 'package:bulk_tempo/core/theme/app_spacing.dart';

/// Visual style variants for [AppButton].
enum AppButtonVariant { primary, secondary, tonal, outlined, text, destructive }

/// Unified button component supporting 3-tier platform dispatch, semantic
/// variants, accessible tap targets, and paired foreground/background busy state.
class AppButton extends ConsumerWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.iconData,
    this.isBusy = false,
    this.isEnabled = true,
    this.expand = false,
    this.semanticLabel,
  });

  /// The text displayed on the button.
  final String label;

  /// Callback when the button is tapped. Ignored when [isEnabled] is false or [isBusy] is true.
  final VoidCallback? onPressed;

  /// Semantic style variant.
  final AppButtonVariant variant;

  /// Semantic [AppIcon] displayed before the label.
  final AppIcon? icon;

  /// Direct [IconData] displayed before the label (takes precedence over [icon]).
  final IconData? iconData;

  /// True when an asynchronous operation is in flight. Disables taps and renders
  /// an activity spinner resolving against the button's paired foreground color.
  final bool isBusy;

  /// Whether the button is interactable.
  final bool isEnabled;

  /// When true, the button expands to fill available horizontal width.
  final bool expand;

  /// Accessibility label override for screen readers.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilities = PresentationCapabilities.resolve(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveOnPressed = (isEnabled && !isBusy) ? onPressed : null;

    final minTapTarget = capabilities.targetPlatform == TargetPlatform.iOS
        ? AppSpacing.iosMinTapTarget
        : AppSpacing.androidMinTapTarget;

    final resolvedIcon =
        iconData ?? (icon != null ? AppIcons.resolve(context, icon!) : null);

    final colors = _resolveColors(colorScheme);

    Widget buttonWidget;
    switch (capabilities.platformMode) {
      case AdaptivePlatformMode.material:
        buttonWidget = _buildMaterialButton(
          context: context,
          capabilities: capabilities,
          colors: colors,
          effectiveOnPressed: effectiveOnPressed,
          minTapTarget: minTapTarget,
          resolvedIcon: resolvedIcon,
        );
      case AdaptivePlatformMode.cupertinoClassic:
        buttonWidget = _buildCupertinoClassicButton(
          context: context,
          colors: colors,
          effectiveOnPressed: effectiveOnPressed,
          minTapTarget: minTapTarget,
          resolvedIcon: resolvedIcon,
        );
      case AdaptivePlatformMode.cupertinoLiquidGlass:
        buttonWidget = _buildCupertinoLiquidGlassButton(
          context: context,
          colors: colors,
          effectiveOnPressed: effectiveOnPressed,
          minTapTarget: minTapTarget,
          resolvedIcon: resolvedIcon,
        );
    }

    return Semantics(
      button: true,
      enabled: isEnabled && !isBusy,
      label: semanticLabel ?? label,
      container: true,
      excludeSemantics: true,
      onTap: effectiveOnPressed,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: expand ? double.infinity : minTapTarget,
          minHeight: minTapTarget,
        ),
        child: buttonWidget,
      ),
    );
  }

  _ButtonColors _resolveColors(ColorScheme scheme) {
    switch (variant) {
      case AppButtonVariant.primary:
        return _ButtonColors(
          background: scheme.primary,
          foreground: scheme.onPrimary,
          disabledBackground: scheme.onSurface.withValues(alpha: 0.12),
          disabledForeground: scheme.onSurface.withValues(alpha: 0.38),
          borderColor: null,
        );
      case AppButtonVariant.secondary:
      case AppButtonVariant.tonal:
        return _ButtonColors(
          background: scheme.secondaryContainer,
          foreground: scheme.onSecondaryContainer,
          disabledBackground: scheme.onSurface.withValues(alpha: 0.12),
          disabledForeground: scheme.onSurface.withValues(alpha: 0.38),
          borderColor: null,
        );
      case AppButtonVariant.outlined:
        return _ButtonColors(
          background: Colors.transparent,
          foreground: scheme.primary,
          disabledBackground: Colors.transparent,
          disabledForeground: scheme.onSurface.withValues(alpha: 0.38),
          borderColor: scheme.outline,
        );
      case AppButtonVariant.text:
        return _ButtonColors(
          background: Colors.transparent,
          foreground: scheme.primary,
          disabledBackground: Colors.transparent,
          disabledForeground: scheme.onSurface.withValues(alpha: 0.38),
          borderColor: null,
        );
      case AppButtonVariant.destructive:
        return _ButtonColors(
          background: scheme.error,
          foreground: scheme.onError,
          disabledBackground: scheme.onSurface.withValues(alpha: 0.12),
          disabledForeground: scheme.onSurface.withValues(alpha: 0.38),
          borderColor: null,
        );
    }
  }

  Widget _buildContent({
    required Color foregroundColor,
    required IconData? resolvedIcon,
    required bool isCupertino,
  }) {
    if (isBusy) {
      if (isCupertino) {
        return CupertinoActivityIndicator(color: foregroundColor);
      }
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
        ),
      );
    }

    final textWidget = Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w600),
    );

    if (resolvedIcon == null) {
      return textWidget;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(resolvedIcon, size: AppIcons.compactSize, color: foregroundColor),
        const SizedBox(width: AppSpacing.space2),
        Flexible(child: textWidget),
      ],
    );
  }

  Widget _buildMaterialButton({
    required BuildContext context,
    required PresentationCapabilities capabilities,
    required _ButtonColors colors,
    required VoidCallback? effectiveOnPressed,
    required double minTapTarget,
    required IconData? resolvedIcon,
  }) {
    final effectiveForeground = isEnabled
        ? colors.foreground
        : colors.disabledForeground;

    final content = _buildContent(
      foregroundColor: effectiveForeground,
      resolvedIcon: resolvedIcon,
      isCupertino: false,
    );

    final minSize = Size(expand ? double.infinity : minTapTarget, minTapTarget);

    switch (variant) {
      case AppButtonVariant.primary:
        return FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            backgroundColor: colors.background,
            foregroundColor: colors.foreground,
            disabledBackgroundColor: colors.disabledBackground,
            disabledForegroundColor: colors.disabledForeground,
            minimumSize: minSize,
            shape: AppShape.smallBorder,
          ),
          child: content,
        );
      case AppButtonVariant.secondary:
      case AppButtonVariant.tonal:
        return FilledButton.tonal(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            backgroundColor: colors.background,
            foregroundColor: colors.foreground,
            disabledBackgroundColor: colors.disabledBackground,
            disabledForegroundColor: colors.disabledForeground,
            minimumSize: minSize,
            shape: AppShape.smallBorder,
          ),
          child: content,
        );
      case AppButtonVariant.outlined:
        return OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.foreground,
            disabledForegroundColor: colors.disabledForeground,
            side: isEnabled && colors.borderColor != null
                ? BorderSide(color: colors.borderColor!)
                : null,
            minimumSize: minSize,
            shape: AppShape.smallBorder,
          ),
          child: content,
        );
      case AppButtonVariant.text:
        return TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: colors.foreground,
            disabledForegroundColor: colors.disabledForeground,
            minimumSize: minSize,
            shape: AppShape.smallBorder,
          ),
          child: content,
        );
      case AppButtonVariant.destructive:
        return FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            backgroundColor: colors.background,
            foregroundColor: colors.foreground,
            disabledBackgroundColor: colors.disabledBackground,
            disabledForegroundColor: colors.disabledForeground,
            minimumSize: minSize,
            shape: AppShape.smallBorder,
          ),
          child: content,
        );
    }
  }

  Widget _buildCupertinoClassicButton({
    required BuildContext context,
    required _ButtonColors colors,
    required VoidCallback? effectiveOnPressed,
    required double minTapTarget,
    required IconData? resolvedIcon,
  }) {
    final effectiveForeground = isEnabled
        ? colors.foreground
        : colors.disabledForeground;

    final content = _buildContent(
      foregroundColor: effectiveForeground,
      resolvedIcon: resolvedIcon,
      isCupertino: true,
    );

    final padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.space4,
      vertical: AppSpacing.space2,
    );

    final minSize = Size(expand ? double.infinity : minTapTarget, minTapTarget);

    if (variant == AppButtonVariant.primary) {
      return CupertinoButton.filled(
        onPressed: effectiveOnPressed,
        padding: padding,
        borderRadius: AppShape.smallRadius,
        minimumSize: minSize,
        child: content,
      );
    }

    if (variant == AppButtonVariant.outlined) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isEnabled
                ? (colors.borderColor ?? colors.foreground)
                : colors.disabledForeground,
          ),
          borderRadius: AppShape.smallRadius,
        ),
        child: CupertinoButton(
          onPressed: effectiveOnPressed,
          padding: padding,
          minimumSize: minSize,
          borderRadius: AppShape.smallRadius,
          child: content,
        ),
      );
    }

    final background = (variant == AppButtonVariant.text)
        ? null
        : (isEnabled ? colors.background : colors.disabledBackground);

    return CupertinoButton(
      onPressed: effectiveOnPressed,
      padding: padding,
      color: background,
      minimumSize: minSize,
      borderRadius: AppShape.smallRadius,
      child: content,
    );
  }

  Widget _buildCupertinoLiquidGlassButton({
    required BuildContext context,
    required _ButtonColors colors,
    required VoidCallback? effectiveOnPressed,
    required double minTapTarget,
    required IconData? resolvedIcon,
  }) {
    final effectiveForeground = isEnabled
        ? colors.foreground
        : colors.disabledForeground;

    final content = _buildContent(
      foregroundColor: effectiveForeground,
      resolvedIcon: resolvedIcon,
      isCupertino: true,
    );

    AdaptiveButtonStyle style;
    Color? buttonColor;

    switch (variant) {
      case AppButtonVariant.primary:
        style = AdaptiveButtonStyle.filled;
        buttonColor = colors.background;
      case AppButtonVariant.secondary:
      case AppButtonVariant.tonal:
        style = AdaptiveButtonStyle.tinted;
        buttonColor = colors.background;
      case AppButtonVariant.outlined:
        style = AdaptiveButtonStyle.bordered;
        buttonColor = colors.borderColor ?? colors.foreground;
      case AppButtonVariant.text:
        style = AdaptiveButtonStyle.plain;
        buttonColor = colors.foreground;
      case AppButtonVariant.destructive:
        style = AdaptiveButtonStyle.filled;
        buttonColor = colors.background;
    }

    return AdaptiveButton.child(
      onPressed: effectiveOnPressed,
      enabled: isEnabled && !isBusy,
      style: style,
      color: buttonColor,
      minSize: Size(expand ? double.infinity : minTapTarget, minTapTarget),
      borderRadius: AppShape.smallRadius,
      useNative: !isBusy,
      child: content,
    );
  }
}

class _ButtonColors {
  const _ButtonColors({
    required this.background,
    required this.foreground,
    required this.disabledBackground,
    required this.disabledForeground,
    required this.borderColor,
  });

  final Color background;
  final Color foreground;
  final Color disabledBackground;
  final Color disabledForeground;
  final Color? borderColor;
}
