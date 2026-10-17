import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/platform/presentation_capabilities.dart';
import 'package:bulk_tempo/core/theme/app_icons.dart';
import 'package:bulk_tempo/core/widgets/app_button.dart';
import 'package:bulk_tempo/core/widgets/app_card.dart';
import 'package:bulk_tempo/core/widgets/app_feedback.dart';
import 'package:bulk_tempo/core/widgets/app_text_field.dart';

import '../../test_helpers/pump_app.dart';

void main() {
  const materialCaps = PresentationCapabilities(
    targetPlatform: TargetPlatform.android,
  );

  const cupertinoClassicCaps = PresentationCapabilities(
    targetPlatform: TargetPlatform.iOS,
    iosMajorVersion: 18,
    supportsNativeIosViews: true,
  );

  group('Accessibility Guidelines - Tap Targets & Labels', () {
    testWidgets(
      'AppButton satisfies Android tap target and labeled guidelines',
      (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await tester.pumpApp(
            Center(
              child: AppButton(label: 'Zapisz', onPressed: () {}),
            ),
            capabilities: materialCaps,
          );

          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets('AppButton satisfies iOS tap target and labeled guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpApp(
          Center(
            child: AppButton(label: 'Gotowe', onPressed: () {}),
          ),
          capabilities: cupertinoClassicCaps,
        );

        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      } finally {
        handle.dispose();
      }
    });

    testWidgets(
      'AppCard with onTap satisfies tap target and labeled guidelines',
      (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await tester.pumpApp(
            Center(
              child: AppCard(
                title: 'Trening',
                onTap: () {},
                child: const Text('Szczegóły treningu'),
              ),
            ),
            capabilities: materialCaps,
          );

          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets(
      'AppFeedbackBanner with action satisfies tap target and labeled guidelines',
      (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await tester.pumpApp(
            Center(
              child: AppFeedbackBanner(
                message: 'Błąd synchronizacji',
                tone: AppFeedbackTone.error,
                actionLabel: 'Ponów',
                onAction: () {},
              ),
            ),
            capabilities: materialCaps,
          );

          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        } finally {
          handle.dispose();
        }
      },
    );
  });

  group('2.0x TextScaler Reflow on Narrow 320px Screen with Polish Strings', () {
    testWidgets(
      'AppButton reflows cleanly without overflow at 2.0x text scale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpApp(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 600),
              textScaler: TextScaler.linear(2.0),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppButton(
                      label: 'Zapisz nowy pomiar wagi',
                      icon: AppIcon.addMeasurement,
                      onPressed: () {},
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Usuń niepoprawny wpis z historii',
                      variant: AppButtonVariant.destructive,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
          locale: const Locale('pl'),
          capabilities: materialCaps,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Zapisz nowy pomiar wagi'), findsOneWidget);
      },
    );

    testWidgets(
      'AppTextField reflows cleanly without overflow at 2.0x text scale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpApp(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 600),
              textScaler: TextScaler.linear(2.0),
            ),
            child: const SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    AppTextField(
                      label: 'Docelowe tempo przyrostu masy ciała',
                      hint: 'np. 0.35',
                      helperText: 'Zalecane tempo to 0.25 - 0.5 kg na tydzień',
                      suffixText: 'kg/tydz.',
                      prefixIcon: AppIcon.weight,
                    ),
                    SizedBox(height: 16),
                    AppTextField(
                      label: 'Klucz API serwisu Hevy',
                      errorText: 'Podany klucz jest nieprawidłowy lub wygasł',
                      prefixIcon: AppIcon.apiKey,
                    ),
                  ],
                ),
              ),
            ),
          ),
          locale: const Locale('pl'),
          capabilities: materialCaps,
        );

        expect(tester.takeException(), isNull);
        expect(
          find.text('Docelowe tempo przyrostu masy ciała'),
          findsOneWidget,
        );
      },
    );

    testWidgets('AppCard reflows cleanly without overflow at 2.0x text scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpApp(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 900),
            textScaler: TextScaler.linear(2.0),
          ),
          child: const SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: AppCard(
                title: 'Tygodniowy przegląd postępów',
                subtitle: 'Ostatnia aktualizacja wczoraj o 22:30',
                leadingIcon: AppIcon.workout,
                headerTrailing: AppStatusBadge(
                  label: 'Nowy rekord',
                  tone: AppFeedbackTone.achievement,
                ),
                child: Text(
                  'Szczegółowe podsumowanie całego tygodnia treningowego.',
                ),
              ),
            ),
          ),
        ),
        locale: const Locale('pl'),
        capabilities: materialCaps,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Tygodniowy przegląd postępów'), findsOneWidget);
      expect(find.text('Nowy rekord'), findsOneWidget);
    });

    testWidgets(
      'AppFeedback reflows cleanly without overflow at 2.0x text scale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpApp(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 900),
              textScaler: TextScaler.linear(2.0),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AppFeedbackBanner(
                  message:
                      'Wystąpił problem z połączeniem sieciowym podczas synchronizacji.',
                  tone: AppFeedbackTone.warning,
                  actionLabel: 'Ponów',
                  onAction: () {},
                ),
              ),
            ),
          ),
          locale: const Locale('pl'),
          capabilities: materialCaps,
        );

        expect(tester.takeException(), isNull);
      },
    );
  });
}
