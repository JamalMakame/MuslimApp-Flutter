import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fquran_app/app/controllers/settings_controller.dart';
import 'package:fquran_app/app/i18n/app_translations.dart';
import 'package:fquran_app/app/routes/app_pages.dart';
import 'package:fquran_app/app/services/azkar_service.dart';
import 'package:fquran_app/app/services/quran_service.dart';
import 'package:fquran_app/app/services/storage_service.dart';
import 'package:fquran_app/app/theme/app_theme.dart';
import 'package:get/get.dart';

/// Every main screen renders on the true-black palette without errors.
/// `--dart-define=DEEN_VISUAL_QA=true` also writes a PNG per screen.
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
    documents = await Directory.systemTemp.createTemp('deen-dark-test-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => documents.path,
        );
    await StorageService.init();
    await QuranService.instance.load();
    await AzkarService.instance.load();
  });

  tearDownAll(() async {
    AppColors.isDark = false;
    await documents.delete(recursive: true).catchError((_) => documents);
  });

  const screens = {
    'home': Routes.home,
    'quran': Routes.quran,
    'reader': '/reader/2?ayah=255',
    'azkar': Routes.azkar,
    'azkar-detail': '/azkar-detail/catMorning',
    'tasbeeh': Routes.tasbeeh,
    'calendar': Routes.calendar,
    'settings': Routes.settings,
    'onboarding': Routes.onboarding,
    'habits': Routes.habits,
    'hadith': Routes.hadith,
    'mushaf': '/mushaf?page=50',
  };

  for (final MapEntry(key: name, value: route) in screens.entries) {
    testWidgets('dark: $name', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Get.testMode = true;
      await StorageService.instance.write(StorageService.kThemeMode, 'dark');
      Get.put(SettingsController(), permanent: true);
      AppColors.isDark = true;
      try {
        await tester.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('dark-frame'),
            child: GetMaterialApp(
              theme: AppTheme.current,
              locale: const Locale('en'),
              fallbackLocale: const Locale('en'),
              translations: DeenTranslations(),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'),
                Locale('ar'),
                Locale('sw'),
              ],
              initialRoute: route,
              getPages: AppPages.pages,
            ),
          ),
        );
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 300));
        }
        expect(tester.takeException(), isNull);
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
        expect(scaffold.backgroundColor, const Color(0xFF000000));
        if (const bool.fromEnvironment('DEEN_VISUAL_QA')) {
          await tester.runAsync(() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('dark-frame')),
            );
            final image = await boundary.toImage(pixelRatio: 2);
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            image.dispose();
            final file = File(
              '${Directory.systemTemp.path}/deen-dark-$name.png',
            );
            await file.writeAsBytes(png!.buffer.asUint8List(), flush: true);
          });
        }
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        Get.reset();
      }
    });
  }
}
