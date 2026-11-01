import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../data/models.dart';
import 'storage_service.dart';

/// Bundled Quran corpus + remote extras (search, tafsir).
///
/// Offline-first: all 114 surahs' metadata, Uthmani text, and the
/// English (Sahih Intl) & Swahili (Al-Barwani) translations are bundled
/// as assets. Remote calls are only used for ayah search and tafsir.
class QuranService {
  QuranService._();
  static final QuranService instance = QuranService._();

  static const audioBase = 'https://server8.mp3quran.net/afs/';
  static const searchBase = 'https://api.quran.com/api/v4/search?q=';
  static const tafsirBase = 'https://api.quran.com/api/v4/verses/';

  final _s = StorageService.instance;

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

  // ---- Remote: ayah search -------------------------------------------------
  Future<List<AyahSearchResult>> searchAyahs(String query) async {
    if (query.trim().isEmpty) return [];
    final res = await http
        .get(Uri.parse('$searchBase${Uri.encodeComponent(query)}'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return [];
    final results = jsonDecode(res.body)['search']['results'] as List;
    return results.map((r) {
      final key = (r['verse_key'] ?? '') as String;
      final parts = key.split(':');
      return AyahSearchResult(
        verseKey: key,
        verseId: r['verse_id'] ?? 0,
        text: (r['text'] ?? '') as String,
        surahNumber: int.tryParse(parts.first) ?? 0,
        ayahNumber: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      );
    }).toList();
  }

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
