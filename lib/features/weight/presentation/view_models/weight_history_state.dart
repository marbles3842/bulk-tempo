import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';
import 'package:bulk_tempo/features/weight/domain/models/weekly_weight_summary_entity.dart';

/// Pure Dart state representations for the Weight History screen.
sealed class WeightHistoryState {
  const WeightHistoryState();
}

/// Initial uninitialized state before entries have been fetched.
final class WeightHistoryInitial extends WeightHistoryState {
  const WeightHistoryInitial();
}

/// Loading state displayed during initial fetch or explicit reload.
final class WeightHistoryLoading extends WeightHistoryState {
  const WeightHistoryLoading();
}

/// Successfully loaded state containing raw entries, full weekly summaries,
/// and the chronological 12-week slice for trend plotting.
final class WeightHistoryLoaded extends WeightHistoryState {
  /// All raw weight entries sorted newest date first.
  final List<WeightEntryEntity> entries;

  /// All logged weekly summaries sorted newest week first.
  final List<WeeklyWeightSummaryEntity> weeklySummaries;

  /// Up to 12 most recent logged weeks sorted oldest week first (chronological left-to-right).
  final List<WeeklyWeightSummaryEntity> chartSummaries;

  /// Non-destructive transient error message populated when a background refresh fails.
  final String? refreshErrorMessage;

  const WeightHistoryLoaded({
    required this.entries,
    required this.weeklySummaries,
    required this.chartSummaries,
    this.refreshErrorMessage,
  });

  /// Checks whether a weight entry has already been recorded for [dateIso] (`YYYY-MM-DD`).
  bool hasEntryForDate(String dateIso) {
    return entries.any((entry) => entry.dateIso == dateIso);
  }

  /// Whether the loaded entry list is empty.
  bool get isEmpty => entries.isEmpty;

  WeightHistoryLoaded copyWith({
    List<WeightEntryEntity>? entries,
    List<WeeklyWeightSummaryEntity>? weeklySummaries,
    List<WeeklyWeightSummaryEntity>? chartSummaries,
    String? refreshErrorMessage,
    bool clearRefreshError = false,
  }) {
    return WeightHistoryLoaded(
      entries: entries ?? this.entries,
      weeklySummaries: weeklySummaries ?? this.weeklySummaries,
      chartSummaries: chartSummaries ?? this.chartSummaries,
      refreshErrorMessage: clearRefreshError
          ? null
          : (refreshErrorMessage ?? this.refreshErrorMessage),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WeightHistoryLoaded || runtimeType != other.runtimeType) {
      return false;
    }
    if (refreshErrorMessage != other.refreshErrorMessage ||
        entries.length != other.entries.length ||
        weeklySummaries.length != other.weeklySummaries.length ||
        chartSummaries.length != other.chartSummaries.length) {
      return false;
    }
    for (int i = 0; i < entries.length; i++) {
      if (entries[i] != other.entries[i]) return false;
    }
    for (int i = 0; i < weeklySummaries.length; i++) {
      if (weeklySummaries[i] != other.weeklySummaries[i]) return false;
    }
    for (int i = 0; i < chartSummaries.length; i++) {
      if (chartSummaries[i] != other.chartSummaries[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(entries),
    Object.hashAll(weeklySummaries),
    Object.hashAll(chartSummaries),
    refreshErrorMessage,
  );

  @override
  String toString() =>
      'WeightHistoryLoaded(entries: ${entries.length}, weeklySummaries: ${weeklySummaries.length}, chartSummaries: ${chartSummaries.length}, refreshErrorMessage: $refreshErrorMessage)';
}

/// Terminal error state for when the initial entry fetch fails.
final class WeightHistoryError extends WeightHistoryState {
  final String message;

  const WeightHistoryError(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeightHistoryError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'WeightHistoryError(message: $message)';
}
