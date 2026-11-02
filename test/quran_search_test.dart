import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fquran_app/app/data/models.dart';
import 'package:fquran_app/app/services/quran_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final quran = QuranService.instance;

  List<AyahSearchResult> search(
    String query, {
    String locale = 'en',
    int limit = 80,
  }) => HttpOverrides.runZoned(
    () => quran.searchAyahs(query, locale: locale, limit: limit),
    createHttpClient: (_) => throw StateError('Search must not use HTTP'),
  );

  setUpAll(quran.load);

  test('Arabic search ignores Uthmani marks but preserves displayed text', () {
    final result = search('الحمد لله').first;
    expect(result.verseKey, '1:2');
    expect(result.matchLanguage, 'ar');
    expect(result.matchedTranslation, isNull);
    expect(result.text, quran.ayahsFor(1)[1].text);
    expect(search('اذكروني').any((r) => r.verseKey == '2:152'), isTrue);
  });

  test('English phrases match the bundled Sahih International translation', () {
    final result = search(
      'So remember Me',
    ).firstWhere((r) => r.verseKey == '2:152');
    expect(result.matchLanguage, 'en');
    expect(result.matchedTranslation, quran.translation(2, 152, 'en'));
    expect(result.text, quran.ayahsFor(2)[151].text);
  });

  test('Swahili text can be found without switching app locale', () {
    final result = search(
      'nikumbukeni',
    ).firstWhere((r) => r.verseKey == '2:152');
    expect(result.matchLanguage, 'sw');
    expect(result.matchedTranslation, quran.translation(2, 152, 'sw'));
  });

  test('results favour the active locale when both translations match', () {
    final english = search(
      'Allah',
      locale: 'en',
      limit: 6236,
    ).firstWhere((r) => r.verseKey == '6:102');
    final swahili = search(
      'Allah',
      locale: 'sw',
      limit: 6236,
    ).firstWhere((r) => r.verseKey == '6:102');
    expect(english.matchLanguage, 'en');
    expect(swahili.matchLanguage, 'sw');
    expect(english.matchedTranslation, quran.translation(6, 102, 'en'));
    expect(swahili.matchedTranslation, quran.translation(6, 102, 'sw'));
  });

  test('English and Arabic-Indic verse references resolve exactly', () {
    final result = search('٢:١٥٢');
    expect(result, hasLength(1));
    expect(result.single.verseKey, '2:152');
    expect(result.single.verseId, quran.ayahsFor(2)[151].number);
    expect(result.single.text, quran.ayahsFor(2)[151].text);
    expect(search('2:152').single.ayahNumber, 152);
    expect(search('2:999'), isEmpty);
    expect(search('999:1'), isEmpty);
  });

  test('search limits matches and never duplicates an ayah', () {
    final results = search('Allah', limit: 5);
    expect(results, hasLength(5));
    expect(results.map((r) => r.verseKey).toSet(), hasLength(5));
    expect(results.first.verseKey, '1:1');
    expect(search('Allah', limit: 0), isEmpty);
  });

  test('empty and one-character queries do not scan the corpus', () {
    expect(search('   '), isEmpty);
    expect(search('a'), isEmpty);
    expect(search('ٌ'), isEmpty);
  });
}
