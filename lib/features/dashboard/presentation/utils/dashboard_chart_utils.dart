import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:bulk_tempo/core/utils/week_date_utils.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/weekly_progress_overview_entity.dart';

/// Presentation utilities for dashboard charts.
abstract final class DashboardChartUtils {
  /// Default interval (in weeks) between X-axis labels to prevent text crowding on mobile.
  static const int defaultAxisStride = 4;

  /// Returns true if an axis tick at [index] should be labeled.
  ///
  /// Always shows the first slot (index `0`) and the current/last slot (`totalSlots - 1`),
  /// plus intermediate slots at every [stride] interval. Suppresses intermediate
  /// ticks that fall too close to the final slot to prevent edge collisions.
  static bool shouldShowWeekLabel({
    required int index,
    required int totalSlots,
    int stride = defaultAxisStride,
  }) {
    if (totalSlots <= 0 || index < 0 || index >= totalSlots) {
      return false;
    }
    if (index == 0 || index == totalSlots - 1) {
      return true;
    }
    if (index % stride != 0) {
      return false;
    }

    // Suppress if intermediate tick is too close to the final slot (e.g. index 10 next to 11).
    final distanceToLast = totalSlots - 1 - index;
    return distanceToLast >= (stride / 2);
  }

  /// Builds a unified, non-overlapping bottom [AxisTitles] for 12-calendar-week charts.
  static AxisTitles buildBottomWeekTitles({
    required List<CalendarWeekProgressSlotEntity> slots,
    int stride = defaultAxisStride,
  }) {
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 32,
        interval: 1,
        getTitlesWidget: (value, meta) {
          final index = value.toInt();
          if (value != index.toDouble() ||
              !shouldShowWeekLabel(
                index: index,
                totalSlots: slots.length,
                stride: stride,
              )) {
            return const SizedBox.shrink();
          }

          return SideTitleWidget(
            meta: meta,
            fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
            child: Text(
              WeekDateUtils.formatShortWeekLabel(slots[index].weekStartMonday),
              style: const TextStyle(fontSize: 10),
            ),
          );
        },
      ),
    );
  }
}
