import 'package:flutter/material.dart';
import 'package:bulk_tempo/core/platform/presentation_capabilities.dart';

/// App-owned motion tokens and accessibility-aware duration resolution.
abstract final class AppMotion {
  /// Small state-feedback transition duration (`120 ms`).
  static const Duration stateFeedbackDuration = Duration(milliseconds: 120);

  /// Content transition duration (`200 ms`).
  static const Duration contentTransitionDuration = Duration(milliseconds: 200);

  /// Standard curve for app-owned state and content transitions.
  static const Curve standardCurve = Curves.easeOutCubic;

  /// Returns [Duration.zero] when Reduce Motion / Disable Animations is active
  /// in [context], or [standard] otherwise.
  static Duration effectiveDuration(BuildContext context, Duration standard) {
    final capabilities = PresentationCapabilities.resolve(context);
    if (capabilities.reduceMotion) {
      return Duration.zero;
    }
    return standard;
  }
}
