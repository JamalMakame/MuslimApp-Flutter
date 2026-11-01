import 'dart:async';

import 'package:get/get.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../services/hijri_date_service.dart';
import '../services/storage_service.dart';

/// One cell in the month grid.
class CalCell {
  final int primary; // big number (hijri day, or gregorian day)
  final int secondary; // small number (gregorian day, or hijri day)
  final int hijriDay;
  final bool inMonth;
  final bool isToday;
  final bool isWhite; // 13/14/15 hijri (fasting)
  final bool isFirst; // 1st of hijri month
  const CalCell({
    required this.primary,
    required this.secondary,
    required this.hijriDay,
    required this.inMonth,
    required this.isToday,
    required this.isWhite,
    required this.isFirst,
  });
}

/// Upcoming sacred date row.
class Occasion {
  final String title; // already localized
  final String subtitle; // localized descriptor
  final int daysUntil;
  const Occasion(this.title, this.subtitle, this.daysUntil);
}

/// Hijri calendar state: viewed month, moon-sighting offset, display mode.
class CalendarController extends GetxController {
  CalendarController({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final _s = StorageService.instance;
  final DateTime Function() _clock;
  Timer? _ticker;
  final currentDate = DateTime.now().obs;

  /// Moon-sighting calibration −2..+2, persisted.
  final offset = 0.obs;

  /// 'hijri' | 'gregorian' — which numbering leads the month grid.
  final primary = 'hijri'.obs;

  /// Hijri month being viewed.
  final hYear = 0.obs;
  final hMonth = 0.obs;

  /// Gregorian month being viewed (used when primary == 'gregorian').
  final gYear = 0.obs;
  final gMonth = 0.obs;

  final _h = HijriCalendar();

  @override
  void onInit() {
    super.onInit();
    offset.value = _s.readInt(StorageService.kMoonOffset).clamp(-2, 2);
    final savedPrimary = _s.readStr(StorageService.kCalPrimary, 'hijri');
    primary.value = savedPrimary == 'gregorian' ? savedPrimary : 'hijri';
    currentDate.value = _clock();
    resetToToday();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      final next = _clock();
      final previous = currentDate.value;
      if (previous.year != next.year ||
          previous.month != next.month ||
          previous.day != next.day) {
        currentDate.value = next;
        resetToToday();
      }
    });
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }

  // ---- Derived ------------------------------------------------------------
  /// Today's Hijri date, calibrated.
  HijriCalendar get todayHijri => HijriDateService.on(todayGreg, offset.value);

  DateTime get todayGreg => currentDate.value;

  /// Month names from the same Hijri data as the calendar calculation.
  String monthName(int month) =>
      HijriDateService.monthName(month, Get.locale?.languageCode ?? 'en');

  String get viewedMonthTitle => '${monthName(hMonth.value)} ${hYear.value}';

  /// Gregorian range covered by the viewed hijri month ("Oct 13 – Nov 11").
  String get gregorianRange {
    final first = HijriDateService.gregorianFor(
      hYear.value,
      hMonth.value,
      1,
      offset.value,
    );
    final len = _h.getDaysInMonth(hYear.value, hMonth.value);
    final last = HijriDateService.gregorianFor(
      hYear.value,
      hMonth.value,
      len,
      offset.value,
    );
    final loc = Get.locale?.toLanguageTag() ?? 'en';
    return '${DateFormat('d MMM', loc).format(first)} – '
        '${DateFormat('d MMM y', loc).format(last)}';
  }

  /// Hijri range covered by viewed gregorian month.
  String get hijriRange {
    final first = HijriDateService.on(
      DateTime(gYear.value, gMonth.value, 1),
      offset.value,
    );
    final len = DateTime(gYear.value, gMonth.value + 1, 0).day;
    final last = HijriDateService.on(
      DateTime(gYear.value, gMonth.value, len),
      offset.value,
    );
    return '${first.hDay} ${monthName(first.hMonth)} – '
        '${last.hDay} ${monthName(last.hMonth)} ${last.hYear}';
  }

  /// A calendar-day approximation, not an observed moon phase.
  String moonPhase(int hDay) {
    return switch (hDay) {
      <= 2 => 'moonNew',
      <= 6 => 'moonWaxingCrescent',
      <= 9 => 'moonFirstQuarter',
      <= 13 => 'moonWaxingGibbous',
      <= 16 => 'moonFull',
      <= 21 => 'moonWaningGibbous',
      <= 24 => 'moonLastQuarter',
      _ => 'moonWaningCrescent',
    };
  }

