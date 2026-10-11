import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_exercise_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_set_entity.dart';
import 'package:bulk_tempo/features/workout/presentation/widgets/workout_detail_bottom_sheet.dart';

import '../../../../test_helpers/pump_app.dart';

void main() {
  WorkoutEntity createWorkout({required List<WorkoutSetEntity> sets}) {
    final now = DateTime.utc(2026, 10, 6, 17, 0);
    return WorkoutEntity(
      id: 'w1',
      title: 'Leg Day',
      startTime: now,
      endTime: now.add(const Duration(minutes: 60)),
      localDate: DateTime.parse('2026-10-06T00:00:00.000Z'),
      localDateIso: '2026-10-06',
      exercises: [
        WorkoutExerciseEntity(
          index: 0,
          title: 'Barbell Squat',
          exerciseTemplateId: 'ex_squat',
          sets: sets,
        ),
      ],
    );
  }

  group('WorkoutDetailBottomSheet', () {
    testWidgets(
      'renders best set chip with crown icon and golden colors, and does not show Working badge',
      (tester) async {
        final workout = createWorkout(
          sets: const [
            WorkoutSetEntity(index: 0, type: 'warmup', weightKg: 60, reps: 10),
            WorkoutSetEntity(index: 1, type: 'normal', weightKg: 100, reps: 8),
            WorkoutSetEntity(index: 2, type: 'dropset', weightKg: 80, reps: 10),
            WorkoutSetEntity(index: 3, type: 'failure', weightKg: 105, reps: 6),
          ],
        );

        await tester.pumpApp(
          Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () =>
                      WorkoutDetailBottomSheet.show(context, workout),
                  child: const Text('Open'),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // Close button tooltip
        expect(find.byTooltip('Close'), findsOneWidget);

        // Best set chip
        expect(find.byKey(const Key('workout_best_set_0')), findsOneWidget);
        expect(find.text('Best: 105.00 kg × 6'), findsOneWidget);

        // Best set chip decoration has golden background
        final bestSetContainer = tester.widget<Container>(
          find.byKey(const Key('workout_best_set_0')),
        );
        final decoration = bestSetContainer.decoration as BoxDecoration;
        expect(decoration.color, const Color(0xFFFEF3C7));

        // Crown icon is rendered inside best set chip
        expect(find.byType(CustomPaint), findsWidgets);

        // Set badges
        expect(find.text('Warmup'), findsOneWidget);
        expect(find.text('Dropset'), findsOneWidget);
        expect(find.text('Failure'), findsOneWidget);
        // "Working" badge is removed
        expect(find.text('Working'), findsNothing);
      },
    );

    testWidgets(
      'renders without layout overflow on a narrow screen with long exercise title and best set',
      (tester) async {
        tester.view.physicalSize = const Size(300, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final workout = WorkoutEntity(
          id: 'w_narrow',
          title: 'Upper Body Workout',
          startTime: DateTime.utc(2026, 10, 6, 10),
          endTime: DateTime.utc(2026, 10, 6, 11),
          localDate: DateTime.parse('2026-10-06T00:00:00.000Z'),
          localDateIso: '2026-10-06',
          exercises: const [
            WorkoutExerciseEntity(
              index: 0,
              title: 'Incline Dumbbell Bench Press with Pause',
              exerciseTemplateId: 'ex_incline',
              sets: [
                WorkoutSetEntity(
                  index: 0,
                  type: 'normal',
                  weightKg: 120.5,
                  reps: 12,
                ),
              ],
            ),
          ],
        );

        await tester.pumpApp(
          Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () =>
                      WorkoutDetailBottomSheet.show(context, workout),
                  child: const Text('Open'),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('workout_best_set_0')), findsOneWidget);
        expect(
          find.text('Incline Dumbbell Bench Press with Pause'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
