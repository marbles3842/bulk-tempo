import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/features/dashboard/domain/calculators/weekly_progress_calculator.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/pace_assessment_entity.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/weekly_progress_overview_entity.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_state.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/pace_assessment_state.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/pace_assessment_card.dart';

import '../../../../test_helpers/pump_app.dart';

void main() {
  final refNow = DateTime.utc(2026, 10, 14, 12, 0);

  WeeklyProgressOverviewEntity buildOverview({int latestLoggedDays = 3}) {
    final base = WeeklyProgressCalculator.calculate(
      allWeightSummaries: const [],
      workoutSummaries: const [],
      now: refNow,
    );
    return base.copyWith(
      latestWeekStartIso: '2026-10-12',
      latestWeekLoggedDays: latestLoggedDays,
    );
  }

  PaceAssessmentEntity buildAssessment({
    PaceAssessmentStatus status = PaceAssessmentStatus.onTarget,
    PaceAssessmentStatus baselineStatus = PaceAssessmentStatus.onTarget,
    String headlineSummary = 'Weight gain is right on target.',
    bool isAssessedWeekPartial = true,
  }) {
    return PaceAssessmentEntity(
      status: status,
      baselineStatus: baselineStatus,
      headlineSummary: headlineSummary,
      weightTrendAnalysis: 'Gaining 0.20 kg/week.',
      workoutContextAnalysis: 'Lifts are progressing steadily.',
      actionableTakeaways: const [
        'Keep caloric intake steady.',
        'Add 2.5 kg to bench press.',
      ],
      assessedWeekStartIso: '2026-10-12',
      isAssessedWeekPartial: isAssessedWeekPartial,
      currentPaceKgPerWeek: 0.20,
      targetMinKgPerWeek: 0.15,
      targetMaxKgPerWeek: 0.25,
      priorWeightWeeksCount: 2,
      localeCode: 'en',
      fingerprint: 'fp_test',
      generatedAt: refNow,
    );
  }

  DashboardState buildState({
    required PaceAssessmentState paceAssessment,
    int latestLoggedDays = 3,
  }) {
    return DashboardState(
      weightStatus: DashboardCardStatus.loaded,
      workoutStatus: DashboardCardStatus.loaded,
      overview: buildOverview(latestLoggedDays: latestLoggedDays),
      paceAssessment: paceAssessment,
    );
  }

  group('PaceAssessmentCard', () {
    testWidgets('renders AI typing dots indicator when status is loading', (
      tester,
    ) async {
      final state = buildState(
        paceAssessment: const PaceAssessmentState(
          status: PaceAssessmentViewStatus.loading,
        ),
      );

      await tester.pumpApp(
        Scaffold(
          body: PaceAssessmentCard(
            state: state,
            onRetry: () {},
            onRefresh: () {},
            onOpenReport: () {},
          ),
        ),
      );

      expect(
        find.byKey(const Key('dashboard_pace_assessment_card')),
        findsOneWidget,
      );
      expect(find.text('AI Pace Assessment'), findsOneWidget);
      expect(
        find.byKey(const Key('pace_assessment_typing_indicator')),
        findsOneWidget,
      );
      expect(find.byType(AiTypingDotsIndicator), findsOneWidget);
      expect(
        find.byKey(const Key('pace_assessment_refresh_button')),
        findsNothing,
      );
    });

    testWidgets(
      'reveals headline summary in chunks like AI chat until complete',
      (tester) async {
        const fullSummary =
            'Your weekly weight gain pace is right on target while bench press strength is climbing.';
        final state = buildState(
          paceAssessment: PaceAssessmentState(
            status: PaceAssessmentViewStatus.loaded,
            assessment: buildAssessment(
              headlineSummary: fullSummary,
            ).copyWith(fingerprint: 'fp_chunk_animation_test'),
          ),
        );

        await tester.pumpApp(
          Scaffold(
            body: PaceAssessmentCard(
              state: state,
              onRetry: () {},
              onRefresh: () {},
              onOpenReport: () {},
            ),
          ),
        );

        final initialTextWidget = tester.widget<Text>(
          find.byKey(const Key('pace_assessment_headline_text')),
        );
        expect(initialTextWidget.data, 'Your weekly weight');
        expect(initialTextWidget.data, isNot(equals(fullSummary)));

        // Advance one chunk tick (40ms)
        await tester.pump(const Duration(milliseconds: 40));
        final secondChunkWidget = tester.widget<Text>(
          find.byKey(const Key('pace_assessment_headline_text')),
        );
        expect(secondChunkWidget.data, 'Your weekly weight gain pace is');

        // Advance until all chunks finish
        await tester.pump(const Duration(milliseconds: 500));
        final finalTextWidget = tester.widget<Text>(
          find.byKey(const Key('pace_assessment_headline_text')),
        );
        expect(finalTextWidget.data, fullSummary);
      },
    );

    testWidgets('renders all 4 ineligibility messages in English and Polish', (
      tester,
    ) async {
      final cases =
          <
            ({
              PaceAssessmentIneligibilityReason reason,
              int priorWeeks,
              String enText,
              String plText,
            })
          >[
            (
              reason: PaceAssessmentIneligibilityReason.missingGainTarget,
              priorWeeks: 2,
              enText:
                  'Set your weekly gain target in Profile to unlock AI pace assessment.',
              plText:
                  'Ustaw docelowy zakres przyrostu w Profilu, aby odblokować ocenę tempa AI.',
            ),
            (
              reason: PaceAssessmentIneligibilityReason.workoutUnconfigured,
              priorWeeks: 2,
              enText:
                  'Connect your Hevy API key in Profile to include workout context in your pace assessment.',
              plText:
                  'Połącz klucz API Hevy w Profilu, aby uwzględnić treningi w ocenie tempa.',
            ),
            (
              reason: PaceAssessmentIneligibilityReason.noWorkoutsInWindow,
              priorWeeks: 2,
              enText:
                  'Log or import at least one workout in the last 12 weeks to assess your pace in training context.',
              plText:
                  'Zapisz lub zaimportuj co najmniej jeden trening z ostatnich 12 tygodni, aby ocenić tempo w kontekście treningowym.',
            ),
            (
              reason: PaceAssessmentIneligibilityReason.insufficientWeightWeeks,
              priorWeeks: 1,
              enText:
                  'Log weight entries in the current (or previous) week and at least 2 earlier weeks (1/2 prior weeks logged) to unlock pace assessment.',
              plText:
                  'Zapisz pomiary wagi w bieżącym (lub poprzednim) tygodniu oraz w co najmniej 2 wcześniejszych tygodniach (zapisano 1/2 wcześniejszych tygodni), aby odblokować ocenę tempa.',
            ),
          ];

      for (final testCase in cases) {
        final state = buildState(
          paceAssessment: PaceAssessmentState(
            status: PaceAssessmentViewStatus.ineligible,
            ineligibilityReason: testCase.reason,
            priorWeightWeeksCount: testCase.priorWeeks,
          ),
        );

        await tester.pumpApp(
          Scaffold(
            body: PaceAssessmentCard(
              state: state,
              onRetry: () {},
              onRefresh: () {},
              onOpenReport: () {},
            ),
          ),
          locale: const Locale('en'),
        );

        expect(
          find.byKey(const Key('pace_assessment_ineligible_text')),
          findsOneWidget,
        );
        expect(find.text(testCase.enText), findsOneWidget);

        await tester.pumpApp(
          Scaffold(
            body: PaceAssessmentCard(
              state: state,
              onRetry: () {},
              onRefresh: () {},
              onOpenReport: () {},
            ),
          ),
          locale: const Locale('pl'),
        );

        expect(find.text(testCase.plText), findsOneWidget);
      }
    });

    testWidgets('renders error message and invokes onRetry when Retry tapped', (
      tester,
    ) async {
      var retried = false;
      final state = buildState(
        paceAssessment: const PaceAssessmentState(
          status: PaceAssessmentViewStatus.error,
          errorMessage: 'Gemini request timed out',
        ),
      );

      await tester.pumpApp(
        Scaffold(
          body: PaceAssessmentCard(
            state: state,
            onRetry: () => retried = true,
            onRefresh: () {},
            onOpenReport: () {},
          ),
        ),
      );

      expect(find.text('Gemini request timed out'), findsOneWidget);
      expect(
        find.byKey(const Key('pace_assessment_retry_button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('pace_assessment_retry_button')));
      expect(retried, isTrue);
    });

    testWidgets(
      'renders all 4 pace statuses in English and Polish with headline, partial-week badge, refresh, and view report button',
      (tester) async {
        final statusCases =
            <({PaceAssessmentStatus status, String enLabel, String plLabel})>[
              (
                status: PaceAssessmentStatus.onTarget,
                enLabel: 'On target',
                plLabel: 'Tempo prawidłowe',
              ),
              (
                status: PaceAssessmentStatus.tooFast,
                enLabel: 'Too fast',
                plLabel: 'Tempo za szybkie',
              ),
              (
                status: PaceAssessmentStatus.tooSlow,
                enLabel: 'Too slow',
                plLabel: 'Tempo za wolne',
              ),
              (
                status: PaceAssessmentStatus.stagnant,
                enLabel: 'Stagnation',
                plLabel: 'Stagnacja',
              ),
            ];

        for (final c in statusCases) {
          var refreshed = false;
          var openedReport = false;
          final state = buildState(
            latestLoggedDays: 4,
            paceAssessment: PaceAssessmentState(
              status: PaceAssessmentViewStatus.loaded,
              assessment: buildAssessment(
                status: c.status,
                headlineSummary: 'Summary for ${c.status.name}',
                isAssessedWeekPartial: true,
              ),
            ),
          );

          await tester.pumpApp(
            Scaffold(
              body: PaceAssessmentCard(
                state: state,
                onRetry: () {},
                onRefresh: () => refreshed = true,
                onOpenReport: () => openedReport = true,
              ),
            ),
            locale: const Locale('en'),
          );
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('pace_assessment_status_badge')),
            findsOneWidget,
          );
          expect(find.text(c.enLabel), findsOneWidget);
          expect(
            find.byKey(const Key('pace_assessment_partial_week_badge')),
            findsOneWidget,
          );
          expect(find.text('Partial week (4/7 days)'), findsOneWidget);
          expect(
            find.byKey(const Key('pace_assessment_headline_text')),
            findsOneWidget,
          );
          expect(find.text('Summary for ${c.status.name}'), findsOneWidget);

          await tester.tap(
            find.byKey(const Key('pace_assessment_refresh_button')),
          );
          expect(refreshed, isTrue);

          await tester.tap(
            find.byKey(const Key('pace_assessment_view_report_button')),
          );
          expect(openedReport, isTrue);

          // Verify Polish rendering
          await tester.pumpApp(
            Scaffold(
              body: PaceAssessmentCard(
                state: state,
                onRetry: () {},
                onRefresh: () {},
                onOpenReport: () {},
              ),
            ),
            locale: const Locale('pl'),
          );

          expect(find.text('Ocena tempa AI'), findsOneWidget);
          expect(find.text(c.plLabel), findsOneWidget);
          expect(find.text('Niepełny tydzień (4/7 dni)'), findsOneWidget);
          expect(find.text('Zobacz pełny raport AI'), findsOneWidget);
        }
      },
    );

    testWidgets('renders outdated badge when isOutdated is true', (
      tester,
    ) async {
      final state = buildState(
        paceAssessment: PaceAssessmentState(
          status: PaceAssessmentViewStatus.loaded,
          isOutdated: true,
          assessment: buildAssessment(isAssessedWeekPartial: false),
        ),
      );

      await tester.pumpApp(
        Scaffold(
          body: PaceAssessmentCard(
            state: state,
            onRetry: () {},
            onRefresh: () {},
            onOpenReport: () {},
          ),
        ),
      );

      expect(
        find.byKey(const Key('pace_assessment_outdated_badge')),
        findsOneWidget,
      );
      expect(find.text('Outdated · last refresh failed'), findsOneWidget);
      expect(
        find.byKey(const Key('pace_assessment_partial_week_badge')),
        findsNothing,
      );
    });
  });
}
