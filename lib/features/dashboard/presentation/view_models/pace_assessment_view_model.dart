import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/errors/failures.dart';
import 'package:bulk_tempo/core/localization/locale_provider.dart';
import 'package:bulk_tempo/core/providers/clock_provider.dart';
import 'package:bulk_tempo/core/result/result.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:bulk_tempo/features/dashboard/data/repositories/pace_assessment_repository_impl.dart';
import 'package:bulk_tempo/features/dashboard/domain/calculators/pace_assessment_calculator.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/pace_assessment_entity.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/pace_assessment_state.dart';
import 'package:bulk_tempo/features/gain_target/presentation/view_models/gain_target_state.dart';
import 'package:bulk_tempo/features/gain_target/presentation/view_models/gain_target_view_model.dart';
import 'package:bulk_tempo/features/weight/domain/models/weekly_weight_summary_entity.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_history_state.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_history_view_model.dart';
import 'package:bulk_tempo/features/workout/domain/models/weekly_workout_summary_entity.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/workout_progress_state.dart';
import 'package:bulk_tempo/features/workout/presentation/view_models/workout_progress_view_model.dart';

final paceAssessmentViewModelProvider =
    AutoDisposeNotifierProvider<PaceAssessmentViewModel, PaceAssessmentState>(
      PaceAssessmentViewModel.new,
    );

/// Pure-Dart ViewModel managing eligibility evaluation, fingerprint-deduplicated
/// automatic AI pace assessment, pull-to-refresh, manual retry, and user isolation.
class PaceAssessmentViewModel extends AutoDisposeNotifier<PaceAssessmentState> {
  late DateTime Function() _clock;
  String? _userId;
  WeightHistoryState _weightState = const WeightHistoryInitial();
  WorkoutProgressState _workoutState = const WorkoutProgressInitial();
  GainTargetState _gainTargetState = const GainTargetState();
  String _localeCode = 'en';
  int _generation = 0;
  bool _disposed = false;
  String? _inFlightFingerprint;
  Future<void>? _inFlightEvaluation;
  PaceAssessmentState _currentState = const PaceAssessmentState();

