import 'package:flutter/material.dart';

/// Reference color palette tokens for Bulk Tempo.
///
/// Standard UI roles are generated via `ColorScheme.fromSeed` using [seedColor]
/// and `DynamicSchemeVariant.tonalSpot`. Additional semantic status and
/// achievement pairs are defined here as opaque foreground/container tokens.
abstract final class AppPalette {
  /// Provisional brand seed (`#673AB7`).
  static const Color seedColor = Color(0xFF673AB7);

  // ---------------------------------------------------------------------------
  // Light semantic pairs (WCAG contrast >= 4.5:1)
  // ---------------------------------------------------------------------------

  static const Color onSuccessContainerLight = Color(0xFF146C43);
  static const Color successContainerLight = Color(0xFFD9F2E3);

  static const Color onWarningContainerLight = Color(0xFF7A4D00);
  static const Color warningContainerLight = Color(0xFFFFEDC2);

  static const Color onInfoContainerLight = Color(0xFF175B9B);
  static const Color infoContainerLight = Color(0xFFDFECFF);

  static const Color onAchievementContainerLight = Color(0xFF92400E);
  static const Color achievementContainerLight = Color(0xFFFEF3C7);
  static const Color achievementBorderLight = Color(0xFFB45309);

  // ---------------------------------------------------------------------------
  // Dark semantic pairs (WCAG contrast >= 4.5:1)
  // ---------------------------------------------------------------------------

  static const Color onSuccessContainerDark = Color(0xFFA0D4B4);
  static const Color successContainerDark = Color(0xFF113826);

  static const Color onWarningContainerDark = Color(0xFFFFD58A);
  static const Color warningContainerDark = Color(0xFF402D08);

  static const Color onInfoContainerDark = Color(0xFFA8C8FF);
  static const Color infoContainerDark = Color(0xFF132F50);

  static const Color onAchievementContainerDark = Color(0xFFFCD34D);
  static const Color achievementContainerDark = Color(0xFF452B0B);
  static const Color achievementBorderDark = Color(0xFFF59E0B);

  // ---------------------------------------------------------------------------
  // High-contrast light semantic pairs (WCAG AAA contrast >= 7.0:1)
  // ---------------------------------------------------------------------------

  static const Color onSuccessContainerHighContrastLight = Color(0xFF0A4D2C);
  static const Color successContainerHighContrastLight = Color(0xFFE6F7ED);

  static const Color onWarningContainerHighContrastLight = Color(0xFF523300);
  static const Color warningContainerHighContrastLight = Color(0xFFFFF3D6);

  static const Color onInfoContainerHighContrastLight = Color(0xFF0B3D6E);
  static const Color infoContainerHighContrastLight = Color(0xFFEBF3FF);

  static const Color onAchievementContainerHighContrastLight = Color(
    0xFF6B2D06,
  );
  static const Color achievementContainerHighContrastLight = Color(0xFFFFF8DB);
  static const Color achievementBorderHighContrastLight = Color(0xFF6B2D06);

  // ---------------------------------------------------------------------------
  // High-contrast dark semantic pairs (WCAG AAA contrast >= 7.0:1)
  // ---------------------------------------------------------------------------

  static const Color onSuccessContainerHighContrastDark = Color(0xFFC4F5D5);
  static const Color successContainerHighContrastDark = Color(0xFF092417);

  static const Color onWarningContainerHighContrastDark = Color(0xFFFFE4B3);
  static const Color warningContainerHighContrastDark = Color(0xFF261A03);

  static const Color onInfoContainerHighContrastDark = Color(0xFFCFE2FF);
  static const Color infoContainerHighContrastDark = Color(0xFF0A1B30);

  static const Color onAchievementContainerHighContrastDark = Color(0xFFFDE68A);
  static const Color achievementContainerHighContrastDark = Color(0xFF291804);
  static const Color achievementBorderHighContrastDark = Color(0xFFFDE68A);
}
