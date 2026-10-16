import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bulk_tempo/core/theme/app_palette.dart';

part 'app_semantic_colors.freezed.dart';

/// Immutable [ThemeExtension] exposing opaque semantic status and achievement
/// foreground/container pairs.
@Freezed(copyWith: false)
abstract class AppSemanticColors extends ThemeExtension<AppSemanticColors>
    with _$AppSemanticColors {
  const AppSemanticColors._();

  const factory AppSemanticColors({
    required Color successContainer,
    required Color onSuccessContainer,
    required Color warningContainer,
    required Color onWarningContainer,
    required Color infoContainer,
    required Color onInfoContainer,
    required Color achievementContainer,
    required Color onAchievementContainer,
    required Color achievementBorder,
  }) = _AppSemanticColors;

  factory AppSemanticColors.light() => const AppSemanticColors(
    successContainer: AppPalette.successContainerLight,
    onSuccessContainer: AppPalette.onSuccessContainerLight,
    warningContainer: AppPalette.warningContainerLight,
    onWarningContainer: AppPalette.onWarningContainerLight,
    infoContainer: AppPalette.infoContainerLight,
    onInfoContainer: AppPalette.onInfoContainerLight,
    achievementContainer: AppPalette.achievementContainerLight,
    onAchievementContainer: AppPalette.onAchievementContainerLight,
    achievementBorder: AppPalette.achievementBorderLight,
  );

  factory AppSemanticColors.dark() => const AppSemanticColors(
    successContainer: AppPalette.successContainerDark,
    onSuccessContainer: AppPalette.onSuccessContainerDark,
    warningContainer: AppPalette.warningContainerDark,
    onWarningContainer: AppPalette.onWarningContainerDark,
    infoContainer: AppPalette.infoContainerDark,
    onInfoContainer: AppPalette.onInfoContainerDark,
    achievementContainer: AppPalette.achievementContainerDark,
    onAchievementContainer: AppPalette.onAchievementContainerDark,
    achievementBorder: AppPalette.achievementBorderDark,
  );

  factory AppSemanticColors.highContrastLight() => const AppSemanticColors(
    successContainer: AppPalette.successContainerHighContrastLight,
    onSuccessContainer: AppPalette.onSuccessContainerHighContrastLight,
    warningContainer: AppPalette.warningContainerHighContrastLight,
    onWarningContainer: AppPalette.onWarningContainerHighContrastLight,
    infoContainer: AppPalette.infoContainerHighContrastLight,
    onInfoContainer: AppPalette.onInfoContainerHighContrastLight,
    achievementContainer: AppPalette.achievementContainerHighContrastLight,
    onAchievementContainer: AppPalette.onAchievementContainerHighContrastLight,
    achievementBorder: AppPalette.achievementBorderHighContrastLight,
  );

  factory AppSemanticColors.highContrastDark() => const AppSemanticColors(
    successContainer: AppPalette.successContainerHighContrastDark,
    onSuccessContainer: AppPalette.onSuccessContainerHighContrastDark,
    warningContainer: AppPalette.warningContainerHighContrastDark,
    onWarningContainer: AppPalette.onWarningContainerHighContrastDark,
    infoContainer: AppPalette.infoContainerHighContrastDark,
    onInfoContainer: AppPalette.onInfoContainerHighContrastDark,
    achievementContainer: AppPalette.achievementContainerHighContrastDark,
    onAchievementContainer: AppPalette.onAchievementContainerHighContrastDark,
    achievementBorder: AppPalette.achievementBorderHighContrastDark,
  );

  /// Resolves [AppSemanticColors] from [context], falling back to the default
  /// light or dark instance matching `Theme.of(context).brightness` if not
  /// registered in an isolated test harness.
  static AppSemanticColors of(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<AppSemanticColors>();
    if (extension != null) {
      return extension;
    }
    return theme.brightness == Brightness.dark
        ? AppSemanticColors.dark()
        : AppSemanticColors.light();
  }

  @override
  AppSemanticColors copyWith({
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? achievementContainer,
    Color? onAchievementContainer,
    Color? achievementBorder,
  }) {
    return AppSemanticColors(
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      achievementContainer: achievementContainer ?? this.achievementContainer,
      onAchievementContainer:
          onAchievementContainer ?? this.onAchievementContainer,
      achievementBorder: achievementBorder ?? this.achievementBorder,
    );
  }

  @override
  AppSemanticColors lerp(
    covariant ThemeExtension<AppSemanticColors>? other,
    double t,
  ) {
    if (other is! AppSemanticColors) {
      return this;
    }
    return AppSemanticColors(
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      achievementContainer: Color.lerp(
        achievementContainer,
        other.achievementContainer,
        t,
      )!,
      onAchievementContainer: Color.lerp(
        onAchievementContainer,
        other.onAchievementContainer,
        t,
      )!,
      achievementBorder: Color.lerp(
        achievementBorder,
        other.achievementBorder,
        t,
      )!,
    );
  }
}
