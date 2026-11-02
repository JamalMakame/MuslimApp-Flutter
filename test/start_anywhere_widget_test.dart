import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fquran_app/app/controllers/home_controller.dart';
import 'package:fquran_app/app/controllers/reader_controller.dart';
import 'package:fquran_app/app/controllers/settings_controller.dart';
import 'package:fquran_app/app/data/daily_ayah.dart';
import 'package:fquran_app/app/data/daily_hadith.dart';
import 'package:fquran_app/app/i18n/app_translations.dart';
import 'package:fquran_app/app/routes/app_pages.dart';
import 'package:fquran_app/app/services/link_service.dart';
import 'package:fquran_app/app/services/quran_service.dart';
import 'package:fquran_app/app/services/storage_service.dart';
import 'package:fquran_app/app/theme/app_theme.dart';
import 'package:fquran_app/app/ui/screens/home_screen.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory documents;
  final quran = QuranService.instance;

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
    documents = await Directory.systemTemp.createTemp('deen-goto-test-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => documents.path,
        );
    await StorageService.init();
    await quran.load();
  });

  setUp(() async {
    Get.testMode = true;
    await StorageService.instance.clearAll();
    quran.lastReadRx.value = null;
    Get.put(SettingsController(), permanent: true);
  });

  tearDown(Get.reset);

  tearDownAll(() async {
    await documents.delete(recursive: true).catchError((_) => documents);
  });

  GetPage<dynamic> page(String name) =>
      AppPages.pages.firstWhere((p) => p.name == name);

  Future<void> pump(
    WidgetTester tester,
    String initialRoute, {
    String locale = 'en',
  }) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.current,
        locale: Locale(locale),
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
          GetPage(
            name: Routes.home,
            page: () => const HomeScreen(),
            binding: BindingsBuilder(() => Get.lazyPut(() => HomeController())),
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

  ReaderController reader(int surah) =>
      Get.find<ReaderController>(tag: 'reader_$surah');

  void expectOnScreen(WidgetTester tester, Finder f) {
    expect(f, findsOneWidget);
    expect(tester.getCenter(f).dy, inInclusiveRange(0, 812));
  }

  for (final locale in ['en', 'ar', 'sw']) {
    testWidgets('$locale: Go to juz 30 from the index opens 78:1', (
      tester,
    ) async {
      await pump(tester, Routes.quran, locale: locale);
      await tap(tester, 'index-goto');
      expect(find.text('goTo'.tr), findsOneWidget);
      await tap(tester, 'goto-mode-1');
      await tester.ensureVisible(find.byKey(const ValueKey('goto-juz-30')));
      await tap(tester, 'goto-juz-30');

      expect(reader(78).highlightAyah.value, 1);
      expect(quran.lastRead?.$1, 78);
      expect(
        find.text('hizbPage'.trParams({'hizb': '59', 'page': '582'})),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Go to surah + ayah validates, then scrolls to the ayah', (
    tester,
  ) async {
    await pump(tester, Routes.quran);
    await tap(tester, 'index-goto');
    await tester.enterText(find.byKey(const ValueKey('goto-ayah')), '8');
    await tap(tester, 'goto-go');
    expect(find.text('invalidNumber'.trParams({'max': '7'})), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('goto-ayah')), '5');
    await tap(tester, 'goto-go');
    expect(reader(1).highlightAyah.value, 5);
    expectOnScreen(tester, find.byKey(reader(1).ayahKey(5)));
  });

  testWidgets('Go to takes Arabic-Indic digits for ayah and page', (
    tester,
  ) async {
    await pump(tester, Routes.quran, locale: 'ar');
    await tap(tester, 'index-goto');
    await tester.enterText(find.byKey(const ValueKey('goto-ayah')), '٥');
    expect(find.text('٥'), findsOneWidget);
    await tap(tester, 'goto-go');
    expect(reader(1).highlightAyah.value, 5);

    Get.back<void>();
    await tester.pumpAndSettle();
    await tap(tester, 'index-goto');
    await tap(tester, 'goto-mode-3');
    await tester.enterText(find.byKey(const ValueKey('goto-page')), '۶۰۴');
    await tap(tester, 'goto-go');
    expect(reader(112).highlightAyah.value, 1);
  });

  testWidgets('Go to page 604 opens 112:1', (tester) async {
    await pump(tester, Routes.quran);
    await tap(tester, 'index-goto');
    await tap(tester, 'goto-mode-3');
    await tester.enterText(find.byKey(const ValueKey('goto-page')), '605');
    await tap(tester, 'goto-go');
    expect(find.text('invalidNumber'.trParams({'max': '604'})), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('goto-page')), '604');
    await tap(tester, 'goto-go');
    expect(reader(112).highlightAyah.value, 1);
  });

  testWidgets('inside the reader: same surah scrolls, another replaces it', (
    tester,
  ) async {
    await pump(tester, Routes.reader(2));
    final baqarah = reader(2);
    expect(
      find.text('hizbPage'.trParams({'hizb': '1', 'page': '2'})),
      findsOneWidget,
    );

    await tap(tester, 'reader-goto');
    await tester.enterText(find.byKey(const ValueKey('goto-ayah')), '255');
    await tap(tester, 'goto-go');
    expect(identical(reader(2), baqarah), isTrue);
    expect(baqarah.highlightAyah.value, 255);
    expectOnScreen(tester, find.byKey(baqarah.ayahKey(255)));
    final kursi = quran.ayahAt(2, 255)!;
    expect(
      find.text(
        'hizbPage'.trParams({'hizb': kursi.hizbLabel, 'page': '${kursi.page}'}),
      ),
      findsOneWidget,
    );
    expect(quran.lastRead, (2, 255, kursi.page));

    await tap(tester, 'reader-position');
    await tap(tester, 'goto-mode-2');
    await tester.ensureVisible(find.byKey(const ValueKey('goto-hizb-60')));
    await tap(tester, 'goto-hizb-60');
    final (s, a) = quran.hizbStart(60)!;
    expect(reader(s).highlightAyah.value, a);
    expect(Get.isRegistered<ReaderController>(tag: 'reader_2'), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home: Continue reading and Ayah of the Day open the reader', (
    tester,
  ) async {
    await quran.saveLastRead(2, 255, 42);
    await pump(tester, Routes.home);
    expect(
      find.text('Al-Baqarah, ${'ayahN'.trParams({'n': '255'})}'),
      findsOneWidget,
    );
    await tap(tester, 'home-continue');
    expect(reader(2).highlightAyah.value, 255);

    Get.back<void>();
    await tester.pumpAndSettle();
    final (s, a) = pickForDay(dailyAyahs, DateTime.now());
    final card = find.byKey(const ValueKey('ayah-of-day'));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(reader(s).highlightAyah.value, a);
  });

  testWidgets('a link received while Home is up opens the reader', (
    tester,
  ) async {
    await pump(tester, Routes.home);
    LinkService.instance.receive(Uri.parse('deen://quran/36/58'));
    await tester.pumpAndSettle();
    expect(reader(36).highlightAyah.value, 58);

    LinkService.instance.receive(Uri.parse('deen://quran/200/1'));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, startsWith('/reader/36'));
  });

  testWidgets('a link to the open surah scrolls that reader', (tester) async {
    await pump(tester, Routes.reader(2));
    final baqarah = reader(2);
    LinkService.instance.receive(Uri.parse('deen://quran/2/255'));
    await tester.pumpAndSettle();
    expect(identical(reader(2), baqarah), isTrue);
    expect(baqarah.highlightAyah.value, 255);
    expectOnScreen(tester, find.byKey(baqarah.ayahKey(255)));
    expect(Get.currentRoute, startsWith('/reader/2'));
    expect(tester.takeException(), isNull);
  });
}
