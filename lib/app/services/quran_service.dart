import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../data/models.dart';
import 'storage_service.dart';

/// Bundled Quran corpus + remote extras (search, tafsir).
///
/// Offline-first: all 114 surahs' metadata, Uthmani text, and the
/// English (Sahih Intl) & Swahili (Al-Barwani) translations are bundled
/// as assets, and ayah search runs over them. Only tafsir is remote.
class QuranService {
  QuranService._();
  static final QuranService instance = QuranService._();

  static const audioBase = 'https://server8.mp3quran.net/afs/';
  static const tafsirBase = 'https://api.quran.com/api/v4/verses/';

  StorageService get _s => StorageService.instance;

  List<Surah> surahs = [];

  /// [surahIndex 0-113] -> ayah list (uthmani).
  final List<List<Ayah>> _ar = [];

  /// [surahIndex 0-113] -> ayahNumber -> translation text.
  final List<Map<int, String>> _en = [];
  final List<Map<int, String>> _sw = [];
  bool _loaded = false;
  Future<void>? _loading;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final pending = _loading ??= _load();
    try {
      await pending;
    } catch (_) {
      if (identical(_loading, pending)) {
        _loading = null;
        surahs = [];
        _ar.clear();
        _en.clear();
        _sw.clear();
        _index = null;
      }
      rethrow;
    }
  }

  Future<void> _load() async {
    final metaRaw = await rootBundle.loadString('assets/json/surahs.json');
    surahs = (jsonDecode(metaRaw)['surahs'] as List)
        .map((e) => Surah.fromJson(e))
        .toList();

    final arRaw = await rootBundle.loadString(
      'assets/json/quran_ar_uthmani.json',
    );
    final enRaw = await rootBundle.loadString(
      'assets/json/quran_en_sahih.json',
    );
    final swRaw = await rootBundle.loadString(
      'assets/json/quran_sw_barwani.json',
    );

    for (final s in (jsonDecode(arRaw)['data']['surahs'] as List)) {
      _ar.add((s['ayahs'] as List).map((a) => Ayah.fromJson(a)).toList());
    }
    for (final (raw, sink) in [(enRaw, _en), (swRaw, _sw)]) {
      final surahList = jsonDecode(raw)['data']['surahs'] as List;
      for (final s in surahList) {
        sink.add({
          for (final a in s['ayahs'] as List)
            a['numberInSurah'] as int: a['text'] as String,
        });
      }
    }
    _loaded = true;
  }

  List<Ayah> ayahsFor(int surahNumber) => _ar[surahNumber - 1];
  Surah surah(int number) => surahs[number - 1];

  /// Translation for one ayah. `lang`: 'en' | 'sw'. Arabic returns ''.
  String translation(int surahNumber, int ayahInSurah, String lang) {
    final table = lang == 'sw' ? _sw : _en;
    if (surahNumber < 1 || surahNumber > table.length) return '';
    return table[surahNumber - 1][ayahInSurah] ?? '';
  }

  /// Mishary Alafasy full-surah MP3 (afs = Alafasy on mp3quran).
  String audioUrl(int surahNumber) {
    final n = surahNumber.toString().padLeft(3, '0');
    return '$audioBase$n.mp3';
  }

  /// First ayah number (global) of a surah — for verse_key lookups.
  int firstGlobalAyah(int surahNumber) => _ar[surahNumber - 1].first.number;

  // ---- Per-ayah audio + offline download -----------------------------------
  /// Per-ayah reciters served by the islamic.network CDN.
  /// Key = edition id; `name` is a stable display label.
  static const reciters = <String, String>{
    'ar.alafasy': 'Mishary Alafasy',
    'ar.abdulbasitmurattal': 'Abdul Basit',
    'ar.husary': 'Al-Husary',
    'ar.minshawi': 'Al-Minshawi',
  };

  /// Per-ayah MP3 URL on the islamic.network CDN.
  String ayahAudioUrl(String edition, int globalAyah) =>
      'https://cdn.islamic.network/quran/audio/128/$edition/$globalAyah.mp3';

  /// Global ayah numbers of one surah (for download iteration).
  List<int> globalAyahs(int surahNumber) =>
      _ar[surahNumber - 1].map((a) => a.number).toList();

  /// Download manifest: {edition: {surahNumber: totalBytes}}.
  Map<String, Map<String, int>> get downloadedAudio =>
      ((_s.read<Map>(StorageService.kDownloadedAudio)) ?? {}).map(
        (k, v) => MapEntry(
          k.toString(),
          (v as Map).map((k2, v2) => MapEntry(k2.toString(), v2 as int)),
        ),
      );

  Future<void> markDownloaded(String edition, int surah, int bytes) async {
    final m = downloadedAudio;
    m.putIfAbsent(edition, () => {})[surah.toString()] = bytes;
    await _s.write(StorageService.kDownloadedAudio, m);
  }

  Future<void> unmarkDownloaded(String edition, int surah) async {
    final m = downloadedAudio;
    m[edition]?.remove(surah.toString());
    if (m[edition]?.isEmpty ?? false) m.remove(edition);
    await _s.write(StorageService.kDownloadedAudio, m);
  }

  bool isDownloaded(String edition, int surah) =>
      downloadedAudio[edition]?[surah.toString()] != null;

  int? downloadedBytes(String edition, int surah) =>
      downloadedAudio[edition]?[surah.toString()];

  // ---- Last-read + bookmarks (storage) ------------------------------------
  (int surah, int ayah, int page)? get lastRead {
    final s = _s.readInt(StorageService.kLastReadSurah);
    if (s == 0) return null;
    return (
      s,
      _s.readInt(StorageService.kLastReadAyah),
      _s.readInt(StorageService.kLastReadPage),
    );
  }

  Future<void> saveLastRead(int surah, int ayah, int page) async {
    await _s.write(StorageService.kLastReadSurah, surah);
    await _s.write(StorageService.kLastReadAyah, ayah);
    await _s.write(StorageService.kLastReadPage, page);
  }

  Set<int> get bookmarks => ((_s.read<List>(StorageService.kBookmarks)) ?? [])
      .whereType<int>()
      .toSet();

  Future<void> toggleBookmark(int surahNumber) async {
    final b = bookmarks;
    b.contains(surahNumber) ? b.remove(surahNumber) : b.add(surahNumber);
    await _s.write(StorageService.kBookmarks, b.toList());
  }

  // ---- Offline ayah search -------------------------------------------------
  static const defaultSearchLimit = 80;

  static final _arabicMarks = RegExp(
    '[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]',
  );
  static final _arabicLetter = RegExp('[\u0621-\u064A\u0671-\u06D3]');
  static final _nonWord = RegExp(r'[^\p{L}\p{N}]+', unicode: true);
  static final _verseRef = RegExp(r'^(\d{1,3})\s*[:.]\s*(\d{1,3})$');

  List<_SearchRow>? _index;

  /// Folds Uthmani orthography onto plain Arabic: drops harakat, Quranic
  /// annotation marks and tatweel, and unifies alef/ya/ta-marbuta forms.
  static String normalizeArabic(String s) => s
      .replaceAll(_arabicMarks, '')
      .replaceAll(RegExp('[\u0671\u0622\u0623\u0625]'), '\u0627')
      .replaceAll('\u0649', '\u064A')
      .replaceAll('\u0626', '\u064A')
      .replaceAll('\u0624', '\u0648')
      .replaceAll('\u0629', '\u0647')
      .replaceAll(_nonWord, ' ')
      .trim();

  /// Uthmani spells many long-a vowels with a dagger alef (stripped above),
  /// so a second, alef-free form lets "العالمين" find "ٱلْعَٰلَمِينَ".
  static String _arabicSkeleton(String normalized) =>
      normalized.replaceAll('\u0627', '');

  static String normalizeLatin(String s) =>
      s.toLowerCase().replaceAll(_nonWord, ' ').trim();

  static String _westernDigits(String s) => s.replaceAllMapped(
    RegExp('[\u0660-\u0669\u06F0-\u06F9]'),
    (m) => '${m[0]!.codeUnitAt(0) & 0xF}',
  );

  List<_SearchRow> get _searchIndex => _index ??= [
    for (var si = 0; si < _ar.length; si++)
      for (final a in _ar[si])
        () {
          final ar = normalizeArabic(a.text);
          return _SearchRow(
            surah: si + 1,
            ayah: a,
            ar: ar,
            arSkeleton: _arabicSkeleton(ar),
            en: normalizeLatin(_en[si][a.numberInSurah] ?? ''),
            sw: normalizeLatin(_sw[si][a.numberInSurah] ?? ''),
          );
        }(),
  ];

  /// Searches the bundled corpus — no network. Arabic queries match the
  /// Uthmani text ignoring diacritics; other queries match the English and
  /// Swahili translations, preferring [locale]'s translation when both
  /// match. "2:255" (Western or Arabic-Indic digits) opens one ayah.
  /// Results are in mushaf order, one per ayah, at most [limit].
  List<AyahSearchResult> searchAyahs(
    String query, {
    String locale = 'en',
    int limit = defaultSearchLimit,
  }) {
    if (!_loaded || limit <= 0) return [];
    final trimmed = query.trim();

    final ref = _verseRef.firstMatch(_westernDigits(trimmed));
    if (ref != null) {
      final s = int.parse(ref[1]!);
      final a = int.parse(ref[2]!);
      if (s < 1 || s > _ar.length || a < 1 || a > _ar[s - 1].length) {
        return [];
      }
      return [_result(s, _ar[s - 1][a - 1], 'ar')];
    }

    final out = <AyahSearchResult>[];
    if (_arabicLetter.hasMatch(trimmed)) {
      final q = normalizeArabic(trimmed);
      if (q.length < 2) return [];
      final skeleton = _arabicSkeleton(q);
      for (final row in _searchIndex) {
        if (row.ar.contains(q) ||
            (skeleton.length >= 2 && row.arSkeleton.contains(skeleton))) {
          out.add(_result(row.surah, row.ayah, 'ar'));
          if (out.length >= limit) break;
        }
      }
      return out;
    }

    final q = normalizeLatin(trimmed);
    if (q.length < 2) return [];
    final order = locale == 'sw' ? const ['sw', 'en'] : const ['en', 'sw'];
    for (final row in _searchIndex) {
      for (final lang in order) {
        if ((lang == 'sw' ? row.sw : row.en).contains(q)) {
          out.add(_result(row.surah, row.ayah, lang));
          break;
        }
      }
      if (out.length >= limit) break;
    }
    return out;
  }

  AyahSearchResult _result(int surah, Ayah a, String lang) => AyahSearchResult(
    verseKey: '$surah:${a.numberInSurah}',
    verseId: a.number,
    text: a.text,
    surahNumber: surah,
    ayahNumber: a.numberInSurah,
    matchLanguage: lang,
    matchedTranslation: lang == 'ar'
        ? null
        : translation(surah, a.numberInSurah, lang),
  );

  // ---- Remote: tafsir (cached locally once fetched) ------------------------
  Future<String?> tafsir(String verseKey) async {
    final cache = (_s.read<Map>(StorageService.kTafsirCache) ?? {})
        .cast<String, String>();
    if (cache.containsKey(verseKey)) return cache[verseKey];

    try {
      final res = await http
          .get(Uri.parse('$tafsirBase$verseKey/tafsirs'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final list = jsonDecode(res.body)['tafsirs'] as List;
      if (list.isEmpty) return null;
      final text = (list.first['text'] ?? '') as String;
      // Strip light HTML formatting.
      final cleaned = text
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll('&amp;', '&')
          .trim();
      cache[verseKey] = cleaned;
      await _s.write(StorageService.kTafsirCache, cache);
      return cleaned;
    } catch (_) {
      return null;
    }
  }
}

class _SearchRow {
  const _SearchRow({
    required this.surah,
    required this.ayah,
    required this.ar,
    required this.arSkeleton,
    required this.en,
    required this.sw,
  });

  final int surah;
  final Ayah ayah;
  final String ar;
  final String arSkeleton;
  final String en;
  final String sw;
}
