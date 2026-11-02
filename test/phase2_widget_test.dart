import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:fquran_app/app/controllers/calendar_controller.dart';
import 'package:fquran_app/app/controllers/home_controller.dart';
import 'package:fquran_app/app/controllers/memorize_controller.dart';
import 'package:fquran_app/app/controllers/settings_controller.dart';
import 'package:fquran_app/app/i18n/app_translations.dart';
import 'package:fquran_app/app/routes/app_pages.dart';
import 'package:fquran_app/app/services/quran_service.dart';
import 'package:fquran_app/app/services/storage_service.dart';
import 'package:fquran_app/app/theme/app_theme.dart';
import 'package:fquran_app/app/ui/screens/calendar_screen.dart';
import 'package:fquran_app/app/ui/screens/home_screen.dart';
import 'package:fquran_app/app/ui/screens/memorize_screen.dart';

// The UI test never instantiates a native audio player or makes HTTP requests.
class PreviewMemorizeController extends MemorizeController {
  PreviewMemorizeController() : super(1);

  // Intentionally bypass native player setup for a widget-only test.
  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  void onClose() {}

  @override
  Future<void> goTo(int index) async {
    ayahIndex.value = index.clamp(0, ayahs.length - 1);
    await StorageService.instance.write(StorageService.kMemPosition, {
      '1': ayah.numberInSurah,
    });
  }

  @override
  Future<void> setReciter(String edition) async {
    reciter.value = edition;
    await StorageService.instance.write(StorageService.kReciter, edition);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory documents;

  Future<void> capture(WidgetTester tester, String screen) async {
    if (!const bool.fromEnvironment('DEEN_VISUAL_QA')) return;
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('phase2-qa-frame')),
      );
      final image = await boundary.toImage(pixelRatio: 2);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File('${Directory.systemTemp.path}/deen-phase2-$screen.png');
      await file.writeAsBytes(png!.buffer.asUint8List(), flush: true);
      // ignore: avoid_print
      print('Phase 2 visual QA: ${file.path}');
    });
  }

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
    final flutterRoot = File(
      Platform.resolvedExecutable,
    ).parent.parent.parent.parent.parent;
    final icons = File(
      '${flutterRoot.path}/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf',
    );
    if (await icons.exists()) {
      fonts.add(
        FontLoader('MaterialIcons')..addFont(
          icons.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        ),
      );
    }
    await Future.wait(fonts.map((font) => font.load()));
    documents = await Directory.systemTemp.createTemp('deen-ui-test-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => documents.path,
        );
    await StorageService.init();
  });

  setUp(() async {
    Get.testMode = true;
    await StorageService.instance.clearAll();
    Get.put(SettingsController(), permanent: true);
  });

  tearDown(() => Get.reset());

  tearDownAll(() async {
    await documents.delete(recursive: true).catchError((_) => documents);
  });

  Widget app(String initialRoute, List<GetPage<dynamic>> pages) =>
      RepaintBoundary(
        key: const ValueKey('phase2-qa-frame'),
        child: GetMaterialApp(
          title: 'Deen',
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
          getPages: pages,
        ),
      );

  testWidgets('Home date opens Calendar, offset and nav work without GPS', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    HomeController? home;
    try {
      await tester.pumpWidget(
        app(Routes.home, [
          GetPage(
            name: Routes.home,
            page: () => const HomeScreen(),
            binding: BindingsBuilder(() => Get.lazyPut(() => HomeController())),
          ),
          GetPage(
            name: Routes.calendar,
            page: () => const CalendarScreen(),
            binding: BindingsBuilder(
              () => Get.lazyPut(() => CalendarController()),
            ),
          ),
        ]),
      );
      await tester.pumpAndSettle();
      home = Get.find<HomeController>();
      expect(find.byKey(const ValueKey('home-calendar-link')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('home-calendar-link')));
      await tester.pumpAndSettle();
      expect(Get.currentRoute, Routes.calendar);
      expect(find.text('Umm al-Qura estimate'), findsOneWidget);
      await capture(tester, 'calendar-en');
      final controller = Get.find<CalendarController>();
      final gregorian = controller.todayGreg;
      await tester.tap(find.byTooltip('One Hijri day later'));
      await tester.pumpAndSettle();
      expect(controller.offset.value, 1);
      expect(controller.todayGreg.day, gregorian.day);

      await tester.ensureVisible(find.text('Gregorian Primary'));
      await tester.tap(find.text('Gregorian Primary'));
      await tester.pumpAndSettle();
      expect(controller.primary.value, 'gregorian');
      await tester.tap(find.byTooltip('Home'));
      await tester.pumpAndSettle();
      expect(Get.currentRoute, Routes.home);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      if (home != null && !home.isClosed) home.onClose();
      if (Get.isRegistered<HomeController>()) {
        Get.delete<HomeController>(force: true);
      }
      if (Get.isRegistered<CalendarController>()) {
        Get.delete<CalendarController>(force: true);
      }
    }
  });

  testWidgets('Calendar remains usable in Arabic and Swahili at 320px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      app(Routes.calendar, [
        GetPage(
          name: Routes.calendar,
          page: () => const CalendarScreen(),
          binding: BindingsBuilder(
            () => Get.lazyPut(() => CalendarController()),
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();
    await capture(tester, 'calendar-narrow-en');
    await Get.find<SettingsController>().setLocale('ar');
    await tester.pumpAndSettle();
    await capture(tester, 'calendar-ar');
    expect(find.text('التقويم الإسلامي'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await Get.find<SettingsController>().setLocale('sw');
    await tester.pumpAndSettle();
    expect(find.text('Kalenda ya Kiislamu'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    Get.delete<CalendarController>(force: true);
  });

  testWidgets('Hifz remains usable in English, Arabic and Swahili at 320px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.lazyPut<MemorizeController>(() => PreviewMemorizeController());
    await tester.runAsync(QuranService.instance.load);
    await tester.pumpWidget(
      app(Routes.memorize(1), [
        GetPage(name: '/memorize/:surah', page: () => const MemorizeScreen()),
      ]),
    );
    await tester.pumpAndSettle();
    expect(Get.currentRoute, Routes.memorize(1));
    expect(find.text('Memorize Al-Fatihah'), findsOneWidget);
    await capture(tester, 'hifz-en');
    await Get.find<SettingsController>().setLocale('ar');
    await tester.pumpAndSettle();
    await capture(tester, 'hifz-ar');
    expect(find.text('تحفيظ الفاتحة'), findsOneWidget);
    await tester.tap(find.byTooltip('الآية التالية'));
    await tester.pumpAndSettle();
    expect(Get.find<MemorizeController>().ayahIndex.value, 1);
    await tester.scrollUntilVisible(
      find.text('الصوتيات دون اتصال'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await Get.find<SettingsController>().setLocale('sw');
    await tester.pumpAndSettle();
    expect(find.text('SAUTI NJE YA MTANDAO'), findsOneWidget);
    expect(
      Get.find<MemorizeController>().translation,
      QuranService.instance.translation(1, 2, 'sw'),
    );
    await tester.ensureVisible(find.byTooltip('Ongeza marudio'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ongeza marudio'));
    await tester.pumpAndSettle();
    expect(Get.find<MemorizeController>().repeat.value, 6);
    expect(tester.takeException(), isNull);
  });
}
