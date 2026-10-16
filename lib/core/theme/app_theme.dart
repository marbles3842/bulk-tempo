import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bulk_tempo/core/theme/app_chart_theme.dart';
import 'package:bulk_tempo/core/theme/app_palette.dart';
import 'package:bulk_tempo/core/theme/app_semantic_colors.dart';
import 'package:bulk_tempo/core/theme/app_shape.dart';
import 'package:bulk_tempo/core/theme/app_spacing.dart';

/// Centralized Material 3 and Cupertino theme factories for Bulk Tempo.
abstract final class AppTheme {
  /// Standard light Material 3 theme.
  static ThemeData light() => _build(
    brightness: Brightness.light,
    isHighContrast: false,
    semanticColors: AppSemanticColors.light(),
  );

  /// Standard dark Material 3 theme.
  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    isHighContrast: false,
    semanticColors: AppSemanticColors.dark(),
  );

  /// High-contrast light Material 3 theme (`contrastLevel: 1.0`).
  static ThemeData highContrastLight() => _build(
    brightness: Brightness.light,
    isHighContrast: true,
    semanticColors: AppSemanticColors.highContrastLight(),
  );

  /// High-contrast dark Material 3 theme (`contrastLevel: 1.0`).
  static ThemeData highContrastDark() => _build(
    brightness: Brightness.dark,
    isHighContrast: true,
    semanticColors: AppSemanticColors.highContrastDark(),
  );

  /// Projects a coordinated [CupertinoThemeData] from a Material [ThemeData].
  static CupertinoThemeData cupertinoFromMaterial(ThemeData materialTheme) {
    final scheme = materialTheme.colorScheme;
    final textTheme = materialTheme.textTheme;
    return CupertinoThemeData(
      brightness: materialTheme.brightness,
      primaryColor: scheme.primary,
      primaryContrastingColor: scheme.onPrimary,
      barBackgroundColor: scheme.surfaceContainerHigh,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: CupertinoTextThemeData(
        primaryColor: scheme.primary,
        textStyle: textTheme.bodyLarge?.copyWith(color: scheme.onSurface),
        navTitleTextStyle: textTheme.titleMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        navLargeTitleTextStyle: textTheme.headlineSmall?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        tabLabelTextStyle: textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required bool isHighContrast,
    required AppSemanticColors semanticColors,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppPalette.seedColor,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
      contrastLevel: isHighContrast ? 1.0 : 0.0,
    );

    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
    );

    final baseTextTheme = baseTheme.textTheme;
    final textTheme = baseTextTheme.copyWith(
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: (baseTextTheme.headlineMedium ?? const TextStyle())
          .copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );

    final chartTheme = AppChartTheme.fromColorScheme(colorScheme);

    return baseTheme.copyWith(
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[semanticColors, chartTheme],
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: AppShape.cardBorder,
        margin: EdgeInsets.zero,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: colorScheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
        shape: AppShape.smallBorder,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        border: OutlineInputBorder(
          borderRadius: AppShape.smallRadius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppShape.smallRadius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppShape.smallRadius,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppShape.smallRadius,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppShape.smallRadius,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppShape.smallRadius,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(
            AppSpacing.androidMinTapTarget,
            AppSpacing.androidMinTapTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            AppSpacing.androidMinTapTarget,
            AppSpacing.androidMinTapTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: AppShape.dialogBorder,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        modalBackgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: AppShape.sheetBorder,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: colorScheme.secondaryContainer,
        surfaceTintColor: Colors.transparent,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        indicatorColor: colorScheme.secondaryContainer,
        selectedIconTheme: IconThemeData(
          color: colorScheme.onSecondaryContainer,
        ),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
