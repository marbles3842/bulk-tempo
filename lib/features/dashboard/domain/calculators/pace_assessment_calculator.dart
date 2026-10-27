import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/pace_assessment_entity.dart';
import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';
import 'package:bulk_tempo/features/weight/domain/models/weekly_weight_summary_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/weekly_workout_summary_entity.dart';
import 'package:bulk_tempo/features/workout/domain/models/workout_set_entity.dart';

/// Result of evaluating whether current user data is eligible for contextual pace assessment.
sealed class PaceAssessmentEligibilityResult {
  const PaceAssessmentEligibilityResult();
}

/// Indicates that all eligibility criteria are satisfied and provides the canonical [input].
final class PaceAssessmentEligible extends PaceAssessmentEligibilityResult {
  final PaceAssessmentInputEntity input;

  const PaceAssessmentEligible(this.input);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaceAssessmentEligible &&
          runtimeType == other.runtimeType &&
          input == other.input;

  @override
  int get hashCode => input.hashCode;

  @override
  String toString() => 'PaceAssessmentEligible(input: $input)';
}

/// Indicates that assessment cannot run yet due to [reason].
final class PaceAssessmentIneligible extends PaceAssessmentEligibilityResult {
  final PaceAssessmentIneligibilityReason reason;
  final int recordedWeightWeeksCount;
  final int priorWeightWeeksCount;

