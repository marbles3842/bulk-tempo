import 'package:flutter_test/flutter_test.dart';
import 'package:bulk_tempo/features/dashboard/domain/models/weekly_progress_overview_entity.dart';
import 'package:bulk_tempo/features/dashboard/presentation/utils/dashboard_chart_utils.dart';

void main() {
  group('DashboardChartUtils.shouldShowWeekLabel', () {
    test(
      'returns true for indices 0, 4, 8, 11 on a 12-slot window with default stride 4',
      () {
        const totalSlots = 12;
        final visibleIndices = <int>[];

        for (var i = 0; i < totalSlots; i++) {
          if (DashboardChartUtils.shouldShowWeekLabel(
            index: i,
            totalSlots: totalSlots,
          )) {
            visibleIndices.add(i);
          }
        }

        expect(visibleIndices, equals(<int>[0, 4, 8, 11]));
      },
    );

    test('suppresses intermediate tick when too close to the last index', () {
      // 10 slots: indices 0..9.
      // 0: true, 4: true (dist 5 >= 2), 8: false (dist 9 - 8 = 1 < 2), 9: true
      const totalSlots = 10;
      final visibleIndices = <int>[];

      for (var i = 0; i < totalSlots; i++) {
        if (DashboardChartUtils.shouldShowWeekLabel(
          index: i,
          totalSlots: totalSlots,
          stride: 4,
        )) {
          visibleIndices.add(i);
        }
      }

      expect(visibleIndices, equals(<int>[0, 4, 9]));
    });

    test('returns false for negative or out of bounds indices', () {
      expect(
        DashboardChartUtils.shouldShowWeekLabel(index: -1, totalSlots: 12),
        isFalse,
      );
      expect(
        DashboardChartUtils.shouldShowWeekLabel(index: 12, totalSlots: 12),
        isFalse,
      );
      expect(
        DashboardChartUtils.shouldShowWeekLabel(index: 0, totalSlots: 0),
        isFalse,
      );
    });

    test('handles small slot collections gracefully', () {
      expect(
        DashboardChartUtils.shouldShowWeekLabel(index: 0, totalSlots: 1),
        isTrue,
      );
      expect(
        DashboardChartUtils.shouldShowWeekLabel(index: 0, totalSlots: 2),
        isTrue,
      );
      expect(
        DashboardChartUtils.shouldShowWeekLabel(index: 1, totalSlots: 2),
        isTrue,
      );
    });
  });

  group('DashboardChartUtils.buildBottomWeekTitles', () {
    test(
      'constructs AxisTitles with SideTitles configured for non-overlapping labels',
      () {
        final slots = List.generate(
          12,
          (i) => CalendarWeekProgressSlotEntity(
            weekStartIso: '2026-08-${(i + 1).toString().padLeft(2, '0')}',
            weekStartMonday: DateTime.utc(2026, 8, i + 1),
            weekEndSunday: DateTime.utc(2026, 8, i + 7),
            loggedWeightDaysCount: 0,
            workoutCount: 0,
            isCurrentWeek: i == 11,
          ),
        );

        final axisTitles = DashboardChartUtils.buildBottomWeekTitles(
          slots: slots,
        );
        final sideTitles = axisTitles.sideTitles;

        expect(sideTitles.showTitles, isTrue);
        expect(sideTitles.interval, equals(1.0));
        expect(sideTitles.reservedSize, equals(32.0));
      },
    );
  });
}
