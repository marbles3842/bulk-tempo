import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/platform/presentation_capabilities.dart';
import 'package:bulk_tempo/core/theme/app_icons.dart';
import 'package:bulk_tempo/core/theme/app_shape.dart';
import 'package:bulk_tempo/core/theme/app_spacing.dart';

/// Unified adaptive text field primitive supporting labels, hints, validation
/// errors, unit suffixes, prefix/suffix icons, and 3-tier platform dispatch.
class AppTextField extends ConsumerWidget {
  const AppTextField({
    super.key,
    this.fieldKey,
    this.controller,
    required this.label,
    this.labelMaxLines,
    this.hint,
    this.helperText,
    this.errorText,
    this.suffixText,
    this.prefixIcon,
    this.prefixIconData,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
  });

  /// Optional [Key] passed directly to the underlying editable text field.
  final Key? fieldKey;

  /// Text editing controller.
  final TextEditingController? controller;

  /// Visible label displayed as floating label (Material) or header (Cupertino).
  final String label;

  /// Maximum lines for long labels. Defaults to the platform control's behavior.
  final int? labelMaxLines;

  /// Placeholder hint text.
  final String? hint;

  /// Explanatory helper text displayed below the field when no error is present.
  final String? helperText;

  /// Validation error message displayed below the field and styling borders red.
  final String? errorText;

  /// Unit text (e.g., 'kg', 'kg/wk') affixed to the trailing edge of the field.
  final String? suffixText;

  /// Semantic prefix [AppIcon].
  final AppIcon? prefixIcon;

  /// Direct [IconData] prefix (takes precedence over [prefixIcon]).
  final IconData? prefixIconData;

  /// Trailing interactive widget (e.g., password visibility toggle).
  final Widget? suffixIcon;

  /// Whether to obscure text input (passwords).
  final bool obscureText;

  /// Whether user input is enabled.
  final bool enabled;

  /// Whether to enable autocorrection.
  final bool autocorrect;

  /// Whether to show input suggestions.
  final bool enableSuggestions;

  /// Keyboard type.
  final TextInputType keyboardType;

  /// Action button on the virtual keyboard.
  final TextInputAction? textInputAction;

  /// Callback when text value changes.
  final ValueChanged<String>? onChanged;

  /// Callback when submitted via keyboard action.
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilities = PresentationCapabilities.resolve(context);
    final theme = Theme.of(context);

    if (capabilities.platformMode == AdaptivePlatformMode.material) {
      return _buildMaterialField(context, theme);
    }

    return _buildCupertinoField(context, theme, capabilities);
  }

  Widget _buildMaterialField(BuildContext context, ThemeData theme) {
    final resolvedPrefixIcon =
        prefixIconData ??
        (prefixIcon != null ? AppIcons.resolve(context, prefixIcon!) : null);

    return Material(
      type: MaterialType.transparency,
      child: TextField(
        key: fieldKey,
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        enabled: enabled,
        autocorrect: autocorrect,
        enableSuggestions: enableSuggestions,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: labelMaxLines == null ? label : null,
          label: labelMaxLines == null
              ? null
              : Text(
                  label,
                  maxLines: labelMaxLines,
                  overflow: TextOverflow.clip,
                ),
          hintText: hint,
          helperText: helperText,
          errorText: errorText,
          suffixText: suffixText,
          prefixIcon: resolvedPrefixIcon != null
              ? Icon(resolvedPrefixIcon, size: AppIcons.compactSize)
              : null,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildCupertinoField(
    BuildContext context,
    ThemeData theme,
    PresentationCapabilities capabilities,
  ) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final resolvedPrefixIcon =
        prefixIconData ??
        (prefixIcon != null ? AppIcons.resolve(context, prefixIcon!) : null);

    Widget? prefixWidget;
    if (resolvedPrefixIcon != null) {
      prefixWidget = Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.space3,
          right: AppSpacing.space2,
        ),
        child: Icon(
          resolvedPrefixIcon,
          size: AppIcons.compactSize,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    Widget? suffixWidget;
    if (suffixText != null || suffixIcon != null) {
      suffixWidget = Padding(
        padding: const EdgeInsets.only(
          right: AppSpacing.space3,
          left: AppSpacing.space2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (suffixText != null)
              Text(
                suffixText!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            if (suffixIcon != null) ...[
              if (suffixText != null) const SizedBox(width: AppSpacing.space1),
              suffixIcon!,
            ],
          ],
        ),
      );
    }

    final hasError = errorText != null && errorText!.isNotEmpty;
    final borderColor = hasError ? colorScheme.error : colorScheme.outline;
    final backgroundColor = enabled
        ? colorScheme.surfaceContainerLow
        : colorScheme.surfaceContainerHighest;

    final minTapTarget = capabilities.targetPlatform == TargetPlatform.iOS
        ? AppSpacing.iosMinTapTarget
        : AppSpacing.androidMinTapTarget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            maxLines: labelMaxLines,
            overflow: labelMaxLines == null ? null : TextOverflow.clip,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        Semantics(
          label: label,
          textField: true,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minTapTarget),
            child: CupertinoTextField(
              key: fieldKey,
              controller: controller,
              placeholder: hint,
              placeholderStyle: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              obscureText: obscureText,
              enabled: enabled,
              autocorrect: autocorrect,
              enableSuggestions: enableSuggestions,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              prefix: prefixWidget,
              suffix: suffixWidget,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space3,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: AppShape.smallRadius,
                border: Border.all(
                  color: borderColor,
                  width: hasError ? 1.5 : 1.0,
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.space1),
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                Icon(
                  AppIcons.resolve(context, AppIcon.error),
                  size: 16,
                  color: colorScheme.error,
                ),
                const SizedBox(width: AppSpacing.inlineGap),
                Expanded(
                  child: Text(
                    errorText!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (helperText != null && helperText!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space1),
          Text(
            helperText!,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
