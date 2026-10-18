/// Core design system barrel export.
///
/// Exports presentation capabilities, design tokens (palette, semantic colors,
/// chart theme, spacing, shape, motion, icons, theme), and shared adaptive
/// widgets (buttons, text fields, cards, feedback, dialogs, sheet frames,
/// and navigation shell).
///
/// Encapsulates platform adaptation so feature modules and ViewModels never
/// depend on third-party adaptive libraries directly.
library;

// Platform capabilities & presentation mode
export 'platform/presentation_capabilities.dart';

// Semantic tokens & theme configuration
export 'theme/app_chart_theme.dart';
export 'theme/app_icons.dart';
export 'theme/app_motion.dart';
export 'theme/app_palette.dart';
export 'theme/app_semantic_colors.dart';
export 'theme/app_shape.dart';
export 'theme/app_spacing.dart';
export 'theme/app_theme.dart';

// Shared UI primitives & overlays
export 'widgets/app_button.dart';
export 'widgets/app_card.dart';
export 'widgets/app_dialog.dart';
export 'widgets/app_feedback.dart';
export 'widgets/app_navigation_shell.dart';
export 'widgets/app_sheet_frame.dart';
export 'widgets/app_text_field.dart';
