import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/features/workout/domain/models/weekly_workout_summary_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_exercise_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_set_entity.dart';

void main() {
  group('WorkoutSetEntity', () {
    test('identifies working sets and excludes warmup from volumeKg', () {
      const warmup = WorkoutSetEntity(
        index: 0,
        type: 'warmup',
        weightKg: 60.0,
        reps: 10,
      );
      const normal = WorkoutSetEntity(
        index: 1,
        type: 'normal',
        weightKg: 82.5,
        reps: 8,
      );
      const failure = WorkoutSetEntity(
        index: 2,
        type: 'failure',
        weightKg: 82.5,
        reps: 6,
      );
      const dropset = WorkoutSetEntity(
        index: 3,
        type: 'dropset',
        weightKg: 60.125,
        reps: 3,
      );
      const bodyweight = WorkoutSetEntity(
        index: 4,
        type: 'normal',
        weightKg: null,
        reps: 15,
      );

      expect(warmup.isWorkingSet, isFalse);
      expect(warmup.volumeKg, 0.0);

      expect(normal.isWorkingSet, isTrue);
      expect(normal.volumeKg, 660.0);

      expect(failure.isWorkingSet, isTrue);
      expect(failure.volumeKg, 495.0);

      expect(dropset.isWorkingSet, isTrue);
      // 60.125 * 3 = 180.375 -> 180.38
      expect(dropset.volumeKg, 180.38);

      expect(bodyweight.isWorkingSet, isTrue);
      expect(bodyweight.volumeKg, 0.0);
    });

    test('supports value equality and copyWith', () {
      const set1 = WorkoutSetEntity(
        index: 0,
        type: 'normal',
        weightKg: 100.0,
        reps: 5,
        rpe: 8.5,
      );
      const set2 = WorkoutSetEntity(
        index: 0,
        type: 'normal',
        weightKg: 100.0,
        reps: 5,
        rpe: 8.5,
      );

      expect(set1, equals(set2));
      expect(set1.hashCode, equals(set2.hashCode));
      expect(set1.copyWith(reps: 6).reps, 6);
    });
  });

  group('WorkoutExerciseEntity', () {
    test('computes workingSetsCount, totalVolumeKg, and bestWorkingSet with tie-breaking', () {
      const warmupHeavy = WorkoutSetEntity(
        index: 0,
        type: 'warmup',
        weightKg: 120.0,
        reps: 5,
      );
      const set1 = WorkoutSetEntity(
        index: 1,
        type: 'normal',
        weightKg: 100.0,
        reps: 6,
      );
      const set2HigherReps = WorkoutSetEntity(
        index: 2,
        type: 'normal',
        weightKg: 100.0,
        reps: 8,
      );
      const set3Drop = WorkoutSetEntity(
        index: 3,
        type: 'dropset',
        weightKg: 80.0,
        reps: 12,
      );

      const exercise = WorkoutExerciseEntity(
        index: 0,
        title: 'Bench Press (Barbell)',
        exerciseTemplateId: 'tpl_bench',
        sets: [warmupHeavy, set1, set2HigherReps, set3Drop],
      );

      expect(exercise.workingSetsCount, 3);
      // 100*6 (600) + 100*8 (800) + 80*12 (960) = 2360.0
      expect(exercise.totalVolumeKg, 2360.0);
      // Warmup is ignored even if heavier; 100x8 beats 100x6 on reps tie-break
      expect(exercise.bestWorkingSet, equals(set2HigherReps));
    });

    test(
      'selects highest reps for bodyweight exercises (weightKg == null)',
      () {
        const set1 = WorkoutSetEntity(index: 0, type: 'normal', reps: 10);
        const set2 = WorkoutSetEntity(index: 1, type: 'failure', reps: 14);
        const exercise = WorkoutExerciseEntity(
          index: 0,
          title: 'Pull Up',
          exerciseTemplateId: 'tpl_pullup',
          sets: [set1, set2],
        );

        expect(exercise.bestWorkingSet, equals(set2));
      },
    );

    test(
      'returns null bestWorkingSet when no working set has weightKg or reps',
      () {
        const durationOnly = WorkoutSetEntity(
          index: 0,
          type: 'normal',
          durationSeconds: 60,
        );
        const exercise = WorkoutExerciseEntity(
          index: 0,
          title: 'Plank',
          exerciseTemplateId: 'tpl_plank',
          sets: [durationOnly],
        );

        expect(exercise.bestWorkingSet, isNull);
      },
    );
  });

  group('WeeklyWorkoutSummaryEntity.groupWorkoutsByIsoWeek', () {
    WorkoutEntity buildWorkout({
      required String id,
      required DateTime localDate,
      required DateTime startTime,
      required List<WorkoutExerciseEntity> exercises,
    }) {
      final y = localDate.year.toString().padLeft(4, '0');
      final m = localDate.month.toString().padLeft(2, '0');
      final d = localDate.day.toString().padLeft(2, '0');
      return WorkoutEntity(
        id: id,
        title: 'Workout $id',
        startTime: startTime,
        endTime: startTime.add(const Duration(hours: 1)),
        localDate: DateTime.utc(localDate.year, localDate.month, localDate.day),
        localDateIso: '$y-$m-$d',
        exercises: exercises,
      );
    }

    test('returns empty list for empty workouts', () {
      expect(WeeklyWorkoutSummaryEntity.groupWorkoutsByIsoWeek([]), isEmpty);
    });

    test('groups workouts by ISO Monday of localDate, sorts newest first, and sums metrics', () {
      const ex1 = WorkoutExerciseEntity(
        index: 0,
        title: 'Squat',
        exerciseTemplateId: 'sq',
        sets: [
          WorkoutSetEntity(index: 0, type: 'warmup', weightKg: 60.0, reps: 10),
          WorkoutSetEntity(index: 1, type: 'normal', weightKg: 100.0, reps: 5),
          WorkoutSetEntity(index: 2, type: 'normal', weightKg: 100.0, reps: 5),
        ],
      );
      const ex2 = WorkoutExerciseEntity(
        index: 0,
        title: 'Deadlift',
        exerciseTemplateId: 'dl',
        sets: [
          WorkoutSetEntity(index: 0, type: 'normal', weightKg: 140.0, reps: 5),
        ],
      );

      // Week 1: Monday 2026-09-28 .. Sunday 2026-10-04
      final sundayWeek1 = buildWorkout(
        id: 'w_sun',
        localDate: DateTime.utc(2026, 10, 4),
        startTime: DateTime.utc(2026, 10, 4, 15),
        exercises: const [ex1], // 2 working sets, 1000.0 kg
      );

      // Week 2: Monday 2026-10-05 .. Sunday 2026-10-11
      final mondayWeek2 = buildWorkout(
        id: 'w_mon',
        localDate: DateTime.utc(2026, 10, 5),
        startTime: DateTime.utc(2026, 10, 5, 9),
        exercises: const [ex1], // 2 working sets, 1000.0 kg
      );
      final thursdayWeek2 = buildWorkout(
        id: 'w_thu',
        localDate: DateTime.utc(2026, 10, 8),
        startTime: DateTime.utc(2026, 10, 8, 18),
        exercises: const [ex2], // 1 working set, 700.0 kg
      );

      final summaries = WeeklyWorkoutSummaryEntity.groupWorkoutsByIsoWeek([
        sundayWeek1,
        mondayWeek2,
        thursdayWeek2,
      ]);

      expect(summaries.length, 2);

      // Newest week first (2026-10-05)
      final latestWeek = summaries[0];
      expect(latestWeek.weekStartIso, '2026-10-05');
      expect(latestWeek.weekStartMonday, DateTime.utc(2026, 10, 5));
      expect(latestWeek.weekEndSunday, DateTime.utc(2026, 10, 11));
      expect(latestWeek.workoutCount, 2);
      expect(latestWeek.totalWorkingSets, 3);
      expect(latestWeek.totalVolumeKg, 1700.0);
      // Workouts within week sorted descending by startTime
      final latestIds = latestWeek.workouts.map((w) => w.id).toList();
      expect(latestIds, ['w_thu', 'w_mon']);

      // Older week second (2026-09-28)
      final olderWeek = summaries[1];
      expect(olderWeek.weekStartIso, '2026-09-28');
      expect(olderWeek.workoutCount, 1);
      expect(olderWeek.totalWorkingSets, 2);
      expect(olderWeek.totalVolumeKg, 1000.0);
    });

    test('deduplicates workouts by id keeping latest startTime', () {
      const exOld = WorkoutExerciseEntity(
        index: 0,
        title: 'Curl',
        exerciseTemplateId: 'curl',
        sets: [
          WorkoutSetEntity(index: 0, type: 'normal', weightKg: 10.0, reps: 10),
        ],
      );
      const exNew = WorkoutExerciseEntity(
        index: 0,
        title: 'Curl',
        exerciseTemplateId: 'curl',
        sets: [
          WorkoutSetEntity(index: 0, type: 'normal', weightKg: 15.0, reps: 10),
        ],
      );

      final dupOlder = buildWorkout(
        id: 'w_dup',
        localDate: DateTime.utc(2026, 10, 6),
        startTime: DateTime.utc(2026, 10, 6, 10),
        exercises: const [exOld],
      );
      final dupNewer = buildWorkout(
        id: 'w_dup',
        localDate: DateTime.utc(2026, 10, 6),
        startTime: DateTime.utc(2026, 10, 6, 12),
        exercises: const [exNew],
      );

      final summaries = WeeklyWorkoutSummaryEntity.groupWorkoutsByIsoWeek([
        dupOlder,
        dupNewer,
      ]);

      expect(summaries.length, 1);
      expect(summaries.first.workoutCount, 1);
      expect(summaries.first.totalVolumeKg, 150.0);
    });
  });
}
