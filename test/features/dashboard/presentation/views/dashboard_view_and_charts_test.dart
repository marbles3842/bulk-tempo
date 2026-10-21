import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/design_system.dart';
import 'package:bulk_tempo/features/auth/domain/models/user_entity.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_state.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:bulk_tempo/features/dashboard/domain/calculators/weekly_progress_calculator.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/weekly_progress_overview_entity.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_state.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_view_model.dart';
import 'package:bulk_tempo/features/dashboard/presentation/views/dashboard_view.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/weekly_pace_chart_card.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/weekly_weight_trend_card.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/weekly_workouts_chart_card.dart';
import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';
import 'package:bulk_tempo/features/weight/domain/models/weekly_weight_summary_entity.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/weekly_workout_summary_entity.dart';

import '../../../../test_helpers/pump_app.dart';

class _SpyAuthViewModel extends AuthViewModel {
  @override
  AuthState build() {
    return const AuthState(
      user: UserEntity(id: 'u1', email: 'athlete@example.com'),
      isInitializing: false,
    );
  }
}

class _SpyDashboardViewModel extends DashboardViewModel {
  _SpyDashboardViewModel(this._initialState);

  final DashboardState _initialState;
  int ensureInitializedCount = 0;
  int refreshAllCount = 0;
  int retryWeightsCount = 0;
  int retryPaceCount = 0;
  int retryWorkoutsCount = 0;

  @override
  DashboardState build() => _initialState;

  @override
  Future<void> ensureInitialized() async {
    ensureInitializedCount++;
  }

  @override
  Future<void> refreshAll() async {
    refreshAllCount++;
  }

  @override
  Future<void> retryWeights() async {
    retryWeightsCount++;
  }

  @override
  Future<void> retryPace() async {
    retryPaceCount++;
  }

  @override
  Future<void> retryWorkouts() async {
    retryWorkoutsCount++;
  }
}

