import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/platform/presentation_capabilities.dart';
import 'package:bulk_tempo/core/theme/app_icons.dart';
import 'package:bulk_tempo/core/theme/app_shape.dart';
import 'package:bulk_tempo/core/theme/app_spacing.dart';

/// Visual surface styling variants for [AppCard].
enum AppCardVariant {
  /// Opaque standard tonal surface (`surfaceContainerLow`).
  grouped,

  /// Opaque bordered surface (`surface` with `outlineVariant` border).
  outlined,

  /// Higher tonal surface (`surfaceContainerHighest`) for emphasis.
  tinted,
}

/// Unified opaque content card component with optional title, subtitle,
/// leading icon, trailing badge/action slot, and variant styling.
class AppCard extends ConsumerWidget {
  const AppCard({
    super.key,
    this.cardKey,
    this.title,
    this.subtitle,
    this.subtitleKey,
    this.leadingIcon,
    this.headerTrailing,
    this.variant = AppCardVariant.grouped,
    this.padding,
    this.margin,
    this.onTap,
    required this.child,
  });

  /// Optional [Key] passed directly to the underlying card/surface widget.
  final Key? cardKey;

  /// Optional header title text.
  final String? title;

  /// Optional header subtitle text.
  final String? subtitle;

  /// Optional [Key] assigned to the subtitle widget.
  final Key? subtitleKey;

  /// Optional semantic icon displayed before the title and subtitle.
  final AppIcon? leadingIcon;

  /// Optional trailing widget in the header row (e.g. status badge or action).
  final Widget? headerTrailing;

  /// Visual surface variant.
  final AppCardVariant variant;

  /// Inner padding for the card content. Defaults to [AppSpacing.cardPadding].
  final EdgeInsetsGeometry? padding;

  /// Outer margin surrounding the card.
  final EdgeInsetsGeometry? margin;

  /// Optional tap callback.
  final VoidCallback? onTap;

  /// Main content widget.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilities = PresentationCapabilities.resolve(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final backgroundColor = _resolveBackgroundColor(colorScheme);
    final effectivePadding =
        padding ?? const EdgeInsets.all(AppSpacing.cardPadding);

    final hasHeader =
        title != null ||
        subtitle != null ||
        leadingIcon != null ||
        headerTrailing != null;

    Widget content = child;

    if (hasHeader) {
      final header = _buildHeader(
        context: context,
        colorScheme: colorScheme,
        textTheme: textTheme,
      );

      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          header,
          const SizedBox(height: AppSpacing.relatedGap),
          child,
        ],
      );
    }

    Widget paddedContent = Padding(padding: effectivePadding, child: content);

    if (onTap != null) {
      final minTapTarget = capabilities.targetPlatform == TargetPlatform.iOS
          ? AppSpacing.iosMinTapTarget
          : AppSpacing.androidMinTapTarget;

      final interactiveChild =
          capabilities.platformMode == AdaptivePlatformMode.material
          ? InkWell(
              onTap: onTap,
              borderRadius: AppShape.cardRadius,
              child: paddedContent,
            )
          : GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: paddedContent,
            );

      paddedContent = Semantics(
        button: true,
        enabled: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minTapTarget,
            minHeight: minTapTarget,
          ),
          child: interactiveChild,
        ),
      );
    }

    if (capabilities.platformMode == AdaptivePlatformMode.material) {
      final shape = RoundedRectangleBorder(
        borderRadius: AppShape.cardRadius,
        side: variant == AppCardVariant.outlined
            ? BorderSide(color: colorScheme.outlineVariant)
            : BorderSide.none,
      );

      return Card(
        key: cardKey,
        color: backgroundColor,
        elevation: 0,
        margin: margin ?? EdgeInsets.zero,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: paddedContent,
      );
    }

    // Cupertino classic & liquid glass: opaque tonal card surface
    return Container(
      key: cardKey,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppShape.cardRadius,
        border: variant == AppCardVariant.outlined
            ? Border.all(color: colorScheme.outlineVariant)
            : null,
      ),
      child: ClipRRect(borderRadius: AppShape.cardRadius, child: paddedContent),
    );
  }

  Color _resolveBackgroundColor(ColorScheme scheme) {
    switch (variant) {
      case AppCardVariant.grouped:
        return scheme.surfaceContainerLow;
      case AppCardVariant.outlined:
        return scheme.surface;
      case AppCardVariant.tinted:
        return scheme.surfaceContainerHighest;
    }
  }

  Widget _buildHeader({
    required BuildContext context,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    final resolvedIcon = leadingIcon != null
        ? AppIcons.resolve(context, leadingIcon!)
        : null;

    final textScaler = MediaQuery.textScalerOf(context);
    final isEnlargedText = textScaler.scale(1.0) >= 1.4;

    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Text(
            title!,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        if (subtitle != null) ...[
          if (title != null) const SizedBox(height: AppSpacing.space1),
          Text(
            subtitle!,
            key: subtitleKey,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    if (isEnlargedText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (resolvedIcon != null) ...[
            Icon(
              resolvedIcon,
              size: AppIcons.normalSize,
              color: colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.space1),
          ],
          titleColumn,
          if (headerTrailing != null) ...[
            const SizedBox(height: AppSpacing.space2),
            headerTrailing!,
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (resolvedIcon != null) ...[
          Icon(
            resolvedIcon,
            size: AppIcons.normalSize,
            color: colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.space3),
        ],
        Expanded(child: titleColumn),
        if (headerTrailing != null) ...[
          const SizedBox(width: AppSpacing.space2),
          headerTrailing!,
        ],
      ],
    );
  }
}
