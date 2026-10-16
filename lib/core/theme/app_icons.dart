import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bulk_tempo/core/platform/presentation_capabilities.dart';

/// Semantic icon identifiers decoupled from concrete Material/Cupertino glyphs.
enum AppIcon {
  home,
  weight,
  workout,
  profile,
  addMeasurement,
  edit,
  delete,
  retry,
  achievement,
  close,
  calendar,
  apiKey,
  link,
  language,
  logout,
  visibility,
  visibilityOff,
  error,
  warning,
  info,
  check,
  target,
  chevronRight,
}

/// Resolves [AppIcon] identifiers to platform-appropriate [IconData] or Apple
/// SF Symbol names.
abstract final class AppIcons {
  /// Standard visible icon size (`24px`), independent of minimum hit target.
  static const double normalSize = 24.0;

  /// Compact visible icon size (`20px`) for badges, inline banners, and dense rows.
  static const double compactSize = 20.0;

  /// Resolves the appropriate [IconData] for the ambient platform in [context].
  static IconData resolve(
    BuildContext context,
    AppIcon icon, {
    bool selected = false,
  }) {
    final capabilities = PresentationCapabilities.resolve(context);
    if (capabilities.targetPlatform == TargetPlatform.iOS) {
      return cupertino(icon, selected: selected);
    }
    return material(icon, selected: selected);
  }

  /// Resolves the Material 3 [IconData] for [icon].
  static IconData material(AppIcon icon, {bool selected = false}) {
    switch (icon) {
      case AppIcon.home:
        return selected ? Icons.dashboard : Icons.dashboard_outlined;
      case AppIcon.weight:
        return selected ? Icons.monitor_weight : Icons.monitor_weight_outlined;
      case AppIcon.workout:
        return selected ? Icons.fitness_center : Icons.fitness_center_outlined;
      case AppIcon.profile:
        return selected ? Icons.person : Icons.person_outline;
      case AppIcon.addMeasurement:
        return Icons.add;
      case AppIcon.edit:
        return selected ? Icons.edit : Icons.edit_outlined;
      case AppIcon.delete:
        return selected ? Icons.delete : Icons.delete_outline;
      case AppIcon.retry:
        return Icons.refresh;
      case AppIcon.achievement:
        return selected ? Icons.emoji_events : Icons.emoji_events_outlined;
      case AppIcon.close:
        return Icons.close;
      case AppIcon.calendar:
        return selected ? Icons.calendar_today : Icons.calendar_today_outlined;
      case AppIcon.apiKey:
        return selected ? Icons.vpn_key : Icons.vpn_key_outlined;
      case AppIcon.link:
        return Icons.open_in_new;
      case AppIcon.language:
        return Icons.language;
      case AppIcon.logout:
        return Icons.logout;
      case AppIcon.visibility:
        return selected ? Icons.visibility : Icons.visibility_outlined;
      case AppIcon.visibilityOff:
        return selected ? Icons.visibility_off : Icons.visibility_off_outlined;
      case AppIcon.error:
        return selected ? Icons.error : Icons.error_outline;
      case AppIcon.warning:
        return selected ? Icons.warning_amber : Icons.warning_amber_rounded;
      case AppIcon.info:
        return selected ? Icons.info : Icons.info_outline;
      case AppIcon.check:
        return Icons.check_circle_outline;
      case AppIcon.target:
        return Icons.track_changes;
      case AppIcon.chevronRight:
        return Icons.chevron_right;
    }
  }

