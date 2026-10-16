import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/platform/presentation_capabilities.dart';

import '../../test_helpers/pump_app.dart';

void main() {
  group('PresentationCapabilities.parseIosMajorVersion', () {
    test('extracts major version from standard iOS version strings', () {
      expect(
        PresentationCapabilities.parseIosMajorVersion(
          'Version 26.0 (Build 23A344)',
        ),
        26,
      );
      expect(
        PresentationCapabilities.parseIosMajorVersion(
          'Version 18.4.1 (Build 22E252)',
        ),
        18,
      );
      expect(PresentationCapabilities.parseIosMajorVersion('iOS 18.4'), 18);
      expect(PresentationCapabilities.parseIosMajorVersion('iOS 26'), 26);
      expect(PresentationCapabilities.parseIosMajorVersion('26.1'), 26);
      expect(PresentationCapabilities.parseIosMajorVersion('15.0'), 15);
    });

    test('returns null for unparseable or empty strings', () {
      expect(PresentationCapabilities.parseIosMajorVersion(''), isNull);
      expect(PresentationCapabilities.parseIosMajorVersion('   '), isNull);
      expect(PresentationCapabilities.parseIosMajorVersion('unknown'), isNull);
      expect(
        PresentationCapabilities.parseIosMajorVersion('Build 23A344'),
        isNull,
      );
    });
  });

  group('PresentationCapabilities.platformMode', () {
    test('returns material for Android and non-iOS platforms', () {
      const android = PresentationCapabilities(
        targetPlatform: TargetPlatform.android,
      );
      expect(android.isIos, isFalse);
      expect(android.isIos26OrNewer, isFalse);
      expect(android.platformMode, AdaptivePlatformMode.material);
    });

    test('returns cupertinoClassic on Web even when targetPlatform is iOS', () {
      const webIos = PresentationCapabilities(
        targetPlatform: TargetPlatform.iOS,
        iosMajorVersion: 26,
        isWeb: true,
        supportsNativeIosViews: false,
      );
      expect(webIos.isIos, isFalse);
      expect(webIos.platformMode, AdaptivePlatformMode.cupertinoClassic);
    });

    test('returns cupertinoClassic on iOS 15–25', () {
      for (final version in [15, 16, 17, 18, 25]) {
        final caps = PresentationCapabilities(
          targetPlatform: TargetPlatform.iOS,
          iosMajorVersion: version,
          supportsNativeIosViews: true,
        );
        expect(caps.isIos, isTrue);
        expect(caps.isIos26OrNewer, isFalse);
        expect(caps.platformMode, AdaptivePlatformMode.cupertinoClassic);
      }
    });

    test(
      'returns cupertinoLiquidGlass on iOS 26+ when supportsNativeIosViews is true and reduceTransparency is false',
      () {
        const ios26 = PresentationCapabilities(
          targetPlatform: TargetPlatform.iOS,
          iosMajorVersion: 26,
          supportsNativeIosViews: true,
          reduceTransparency: false,
        );
        expect(ios26.isIos, isTrue);
        expect(ios26.isIos26OrNewer, isTrue);
        expect(ios26.platformMode, AdaptivePlatformMode.cupertinoLiquidGlass);
      },
    );

    test(
      'falls back to cupertinoClassic on iOS 26+ when reduceTransparency is true or supportsNativeIosViews is false',
      () {
        const reducedTransparency = PresentationCapabilities(
          targetPlatform: TargetPlatform.iOS,
          iosMajorVersion: 26,
          supportsNativeIosViews: true,
          reduceTransparency: true,
        );
        expect(
          reducedTransparency.platformMode,
          AdaptivePlatformMode.cupertinoClassic,
        );

        const headlessTestIos26 = PresentationCapabilities(
          targetPlatform: TargetPlatform.iOS,
          iosMajorVersion: 26,
          supportsNativeIosViews: false,
        );
        expect(
          headlessTestIos26.platformMode,
          AdaptivePlatformMode.cupertinoClassic,
        );
      },
    );
  });

  group('PresentationCapabilities.resolve', () {
    testWidgets(
      'merges provider override with ambient MediaQuery accessibility flags',
      (tester) async {
        late PresentationCapabilities resolved;

        await tester.pumpApp(
          MediaQuery(
            data: const MediaQueryData(
              disableAnimations: true,
              highContrast: true,
            ),
            child: Builder(
              builder: (context) {
                resolved = PresentationCapabilities.resolve(context);
                return const SizedBox.shrink();
              },
            ),
          ),
          capabilities: const PresentationCapabilities(
            targetPlatform: TargetPlatform.iOS,
            iosMajorVersion: 26,
            supportsNativeIosViews: true,
          ),
        );

        expect(resolved.targetPlatform, TargetPlatform.iOS);
        expect(resolved.iosMajorVersion, 26);
        expect(resolved.reduceMotion, isTrue);
        expect(resolved.highContrast, isTrue);
        expect(
          resolved.platformMode,
          AdaptivePlatformMode.cupertinoLiquidGlass,
        );
      },
    );
  });
}
