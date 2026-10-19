// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:bulk_tempo/core/design_system.dart';

PresentationCapabilities _capabilitiesForMode(AdaptivePlatformMode mode) {
  switch (mode) {
    case AdaptivePlatformMode.material:
      return const PresentationCapabilities(
        targetPlatform: TargetPlatform.android,
      );
    case AdaptivePlatformMode.cupertinoClassic:
      return const PresentationCapabilities(
        targetPlatform: TargetPlatform.iOS,
        iosMajorVersion: 18,
        supportsNativeIosViews: false,
      );
    case AdaptivePlatformMode.cupertinoLiquidGlass:
      return const PresentationCapabilities(
        targetPlatform: TargetPlatform.iOS,
        iosMajorVersion: 26,
        supportsNativeIosViews: true,
        reduceTransparency: false,
      );
  }
}

Widget _wrapAdaptivePlatform(
  BuildContext context,
  AdaptivePlatformMode mode,
  Widget child,
) {
  final capabilities = _capabilitiesForMode(mode);
  final theme = Theme.of(context);
  final targetPlatform = mode == AdaptivePlatformMode.material
      ? TargetPlatform.android
      : TargetPlatform.iOS;

  return ProviderScope(
    overrides: [
      presentationCapabilitiesOverrideProvider.overrideWithValue(capabilities),
    ],
    child: Theme(
      data: theme.copyWith(platform: targetPlatform),
      child: CupertinoTheme(
        data: AppTheme.cupertinoFromMaterial(theme),
        child: child,
      ),
    ),
  );
}

AdaptivePlatformMode _readPlatformKnob(BuildContext context) {
  try {
    return context.knobs.object.dropdown<AdaptivePlatformMode>(
      label: 'Platform Mode',
      options: AdaptivePlatformMode.values,
      initialOption: AdaptivePlatformMode.material,
      labelBuilder: (mode) => switch (mode) {
        AdaptivePlatformMode.material => 'Material 3 (Android)',
        AdaptivePlatformMode.cupertinoClassic =>
          'Cupertino Classic (iOS 15–25)',
        AdaptivePlatformMode.cupertinoLiquidGlass =>
          'Cupertino Liquid Glass (iOS 26+)',
      },
    );
  } catch (_) {
    return AdaptivePlatformMode.material;
  }
}

