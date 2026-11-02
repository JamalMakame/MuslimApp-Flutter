import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fquran_app/app/controllers/quran_controller.dart';
import 'package:fquran_app/app/controllers/reader_controller.dart';
import 'package:fquran_app/app/controllers/settings_controller.dart';
import 'package:fquran_app/app/i18n/app_translations.dart';
import 'package:fquran_app/app/routes/app_pages.dart';
import 'package:fquran_app/app/services/quran_service.dart';
import 'package:fquran_app/app/services/storage_service.dart';
import 'package:fquran_app/app/theme/app_theme.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory documents;
  final quran = QuranService.instance;
  String? clipboard;

  setUpAll(() async {
    final fonts = [
      FontLoader(AppFonts.headline)
        ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Bold.ttf')),
      FontLoader(AppFonts.body)
        ..addFont(rootBundle.load('assets/fonts/Manrope-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/Manrope-Bold.ttf')),
      FontLoader(AppFonts.quran)
        ..addFont(rootBundle.load('assets/fonts/Amiri-Regular.ttf')),
    ];
    await Future.wait(fonts.map((font) => font.load()));
    documents = await Directory.systemTemp.createTemp('deen-reader-test-');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => documents.path,
    );
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboard = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    await StorageService.init();
    await quran.load();
  });

  setUp(() async {
    Get.testMode = true;
    clipboard = null;
    await StorageService.instance.clearAll();
    quran.resetUserState();
    Get.put(SettingsController(), permanent: true);
  });

  tearDown(Get.reset);

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    await documents.delete(recursive: true);
  });

  GetPage<dynamic> page(String name) =>
      AppPages.pages.firstWhere((p) => p.name == name);

  Future<void> pump(WidgetTester tester, String initialRoute) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.current,
        locale: const Locale('en'),
        fallbackLocale: const Locale('en'),
        translations: DeenTranslations(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ar'), Locale('sw')],
        initialRoute: initialRoute,
        getPages: [
          page(Routes.quran),
          page('/reader/:surah'),
          page(Routes.bookmarks),
          GetPage(
            name: '/memorize/:surah',
            page: () => Scaffold(
              body: Text(
                'memorize ${Get.parameters['surah']}:${Get.parameters['ayah']}',
              ),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  /// Lets a reader toast run out so no timer is left pending.
  Future<void> settleToast(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  ReaderController reader(int surah) =>
      Get.find<ReaderController>(tag: 'reader_$surah');

  testWidgets('ayahs are built as they scroll in, translation under each', (
    tester,
  ) async {
    await pump(tester, Routes.reader(2));
    final c = reader(2);
    expect(find.byKey(c.ayahKey(1)), findsOneWidget);
    expect(find.byKey(c.ayahKey(200)), findsNothing);
    expect(find.text(quran.translation(2, 1, 'en')), findsOneWidget);

    unawaited(c.jumpTo(200));
    await tester.pumpAndSettle();
    expect(find.byKey(c.ayahKey(200)), findsOneWidget);
    expect(find.byKey(c.ayahKey(1)), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the ۞ mark shows once on every quarter start', (tester) async {
    final starts = quran.ayahsFor(2).where(quran.startsHizbQuarter);
    final marked = starts.firstWhere((a) => a.text.startsWith('۞'));
    final unmarked = starts.where((a) => !a.text.startsWith('۞'));
    for (final a in [marked, ...unmarked.take(1)]) {
      await pump(tester, Routes.reader(2, ayah: a.numberInSurah));
      final block = find.byKey(reader(2).ayahKey(a.numberInSurah));
      final text = tester
          .widgetList<RichText>(
            find.descendant(of: block, matching: find.byType(RichText)),
          )
          .map((t) => t.text.toPlainText())
          .join();
      expect('۞'.allMatches(text).length, 1, reason: '2:${a.numberInSurah}');
      Get.reset();
      Get.put(SettingsController(), permanent: true);
    }
  });

  testWidgets('ayah menu: bookmark, note and copy', (tester) async {
    await pump(tester, Routes.reader(2));
    final c = reader(2);

    await tester.longPress(find.byKey(c.ayahKey(2)));
    await tester.pumpAndSettle();
    await tap(tester, 'action-bookmark');
    await settleToast(tester);
    expect(quran.bookmarkAt(2, 2), isNotNull);
    expect(find.byKey(const ValueKey('ayah-bookmarked-2')), findsOneWidget);

    await tap(tester, 'ayah-more-2');
    await tap(tester, 'action-note');
    await tester.enterText(
      find.byKey(const ValueKey('note-field')),
      'Guidance',
    );
    await tap(tester, 'note-save');
    expect(quran.bookmarkAt(2, 2)?.note, 'Guidance');

    await tap(tester, 'ayah-more-2');
    await tap(tester, 'action-copy');
    await settleToast(tester);
    expect(clipboard, contains(quran.ayahAt(2, 2)!.text));
    expect(clipboard, contains(quran.translation(2, 2, 'en')));
    expect(clipboard, contains('— Al-Baqarah 2:2'));
    expect(clipboard, contains('deen://quran/2/2'));

    await tap(tester, 'ayah-more-2');
    await tap(tester, 'action-bookmark');
    await settleToast(tester);
    expect(quran.bookmarkAt(2, 2), isNull);
  });

  testWidgets('Arabic only: no translation in the reader or the copy', (
    tester,
  ) async {
    await Get.find<SettingsController>().setTranslationLang('ar');
    await pump(tester, Routes.reader(2));
    expect(find.text(quran.translation(2, 1, 'en')), findsNothing);
    await tap(tester, 'ayah-more-1');
    await tap(tester, 'action-copy');
    await settleToast(tester);
    expect(clipboard, isNot(contains(quran.translation(2, 1, 'en'))));
    expect(clipboard, contains('— Al-Baqarah 2:1'));
  });

  test('editing a note keeps the bookmark in its place', () async {
    await quran.saveBookmark(2, 255);
    await quran.saveBookmark(36, 58);
    await quran.saveBookmark(2, 255, note: 'Kursi');
    expect(quran.bookmarksRx.map((b) => b.verseKey), ['36:58', '2:255']);
    expect(quran.bookmarkAt(2, 255)?.note, 'Kursi');
  });

  testWidgets('header bookmark toggles the ayah being read', (tester) async {
    await pump(tester, Routes.reader(36, ayah: 58));
    await tap(tester, 'reader-bookmark');
    await settleToast(tester);
    expect(quran.bookmarkAt(36, 58), isNotNull);
    await tap(tester, 'reader-bookmark');
    await settleToast(tester);
    expect(quran.bookmarkAt(36, 58), isNull);
  });

  testWidgets('memorise from here opens Hifz at that ayah', (tester) async {
    await pump(tester, Routes.reader(2, ayah: 5));
    await tap(tester, 'ayah-more-5');
    await tap(tester, 'action-memorize');
    expect(Get.currentRoute, Routes.memorize(2, ayah: 5));
    expect(find.text('memorize 2:5'), findsOneWidget);
  });

  testWidgets('next and previous surah replace the reader', (tester) async {
    await pump(tester, Routes.reader(113));
    reader(113).itemScroll.jumpTo(index: quran.ayahsFor(113).length + 1);
    await tester.pumpAndSettle();
    await tap(tester, 'reader-next');
    expect(Get.isRegistered<ReaderController>(tag: 'reader_113'), isFalse);

    final nas = reader(114);
    nas.itemScroll.jumpTo(index: quran.ayahsFor(114).length + 1);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader-next')), findsNothing);
    await tap(tester, 'reader-prev');
    expect(reader(113).surahNumber, 113);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bookmarks screen lists, edits, deletes and opens', (
    tester,
  ) async {
    await quran.saveBookmark(2, 255, note: 'Kursi');
    await quran.saveBookmark(36, 58);
    await pump(tester, Routes.quran);
    await tap(tester, 'index-bookmarks');

    final first = tester.getTopLeft(
      find.byKey(const ValueKey('bookmark-36:58')),
    );
    final second = tester.getTopLeft(
      find.byKey(const ValueKey('bookmark-2:255')),
    );
    expect(first.dy, lessThan(second.dy));
    expect(find.text('Kursi'), findsOneWidget);

    await tap(tester, 'bookmark-note-36:58');
    await tester.enterText(find.byKey(const ValueKey('note-field')), 'Peace');
    await tap(tester, 'note-save');
    expect(quran.bookmarkAt(36, 58)?.note, 'Peace');

    await tap(tester, 'bookmark-delete-36:58');
    expect(quran.bookmarkAt(36, 58), isNull);
    expect(find.byKey(const ValueKey('bookmark-36:58')), findsNothing);

    await tap(tester, 'bookmark-2:255');
    expect(reader(2).highlightAyah.value, 255);

    await quran.removeBookmark(2, 255);
    Get.back<void>();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bookmarks-empty')), findsOneWidget);
  });

  testWidgets('surah bookmark: first tap bookmarks ayah 1, then lists', (
    tester,
  ) async {
    await pump(tester, Routes.quran);
    final c = Get.find<QuranController>();
    await c.surahBookmarkTap(3);
    await tester.pumpAndSettle();
    expect(quran.bookmarkAt(3, 1), isNotNull);
    expect(Get.currentRoute, Routes.quran);
    c.surahBookmarkTap(3);
    await tester.pumpAndSettle();
    expect(Get.currentRoute, Routes.bookmarks);
  });

  test('surah bookmarks from older versions move to ayah 1', () async {
    await StorageService.instance.write(StorageService.kBookmarks, [2, 36]);
    quran.resetUserState();
    expect(quran.bookmarksRx.map((b) => b.verseKey).toSet(), {'2:1', '36:1'});
    expect(StorageService.instance.has(StorageService.kBookmarks), isFalse);
    quran.resetUserState();
    expect(quran.bookmarksRx, hasLength(2));
  });

  testWidgets('Juz tab opens a quarter in the reader', (tester) async {
    await pump(tester, Routes.quran);
    await tester.tap(find.text('juz'.tr).first);
    await tester.pumpAndSettle();
    final tile = find.byKey(const ValueKey('juz-tile-30'));
    await tester.scrollUntilVisible(
      tile,
      300,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('juz-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(tile);
    await tester.pumpAndSettle();
    final row = find.byKey(const ValueKey('quarter-row-233'));
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(reader(78).highlightAyah.value, 1);
    expect(tester.takeException(), isNull);
  });
}
