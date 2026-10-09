import 'package:flutter/material.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