/// Category containing all primitive shared widget use cases.
final primitivesCategory = WidgetbookCategory(
  name: 'Primitives',
  children: [
    WidgetbookComponent(
      name: 'AppButton',
      useCases: [
        WidgetbookUseCase(
          name: '7-State Matrix Showcase',
          builder: (context) {
            final theme = Theme.of(context);
            final mode = _readPlatformKnob(context);

            final variants = [
              ('Primary', AppButtonVariant.primary),
              ('Secondary', AppButtonVariant.secondary),
              ('Tonal', AppButtonVariant.tonal),
              ('Outlined', AppButtonVariant.outlined),
              ('Text', AppButtonVariant.text),
              ('Destructive', AppButtonVariant.destructive),
            ];

            return _wrapAdaptivePlatform(
              context,
              mode,
              SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AppButton 7-State Matrix',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      'States: Default, Pressed, Focused, Hovered, Disabled, Busy, and Destructive across all semantic variants. '
                      'Interactive states (Pressed, Focused, Hovered) are handled dynamically by the platform gesture recognizers.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    for (final (name, variant) in variants) ...[
                      Text('$name Variant', style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.space2),
                      Wrap(
                        spacing: AppSpacing.space3,
                        runSpacing: AppSpacing.space3,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          AppButton(
                            label: 'Default',
                            variant: variant,
                            onPressed: () {},
                          ),
                          AppButton(
                            label: 'Disabled',
                            variant: variant,
                            isEnabled: false,
                            onPressed: () {},
                          ),
                          AppButton(
                            label: 'Busy',
                            variant: variant,
                            isBusy: true,
                            onPressed: () {},
                          ),
                          AppButton(
                            label: 'With Icon',
                            variant: variant,
                            icon: AppIcon.addMeasurement,
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space4),
                    ],
                    const Divider(),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      'Note on Framework-Managed States:',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      '• Pressed: triggered on primary pointer down via Material Ink response or Cupertino opacity dimming.\n'
                      '• Focused: indicated via Material focus highlight and Cupertino keyboard focus ring.\n'
                      '• Hovered: surfaces mouse hover highlight on web/desktop viewports.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        WidgetbookUseCase(
          name: 'Interactive Knobs',
          builder: (context) {
            final mode = _readPlatformKnob(context);

            final label = context.knobs.string(
              label: 'Label',
              initialValue: 'Save Measurement',
            );
            final variant = context.knobs.object.dropdown<AppButtonVariant>(
              label: 'Variant',
              options: AppButtonVariant.values,
              initialOption: AppButtonVariant.primary,
              labelBuilder: (v) => v.name,
            );
            final isEnabled = context.knobs.boolean(
              label: 'Is Enabled',
              initialValue: true,
            );
            final isBusy = context.knobs.boolean(
              label: 'Is Busy',
              initialValue: false,
            );
            final expand = context.knobs.boolean(
              label: 'Expand Full Width',
              initialValue: false,
            );
            final hasIcon = context.knobs.boolean(
              label: 'Include Icon',
              initialValue: true,
            );

            return _wrapAdaptivePlatform(
              context,
              mode,
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  child: AppButton(
                    label: label,
                    variant: variant,
                    isEnabled: isEnabled,
                    isBusy: isBusy,
                    expand: expand,
                    icon: hasIcon ? AppIcon.addMeasurement : null,
                    onPressed: () {},
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'AppTextField',
      useCases: [
        WidgetbookUseCase(
          name: '7-State Matrix Showcase',
          builder: (context) {
            final theme = Theme.of(context);
            final mode = _readPlatformKnob(context);

            return _wrapAdaptivePlatform(
              context,
              mode,
              SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AppTextField 7-State Matrix',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      'States: Default, Focused/Filled, Hovered, Disabled, Error Validation, Password Obscure Toggle, and Unit Suffixes.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    const AppTextField(
                      label: 'Default State',
                      hint: 'e.g. 82.50',
                      prefixIcon: AppIcon.weight,
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    AppTextField(
                      label: 'Filled with Unit Suffix',
                      controller: TextEditingController(text: '83.25'),
                      suffixText: 'kg',
                      prefixIcon: AppIcon.weight,
                      helperText: 'Morning weight before breakfast',
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    AppTextField(
                      label: 'Weekly Pace Target',
                      controller: TextEditingController(text: '+0.35'),
                      suffixText: 'kg/wk',
                      prefixIcon: AppIcon.target,
                      helperText: 'Target gain pace per calendar week',
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    const AppTextField(
                      label: 'Validation Error State',
                      controller: null,
                      hint: '0.00',
                      errorText: 'Value must be between 30.00 kg and 300.00 kg',
                      prefixIcon: AppIcon.weight,
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    const AppTextField(
                      label: 'Disabled State',
                      controller: null,
                      hint: 'Calculated automatically',
                      enabled: false,
                      prefixIcon: AppIcon.calendar,
                      helperText: 'Disabled fields cannot receive user input',
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    const _PasswordStateField(),
                  ],
                ),
              ),
            );
          },
        ),
        WidgetbookUseCase(
          name: 'Interactive Knobs',
          builder: (context) {
            final mode = _readPlatformKnob(context);

            final label = context.knobs.string(
              label: 'Label',
              initialValue: 'Body Weight',
            );
            final hint = context.knobs.string(
              label: 'Hint',
              initialValue: 'Enter weight in kg',
            );
            final helperText = context.knobs.string(
              label: 'Helper Text',
              initialValue: 'Weigh in first thing in the morning',
            );
            final hasError = context.knobs.boolean(
              label: 'Show Error',
              initialValue: false,
            );
            final errorText = hasError
                ? context.knobs.string(
                    label: 'Error Text',
                    initialValue: 'Measurement exceeds reasonable range',
                  )
                : null;
            final suffixText = context.knobs.string(
              label: 'Suffix Unit',
              initialValue: 'kg',
            );
            final enabled = context.knobs.boolean(
              label: 'Enabled',
              initialValue: true,
            );
            final obscureText = context.knobs.boolean(
              label: 'Obscure Text',
              initialValue: false,
            );

            return _wrapAdaptivePlatform(
              context,
              mode,
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.formMaxWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.space4),
                    child: AppTextField(
                      label: label,
                      hint: hint.isNotEmpty ? hint : null,
                      helperText: helperText.isNotEmpty ? helperText : null,
                      errorText: errorText,
                      suffixText: suffixText.isNotEmpty ? suffixText : null,
                      enabled: enabled,
                      obscureText: obscureText,
                      prefixIcon: AppIcon.weight,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'AppCard',
      useCases: [
        WidgetbookUseCase(
          name: 'Surface Variants & Asynchronous Content States',
          builder: (context) {
            final theme = Theme.of(context);
            final mode = _readPlatformKnob(context);

            return _wrapAdaptivePlatform(
              context,
              mode,
              SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AppCard Surface Variants',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      'Grouped (surfaceContainerLow), Outlined (surface + outline border), and Tinted (surfaceContainerHighest).',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    AppCard(
                      variant: AppCardVariant.grouped,
                      title: 'Grouped Card Variant',
                      subtitle: 'Standard opaque container surface',
                      leadingIcon: AppIcon.home,
                      headerTrailing: const AppStatusBadge(
                        label: 'Grouped',
                        tone: AppFeedbackTone.info,
                      ),
                      child: const Text(
                        'Default card surface used across dashboard and list screens.',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    AppCard(
                      variant: AppCardVariant.outlined,
                      title: 'Outlined Card Variant',
                      subtitle: 'Surface with explicit outlineVariant border',
                      leadingIcon: AppIcon.weight,
                      headerTrailing: const AppStatusBadge(
                        label: 'Outlined',
                        tone: AppFeedbackTone.warning,
                      ),
                      child: const Text(
                        'Bordered card variant used for high contrast separation.',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    AppCard(
                      variant: AppCardVariant.tinted,
                      title: 'Tinted Card Variant',
                      subtitle: 'Higher tonal surface container',
                      leadingIcon: AppIcon.achievement,
                      headerTrailing: const AppStatusBadge(
                        label: 'Tinted',
                        tone: AppFeedbackTone.achievement,
                      ),
                      child: const Text(
                        'Highlighted card surface used for featured statistics and PR milestones.',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space6),
                    Text(
                      'Asynchronous Content States',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    // Loading State
                    AppCard(
                      title: 'Loading Asynchronous State',
                      subtitle: 'Fetching weight measurements...',
                      leadingIcon: AppIcon.weight,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: AppSpacing.space4,
                        ),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    // Loaded State with Outdated / Stale Badge
                    AppCard(
                      title: 'Loaded State (Stale Cache)',
                      subtitle: 'Last synced 3 hours ago',
                      leadingIcon: AppIcon.weight,
                      headerTrailing: const AppStatusBadge(
                        label: 'Stale',
                        tone: AppFeedbackTone.warning,
                        icon: AppIcon.warning,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '82.50 kg',
                            style: theme.textTheme.headlineMedium,
                          ),
                          const Spacer(),
                          const Text(
                            '+0.35 kg/wk pace',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    // Empty State
                    AppCard(
                      title: 'Empty State',
                      subtitle: 'No measurements logged yet',
                      leadingIcon: AppIcon.calendar,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Begin tracking your weekly weight trend by logging your first weigh-in.',
                          ),
                          const SizedBox(height: AppSpacing.space3),
                          AppButton(
                            label: 'Log Weight Now',
                            variant: AppButtonVariant.primary,
                            icon: AppIcon.addMeasurement,
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    // Unconfigured State
                    AppCard(
                      title: 'Unconfigured Integration',
                      subtitle: 'Hevy API key required',
                      leadingIcon: AppIcon.apiKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Connect your Hevy API key in Profile settings to synchronize completed workout routines.',
                          ),
                          const SizedBox(height: AppSpacing.space3),
                          AppButton(
                            label: 'Configure Hevy API Key',
                            variant: AppButtonVariant.secondary,
                            icon: AppIcon.link,
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    // Error / Retry State
                    AppCard(
                      title: 'Error & Retry State',
                      subtitle: 'Network connection timeout',
                      leadingIcon: AppIcon.error,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Failed to reach Firebase backend. Please check your network and retry.',
                          ),
                          const SizedBox(height: AppSpacing.space3),
                          AppButton(
                            label: 'Retry Connection',
                            variant: AppButtonVariant.outlined,
                            icon: AppIcon.retry,
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'AppFeedback',
      useCases: [
        WidgetbookUseCase(
          name: 'Banners, Badges & SnackBar Showcase',
          builder: (context) {
            final theme = Theme.of(context);
            final mode = _readPlatformKnob(context);

            final tones = [
              (
                'Success',
                AppFeedbackTone.success,
                'Weight entry saved successfully.',
              ),
              (
                'Warning',
                AppFeedbackTone.warning,
                'Target pace exceeded: gain rate exceeds +0.75 kg/wk.',
              ),
              (
                'Info',
                AppFeedbackTone.info,
                'Weekly rolling average updates after 3 recorded measurements.',
              ),
              (
                'Error',
                AppFeedbackTone.error,
                'Invalid Hevy API key format. Expected 36-character UUID.',
              ),
              (
                'Achievement',
                AppFeedbackTone.achievement,
                'New personal record: 4 consecutive target weeks achieved!',
              ),
            ];

            return _wrapAdaptivePlatform(
              context,
              mode,
              SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AppFeedbackBanner Tones',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      'Inline banners with paired container/foreground tokens from AppSemanticColors and ColorScheme.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    for (final (_, tone, message) in tones) ...[
                      AppFeedbackBanner(
                        message: message,
                        tone: tone,
                        actionLabel: 'Details',
                        onAction: () {},
                      ),
                      const SizedBox(height: AppSpacing.space3),
                    ],
                    const SizedBox(height: AppSpacing.space6),
                    Text(
                      'AppStatusBadge Tones & Gold Motif',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      'Compact status chips with optional icons. Achievement tone uses golden border & container motif.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Wrap(
                      spacing: AppSpacing.space3,
                      runSpacing: AppSpacing.space3,
                      children: [
                        for (final (name, tone, _) in tones) ...[
                          AppStatusBadge(label: name, tone: tone),
                          AppStatusBadge(
                            label: '$name + Icon',
                            tone: tone,
                            icon: tone == AppFeedbackTone.achievement
                                ? AppIcon.achievement
                                : null,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space6),
                    Text(
                      'AppFeedback.showSnackBar Triggers',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      'Transient toast feedback dispatches to floating SnackBar or AdaptiveSnackBar on iOS 26+.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Wrap(
                      spacing: AppSpacing.space3,
                      runSpacing: AppSpacing.space3,
                      children: [
                        for (final (name, tone, message) in tones)
                          AppButton(
                            label: 'Show $name SnackBar',
                            variant: tone == AppFeedbackTone.error
                                ? AppButtonVariant.destructive
                                : AppButtonVariant.tonal,
                            onPressed: () {
                              AppFeedback.showSnackBar(
                                context,
                                message: message,
                                tone: tone,
                                actionLabel: 'Undo',
                                onAction: () {},
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),
  ],
);

class _PasswordStateField extends StatefulWidget {
  const _PasswordStateField();

  @override
  State<_PasswordStateField> createState() => _PasswordStateFieldState();
}

class _PasswordStateFieldState extends State<_PasswordStateField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: 'Password Input with Obscure Toggle',
      controller: TextEditingController(text: 'secretPassword123'),
      obscureText: _obscure,
      prefixIcon: AppIcon.apiKey,
      suffixIcon: IconButton(
        icon: Icon(
          _obscure
              ? AppIcons.resolve(context, AppIcon.visibility)
              : AppIcons.resolve(context, AppIcon.visibilityOff),
          size: 20,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
      helperText: 'Tap the eye icon to toggle secret visibility',
    );
  }
}
