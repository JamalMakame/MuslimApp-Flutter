import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fquran_app/app/i18n/app_translations.dart';
import 'package:fquran_app/app/services/azkar_service.dart';
import 'package:fquran_app/app/services/hadith_service.dart';
import 'package:fquran_app/app/services/quran_service.dart';
import 'package:fquran_app/app/services/storage_service.dart';
import 'package:fquran_app/app/services/transliteration.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory documents;

  setUpAll(() async {
    documents = await Directory.systemTemp.createTemp('deen-content-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => documents.path,
        );
    await StorageService.init();
  });

  tearDownAll(() async {
    await documents.delete(recursive: true).catchError((_) => documents);
  });

  test('transliteration follows the vowel marks', () {
    expect(
      Transliteration.of('سُبْحَانَ اللَّهِ وَبِحَمْدِهِ'),
      'subhāna Allāhi wabihamdihi',
    );
    expect(
      Transliteration.of('بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ'),
      'bismi Allāhi ar-rahmani ar-rahīmi',
    );
    expect(
      Transliteration.of('أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ'),
      "astaghfiru Allāha wa'atūbu ilayhi",
    );
    expect(Transliteration.of('رَبِّ اغْفِرْ لِي'), 'rabbi aghfir lī');
    expect(Transliteration.of('وَالحَمدُ لله'), 'wal-hamdu lillāh');
  });

  test('every azkar chapter maps to a named bucket that has items', () async {
    await AzkarService.instance.load();
    final az = AzkarService.instance;
    for (final b in [
      'catHomeWudu',
      'catIstighfar',
      'catSalawat',
      'catSalam',
      'catHajj',
    ]) {
      expect(az.categories, contains(b));
      expect(az.items(b), isNotEmpty, reason: b);
    }
    final named = az.categories.where((c) => c != 'catOther');
    final total = az.categories.fold<int>(0, (n, c) => n + az.items(c).length);
    expect(
      az.items('catOther').length,
      lessThan(total ~/ 2),
      reason: 'most azkar sit in a named bucket (${named.length})',
    );
    expect(az.items('catOther').every((i) => i.category.isNotEmpty), isTrue);
  });

  test('An-Nawawi 40 Hadith bundle has 42 in Arabic and English', () async {
    final list = await HadithService.instance.load();
    expect(list.length, 42);
    expect(list.map((h) => h.number), [for (var i = 1; i <= 42; i++) i]);
    expect(
      list.every((h) => h.arabic.isNotEmpty && h.english.isNotEmpty),
      isTrue,
    );
  });

  group('offline tafsir', () {
    late Directory dir;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('tafsir');
      QuranService.documentsDirectory = () async => dir;
    });
    tearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('downloads every page of a surah into one file', () async {
      final asked = <String>[];
      final client = MockClient((r) async {
        asked.add(r.url.toString());
        final page = int.parse(r.url.queryParameters['page']!);
        return http.Response(
          jsonEncode({
            'tafsirs': [
              {'verse_key': '2:$page', 'text': '<p>Ayah $page &amp; more</p>'},
            ],
            'pagination': {'next_page': page < 2 ? page + 1 : null},
          }),
          200,
        );
      });
      final q = QuranService.instance;
      expect(await q.hasTafsirOffline(2), isFalse);
      expect(await q.downloadTafsir(2, client: client), isTrue);
      expect(asked, [
        QuranService.tafsirChapterUrl(169, 2, 1),
        QuranService.tafsirChapterUrl(169, 2, 2),
      ]);
      expect(await q.hasTafsirOffline(2), isTrue);
      expect(await q.tafsirOfflineCount(), 1);
      expect(await q.tafsir('2:2'), 'Ayah 2 & more');

      await QuranService.clearTafsirFiles();
      expect(await q.hasTafsirOffline(2), isFalse);
    });

    test(
      'a clear during a download keeps the file from being written',
      () async {
        final client = MockClient((r) async {
          await QuranService.clearTafsirFiles();
          return http.Response(
            jsonEncode({
              'tafsirs': [
                {'verse_key': '4:1', 'text': 'x'},
              ],
              'pagination': {'next_page': null},
            }),
            200,
          );
        });
        expect(
          await QuranService.instance.downloadTafsir(4, client: client),
          isFalse,
        );
        expect(await QuranService.instance.hasTafsirOffline(4), isFalse);
      },
    );

    test('a save started after a clear does not join the old one', () async {
      var calls = 0;
      final client = MockClient((r) async {
        if (++calls == 1) await QuranService.clearTafsirFiles();
        return http.Response(
          jsonEncode({
            'tafsirs': [
              {'verse_key': '6:1', 'text': 'x'},
            ],
            'pagination': {'next_page': null},
          }),
          200,
        );
      });
      final q = QuranService.instance;
      final old = q.downloadTafsir(6, client: client);
      await Future<void>.delayed(Duration.zero);
      final fresh = q.downloadTafsir(6, client: client);
      expect(await old, isFalse);
      expect(await fresh, isTrue);
      expect(await q.hasTafsirOffline(6), isTrue);
    });

    test('two saves of one surah share a single download', () async {
      var calls = 0;
      final client = MockClient((r) async {
        calls++;
        return http.Response(
          jsonEncode({
            'tafsirs': [
              {'verse_key': '5:1', 'text': 'x'},
            ],
            'pagination': {'next_page': null},
          }),
          200,
        );
      });
      final q = QuranService.instance;
      final r = await Future.wait([
        q.downloadTafsir(5, client: client),
        q.downloadTafsir(5, client: client),
      ]);
      expect(r, [true, true]);
      expect(calls, 1);
      final dir = (await QuranService.tafsirFile(169, 5)).parent;
      expect(dir.listSync().where((f) => f.path.endsWith('.part')), isEmpty);
    });

    test('a failed page saves nothing', () async {
      var calls = 0;
      final client = MockClient((r) async {
        calls++;
        if (calls > 1) return http.Response('', 500);
        return http.Response(
          jsonEncode({
            'tafsirs': [
              {'verse_key': '3:1', 'text': 'x'},
            ],
            'pagination': {'next_page': 2},
          }),
          200,
        );
      });
      expect(
        await QuranService.instance.downloadTafsir(3, client: client),
        isFalse,
      );
      expect(await QuranService.instance.hasTafsirOffline(3), isFalse);
    });
  });

  test('phase 6 strings exist in English, Arabic and Swahili', () {
    final keys = DeenTranslations().keys;
    for (final k in [
      'catHomeWudu',
      'catIstighfar',
      'catSalawat',
      'catSalam',
      'catHajj',
      'transliteration',
      'transliterationDesc',
      'hadithLibrary',
      'hadithN',
      'offlineTafsir',
      'offlineTafsirDesc',
      'tafsirDownloading',
      'downloadAll',
      'stopDownload',
      'saveTafsirOffline',
      'tafsirSavedOffline',
      'downloadFailed',
    ]) {
      for (final lang in ['en', 'ar', 'sw']) {
        expect(keys[lang]![k], isNotNull, reason: '$lang.$k');
      }
    }
  });
}