  // ---- Grid ---------------------------------------------------------------
  /// Sunday-first cells, including muted dates from adjacent months.
  List<CalCell> get cells {
    if (primary.value == 'hijri') {
      final len = _h.getDaysInMonth(hYear.value, hMonth.value);
      final firstGreg = HijriDateService.gregorianFor(
        hYear.value,
        hMonth.value,
        1,
        offset.value,
      );
      final leading = firstGreg.weekday % 7; // Sunday=0
      final count = ((leading + len + 6) ~/ 7) * 7;
      final now = todayGreg;
      return List<CalCell>.generate(count, (i) {
        final g = DateTime(
          firstGreg.year,
          firstGreg.month,
          firstGreg.day + i - leading,
        );
        final h = HijriDateService.on(g, offset.value);
        final inMonth = h.hYear == hYear.value && h.hMonth == hMonth.value;
        return CalCell(
          primary: h.hDay,
          secondary: g.day,
          hijriDay: h.hDay,
          inMonth: inMonth,
          isToday:
              inMonth &&
              g.year == now.year &&
              g.month == now.month &&
              g.day == now.day,
          isWhite: inMonth && h.hDay >= 13 && h.hDay <= 15,
          isFirst: inMonth && h.hDay == 1,
        );
      });
    }
    // Gregorian-primary: each gregorian day with its hijri day underneath.
    final len = DateTime(gYear.value, gMonth.value + 1, 0).day;
    final leading = DateTime(gYear.value, gMonth.value, 1).weekday % 7;
    final count = ((leading + len + 6) ~/ 7) * 7;
    final now = todayGreg;
    return List<CalCell>.generate(count, (i) {
      final g = DateTime(gYear.value, gMonth.value, i - leading + 1);
      final h = HijriDateService.on(g, offset.value);
      final inMonth = g.month == gMonth.value && g.year == gYear.value;
      return CalCell(
        primary: g.day,
        secondary: h.hDay,
        hijriDay: h.hDay,
        inMonth: inMonth,
        isToday:
            inMonth &&
            now.year == g.year &&
            now.month == g.month &&
            now.day == g.day,
        isWhite: inMonth && h.hDay >= 13 && h.hDay <= 15,
        isFirst: inMonth && h.hDay == 1,
      );
    });
  }

  /// Sunday-first; use narrow locale forms so RTL and small devices fit.
  List<String> weekdayLetters() {
    final loc = Get.locale?.toLanguageTag() ?? 'en';
    final fmt = DateFormat('EEEEE', loc);
    // 2024-01-07 was a Sunday.
    return List.generate(7, (i) => fmt.format(DateTime(2024, 1, 7 + i)));
  }

  // ---- Occasions ----------------------------------------------------------
  static const _fixed = <(int, int), (String, String)>{
    (1, 1): ('occNewYear', 'newHijriMonth'),
    (1, 10): ('occAshura', 'fastingRecommended'),
    (3, 12): ('occMawlid', 'occMawlid'),
    (7, 27): ('occIsraMiraj', 'nightJourney'),
    (8, 15): ('occMidShaban', 'monthPrep'),
    (9, 1): ('occRamadanStart', 'monthPrep'),
    (9, 27): ('occLaylatQadr', 'lastTenNights'),
    (10, 1): ('occEidFitr', 'eidCelebration'),
    (12, 9): ('occArafah', 'fastingRecommended'),
    (12, 10): ('occEidAdha', 'eidCelebration'),
  };

  List<Occasion> get occasions {
    final today = todayHijri;
    final out = <Occasion>[];
    // Collect before sorting: calendar events are not stored in date order.
    for (var y = today.hYear; y <= today.hYear + 1; y++) {
      for (final e in _fixed.entries) {
        final g = HijriDateService.gregorianFor(
          y,
          e.key.$1,
          e.key.$2,
          offset.value,
        );
        final diff = HijriDateService.daysBetween(todayGreg, g);
        if (diff <= 0) continue;
        out.add(Occasion(e.value.$1.tr, e.value.$2.tr, diff));
      }
    }
    final nm = today.hMonth == 12
        ? (1, today.hYear + 1)
        : (today.hMonth + 1, today.hYear);
    final nextMonth = HijriDateService.gregorianFor(
      nm.$2,
      nm.$1,
      1,
      offset.value,
    );
    final diff = HijriDateService.daysBetween(todayGreg, nextMonth);
    if (diff > 0 && nm.$1 != 1) {
      out.add(
        Occasion(
          'occNewMonth'.trParams({'month': monthName(nm.$1)}),
          'newHijriMonth'.tr,
          diff,
        ),
      );
    }
    out.sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
    return out;
  }

  // ---- Mutations -----------------------------------------------------------
  void prevMonth() {
    if (primary.value == 'hijri') {
      if (hMonth.value == 1) {
        hMonth.value = 12;
        hYear.value--;
      } else {
        hMonth.value--;
      }
    } else {
      if (gMonth.value == 1) {
        gMonth.value = 12;
        gYear.value--;
      } else {
        gMonth.value--;
      }
    }
  }

  void nextMonth() {
    if (primary.value == 'hijri') {
      if (hMonth.value == 12) {
        hMonth.value = 1;
        hYear.value++;
      } else {
        hMonth.value++;
      }
    } else {
      if (gMonth.value == 12) {
        gMonth.value = 1;
        gYear.value++;
      } else {
        gMonth.value++;
      }
    }
  }

  void resetToToday() {
    currentDate.value = _clock();
    final h = todayHijri;
    hYear.value = h.hYear;
    hMonth.value = h.hMonth;
    final g = todayGreg;
    gYear.value = g.year;
    gMonth.value = g.month;
  }

  Future<void> bumpOffset(int delta) async {
    offset.value = (offset.value + delta).clamp(-2, 2);
    await _s.write(StorageService.kMoonOffset, offset.value);
    resetToToday();
  }

  Future<void> setPrimary(String p) async {
    if (p != 'hijri' && p != 'gregorian') return;
    if (p == primary.value) return;
    if (p == 'gregorian') {
      final g = HijriDateService.gregorianFor(
        hYear.value,
        hMonth.value,
        1,
        offset.value,
      );
      gYear.value = g.year;
      gMonth.value = g.month;
    } else {
      final h = HijriDateService.on(
        DateTime(gYear.value, gMonth.value, 1),
        offset.value,
      );
      hYear.value = h.hYear;
      hMonth.value = h.hMonth;
    }
    primary.value = p;
    await _s.write(StorageService.kCalPrimary, p);
  }
}
