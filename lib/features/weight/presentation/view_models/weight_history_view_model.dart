import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bulk_tempo/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:bulk_tempo/features/weight/data/repositories/weight_repository_impl.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';
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

  bool _disposed = false;
  int _requestCounter = 0;
  int _minEligibleRequestId = 0;
  int _lastAcceptedRequestId = 0;

  @override
  WeightHistoryState build() {
    ref.keepAlive();
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
    });

    ref.watch(authViewModelProvider.select((s) => s.user?.id));
    ref.watch(weightRepositoryProvider);

    _requestCounter = 0;
    _minEligibleRequestId = 0;
    _lastAcceptedRequestId = 0;

    return const WeightHistoryInitial();
  }

  /// Triggers [loadEntries] only when the ViewModel is still in
  /// [WeightHistoryInitial], preserving session-cached state across tab switches.
  Future<void> ensureInitialized() async {
    if (state is WeightHistoryInitial) {
      await loadEntries();
    }
  }

  /// Derives sorted entries, weekly summaries, and chronological chart slice
  /// from an arbitrary list of entries.
  WeightHistoryLoaded _deriveLoadedState(
    List<WeightEntryEntity> entries, {
    String? refreshErrorMessage,
  }) {
    final sortedEntries = List<WeightEntryEntity>.unmodifiable(
      List<WeightEntryEntity>.from(entries)
        ..sort((a, b) => b.dateIso.compareTo(a.dateIso)),
    );

    final weeklySummaries = WeeklyWeightSummaryEntity.groupEntriesByIsoWeek(
      sortedEntries,
    );

    final chartSummaries = List<WeeklyWeightSummaryEntity>.unmodifiable(
      weeklySummaries.take(maxChartWeeks).toList().reversed.toList(),
    );

    return WeightHistoryLoaded(
      entries: sortedEntries,
      weeklySummaries: List.unmodifiable(weeklySummaries),
      chartSummaries: chartSummaries,
      refreshErrorMessage: refreshErrorMessage,
    );
  }

  /// Applies a confirmed saved entry immediately to local state, scoping it
  /// to the matching [userId]. Invalidates reads started prior to this call.
  void applySavedEntry({
    required String userId,
    required WeightEntryEntity entry,
  }) {
    if (_disposed) return;
    final currentUserId = ref.read(authViewModelProvider).user?.id;
    if (currentUserId == null || currentUserId != userId) {
      return;
    }

    // Invalidate any read started before this acknowledged mutation
    _minEligibleRequestId = _requestCounter + 1;

    final currentEntries = state is WeightHistoryLoaded
        ? (state as WeightHistoryLoaded).entries
        : const <WeightEntryEntity>[];

    final updated = List<WeightEntryEntity>.from(currentEntries);
    final index = updated.indexWhere((e) => e.dateIso == entry.dateIso);
    if (index >= 0) {
      updated[index] = entry;
    } else {
      updated.add(entry);
    }

    final refreshError = state is WeightHistoryLoaded
        ? (state as WeightHistoryLoaded).refreshErrorMessage
        : null;

    state = _deriveLoadedState(updated, refreshErrorMessage: refreshError);
  }

  /// Alias for [applySavedEntry].
  void applySavedEntity({
    required String userId,
    required WeightEntryEntity entry,
  }) => applySavedEntry(userId: userId, entry: entry);

  /// Applies a confirmed deletion immediately to local state, scoping it
  /// to the matching [userId]. Invalidates reads started prior to this call.
  void applyDeletedEntry({required String userId, required String dateIso}) {
    if (_disposed) return;
    final currentUserId = ref.read(authViewModelProvider).user?.id;
    if (currentUserId == null || currentUserId != userId) {
      return;
    }

    // Invalidate any read started before this acknowledged mutation
    _minEligibleRequestId = _requestCounter + 1;

    final currentEntries = state is WeightHistoryLoaded
        ? (state as WeightHistoryLoaded).entries
        : const <WeightEntryEntity>[];

    final updated = currentEntries.where((e) => e.dateIso != dateIso).toList();

    final refreshError = state is WeightHistoryLoaded
        ? (state as WeightHistoryLoaded).refreshErrorMessage
        : null;

    state = _deriveLoadedState(updated, refreshErrorMessage: refreshError);
  }

  /// Alias for [applyDeletedEntry].
  void applyDeletedDate({required String userId, required String dateIso}) =>
      applyDeletedEntry(userId: userId, dateIso: dateIso);

  /// Fetches logged entries for the currently authenticated user.
  ///
  /// When [showLoading] is true, emits [WeightHistoryLoading] immediately.
  /// If [showLoading] is false (e.g. background refresh) and data is already loaded,
  /// repository failures are captured in [WeightHistoryLoaded.refreshErrorMessage]
  /// without discarding existing data.
  Future<void> loadEntries({bool showLoading = true}) async {
    final authState = ref.read(authViewModelProvider);
    final user = authState.user;

    if (user == null || user.id.trim().isEmpty) {
      if (!_disposed) {
        state = const WeightHistoryError('User is not authenticated');
      }
      return;
    }

    final requestUserId = user.id;
    final requestId = ++_requestCounter;

    if (showLoading || state is! WeightHistoryLoaded) {
      state = const WeightHistoryLoading();
    }

    final repository = ref.read(weightRepositoryProvider);
    final result = await repository.getWeightEntries(userId: requestUserId);

    if (_disposed) return;

    // Check account continuity
    final currentUserId = ref.read(authViewModelProvider).user?.id;
    if (currentUserId != requestUserId) {
      return;
    }

    // Discard result if a mutation was applied after this request started
    if (requestId < _minEligibleRequestId) {
      return;
    }

    // Discard result if an out-of-order newer request has already completed
    if (requestId < _lastAcceptedRequestId) {
      return;
    }

    _lastAcceptedRequestId = requestId;

    result.when(
      success: (entries) {
        if (_disposed) return;
        state = _deriveLoadedState(entries);
      },
      failure: (failure) {
        if (_disposed) return;
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
