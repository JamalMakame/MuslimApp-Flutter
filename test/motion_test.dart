import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fquran_app/app/services/habit_service.dart';
import 'package:fquran_app/app/services/storage_service.dart';
import 'package:fquran_app/app/ui/widgets/celebration.dart';
import 'package:fquran_app/app/ui/widgets/motion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory documents;

  setUpAll(() async {
    documents = await Directory.systemTemp.createTemp('deen-motion-test-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => documents.path,
        );
    await StorageService.init();
    await StorageService.instance.clearAll();
  });

  tearDownAll(() async {
    await documents.delete(recursive: true).catchError((_) => documents);
  });

  testWidgets('a Rive slot without its file shows the built-in animation', (
    t,
  ) async {
    await t.pumpWidget(
      const MaterialApp(
        home: DeenRive('not_bundled', fallback: Text('fallback')),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('fallback'), findsOneWidget);
    expect(await DeenRive.load('not_bundled'), isNull);
  });

  testWidgets('staggered items fade in fully, later ones later', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Column(children: staggered([const Text('a'), const Text('b')])),
      ),
    );
    double opacity(String s) => t
        .widget<FadeTransition>(
          find
              .ancestor(of: find.text(s), matching: find.byType(FadeTransition))
              .first,
        )
        .opacity
        .value;
    await t.pump(const Duration(milliseconds: 100));
    expect(opacity('a'), greaterThan(opacity('b')));
    await t.pumpAndSettle();
    expect(opacity('a'), 1);
    expect(opacity('b'), 1);
  });

  testWidgets('Pressable shrinks while pressed', (t) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Center(
          child: Pressable(
            child: SizedBox(key: ValueKey('box'), width: 80, height: 80),
          ),
        ),
      ),
    );
    double scale() => t.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;
    final g = await t.startGesture(
      t.getCenter(find.byKey(const ValueKey('box'))),
    );
    await t.pump();
    expect(scale(), 0.96);
    await g.up();
    await t.pump();
    expect(scale(), 1);
  });

  testWidgets('celebrating without an overlay does nothing', (t) async {
    celebrate(null, 'x');
    celebrateIf(false, 'x');
    await t.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(find.byKey(const ValueKey('celebration')), findsNothing);
  });

  test('reading a page reports meeting the daily goal once', () async {
    final h = HabitService.instance;
    final now = DateTime(2026, 11, 2, 9);
    await h.setGoal(2);
    expect(await h.recordPage(10, now), isFalse);
    expect(await h.recordPage(11, now), isTrue);
    expect(await h.recordPage(11, now), isFalse);
    expect(await h.recordPage(12, now), isFalse);
    await h.setGoal(0);
    expect(await h.recordPage(13, now), isFalse);
  });
}
