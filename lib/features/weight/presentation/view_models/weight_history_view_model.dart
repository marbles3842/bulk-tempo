import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:bulk_tempo/features/weight/data/repositories/weight_repository_impl.dart';
import 'package:bulk_tempo/features/weight/domain/models/weekly_weight_summary_entity.dart';
import 'package:bulk_tempo/features/weight/presentation/view_models/weight_history_state.dart';

final weightHistoryViewModelProvider =
    AutoDisposeNotifierProvider<WeightHistoryViewModel, WeightHistoryState>(
      WeightHistoryViewModel.new,
    );

/// Pure-Dart ViewModel managing the user's weight history, weekly groupings,
/// and 12-week chronological trend slice.
class WeightHistoryViewModel extends AutoDisposeNotifier<WeightHistoryState> {
  static const int maxChartWeeks = 12;

  @override
  WeightHistoryState build() {
    ref.watch(authViewModelProvider.select((s) => s.user?.id));
    ref.watch(weightRepositoryProvider);
    return const WeightHistoryInitial();
  }

  /// Fetches logged entries for the currently authenticated user.
  ///
  /// When [showLoading] is true, emits [WeightHistoryLoading] immediately.
  /// If [showLoading] is false (e.g. during pull-to-refresh) and data is already loaded,
  /// repository failures are captured in [WeightHistoryLoaded.refreshErrorMessage]
  /// without discarding existing data.
  Future<void> loadEntries({bool showLoading = true}) async {
    final authState = ref.read(authViewModelProvider);
    final user = authState.user;

    if (user == null || user.id.trim().isEmpty) {
      state = const WeightHistoryError('User is not authenticated');
      return;
    }

    if (showLoading || state is! WeightHistoryLoaded) {
      state = const WeightHistoryLoading();
    }

    final repository = ref.read(weightRepositoryProvider);
    final result = await repository.getWeightEntries(userId: user.id);

    result.when(
      success: (entries) {
        final weeklySummaries = WeeklyWeightSummaryEntity.groupEntriesByIsoWeek(
          entries,
        );
        // Take the 12 most recent logged weeks (weeklySummaries is newest-first)
        // and reverse them so chartSummaries is chronologically oldest-to-newest (left-to-right).
        final chartSummaries = weeklySummaries
            .take(maxChartWeeks)
            .toList()
            .reversed
            .toList();

        state = WeightHistoryLoaded(
          entries: entries,
          weeklySummaries: weeklySummaries,
          chartSummaries: chartSummaries,
        );
      },
      failure: (failure) {
        if (!showLoading && state is WeightHistoryLoaded) {
          final current = state as WeightHistoryLoaded;
          state = current.copyWith(refreshErrorMessage: failure.message);
        } else {
          state = WeightHistoryError(failure.message);
        }
      },
    );
  }

  /// Clears transient pull-to-refresh error without altering existing data.
  void clearRefreshError() {
    if (state is WeightHistoryLoaded) {
      final current = state as WeightHistoryLoaded;
      state = current.copyWith(clearRefreshError: true);
    }
  }
}
