import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/platform/presentation_capabilities.dart';
import 'package:bulk_tempo/core/theme/app_chart_theme.dart';
import 'package:bulk_tempo/core/theme/app_icons.dart';
import 'package:bulk_tempo/core/theme/app_motion.dart';
import 'package:bulk_tempo/core/theme/app_palette.dart';
import 'package:bulk_tempo/core/theme/app_semantic_colors.dart';
import 'package:bulk_tempo/core/theme/app_shape.dart';
import 'package:bulk_tempo/core/theme/app_spacing.dart';
import 'package:bulk_tempo/core/theme/app_theme.dart';

import '../../test_helpers/pump_app.dart';

double _contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('WCAG relative luminance contrast checks', () {
    void verifySemanticPalette(String label, AppSemanticColors colors) {
      test(
        '$label semantic pairs meet >= 4.5:1 text contrast and >= 3.0:1 border contrast',
        () {
          expect(
            _contrastRatio(colors.onSuccessContainer, colors.successContainer),
            greaterThanOrEqualTo(4.5),
            reason: '$label success pair contrast below 4.5:1',
          );
          expect(
            _contrastRatio(colors.onWarningContainer, colors.warningContainer),
            greaterThanOrEqualTo(4.5),
            reason: '$label warning pair contrast below 4.5:1',
          );
          expect(
            _contrastRatio(colors.onInfoContainer, colors.infoContainer),
            greaterThanOrEqualTo(4.5),
            reason: '$label info pair contrast below 4.5:1',
          );
          expect(
            _contrastRatio(
              colors.onAchievementContainer,
              colors.achievementContainer,
            ),
            greaterThanOrEqualTo(4.5),
            reason: '$label achievement pair contrast below 4.5:1',
          );
          expect(
            _contrastRatio(
              colors.achievementBorder,
              colors.achievementContainer,
            ),
            greaterThanOrEqualTo(3.0),
            reason: '$label achievement border contrast below 3.0:1',
          );
        },
      );
    }

    verifySemanticPalette('Light', AppSemanticColors.light());
    verifySemanticPalette('Dark', AppSemanticColors.dark());
    verifySemanticPalette(
      'High-Contrast Light',
      AppSemanticColors.highContrastLight(),
    );
    verifySemanticPalette(
      'High-Contrast Dark',
      AppSemanticColors.highContrastDark(),
    );

    void verifyColorSchemePairs(String label, ThemeData theme) {
      test(
        '$label ColorScheme primary and surface pairings meet >= 4.5:1 contrast',
        () {
          final scheme = theme.colorScheme;
          expect(
            _contrastRatio(scheme.onPrimary, scheme.primary),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrastRatio(scheme.onPrimaryContainer, scheme.primaryContainer),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrastRatio(scheme.onSurface, scheme.surface),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrastRatio(scheme.onSurface, scheme.surfaceContainerLow),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrastRatio(scheme.onSurface, scheme.surfaceContainerHigh),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrastRatio(scheme.onError, scheme.error),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrastRatio(scheme.onErrorContainer, scheme.errorContainer),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrastRatio(scheme.onInverseSurface, scheme.inverseSurface),
            greaterThanOrEqualTo(4.5),
          );
        },
      );
    }

    verifyColorSchemePairs('Light', AppTheme.light());
    verifyColorSchemePairs('Dark', AppTheme.dark());
    verifyColorSchemePairs('High-Contrast Light', AppTheme.highContrastLight());
    verifyColorSchemePairs('High-Contrast Dark', AppTheme.highContrastDark());
  });

  group('AppSemanticColors ThemeExtension', () {
    test('copyWith and lerp behave deterministically', () {
      final light = AppSemanticColors.light();
      final dark = AppSemanticColors.dark();

      final copied = light.copyWith(successContainer: Colors.green);
      expect(copied.successContainer, Colors.green);
      expect(copied.onSuccessContainer, light.onSuccessContainer);
      expect(copied, isNot(equals(light)));

      expect(light.lerp(null, 0.5), equals(light));
      expect(light.lerp(dark, 0.0), equals(light));
      expect(light.lerp(dark, 1.0), equals(dark));

      final mid = light.lerp(dark, 0.5);
      expect(
        mid.successContainer,
        Color.lerp(light.successContainer, dark.successContainer, 0.5),
      );
    });

    testWidgets(
      'of(context) resolves registered extension and falls back safely',
      (tester) async {
        late AppSemanticColors resolvedFromAppTheme;
        await tester.pumpApp(
          Builder(
            builder: (context) {
              resolvedFromAppTheme = AppSemanticColors.of(context);
              return const SizedBox.shrink();
            },
          ),
        );
        expect(resolvedFromAppTheme, equals(AppSemanticColors.light()));

        late AppSemanticColors fallbackDark;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Builder(
              builder: (context) {
                fallbackDark = AppSemanticColors.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        expect(fallbackDark, equals(AppSemanticColors.dark()));
      },
    );
  });

  group('AppChartTheme ThemeExtension', () {
    test('fromColorScheme maps roles and supports copyWith/lerp', () {
      final lightScheme = AppTheme.light().colorScheme;
      final darkScheme = AppTheme.dark().colorScheme;
      final lightChart = AppChartTheme.fromColorScheme(lightScheme);
      final darkChart = AppChartTheme.fromColorScheme(darkScheme);

      expect(lightChart.seriesWeight, lightScheme.primary);
      expect(lightChart.seriesPace, lightScheme.primary);
      expect(lightChart.seriesWorkouts, lightScheme.tertiary);
      expect(lightChart.targetFill, lightScheme.secondaryContainer);
      expect(lightChart.targetBoundary, lightScheme.onSecondaryContainer);
      expect(lightChart.axisLabel, lightScheme.onSurfaceVariant);
      expect(lightChart.gridLine, lightScheme.outlineVariant);
      expect(lightChart.tooltipSurface, lightScheme.inverseSurface);
      expect(lightChart.onTooltipSurface, lightScheme.onInverseSurface);
      expect(lightChart.lineStrokeWidth, 3.0);
      expect(lightChart.barWidth, 12.0);
      expect(lightChart.targetDashPattern, const [6, 4]);

      final updated = lightChart.copyWith(
        lineStrokeWidth: 4.0,
        barWidth: 16.0,
        targetDashPattern: const [8, 4],
      );
      expect(updated.lineStrokeWidth, 4.0);
      expect(updated.barWidth, 16.0);
      expect(updated.targetDashPattern, const [8, 4]);

      expect(lightChart.lerp(null, 0.5), equals(lightChart));
      final lerped = lightChart.lerp(updated, 0.5);
      expect(lerped.lineStrokeWidth, 3.5);
      expect(lerped.barWidth, 14.0);
      expect(lerped.targetDashPattern, const [8, 4]);
      expect(lightChart.lerp(darkChart, 0.0), equals(lightChart));
    });

    testWidgets(
      'of(context) resolves registered extension and falls back safely',
      (tester) async {
        late AppChartTheme resolved;
        await tester.pumpApp(
          Builder(
            builder: (context) {
              resolved = AppChartTheme.of(context);
              return const SizedBox.shrink();
            },
          ),
        );
        expect(
          resolved,
          equals(AppChartTheme.fromColorScheme(AppTheme.light().colorScheme)),
        );

        late AppChartTheme fallback;
        final bareTheme = ThemeData.light();
        await tester.pumpWidget(
          MaterialApp(
            theme: bareTheme,
            home: Builder(
              builder: (context) {
                fallback = AppChartTheme.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        expect(
          fallback,
          equals(AppChartTheme.fromColorScheme(bareTheme.colorScheme)),
        );
      },
    );
  });

  group('AppTheme & CupertinoTheme projection', () {
    test('headlineMedium configures tabular figures for Metric role', () {
      for (final theme in [
        AppTheme.light(),
        AppTheme.dark(),
        AppTheme.highContrastLight(),
        AppTheme.highContrastDark(),
      ]) {
        final features = theme.textTheme.headlineMedium?.fontFeatures;
        expect(features, contains(const FontFeature.tabularFigures()));
      }
    });

    test(
      'cupertinoFromMaterial maps Material ColorScheme roles accurately',
      () {
        final materialDark = AppTheme.dark();
        final cupertinoDark = AppTheme.cupertinoFromMaterial(materialDark);

        expect(cupertinoDark.brightness, Brightness.dark);
        expect(cupertinoDark.primaryColor, materialDark.colorScheme.primary);
        expect(
          cupertinoDark.primaryContrastingColor,
          materialDark.colorScheme.onPrimary,
        );
        expect(
          cupertinoDark.barBackgroundColor,
          materialDark.colorScheme.surfaceContainerHigh,
        );
        expect(
          cupertinoDark.scaffoldBackgroundColor,
          materialDark.colorScheme.surface,
        );
      },
    );
  });

  group('AppSpacing, AppShape, AppMotion, and AppIcons tokens', () {
    test(
      'AppPalette, AppSpacing, and AppShape expose expected token values',
      () {
        expect(AppPalette.seedColor, const Color(0xFF673AB7));
        expect(AppSpacing.space0, 0.0);
        expect(AppSpacing.space1, 4.0);
        expect(AppSpacing.space2, 8.0);
        expect(AppSpacing.space3, 12.0);
        expect(AppSpacing.space4, 16.0);
        expect(AppSpacing.space6, 24.0);
        expect(AppSpacing.space8, 32.0);
        expect(AppSpacing.space12, 48.0);
        expect(AppSpacing.inlineGap, 8.0);
        expect(AppSpacing.relatedGap, 12.0);
        expect(AppSpacing.cardPadding, 16.0);
        expect(AppSpacing.sectionGap, 24.0);
        expect(AppSpacing.pageInsetCompact, 16.0);
        expect(AppSpacing.pageInsetWide, 24.0);
        expect(AppSpacing.sheetInset, 24.0);
        expect(AppSpacing.compactBreakpoint, 600.0);
        expect(AppSpacing.expandedBreakpoint, 840.0);
        expect(AppSpacing.formMaxWidth, 480.0);
        expect(AppSpacing.dashboardMaxWidth, 1120.0);
        expect(AppSpacing.androidMinTapTarget, 48.0);
        expect(AppSpacing.iosMinTapTarget, 44.0);

        expect(AppShape.small, 8.0);
        expect(AppShape.card, 16.0);
        expect(AppShape.sheet, 24.0);
      },
    );

    testWidgets(
      'AppMotion.effectiveDuration returns Duration.zero when reduceMotion is active',
      (tester) async {
        late Duration normalDuration;
        await tester.pumpApp(
          Builder(
            builder: (context) {
              normalDuration = AppMotion.effectiveDuration(
                context,
                AppMotion.contentTransitionDuration,
              );
              return const SizedBox.shrink();
            },
          ),
          capabilities: const PresentationCapabilities(
            targetPlatform: TargetPlatform.android,
            reduceMotion: false,
          ),
        );
        expect(normalDuration, AppMotion.contentTransitionDuration);

        late Duration reducedDuration;
        await tester.pumpApp(
          Builder(
            builder: (context) {
              reducedDuration = AppMotion.effectiveDuration(
                context,
                AppMotion.contentTransitionDuration,
              );
              return const SizedBox.shrink();
            },
          ),
          capabilities: const PresentationCapabilities(
            targetPlatform: TargetPlatform.iOS,
            reduceMotion: true,
          ),
        );
        expect(reducedDuration, Duration.zero);
      },
    );

    testWidgets(
      'AppIcons resolves Material, Cupertino, and SF Symbols for every AppIcon',
      (tester) async {
        for (final icon in AppIcon.values) {
          expect(AppIcons.material(icon), isNotNull);
          expect(AppIcons.material(icon, selected: true), isNotNull);
          expect(AppIcons.cupertino(icon), isNotNull);
          expect(AppIcons.cupertino(icon, selected: true), isNotNull);
          expect(AppIcons.sfSymbol(icon), isNotEmpty);
          expect(AppIcons.sfSymbol(icon, selected: true), isNotEmpty);
        }

        late IconData androidIcon;
        await tester.pumpApp(
          Builder(
            builder: (context) {
              androidIcon = AppIcons.resolve(context, AppIcon.home);
              return const SizedBox.shrink();
            },
          ),
          capabilities: const PresentationCapabilities(
            targetPlatform: TargetPlatform.android,
          ),
        );
        expect(androidIcon, Icons.dashboard_outlined);

        late IconData iosIcon;
        await tester.pumpApp(
          Builder(
            builder: (context) {
              iosIcon = AppIcons.resolve(context, AppIcon.home, selected: true);
              return const SizedBox.shrink();
            },
          ),
          capabilities: const PresentationCapabilities(
            targetPlatform: TargetPlatform.iOS,
          ),
        );
        expect(iosIcon, CupertinoIcons.square_grid_2x2_fill);
      },
    );
  });
}
