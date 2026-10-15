import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/weekly_progress_overview_entity.dart';
import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';

part 'dashboard_state.freezed.dart';

/// Presentation status for an individual card on the Home dashboard.
enum DashboardCardStatus { loading, error, unconfigured, empty, loaded }

/// Immutable presentation state composed reactively for the Home dashboard.
@freezed
abstract class DashboardState with _$DashboardState {
  const DashboardState._();

  const factory DashboardState({
    required DashboardCardStatus weightStatus,
    required DashboardCardStatus workoutStatus,
    @Default(DashboardCardStatus.loaded) DashboardCardStatus gainTargetStatus,
    @Default(false) bool isWeightOutdated,
    @Default(false) bool isWorkoutOutdated,
    @Default(false) bool isGainTargetOutdated,
    String? weightErrorMessage,
    String? workoutErrorMessage,
    String? gainTargetErrorMessage,
    GainTargetEntity? gainTarget,
    required WeeklyProgressOverviewEntity overview,
    @Default(false) bool hasAnyWorkoutInWindow,
  }) = _DashboardState;
}
