import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fquran_app/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('locale switch', (tester) async {
    await tester.pumpWidget(const DeenApp());
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    debugPrint('START ROUTE=${Get.currentRoute}');
    // Skip onboarding if present.
    if (Get.currentRoute == '/onboarding') {
      final cont = find.text('Continue');
      await tester.scrollUntilVisible(
        cont,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }
    debugPrint('AFTER ROUTE=${Get.currentRoute}');

    // Settings.
    await tester.tap(find.byIcon(Icons.tune).first);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    debugPrint('ROUTE=${Get.currentRoute}');

    // Language → Arabic.
    await tester.scrollUntilVisible(
      find.text('Language'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Language'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.tap(find.text('العربية').first);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    debugPrint('AFTER-AR ROUTE=${Get.currentRoute}');
    expect(find.text('الإعدادات'), findsWidgets);
  });
}
