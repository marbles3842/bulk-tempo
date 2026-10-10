import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';

/// Domain entity representing an ISO Monday–Sunday weekly aggregate of weight entries.
class WeeklyWeightSummaryEntity {
  final String weekStartIso;
  final DateTime weekStartMonday;
  final DateTime weekEndSunday;
  final double averageWeightKg;
  final List<WeightEntryEntity> entries;

  const WeeklyWeightSummaryEntity({
    required this.weekStartIso,
    required this.weekStartMonday,
    required this.weekEndSunday,
    required this.averageWeightKg,
    required this.entries,
  });

  int get loggedDaysCount => entries.length;

  WeeklyWeightSummaryEntity copyWith({
    String? weekStartIso,
    DateTime? weekStartMonday,
    DateTime? weekEndSunday,
    double? averageWeightKg,
    List<WeightEntryEntity>? entries,
  }) {
    return WeeklyWeightSummaryEntity(
      weekStartIso: weekStartIso ?? this.weekStartIso,
      weekStartMonday: weekStartMonday ?? this.weekStartMonday,
      weekEndSunday: weekEndSunday ?? this.weekEndSunday,
      averageWeightKg: averageWeightKg ?? this.averageWeightKg,
      entries: entries ?? this.entries,
    );
  }

  /// Groups individual daily entries into ISO Monday–Sunday weeks.
  ///
  /// - Deduplicates entries by [dateIso], keeping the latest [updatedAt] if duplicates exist.
  /// - Groups entries by ISO Monday.
  /// - Excludes weeks with 0 entries.
  /// - Sorts daily entries in each week descending by [dateIso] (newest date first).
  /// - Computes [averageWeightKg] rounded to 2 decimal places.
  /// - Returns summaries sorted descending by [weekStartIso] (newest week first).
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WeeklyWeightSummaryEntity ||
        runtimeType != other.runtimeType) {
      return false;
    }
    if (weekStartIso != other.weekStartIso ||
        weekStartMonday != other.weekStartMonday ||
        weekEndSunday != other.weekEndSunday ||
        averageWeightKg != other.averageWeightKg ||
        entries.length != other.entries.length) {
      return false;
    }
    for (int i = 0; i < entries.length; i++) {
      if (entries[i] != other.entries[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    weekStartIso,
    weekStartMonday,
    weekEndSunday,
    averageWeightKg,
    Object.hashAll(entries),
  );

  @override
  String toString() =>
      'WeeklyWeightSummaryEntity(weekStartIso: $weekStartIso, weekStartMonday: $weekStartMonday, weekEndSunday: $weekEndSunday, averageWeightKg: $averageWeightKg, entries: $entries)';
}
