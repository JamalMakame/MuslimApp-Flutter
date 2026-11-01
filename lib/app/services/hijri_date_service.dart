import 'package:hijri/hijri_array.dart' show arMonthNames, monthNames;
import 'package:hijri/hijri_calendar.dart';

/// Umm al-Qura dates with a locally chosen Hijri-day adjustment.
///
/// A positive offset advances the Hijri date, never the real Gregorian date.
/// Neither the calculated dates nor lunar phases confirm a local sighting.
abstract final class HijriDateService {
  static HijriCalendar on(DateTime gregorian, int offset) =>
      HijriCalendar.fromDate(
        DateTime(gregorian.year, gregorian.month, gregorian.day + offset),
      );

  static DateTime gregorianFor(int year, int month, int day, int offset) {
    final date = HijriCalendar().hijriToGregorian(year, month, day);
    return DateTime(date.year, date.month, date.day - offset);
  }

  static String monthName(int month, String language) =>
      (language == 'ar' ? arMonthNames : monthNames)[month] ?? '';

  static int daysBetween(DateTime from, DateTime to) => DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
}