void main() {
  const materialCaps = PresentationCapabilities(
    targetPlatform: TargetPlatform.android,
  );

  final sampleNow = DateTime.utc(2026, 10, 14, 12);

  WeeklyProgressOverviewEntity buildSampleOverview() {
    final currentMonday = DateTime.utc(2026, 10, 12);
    final weightSummaries = <WeeklyWeightSummaryEntity>[];
    final workoutSummaries = <WeeklyWorkoutSummaryEntity>[];

    for (var i = 0; i < 12; i++) {
      final weeksAgo = 11 - i;
      final monday = DateTime.utc(
        currentMonday.year,
        currentMonday.month,
        currentMonday.day - (7 * weeksAgo),
      );
      final sunday = monday.add(const Duration(days: 6));
      final iso =
          '${monday.year.toString().padLeft(4, '0')}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';

      weightSummaries.add(
        WeeklyWeightSummaryEntity(
          weekStartIso: iso,
          weekStartMonday: monday,
          weekEndSunday: sunday,
          averageWeightKg: 80.0 + (i * 0.25),
          entries: [
            for (var d = 0; d < 7; d++)
              WeightEntryEntity(
                dateIso: iso,
                date: monday.add(Duration(days: d)),
                weightKg: 80.0 + (i * 0.25),
                updatedAt: sampleNow,
              ),
          ],
        ),
      );

      workoutSummaries.add(
        WeeklyWorkoutSummaryEntity(
          weekStartIso: iso,
          weekStartMonday: monday,
          weekEndSunday: sunday,
          workoutCount: (i % 3) + 2,
          workouts: const [],
          totalWorkingSets: 12,
          totalVolumeKg: 4800.0,
        ),
      );
    }

    return WeeklyProgressCalculator.calculate(
      allWeightSummaries: weightSummaries,
      workoutSummaries: workoutSummaries,
      now: sampleNow,
    );
  }

  DashboardState buildLoadedDashboardState({
    GainTargetEntity? gainTarget = const GainTargetEntity(
      minWeeklyGainKg: 0.20,
      maxWeeklyGainKg: 0.40,
    ),
  }) {
    return DashboardState(
      weightStatus: DashboardCardStatus.loaded,
      workoutStatus: DashboardCardStatus.loaded,
      gainTargetStatus: DashboardCardStatus.loaded,
      gainTarget: gainTarget,
      overview: buildSampleOverview(),
      hasAnyWorkoutInWindow: true,
    );
  }

  int countVisibleBottomTicks(SideTitles sideTitles, int totalWeeks) {
    final meta = TitleMeta(
      min: 0,
      max: (totalWeeks - 1).toDouble(),
      parentAxisSize: 400,
      axisPosition: 0,
      appliedInterval: 1,
      sideTitles: sideTitles,
      formattedValue: '',
      axisSide: AxisSide.bottom,
      rotationQuarterTurns: 0,
    );
    var visibleCount = 0;
    for (var i = 0; i < totalWeeks; i++) {
      final widget = sideTitles.getTitlesWidget(i.toDouble(), meta);
      if (widget is SideTitleWidget) {
        visibleCount++;
      }
    }
    return visibleCount;
  }

  group('WeeklyWeightTrendCard', () {
    testWidgets(
      'binds AppChartTheme tokens (seriesWeight, lineStrokeWidth, gridLine, tooltipSurface) and exposes Semantics label with formatted weights',
      (tester) async {
        final state = buildLoadedDashboardState();
        final theme = AppTheme.light();
        final chartTheme = theme.extension<AppChartTheme>()!;

        await tester.pumpApp(
          Scaffold(
            body: WeeklyWeightTrendCard(state: state, onRetry: () {}),
          ),
          theme: theme,
          capabilities: materialCaps,
        );

        final lineChart = tester.widget<LineChart>(find.byType(LineChart));
        final data = lineChart.data;
        final barData = data.lineBarsData.single;

        final chartSizedBox = tester.widget<SizedBox>(
          find
              .ancestor(
                of: find.byType(LineChart),
                matching: find.byType(SizedBox),
              )
              .first,
        );
        expect(chartSizedBox.height, equals(chartTheme.chartHeight));
        expect(
          data.titlesData.bottomTitles.sideTitles.reservedSize,
          equals(chartTheme.bottomAxisReservedSize),
        );
        expect(
          data.titlesData.leftTitles.sideTitles.reservedSize,
          equals(chartTheme.weightLeftAxisReservedSize),
        );

        expect(barData.color, equals(chartTheme.seriesWeight));
        expect(barData.barWidth, equals(chartTheme.lineStrokeWidth));
        expect(
          data.gridData.getDrawingHorizontalLine(80).color,
          equals(chartTheme.gridLine),
        );
        expect(
          data.lineTouchData.touchTooltipData.getTooltipColor(
            LineBarSpot(barData, 0, barData.spots.first),
          ),
          equals(chartTheme.tooltipSurface),
        );

        final semanticsFinder = find.descendant(
          of: find.byType(WeeklyWeightTrendCard),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.container &&
                (w.properties.label?.contains('Weekly Weight Trend') ?? false),
          ),
        );
        expect(semanticsFinder, findsOneWidget);
        final semanticsWidget = tester.widget<Semantics>(semanticsFinder);
        expect(semanticsWidget.properties.label, isNotEmpty);
        expect(semanticsWidget.properties.label, contains('80.00 kg'));
        expect(semanticsWidget.properties.label, contains('82.75 kg'));
      },
    );
  });

  group('WeeklyPaceChartCard', () {
    testWidgets(
      'binds AppChartTheme tokens (seriesPace, barWidth, targetFill) and renders two dashed HorizontalLines when gainTarget is present',
      (tester) async {
        const target = GainTargetEntity(
          minWeeklyGainKg: 0.20,
          maxWeeklyGainKg: 0.40,
        );
        final state = buildLoadedDashboardState(gainTarget: target);
        final theme = AppTheme.light();
        final chartTheme = theme.extension<AppChartTheme>()!;

        await tester.pumpApp(
          Scaffold(
            body: WeeklyPaceChartCard(state: state, onRetry: () {}),
          ),
          theme: theme,
          capabilities: materialCaps,
        );

        expect(
          find.byKey(const Key('dashboard_pace_target_subtitle')),
          findsOneWidget,
        );

        final barChart = tester.widget<BarChart>(find.byType(BarChart));
        final data = barChart.data;

        final chartSizedBox = tester.widget<SizedBox>(
          find.descendant(
            of: find.byType(WeeklyPaceChartCard),
            matching: find.byWidgetPredicate(
              (w) => w is SizedBox && w.child is BarChart,
            ),
          ),
        );
        expect(chartSizedBox.height, equals(chartTheme.chartHeight));
        expect(
          data.titlesData.bottomTitles.sideTitles.reservedSize,
          equals(chartTheme.bottomAxisReservedSize),
        );
        expect(
          data.titlesData.leftTitles.sideTitles.reservedSize,
          equals(chartTheme.paceLeftAxisReservedSize),
        );

        // First week has null pace (width 0), subsequent weeks have pace (width chartTheme.barWidth)
        final populatedRods = data.barGroups
            .skip(1)
            .map((g) => g.barRods.single)
            .toList();
        expect(populatedRods, isNotEmpty);
        for (final rod in populatedRods) {
          expect(rod.color, equals(chartTheme.seriesPace));
          expect(rod.width, equals(chartTheme.barWidth));
          expect(
            rod.borderRadius,
            equals(
              BorderRadius.vertical(
                top: Radius.circular(chartTheme.barRadius),
                bottom: Radius.circular(chartTheme.barRadius),
              ),
            ),
          );
        }

        // Target band annotation
        final rangeAnnotations =
            data.rangeAnnotations.horizontalRangeAnnotations;
        expect(rangeAnnotations, hasLength(1));
        final targetBand = rangeAnnotations.single;
        expect(targetBand.y1, equals(target.minWeeklyGainKg));
        expect(targetBand.y2, equals(target.maxWeeklyGainKg));
        expect(
          targetBand.color,
          equals(chartTheme.targetFill.withValues(alpha: 0.55)),
        );

        // Extra horizontal lines: 0 baseline + 2 dashed target boundary lines
        final horizontalLines = data.extraLinesData.horizontalLines;
        final dashedBoundaryLines = horizontalLines
            .where((line) => line.dashArray != null)
            .toList();
        expect(dashedBoundaryLines, hasLength(2));
        expect(
          dashedBoundaryLines.map((l) => l.y),
          containsAll([target.minWeeklyGainKg, target.maxWeeklyGainKg]),
        );
        for (final line in dashedBoundaryLines) {
          expect(line.color, equals(chartTheme.targetBoundary));
          expect(line.dashArray, equals(chartTheme.targetDashPattern));
        }

        // Semantics label includes title, target subtitle, and formatted weekly pace
        final semanticsFinder = find.descendant(
          of: find.byType(WeeklyPaceChartCard),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.container &&
                (w.properties.label?.contains('Weekly Pace') ?? false),
          ),
        );
        expect(semanticsFinder, findsOneWidget);
        final semanticsLabel = tester
            .widget<Semantics>(semanticsFinder)
            .properties
            .label!;
        expect(semanticsLabel, contains('+0.25 kg/week'));
      },
    );
  });

  group('WeeklyWorkoutsChartCard', () {
    testWidgets(
      'binds chartTheme.seriesWorkouts (colorScheme.tertiary, distinct from primary) and chartTheme.barWidth',
      (tester) async {
        final state = buildLoadedDashboardState();
        final theme = AppTheme.light();
        final chartTheme = theme.extension<AppChartTheme>()!;

        expect(chartTheme.seriesWorkouts, equals(theme.colorScheme.tertiary));
        expect(
          chartTheme.seriesWorkouts,
          isNot(equals(theme.colorScheme.primary)),
        );

        await tester.pumpApp(
          Scaffold(
            body: WeeklyWorkoutsChartCard(state: state, onRetry: () {}),
          ),
          theme: theme,
          capabilities: materialCaps,
        );

        final barChart = tester.widget<BarChart>(find.byType(BarChart));
        final data = barChart.data;
        expect(data.barGroups, hasLength(12));

        final chartSizedBox = tester.widget<SizedBox>(
          find.descendant(
            of: find.byType(WeeklyWorkoutsChartCard),
            matching: find.byWidgetPredicate(
              (w) => w is SizedBox && w.child is BarChart,
            ),
          ),
        );
        expect(chartSizedBox.height, equals(chartTheme.chartHeight));
        expect(
          data.titlesData.bottomTitles.sideTitles.reservedSize,
          equals(chartTheme.bottomAxisReservedSize),
        );
        expect(
          data.titlesData.leftTitles.sideTitles.reservedSize,
          equals(chartTheme.workoutsLeftAxisReservedSize),
        );

        for (final group in data.barGroups) {
          final rod = group.barRods.single;
          expect(rod.color, equals(chartTheme.seriesWorkouts));
          expect(rod.width, equals(chartTheme.barWidth));
          expect(
            rod.borderRadius,
            equals(
              BorderRadius.vertical(top: Radius.circular(chartTheme.barRadius)),
            ),
          );
        }

        final semanticsFinder = find.descendant(
          of: find.byType(WeeklyWorkoutsChartCard),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.container &&
                (w.properties.label?.contains('Workouts per Week') ?? false),
          ),
        );
        expect(semanticsFinder, findsOneWidget);
        final semanticsLabel = tester
            .widget<Semantics>(semanticsFinder)
            .properties
            .label!;
        expect(semanticsLabel, contains('workouts'));
      },
    );
  });

  group('Chart Bottom Axis Tick Density at 1.0x vs 2.0x TextScaler', () {
    testWidgets(
      'bottom axis tick count drops from 6 ticks (index.isEven) at 1.0x to 3 ticks (index % 4 == 0) at 2.0x text scale with zero layout exceptions',
      (tester) async {
        final state = buildLoadedDashboardState();

        // 1.0x text scale
        await tester.pumpApp(
          Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  WeeklyWeightTrendCard(state: state, onRetry: () {}),
                  WeeklyPaceChartCard(state: state, onRetry: () {}),
                  WeeklyWorkoutsChartCard(state: state, onRetry: () {}),
                ],
              ),
            ),
          ),
          capabilities: materialCaps,
        );
        expect(tester.takeException(), isNull);

        final lineChart1x = tester.widget<LineChart>(find.byType(LineChart));
        final barCharts1x = tester
            .widgetList<BarChart>(find.byType(BarChart))
            .toList();

        expect(
          countVisibleBottomTicks(
            lineChart1x.data.titlesData.bottomTitles.sideTitles,
            12,
          ),
          equals(6),
        );
        expect(
          countVisibleBottomTicks(
            barCharts1x[0].data.titlesData.bottomTitles.sideTitles,
            12,
          ),
          equals(6),
        );
        expect(
          countVisibleBottomTicks(
            barCharts1x[1].data.titlesData.bottomTitles.sideTitles,
            12,
          ),
          equals(6),
        );

        // 2.0x text scale in Polish
        await tester.pumpApp(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 1200),
              textScaler: TextScaler.linear(2.0),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    WeeklyWeightTrendCard(state: state, onRetry: () {}),
                    WeeklyPaceChartCard(state: state, onRetry: () {}),
                    WeeklyWorkoutsChartCard(state: state, onRetry: () {}),
                  ],
                ),
              ),
            ),
          ),
          locale: const Locale('pl'),
          capabilities: materialCaps,
        );
        expect(tester.takeException(), isNull);

        final lineChart2x = tester.widget<LineChart>(find.byType(LineChart));
        final barCharts2x = tester
            .widgetList<BarChart>(find.byType(BarChart))
            .toList();

        expect(
          countVisibleBottomTicks(
            lineChart2x.data.titlesData.bottomTitles.sideTitles,
            12,
          ),
          equals(3),
        );
        expect(
          countVisibleBottomTicks(
            barCharts2x[0].data.titlesData.bottomTitles.sideTitles,
            12,
          ),
          equals(3),
        );
        expect(
          countVisibleBottomTicks(
            barCharts2x[1].data.titlesData.bottomTitles.sideTitles,
            12,
          ),
          equals(3),
        );
      },
    );
  });

  group('DashboardView', () {
    testWidgets(
      'renders RefreshIndicator.adaptive, triggers refreshAll() on pull-to-refresh, and caps content width at AppSpacing.dashboardMaxWidth (1120.0)',
      (tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        tester.view.physicalSize = const Size(1440, 1000);
        tester.view.devicePixelRatio = 1.0;

        final state = buildLoadedDashboardState();
        final spyDashboardVm = _SpyDashboardViewModel(state);

        await tester.pumpApp(
          const Scaffold(body: DashboardView()),
          overrides: [
            authViewModelProvider.overrideWith(_SpyAuthViewModel.new),
            dashboardViewModelProvider.overrideWith(() => spyDashboardVm),
          ],
          capabilities: materialCaps,
        );
        await tester.pumpAndSettle();

        expect(spyDashboardVm.ensureInitializedCount, equals(1));
        expect(find.byType(RefreshIndicator), findsOneWidget);

        // Verify content width cap at AppSpacing.dashboardMaxWidth (1120.0)
        final constrainedBoxFinder = find.ancestor(
          of: find.byKey(const Key('dashboard_scroll_view')),
          matching: find.byWidgetPredicate(
            (w) =>
                w is ConstrainedBox &&
                w.constraints.maxWidth == AppSpacing.dashboardMaxWidth,
          ),
        );
        expect(constrainedBoxFinder, findsOneWidget);

        final listViewRect = tester.getRect(
          find.byKey(const Key('dashboard_scroll_view')),
        );
        expect(listViewRect.width, equals(AppSpacing.dashboardMaxWidth));

        // Trigger pull-to-refresh
        await tester.fling(
          find.byKey(const Key('dashboard_scroll_view')),
          const Offset(0, 300),
          1000,
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        expect(spyDashboardVm.refreshAllCount, equals(1));
      },
    );
  });
}
