import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/workout/data/models/workout_dto.dart';

void main() {
  group('PaginatedWorkoutsResponseDto & WorkoutDto', () {
    test(
      'parses Hevy /v1/workouts JSON payload with nullable set fields and maps to entity',
      () {
        final json = <String, dynamic>{
          'page': 1,
          'page_count': 3,
          'workouts': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'w_123',
              'title': 'Upper Body Power',
              'description': 'Felt strong today',
              'start_time': '2026-10-06T14:30:00Z',
              'end_time': '2026-10-06T15:45:00Z',
              'exercises': <Map<String, dynamic>>[
                <String, dynamic>{
                  'index': 0,
                  'title': 'Bench Press (Barbell)',
                  'notes': 'Pause at chest',
                  'exercise_template_id': '79D0BB3A',
                  'superset_id': null,
                  'sets': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'index': 0,
                      'type': 'warmup',
                      'weight_kg': 60,
                      'reps': 10,
                      'distance_meters': null,
                      'duration_seconds': null,
                      'rpe': null,
                    },
                    <String, dynamic>{
                      'index': 1,
                      'type': 'normal',
                      'weight_kg': 102.5,
                      'reps': 6,
                      'distance_meters': null,
                      'duration_seconds': null,
                      'rpe': 8.5,
                    },
                    <String, dynamic>{
                      'index': 2,
                      'type': 'failure',
                      'weight_kg': null,
                      'reps': 12,
                      'distance_meters': 200.5,
                      'duration_seconds': 45,
                      'rpe': 10,
                    },
                  ],
                },
              ],
            },
          ],
        };

        final pageDto = PaginatedWorkoutsResponseDto.fromJson(json);
        expect(pageDto.page, 1);
        expect(pageDto.pageCount, 3);
        expect(pageDto.workouts.length, 1);

        final workoutDto = pageDto.workouts.first;
        expect(workoutDto.id, 'w_123');
        expect(workoutDto.title, 'Upper Body Power');
        expect(workoutDto.description, 'Felt strong today');

        final entity = workoutDto.toEntity();
        expect(entity.id, 'w_123');
        expect(entity.title, 'Upper Body Power');
        expect(entity.description, 'Felt strong today');
        expect(entity.startTime, DateTime.parse('2026-10-06T14:30:00Z'));
        expect(entity.endTime, DateTime.parse('2026-10-06T15:45:00Z'));

        final expectedLocal = DateTime.parse('2026-10-06T14:30:00Z').toLocal();
        final expectedLocalDate = DateTime.utc(
          expectedLocal.year,
          expectedLocal.month,
          expectedLocal.day,
        );
        expect(entity.localDate, expectedLocalDate);
        expect(
          entity.localDateIso,
          WeekDateUtils.toIsoDateString(expectedLocalDate),
        );

        expect(entity.exercises.length, 1);
        final exercise = entity.exercises.first;
        expect(exercise.title, 'Bench Press (Barbell)');
        expect(exercise.exerciseTemplateId, '79D0BB3A');
        expect(exercise.notes, 'Pause at chest');
        expect(exercise.supersetId, isNull);
        expect(exercise.sets.length, 3);
        expect(exercise.workingSetsCount, 2);

        final set1 = exercise.sets[1];
        expect(set1.type, 'normal');
        expect(set1.weightKg, 102.5);
        expect(set1.reps, 6);
        expect(set1.rpe, 8.5);

        final set2 = exercise.sets[2];
        expect(set2.type, 'failure');
        expect(set2.weightKg, isNull);
        expect(set2.reps, 12);
        expect(set2.distanceMeters, 200.5);
        expect(set2.durationSeconds, 45);
        expect(set2.rpe, 10.0);
      },
    );

    test(
      'throws FormatException when workout id or start_time is missing or invalid',
      () {
        expect(
          () => WorkoutDto.fromJson(<String, dynamic>{
            'id': '',
            'start_time': '2026-10-06T14:30:00Z',
          }),
          throwsFormatException,
        );

        expect(
          () => WorkoutDto.fromJson(<String, dynamic>{
            'id': 'w_1',
            'start_time': 'not-a-timestamp',
          }),
          throwsFormatException,
        );
      },
    );

    test('normalizes set type string casing and trimming', () {
      final setDto = WorkoutSetDto.fromJson(<String, dynamic>{
        'index': 0,
        'type': '  Warmup  ',
        'weight_kg': 50.0,
        'reps': 10,
      });

      expect(setDto.type, 'warmup');
      final entity = setDto.toEntity();
      expect(entity.isWorkingSet, isFalse);
    });
  });
}
