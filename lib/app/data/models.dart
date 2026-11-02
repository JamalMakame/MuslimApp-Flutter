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

  /// 1–240: the quarter of a hizb (rubʿ) this ayah is in; hizb is
  /// `(hizbQuarter - 1) ~/ 4 + 1`.
  final int hizbQuarter;
  final int manzil;
  final int ruku;

  const Ayah({
    required this.number,
    required this.numberInSurah,
    required this.text,
    required this.juz,
    required this.page,
    required this.sajda,
    this.hizbQuarter = 1,
    this.manzil = 1,
    this.ruku = 1,
  });

  int get hizb => (hizbQuarter - 1) ~/ 4 + 1;

  /// "3", "3¼", "3½" or "3¾" — the hizb and the quarter of it.
  String get hizbLabel =>
      '$hizb${const ['', '¼', '½', '¾'][(hizbQuarter - 1) % 4]}';

  factory Ayah.fromJson(Map<String, dynamic> j) => Ayah(
    number: j['number'],
    numberInSurah: j['numberInSurah'],
    text: (j['text'] as String).replaceAll('﻿', ''),
    juz: j['juz'],
    page: j['page'],
    sajda: j['sajda'] != null && j['sajda'] != false,
    hizbQuarter: j['hizbQuarter'] ?? 1,
    manzil: j['manzil'] ?? 1,
    ruku: j['ruku'] ?? 1,
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
  final int verseId; // global ayah number
  final String text; // uthmani
  final int surahNumber;
  final int ayahNumber;

  /// Corpus the query matched: 'ar' (Uthmani or a verse reference),
  /// 'en' (Sahih International) or 'sw' (Al-Barwani).
  final String matchLanguage;

  /// The matched translation text; null for Arabic matches.
  final String? matchedTranslation;

  const AyahSearchResult({
    required this.verseKey,
    required this.verseId,
    required this.text,
    required this.surahNumber,
    required this.ayahNumber,
    this.matchLanguage = 'ar',
    this.matchedTranslation,
  });
}

/// A bookmarked ayah with an optional note.
class AyahBookmark {
  final int surah;
  final int ayah;
  final String note;
  final DateTime created;

  const AyahBookmark({
    required this.surah,
    required this.ayah,
    this.note = '',
    required this.created,
  });

  String get verseKey => '$surah:$ayah';

  AyahBookmark withNote(String note) =>
      AyahBookmark(surah: surah, ayah: ayah, note: note, created: created);

  Map<String, dynamic> toJson() => {
    's': surah,
    'a': ayah,
    'n': note,
    't': created.millisecondsSinceEpoch,
  };

  factory AyahBookmark.fromJson(Map j) => AyahBookmark(
    surah: j['s'] as int,
    ayah: j['a'] as int,
    note: (j['n'] ?? '') as String,
    created: DateTime.fromMillisecondsSinceEpoch((j['t'] ?? 0) as int),
  );
}
