import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:fquran_app/app/i18n/app_translations.dart';
import 'package:fquran_app/app/routes/app_pages.dart';
import 'package:fquran_app/app/services/crash_log.dart';
import 'package:fquran_app/app/services/habit_service.dart';
import 'package:fquran_app/app/services/mushaf_layout.dart';
import 'package:fquran_app/app/services/prayer_service.dart';
import 'package:fquran_app/app/services/prayer_widget.dart';
import 'package:fquran_app/app/services/quran_service.dart';
import 'package:fquran_app/app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory documents;

  setUpAll(() async {
    documents = await Directory.systemTemp.createTemp('deen-platform-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => documents.path,
        );
    await StorageService.init();
    await QuranService.instance.load();
    await MushafLayout.load();
  });

  tearDownAll(() async {
    await documents.delete(recursive: true).catchError((_) => documents);
  });

  test('the 604 mushaf pages hold every ayah once, in order', () {
    final q = QuranService.instance;
    var count = 0;
    (int, int)? prev;
    for (var p = 1; p <= QuranService.pageCount; p++) {
      final on = q.ayahsOnPage(p);
      expect(on, isNotEmpty, reason: 'page $p');
      for (final (s, a) in on) {
        expect(a.page, p);
        final key = (s, a.numberInSurah);
        if (prev != null) {
          expect(
            s > prev.$1 || (s == prev.$1 && a.numberInSurah == prev.$2 + 1),
            isTrue,
            reason: '$key after $prev',
          );
        }
        prev = key;
        count++;
      }
    }
    expect(count, 6236);
    expect(q.ayahsOnPage(605), isEmpty);
  });

  test('crash log keeps the newest 20 and clears', () async {
    await CrashLog.clear();
    for (var i = 0; i < 25; i++) {
      await CrashLog.record(StateError('e$i'), StackTrace.current);
    }
    expect(CrashLog.entries, hasLength(CrashLog.max));
    expect(CrashLog.entries.first['e'], contains('e24'));
    expect(CrashLog.report(), contains('e24'));
    await CrashLog.clear();
    expect(CrashLog.entries, isEmpty);
  });

  test('widget payload lists upcoming prayers without sunrise', () {
    final now = DateTime(2026, 1, 1, 12);
    final slots = [
      PrayerSlot('fajr', DateTime(2026, 1, 1, 5)),
      PrayerSlot('sunrise', DateTime(2026, 1, 1, 13)),
      PrayerSlot('asr', DateTime(2026, 1, 1, 15, 30)),
      PrayerSlot('fajr', DateTime(2026, 1, 2, 5)),
    ];
    final list =
        jsonDecode(PrayerWidget.payload(slots, now, (k) => k.tr)) as List;
    expect(list.map((e) => e[1]), ['asr', 'fajr']);
    expect(list.first[0], DateTime(2026, 1, 1, 15, 30).millisecondsSinceEpoch);
  });

  test('phase 7 strings exist in English, Arabic and Swahili', () {
    final keys = DeenTranslations().keys;
    for (final k in [
      'mushafPage',
      'openInReader',
      'problemReports',
      'problemReportsDesc',
      'noProblemReports',
      'shareReport',
      'clearReports',
      'problemReportsCount',
    ]) {
      for (final l in ['en', 'ar', 'sw']) {
        expect(keys[l]![k], isNotNull, reason: '$l $k');
      }
    }
  });

  testWidgets('mushaf opens at a page and swipes to the next', (t) async {
    await t.pumpWidget(
      GetMaterialApp(
        translations: DeenTranslations(),
        locale: const Locale('en'),
        initialRoute: Routes.mushaf(1),
        getPages: AppPages.pages,
      ),
    );
    await t.pumpAndSettle();
    expect(find.textContaining('Page 1'), findsWidgets);
    expect(QuranService.instance.lastRead?.$3, 1);
    await t.fling(
      find.byKey(const ValueKey('mushaf-pages')),
      const Offset(600, 0),
      2000,
    );
    await t.pumpAndSettle();
    expect(find.textContaining('Page 2'), findsWidgets);
    expect(QuranService.instance.lastRead?.$3, 2);
  });

  testWidgets('Arabic (RTL) also swipes right for the next page', (t) async {
    await t.pumpWidget(
      GetMaterialApp(
        translations: DeenTranslations(),
        locale: const Locale('ar'),
        builder: (_, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        initialRoute: Routes.mushaf(10),
        getPages: AppPages.pages,
      ),
    );
    await t.pumpAndSettle();
    await t.fling(
      find.byKey(const ValueKey('mushaf-pages')),
      const Offset(600, 0),
      2000,
    );
    await t.pumpAndSettle();
    expect(QuranService.instance.lastRead?.$3, 11);
  });

  testWidgets('page 604 counts only after Done', (t) async {
    final habits = HabitService.instance;
    int today() => habits.pagesOn(DateTime.now());
    final before = today();
    await t.pumpWidget(
      GetMaterialApp(
        translations: DeenTranslations(),
        locale: const Locale('en'),
        initialRoute: Routes.mushaf(603),
        getPages: AppPages.pages,
      ),
    );
    await t.pumpAndSettle();
    await t.fling(
      find.byKey(const ValueKey('mushaf-pages')),
      const Offset(600, 0),
      2000,
    );
    await t.pumpAndSettle();
    expect(today(), before + 1);
    await t.scrollUntilVisible(
      find.byKey(const ValueKey('mushaf-finish')),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('mushaf-pages')),
            matching: find.byType(Scrollable),
          )
          .last,
    );
    await t.tap(find.byKey(const ValueKey('mushaf-finish')));
    await t.pump();
    expect(today(), before + 2);
  });
}
