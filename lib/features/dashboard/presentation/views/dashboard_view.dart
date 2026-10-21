import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/core/design_system.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:bulk_tempo/features/dashboard/presentation/view_models/dashboard_view_model.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/dashboard_kpi_row.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/weekly_pace_chart_card.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/weekly_weight_trend_card.dart';
import 'package:bulk_tempo/features/dashboard/presentation/widgets/weekly_workouts_chart_card.dart';

/// Home tab dashboard view featuring 4 KPI metric stat tiles and 3 fl_chart cards
/// (Weekly Weight Trend, Weekly Pace, and Workouts per Week).
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

    return RefreshIndicator.adaptive(
      onRefresh: () =>
          ref.read(dashboardViewModelProvider.notifier).refreshAll(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalInset =
              constraints.maxWidth >= AppSpacing.compactBreakpoint
              ? AppSpacing.pageInsetWide
              : AppSpacing.pageInsetCompact;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.dashboardMaxWidth,
              ),
              child: ListView(
                key: const Key('dashboard_scroll_view'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalInset,
                  vertical: AppSpacing.space4,
                ),
                children: [
                  DashboardKpiRow(state: state),
                  const SizedBox(height: AppSpacing.relatedGap),
                  WeeklyWeightTrendCard(
                    state: state,
                    onRetry: () => ref
                        .read(dashboardViewModelProvider.notifier)
                        .retryWeights(),
                  ),
                  const SizedBox(height: AppSpacing.relatedGap),
                  WeeklyPaceChartCard(
                    state: state,
                    onRetry: () => ref
                        .read(dashboardViewModelProvider.notifier)
                        .retryPace(),
                  ),
                  const SizedBox(height: AppSpacing.relatedGap),
                  WeeklyWorkoutsChartCard(
                    state: state,
                    onRetry: () => ref
                        .read(dashboardViewModelProvider.notifier)
                        .retryWorkouts(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
