import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fquran_app/app/data/daily_ayah.dart';
import 'package:fquran_app/app/services/link_service.dart';
import 'package:fquran_app/app/services/quran_service.dart';
import 'package:fquran_app/app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory documents;
  final quran = QuranService.instance;

  setUpAll(() async {
    documents = await Directory.systemTemp.createTemp('deen-start-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => documents.path,
        );
    await StorageService.init();
    await quran.load();
  });

  tearDownAll(
    () => documents.delete(recursive: true).catchError((_) => documents),
  );

  test('ayahs keep hizb quarter, manzil, ruku and the 15 sajdas', () {
    final kursi = quran.ayahAt(2, 255)!;
    expect(kursi.juz, 3);
    expect(kursi.hizbQuarter, 17);
    expect(kursi.hizbLabel, '5');
    expect(quran.ayahAt(2, 26)!.hizbLabel, '1¼');
    expect(quran.ayahAt(5, 1)!.manzil, 2);
    expect(quran.ayahAt(2, 1)!.ruku, 2);
    final sajdas = [
      for (var s = 1; s <= 114; s++)
        for (final a in quran.ayahsFor(s))
          if (a.sajda) '$s:${a.numberInSurah}',
    ];
    expect(sajdas, hasLength(15));
    expect(sajdas.first, '7:206');
  });

  test('juz, hizb, quarter and page starts come from the bundled data', () {
    expect(quran.juzStart(1), (1, 1));
    expect(quran.juzStart(2), (2, 142));
    expect(quran.juzStart(30), (78, 1));
    expect(quran.juzStart(31), isNull);
    expect(quran.hizbStart(1), (1, 1));
    expect(quran.hizbQuarterStart(2), (2, 26));
    expect(quran.hizbStart(60), quran.hizbQuarterStart(237));
    expect(quran.hizbStart(61), isNull);
    expect(quran.pageStart(2), (2, 1));
    expect(quran.pageStart(604), (112, 1));
    expect(quran.pageStart(0), isNull);
    expect(quran.pageStart(605), isNull);
    expect(quran.ayahAt(1, 8), isNull);
    expect(quran.ayahAt(115, 1), isNull);
  });

  test('the ۞ mark falls on quarter starts, never on 1:1', () {
    expect(quran.startsHizbQuarter(quran.ayahAt(1, 1)!), isFalse);
    expect(quran.startsHizbQuarter(quran.ayahAt(2, 26)!), isTrue);
    expect(quran.startsHizbQuarter(quran.ayahAt(2, 27)!), isFalse);
    var marks = 0;
    for (var s = 1; s <= 114; s++) {
      marks += quran.ayahsFor(s).where(quran.startsHizbQuarter).length;
    }
    expect(marks, 239);
  });

  group('search shortcuts', () {
    List<String> keys(String q) =>
        quran.searchAyahs(q).map((r) => r.verseKey).toList();

    test('juz lists where each of its eight quarters starts', () {
      expect(keys('juz 2'), hasLength(8));
      expect(keys('juz 2').first, '2:142');
      expect(keys('Juz 30').first, '78:1');
      expect(keys('الجزء ٣٠').first, '78:1');
      expect(keys('juzuu 2').first, '2:142');
      expect(keys('juz 31'), isEmpty);
    });

    test('hizb lists its four quarters', () {
      expect(keys('hizb 1'), ['1:1', '2:26', '2:44', '2:60']);
      expect(keys('حزب 1'), keys('hizb 1'));
      expect(keys('hizb 61'), isEmpty);
    });

    test('page lists the ayahs on that page', () {
      expect(keys('page 1'), [for (var a = 1; a <= 7; a++) '1:$a']);
      expect(keys('ukurasa 604'), keys('page 604'));
      expect(keys('صفحة 604').first, '112:1');
      expect(keys('page 605'), isEmpty);
    });

    test('a range lists its ayahs, cut at the end of the surah', () {
      expect(keys('2:255-257'), ['2:255', '2:256', '2:257']);
      expect(keys('1:6-20'), ['1:6', '1:7']);
      expect(keys('1:8-9'), isEmpty);
      expect(keys('2:5-3'), isEmpty);
    });

    test('plain words are still text search', () {
      expect(keys('patience'), isNotEmpty);
      expect(keys('page'), isNot(contains('1:1')));
    });
  });

  group('links', () {
    (int, int)? open(String link) => LinkService.parse(Uri.parse(link), quran);

    test('surah and ayah, in both spellings', () {
      expect(open('deen://quran/2/255'), (2, 255));
      expect(open('deen://quran/2:255'), (2, 255));
      expect(open('deen://quran/36'), (36, 1));
      expect(LinkService.linkTo(18, 10).toString(), 'deen://quran/18/10');
      expect(open(LinkService.linkTo(18, 10).toString()), (18, 10));
    });

    test('juz, hizb and page', () {
      expect(open('deen://quran?juz=30'), (78, 1));
      expect(open('deen://quran?hizb=1'), (1, 1));
      expect(open('deen://quran?page=604'), (112, 1));
    });

    test('anything else is ignored', () {
      expect(open('deen://quran/1/8'), isNull);
      expect(open('deen://quran/115'), isNull);
      expect(open('deen://quran'), isNull);
      expect(open('deen://quran/1/2/3'), isNull);
      expect(open('deen://quran?juz=31'), isNull);
      expect(open('deen://azkar/1'), isNull);
      expect(open('https://quran/2/255'), isNull);
    });
  });

  test('every Ayah of the Day exists', () {
    for (final (s, a) in dailyAyahs) {
      expect(quran.ayahAt(s, a), isNotNull, reason: '$s:$a');
    }
  });
}
