import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fquran_app/main.dart';

Future<void> settle(
  WidgetTester tester, [
  Duration d = const Duration(seconds: 3),
]) async {
  await tester.pump(d);
  await tester.pumpAndSettle(const Duration(seconds: 2));
  debugPrint('ROUTE=${Get.currentRoute}');
}

Future<void> tapText(WidgetTester tester, String text) async {
  final f = find.text(text);
  expect(f, findsWidgets, reason: 'expected text "$text"');
  await tester.tap(f.first);
  await settle(tester);
}

Future<void> tapIcon(WidgetTester tester, IconData icon) async {
  final f = find.byIcon(icon);
  expect(f, findsWidgets, reason: 'expected icon $icon');
  await tester.tap(f.first);
  await settle(tester);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full phase-1 flow', (tester) async {
    await tester.pumpWidget(const DeenApp());
    // Splash: services init + progress animation.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // ---- Onboarding -------------------------------------------------------
    expect(find.text('Deen'), findsWidgets);
    await tapText(tester, 'English');
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await settle(tester, const Duration(seconds: 1));
    // Manual location (simulator GPS may be unset) — type a city.
    final manualBtn = find.text('Set location manually');
    if (manualBtn.evaluate().isNotEmpty) {
      await tester.tap(manualBtn);
      await settle(tester, const Duration(seconds: 1));
      await tester.enterText(find.byType(TextField).first, 'Makkah');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester, const Duration(seconds: 6));
    }
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await settle(tester, const Duration(seconds: 1));
    await tapText(tester, 'Continue');

    // ---- Home -------------------------------------------------------------
    expect(find.text('Salah Times'), findsWidgets);
    expect(find.textContaining('in '), findsWidgets); // countdown

    // Qibla via home card (lazily built — scroll until mounted+visible).
    final qiblaCard = find.text('Qibla Finder');
    await tester.scrollUntilVisible(
      qiblaCard,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settle(tester, const Duration(seconds: 1));
    await tester.tap(qiblaCard);
    await settle(tester);
    expect(find.text('Qibla Direction'), findsWidgets);
    await tapIcon(tester, Icons.arrow_back);

    // ---- Quran index ----
    await tapIcon(tester, Icons.menu_book_outlined);
    expect(find.text('Quran'), findsWidgets);
    // Search field present
    expect(find.byType(TextField), findsWidgets);
    // Open Al-Fatihah — first surah tile.
    final fatiha = find.text('Al-Fatihah');
    if (fatiha.evaluate().isEmpty) {
      await tester.tap(find.text('Al-Fatihah').first);
    } else {
      await tester.tap(fatiha.first);
    }
    await settle(tester, const Duration(seconds: 4));
    // ---- Reader -----------------------------------------------------------
    expect(find.textContaining('Al-Fatihah'), findsWidgets);
    // Scroll to translation block and tap the tafsir link.
    final tafsirLink = find.textContaining('TAFSIR');
    if (tafsirLink.evaluate().isNotEmpty) {
      await tester.ensureVisible(tafsirLink.first);
      await settle(tester, const Duration(seconds: 1));
      await tester.tap(tafsirLink.first);
      await settle(tester, const Duration(seconds: 8));
      // Sheet shows ayah + commentary; close via Done or back.
      final done = find.text('Done');
      if (done.evaluate().isNotEmpty) {
        await tester.tap(done);
        await settle(tester);
      } else {
        await tester.tapAt(const Offset(200, 60)); // tap outside sheet
        await settle(tester);
      }
    }
    await tapIcon(tester, Icons.arrow_back);
    await settle(tester);

    // ---- Azkar ------------------------------------------------------------
    await tapIcon(tester, Icons.fingerprint);
    expect(find.text('Azkar'), findsWidgets);
    // Open first category card — target the tappable tile, not the
    // featured card's static title.
    final morning = find.widgetWithText(GestureDetector, 'Morning Adhkar');
    await tester.scrollUntilVisible(
      morning,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settle(tester, const Duration(seconds: 1));
    await tester.tap(morning.first);
    await settle(tester);
    // Detail screen: tap to count.
    final countBtn = find.textContaining('TAP TO COUNT');
    if (countBtn.evaluate().isNotEmpty) {
      await tester.tap(countBtn.first);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(countBtn.first);
      await settle(tester);
    }
    await tapIcon(tester, Icons.arrow_back);
    await settle(tester);

    // Instant Dhikr → tasbeeh (lazily built — scroll until mounted).
    final dhikr = find.textContaining('INSTANT DHIKR');
    await tester.scrollUntilVisible(
      dhikr,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settle(tester, const Duration(seconds: 1));
    await tester.tap(dhikr.first);
    await settle(tester);
    expect(find.text('Tasbeeh'), findsWidgets);
    // Tap the counter dial.
    final dial = find.byType(GestureDetector);
    await tester.tap(dial.last);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(dial.last);
    await settle(tester);
    await tapIcon(tester, Icons.arrow_back);
    await settle(tester);

    // ---- Settings ----------------------------------------------------------
    await tapIcon(tester, Icons.tune);
    expect(find.text('Settings'), findsWidgets);
    // Language switch to Arabic → verify RTL, then back to English.
    final langRow = find.text('Language');
    if (langRow.evaluate().isNotEmpty) {
      await tester.tap(langRow);
      await settle(tester);
      final ar = find.text('العربية');
      if (ar.evaluate().isNotEmpty) {
        await tester.tap(ar.first);
        await settle(tester);
        expect(find.text('الإعدادات'), findsWidgets);
        await tester.tap(find.text('اللغة'));
        await settle(tester);
        await tester.tap(find.text('English'));
        await settle(tester);
        expect(find.text('Settings'), findsWidgets);
      }
    }
  });
}
