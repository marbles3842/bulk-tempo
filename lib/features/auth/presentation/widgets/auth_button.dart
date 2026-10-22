import 'package:flutter/material.dart';
import 'package:bulk_tempo/core/design_system.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final AppButtonVariant variant;
  final AppIcon? icon;

  const AuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.variant = AppButtonVariant.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: text,
      onPressed: onPressed,
      isBusy: isLoading,
      isEnabled: isEnabled,
      variant: variant,
      icon: icon,
      expand: true,
    );
  }
}
