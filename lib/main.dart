import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'app/controllers/settings_controller.dart';
import 'app/i18n/app_translations.dart';
import 'app/routes/app_pages.dart';
import 'app/services/link_service.dart';
import 'app/services/storage_service.dart';
import 'app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  LinkService.instance.init();
  runApp(const DeenApp());
}

class DeenApp extends StatefulWidget {
  const DeenApp({super.key});

  @override
  State<DeenApp> createState() => _DeenAppState();
}

class _DeenAppState extends State<DeenApp> with WidgetsBindingObserver {
  final settings = Get.put(SettingsController(), permanent: true);
  late final Worker _themeWorker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncPalette();
    _themeWorker = ever(settings.themeMode, (_) => _restyle());
  }

  @override
  void dispose() {
    _themeWorker.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    if (settings.themeMode.value == 'system') _restyle();
  }

  bool _syncPalette() {
    final dark = switch (settings.themeMode.value) {
      'dark' => true,
      'light' => false,
      _ =>
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark,
    };
    final changed = dark != AppColors.isDark;
    AppColors.isDark = dark;
    return changed;
  }

  /// Screens read [AppColors] directly, so a palette change rebuilds them all.
  void _restyle() {
    if (!_syncPalette() || !mounted) return;
    setState(() {});
    Get.forceAppUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Deen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.current,
      themeMode: ThemeMode.light,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppColors.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: child ?? const SizedBox.shrink(),
      ),
      translations: DeenTranslations(),
      locale: settings.locale,
      fallbackLocale: const Locale('en'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar'), Locale('sw')],
      initialRoute: Routes.splash,
      initialBinding: AppBinding(),
      getPages: AppPages.pages,
    );
  }
}
