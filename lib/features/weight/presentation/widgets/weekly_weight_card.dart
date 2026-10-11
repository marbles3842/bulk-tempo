import 'package:flutter/material.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/weight/domain/models/weight_entry_entity.dart';
import 'package:bulk_tempo/features/weight/domain/models/weekly_weight_summary_entity.dart';

/// Card widget displaying an ISO week summary row with its average weight,
/// expanding to reveal the individual daily weight measurements logged for that week.
class WeeklyWeightCard extends StatelessWidget {
  final WeeklyWeightSummaryEntity summary;
  final bool initiallyExpanded;
  final ValueChanged<WeightEntryEntity>? onEntryTap;

  const WeeklyWeightCard({
    super.key,
    required this.summary,
    required this.initiallyExpanded,
    this.onEntryTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: Key('week_card_${summary.weekStartIso}'),
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: Text(
                WeekDateUtils.formatWeekRange(
                  summary.weekStartMonday,
                  summary.weekEndSunday,
                ),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${summary.loggedDaysCount}/7 days',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${summary.averageWeightKg.toStringAsFixed(2)} kg avg',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        children: summary.entries.map((entry) {
          return ListTile(
            key: Key('daily_entry_${entry.dateIso}'),
            dense: true,
            onTap: onEntryTap != null ? () => onEntryTap!(entry) : null,
            leading: Icon(
              Icons.calendar_today,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(
              WeekDateUtils.formatDayWithWeekday(entry.date),
              style: theme.textTheme.bodyMedium,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${entry.weightKg.toStringAsFixed(2)} kg',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  key: Key('edit_entry_${entry.dateIso}'),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit weight entry',
                  onPressed: onEntryTap != null
                      ? () => onEntryTap!(entry)
                      : null,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
