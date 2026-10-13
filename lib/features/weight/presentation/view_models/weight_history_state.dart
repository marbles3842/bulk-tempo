import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';
import 'package:bulk_tempo/features/weight/domain/models/weekly_weight_summary_entity.dart';

part 'weight_history_state.freezed.dart';

/// Pure Dart state representations for the Weight History screen.
@freezed
sealed class WeightHistoryState with _$WeightHistoryState {
  const factory WeightHistoryState.initial() = WeightHistoryInitial;
  const factory WeightHistoryState.loading() = WeightHistoryLoading;
  const factory WeightHistoryState.loaded({
    required List<WeightEntryEntity> entries,
    required List<WeeklyWeightSummaryEntity> weeklySummaries,
    required List<WeeklyWeightSummaryEntity> chartSummaries,
    String? refreshErrorMessage,
  }) = WeightHistoryLoaded;
  const factory WeightHistoryState.error(String message) = WeightHistoryError;
}

extension WeightHistoryLoadedX on WeightHistoryLoaded {
  /// Checks whether a weight entry has already been recorded for [dateIso] (`YYYY-MM-DD`).
  bool hasEntryForDate(String dateIso) {
    return entries.any((entry) => entry.dateIso == dateIso);
  }

  /// Whether the loaded entry list is empty.
  bool get isEmpty => entries.isEmpty;
}
