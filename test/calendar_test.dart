import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:fquran_app/app/controllers/calendar_controller.dart';
import 'package:fquran_app/app/i18n/app_translations.dart';
import 'package:fquran_app/app/services/hijri_date_service.dart';
import 'package:fquran_app/app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a Hijri adjustment never moves the Gregorian day', () {
    final actual = DateTime(2026, 10, 31, 23, 40);
    for (final offset in [-2, -1, 0, 1, 2]) {
      final h = HijriDateService.on(actual, offset);
      final date = HijriDateService.gregorianFor(
        h.hYear,
        h.hMonth,
        h.hDay,
        offset,
      );
      expect(date, DateTime(2026, 10, 31));
    }
    final unadjusted = HijriCalendar.fromDate(DateTime(2026, 11, 1));
    final ahead = HijriDateService.on(actual, 1);
    expect(
      (ahead.hYear, ahead.hMonth, ahead.hDay),
      (unadjusted.hYear, unadjusted.hMonth, unadjusted.hDay),
    );
  });

  test('calendar-day difference ignores daylight-saving hour changes', () {
    expect(
      HijriDateService.daysBetween(
        DateTime(2026, 3, 8, 22),
        DateTime(2026, 3, 9, 1),
      ),
      1,
    );
  });

  test('every new calendar label is available in en, ar and sw', () {
    final locales = DeenTranslations().keys;
    for (final language in ['ar', 'sw']) {
      expect(locales[language]!.keys.toSet(), locales['en']!.keys.toSet());
    }
    expect(locales['en']!['calendarBasis'], contains('estimate'));
  });

  group('CalendarController', () {
    late Directory documents;

    void mockDocuments() => TestDefaultBinaryMessengerBinding
        .instance
        .defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => documents.path,
        );

    setUpAll(() async {
      documents = await Directory.systemTemp.createTemp('deen-calendar-test-');
      mockDocuments();
      await StorageService.init();
      Get.testMode = true;
    });

    // GetStorage flushes to disk asynchronously; keep the documents
    // directory mocked for every test so a late flush never hits a missing
    // plugin.
    setUp(() async {
      mockDocuments();
      await StorageService.instance.clearAll();
    });

    tearDown(() => Get.delete<CalendarController>(force: true));

    tearDownAll(() async {
      await GetStorage().save();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
      await documents.delete(recursive: true);
    });

    test(
      'grid keeps weekdays and day numbers aligned after an offset',
      () async {
        final date = DateTime(2025, 11, 1);
        final c = Get.put(CalendarController(clock: () => date));
        await c.bumpOffset(1);

        expect(c.todayGreg, date);
        expect(
          HijriDateService.gregorianFor(
            c.todayHijri.hYear,
            c.todayHijri.hMonth,
            c.todayHijri.hDay,
            c.offset.value,
          ),
          date,
        );
        final first = HijriDateService.gregorianFor(
          c.hYear.value,
          c.hMonth.value,
          1,
          c.offset.value,
        );
        final cell = c.cells[first.weekday % 7];
        expect(cell.primary, 1);
        expect(cell.secondary, first.day);
        expect(c.cells.whereType<CalCell>().where((e) => e.isToday).length, 1);

        await c.setPrimary('gregorian');
        final gregFirst = c.cells.firstWhere((cell) => cell.inMonth);
        final expected = HijriDateService.on(
          DateTime(c.gYear.value, c.gMonth.value, 1),
          1,
        );
        expect(gregFirst.hijriDay, expected.hDay);
        expect(StorageService.instance.readInt(StorageService.kMoonOffset), 1);
      },
    );

    test(
      'switching calendar type keeps the viewed month instead of resetting',
      () async {
        final c = Get.put(
          CalendarController(clock: () => DateTime(2026, 6, 15)),
        );
        c.prevMonth();
        final start = HijriDateService.gregorianFor(
          c.hYear.value,
          c.hMonth.value,
          1,
          0,
        );
        await c.setPrimary('gregorian');
        expect((c.gYear.value, c.gMonth.value), (start.year, start.month));
      },
    );

    test('occasions are chronological and have positive remaining days', () {
      final c = Get.put(CalendarController(clock: () => DateTime(2026, 6, 15)));
      final events = c.occasions;
      expect(events.length, greaterThanOrEqualTo(4));
      expect(events.every((o) => o.daysUntil > 0), isTrue);
      expect(
        events.map((o) => o.daysUntil).toList(),
        orderedEquals([...events.map((o) => o.daysUntil)]..sort()),
      );
    });
  });
}
