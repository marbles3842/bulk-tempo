import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/pace_assessment_entity.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/pace_assessment_report_bottom_sheet.dart';

import '../../../../test_helpers/pump_app.dart';

void main() {
  final refNow = DateTime.utc(2026, 10, 14, 12, 0);

  PaceAssessmentEntity buildAssessment({
    PaceAssessmentStatus status = PaceAssessmentStatus.onTarget,
    PaceAssessmentStatus baselineStatus = PaceAssessmentStatus.onTarget,
    bool isAssessedWeekPartial = true,
  }) {
    return PaceAssessmentEntity(
      status: status,
      baselineStatus: baselineStatus,
      headlineSummary: 'Weight gain is progressing within your target band.',
      weightTrendAnalysis:
          'Your 3-week weight trend averages +0.20 kg/week vs target 0.15–0.25 kg/week.',
      workoutContextAnalysis:
          'Bench Press improved from 95 kg × 8 to 100 kg × 8 with steady working volume.',
      actionableTakeaways: const [
        'Keep daily calories unchanged for the coming week.',
        'Aim for 1–2 extra reps on compound lifts.',
        'Log at least 4 weight entries per week for higher confidence.',
      ],
      assessedWeekStartIso: '2026-10-12',
      isAssessedWeekPartial: isAssessedWeekPartial,
      currentPaceKgPerWeek: 0.20,
      targetMinKgPerWeek: 0.15,
      targetMaxKgPerWeek: 0.25,
      priorWeightWeeksCount: 2,
      localeCode: 'en',
      fingerprint: 'fp_report',
      generatedAt: refNow,
    );
  }

  group('PaceAssessmentReportBottomSheet', () {
    testWidgets(
      'presents modal bottom sheet with header, partial-week badge, baseline comparison note, and 3 report sections in English',
      (tester) async {
        final assessment = buildAssessment(
          status: PaceAssessmentStatus.onTarget,
          baselineStatus: PaceAssessmentStatus.tooSlow,
          isAssessedWeekPartial: true,
        );

        await tester.pumpApp(
          Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => PaceAssessmentReportBottomSheet.show(
                    context,
                    assessment,
                    assessedWeekLoggedDays: 3,
                  ),
                  child: const Text('Open Report'),
                );
              },
            ),
          ),
          locale: const Locale('en'),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Report'));
        await tester.pumpAndSettle();

        expect(find.byType(PaceAssessmentReportBottomSheet), findsOneWidget);
        expect(find.text('AI Pace Assessment Report'), findsOneWidget);
        expect(find.text('On target'), findsOneWidget);
        expect(find.text('Partial week (3/7 days)'), findsOneWidget);
        expect(find.text('Baseline pace status: Too slow'), findsOneWidget);

        // Sections
        expect(
          find.byKey(const Key('pace_report_weight_section')),
          findsOneWidget,
        );
        expect(find.text('Weight Trend vs. Target'), findsOneWidget);
        expect(
          find.text(
            'Your 3-week weight trend averages +0.20 kg/week vs target 0.15–0.25 kg/week.',
          ),
          findsOneWidget,
        );

        expect(
          find.byKey(const Key('pace_report_workout_section')),
          findsOneWidget,
        );
        expect(find.text('Workout & Strength Context'), findsOneWidget);
        expect(
          find.text(
            'Bench Press improved from 95 kg × 8 to 100 kg × 8 with steady working volume.',
          ),
          findsOneWidget,
        );

        await tester.scrollUntilVisible(
          find.byKey(const Key('pace_report_takeaways_section')),
          100,
        );
        expect(
          find.byKey(const Key('pace_report_takeaways_section')),
          findsOneWidget,
        );
        expect(find.text('Actionable Takeaways'), findsOneWidget);
        expect(
          find.text('Keep daily calories unchanged for the coming week.'),
          findsOneWidget,
        );
        expect(
          find.text('Aim for 1–2 extra reps on compound lifts.'),
          findsOneWidget,
        );

        // Close button dismisses bottom sheet
        await tester.tap(find.byKey(const Key('pace_report_close_button')));
        await tester.pumpAndSettle();

        expect(find.byType(PaceAssessmentReportBottomSheet), findsNothing);
      },
    );

    testWidgets(
      'renders localized Polish headers and omits baseline label when status matches baselineStatus',
      (tester) async {
        final assessment = buildAssessment(
          status: PaceAssessmentStatus.tooFast,
          baselineStatus: PaceAssessmentStatus.tooFast,
          isAssessedWeekPartial: false,
        );

        await tester.pumpApp(
          Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () =>
                      PaceAssessmentReportBottomSheet.show(context, assessment),
                  child: const Text('Open Report PL'),
                );
              },
            ),
          ),
          locale: const Locale('pl'),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Report PL'));
        await tester.pumpAndSettle();

        expect(find.text('Raport oceny tempa AI'), findsOneWidget);
        expect(find.text('Tempo za szybkie'), findsOneWidget);
        expect(find.textContaining('Bazowy status z wagi:'), findsNothing);
        expect(find.text('Trend masy względem celu'), findsOneWidget);
        expect(find.text('Kontekst treningowy i siłowy'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.byKey(const Key('pace_report_takeaways_section')),
          100,
        );
        expect(find.text('Wskazówki na kolejny tydzień'), findsOneWidget);
      },
    );
  });
}
