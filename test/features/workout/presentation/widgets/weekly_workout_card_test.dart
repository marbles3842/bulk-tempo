import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/workout/domain/models/weekly_workout_summary_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_entity.dart';
import 'package:bulk_tempo/features/workout/presentation/widgets/weekly_workout_card.dart';

import '../../../../test_helpers/pump_app.dart';

void main() {
  WeeklyWorkoutSummaryEntity createSummary({
    String weekStartIso = '2026-10-05',
    int workoutCount = 2,
  }) {
    final start = DateTime.parse('${weekStartIso}T00:00:00.000Z');
    return WeeklyWorkoutSummaryEntity(
      weekStartIso: weekStartIso,
      weekStartMonday: start,
      weekEndSunday: start.add(const Duration(days: 6)),
      workoutCount: workoutCount,
      totalWorkingSets: 6,
      totalVolumeKg: 1200.0,
      workouts: List.generate(
        workoutCount,
        (i) => WorkoutEntity(
          id: 'w_$i',
          title: 'Workout $i',
          startTime: start.add(Duration(days: i, hours: 10)),
          endTime: start.add(Duration(days: i, hours: 11)),
          localDate: start.add(Duration(days: i)),
          localDateIso: weekStartIso,
          exercises: const [],
        ),
      ),
    );
  }

  group('WeeklyWorkoutCard', () {
    testWidgets(
      'shows workout count chip when collapsed and hides it when expanded with animation',
      (tester) async {
        final summary = createSummary(workoutCount: 3);

        await tester.pumpApp(
          Scaffold(
            body: WeeklyWorkoutCard(summary: summary, initiallyExpanded: false),
          ),
        );
        await tester.pumpAndSettle();

        // When collapsed, the chip is visible
        expect(
          find.byKey(const Key('workout_count_chip_2026-10-05')),
          findsOneWidget,
        );
        expect(find.text('3 workouts'), findsOneWidget);

        final headerText = find.text(
          WeekDateUtils.formatWeekRange(
            summary.weekStartMonday,
            summary.weekEndSunday,
          ),
        );

        // Tap expansion tile header to expand
        await tester.tap(headerText);
        // Advance slightly to verify animation is running
        await tester.pump(const Duration(milliseconds: 100));
        // Settle animation
        await tester.pumpAndSettle();

        // Once expanded, the chip is hidden
        expect(
          find.byKey(const Key('workout_count_chip_2026-10-05')),
          findsNothing,
        );

        // Tap expansion tile header to collapse again
        await tester.tap(headerText);
        await tester.pumpAndSettle();

        // Once collapsed, the chip is visible again
        expect(
          find.byKey(const Key('workout_count_chip_2026-10-05')),
          findsOneWidget,
        );
        expect(find.text('3 workouts'), findsOneWidget);
      },
    );

    testWidgets(
      'initially expanded card starts with workout count chip hidden',
      (tester) async {
        final summary = createSummary(workoutCount: 1);

        await tester.pumpApp(
          Scaffold(
            body: WeeklyWorkoutCard(summary: summary, initiallyExpanded: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('workout_count_chip_2026-10-05')),
          findsNothing,
        );
        expect(find.text('Workout 0'), findsOneWidget);
      },
    );

    testWidgets(
      'updates expansion state and count chip when initiallyExpanded changes',
      (tester) async {
        final summary = createSummary(workoutCount: 2);

        // Start collapsed
        await tester.pumpApp(
          Scaffold(
            body: WeeklyWorkoutCard(summary: summary, initiallyExpanded: false),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('workout_count_chip_2026-10-05')),
          findsOneWidget,
        );

        // Update widget with initiallyExpanded: true
        await tester.pumpApp(
          Scaffold(
            body: WeeklyWorkoutCard(summary: summary, initiallyExpanded: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('workout_count_chip_2026-10-05')),
          findsNothing,
        );
        expect(find.text('Workout 0'), findsOneWidget);

        // Update widget back to initiallyExpanded: false
        await tester.pumpApp(
          Scaffold(
            body: WeeklyWorkoutCard(summary: summary, initiallyExpanded: false),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('workout_count_chip_2026-10-05')),
          findsOneWidget,
        );
      },
    );
  });
}
