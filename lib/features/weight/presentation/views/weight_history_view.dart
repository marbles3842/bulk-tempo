import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_history_state.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_history_view_model.dart';
import 'package:bulk_tempo/features/weight/presentation/widgets/weekly_weight_card.dart';
import 'package:bulk_tempo/features/weight/presentation/widgets/weekly_weight_chart.dart';
import 'package:bulk_tempo/features/weight/presentation/widgets/weight_entry_bottom_sheet.dart';

/// Presentation view for the Weights tab, combining the weekly average trend chart
/// and the scrollable list of expandable weekly weight summaries.
class WeightHistoryView extends ConsumerStatefulWidget {
  const WeightHistoryView({super.key});

  @override
  ConsumerState<WeightHistoryView> createState() => _WeightHistoryViewState();
}

class _WeightHistoryViewState extends ConsumerState<WeightHistoryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(weightHistoryViewModelProvider);
      if (state is WeightHistoryInitial) {
        ref.read(weightHistoryViewModelProvider.notifier).loadEntries();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<WeightHistoryState>(weightHistoryViewModelProvider, (
      previous,
      next,
    ) {
      if (next is WeightHistoryLoaded && next.refreshErrorMessage != null) {
        final prevError = previous is WeightHistoryLoaded
            ? previous.refreshErrorMessage
            : null;
        if (next.refreshErrorMessage != prevError) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              key: const Key('weight_history_refresh_error_snackbar'),
              content: Text(next.refreshErrorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
              action: SnackBarAction(
                key: const Key('weight_history_refresh_retry_action'),
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  ref
                      .read(weightHistoryViewModelProvider.notifier)
                      .loadEntries(showLoading: false);
                },
              ),
            ),
          );
          ref.read(weightHistoryViewModelProvider.notifier).clearRefreshError();
        }
      }
    });

    final historyState = ref.watch(weightHistoryViewModelProvider);

    Widget content;
    switch (historyState) {
      case WeightHistoryInitial() || WeightHistoryLoading():
        content = const Center(
          child: CircularProgressIndicator(
            key: Key('weight_history_loading_indicator'),
          ),
        );
      case WeightHistoryError(:final message):
        content = Center(
          key: const Key('weight_history_error_state'),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('weight_history_retry_button'),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  onPressed: () {
                    ref
                        .read(weightHistoryViewModelProvider.notifier)
                        .loadEntries();
                  },
                ),
              ],
            ),
          ),
        );
      case WeightHistoryLoaded(:final weeklySummaries, :final chartSummaries):
        if (weeklySummaries.isEmpty) {
          content = RefreshIndicator(
            onRefresh: () => ref
                .read(weightHistoryViewModelProvider.notifier)
                .loadEntries(showLoading: false),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    key: const Key('weight_history_empty_state'),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.monitor_weight_outlined,
                            size: 72,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No weight entries yet',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Track your weight progression consistently to see trends over time.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            key: const Key('empty_state_add_weight_button'),
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Weight'),
                            onPressed: () =>
                                WeightEntryBottomSheet.show(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          content = RefreshIndicator(
            onRefresh: () => ref
                .read(weightHistoryViewModelProvider.notifier)
                .loadEntries(showLoading: false),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: weeklySummaries.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return WeeklyWeightChart(chartSummaries: chartSummaries);
                }
                final summaryIndex = index - 1;
                final summary = weeklySummaries[summaryIndex];
                return WeeklyWeightCard(
                  key: PageStorageKey<String>(
                    'week_card_outer_${summary.weekStartIso}',
                  ),
                  summary: summary,
                  initiallyExpanded: summaryIndex == 0,
                  onEntryTap: (entry) {
                    WeightEntryBottomSheet.show(context, existingEntry: entry);
                  },
                );
              },
            ),
          );
        }
    }

    return Scaffold(
      body: SafeArea(child: content),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_weight_fab'),
        tooltip: 'Add Weight',
        icon: const Icon(Icons.add),
        label: const Text('Add Weight'),
        onPressed: () => WeightEntryBottomSheet.show(context),
      ),
    );
  }
}
