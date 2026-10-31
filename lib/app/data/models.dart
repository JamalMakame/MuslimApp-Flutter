// Plain data models for Deen — bundled Quran, azkar, tasbeeh.

class Surah {
  final int number;
  final String nameArabic;
  final String nameOrnate;
  final String nameSimple;
  final String nameTranslated;
  final int ayahs;
  final String revelation; // 'makki' | 'madani'
  final int revelationOrder;
  final int pageStart;
  final int pageEnd;
  final int juzStart;
  final bool bismillahPre;

  const Surah({
    required this.number,
    required this.nameArabic,
    required this.nameOrnate,
    required this.nameSimple,
    required this.nameTranslated,
    required this.ayahs,
    required this.revelation,
    required this.revelationOrder,
    required this.pageStart,
    required this.pageEnd,
    required this.juzStart,
    required this.bismillahPre,
  });

  factory Surah.fromJson(Map<String, dynamic> j) => Surah(
    number: j['number'],
    nameArabic: j['nameArabic'],
    nameOrnate: j['nameOrnate'],
    nameSimple: j['nameSimple'],
    nameTranslated: j['nameTranslated'],
    ayahs: j['ayahs'],
    revelation: j['revelation'],
    revelationOrder: j['revelationOrder'],
    pageStart: j['pages'][0],
    pageEnd: j['pages'][1],
    juzStart: j['juzStart'],
    bismillahPre: j['bismillahPre'],
  );
}

class Ayah {
  final int number; // global ayah number
  final int numberInSurah;
  final String text; // uthmani
  final int juz;
  final int page;
  final bool sajda;

  const Ayah({
    required this.number,
    required this.numberInSurah,
    required this.text,
    required this.juz,
    required this.page,
    required this.sajda,
  });

  factory Ayah.fromJson(Map<String, dynamic> j) => Ayah(
    number: j['number'],
    numberInSurah: j['numberInSurah'],
    text: (j['text'] as String).replaceAll('﻿', ''),
    juz: j['juz'],
    page: j['page'],
    sajda: j['sajda'] == true,
  );
}

class AzkarCategory {
  /// Key used for i18n display name + icon.
  final String key;

  /// Category names inside bundled azkar.json (Arabic, as stored).
  final List<String> sourceTitles;

  const AzkarCategory({required this.key, required this.sourceTitles});
}

class DhikrItem {
  final int id;
  final String zekr;
  final String reference;
  final String description;
  final int count;

  const DhikrItem({
    required this.id,
    required this.zekr,
    required this.reference,
    required this.description,
    required this.count,
  });

  factory DhikrItem.fromJson(Map<String, dynamic> j) => DhikrItem(
    id: j['Id'] ?? 0,
    zekr: (j['zekr'] ?? '').toString(),
    reference: (j['reference'] ?? '').toString(),
    description: j['description'] is Map
        ? ((j['description']['text'] ??
                  (j['description'] as Map).values.whereType<String>().join(
                    ' ',
                  ))
              .toString())
        : (j['description'] ?? '').toString(),
    count: int.tryParse((j['count'] ?? '1').toString().trim()) ?? 1,
  );
}

class TasbeehPhrase {
  final String key; // i18n key for display name
  final String arabic;
  final String transliteration;
  final String meaningKey;

  const TasbeehPhrase({
    required this.key,
    required this.arabic,
    required this.transliteration,
    required this.meaningKey,
  });
}

class AyahSearchResult {
  final String verseKey; // "2:152"
  final int verseId;
  final String text;
  final int surahNumber;
  final int ayahNumber;

  const AyahSearchResult({
    required this.verseKey,
    required this.verseId,
    required this.text,
    required this.surahNumber,
    required this.ayahNumber,
  });
}
