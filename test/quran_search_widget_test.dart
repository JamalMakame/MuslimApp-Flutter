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
    documents = await Directory.systemTemp.createTemp('deen-search-test-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => documents.path,
        );
    await StorageService.init();
    await QuranService.instance.load();
  });

  setUp(() async {
    Get.testMode = true;
    await StorageService.instance.clearAll();
    Get.put(SettingsController(), permanent: true);
  });

  tearDown(Get.reset);

  tearDownAll(() async {
    await documents.delete(recursive: true).catchError((_) => documents);
  });

  Future<void> pumpIndex(WidgetTester tester, String locale) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final quranPage = AppPages.pages.firstWhere((p) => p.name == Routes.quran);
    final readerPage = AppPages.pages.firstWhere(
      (p) => p.name == '/reader/:surah',
    );
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
        initialRoute: Routes.quran,
        getPages: [quranPage, readerPage],
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openAyatSegment(WidgetTester tester) async {
    await tester.tap(find.text('ayat'.tr));
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pumpAndSettle();
  }

  testWidgets('empty query, no matches and results are distinct states', (
    tester,
  ) async {
    await HttpOverrides.runZoned(() async {
      await pumpIndex(tester, 'en');
      await openAyatSegment(tester);
      expect(find.byKey(const ValueKey('ayah-search-hint')), findsOneWidget);

      await type(tester, 'qxzqxz');
      expect(find.byKey(const ValueKey('ayah-search-empty')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('ayah-search-empty')),
          matching: find.textContaining('qxzqxz'),
        ),
        findsOneWidget,
      );

      await type(tester, 'So remember Me');
      expect(find.byKey(const ValueKey('ayah-result-2:152')), findsOneWidget);
      expect(find.text('matchEn'.tr), findsWidgets);

      await type(tester, 'a');
      expect(find.byKey(const ValueKey('ayah-search-hint')), findsOneWidget);
      expect(find.byKey(const ValueKey('ayah-result-2:152')), findsNothing);
    }, createHttpClient: (_) => throw StateError('Search must not use HTTP'));
  });

  testWidgets('switching segments re-runs the current query', (tester) async {
    await pumpIndex(tester, 'en');
    await type(tester, 'Allah');
    expect(find.byKey(const ValueKey('ayah-search-results')), findsNothing);

    await openAyatSegment(tester);
    expect(find.byKey(const ValueKey('ayah-search-results')), findsOneWidget);
    expect(find.text('searchLimited'.trParams({'n': '80'})), findsOneWidget);
    expect(Get.find<QuranController>().ayahResults, hasLength(80));
  });

  for (final locale in ['en', 'ar', 'sw']) {
    testWidgets('$locale: a result opens the reader on that ayah', (
      tester,
    ) async {
      await pumpIndex(tester, locale);
      await openAyatSegment(tester);
      await type(tester, 'nikumbukeni');
      expect(find.text('matchSw'.tr), findsWidgets);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('ayah-result-2:152')));
      await tester.pumpAndSettle();

      final reader = Get.find<ReaderController>(tag: 'reader_2');
      expect(reader.highlightAyah.value, 152);
      final medallion = find.byKey(reader.ayahKey(152));
      expect(medallion, findsOneWidget);
      final y = tester.getCenter(medallion).dy;
      expect(y, inInclusiveRange(0, 812));
      expect(QuranService.instance.lastRead?.$2, 152);
      expect(tester.takeException(), isNull);
    });
  }
}