  const PaceAssessmentIneligible(
    this.reason, {
    this.recordedWeightWeeksCount = 0,
    this.priorWeightWeeksCount = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaceAssessmentIneligible &&
          runtimeType == other.runtimeType &&
          reason == other.reason &&
          recordedWeightWeeksCount == other.recordedWeightWeeksCount &&
          priorWeightWeeksCount == other.priorWeightWeeksCount;

  @override
  int get hashCode =>
      Object.hash(reason, recordedWeightWeeksCount, priorWeightWeeksCount);

  @override
  String toString() =>
      'PaceAssessmentIneligible(reason: $reason, recordedWeightWeeksCount: $recordedWeightWeeksCount, priorWeightWeeksCount: $priorWeightWeeksCount)';
}

/// Pure-Dart calculator for pace assessment eligibility, deterministic baseline
/// classification, weekly exercise aggregation, and canonical fingerprinting.
abstract final class PaceAssessmentCalculator {
  static const int windowWeeks = 12;

  /// Computes the deterministic baseline status from [paceKgPerWeek] and [target].
  static PaceAssessmentStatus computeBaselineStatus({
    required double paceKgPerWeek,
    required GainTargetEntity target,
  }) {
    if (paceKgPerWeek <= 0.0) {
      return PaceAssessmentStatus.stagnant;
    }
    if (paceKgPerWeek < target.minWeeklyGainKg) {
      return PaceAssessmentStatus.tooSlow;
    }
    if (paceKgPerWeek <= target.maxWeeklyGainKg) {
      return PaceAssessmentStatus.onTarget;
    }
    return PaceAssessmentStatus.tooFast;
  }

  /// Evaluates eligibility for contextual pace assessment and builds the canonical
  /// [PaceAssessmentInputEntity] when eligible.
  static PaceAssessmentEligibilityResult evaluateEligibility({
    required List<WeeklyWeightSummaryEntity> weightSummaries,
    required List<WeeklyWorkoutSummaryEntity> workoutSummaries,
    required bool isWorkoutConfigured,
    required GainTargetEntity? gainTarget,
    required String localeCode,
    required DateTime now,
  }) {
    final currentMonday = WeekDateUtils.startOfIsoWeekUtc(now);
    final currentWeekIso = WeekDateUtils.toIsoDateString(currentMonday);
    final previousMonday = DateTime.utc(
      currentMonday.year,
      currentMonday.month,
      currentMonday.day - 7,
    );
    final previousWeekIso = WeekDateUtils.toIsoDateString(previousMonday);
    final windowStartMonday = DateTime.utc(
      currentMonday.year,
      currentMonday.month,
      currentMonday.day - (7 * (windowWeeks - 1)),
    );
    final windowStartIso = WeekDateUtils.toIsoDateString(windowStartMonday);

    final sortedWeights = _deduplicateAndSortWeights(weightSummaries);
    final windowWeights = sortedWeights
        .where(
          (w) =>
              w.weekStartIso.compareTo(windowStartIso) >= 0 &&
              w.weekStartIso.compareTo(currentWeekIso) <= 0,
        )
        .toList();

    final recordedWeightWeeksCount = windowWeights.length;
    final hasRecentAssessedWeek =
        windowWeights.isNotEmpty &&
        (windowWeights.last.weekStartIso == currentWeekIso ||
            windowWeights.last.weekStartIso == previousWeekIso);
    final priorWeightWeeksCount = windowWeights.isEmpty
        ? 0
        : windowWeights.length - 1;

    // 1. Gain target check
    if (gainTarget == null || !gainTarget.isValid) {
      return PaceAssessmentIneligible(
        PaceAssessmentIneligibilityReason.missingGainTarget,
        recordedWeightWeeksCount: recordedWeightWeeksCount,
        priorWeightWeeksCount: priorWeightWeeksCount,
      );
    }

    // 2. Hevy workout configuration check
    if (!isWorkoutConfigured) {
      return PaceAssessmentIneligible(
        PaceAssessmentIneligibilityReason.workoutUnconfigured,
        recordedWeightWeeksCount: recordedWeightWeeksCount,
        priorWeightWeeksCount: priorWeightWeeksCount,
      );
    }

    // 3. Workouts in 12-week window check
    final windowWorkoutsByIso = _indexWindowWorkoutsByWeek(
      workoutSummaries: workoutSummaries,
      windowStartIso: windowStartIso,
      currentWeekIso: currentWeekIso,
    );
    final totalWorkoutsInWindow = windowWorkoutsByIso.values.fold<int>(
      0,
      (sum, summary) => sum + summary.workoutCount,
    );
    if (totalWorkoutsInWindow <= 0) {
      return PaceAssessmentIneligible(
        PaceAssessmentIneligibilityReason.noWorkoutsInWindow,
        recordedWeightWeeksCount: recordedWeightWeeksCount,
        priorWeightWeeksCount: priorWeightWeeksCount,
      );
    }

    // 4. Weight eligibility in 12-ISO-week window
    if (!hasRecentAssessedWeek || priorWeightWeeksCount < 2) {
      return PaceAssessmentIneligible(
        PaceAssessmentIneligibilityReason.insufficientWeightWeeks,
        recordedWeightWeeksCount: recordedWeightWeeksCount,
        priorWeightWeeksCount: priorWeightWeeksCount,
      );
    }

    final paceByWeekIso = _computePaceByWeekIso(sortedWeights);
    final assessedWeightWeek = windowWeights.last;
    final currentPace = paceByWeekIso[assessedWeightWeek.weekStartIso];
    if (currentPace == null) {
      return PaceAssessmentIneligible(
        PaceAssessmentIneligibilityReason.insufficientWeightWeeks,
        recordedWeightWeeksCount: recordedWeightWeeksCount,
        priorWeightWeeksCount: priorWeightWeeksCount,
      );
    }

    final weightByIso = {for (final w in windowWeights) w.weekStartIso: w};

    final assessedWeekContext = _buildWeekContext(
      weekStartMonday: assessedWeightWeek.weekStartMonday,
      currentWeekIso: currentWeekIso,
      weightSummary: assessedWeightWeek,
      paceKgPerWeek: currentPace,
      workoutSummary: windowWorkoutsByIso[assessedWeightWeek.weekStartIso],
    );

    // Collect all prior weeks in the 12-week window before assessedWeek that have
    // recorded weights or recorded workouts, sorted chronologically.
    final priorWeekIsos = <String>{
      for (int i = 0; i < windowWeights.length - 1; i++)
        windowWeights[i].weekStartIso,
      for (final entry in windowWorkoutsByIso.entries)
        if (entry.key.compareTo(assessedWeightWeek.weekStartIso) < 0 &&
            entry.value.workoutCount > 0)
          entry.key,
    }.toList()..sort();

    final priorWeeks = priorWeekIsos.map((weekIso) {
      final weight = weightByIso[weekIso];
      final workout = windowWorkoutsByIso[weekIso];
      final monday =
          weight?.weekStartMonday ??
          workout?.weekStartMonday ??
          WeekDateUtils.tryParseIsoDate(weekIso)!;
      return _buildWeekContext(
        weekStartMonday: monday,
        currentWeekIso: currentWeekIso,
        weightSummary: weight,
        paceKgPerWeek: weight != null ? paceByWeekIso[weekIso] : null,
        workoutSummary: workout,
      );
    }).toList();

    final baselineStatus = computeBaselineStatus(
      paceKgPerWeek: currentPace,
      target: gainTarget,
    );
    final normalizedLocale = localeCode.trim().isEmpty
        ? 'en'
        : localeCode.trim().toLowerCase();

    final fingerprint = _computeFingerprint(
      localeCode: normalizedLocale,
      gainTarget: gainTarget,
      assessedWeek: assessedWeekContext,
      priorWeeks: priorWeeks,
      windowWorkoutsByIso: windowWorkoutsByIso,
    );

    return PaceAssessmentEligible(
      PaceAssessmentInputEntity(
        fingerprint: fingerprint,
        localeCode: normalizedLocale,
        gainTarget: gainTarget,
        baselineStatus: baselineStatus,
        currentPaceKgPerWeek: currentPace,
        assessedWeek: assessedWeekContext,
        priorWeeks: List.unmodifiable(priorWeeks),
      ),
    );
  }

  static List<WeeklyWeightSummaryEntity> _deduplicateAndSortWeights(
    List<WeeklyWeightSummaryEntity> summaries,
  ) {
    final Map<String, WeeklyWeightSummaryEntity> deduped = {
      for (final s in summaries)
        if (s.loggedDaysCount > 0) s.weekStartIso: s,
    };
    return deduped.values.toList()
      ..sort((a, b) => a.weekStartIso.compareTo(b.weekStartIso));
  }

  static Map<String, WeeklyWorkoutSummaryEntity> _indexWindowWorkoutsByWeek({
    required List<WeeklyWorkoutSummaryEntity> workoutSummaries,
    required String windowStartIso,
    required String currentWeekIso,
  }) {
    final Map<String, WeeklyWorkoutSummaryEntity> map = {};
    for (final summary in workoutSummaries) {
      if (summary.weekStartIso.compareTo(windowStartIso) >= 0 &&
          summary.weekStartIso.compareTo(currentWeekIso) <= 0) {
        map[summary.weekStartIso] = summary;
      }
    }
    return map;
  }

  static Map<String, double?> _computePaceByWeekIso(
    List<WeeklyWeightSummaryEntity> sortedWeights,
  ) {
    final Map<String, double?> paceMap = {};
    if (sortedWeights.isEmpty) {
      return paceMap;
    }

    paceMap[sortedWeights.first.weekStartIso] = null;
    for (int i = 1; i < sortedWeights.length; i++) {
      final current = sortedWeights[i];
      final previous = sortedWeights[i - 1];
      final weeksBetween =
          current.weekStartMonday.difference(previous.weekStartMonday).inDays ~/
          7;
      if (weeksBetween < 1) {
        paceMap[current.weekStartIso] = null;
      } else {
        final diff = current.averageWeightKg - previous.averageWeightKg;
        paceMap[current.weekStartIso] = WeekDateUtils.roundToTwoDecimals(
          diff / weeksBetween,
        );
      }
    }
    return paceMap;
  }

  static AssessedWeekContextEntity _buildWeekContext({
    required DateTime weekStartMonday,
    required String currentWeekIso,
    required WeeklyWeightSummaryEntity? weightSummary,
    required double? paceKgPerWeek,
    required WeeklyWorkoutSummaryEntity? workoutSummary,
  }) {
    final weekStartIso = WeekDateUtils.toIsoDateString(weekStartMonday);
    final weekEndSunday = WeekDateUtils.endOfIsoWeekUtc(weekStartMonday);
    final loggedDays = weightSummary?.loggedDaysCount ?? 0;
    final isCurrentWeek = weekStartIso == currentWeekIso;
    final isPartialWeek = loggedDays > 0 && loggedDays < 7;
    final exercises = _aggregateWeeklyExercises(workoutSummary);

    return AssessedWeekContextEntity(
      weekStartIso: weekStartIso,
      weekStartMonday: weekStartMonday,
      weekEndSunday: weekEndSunday,
      averageWeightKg: weightSummary?.averageWeightKg,
      loggedWeightDaysCount: loggedDays,
      isCurrentWeek: isCurrentWeek,
      isPartialWeek: isPartialWeek,
      paceKgPerWeek: paceKgPerWeek,
      workoutCount: workoutSummary?.workoutCount ?? 0,
      totalWorkingSets: workoutSummary?.totalWorkingSets ?? 0,
      totalVolumeKg: workoutSummary != null
          ? WeekDateUtils.roundToTwoDecimals(workoutSummary.totalVolumeKg)
          : 0.0,
      exercises: List.unmodifiable(exercises),
    );
  }

  static List<WeeklyExercisePerformanceEntity> _aggregateWeeklyExercises(
    WeeklyWorkoutSummaryEntity? workoutSummary,
  ) {
    if (workoutSummary == null || workoutSummary.workouts.isEmpty) {
      return const <WeeklyExercisePerformanceEntity>[];
    }

    final sortedWorkouts = workoutSummary.workouts.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final Map<String, _MutableExerciseAccumulator> accumulators = {};

    for (final workout in sortedWorkouts) {
      for (final exercise in workout.exercises) {
        final trimmedTemplateId = exercise.exerciseTemplateId.trim();
        final trimmedTitle = exercise.title.trim();
        final key = trimmedTemplateId.isNotEmpty
            ? 'id:${trimmedTemplateId.toLowerCase()}'
            : 'title:${trimmedTitle.toLowerCase()}';

        final acc = accumulators.putIfAbsent(
          key,
          () => _MutableExerciseAccumulator(
            exerciseTemplateId: trimmedTemplateId,
            title: trimmedTitle,
          ),
        );

        acc.workingSetsCount += exercise.workingSetsCount;
        acc.totalVolumeKg = WeekDateUtils.roundToTwoDecimals(
          acc.totalVolumeKg + exercise.totalVolumeKg,
        );
        acc.considerBestSet(exercise.bestWorkingSet);
      }
    }

    return accumulators.values
        .where((acc) => acc.workingSetsCount > 0)
        .map(
          (acc) => WeeklyExercisePerformanceEntity(
            exerciseTemplateId: acc.exerciseTemplateId,
            title: acc.title,
            workingSetsCount: acc.workingSetsCount,
            totalVolumeKg: acc.totalVolumeKg,
            bestWeightKg: acc.bestSet?.weightKg,
            bestReps: acc.bestSet?.reps,
          ),
        )
        .toList();
  }

  static String _computeFingerprint({
    required String localeCode,
    required GainTargetEntity gainTarget,
    required AssessedWeekContextEntity assessedWeek,
    required List<AssessedWeekContextEntity> priorWeeks,
    required Map<String, WeeklyWorkoutSummaryEntity> windowWorkoutsByIso,
  }) {
    final buffer = StringBuffer()
      ..write('v1|loc:')
      ..write(localeCode)
      ..write('|tgt:')
      ..write(gainTarget.minWeeklyGainKg.toStringAsFixed(2))
      ..write('-')
      ..write(gainTarget.maxWeeklyGainKg.toStringAsFixed(2))
      ..write('|assessed:')
      ..write(_canonicalWeekString(assessedWeek))
      ..write('|prior:');

    for (int i = 0; i < priorWeeks.length; i++) {
      if (i > 0) {
        buffer.write(';');
      }
      buffer.write(_canonicalWeekString(priorWeeks[i]));
    }

    final sortedWorkoutIsos = windowWorkoutsByIso.keys.toList()..sort();
    buffer.write('|win_wo:');
    for (int i = 0; i < sortedWorkoutIsos.length; i++) {
      final iso = sortedWorkoutIsos[i];
      final summary = windowWorkoutsByIso[iso]!;
      if (i > 0) {
        buffer.write(';');
      }
      final exercises = _aggregateWeeklyExercises(summary);
      buffer
        ..write(iso)
        ..write(':')
        ..write(summary.workoutCount)
        ..write(':')
        ..write(summary.totalWorkingSets)
        ..write(':')
        ..write(summary.totalVolumeKg.toStringAsFixed(2))
        ..write('[')
        ..write(_canonicalExercisesString(exercises))
        ..write(']');
    }

    return buffer.toString();
  }

  static String _canonicalWeekString(AssessedWeekContextEntity week) {
    final avg = week.averageWeightKg?.toStringAsFixed(2) ?? 'null';
    final pace = week.paceKgPerWeek?.toStringAsFixed(2) ?? 'null';
    final vol = week.totalVolumeKg.toStringAsFixed(2);
    final exStr = _canonicalExercisesString(week.exercises);
    return '${week.weekStartIso},w:$avg,d:${week.loggedWeightDaysCount},p:${week.isPartialWeek ? 1 : 0},pace:$pace,wc:${week.workoutCount},ws:${week.totalWorkingSets},wv:$vol,ex:[$exStr]';
  }

  static String _canonicalExercisesString(
    List<WeeklyExercisePerformanceEntity> exercises,
  ) {
    if (exercises.isEmpty) {
      return '';
    }
    final sorted = exercises.toList()
      ..sort((a, b) {
        final idCmp = a.exerciseTemplateId.compareTo(b.exerciseTemplateId);
        if (idCmp != 0) {
          return idCmp;
        }
        return a.title.compareTo(b.title);
      });
    return sorted
        .map((e) {
          final bw = e.bestWeightKg?.toStringAsFixed(2) ?? 'null';
          final br = e.bestReps?.toString() ?? 'null';
          final vol = e.totalVolumeKg.toStringAsFixed(2);
          return '${e.exerciseTemplateId}:${e.title.toLowerCase()}:${e.workingSetsCount}:$vol:$bw:$br';
        })
        .join(',');
  }
}

class _MutableExerciseAccumulator {
  final String exerciseTemplateId;
  final String title;
  int workingSetsCount = 0;
  double totalVolumeKg = 0.0;
  WorkoutSetEntity? bestSet;

  _MutableExerciseAccumulator({
    required this.exerciseTemplateId,
    required this.title,
  });

  void considerBestSet(WorkoutSetEntity? candidate) {
    if (candidate == null) {
      return;
    }
    if (candidate.weightKg == null && candidate.reps == null) {
      return;
    }
    if (bestSet == null) {
      bestSet = candidate;
      return;
    }
    final candidateWeight = candidate.weightKg ?? -1.0;
    final currentBestWeight = bestSet!.weightKg ?? -1.0;
    if (candidateWeight > currentBestWeight) {
      bestSet = candidate;
    } else if (candidateWeight == currentBestWeight) {
      final candidateReps = candidate.reps ?? 0;
      final currentBestReps = bestSet!.reps ?? 0;
      if (candidateReps > currentBestReps) {
        bestSet = candidate;
      }
    }
  }
}
