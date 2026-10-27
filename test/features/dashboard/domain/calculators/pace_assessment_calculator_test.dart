import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/dashboard/domain/calculators/pace_assessment_calculator.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/pace_assessment_entity.dart';
import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';
import 'package:bulk_tempo/features/weight/domain/models/weekly_weight_summary_entity.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/weekly_workout_summary_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_exercise_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_set_entity.dart';
import 'package:flutter_test/flutter_test.dart';

WeeklyWeightSummaryEntity _createWeightSummary({
  required String weekStartIso,
  required double averageWeightKg,
  int loggedDaysCount = 7,
}) {
  final monday = WeekDateUtils.tryParseIsoDate(weekStartIso)!;
  final sunday = WeekDateUtils.endOfIsoWeekUtc(monday);
  final entries = List.generate(
    loggedDaysCount,
    (i) => WeightEntryEntity(
      dateIso: WeekDateUtils.toIsoDateString(monday.add(Duration(days: i))),
      date: monday.add(Duration(days: i)),
      weightKg: averageWeightKg,
      updatedAt: monday,
    ),
  );
  return WeeklyWeightSummaryEntity(
    weekStartIso: weekStartIso,
    weekStartMonday: monday,
    weekEndSunday: sunday,
    averageWeightKg: averageWeightKg,
    entries: entries,
  );
}

WorkoutEntity _createWorkout({
  required String id,
  required String localDateIso,
  required DateTime startTime,
  required List<WorkoutExerciseEntity> exercises,
}) {
  final date = WeekDateUtils.tryParseIsoDate(localDateIso)!;
  return WorkoutEntity(
    id: id,
    title: 'Workout $id',
    startTime: startTime,
    endTime: startTime.add(const Duration(hours: 1)),
    localDate: date,
    localDateIso: localDateIso,
    exercises: exercises,
  );
}

WeeklyWorkoutSummaryEntity _createWorkoutSummary({
  required String weekStartIso,
  List<WorkoutEntity>? workouts,
  int workoutCount = 2,
}) {
  final monday = WeekDateUtils.tryParseIsoDate(weekStartIso)!;
  final sunday = WeekDateUtils.endOfIsoWeekUtc(monday);
  if (workouts != null) {
    final totalSets = workouts.fold<int>(
      0,
      (sum, w) => sum + w.workingSetsCount,
    );
    final totalVol = WeekDateUtils.roundToTwoDecimals(
      workouts.fold<double>(0.0, (sum, w) => sum + w.totalVolumeKg),
    );
    return WeeklyWorkoutSummaryEntity(
      weekStartIso: weekStartIso,
      weekStartMonday: monday,
      weekEndSunday: sunday,
      workouts: workouts,
      workoutCount: workouts.length,
      totalWorkingSets: totalSets,
      totalVolumeKg: totalVol,
    );
  }

  if (workoutCount <= 0) {
    return WeeklyWorkoutSummaryEntity(
      weekStartIso: weekStartIso,
      weekStartMonday: monday,
      weekEndSunday: sunday,
      workouts: const [],
      workoutCount: 0,
      totalWorkingSets: 0,
      totalVolumeKg: 0.0,
    );
  }

  final defaultWorkouts = List.generate(
    workoutCount,
    (index) => _createWorkout(
      id: 'w_${weekStartIso}_$index',
      localDateIso: weekStartIso,
      startTime: monday.add(Duration(hours: 10 + index)),
      exercises: [
        const WorkoutExerciseEntity(
          index: 0,
          title: 'Bench Press',
          exerciseTemplateId: 'bench_press',
          sets: [
            WorkoutSetEntity(index: 0, type: 'normal', weightKg: 80.0, reps: 8),
          ],
        ),
      ],
    ),
  );

  return _createWorkoutSummary(
    weekStartIso: weekStartIso,
    workouts: defaultWorkouts,
  );
}

