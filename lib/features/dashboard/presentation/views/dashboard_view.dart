import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_view_model.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/dashboard_kpi_row.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/weekly_weight_trend_card.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/weekly_workouts_chart_card.dart';

/// Presentation view for the Home tab, combining the KPI metrics summary row
/// and the two synchronized 12-calendar-week fl_chart progress cards.
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
      if (!mounted) return;
      ref.read(dashboardViewModelProvider.notifier).ensureInitialized();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(authViewModelProvider.select((s) => s.user?.id), (
      previous,
      next,
    ) {
      if (next != null && next != previous) {
        ref.read(dashboardViewModelProvider.notifier).ensureInitialized();
      }
    });

    final dashboardState = ref.watch(dashboardViewModelProvider);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(dashboardViewModelProvider.notifier).refreshAll(),
      child: ListView(
        key: const Key('dashboard_scroll_view'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          DashboardKpiRow(
            overview: dashboardState.overview,
            workoutStatus: dashboardState.workoutStatus,
          ),
          const SizedBox(height: 16),
          WeeklyWeightTrendCard(
            status: dashboardState.weightStatus,
            isOutdated: dashboardState.isWeightOutdated,
            errorMessage: dashboardState.weightErrorMessage,
            slots: dashboardState.overview.calendarWeeks,
            onRetry: () =>
                ref.read(dashboardViewModelProvider.notifier).retryWeights(),
          ),
          const SizedBox(height: 16),
          WeeklyWorkoutsChartCard(
            status: dashboardState.workoutStatus,
            isOutdated: dashboardState.isWorkoutOutdated,
            errorMessage: dashboardState.workoutErrorMessage,
            slots: dashboardState.overview.calendarWeeks,
            onRetry: () =>
                ref.read(dashboardViewModelProvider.notifier).retryWorkouts(),
          ),
        ],
      ),
    );
  }
}