  @override
  PaceAssessmentState build() {
    ref.keepAlive();
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _inFlightFingerprint = null;
      _inFlightEvaluation = null;
    });

    _clock = ref.watch(clockProvider);

    final newUserId = ref.watch(
      authViewModelProvider.select((s) => s.user?.id),
    );

    _weightState = ref.read(weightHistoryViewModelProvider);
    _workoutState = ref.read(workoutProgressViewModelProvider);
    _gainTargetState = ref.read(gainTargetViewModelProvider);
    _localeCode = ref.read(localeProvider).languageCode;

    ref.listen<WeightHistoryState>(weightHistoryViewModelProvider, (_, next) {
      _weightState = next;
      _onUpstreamChanged();
    });
    ref.listen<WorkoutProgressState>(workoutProgressViewModelProvider, (
      _,
      next,
    ) {
      _workoutState = next;
      _onUpstreamChanged();
    });
    ref.listen<GainTargetState>(gainTargetViewModelProvider, (_, next) {
      _gainTargetState = next;
      _onUpstreamChanged();
    });
    ref.listen<String>(localeProvider.select((locale) => locale.languageCode), (
      _,
      next,
    ) {
      _localeCode = next;
      _onUpstreamChanged();
    });

    if (_userId != newUserId) {
      _userId = newUserId;
      _generation++;
      _inFlightFingerprint = null;
      _inFlightEvaluation = null;
      _currentState = const PaceAssessmentState();
    }

    if (newUserId == null || newUserId.trim().isEmpty) {
      _inFlightFingerprint = null;
      _inFlightEvaluation = null;
      return _recordState(
        const PaceAssessmentState(
          status: PaceAssessmentViewStatus.ineligible,
          ineligibilityReason:
              PaceAssessmentIneligibilityReason.unauthenticated,
        ),
      );
    }

    return _deriveState(
      userId: newUserId,
      weightState: _weightState,
      workoutState: _workoutState,
      gainTargetState: _gainTargetState,
      localeCode: _localeCode,
      now: _clock(),
      scheduleEvaluationIfNeeded: true,
    );
  }

  void _onUpstreamChanged() {
    if (_disposed) return;
    final userId = _userId;
    if (userId == null || userId.trim().isEmpty) {
      _inFlightFingerprint = null;
      _inFlightEvaluation = null;
      state = _recordState(
        const PaceAssessmentState(
          status: PaceAssessmentViewStatus.ineligible,
          ineligibilityReason:
              PaceAssessmentIneligibilityReason.unauthenticated,
        ),
      );
      return;
    }

    state = _deriveState(
      userId: userId,
      weightState: _weightState,
      workoutState: _workoutState,
      gainTargetState: _gainTargetState,
      localeCode: _localeCode,
      now: _clock(),
      scheduleEvaluationIfNeeded: true,
    );
  }

  /// Refreshes the contextual pace assessment.
  ///
  /// When [forceRefresh] is `true`, bypasses the RTDB fingerprint cache read
  /// to generate a fresh AI assessment. If a previous assessment is already
  /// displayed and the refresh fails, preserves `status: loaded`, sets
  /// `isOutdated: true`, and populates `refreshErrorMessage`.
  Future<void> refresh({bool forceRefresh = false}) async {
    if (_disposed) return;

    final userId = _userId;
    if (userId == null || userId.trim().isEmpty) {
      _generation++;
      _inFlightFingerprint = null;
      _inFlightEvaluation = null;
      state = _recordState(
        const PaceAssessmentState(
          status: PaceAssessmentViewStatus.ineligible,
          ineligibilityReason:
              PaceAssessmentIneligibilityReason.unauthenticated,
        ),
      );
      return;
    }

    final weightState = _weightState;
    final workoutState = _workoutState;
    final gainTargetState = _gainTargetState;
    final localeCode = _localeCode;
    final now = _clock();

    final upstreamGateState = _checkUpstreamLoadingOrError(
      weightState: weightState,
      workoutState: workoutState,
      gainTargetState: gainTargetState,
    );
    if (upstreamGateState != null) {
      state = _recordState(upstreamGateState);
      return;
    }

    final eligibility = _computeEligibility(
      weightState: weightState,
      workoutState: workoutState,
      gainTargetState: gainTargetState,
      localeCode: localeCode,
      now: now,
    );

    switch (eligibility) {
      case PaceAssessmentIneligible(
        :final reason,
        :final recordedWeightWeeksCount,
        :final priorWeightWeeksCount,
      ):
        _generation++;
        _inFlightFingerprint = null;
        _inFlightEvaluation = null;
        state = _recordState(
          PaceAssessmentState(
            status: PaceAssessmentViewStatus.ineligible,
            ineligibilityReason: reason,
            recordedWeightWeeksCount: recordedWeightWeeksCount,
            priorWeightWeeksCount: priorWeightWeeksCount,
          ),
        );
        return;

      case PaceAssessmentEligible(:final input):
        if (!forceRefresh && _inFlightFingerprint == input.fingerprint) {
          await _inFlightEvaluation;
          return;
        }
        final priorCount = _countPriorWeightWeeks(input);
        final recordedCount = priorCount + 1;
        _inFlightFingerprint = input.fingerprint;
        final generation = ++_generation;

        if (_currentState.assessment != null) {
          state = _recordState(
            _currentState.copyWith(
              status: PaceAssessmentViewStatus.loaded,
              ineligibilityReason: null,
              recordedWeightWeeksCount: recordedCount,
              priorWeightWeeksCount: priorCount,
              isRefreshing: true,
              errorMessage: null,
              refreshErrorMessage: null,
            ),
          );
        } else {
          state = _recordState(
            PaceAssessmentState(
              status: PaceAssessmentViewStatus.loading,
              recordedWeightWeeksCount: recordedCount,
              priorWeightWeeksCount: priorCount,
            ),
          );
        }

        final evalFuture = _evaluate(
          input: input,
          userId: userId,
          generation: generation,
          forceRefresh: forceRefresh,
          recordedWeightWeeksCount: recordedCount,
          priorWeightWeeksCount: priorCount,
        );
        _inFlightEvaluation = evalFuture;
        await evalFuture;
    }
  }

  /// Retries pace assessment evaluation after an error or outdated refresh failure.
  Future<void> retry() => refresh(forceRefresh: false);

  PaceAssessmentState _deriveState({
    required String userId,
    required WeightHistoryState weightState,
    required WorkoutProgressState workoutState,
    required GainTargetState gainTargetState,
    required String localeCode,
    required DateTime now,
    required bool scheduleEvaluationIfNeeded,
  }) {
    final upstreamGateState = _checkUpstreamLoadingOrError(
      weightState: weightState,
      workoutState: workoutState,
      gainTargetState: gainTargetState,
    );
    if (upstreamGateState != null) {
      return _recordState(upstreamGateState);
    }

    final eligibility = _computeEligibility(
      weightState: weightState,
      workoutState: workoutState,
      gainTargetState: gainTargetState,
      localeCode: localeCode,
      now: now,
    );

    switch (eligibility) {
      case PaceAssessmentIneligible(
        :final reason,
        :final recordedWeightWeeksCount,
        :final priorWeightWeeksCount,
      ):
        _generation++;
        _inFlightFingerprint = null;
        _inFlightEvaluation = null;
        return _recordState(
          PaceAssessmentState(
            status: PaceAssessmentViewStatus.ineligible,
            ineligibilityReason: reason,
            recordedWeightWeeksCount: recordedWeightWeeksCount,
            priorWeightWeeksCount: priorWeightWeeksCount,
          ),
        );

      case PaceAssessmentEligible(:final input):
        final priorCount = _countPriorWeightWeeks(input);
        final recordedCount = priorCount + 1;

        if (_currentState.assessment != null &&
            _currentState.assessment!.fingerprint == input.fingerprint &&
            _inFlightFingerprint != input.fingerprint) {
          final isSameEvaluated =
              _currentState.lastEvaluatedFingerprint == input.fingerprint;
          return _recordState(
            _currentState.copyWith(
              status: PaceAssessmentViewStatus.loaded,
              ineligibilityReason: null,
              recordedWeightWeeksCount: recordedCount,
              priorWeightWeeksCount: priorCount,
              isRefreshing: _inFlightFingerprint != null,
              isOutdated: isSameEvaluated ? _currentState.isOutdated : false,
              errorMessage: null,
              refreshErrorMessage: isSameEvaluated
                  ? _currentState.refreshErrorMessage
                  : null,
              lastEvaluatedFingerprint: input.fingerprint,
            ),
          );
        }

        if (_currentState.lastEvaluatedFingerprint == input.fingerprint &&
            _inFlightFingerprint != input.fingerprint) {
          return _recordState(
            _currentState.copyWith(
              ineligibilityReason: null,
              recordedWeightWeeksCount: recordedCount,
              priorWeightWeeksCount: priorCount,
              isRefreshing: _inFlightFingerprint != null,
            ),
          );
        }

        if (scheduleEvaluationIfNeeded &&
            _inFlightFingerprint != input.fingerprint) {
          _inFlightFingerprint = input.fingerprint;
          final generation = ++_generation;
          _inFlightEvaluation = Future.microtask(
            () => _evaluate(
              input: input,
              userId: userId,
              generation: generation,
              forceRefresh: false,
              recordedWeightWeeksCount: recordedCount,
              priorWeightWeeksCount: priorCount,
            ),
          );
        }

        if (_currentState.assessment != null) {
          return _recordState(
            _currentState.copyWith(
              status: PaceAssessmentViewStatus.loaded,
              ineligibilityReason: null,
              recordedWeightWeeksCount: recordedCount,
              priorWeightWeeksCount: priorCount,
              isRefreshing: true,
              errorMessage: null,
              refreshErrorMessage: null,
            ),
          );
        }

        return _recordState(
          PaceAssessmentState(
            status: PaceAssessmentViewStatus.loading,
            recordedWeightWeeksCount: recordedCount,
            priorWeightWeeksCount: priorCount,
          ),
        );
    }
  }

  PaceAssessmentState? _checkUpstreamLoadingOrError({
    required WeightHistoryState weightState,
    required WorkoutProgressState workoutState,
    required GainTargetState gainTargetState,
  }) {
    final isActivelyLoading =
        weightState is WeightHistoryLoading ||
        workoutState is WorkoutProgressLoading ||
        (gainTargetState.isLoading && !gainTargetState.hasLoadedOnce);

    if (isActivelyLoading) {
      if (_currentState.assessment != null) {
        return _currentState.copyWith(
          status: PaceAssessmentViewStatus.loaded,
          isRefreshing: true,
          errorMessage: null,
        );
      }
      _inFlightFingerprint = null;
      _inFlightEvaluation = null;
      return const PaceAssessmentState(
        status: PaceAssessmentViewStatus.loading,
      );
    }

    final String? upstreamError = switch ((weightState, workoutState)) {
      (WeightHistoryError(:final message), _) => message,
      (_, WorkoutProgressError(:final message)) => message,
      _
          when gainTargetState.errorMessage != null &&
              !gainTargetState.hasLoadedOnce =>
        gainTargetState.errorMessage,
      _ => null,
    };

    if (upstreamError != null) {
      _generation++;
      _inFlightFingerprint = null;
      _inFlightEvaluation = null;
      if (_currentState.assessment != null) {
        return _currentState.copyWith(
          status: PaceAssessmentViewStatus.loaded,
          isRefreshing: false,
          isOutdated: true,
          errorMessage: null,
          refreshErrorMessage: upstreamError,
        );
      }
      return PaceAssessmentState(
        status: PaceAssessmentViewStatus.error,
        errorMessage: upstreamError,
      );
    }

    final isInitial =
        weightState is WeightHistoryInitial ||
        workoutState is WorkoutProgressInitial;

    if (isInitial) {
      if (_currentState.assessment != null) {
        return _currentState.copyWith(status: PaceAssessmentViewStatus.loaded);
      }
      _inFlightFingerprint = null;
      _inFlightEvaluation = null;
      return const PaceAssessmentState(
        status: PaceAssessmentViewStatus.loading,
      );
    }

    return null;
  }

  PaceAssessmentEligibilityResult _computeEligibility({
    required WeightHistoryState weightState,
    required WorkoutProgressState workoutState,
    required GainTargetState gainTargetState,
    required String localeCode,
    required DateTime now,
  }) {
    final weightSummaries = weightState is WeightHistoryLoaded
        ? weightState.weeklySummaries
        : const <WeeklyWeightSummaryEntity>[];
    final workoutSummaries = workoutState is WorkoutProgressLoaded
        ? workoutState.weeklySummaries
        : const <WeeklyWorkoutSummaryEntity>[];
    final isWorkoutConfigured = workoutState is WorkoutProgressLoaded;

    return PaceAssessmentCalculator.evaluateEligibility(
      weightSummaries: weightSummaries,
      workoutSummaries: workoutSummaries,
      isWorkoutConfigured: isWorkoutConfigured,
      gainTarget: gainTargetState.savedTarget,
      localeCode: localeCode,
      now: now,
    );
  }

  Future<void> _evaluate({
    required PaceAssessmentInputEntity input,
    required String userId,
    required int generation,
    required bool forceRefresh,
    required int recordedWeightWeeksCount,
    required int priorWeightWeeksCount,
  }) async {
    if (_disposed || _userId != userId || generation != _generation) {
      return;
    }

    Result<PaceAssessmentEntity, AppFailure> result;
    try {
      final repository = ref.read(paceAssessmentRepositoryProvider);
      result = await repository.getOrGenerateAssessment(
        userId: userId,
        input: input,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      result = Result.failure(ServerFailure(e.toString()));
    }

    if (_disposed || _userId != userId || generation != _generation) {
      return;
    }

    _inFlightFingerprint = null;
    _inFlightEvaluation = null;

    result.when(
      success: (assessment) {
        state = _recordState(
          PaceAssessmentState(
            status: PaceAssessmentViewStatus.loaded,
            assessment: assessment,
            recordedWeightWeeksCount: recordedWeightWeeksCount,
            priorWeightWeeksCount: priorWeightWeeksCount,
            isRefreshing: false,
            isOutdated: false,
            errorMessage: null,
            refreshErrorMessage: null,
            lastEvaluatedFingerprint: input.fingerprint,
          ),
        );
      },
      failure: (failure) {
        if (_currentState.assessment != null) {
          state = _recordState(
            _currentState.copyWith(
              status: PaceAssessmentViewStatus.loaded,
              ineligibilityReason: null,
              recordedWeightWeeksCount: recordedWeightWeeksCount,
              priorWeightWeeksCount: priorWeightWeeksCount,
              isRefreshing: false,
              isOutdated: true,
              errorMessage: null,
              refreshErrorMessage: failure.message,
              lastEvaluatedFingerprint: input.fingerprint,
            ),
          );
        } else {
          state = _recordState(
            PaceAssessmentState(
              status: PaceAssessmentViewStatus.error,
              recordedWeightWeeksCount: recordedWeightWeeksCount,
              priorWeightWeeksCount: priorWeightWeeksCount,
              isRefreshing: false,
              isOutdated: false,
              errorMessage: failure.message,
              refreshErrorMessage: null,
              lastEvaluatedFingerprint: input.fingerprint,
            ),
          );
        }
      },
    );
  }

  static int _countPriorWeightWeeks(PaceAssessmentInputEntity input) {
    return input.priorWeeks
        .where((w) => w.loggedWeightDaysCount > 0 && w.averageWeightKg != null)
        .length;
  }

  PaceAssessmentState _recordState(PaceAssessmentState next) {
    _currentState = next;
    return next;
  }
}
