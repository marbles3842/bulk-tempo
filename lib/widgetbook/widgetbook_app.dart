// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:bulk_tempo/core/design_system.dart';
import 'package:bulk_tempo/l10n/app_localizations.dart';
import 'package:bulk_tempo/widgetbook/use_cases/overlays_and_shell_use_cases.dart';
import 'package:bulk_tempo/widgetbook/use_cases/primitives_use_cases.dart';
import 'package:bulk_tempo/widgetbook/use_cases/tokens_use_cases.dart';

/// Top-level list of all Widgetbook navigation nodes exported for the catalog
/// and programmatic smoke tests.
final List<WidgetbookNode> widgetbookDirectories = [
  tokensCategory,
  primitivesCategory,
  overlaysAndShellCategory,
];

/// Global addon providing live switching between the 3 adaptive platform modes.
class AdaptivePlatformModeAddon extends WidgetbookAddon<AdaptivePlatformMode> {
  AdaptivePlatformModeAddon({this.initialMode = AdaptivePlatformMode.material})
    : super(name: 'Platform Mode');

  final AdaptivePlatformMode initialMode;

  @override
  List<Field> get fields => [
    ObjectDropdownField<AdaptivePlatformMode>(
      name: 'mode',
      values: AdaptivePlatformMode.values,
      initialValue: initialMode,
      labelBuilder: (mode) => switch (mode) {
        AdaptivePlatformMode.material => 'Material 3 (Android / Web)',
        AdaptivePlatformMode.cupertinoClassic =>
          'Cupertino Classic (iOS 15–25)',
        AdaptivePlatformMode.cupertinoLiquidGlass =>
          'Cupertino Liquid Glass (iOS 26+)',
      },
    ),
  ];

  @override
  AdaptivePlatformMode valueFromQueryGroup(Map<String, String> group) {
    return valueOf('mode', group) ?? initialMode;
  }

  @override
  Widget buildUseCase(
    BuildContext context,
    Widget child,
    AdaptivePlatformMode setting,
  ) {
    final capabilities = switch (setting) {
      AdaptivePlatformMode.material => const PresentationCapabilities(
        targetPlatform: TargetPlatform.android,
      ),
      AdaptivePlatformMode.cupertinoClassic => const PresentationCapabilities(
        targetPlatform: TargetPlatform.iOS,
        iosMajorVersion: 18,
        supportsNativeIosViews: false,
      ),
      AdaptivePlatformMode.cupertinoLiquidGlass =>
        const PresentationCapabilities(
          targetPlatform: TargetPlatform.iOS,
          iosMajorVersion: 26,
          supportsNativeIosViews: true,
          reduceTransparency: false,
        ),
    };

    final targetPlatform = setting == AdaptivePlatformMode.material
        ? TargetPlatform.android
        : TargetPlatform.iOS;

    return ProviderScope(
      overrides: [
        presentationCapabilitiesOverrideProvider.overrideWithValue(
          capabilities,
        ),
      ],
      child: Theme(
        data: Theme.of(context).copyWith(platform: targetPlatform),
        child: child,
      ),
    );
  }
}

/// Standalone Widgetbook application for Bulk Tempo component catalog.
class BulkTempoWidgetbookApp extends StatelessWidget {
  const BulkTempoWidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Widgetbook.material(
        directories: widgetbookDirectories,
        addons: [
          MaterialThemeAddon(
            themes: [
              WidgetbookTheme(name: 'Light', data: AppTheme.light()),
              WidgetbookTheme(name: 'Dark', data: AppTheme.dark()),
              WidgetbookTheme(
                name: 'High Contrast Light',
                data: AppTheme.highContrastLight(),
              ),
              WidgetbookTheme(
                name: 'High Contrast Dark',
                data: AppTheme.highContrastDark(),
              ),
            ],
          ),
          BuilderAddon(
            name: 'Cupertino Coordination',
            builder: (context, child) {
              final theme = Theme.of(context);
              return CupertinoTheme(
                data: AppTheme.cupertinoFromMaterial(theme),
                child: child,
              );
            },
          ),
          LocalizationAddon(
            locales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            initialLocale: const Locale('en'),
          ),
          // ignore: deprecated_member_use
          TextScaleAddon(scales: const [1.0, 1.3, 1.6, 2.0], initialScale: 1.0),
          AdaptivePlatformModeAddon(),
        ],
      ),
    );
  }
}