void main() {
  group('PaceAssessmentCalculator', () {
    // Reference date: Wednesday 2026-10-14.
    // Current ISO week Monday: 2026-10-12 (Sunday 2026-10-18).
    // Previous ISO week Monday: 2026-10-05.
    // 12-week window starts at: 2026-07-27.
    final refNow = DateTime.utc(2026, 10, 14, 15, 30);
    const defaultTarget = GainTargetEntity(
      minWeeklyGainKg: 0.15,
      maxWeeklyGainKg: 0.25,
    );

    group('computeBaselineStatus', () {
      test('returns stagnant when paceKgPerWeek <= 0.0', () {
        expect(
          PaceAssessmentCalculator.computeBaselineStatus(
            paceKgPerWeek: 0.0,
            target: defaultTarget,
          ),
          equals(PaceAssessmentStatus.stagnant),
        );
        expect(
          PaceAssessmentCalculator.computeBaselineStatus(
            paceKgPerWeek: -0.20,
            target: defaultTarget,
          ),
          equals(PaceAssessmentStatus.stagnant),
        );
      });

      test('returns tooSlow when 0.0 < paceKgPerWeek < minWeeklyGainKg', () {
        expect(
          PaceAssessmentCalculator.computeBaselineStatus(
            paceKgPerWeek: 0.01,
            target: defaultTarget,
          ),
          equals(PaceAssessmentStatus.tooSlow),
        );
        expect(
          PaceAssessmentCalculator.computeBaselineStatus(
            paceKgPerWeek: 0.14,
            target: defaultTarget,
          ),
          equals(PaceAssessmentStatus.tooSlow),
        );
      });

      test(
        'returns onTarget when minWeeklyGainKg <= paceKgPerWeek <= maxWeeklyGainKg',
        () {
          expect(
            PaceAssessmentCalculator.computeBaselineStatus(
              paceKgPerWeek: 0.15,
              target: defaultTarget,
            ),
            equals(PaceAssessmentStatus.onTarget),
          );
          expect(
            PaceAssessmentCalculator.computeBaselineStatus(
              paceKgPerWeek: 0.20,
              target: defaultTarget,
            ),
            equals(PaceAssessmentStatus.onTarget),
          );
          expect(
            PaceAssessmentCalculator.computeBaselineStatus(
              paceKgPerWeek: 0.25,
              target: defaultTarget,
            ),
            equals(PaceAssessmentStatus.onTarget),
          );
        },
      );

      test('returns tooFast when paceKgPerWeek > maxWeeklyGainKg', () {
        expect(
          PaceAssessmentCalculator.computeBaselineStatus(
            paceKgPerWeek: 0.26,
            target: defaultTarget,
          ),
          equals(PaceAssessmentStatus.tooFast),
        );
        expect(
          PaceAssessmentCalculator.computeBaselineStatus(
            paceKgPerWeek: 0.50,
            target: defaultTarget,
          ),
          equals(PaceAssessmentStatus.tooFast),
        );
      });
    });

    group('evaluateEligibility - ineligibility checks', () {
      final eligibleWeights = [
        _createWeightSummary(
          weekStartIso: '2026-09-21',
          averageWeightKg: 80.00,
        ),
        _createWeightSummary(
          weekStartIso: '2026-09-28',
          averageWeightKg: 80.20,
        ),
        _createWeightSummary(
          weekStartIso: '2026-10-12',
          averageWeightKg: 80.60,
        ),
      ];
      final eligibleWorkouts = [
        _createWorkoutSummary(weekStartIso: '2026-10-12', workoutCount: 3),
      ];

      test('returns missingGainTarget when gainTarget is null or invalid', () {
        final nullResult = PaceAssessmentCalculator.evaluateEligibility(
          weightSummaries: eligibleWeights,
          workoutSummaries: eligibleWorkouts,
          isWorkoutConfigured: true,
          gainTarget: null,
          localeCode: 'en',
          now: refNow,
        );

        expect(
          nullResult,
          equals(
            const PaceAssessmentIneligible(
              PaceAssessmentIneligibilityReason.missingGainTarget,
              recordedWeightWeeksCount: 3,
              priorWeightWeeksCount: 2,
            ),
          ),
        );

        final invalidResult = PaceAssessmentCalculator.evaluateEligibility(
          weightSummaries: eligibleWeights,
          workoutSummaries: eligibleWorkouts,
          isWorkoutConfigured: true,
          gainTarget: const GainTargetEntity(
            minWeeklyGainKg: 0.30,
            maxWeeklyGainKg: 0.20,
          ),
          localeCode: 'en',
          now: refNow,
        );

        expect(
          invalidResult,
          equals(
            const PaceAssessmentIneligible(
              PaceAssessmentIneligibilityReason.missingGainTarget,
              recordedWeightWeeksCount: 3,
              priorWeightWeeksCount: 2,
            ),
          ),
        );
      });

      test('returns workoutUnconfigured when isWorkoutConfigured is false', () {
        final result = PaceAssessmentCalculator.evaluateEligibility(
          weightSummaries: eligibleWeights,
          workoutSummaries: eligibleWorkouts,
          isWorkoutConfigured: false,
          gainTarget: defaultTarget,
          localeCode: 'en',
          now: refNow,
        );

        expect(
          result,
          equals(
            const PaceAssessmentIneligible(
              PaceAssessmentIneligibilityReason.workoutUnconfigured,
              recordedWeightWeeksCount: 3,
              priorWeightWeeksCount: 2,
            ),
          ),
        );
      });

      test(
        'returns noWorkoutsInWindow when workoutSummaries in 12-week window has 0 workouts',
        () {
          final emptyResult = PaceAssessmentCalculator.evaluateEligibility(
            weightSummaries: eligibleWeights,
            workoutSummaries: const [],
            isWorkoutConfigured: true,
            gainTarget: defaultTarget,
            localeCode: 'en',
            now: refNow,
          );

          expect(
            emptyResult,
            equals(
              const PaceAssessmentIneligible(
                PaceAssessmentIneligibilityReason.noWorkoutsInWindow,
                recordedWeightWeeksCount: 3,
                priorWeightWeeksCount: 2,
              ),
            ),
          );

          // Workout outside the 12-week window (before 2026-07-27) + zero-workout week inside window
          final outsideWindowResult =
              PaceAssessmentCalculator.evaluateEligibility(
                weightSummaries: eligibleWeights,
                workoutSummaries: [
                  _createWorkoutSummary(
                    weekStartIso: '2026-07-20',
                    workoutCount: 4,
                  ),
                  _createWorkoutSummary(
                    weekStartIso: '2026-10-12',
                    workoutCount: 0,
                  ),
                ],
                isWorkoutConfigured: true,
                gainTarget: defaultTarget,
                localeCode: 'en',
                now: refNow,
              );

          expect(
            outsideWindowResult,
            equals(
              const PaceAssessmentIneligible(
                PaceAssessmentIneligibilityReason.noWorkoutsInWindow,
                recordedWeightWeeksCount: 3,
                priorWeightWeeksCount: 2,
              ),
            ),
          );
        },
      );

      test(
        'returns insufficientWeightWeeks when fewer than 2 prior recorded weight weeks exist in 12-week window',
        () {
          // 0 weight weeks
          final zeroWeeks = PaceAssessmentCalculator.evaluateEligibility(
            weightSummaries: const [],
            workoutSummaries: eligibleWorkouts,
            isWorkoutConfigured: true,
            gainTarget: defaultTarget,
            localeCode: 'en',
            now: refNow,
          );
          expect(
            zeroWeeks,
            equals(
              const PaceAssessmentIneligible(
                PaceAssessmentIneligibilityReason.insufficientWeightWeeks,
                recordedWeightWeeksCount: 0,
                priorWeightWeeksCount: 0,
              ),
            ),
          );

          // 1 weight week (current week only -> 0 prior weeks)
          final oneWeek = PaceAssessmentCalculator.evaluateEligibility(
            weightSummaries: [
              _createWeightSummary(
                weekStartIso: '2026-10-12',
                averageWeightKg: 80.50,
              ),
            ],
            workoutSummaries: eligibleWorkouts,
            isWorkoutConfigured: true,
            gainTarget: defaultTarget,
            localeCode: 'en',
            now: refNow,
          );
          expect(
            oneWeek,
            equals(
              const PaceAssessmentIneligible(
                PaceAssessmentIneligibilityReason.insufficientWeightWeeks,
                recordedWeightWeeksCount: 1,
                priorWeightWeeksCount: 0,
              ),
            ),
          );

          // 2 weight weeks in window + 1 outside window (2026-07-20 is before 2026-07-27) -> only 1 prior week in window
          final twoWeeksInWindow = PaceAssessmentCalculator.evaluateEligibility(
            weightSummaries: [
              _createWeightSummary(
                weekStartIso: '2026-07-20',
                averageWeightKg: 79.50,
              ),
              _createWeightSummary(
                weekStartIso: '2026-10-05',
                averageWeightKg: 80.30,
              ),
              _createWeightSummary(
                weekStartIso: '2026-10-12',
                averageWeightKg: 80.50,
              ),
            ],
            workoutSummaries: eligibleWorkouts,
            isWorkoutConfigured: true,
            gainTarget: defaultTarget,
            localeCode: 'en',
            now: refNow,
          );
          expect(
            twoWeeksInWindow,
            equals(
              const PaceAssessmentIneligible(
                PaceAssessmentIneligibilityReason.insufficientWeightWeeks,
                recordedWeightWeeksCount: 2,
                priorWeightWeeksCount: 1,
              ),
            ),
          );
        },
      );

      test(
        'returns insufficientWeightWeeks when latest weight week in window is stale (>1 week old)',
        () {
          // 3 recorded weeks in window, but latest is 2026-09-28 (2 weeks before current week 2026-10-12)
          final staleResult = PaceAssessmentCalculator.evaluateEligibility(
            weightSummaries: [
              _createWeightSummary(
                weekStartIso: '2026-09-14',
                averageWeightKg: 80.00,
              ),
              _createWeightSummary(
                weekStartIso: '2026-09-21',
                averageWeightKg: 80.20,
              ),
              _createWeightSummary(
                weekStartIso: '2026-09-28',
                averageWeightKg: 80.40,
              ),
            ],
            workoutSummaries: eligibleWorkouts,
            isWorkoutConfigured: true,
            gainTarget: defaultTarget,
            localeCode: 'en',
            now: refNow,
          );

          expect(
            staleResult,
            equals(
              const PaceAssessmentIneligible(
                PaceAssessmentIneligibilityReason.insufficientWeightWeeks,
                recordedWeightWeeksCount: 3,
                priorWeightWeeksCount: 2,
              ),
            ),
          );
        },
      );
    });

    group('evaluateEligibility - eligible context & aggregation', () {
      test(
        'eligible current partial week (loggedDaysCount < 7) + 2 non-adjacent prior weight weeks + 0-workout rest week in window',
        () {
          // Current week: 2026-10-12 (3 days logged -> partial week)
          // Prior weight week 2: 2026-09-28 (7 days logged, 0 workouts -> rest week)
          // Prior weight week 1: 2026-09-07 (7 days logged, 2 workouts; non-adjacent to 2026-09-28)
          final weights = [
            _createWeightSummary(
              weekStartIso: '2026-10-12',
              averageWeightKg: 80.60,
              loggedDaysCount: 3,
            ),
            _createWeightSummary(
              weekStartIso: '2026-09-07',
              averageWeightKg: 79.60,
              loggedDaysCount: 7,
            ),
            _createWeightSummary(
              weekStartIso: '2026-09-28',
              averageWeightKg: 80.20,
              loggedDaysCount: 7,
            ),
          ];

          final workouts = [
            _createWorkoutSummary(weekStartIso: '2026-09-07', workoutCount: 2),
            // 2026-09-28 intentionally has 0 workouts (rest/deload week)
            _createWorkoutSummary(weekStartIso: '2026-10-12', workoutCount: 3),
          ];

          final result = PaceAssessmentCalculator.evaluateEligibility(
            weightSummaries: weights,
            workoutSummaries: workouts,
            isWorkoutConfigured: true,
            gainTarget: defaultTarget,
            localeCode: 'PL',
            now: refNow,
          );

          expect(result, isA<PaceAssessmentEligible>());
          final input = (result as PaceAssessmentEligible).input;

          expect(input.localeCode, equals('pl'));
          expect(input.gainTarget, equals(defaultTarget));
          // Pace from 2026-09-28 (80.20) to 2026-10-12 (80.60) over 2 weeks = +0.20 kg/wk
          expect(input.currentPaceKgPerWeek, equals(0.20));
          expect(input.baselineStatus, equals(PaceAssessmentStatus.onTarget));

          // Assessed week checks
          expect(input.assessedWeek.weekStartIso, equals('2026-10-12'));
          expect(input.assessedWeek.averageWeightKg, equals(80.60));
          expect(input.assessedWeek.loggedWeightDaysCount, equals(3));
          expect(input.assessedWeek.isCurrentWeek, isTrue);
          expect(input.assessedWeek.isPartialWeek, isTrue);
          expect(input.assessedWeek.paceKgPerWeek, equals(0.20));
          expect(input.assessedWeek.workoutCount, equals(3));
          expect(input.assessedWeek.totalWorkingSets, equals(3));
          expect(input.assessedWeek.totalVolumeKg, equals(1920.0));
          expect(input.assessedWeek.exercises, hasLength(1));

          // Prior weeks checks (sorted chronologically: 2026-09-07, then 2026-09-28)
          expect(input.priorWeeks, hasLength(2));
          final prior1 = input.priorWeeks[0];
          expect(prior1.weekStartIso, equals('2026-09-07'));
          expect(prior1.averageWeightKg, equals(79.60));
          expect(prior1.loggedWeightDaysCount, equals(7));
          expect(prior1.isCurrentWeek, isFalse);
          expect(prior1.isPartialWeek, isFalse);
          expect(prior1.paceKgPerWeek, isNull);
          expect(prior1.workoutCount, equals(2));

          final prior2RestWeek = input.priorWeeks[1];
          expect(prior2RestWeek.weekStartIso, equals('2026-09-28'));
          expect(prior2RestWeek.averageWeightKg, equals(80.20));
          expect(prior2RestWeek.loggedWeightDaysCount, equals(7));
          expect(prior2RestWeek.isCurrentWeek, isFalse);
          expect(prior2RestWeek.isPartialWeek, isFalse);
          // Pace from 2026-09-07 (79.60) to 2026-09-28 (80.20) over 3 weeks = +0.20 kg/wk
          expect(prior2RestWeek.paceKgPerWeek, equals(0.20));
          // Rest week has 0 workouts and empty exercises
          expect(prior2RestWeek.workoutCount, equals(0));
          expect(prior2RestWeek.totalWorkingSets, equals(0));
          expect(prior2RestWeek.totalVolumeKg, equals(0.0));
          expect(prior2RestWeek.exercises, isEmpty);
        },
      );

      test(
        'eligible when latest weight week is immediately preceding ISO week',
        () {
          final weights = [
            _createWeightSummary(
              weekStartIso: '2026-09-21',
              averageWeightKg: 80.00,
            ),
            _createWeightSummary(
              weekStartIso: '2026-09-28',
              averageWeightKg: 80.10,
            ),
            _createWeightSummary(
              weekStartIso: '2026-10-05',
              averageWeightKg: 80.15,
              loggedDaysCount: 7,
            ),
          ];
          final workouts = [
            _createWorkoutSummary(weekStartIso: '2026-10-05', workoutCount: 2),
          ];

          final result = PaceAssessmentCalculator.evaluateEligibility(
            weightSummaries: weights,
            workoutSummaries: workouts,
            isWorkoutConfigured: true,
            gainTarget: defaultTarget,
            localeCode: 'en',
            now: refNow,
          );

          expect(result, isA<PaceAssessmentEligible>());
          final input = (result as PaceAssessmentEligible).input;
          expect(input.assessedWeek.weekStartIso, equals('2026-10-05'));
          expect(input.assessedWeek.isCurrentWeek, isFalse);
          expect(input.assessedWeek.isPartialWeek, isFalse);
          expect(input.currentPaceKgPerWeek, equals(0.05));
          expect(input.baselineStatus, equals(PaceAssessmentStatus.tooSlow));
        },
      );

      test(
        'per-exercise bestWorkingSet tie-breaking and volume aggregation across multiple workouts in the same week',
        () {
          final monday = DateTime.utc(2026, 10, 12);
          final workout1 = _createWorkout(
            id: 'w1',
            localDateIso: '2026-10-12',
            startTime: monday.add(const Duration(hours: 9)),
            exercises: [
              const WorkoutExerciseEntity(
                index: 0,
                title: 'Bench Press',
                exerciseTemplateId: 'bench_press',
                sets: [
                  // Warmup set with heavier weight must be ignored
                  WorkoutSetEntity(
                    index: 0,
                    type: 'warmup',
                    weightKg: 100.0,
                    reps: 5,
                  ),
                  WorkoutSetEntity(
                    index: 1,
                    type: 'normal',
                    weightKg: 80.0,
                    reps: 8,
                  ),
                  WorkoutSetEntity(
                    index: 2,
                    type: 'normal',
                    weightKg: 85.0,
                    reps: 5,
                  ),
                ],
              ),
              const WorkoutExerciseEntity(
                index: 1,
                title: ' Pull Up ',
                exerciseTemplateId: '',
                sets: [
                  WorkoutSetEntity(
                    index: 0,
                    type: 'normal',
                    weightKg: 10.0,
                    reps: 6,
                  ),
                ],
              ),
            ],
          );

          final workout2 = _createWorkout(
            id: 'w2',
            localDateIso: '2026-10-15',
            startTime: monday.add(const Duration(days: 3, hours: 9)),
            exercises: [
              const WorkoutExerciseEntity(
                index: 0,
                title: 'Bench Press',
                exerciseTemplateId: 'bench_press',
                sets: [
                  // Same 85.0 kg top weight as workout1, but 6 reps beats 5 reps!
                  WorkoutSetEntity(
                    index: 0,
                    type: 'normal',
                    weightKg: 85.0,
                    reps: 6,
                  ),
                  // More reps (10) at lower weight (82.5) loses to 85.0 kg
                  WorkoutSetEntity(
                    index: 1,
                    type: 'normal',
                    weightKg: 82.5,
                    reps: 10,
                  ),
                ],
              ),
              const WorkoutExerciseEntity(
                index: 1,
                title: 'pull up',
                exerciseTemplateId: '',
                sets: [
                  // Higher weight (12.5 kg x 4) beats 10.0 kg x 6
                  WorkoutSetEntity(
                    index: 0,
                    type: 'normal',
                    weightKg: 12.5,
                    reps: 4,
                  ),
                ],
              ),
            ],
          );

          final workoutSummary = _createWorkoutSummary(
            weekStartIso: '2026-10-12',
            workouts: [workout2, workout1],
          );

          final result = PaceAssessmentCalculator.evaluateEligibility(
            weightSummaries: [
              _createWeightSummary(
                weekStartIso: '2026-09-28',
                averageWeightKg: 80.00,
              ),
              _createWeightSummary(
                weekStartIso: '2026-10-05',
                averageWeightKg: 80.20,
              ),
              _createWeightSummary(
                weekStartIso: '2026-10-12',
                averageWeightKg: 80.40,
              ),
            ],
            workoutSummaries: [workoutSummary],
            isWorkoutConfigured: true,
            gainTarget: defaultTarget,
            localeCode: 'en',
            now: refNow,
          );

          expect(result, isA<PaceAssessmentEligible>());
          final exercises =
              (result as PaceAssessmentEligible).input.assessedWeek.exercises;
          expect(exercises, hasLength(2));

          final bench = exercises[0];
          expect(bench.exerciseTemplateId, equals('bench_press'));
          expect(bench.title, equals('Bench Press'));
          expect(bench.workingSetsCount, equals(4));
          // Volume: (80*8 + 85*5) + (85*6 + 82.5*10) = 1065 + 1335 = 2400.0
          expect(bench.totalVolumeKg, equals(2400.0));
          expect(bench.bestWeightKg, equals(85.0));
          expect(bench.bestReps, equals(6));

          final pullUp = exercises[1];
          expect(pullUp.exerciseTemplateId, isEmpty);
          expect(pullUp.title, equals('Pull Up'));
          expect(pullUp.workingSetsCount, equals(2));
          // Volume: (10*6) + (12.5*4) = 60 + 50 = 110.0
          expect(pullUp.totalVolumeKg, equals(110.0));
          expect(pullUp.bestWeightKg, equals(12.5));
          expect(pullUp.bestReps, equals(4));
        },
      );

      test(
        'fingerprint is deterministic and sensitive to weight, workout, target, and locale changes',
        () {
          final w1 = _createWeightSummary(
            weekStartIso: '2026-09-28',
            averageWeightKg: 80.00,
          );
          final w2 = _createWeightSummary(
            weekStartIso: '2026-10-05',
            averageWeightKg: 80.20,
          );
          final w3 = _createWeightSummary(
            weekStartIso: '2026-10-12',
            averageWeightKg: 80.40,
          );
          final wo = _createWorkoutSummary(
            weekStartIso: '2026-10-12',
            workoutCount: 3,
          );

          final baseResult =
              PaceAssessmentCalculator.evaluateEligibility(
                    weightSummaries: [w1, w2, w3],
                    workoutSummaries: [wo],
                    isWorkoutConfigured: true,
                    gainTarget: defaultTarget,
                    localeCode: 'en',
                    now: refNow,
                  )
                  as PaceAssessmentEligible;

          // Reordered input lists and different time on same day produce identical fingerprint
          final reorderedResult =
              PaceAssessmentCalculator.evaluateEligibility(
                    weightSummaries: [w3, w1, w2],
                    workoutSummaries: [wo],
                    isWorkoutConfigured: true,
                    gainTarget: defaultTarget,
                    localeCode: ' EN ',
                    now: DateTime.utc(2026, 10, 16, 8, 0),
                  )
                  as PaceAssessmentEligible;

          expect(
            reorderedResult.input.fingerprint,
            equals(baseResult.input.fingerprint),
          );

          // 1. Sensitive to weight change
          final weightChangedResult =
              PaceAssessmentCalculator.evaluateEligibility(
                    weightSummaries: [
                      w1,
                      w2,
                      _createWeightSummary(
                        weekStartIso: '2026-10-12',
                        averageWeightKg: 80.45,
                      ),
                    ],
                    workoutSummaries: [wo],
                    isWorkoutConfigured: true,
                    gainTarget: defaultTarget,
                    localeCode: 'en',
                    now: refNow,
                  )
                  as PaceAssessmentEligible;
          expect(
            weightChangedResult.input.fingerprint,
            isNot(equals(baseResult.input.fingerprint)),
          );

          // 2. Sensitive to workout change
          final workoutChangedResult =
              PaceAssessmentCalculator.evaluateEligibility(
                    weightSummaries: [w1, w2, w3],
                    workoutSummaries: [
                      _createWorkoutSummary(
                        weekStartIso: '2026-10-12',
                        workoutCount: 4,
                      ),
                    ],
                    isWorkoutConfigured: true,
                    gainTarget: defaultTarget,
                    localeCode: 'en',
                    now: refNow,
                  )
                  as PaceAssessmentEligible;
          expect(
            workoutChangedResult.input.fingerprint,
            isNot(equals(baseResult.input.fingerprint)),
          );

          // 3. Sensitive to target change
          final targetChangedResult =
              PaceAssessmentCalculator.evaluateEligibility(
                    weightSummaries: [w1, w2, w3],
                    workoutSummaries: [wo],
                    isWorkoutConfigured: true,
                    gainTarget: const GainTargetEntity(
                      minWeeklyGainKg: 0.20,
                      maxWeeklyGainKg: 0.30,
                    ),
                    localeCode: 'en',
                    now: refNow,
                  )
                  as PaceAssessmentEligible;
          expect(
            targetChangedResult.input.fingerprint,
            isNot(equals(baseResult.input.fingerprint)),
          );

          // 4. Sensitive to locale change
          final localeChangedResult =
              PaceAssessmentCalculator.evaluateEligibility(
                    weightSummaries: [w1, w2, w3],
                    workoutSummaries: [wo],
                    isWorkoutConfigured: true,
                    gainTarget: defaultTarget,
                    localeCode: 'pl',
                    now: refNow,
                  )
                  as PaceAssessmentEligible;
          expect(
            localeChangedResult.input.fingerprint,
            isNot(equals(baseResult.input.fingerprint)),
          );
        },
      );
    });
  });
}