  /// Resolves the Cupertino [IconData] for [icon].
  static IconData cupertino(AppIcon icon, {bool selected = false}) {
    switch (icon) {
      case AppIcon.home:
        return selected
            ? CupertinoIcons.square_grid_2x2_fill
            : CupertinoIcons.square_grid_2x2;
      case AppIcon.weight:
        return selected
            ? CupertinoIcons.chart_bar_alt_fill
            : CupertinoIcons.chart_bar;
      case AppIcon.workout:
        return selected ? CupertinoIcons.flame_fill : CupertinoIcons.flame;
      case AppIcon.profile:
        return selected ? CupertinoIcons.person_fill : CupertinoIcons.person;
      case AppIcon.addMeasurement:
        return CupertinoIcons.add;
      case AppIcon.edit:
        return CupertinoIcons.pencil;
      case AppIcon.delete:
        return selected ? CupertinoIcons.trash_fill : CupertinoIcons.trash;
      case AppIcon.retry:
        return CupertinoIcons.refresh;
      case AppIcon.achievement:
        return selected ? CupertinoIcons.rosette : CupertinoIcons.star_fill;
      case AppIcon.close:
        return CupertinoIcons.xmark;
      case AppIcon.calendar:
        return CupertinoIcons.calendar;
      case AppIcon.apiKey:
        return CupertinoIcons.lock_shield;
      case AppIcon.link:
        return CupertinoIcons.arrow_up_right_square;
      case AppIcon.language:
        return CupertinoIcons.globe;
      case AppIcon.logout:
        return CupertinoIcons.square_arrow_right;
      case AppIcon.visibility:
        return selected ? CupertinoIcons.eye_fill : CupertinoIcons.eye;
      case AppIcon.visibilityOff:
        return selected
            ? CupertinoIcons.eye_slash_fill
            : CupertinoIcons.eye_slash;
      case AppIcon.error:
        return selected
            ? CupertinoIcons.exclamationmark_circle_fill
            : CupertinoIcons.exclamationmark_circle;
      case AppIcon.warning:
        return selected
            ? CupertinoIcons.exclamationmark_triangle_fill
            : CupertinoIcons.exclamationmark_triangle;
      case AppIcon.info:
        return selected
            ? CupertinoIcons.info_circle_fill
            : CupertinoIcons.info_circle;
      case AppIcon.check:
        return selected
            ? CupertinoIcons.check_mark_circled_solid
            : CupertinoIcons.check_mark_circled;
      case AppIcon.target:
        return CupertinoIcons.scope;
      case AppIcon.chevronRight:
        return CupertinoIcons.chevron_right;
    }
  }

  /// Resolves the Apple SF Symbol name for native iOS controls (`adaptive_platform_ui`).
  static String sfSymbol(AppIcon icon, {bool selected = false}) {
    switch (icon) {
      case AppIcon.home:
        return selected ? 'square.grid.2x2.fill' : 'square.grid.2x2';
      case AppIcon.weight:
        return selected ? 'scalemass.fill' : 'scalemass';
      case AppIcon.workout:
        return selected ? 'dumbbell.fill' : 'dumbbell';
      case AppIcon.profile:
        return selected ? 'person.fill' : 'person';
      case AppIcon.addMeasurement:
        return 'plus';
      case AppIcon.edit:
        return 'pencil';
      case AppIcon.delete:
        return selected ? 'trash.fill' : 'trash';
      case AppIcon.retry:
        return 'arrow.clockwise';
      case AppIcon.achievement:
        return selected ? 'trophy.fill' : 'trophy';
      case AppIcon.close:
        return 'xmark';
      case AppIcon.calendar:
        return 'calendar';
      case AppIcon.apiKey:
        return selected ? 'key.fill' : 'key';
      case AppIcon.link:
        return 'arrow.up.right.square';
      case AppIcon.language:
        return 'globe';
      case AppIcon.logout:
        return 'rectangle.portrait.and.arrow.right';
      case AppIcon.visibility:
        return selected ? 'eye.fill' : 'eye';
      case AppIcon.visibilityOff:
        return selected ? 'eye.slash.fill' : 'eye.slash';
      case AppIcon.error:
        return selected
            ? 'exclamationmark.circle.fill'
            : 'exclamationmark.circle';
      case AppIcon.warning:
        return selected
            ? 'exclamationmark.triangle.fill'
            : 'exclamationmark.triangle';
      case AppIcon.info:
        return selected ? 'info.circle.fill' : 'info.circle';
      case AppIcon.check:
        return selected ? 'checkmark.circle.fill' : 'checkmark.circle';
      case AppIcon.target:
        return 'scope';
      case AppIcon.chevronRight:
        return 'chevron.right';
    }
  }
}
