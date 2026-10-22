/// Fixed logical-pixel spacing scale, layout aliases, responsive breakpoints,
/// and accessible minimum tap-target dimensions.
abstract final class AppSpacing {
  // ---------------------------------------------------------------------------
  // Reference scale (4-unit rhythm)
  // ---------------------------------------------------------------------------

  static const double space0 = 0.0;
  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0;
  static const double space6 = 24.0;
  static const double space8 = 32.0;
  static const double space12 = 48.0;

  // ---------------------------------------------------------------------------
  // Semantic layout aliases
  // ---------------------------------------------------------------------------

  static const double inlineGap = space2;
  static const double relatedGap = space3;
  static const double cardPadding = space4;
  static const double sectionGap = space6;
  static const double pageInsetCompact = space4;
  static const double pageInsetWide = space6;
  static const double sheetInset = space6;

  // ---------------------------------------------------------------------------
  // Responsive layout breakpoints & content width caps
  // ---------------------------------------------------------------------------

  static const double compactBreakpoint = 600.0;
  static const double expandedBreakpoint = 840.0;
  static const double formMaxWidth = 480.0;
  static const double dashboardMaxWidth = 1120.0;
  static const double stackedSummaryBreakpoint = 420.0;
  static const double enlargedTextScaleThreshold = 1.4;

  // ---------------------------------------------------------------------------
  // Accessible minimum tap-target dimensions
  // ---------------------------------------------------------------------------

  static const double androidMinTapTarget = 48.0;
  static const double iosMinTapTarget = 44.0;
}
