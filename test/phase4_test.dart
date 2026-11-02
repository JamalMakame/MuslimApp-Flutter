import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_test/flutter_test.dart';
import 'package:fquran_app/app/controllers/app_controller.dart';
import 'package:fquran_app/app/controllers/qibla_controller.dart';
import 'package:fquran_app/app/controllers/reader_controller.dart';
import 'package:fquran_app/app/data/daily_hadith.dart';
import 'package:fquran_app/app/services/azkar_service.dart';
import 'package:fquran_app/app/services/storage_service.dart';
import 'package:get/get.dart';

class _BootOnly extends AppController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory documents;

  setUpAll(() async {
    documents = await Directory.systemTemp.createTemp('deen-phase4-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => documents.path,
        );
    await StorageService.init();
  });

  tearDownAll(() async {
    Get.reset();
    await documents.delete(recursive: true);
  });

  group('Qibla calibration', () {
    test('only a known heading error of at most 30° counts', () {
      expect(QiblaController.isCalibrated(15), isTrue);
      expect(QiblaController.isCalibrated(30), isTrue);
      expect(QiblaController.isCalibrated(45), isFalse);
      expect(QiblaController.isCalibrated(null), isFalse);
      expect(QiblaController.isCalibrated(-1), isFalse);
      expect(QiblaController.isCalibrated(0), isFalse);
    });
  });

  group('Reading position', () {
    test('picks the last ayah that reached the reading line', () {
      final anchors = [(1, -400.0), (2, -50.0), (3, 120.0), (4, 600.0)];
      expect(ReaderController.ayahAtLine(anchors, 200), 3);
      expect(ReaderController.ayahAtLine(anchors, 0), 2);
    });

    test('falls back to the first ayah above the fold', () {
      expect(ReaderController.ayahAtLine([(5, 300.0), (6, 500.0)], 100), 5);
      expect(ReaderController.ayahAtLine(const [], 100), isNull);
    });
  });

  group('Daily inspiration', () {
    test('same pick all day, next item the next day, cycling', () {
      final morning = DateTime(2026, 11, 2, 0, 5);
      final night = DateTime(2026, 11, 2, 23, 55);
      expect(pickForDay(dailyHadith, morning), pickForDay(dailyHadith, night));
      final i = dayIndex(morning);
      expect(dayIndex(DateTime(2026, 11, 3)), i + 1);
      expect(
        pickForDay(dailyHadith, DateTime(2026, 11, 3)),
        dailyHadith[(i + 1) % dailyHadith.length],
      );
    });

    test('every hadith has text and a reference', () {
      expect(dailyHadith.length, greaterThanOrEqualTo(14));
      for (final h in dailyHadith) {
        expect(h.text.trim(), isNotEmpty);
        expect(h.reference.trim(), isNotEmpty);
      }
    });

    test('dua pool comes from the bundled azkar and fits the card', () async {
      await AzkarService.instance.load();
      final pool = AzkarService.instance.dailyDuaPool;
      expect(pool.length, greaterThan(30));
      expect(
        pool.every((d) => d.zekr.isNotEmpty && d.zekr.length <= 220),
        isTrue,
      );
    });
  });

  group('Splash boot', () {
    test('a failing or hanging step still lets the app open', () async {
      final app = _BootOnly();
      await app.boot({
        'ok': () async {},
        'broken': () async => throw StateError('bad asset'),
        'stuck': () => Completer<void>().future,
      }, timeout: const Duration(milliseconds: 50));
      expect(app.ready.value, isTrue);
      expect(app.bootFailures, unorderedEquals(['broken', 'stuck']));
    });
  });
}
