import 'package:flutter/material.dart';

/// Shared border-radius tokens and prebuilt shape helpers.
abstract final class AppShape {
  /// Compact radius (`8px`) for status badges, inline banners, and inputs.
  static const double small = 8.0;

  /// Content card radius (`16px`).
  static const double card = 16.0;

  /// Modal bottom sheet and dialog corner radius (`24px`).
  static const double sheet = 24.0;

  static const BorderRadius smallRadius = BorderRadius.all(
    Radius.circular(small),
  );

  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(card),
  );

  static const BorderRadius sheetTopRadius = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );

  static const BorderRadius sheetRadius = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );

  static const BorderRadius dialogRadius = BorderRadius.all(
    Radius.circular(sheet),
  );

  static const RoundedRectangleBorder smallBorder = RoundedRectangleBorder(
    borderRadius: smallRadius,
  );

  static const RoundedRectangleBorder cardBorder = RoundedRectangleBorder(
    borderRadius: cardRadius,
  );

  static const RoundedRectangleBorder sheetBorder = RoundedRectangleBorder(
    borderRadius: sheetTopRadius,
  );

  static const RoundedRectangleBorder dialogBorder = RoundedRectangleBorder(
    borderRadius: dialogRadius,
  );
}
