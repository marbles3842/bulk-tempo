import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';

part 'weekly_weight_summary_entity.freezed.dart';

/// Domain entity representing an ISO Monday–Sunday weekly aggregate of weight entries.
@freezed
abstract class WeeklyWeightSummaryEntity with _$WeeklyWeightSummaryEntity {
  const WeeklyWeightSummaryEntity._();

  const factory WeeklyWeightSummaryEntity({
    required String weekStartIso,
    required DateTime weekStartMonday,
    required DateTime weekEndSunday,
    required double averageWeightKg,
    required List<WeightEntryEntity> entries,
  }) = _WeeklyWeightSummaryEntity;

  int get loggedDaysCount => entries.length;

  /// Groups individual daily entries into ISO Monday–Sunday weeks.
  static List<WeeklyWeightSummaryEntity> groupEntriesByIsoWeek(
    List<WeightEntryEntity> entries,
  ) {
    if (entries.isEmpty) {
      return const <WeeklyWeightSummaryEntity>[];
    }

    // 1. Deduplicate by dateIso, keeping latest if duplicates exist in input
    final Map<String, WeightEntryEntity> deduped = {};
    for (final entry in entries) {
      final existing = deduped[entry.dateIso];
      if (existing == null || !entry.updatedAt.isBefore(existing.updatedAt)) {
        deduped[entry.dateIso] = entry;
      }
    }

    // 2. Group by ISO Monday
    final Map<String, List<WeightEntryEntity>> weekGroups = {};
    final Map<String, DateTime> weekMondays = {};
    final Map<String, DateTime> weekSundays = {};

    for (final entry in deduped.values) {
      final monday = WeekDateUtils.startOfIsoWeekUtc(entry.date);
      final weekStartIso = WeekDateUtils.toIsoDateString(monday);
      final sunday = WeekDateUtils.endOfIsoWeekUtc(entry.date);

      weekMondays[weekStartIso] = monday;
      weekSundays[weekStartIso] = sunday;
      weekGroups
          .putIfAbsent(weekStartIso, () => <WeightEntryEntity>[])
          .add(entry);
    }

    // 3. Build WeeklyWeightSummaryEntity for each non-empty week
    final List<WeeklyWeightSummaryEntity> summaries = [];
    for (final groupEntry in weekGroups.entries) {
      final weekStartIso = groupEntry.key;
      final weekEntries = groupEntry.value;
      if (weekEntries.isEmpty) {
        continue;
      }

      // Sort entries descending by dateIso
      weekEntries.sort((a, b) => b.dateIso.compareTo(a.dateIso));

      final sum = weekEntries.fold<double>(
        0.0,
        (acc, item) => acc + item.weightKg,
      );
      final averageWeightKg = WeekDateUtils.roundToTwoDecimals(
        sum / weekEntries.length,
      );

      summaries.add(
        WeeklyWeightSummaryEntity(
          weekStartIso: weekStartIso,
          weekStartMonday: weekMondays[weekStartIso]!,
          weekEndSunday: weekSundays[weekStartIso]!,
          averageWeightKg: averageWeightKg,
          entries: List.unmodifiable(weekEntries),
        ),
      );
    }

    // 4. Sort summaries descending by weekStartIso (newest week first)
    summaries.sort((a, b) => b.weekStartIso.compareTo(a.weekStartIso));
    return summaries;
  }
}
