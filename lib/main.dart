import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'app/controllers/settings_controller.dart';
import 'app/i18n/app_translations.dart';
import 'app/routes/app_pages.dart';
import 'app/services/storage_service.dart';
import 'app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(const DeenApp());
}

class DeenApp extends StatelessWidget {
  const DeenApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.put(SettingsController(), permanent: true);
    return GetMaterialApp(
      title: 'Deen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.system,
      // i18n — GetX map translations + flutter delegates.
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
