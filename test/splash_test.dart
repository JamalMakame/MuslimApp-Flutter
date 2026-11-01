import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart'
    show FontLoader, MethodChannel, rootBundle, SystemUiOverlayStyle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:fquran_app/app/controllers/app_controller.dart';
import 'package:fquran_app/app/i18n/app_translations.dart';
import 'package:fquran_app/app/routes/app_pages.dart';
import 'package:fquran_app/app/services/storage_service.dart';
import 'package:fquran_app/app/theme/app_theme.dart';
import 'package:fquran_app/app/ui/screens/splash_screen.dart';

class _PreviewAppController extends AppController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory documents;

  Future<void> capture(WidgetTester tester, String language) async {
    if (!const bool.fromEnvironment('DEEN_VISUAL_QA')) return;
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('splash-qa-frame')),
      );
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File(
        '${Directory.systemTemp.path}/deen-splash-$language.png',
      );
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
      // ignore: avoid_print
      print('Splash visual QA: ${file.path}');
    });
  }

  setUpAll(() async {
    await Future.wait([
      (FontLoader(AppFonts.headline)
            ..addFont(
              rootBundle.load('assets/fonts/PlusJakartaSans-Regular.ttf'),
            )
            ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Bold.ttf')))
          .load(),
      (FontLoader(
        AppFonts.body,
      )..addFont(rootBundle.load('assets/fonts/Manrope-Regular.ttf'))).load(),
      (FontLoader(
        AppFonts.quran,
      )..addFont(rootBundle.load('assets/fonts/Amiri-Regular.ttf'))).load(),
    ]);
    documents = await Directory.systemTemp.createTemp('deen-splash-test-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => documents.path,
        );
    await StorageService.init();
    Get.testMode = true;
  });

  setUp(() async => StorageService.instance.clearAll());
  tearDown(Get.reset);
  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    await documents.delete(recursive: true);
  });

  Widget app(String language) => RepaintBoundary(
    key: const ValueKey('splash-qa-frame'),
    child: GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      translations: DeenTranslations(),
      locale: Locale(language),
      fallbackLocale: const Locale('en'),
      initialRoute: Routes.splash,
      getPages: [
        GetPage(name: Routes.splash, page: () => const SplashScreen()),
        GetPage(
          name: Routes.home,
          page: () => const Scaffold(body: Text('Home destination')),
        ),
        GetPage(
          name: Routes.onboarding,
          page: () => const Scaffold(body: Text('Onboarding destination')),
        ),
      ],
    ),
  );

  test('iOS launch uses a branded background and real image assets', () async {
    final storyboard = await File(
      'ios/Runner/Base.lproj/LaunchScreen.storyboard',
    ).readAsString();
    final mainStoryboard = await File(
      'ios/Runner/Base.lproj/Main.storyboard',
    ).readAsString();
    const launchGreen =
        'red="0.0431372549" green="0.3294117647" blue="0.2823529412"';
    expect(storyboard, contains('image="LaunchImage"'));
    expect(storyboard, contains('text="Deen"'));
    expect(storyboard, contains('statusBarStyle="lightContent"'));
    expect(storyboard, contains(launchGreen));
    expect(mainStoryboard, contains(launchGreen));
    for (final (name, minimumWidth) in [
      ('LaunchImage.png', 200),
      ('LaunchImage@2x.png', 400),
      ('LaunchImage@3x.png', 600),
    ]) {
      final bytes = await File(
        'ios/Runner/Assets.xcassets/LaunchImage.imageset/$name',
      ).readAsBytes();
      expect(bytes.length, greaterThan(512));
      final header = ByteData.sublistView(bytes);
      expect(header.getUint32(16), greaterThanOrEqualTo(minimumWidth));
      expect(header.getUint32(20), greaterThanOrEqualTo(minimumWidth));
    }
  });

  testWidgets('splash waits for readiness and then opens onboarding', (
    tester,
  ) async {
    final controller = Get.put<AppController>(
      _PreviewAppController(),
      permanent: true,
    );
    await tester.pumpWidget(app('en'));
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Deen'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/images/deen_dome.png')),
      findsOneWidget,
    );
    final overlay = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
    );
    expect(overlay.value, SystemUiOverlayStyle.light);
    controller.ready.value = true;
    await tester.pumpAndSettle();
    expect(Get.currentRoute, Routes.onboarding);
  });

  testWidgets('already-ready returning users open home', (tester) async {
    await StorageService.instance.write(StorageService.kOnboarded, true);
    Get.put<AppController>(
      _PreviewAppController()..ready.value = true,
      permanent: true,
    );
    await tester.pumpWidget(app('en'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, Routes.home);
  });

  testWidgets('leaving the splash cancels its readiness navigation', (
    tester,
  ) async {
    final controller = Get.put<AppController>(
      _PreviewAppController(),
      permanent: true,
    );
    await tester.pumpWidget(app('en'));
    await tester.pump(const Duration(seconds: 3));
    Get.offAllNamed(Routes.onboarding);
    await tester.pumpAndSettle();
    controller.ready.value = true;
    await tester.pump();
    expect(Get.currentRoute, Routes.onboarding);
  });

  testWidgets('English splash fits the approved phone canvas', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.put<AppController>(_PreviewAppController(), permanent: true);
    await tester.pumpWidget(app('en'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      tester.getSize(find.byKey(const ValueKey('splash-background'))),
      const Size(393, 852),
    );
    expect(
      tester
          .getCenter(
            find.image(const AssetImage('assets/images/deen_dome.png')),
          )
          .dx,
      closeTo(393 / 2, 1),
    );
    expect(tester.takeException(), isNull);
    await capture(tester, 'en');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final language in ['en', 'ar', 'sw']) {
    testWidgets('$language splash fits a narrow phone', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Get.put<AppController>(_PreviewAppController(), permanent: true);
      await tester.pumpWidget(app(language));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('splash-background'))),
        const Size(320, 568),
      );
      expect(
        tester
            .getCenter(
              find.image(const AssetImage('assets/images/deen_dome.png')),
            )
            .dx,
        closeTo(320 / 2, 1),
      );
      expect(tester.takeException(), isNull);
      await capture(tester, '$language-narrow');
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
