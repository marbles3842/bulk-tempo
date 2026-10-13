import 'package:intl/intl.dart';

/// Timezone-safe calendar date and ISO Monday–Sunday week utilities.
abstract final class WeekDateUtils {
  static final RegExp _isoDateRegex = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// Normalizes a [date] to midnight UTC (`DateTime.utc(y, m, d)`).
  static DateTime normalizeDateUtc(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  /// Formats a [date] into an ISO-8601 calendar date string (`YYYY-MM-DD`).
  static String toIsoDateString(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Strictly parses a `YYYY-MM-DD` string into a UTC [DateTime], rejecting
  /// non-conforming formats or non-existent calendar dates (e.g., `2026-02-30`).
  static DateTime? tryParseIsoDate(String value) {
    final match = _isoDateRegex.firstMatch(value.trim());
    if (match == null) {
      return null;
    }

    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    if (year == null || month == null || day == null) {
      return null;
    }

    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }

    final parsed = DateTime.utc(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }

    return parsed;
  }

  /// Returns the Monday (`weekday == DateTime.monday`) of the ISO week containing [date] in UTC.
  static DateTime startOfIsoWeekUtc(DateTime date) {
    final normalized = normalizeDateUtc(date);
    return normalized.subtract(
      Duration(days: normalized.weekday - DateTime.monday),
    );
  }

  /// Returns the Sunday of the ISO week containing [date] in UTC.
  static DateTime endOfIsoWeekUtc(DateTime date) {
    return startOfIsoWeekUtc(date).add(const Duration(days: 6));
  }

  /// Formats a Monday–Sunday date range (e.g. `"Oct 5 – Oct 11, 2026"` or `"Sep 28 – Oct 4, 2026"`).
  ///
  /// Uses an en-dash (`–`) separator between dates.
  static String formatWeekRange(
    DateTime weekStartMonday,
    DateTime weekEndSunday, [
    String? locale,
  ]) {
    final effectiveLocale = locale ?? Intl.defaultLocale ?? 'en';
    final monthFormat = DateFormat.MMM(effectiveLocale);
    final startMonth = monthFormat.format(weekStartMonday);
    final endMonth = monthFormat.format(weekEndSunday);

    if (weekStartMonday.year == weekEndSunday.year) {
      return '$startMonth ${weekStartMonday.day} – $endMonth ${weekEndSunday.day}, ${weekEndSunday.year}';
    }

    return '$startMonth ${weekStartMonday.day}, ${weekStartMonday.year} – $endMonth ${weekEndSunday.day}, ${weekEndSunday.year}';
  }

  /// Returns a compact week label for chart axes (e.g. `"Oct 5"`).
  static String formatShortWeekLabel(
    DateTime weekStartMonday, [
    String? locale,
  ]) {
    final effectiveLocale = locale ?? Intl.defaultLocale ?? 'en';
    final month = DateFormat.MMM(effectiveLocale).format(weekStartMonday);
    return '$month ${weekStartMonday.day}';
  }

  /// Formats a date with abbreviated weekday (e.g. `"Mon, Oct 5, 2026"`).
  static String formatDayWithWeekday(DateTime date, [String? locale]) {
    final effectiveLocale = locale ?? Intl.defaultLocale ?? 'en';
    final weekday = DateFormat.E(effectiveLocale).format(date);
    final month = DateFormat.MMM(effectiveLocale).format(date);
    return '$weekday, $month ${date.day}, ${date.year}';
  }

  /// Rounds a floating point [value] to two decimal places using standard half-up rounding.
  static double roundToTwoDecimals(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}
