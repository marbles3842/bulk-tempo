import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/pace_assessment_entity.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_state.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_view_model.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/pace_assessment_view_model.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/dashboard_kpi_row.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/pace_assessment_card.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/pace_assessment_report_bottom_sheet.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/weekly_pace_chart_card.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/weekly_weight_trend_card.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/weekly_workouts_chart_card.dart';

/// Home tab dashboard view featuring the AI Pace Assessment card, 4 KPI metric
/// stat tiles, and 3 fl_chart cards (Weekly Weight Trend, Weekly Pace, and
/// Workouts per Week).
class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key = const Key('dashboard_view')});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(dashboardViewModelProvider.notifier).ensureInitialized();
      }
    });
  }

  int _resolveAssessedWeekLoggedDays(
    DashboardState state,
    PaceAssessmentEntity assessment,
  ) {
    for (final slot in state.overview.calendarWeeks) {
      if (slot.weekStartIso == assessment.assessedWeekStartIso &&
          slot.loggedWeightDaysCount > 0) {
        return slot.loggedWeightDaysCount;
      }
    }
    return state.overview.latestWeekLoggedDays > 0
        ? state.overview.latestWeekLoggedDays
        : 1;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authViewModelProvider.select((s) => s.user?.id), (
      previous,
      next,
    ) {
      if (next != null && next != previous) {
        ref.read(dashboardViewModelProvider.notifier).ensureInitialized();
      }
    });

    final state = ref.watch(dashboardViewModelProvider);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(dashboardViewModelProvider.notifier).refreshAll(),
      child: ListView(
        key: const Key('dashboard_scroll_view'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          PaceAssessmentCard(
            state: state,
            onRetry: () => ref
                .read(dashboardViewModelProvider.notifier)
                .retryPaceAssessment(),
            onRefresh: () => ref
                .read(paceAssessmentViewModelProvider.notifier)
                .refresh(forceRefresh: true),
            onOpenReport: () {
              final assessment = state.paceAssessment.assessment;
              if (assessment != null) {
                PaceAssessmentReportBottomSheet.show(
                  context,
                  assessment,
                  assessedWeekLoggedDays: _resolveAssessedWeekLoggedDays(
                    state,
                    assessment,
                  ),
                );
              }
            },
          ),
          DashboardKpiRow(state: state),
          WeeklyWeightTrendCard(
            state: state,
            onRetry: () =>
                ref.read(dashboardViewModelProvider.notifier).retryWeights(),
          ),
          WeeklyPaceChartCard(
            state: state,
            onRetry: () =>
                ref.read(dashboardViewModelProvider.notifier).retryPace(),
          ),
          WeeklyWorkoutsChartCard(
            state: state,
            onRetry: () =>
                ref.read(dashboardViewModelProvider.notifier).retryWorkouts(),
          ),
        ],
      ),
    );
  }
}
