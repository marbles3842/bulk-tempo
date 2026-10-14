import 'package:bulk_tempo/features/gain_target/domain/models/gain_target_entity.dart';
import 'package:intl/intl.dart';

/// Formats a weekly gain range for display in the active locale.
abstract final class GainTargetFormatter {
  static String formatRange(GainTargetEntity target, String locale) {
    final format = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 2,
    );
    return '${format.format(target.minWeeklyGainKg)}–${format.format(target.maxWeeklyGainKg)}';
  }
}
