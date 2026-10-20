import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/platform/presentation_capabilities.dart';
import 'package:bulk_tempo/core/theme/app_icons.dart';
import 'package:bulk_tempo/core/widgets/app_navigation_shell.dart';

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

  const cupertinoLiquidGlassCaps = PresentationCapabilities(
    targetPlatform: TargetPlatform.iOS,
    iosMajorVersion: 26,
    supportsNativeIosViews: true,
    reduceTransparency: false,
  );

  const testDestinations = [
    AppNavigationDestinationItem(
      key: Key('tab_dashboard'),
      label: 'Dashboard',
      icon: AppIcon.home,
    ),
    AppNavigationDestinationItem(
      key: Key('tab_weight'),
      label: 'Weight',
      icon: AppIcon.weight,
      badgeText: '3',
    ),
    AppNavigationDestinationItem(
      key: Key('tab_workout'),
      label: 'Workout',
      icon: AppIcon.workout,
    ),
    AppNavigationDestinationItem(
      key: Key('tab_profile'),
      label: 'Profile',
      icon: AppIcon.profile,
    ),
  ];

  group('AppNavigationShell - Material (<840px NavigationBar)', () {
    testWidgets(
      'renders AppBar, NavigationBar, destinations, badge, and responds to tab tap',
      (tester) async {
        tester.view.physicalSize = const Size(600, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        var selectedIndex = 0;
        var actionPressed = false;

        await tester.pumpApp(
          AppNavigationShell(
            title: 'BulkTempo',
            destinations: testDestinations,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => selectedIndex = index,
            toolbarActions: [
              AppToolbarAction(
                key: const Key('toolbar_settings'),
                tooltip: 'Settings',
                icon: AppIcon.link,
                onPressed: () => actionPressed = true,
              ),
            ],
            floatingActionButton: FloatingActionButton(
              key: const Key('test_fab'),
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
            body: const Center(child: Text('Body Content')),
          ),
          capabilities: materialCaps,
        );

        expect(find.text('BulkTempo'), findsOneWidget);
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byType(NavigationRail), findsNothing);
        expect(find.byKey(const Key('test_fab')), findsOneWidget);
        expect(find.text('Body Content'), findsOneWidget);

        // Verify badge
        expect(find.text('3'), findsOneWidget);

        // Verify toolbar action
        expect(find.byKey(const Key('toolbar_settings')), findsOneWidget);
        await tester.tap(find.byKey(const Key('toolbar_settings')));
        expect(actionPressed, isTrue);

        // Verify destination key and tap callback
        expect(find.byKey(const Key('tab_weight')), findsOneWidget);
        await tester.tap(find.byKey(const Key('tab_weight')));
        await tester.pump();
        expect(selectedIndex, 1);
      },
    );
  });

  group('AppNavigationShell - Material (>=840px NavigationRail)', () {
    testWidgets(
      'switches to NavigationRail on expanded width and handles taps',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        var selectedIndex = 0;

        await tester.pumpApp(
          AppNavigationShell(
            title: 'BulkTempo Wide',
            destinations: testDestinations,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => selectedIndex = index,
            body: const Text('Expanded Content'),
          ),
          capabilities: materialCaps,
        );

        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.text('BulkTempo Wide'), findsOneWidget);
        expect(find.text('Expanded Content'), findsOneWidget);

        // Verify destination key in rail
        expect(find.byKey(const Key('tab_workout')), findsOneWidget);
        await tester.tap(find.byKey(const Key('tab_workout')));
        await tester.pump();
        expect(selectedIndex, 2);
      },
    );
  });

  group('AppNavigationShell - Cupertino Classic dispatch', () {
    testWidgets(
      'renders CupertinoNavigationBar, CupertinoTabBar, and handles tab selection',
      (tester) async {
        var selectedIndex = 0;
        var logoutTapped = false;

        await tester.pumpApp(
          AppNavigationShell(
            title: 'Cupertino Title',
            destinations: testDestinations,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => selectedIndex = index,
            toolbarActions: [
              AppToolbarAction(
                key: const Key('action_logout'),
                tooltip: 'Log out',
                icon: AppIcon.logout,
                onPressed: () => logoutTapped = true,
              ),
            ],
            floatingActionButton: FloatingActionButton(
              key: const Key('cupe_fab'),
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
            body: const Text('Cupertino Content'),
          ),
          capabilities: cupertinoClassicCaps,
        );

        expect(find.byType(CupertinoNavigationBar), findsOneWidget);
        expect(find.byType(CupertinoTabBar), findsOneWidget);
        expect(find.text('Cupertino Title'), findsOneWidget);
        expect(find.text('Cupertino Content'), findsOneWidget);
        expect(find.byKey(const Key('cupe_fab')), findsOneWidget);

        // Verify toolbar action
        expect(find.byKey(const Key('action_logout')), findsOneWidget);
        await tester.tap(find.byKey(const Key('action_logout')));
        expect(logoutTapped, isTrue);

        // Verify tab destination selection
        expect(find.byKey(const Key('tab_profile')), findsOneWidget);
        await tester.tap(find.byKey(const Key('tab_profile')));
        await tester.pump();
        expect(selectedIndex, 3);
      },
    );
  });

  group('AppNavigationShell - Cupertino Liquid Glass dispatch', () {
    testWidgets(
      'renders AdaptiveScaffold with blur enabled and omits disabled toolbar actions',
      (tester) async {
        await tester.pumpApp(
          AppNavigationShell(
            title: 'Liquid Glass Shell',
            destinations: testDestinations,
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            toolbarActions: [
              AppToolbarAction(
                tooltip: 'Enabled Action',
                icon: AppIcon.addMeasurement,
                onPressed: () {},
              ),
              const AppToolbarAction(
                tooltip: 'Disabled Action',
                icon: AppIcon.delete,
                onPressed: null,
              ),
            ],
            body: const Text('Liquid Content'),
          ),
          capabilities: cupertinoLiquidGlassCaps,
        );

        expect(find.byType(AdaptiveScaffold), findsOneWidget);
        final scaffold = tester.widget<AdaptiveScaffold>(
          find.byType(AdaptiveScaffold),
        );
        expect(scaffold.enableBlur, isTrue);
        expect(scaffold.appBar?.useNativeToolbar, isTrue);
        expect(scaffold.appBar?.actions?.length, 1);
        expect(scaffold.appBar?.actions?.first.label, 'Enabled Action');
        expect(scaffold.bottomNavigationBar?.items?.length, 4);
      },
    );
  });
}
