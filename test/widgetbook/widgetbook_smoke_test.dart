import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:bulk_tempo/core/design_system.dart';
import '../../widgetbook/widgetbook_app.dart';
import '../test_helpers/pump_app.dart';

List<WidgetbookUseCase> _extractUseCases(List<WidgetbookNode> nodes) {
  final useCases = <WidgetbookUseCase>[];
  for (final node in nodes) {
    if (node is WidgetbookUseCase) {
      useCases.add(node);
    } else if (node.children != null) {
      useCases.addAll(_extractUseCases(node.children!));
    }
  }
  return useCases;
}

void main() {
  final allUseCases = _extractUseCases(widgetbookDirectories);

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('BulkTempoWidgetbookApp Root Smoke Test', () {
    testWidgets('mounts without throwing runtime or layout errors', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const BulkTempoWidgetbookApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });

    test('catalog exports all required use case nodes', () {
      expect(allUseCases, isNotEmpty);
      expect(allUseCases.length, greaterThanOrEqualTo(10));
    });
  });

  group('WidgetbookUseCase Smoke Tests Across Configurations', () {
    for (final useCase in allUseCases) {
      final name = '${useCase.parent?.name ?? "Root"} -> ${useCase.name}';

      testWidgets('pumps under (Locale("en"), AppTheme.light()): $name', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final state = WidgetbookState(
          root: WidgetbookRoot(children: widgetbookDirectories),
        );

        await tester.pumpApp(
          WidgetbookScope(
            state: state,
            child: Builder(builder: (context) => useCase.build(context)),
          ),
          locale: const Locale('en'),
          theme: AppTheme.light(),
        );
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
      });

      testWidgets('pumps under (Locale("pl"), AppTheme.dark()): $name', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final state = WidgetbookState(
          root: WidgetbookRoot(children: widgetbookDirectories),
        );

        await tester.pumpApp(
          WidgetbookScope(
            state: state,
            child: Builder(builder: (context) => useCase.build(context)),
          ),
          locale: const Locale('pl'),
          theme: AppTheme.dark(),
        );
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
      });

      testWidgets('pumps under TextScaler.linear(2.0): $name', (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final state = WidgetbookState(
          root: WidgetbookRoot(children: widgetbookDirectories),
        );

        await tester.pumpApp(
          WidgetbookScope(
            state: state,
            child: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2.0)),
                child: useCase.build(context),
              ),
            ),
          ),
          locale: const Locale('en'),
          theme: AppTheme.light(),
        );
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
      'Gain Target kitchen sink covers Material and classic Cupertino fallbacks',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final useCase = allUseCases.singleWhere(
          (item) => item.name == 'Kitchen Sink — State Matrix',
        );
        final state = WidgetbookState(
          root: WidgetbookRoot(children: widgetbookDirectories),
        );

        for (final capabilities in [
          const PresentationCapabilities(
            targetPlatform: TargetPlatform.android,
          ),
          const PresentationCapabilities(
            targetPlatform: TargetPlatform.iOS,
            iosMajorVersion: 18,
            supportsNativeIosViews: false,
          ),
        ]) {
          final platform = capabilities.targetPlatform;
          await tester.pumpApp(
            WidgetbookScope(
              state: state,
              child: Builder(builder: (context) => useCase.build(context)),
            ),
            locale: const Locale('pl'),
            theme: AppTheme.dark().copyWith(platform: platform),
            capabilities: capabilities,
          );
          await tester.pump(const Duration(milliseconds: 50));

          expect(find.text('Nie ustawiono celu'), findsOneWidget);
          expect(find.text('Default / saved'), findsOneWidget);
          expect(find.text('Empty / no target'), findsOneWidget);
          expect(find.text('Loading'), findsOneWidget);
          expect(find.text('Fetch error'), findsOneWidget);
          expect(find.text('Validation error'), findsOneWidget);
          expect(find.text('Disabled / busy'), findsOneWidget);
          expect(find.text('Success feedback'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'Auth Login state matrix covers Material and classic Cupertino fallbacks',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final loginUseCase = allUseCases.singleWhere(
          (item) => item.name == 'Login — State Matrix',
        );
        final state = WidgetbookState(
          root: WidgetbookRoot(children: widgetbookDirectories),
        );

        for (final capabilities in [
          const PresentationCapabilities(
            targetPlatform: TargetPlatform.android,
          ),
          const PresentationCapabilities(
            targetPlatform: TargetPlatform.iOS,
            iosMajorVersion: 18,
            supportsNativeIosViews: false,
          ),
        ]) {
          final platform = capabilities.targetPlatform;

          await tester.pumpApp(
            WidgetbookScope(
              state: state,
              child: Builder(builder: (context) => loginUseCase.build(context)),
            ),
            locale: const Locale('pl'),
            theme: AppTheme.dark().copyWith(platform: platform),
            capabilities: capabilities,
          );
          await tester.pump(const Duration(milliseconds: 50));

          expect(find.text('Default (empty)'), findsOneWidget);
          expect(find.text('Populated (ready)'), findsOneWidget);
          expect(find.text('Validation error'), findsOneWidget);
          expect(find.text('Submission failure'), findsOneWidget);
          expect(find.text('Submitting / busy'), findsOneWidget);
          expect(find.text('Auth stream error'), findsOneWidget);
          expect(find.text('Success feedback'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'Auth Register state matrix covers Material and classic Cupertino fallbacks',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final registerUseCase = allUseCases.singleWhere(
          (item) => item.name == 'Register — State Matrix',
        );
        final state = WidgetbookState(
          root: WidgetbookRoot(children: widgetbookDirectories),
        );

        for (final capabilities in [
          const PresentationCapabilities(
            targetPlatform: TargetPlatform.android,
          ),
          const PresentationCapabilities(
            targetPlatform: TargetPlatform.iOS,
            iosMajorVersion: 18,
            supportsNativeIosViews: false,
          ),
        ]) {
          final platform = capabilities.targetPlatform;

          await tester.pumpApp(
            WidgetbookScope(
              state: state,
              child: Builder(
                builder: (context) => registerUseCase.build(context),
              ),
            ),
            locale: const Locale('pl'),
            theme: AppTheme.dark().copyWith(platform: platform),
            capabilities: capabilities,
          );
          await tester.pump(const Duration(milliseconds: 50));

          expect(find.text('Default (empty)'), findsOneWidget);
          expect(find.text('Populated (ready)'), findsOneWidget);
          expect(find.text('Validation error'), findsOneWidget);
          expect(find.text('Submission failure'), findsOneWidget);
          expect(find.text('Submitting / busy'), findsOneWidget);
          expect(find.text('Auth stream error'), findsOneWidget);
          expect(find.text('Success feedback'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );
  });
}
