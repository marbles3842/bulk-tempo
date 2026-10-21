import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/design_system.dart';
import 'package:bulk_tempo/features/dashboard/domain/calculators/weekly_progress_calculator.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/weekly_progress_overview_entity.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_state.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/dashboard_card_shell.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/dashboard_kpi_row.dart';

import '../../../../test_helpers/pump_app.dart';

void main() {
  const materialCaps = PresentationCapabilities(
    targetPlatform: TargetPlatform.android,
  );

  const cupertinoClassicCaps = PresentationCapabilities(
    targetPlatform: TargetPlatform.iOS,
    iosMajorVersion: 18,
    supportsNativeIosViews: false,
  );

  const cupertinoLiquidGlassCaps = PresentationCapabilities(
    targetPlatform: TargetPlatform.iOS,
    iosMajorVersion: 26,
    supportsNativeIosViews: true,
    reduceTransparency: false,
  );

  final sampleNow = DateTime.utc(2026, 10, 14, 12);

  WeeklyProgressOverviewEntity buildEmptyOverview() {
    return WeeklyProgressCalculator.calculate(
      allWeightSummaries: const [],
      workoutSummaries: const [],
      now: sampleNow,
    );
  }

  WeeklyProgressOverviewEntity buildPopulatedOverview({
    double? currentPaceKgPerWeek = 0.35,
    double? latestAverageWeightKg = 82.40,
    int latestWeekLoggedDays = 7,
    bool isLatestWeekCurrentWeek = true,
    bool isLatestWeekIncomplete = false,
    double? totalGainKg = 2.10,
    int currentWeekWorkoutCount = 4,
    int loggedWeightWeeksCount = 6,
  }) {
    final base = buildEmptyOverview();
    return base.copyWith(
      currentPaceKgPerWeek: currentPaceKgPerWeek,
      latestAverageWeightKg: latestAverageWeightKg,
      latestWeekStartIso: '2026-10-12',
      latestWeekStartMonday: DateTime.utc(2026, 10, 12),
      latestWeekEndSunday: DateTime.utc(2026, 10, 18),
      latestWeekLoggedDays: latestWeekLoggedDays,
      isLatestWeekCurrentWeek: isLatestWeekCurrentWeek,
      isLatestWeekIncomplete: isLatestWeekIncomplete,
      totalGainKg: totalGainKg,
      currentWeekWorkoutCount: currentWeekWorkoutCount,
      loggedWeightWeeksCount: loggedWeightWeeksCount,
    );
  }

  group('DashboardCardShell', () {
    testWidgets(
      'renders CircularProgressIndicator on Material and CupertinoActivityIndicator on Cupertino modes when loading',
      (tester) async {
        await tester.pumpApp(
          const Scaffold(
            body: DashboardCardShell(
              cardKey: Key('shell_loading'),
              title: 'Weekly Weight Trend',
              status: DashboardCardStatus.loading,
              child: Text('Loaded Child'),
            ),
          ),
          capabilities: materialCaps,
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(CupertinoActivityIndicator), findsNothing);
        expect(find.text('Loaded Child'), findsNothing);

        await tester.pumpApp(
          const Scaffold(
            body: DashboardCardShell(
              cardKey: Key('shell_loading_classic'),
              title: 'Weekly Weight Trend',
              status: DashboardCardStatus.loading,
              child: Text('Loaded Child'),
            ),
          ),
          capabilities: cupertinoClassicCaps,
        );

        expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        await tester.pumpApp(
          const Scaffold(
            body: DashboardCardShell(
              cardKey: Key('shell_loading_glass'),
              title: 'Weekly Weight Trend',
              status: DashboardCardStatus.loading,
              child: Text('Loaded Child'),
            ),
          ),
          capabilities: cupertinoLiquidGlassCaps,
        );

        expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      'renders error message, invokes onRetry callback, and respects platform minTapTarget on Material and iOS',
      (tester) async {
        var retryCount = 0;

        await tester.pumpApp(
          Scaffold(
            body: DashboardCardShell(
              cardKey: const Key('shell_error_material'),
              title: 'Weekly Weight Trend',
              status: DashboardCardStatus.error,
              errorMessage: 'Failed to load weights',
              retryButtonKey: const Key('retry_btn'),
              onRetry: () => retryCount++,
              child: const Text('Loaded Child'),
            ),
          ),
          capabilities: materialCaps,
        );

        expect(find.text('Failed to load weights'), findsOneWidget);
        expect(find.text('Loaded Child'), findsNothing);

        final retryFinder = find.byKey(const Key('retry_btn'));
        expect(retryFinder, findsOneWidget);
        final materialSize = tester.getSize(retryFinder);
        expect(
          materialSize.height,
          greaterThanOrEqualTo(AppSpacing.androidMinTapTarget),
        );
        expect(
          materialSize.width,
          greaterThanOrEqualTo(AppSpacing.androidMinTapTarget),
        );

        await tester.tap(retryFinder);
        await tester.pump();
        expect(retryCount, 1);

        await tester.pumpApp(
          Scaffold(
            body: DashboardCardShell(
              cardKey: const Key('shell_error_ios'),
              title: 'Weekly Weight Trend',
              status: DashboardCardStatus.error,
              errorMessage: 'Failed to load weights',
              retryButtonKey: const Key('retry_btn_ios'),
              onRetry: () => retryCount++,
              child: const Text('Loaded Child'),
            ),
          ),
          capabilities: cupertinoClassicCaps,
        );

        final iosRetryFinder = find.byKey(const Key('retry_btn_ios'));
        final iosSize = tester.getSize(iosRetryFinder);
        expect(
          iosSize.height,
          greaterThanOrEqualTo(AppSpacing.iosMinTapTarget),
        );
        expect(iosSize.width, greaterThanOrEqualTo(AppSpacing.iosMinTapTarget));

        await tester.tap(iosRetryFinder);
        await tester.pump();
        expect(retryCount, 2);
      },
    );

    testWidgets('renders empty and unconfigured states with keyed messages', (
      tester,
    ) async {
      await tester.pumpApp(
        const Scaffold(
          body: Column(
            children: [
              DashboardCardShell(
                title: 'Weekly Weight Trend',
                status: DashboardCardStatus.empty,
                emptyMessage: 'No weights logged yet',
                emptyMessageKey: Key('empty_msg'),
                child: Text('Loaded Child 1'),
              ),
              DashboardCardShell(
                title: 'Workouts per Week',
                status: DashboardCardStatus.unconfigured,
                unconfiguredMessage: 'Hevy not connected',
                unconfiguredMessageKey: Key('unconfigured_msg'),
                child: Text('Loaded Child 2'),
              ),
            ],
          ),
        ),
        capabilities: materialCaps,
      );

      expect(find.byKey(const Key('empty_msg')), findsOneWidget);
      expect(find.text('No weights logged yet'), findsOneWidget);
      expect(find.text('Loaded Child 1'), findsNothing);

      expect(find.byKey(const Key('unconfigured_msg')), findsOneWidget);
      expect(find.text('Hevy not connected'), findsOneWidget);
      expect(find.text('Loaded Child 2'), findsNothing);
    });

    testWidgets(
      'renders loaded state with leadingIcon and warning AppStatusBadge when isOutdated is true in EN and PL',
      (tester) async {
        await tester.pumpApp(
          const Scaffold(
            body: DashboardCardShell(
              cardKey: Key('shell_loaded'),
              title: 'Weekly Pace',
              subtitle: 'Target: 0.20–0.40 kg/week',
              subtitleKey: Key('shell_subtitle'),
              leadingIcon: AppIcon.target,
              isOutdated: true,
              outdatedBadgeKey: Key('outdated_badge'),
              status: DashboardCardStatus.loaded,
              child: Text('Chart Body'),
            ),
          ),
          locale: const Locale('en'),
          capabilities: materialCaps,
        );

        expect(find.text('Chart Body'), findsOneWidget);
        expect(find.byKey(const Key('shell_subtitle')), findsOneWidget);
        expect(find.byIcon(AppIcons.material(AppIcon.target)), findsOneWidget);

        final badgeFinder = find.byType(AppStatusBadge);
        expect(badgeFinder, findsOneWidget);
        expect(find.byKey(const Key('outdated_badge')), findsOneWidget);
        final badge = tester.widget<AppStatusBadge>(badgeFinder);
        expect(badge.tone, AppFeedbackTone.warning);
        expect(badge.icon, AppIcon.warning);
        expect(find.text('Outdated · last refresh failed'), findsOneWidget);

        await tester.pumpApp(
          const Scaffold(
            body: DashboardCardShell(
              cardKey: Key('shell_loaded_pl'),
              title: 'Tygodniowe tempo',
              leadingIcon: AppIcon.target,
              isOutdated: true,
              outdatedBadgeKey: Key('outdated_badge_pl'),
              status: DashboardCardStatus.loaded,
              child: Text('Chart Body PL'),
            ),
          ),
          locale: const Locale('pl'),
          capabilities: cupertinoLiquidGlassCaps,
        );

        expect(find.text('Nieaktualne · błąd odświeżania'), findsOneWidget);
        expect(find.byIcon(AppIcons.cupertino(AppIcon.target)), findsOneWidget);
      },
    );
  });

  group('DashboardKpiRow', () {
    testWidgets(
      'renders populated metrics with headlineMedium tabular figures and no FittedBox',
      (tester) async {
        final state = DashboardState(
          weightStatus: DashboardCardStatus.loaded,
          workoutStatus: DashboardCardStatus.loaded,
          overview: buildPopulatedOverview(),
        );

        await tester.pumpApp(
          Scaffold(body: DashboardKpiRow(state: state)),
          capabilities: materialCaps,
        );

        expect(
          find.byKey(const Key('dashboard_kpi_pace_tile')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('dashboard_kpi_average_tile')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('dashboard_kpi_total_gain_tile')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('dashboard_kpi_workouts_tile')),
          findsOneWidget,
        );

        expect(find.text('+0.35 kg/week'), findsOneWidget);
        expect(find.text('82.40 kg'), findsOneWidget);
        expect(find.text('This week · 7/7 days logged'), findsOneWidget);
        expect(find.text('+2.10 kg'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
        expect(find.text('This week'), findsOneWidget);

        expect(
          find.descendant(
            of: find.byType(DashboardKpiRow),
            matching: find.byType(FittedBox),
          ),
          findsNothing,
        );

        final valueText = tester.widget<Text>(find.text('82.40 kg'));
        expect(valueText.style?.fontSize, 28);
        expect(
          valueText.style?.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
      },
    );

    testWidgets(
      'renders incomplete current week badge as AppStatusBadge with AppFeedbackTone.info',
      (tester) async {
        final state = DashboardState(
          weightStatus: DashboardCardStatus.loaded,
          workoutStatus: DashboardCardStatus.loaded,
          overview: buildPopulatedOverview(
            latestWeekLoggedDays: 3,
            isLatestWeekCurrentWeek: true,
            isLatestWeekIncomplete: true,
          ),
        );

        await tester.pumpApp(
          Scaffold(body: DashboardKpiRow(state: state)),
          capabilities: materialCaps,
        );

        expect(
          find.byKey(const Key('dashboard_incomplete_week_badge')),
          findsOneWidget,
        );
        final badge = tester.widget<AppStatusBadge>(
          find.descendant(
            of: find.byKey(const Key('dashboard_kpi_average_tile')),
            matching: find.byType(AppStatusBadge),
          ),
        );
        expect(badge.tone, AppFeedbackTone.info);
        expect(find.text('This week · 3/7 days logged'), findsOneWidget);
      },
    );

    testWidgets(
      'renders empty state (Log 2+ weeks), workout unconfigured, and workout error badge',
      (tester) async {
        final unconfiguredState = DashboardState(
          weightStatus: DashboardCardStatus.empty,
          workoutStatus: DashboardCardStatus.unconfigured,
          overview: buildEmptyOverview(),
        );

        await tester.pumpApp(
          Scaffold(body: DashboardKpiRow(state: unconfiguredState)),
          capabilities: materialCaps,
        );

        expect(find.text('Log 2+ weeks'), findsNWidgets(2));
        expect(find.text('Not connected'), findsOneWidget);
        expect(find.text('—'), findsNWidgets(4));

        final errorState = unconfiguredState.copyWith(
          workoutStatus: DashboardCardStatus.error,
        );

        await tester.pumpApp(
          Scaffold(body: DashboardKpiRow(state: errorState)),
          capabilities: materialCaps,
        );

        final errorBadgeFinder = find.descendant(
          of: find.byKey(const Key('dashboard_kpi_workouts_tile')),
          matching: find.byType(AppStatusBadge),
        );
        expect(errorBadgeFinder, findsOneWidget);
        final errorBadge = tester.widget<AppStatusBadge>(errorBadgeFinder);
        expect(errorBadge.tone, AppFeedbackTone.error);
        expect(find.text('Sync error'), findsOneWidget);
      },
    );

    testWidgets(
      'adapts layout across 2x2 grid at 400px, 4x1 row at 960px, and 1x4 single-column reflow at 2.0x text scale in Polish',
      (tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final state = DashboardState(
          weightStatus: DashboardCardStatus.loaded,
          workoutStatus: DashboardCardStatus.loaded,
          overview: buildPopulatedOverview(
            latestWeekLoggedDays: 4,
            isLatestWeekIncomplete: true,
          ),
        );

        // 1. 400px width -> 2x2 grid
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpApp(
          Scaffold(body: DashboardKpiRow(state: state)),
          capabilities: materialCaps,
        );
        expect(tester.takeException(), isNull);

        final paceRect400 = tester.getRect(
          find.byKey(const Key('dashboard_kpi_pace_tile')),
        );
        final avgRect400 = tester.getRect(
          find.byKey(const Key('dashboard_kpi_average_tile')),
        );
        final gainRect400 = tester.getRect(
          find.byKey(const Key('dashboard_kpi_total_gain_tile')),
        );
        final workoutsRect400 = tester.getRect(
          find.byKey(const Key('dashboard_kpi_workouts_tile')),
        );

        expect(paceRect400.top, equals(avgRect400.top));
        expect(paceRect400.left, lessThan(avgRect400.left));
        expect(gainRect400.top, equals(workoutsRect400.top));
        expect(gainRect400.top, greaterThan(paceRect400.top));
        expect(gainRect400.left, lessThan(workoutsRect400.left));

        // 2. 960px width (>= 840px expandedBreakpoint) -> 4x1 single-row layout
        tester.view.physicalSize = const Size(960, 800);
        await tester.pumpApp(
          Scaffold(body: DashboardKpiRow(state: state)),
          capabilities: materialCaps,
        );
        expect(tester.takeException(), isNull);

        final paceRect960 = tester.getRect(
          find.byKey(const Key('dashboard_kpi_pace_tile')),
        );
        final avgRect960 = tester.getRect(
          find.byKey(const Key('dashboard_kpi_average_tile')),
        );
        final gainRect960 = tester.getRect(
          find.byKey(const Key('dashboard_kpi_total_gain_tile')),
        );
        final workoutsRect960 = tester.getRect(
          find.byKey(const Key('dashboard_kpi_workouts_tile')),
        );

        expect(paceRect960.top, equals(avgRect960.top));
        expect(avgRect960.top, equals(gainRect960.top));
        expect(gainRect960.top, equals(workoutsRect960.top));
        expect(paceRect960.left, lessThan(avgRect960.left));
        expect(avgRect960.left, lessThan(gainRect960.left));
        expect(gainRect960.left, lessThan(workoutsRect960.left));

        // 3. TextScaler.linear(2.0) in Polish (Locale('pl')) -> 1x4 single-column reflow with zero overflow
        tester.view.physicalSize = const Size(400, 1200);
        await tester.pumpApp(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 1200),
              textScaler: TextScaler.linear(2.0),
            ),
            child: Scaffold(
              body: SingleChildScrollView(child: DashboardKpiRow(state: state)),
            ),
          ),
          locale: const Locale('pl'),
          capabilities: materialCaps,
        );
        expect(tester.takeException(), isNull);

        final paceRectPl = tester.getRect(
          find.byKey(const Key('dashboard_kpi_pace_tile')),
        );
        final avgRectPl = tester.getRect(
          find.byKey(const Key('dashboard_kpi_average_tile')),
        );
        final gainRectPl = tester.getRect(
          find.byKey(const Key('dashboard_kpi_total_gain_tile')),
        );
        final workoutsRectPl = tester.getRect(
          find.byKey(const Key('dashboard_kpi_workouts_tile')),
        );

        expect(paceRectPl.left, equals(avgRectPl.left));
        expect(avgRectPl.left, equals(gainRectPl.left));
        expect(gainRectPl.left, equals(workoutsRectPl.left));
        expect(paceRectPl.top, lessThan(avgRectPl.top));
        expect(avgRectPl.top, lessThan(gainRectPl.top));
        expect(gainRectPl.top, lessThan(workoutsRectPl.top));
        expect(find.text('Ten tydzień · 4/7 dni'), findsOneWidget);
      },
    );
  });
}
