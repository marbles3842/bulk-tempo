import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bulk_tempo/core/platform/os_version_probe.dart';

part 'presentation_capabilities.freezed.dart';

/// Platform rendering tier selected by [PresentationCapabilities].
enum AdaptivePlatformMode {
  /// Material 3 controls and navigation (Android, Web, desktop fallbacks).
  material,

  /// Classic opaque Cupertino controls and bars (iOS 15–25, web/test iOS previews,
  /// or iOS 26+ when Reduce Transparency is enabled).
  cupertinoClassic,

  /// Native iOS 26+ Liquid Glass chrome via `adaptive_platform_ui` when native
  /// UIKit platform views are supported and Reduce Transparency is off.
  cupertinoLiquidGlass,
}

/// Immutable value object encapsulating platform, OS version, and accessibility
/// capabilities so shared widgets never inspect `dart:io` directly.
@freezed
abstract class PresentationCapabilities with _$PresentationCapabilities {
  const PresentationCapabilities._();

  const factory PresentationCapabilities({
    required TargetPlatform targetPlatform,
    int? iosMajorVersion,
    @Default(false) bool isWeb,
    @Default(false) bool reduceMotion,
    @Default(false) bool reduceTransparency,
    @Default(false) bool highContrast,
    @Default(false) bool supportsNativeIosViews,
  }) = _PresentationCapabilities;

  /// True when targeting iOS outside a web browser.
  bool get isIos => !isWeb && targetPlatform == TargetPlatform.iOS;

  /// True when the parsed iOS major version is 26 or newer.
  bool get isIos26OrNewer => (iosMajorVersion ?? 0) >= 26;

  /// Resolves the 3-tier adaptive rendering mode.
  AdaptivePlatformMode get platformMode {
    if (targetPlatform != TargetPlatform.iOS) {
      return AdaptivePlatformMode.material;
    }
    if (isIos26OrNewer && supportsNativeIosViews && !reduceTransparency) {
      return AdaptivePlatformMode.cupertinoLiquidGlass;
    }
    return AdaptivePlatformMode.cupertinoClassic;
  }

  /// Extracts the major iOS version integer from strings such as
  /// `'Version 26.0 (Build 23A344)'`, `'iOS 18.4'`, or `'26.1'`.
  ///
  /// Returns `null` when the version cannot be parsed.
  static int? parseIosMajorVersion(String operatingSystemVersion) {
    final trimmed = operatingSystemVersion.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final match = RegExp(
      r'(?:(?:version|ios|iphone\s+os)\s+(\d+)|^(\d+)(?:\.\d+|$))',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (match == null) {
      return null;
    }
    final rawMajor = match.group(1) ?? match.group(2) ?? '';
    final parsed = int.tryParse(rawMajor);
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  /// Resolves capabilities for the given [context], merging any explicit
  /// [override] or ambient [presentationCapabilitiesOverrideProvider] with
  /// live [Theme], [MediaQuery], and [AccessibilityFeatures] signals.
  static PresentationCapabilities resolve(
    BuildContext context, {
    PresentationCapabilities? override,
  }) {
    var effectiveOverride = override;
    if (effectiveOverride == null &&
        context.getInheritedWidgetOfExactType<UncontrolledProviderScope>() !=
            null) {
      final container = ProviderScope.containerOf(context, listen: false);
      effectiveOverride = container.read(
        presentationCapabilitiesOverrideProvider,
      );
    }

    final dispatcherFeatures =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
    final mediaQuery = MediaQuery.maybeOf(context);
    final ambientReduceMotion =
        (mediaQuery?.disableAnimations ?? false) ||
        dispatcherFeatures.reduceMotion;
    final ambientHighContrast =
        (mediaQuery?.highContrast ?? false) || dispatcherFeatures.highContrast;

    if (effectiveOverride != null) {
      return effectiveOverride.copyWith(
        reduceMotion: effectiveOverride.reduceMotion || ambientReduceMotion,
        highContrast: effectiveOverride.highContrast || ambientHighContrast,
      );
    }

    final themePlatform = Theme.of(context).platform;
    final isRealIosRuntime = !kIsWeb && isNativeIosRuntime();

    final iosVersion = (!kIsWeb && themePlatform == TargetPlatform.iOS)
        ? parseIosMajorVersion(currentOperatingSystemVersion())
        : null;

    return PresentationCapabilities(
      targetPlatform: themePlatform,
      iosMajorVersion: iosVersion,
      isWeb: kIsWeb,
      reduceMotion: ambientReduceMotion,
      reduceTransparency: false,
      highContrast: ambientHighContrast,
      supportsNativeIosViews: isRealIosRuntime,
    );
  }
}

/// Optional provider used by tests and Widgetbook to override platform and
/// accessibility capabilities deterministically.
final presentationCapabilitiesOverrideProvider =
    Provider<PresentationCapabilities?>((ref) => null);
