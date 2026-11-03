import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:fquran_app/app/i18n/app_translations.dart';
import 'package:fquran_app/app/routes/app_pages.dart';
import 'package:fquran_app/app/services/mushaf_layout.dart';
import 'package:fquran_app/app/services/quran_service.dart';
import 'package:fquran_app/app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory documents;
  late MushafLayout layout;

  setUpAll(() async {
    documents = await Directory.systemTemp.createTemp('deen-mushaf-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => documents.path,
        );
    await StorageService.init();
    await QuranService.instance.load();
    layout = await MushafLayout.load();
  });

  tearDownAll(() async {
    await documents.delete(recursive: true).catchError((_) => documents);
  });

  test('every page fills its 15 lines (8 on pages 1 and 2)', () {
    expect(layout.pageCount, QuranService.pageCount);
    for (var p = 1; p <= layout.pageCount; p++) {
      expect(layout.page(p).map((l) => l.line).toList(), [
        for (var i = 1; i <= MushafLayout.linesOn(p); i++) i,
      ], reason: 'page $p');
    }
  });

  test('each surah gets one header, and a basmala except At-Tawbah', () {
    final headers = <int>[];
    var basmalas = 0;
    for (var p = 1; p <= layout.pageCount; p++) {
      for (final l in layout.page(p)) {
        if (l.kind == MushafLineKind.surah) headers.add(l.surah);
        if (l.kind == MushafLineKind.basmala) basmalas++;
      }
    }
    expect(headers, [for (var s = 1; s <= 114; s++) s]);
    expect(basmalas, 112);
  });

  test('each page holds one ayah-number glyph per ayah on that page', () {
    final quran = QuranService.instance;
    final marks = RegExp('[\uFB50-\uFDFF\uFE70-\uFEFF]');
    for (var p = 1; p <= layout.pageCount; p++) {
      final text = layout
          .page(p)
          .where((l) => l.kind == MushafLineKind.text)
          .map((l) => l.text)
          .join(' ');
      expect(
        marks.allMatches(text).length,
        quran.ayahsOnPage(p).length,
        reason: 'page $p',
      );
    }
  });

  test('each surah\'s page range matches the pages of its ayahs', () {
    final quran = QuranService.instance;
    for (var n = 1; n <= 114; n++) {
      final surah = quran.surah(n);
      expect(quran.ayahAt(n, 1)!.page, surah.pageStart, reason: 'surah $n');
      expect(
        quran.ayahAt(n, surah.ayahs)!.page,
        surah.pageEnd,
        reason: 'surah $n',
      );
    }
  });

  test('a last-read page saved before the page fix follows the ayah', () async {
    final quran = QuranService.instance;
    await quran.saveLastRead(5, 77, 121);
    expect(quran.lastRead, (5, 77, 120));
  });

  test('page 2 opens Al-Baqarah with header, basmala, then 2:1 on line 3', () {
    final page = layout.page(2);
    expect(page[0].kind, MushafLineKind.surah);
    expect(page[0].surah, 2);
    expect(page[1].kind, MushafLineKind.basmala);
    expect(page[2].text, startsWith('الٓمٓ'));
  });

  testWidgets('page mode draws the printed lines', (t) async {
    await t.pumpWidget(
      GetMaterialApp(
        translations: DeenTranslations(),
        locale: const Locale('en'),
        initialRoute: Routes.mushaf(3),
        getPages: AppPages.pages,
      ),
    );
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('mushaf-printed-3')), findsOneWidget);
    for (var i = 1; i <= 15; i++) {
      expect(find.byKey(ValueKey('mushaf-line-3-$i')), findsOneWidget);
    }
    expect(t.takeException(), isNull);
  });
}
