import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bulk_tempo/core/design_system.dart';

class AuthTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController? controller;
  final Widget? suffixIcon;
  final bool enabled;
  final Key? fieldKey;
  final VoidCallback? onToggleObscureText;
  final String? toggleObscureTooltip;

  const AuthTextField({
    super.key,
    required this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.suffixIcon,
    this.enabled = true,
    this.fieldKey,
    this.onToggleObscureText,
    this.toggleObscureTooltip,
  });

  @override
  Widget build(BuildContext context) {
    Widget? effectiveSuffixIcon = suffixIcon;

    if (effectiveSuffixIcon == null && onToggleObscureText != null) {
      final capabilities = PresentationCapabilities.resolve(context);
      final iconData = AppIcons.resolve(
        context,
        obscureText ? AppIcon.visibility : AppIcon.visibilityOff,
      );

      if (capabilities.platformMode == AdaptivePlatformMode.material) {
        effectiveSuffixIcon = IconButton(
          tooltip: toggleObscureTooltip,
          onPressed: enabled ? onToggleObscureText : null,
          icon: Icon(iconData),
        );
      } else {
        effectiveSuffixIcon = Tooltip(
          message: toggleObscureTooltip ?? '',
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(
              AppSpacing.iosMinTapTarget,
              AppSpacing.iosMinTapTarget,
            ),
            onPressed: enabled ? onToggleObscureText : null,
            child: Icon(
              iconData,
              size: AppIcons.compactSize,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }
    }

    return AppTextField(
      fieldKey: fieldKey,
      controller: controller,
      label: label,
      hint: hint,
      errorText: errorText,
      obscureText: obscureText,
      enabled: enabled,
      autocorrect: !obscureText && keyboardType != TextInputType.emailAddress,
      enableSuggestions: !obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      suffixIcon: effectiveSuffixIcon,
    );
  }
}
