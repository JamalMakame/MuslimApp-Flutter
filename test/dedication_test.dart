import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fquran_app/app/i18n/app_translations.dart';
import 'package:fquran_app/app/ui/screens/dedication_screen.dart';
import 'package:get/get.dart';

void main() {
  for (final lang in ['en', 'ar', 'sw']) {
    testWidgets('$lang dedication names everyone on a narrow phone', (t) async {
      t.view.physicalSize = const Size(360, 3000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        GetMaterialApp(
          translations: DeenTranslations(),
          locale: Locale(lang),
          home: const DedicationScreen(),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      for (final name in [
        'Jamal Makame',
        DedicationScreen.father,
        ...DedicationScreen.mothers,
        DedicationScreen.wife,
      ]) {
        expect(find.textContaining(name), findsWidgets, reason: name);
      }
      expect(find.text('dedicationThawab'.tr), findsOneWidget);
    });
  }
}
