import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fquran_app/main.dart';

Future<void> pause(WidgetTester t, String label) async {
  for (var i = 0; i < 4; i++) {
    await t.pump(const Duration(seconds: 1));
    await t.pumpAndSettle(const Duration(milliseconds: 800));
  }
  debugPrint('SCREEN=$label ROUTE=${Get.currentRoute}');
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(seconds: 1));
  }
}

Future<void> nav(WidgetTester t, Future<void> Function() action) async {
  await action();
  for (var i = 0; i < 3; i++) {
    await t.pump(const Duration(seconds: 1));
    await t.pumpAndSettle(const Duration(milliseconds: 500));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot tour', (tester) async {
    await tester.pumpWidget(const DeenApp());
    await tester.pump(const Duration(seconds: 3));
    await pause(tester, 'splash-or-onboarding');

    if (Get.currentRoute == '/onboarding') {
      await nav(tester, () => tester.tap(find.text('English')));
      final cont = find.text('Continue');
      await tester.scrollUntilVisible(
        cont,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await pause(tester, 'onboarding-bottom');
      await nav(tester, () => tester.tap(cont));
    }
    await pause(tester, 'home');
    await nav(
      tester,
      () => tester.scrollUntilVisible(
        find.text('Qibla Finder'),
        200,
        scrollable: find.byType(Scrollable).first,
      ),
    );
    await pause(tester, 'home-scrolled');
    await nav(tester, () => tester.tap(find.text('Qibla Finder')));
    await pause(tester, 'qibla');
    await nav(
      tester,
      () => tester.tap(find.byIcon(Icons.arrow_back).first),
    );
    await nav(
      tester,
      () => tester.tap(find.byIcon(Icons.menu_book_outlined).first),
    );
    await pause(tester, 'quran-index');
    await nav(tester, () => tester.tap(find.text('Al-Fatihah').first));
    await pause(tester, 'reader');
    final tf = find.textContaining('TAFSIR');
    await tester.ensureVisible(tf.first);
    await nav(tester, () => tester.tap(tf.first));
    await pause(tester, 'tafsir-sheet');
    await nav(tester, () => tester.tapAt(const Offset(200, 40)));
    await nav(
      tester,
      () => tester.tap(find.byIcon(Icons.arrow_back).first),
    );
    await nav(
      tester,
      () => tester.tap(find.byIcon(Icons.fingerprint).first),
    );
    await pause(tester, 'azkar');
    await nav(
      tester,
      () => tester.tap(
        find.widgetWithText(GestureDetector, 'Morning Adhkar').first,
      ),
    );
    await pause(tester, 'azkar-detail');
    await nav(
      tester,
      () => tester.tap(find.byIcon(Icons.arrow_back).first),
    );
    await nav(
      tester,
      () => tester.scrollUntilVisible(
        find.textContaining('INSTANT DHIKR'),
        200,
        scrollable: find.byType(Scrollable).first,
      ),
    );
    await nav(
      tester,
      () => tester.tap(find.textContaining('INSTANT DHIKR').first),
    );
    await pause(tester, 'tasbeeh');
    await nav(
      tester,
      () => tester.tap(find.byIcon(Icons.arrow_back).first),
    );
    await nav(tester, () => tester.tap(find.byIcon(Icons.tune).first));
    await pause(tester, 'settings');
  });
}
