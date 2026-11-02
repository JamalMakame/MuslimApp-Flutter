import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../data/models.dart';
import 'storage_service.dart';

/// Bundled Quran corpus + remote extras (tafsir, recitation audio).
///
/// Offline-first: all 114 surahs' metadata, Uthmani text, and the
/// English (Sahih Intl) & Swahili (Al-Barwani) translations are bundled
/// as assets, and ayah search runs over them. Only tafsir is remote.
class QuranService {
  QuranService._();
  static final QuranService instance = QuranService._();

  static const audioBase = 'https://server8.mp3quran.net/afs/';
  static const tafsirBase = 'https://api.quran.com/api/v4/tafsirs/';

  /// quran.com tafsir resources: Ibn Kathir in Arabic (14) and the
  /// abridged English edition (169). Swahili readers get the English one.
  static int tafsirEdition(String lang) => lang == 'ar' ? 14 : 169;

  static String tafsirUrl(String verseKey, {String lang = 'en'}) =>
      '$tafsirBase${tafsirEdition(lang)}/by_ayah/$verseKey';

  /// Plain text of a quran.com `by_ayah` response; null when it has none.
  static String? parseTafsir(String body) {
    final tafsir = (jsonDecode(body) as Map)['tafsir'];
    final html = tafsir is Map ? tafsir['text'] as String? : null;
    return html == null ? null : tafsirText(html);
  }

  static String tafsirChapterUrl(int edition, int surah, int page) =>
      '$tafsirBase$edition/by_chapter/$surah?per_page=50&page=$page';

  /// Directory for downloaded tafsir; replaceable in tests.
  static Future<Directory> Function() documentsDirectory =
      getApplicationDocumentsDirectory;

  static Future<File> tafsirFile(int edition, int surah) async =>
      File('${(await documentsDirectory()).path}/tafsir/$edition/$surah.json');

  /// Bumped by [clearTafsirFiles]; a download started before a clear
  /// never writes its file.
  static int tafsirGeneration = 0;

  static Future<void> clearTafsirFiles() async {
    tafsirGeneration++;
    final dir = Directory('${(await documentsDirectory()).path}/tafsir');
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<bool> hasTafsirOffline(int surah, {String lang = 'en'}) async =>
      (await tafsirFile(tafsirEdition(lang), surah)).exists();

  Future<int> tafsirOfflineCount({String lang = 'en'}) async {
    var n = 0;
    for (var s = 1; s <= 114; s++) {
      if (await hasTafsirOffline(s, lang: lang)) n++;
    }
    return n;
  }

  /// Saves a whole surah's tafsir (quran.com `by_chapter`, 50 per page) to a
  /// file, written only once every ayah is in. Returns false on failure.
  Future<bool> downloadTafsir(
    int surah, {
    String lang = 'en',
    http.Client? client,
  }) {
    final key = '$tafsirGeneration:${tafsirEdition(lang)}:$surah';
    return _tafsirSaves[key] ??= _downloadTafsir(surah, lang, client)
        .whenComplete(() {
          _tafsirSaves.remove(key);
        });
  }

  /// One save per edition:surah at a time; a second caller shares it.
  /// Keyed by generation too, so a save after a clear starts fresh.
  static final _tafsirSaves = <String, Future<bool>>{};

  Future<bool> _downloadTafsir(
    int surah,
    String lang,
    http.Client? client,
  ) async {
    final edition = tafsirEdition(lang);
    final generation = tafsirGeneration;
    final get = client?.get ?? http.get;
    final out = <String, String>{};
    try {
      for (var page = 1; page <= 20; page++) {
        final res = await get(
          Uri.parse(tafsirChapterUrl(edition, surah, page)),
        ).timeout(const Duration(seconds: 20));
        if (res.statusCode != 200) return false;
        final body = jsonDecode(res.body) as Map;
        for (final t in (body['tafsirs'] as List? ?? const [])) {
          final key = t['verse_key'] as String?;
          final html = t['text'] as String?;
          final text = html == null ? null : tafsirText(html);
          if (key != null && text != null) out[key] = text;
        }
        final next = (body['pagination'] as Map?)?['next_page'];
        if (next == null) break;
      }
    } catch (_) {
      return false;
    }
    if (out.isEmpty || generation != tafsirGeneration) return false;
    File? tmp;
    try {
      final file = await tafsirFile(edition, surah);
      await file.parent.create(recursive: true);
      tmp = File('${file.path}.${DateTime.now().microsecondsSinceEpoch}.part');
      await tmp.writeAsString(jsonEncode(out), flush: true);
      if (generation != tafsirGeneration) throw StateError('cleared');
      await tmp.rename(file.path);
      return true;
    } catch (_) {
      try {
        if (tmp != null && await tmp.exists()) await tmp.delete();
      } catch (_) {}
      return false;
    }
  }

  Future<String?> _offlineTafsir(String verseKey, int edition) async {
    final surah = int.tryParse(verseKey.split(':').first);
    if (surah == null) return null;
    try {
      final file = await tafsirFile(edition, surah);
      if (!await file.exists()) return null;
      final map = jsonDecode(await file.readAsString()) as Map;
      return map[verseKey] as String?;
    } catch (_) {
      return null;
    }
  }

  static String? tafsirText(String html) {
    final text = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(
          RegExp(r'</(p|h[1-6]|div|li)>', caseSensitive: false),
          '\n\n',
        )
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    return text.isEmpty ? null : text;
  }

  StorageService get _s => StorageService.instance;

  List<Surah> surahs = [];

  /// [surahIndex 0-113] -> ayah list (uthmani).
  final List<List<Ayah>> _ar = [];

  /// [surahIndex 0-113] -> ayahNumber -> translation text.
  final List<Map<int, String>> _en = [];
  final List<Map<int, String>> _sw = [];
  bool _loaded = false;
  Future<void>? _loading;

  static const juzCount = 30;
  static const hizbCount = 60;
  static const pageCount = 604;

  /// First (surah, ayah) of each juz / hizb quarter / mushaf page, in order.
  final List<(int, int)> _juzStarts = [];
  final List<(int, int)> _quarterStarts = [];
  final List<(int, int)> _pageStarts = [];
  final Set<int> _quarterStartGlobals = {};

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
        _juzStarts.clear();
        _quarterStarts.clear();
        _pageStarts.clear();
        _quarterStartGlobals.clear();
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
    _buildDivisions();
    _loaded = true;
  }

  void _buildDivisions() {
    Ayah? prev;
    for (var si = 0; si < _ar.length; si++) {
      for (final a in _ar[si]) {
        final at = (si + 1, a.numberInSurah);
        if (prev == null || a.juz != prev.juz) _juzStarts.add(at);
        if (prev == null || a.hizbQuarter != prev.hizbQuarter) {
          _quarterStarts.add(at);
          _quarterStartGlobals.add(a.number);
        }
        if (prev == null || a.page != prev.page) _pageStarts.add(at);
        prev = a;
      }
    }
  }

  /// Where juz [n] (1–30) starts; null when out of range.
  (int surah, int ayah)? juzStart(int n) => _at(_juzStarts, n);

  /// Where hizb [n] (1–60) starts.
  (int surah, int ayah)? hizbStart(int n) => _at(_quarterStarts, n * 4 - 3);

  /// Where hizb quarter [n] (1–240) starts.
  (int surah, int ayah)? hizbQuarterStart(int n) => _at(_quarterStarts, n);

  /// Where mushaf page [n] (1–604) starts.
  (int surah, int ayah)? pageStart(int n) => _at(_pageStarts, n);

  /// Every (surah, ayah) on mushaf page [n], in order.
  List<(int, Ayah)> ayahsOnPage(int n) {
    final start = pageStart(n);
    if (start == null) return const [];
    final out = <(int, Ayah)>[];
    for (var s = start.$1; s <= _ar.length; s++) {
      final list = _ar[s - 1];
      for (var i = s == start.$1 ? start.$2 - 1 : 0; i < list.length; i++) {
        if (list[i].page != n) return out;
        out.add((s, list[i]));
      }
    }
    return out;
  }

  static (int, int)? _at(List<(int, int)> starts, int n) =>
      n >= 1 && n <= starts.length ? starts[n - 1] : null;

  /// The ayah at [surah]:[ayah]; null when either is out of range.
  Ayah? ayahAt(int surah, int ayah) {
    if (surah < 1 || surah > _ar.length) return null;
    final list = _ar[surah - 1];
    return ayah >= 1 && ayah <= list.length ? list[ayah - 1] : null;
  }

  /// True when [a] opens a hizb quarter (the mushaf's ۞ mark), except 1:1.
  bool startsHizbQuarter(Ayah a) =>
      a.number != 1 && _quarterStartGlobals.contains(a.number);

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

  /// Bitrates the CDN actually serves per edition (Abdul Basit has no 128).
  static const _reciterBitrate = <String, int>{'ar.abdulbasitmurattal': 192};

  /// Per-ayah MP3 URL on the islamic.network CDN.
  String ayahAudioUrl(String edition, int globalAyah) =>
      'https://cdn.islamic.network/quran/audio/'
      '${_reciterBitrate[edition] ?? 128}/$edition/$globalAyah.mp3';

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

  /// [lastRead], kept current so Home and the index follow the reader.
  Rxn<(int, int, int)> get lastReadRx => _lastReadRx ??= Rxn(lastRead);
  Rxn<(int, int, int)>? _lastReadRx;

  Future<void> saveLastRead(int surah, int ayah, int page) async {
    lastReadRx.value = (surah, ayah, page);
    await _s.write(StorageService.kLastReadSurah, surah);
    await _s.write(StorageService.kLastReadAyah, ayah);
    await _s.write(StorageService.kLastReadPage, page);
  }

  /// Ayah bookmarks, newest first. Surah bookmarks from older versions
  /// become bookmarks on that surah's first ayah.
  RxList<AyahBookmark> get bookmarksRx =>
      _bookmarksRx ??= RxList(_readBookmarks());
  RxList<AyahBookmark>? _bookmarksRx;

  List<AyahBookmark> _readBookmarks() {
    final stored = _s.read<List>(StorageService.kAyahBookmarks);
    if (stored != null) {
      return [
        for (final m in stored.whereType<Map>()) AyahBookmark.fromJson(m),
      ];
    }
    final legacy = (_s.read<List>(StorageService.kBookmarks) ?? [])
        .whereType<int>()
        .where((s) => s >= 1 && s <= 114)
        .toSet();
    final now = DateTime.now();
    final migrated = [
      for (final s in legacy) AyahBookmark(surah: s, ayah: 1, created: now),
    ];
    if (legacy.isNotEmpty) {
      _s.write(StorageService.kAyahBookmarks, [
        for (final b in migrated) b.toJson(),
      ]);
      _s.remove(StorageService.kBookmarks);
    }
    return migrated;
  }

  AyahBookmark? bookmarkAt(int surah, int ayah) =>
      bookmarksRx.firstWhereOrNull((b) => b.surah == surah && b.ayah == ayah);

  /// Surahs that have at least one bookmarked ayah.
  Set<int> get bookmarkedSurahs => {for (final b in bookmarksRx) b.surah};

  /// Adds the bookmark, or updates its note when it exists.
  Future<void> saveBookmark(int surah, int ayah, {String? note}) async {
    final old = bookmarkAt(surah, ayah);
    final b = old == null
        ? AyahBookmark(
            surah: surah,
            ayah: ayah,
            note: note ?? '',
            created: DateTime.now(),
          )
        : old.withNote(note ?? old.note);
    final at = old == null ? -1 : bookmarksRx.indexOf(old);
    // A new bookmark goes first; a note edit keeps its place.
    at < 0 ? bookmarksRx.insert(0, b) : bookmarksRx[at] = b;
    await _writeBookmarks();
  }

  Future<void> removeBookmark(int surah, int ayah) async {
    bookmarksRx.removeWhere((b) => b.surah == surah && b.ayah == ayah);
    await _writeBookmarks();
  }

  Future<void> _writeBookmarks() => _s.write(StorageService.kAyahBookmarks, [
    for (final b in bookmarksRx) b.toJson(),
  ]);

  /// Forgets cached user state after Settings → clear local data.
  void resetUserState() {
    _lastReadRx = null;
    _bookmarksRx = null;
  }

  // ---- Offline ayah search -------------------------------------------------
  static const defaultSearchLimit = 80;

  static final _arabicMarks = RegExp(
    '[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]',
  );
  static final _arabicLetter = RegExp('[\u0621-\u064A\u0671-\u06D3]');
  static final _nonWord = RegExp(r'[^\p{L}\p{N}]+', unicode: true);
  static final _verseRef = RegExp(r'^(\d{1,3})\s*[:.]\s*(\d{1,3})$');
  static final _verseRange = RegExp(
    r'^(\d{1,3})\s*[:.]\s*(\d{1,3})\s*[-–—]\s*(\d{1,3})$',
  );
  static final _divisionRef = RegExp(
    r'^(juz|juzu|juzuu|juzz|para|jz|hizb|hizbu|page|pg|p|ukurasa|uk|'
    r'الجزء|جزء|الحزب|حزب|الصفحة|صفحة|ص)\.?\s*(\d{1,3})$',
  );

  List<_SearchRow>? _index;

  /// Folds Uthmani orthography onto plain Arabic: drops harakat, Quranic
  /// annotation marks and tatweel, and unifies alef/ya/ta-marbuta forms.
  /// Uthmani waw + dagger alef (ٱلصَّلَوٰة) is read as the plain alef of
  /// الصلاة.
  static String normalizeArabic(String s) =>
      _foldArabic(s.replaceAll('\u0648\u0670', '\u0627'));

  /// [normalizeArabic] that keeps the Uthmani waw, so undiacritized Uthmani
  /// spellings (الصلوة, الزكوة) still match.
  static String _foldArabic(String s) => s
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

  /// Arabic-Indic (٠–٩) and Eastern Arabic-Indic (۰–۹) digits as 0–9.
  static String westernDigits(String s) => s.replaceAllMapped(
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
            arWaw: _foldArabic(a.text),
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

    final ref = _verseRef.firstMatch(westernDigits(trimmed));
    if (ref != null) {
      final s = int.parse(ref[1]!);
      final a = int.parse(ref[2]!);
      if (s < 1 || s > _ar.length || a < 1 || a > _ar[s - 1].length) {
        return [];
      }
      return [_result(s, _ar[s - 1][a - 1], 'ar')];
    }
    final shortcut = _divisionResults(westernDigits(trimmed).toLowerCase());
    if (shortcut != null) return shortcut.take(limit).toList();

    final out = <AyahSearchResult>[];
    if (_arabicLetter.hasMatch(trimmed)) {
      final q = normalizeArabic(trimmed);
      if (q.length < 2) return [];
      final skeleton = _arabicSkeleton(q);
      for (final row in _searchIndex) {
        if (row.ar.contains(q) ||
            row.arWaw.contains(q) ||
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

  /// `2:255-260`, `juz 5`, `hizb 12`, `page 300` (and their Arabic and
  /// Swahili words). Null when [q] is none of these. A juz or hizb lists
  /// where each of its quarters starts; a page or range lists its ayahs.
  List<AyahSearchResult>? _divisionResults(String q) {
    final range = _verseRange.firstMatch(q);
    if (range != null) {
      final s = int.parse(range[1]!);
      final from = int.parse(range[2]!);
      final to = int.parse(range[3]!);
      if (s < 1 || s > _ar.length || from < 1 || to < from) return [];
      final list = _ar[s - 1];
      if (from > list.length) return [];
      return [
        for (final a in list.sublist(from - 1, to.clamp(from, list.length)))
          _result(s, a, 'ar'),
      ];
    }
    final m = _divisionRef.firstMatch(q);
    if (m == null) return null;
    final word = m[1]!;
    final n = int.parse(m[2]!);
    AyahSearchResult res((int, int) p) => _result(p.$1, _ayahOf(p), 'ar');
    if (const {
      'juz',
      'juzu',
      'juzuu',
      'juzz',
      'para',
      'jz',
      'الجزء',
      'جزء',
    }.contains(word)) {
      if (juzStart(n) == null) return [];
      return [
        for (var i = 0; i < _quarterStarts.length; i++)
          if (_ayahOf(_quarterStarts[i]).juz == n) res(_quarterStarts[i]),
      ];
    }
    if (const {'hizb', 'hizbu', 'الحزب', 'حزب'}.contains(word)) {
      if (n < 1 || n > hizbCount) return [];
      return [
        for (var q = n * 4 - 3; q <= n * 4; q++) res(_quarterStarts[q - 1]),
      ];
    }
    if (n < 1 || n > _pageStarts.length) return [];
    return [
      for (var si = 0; si < _ar.length; si++)
        for (final a in _ar[si])
          if (a.page == n) _result(si + 1, a, 'ar'),
    ];
  }

  Ayah _ayahOf((int, int) p) => _ar[p.$1 - 1][p.$2 - 1];

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
  Future<String?> tafsir(String verseKey, {String lang = 'en'}) async {
    final offline = await _offlineTafsir(verseKey, tafsirEdition(lang));
    if (offline != null && offline.isNotEmpty) return offline;
    final cacheKey = '${tafsirEdition(lang)}:$verseKey';
    final cache = (_s.read<Map>(StorageService.kTafsirCache) ?? {})
        .cast<String, String>();
    if (cache.containsKey(cacheKey)) return cache[cacheKey];

    try {
      final res = await http
          .get(Uri.parse(tafsirUrl(verseKey, lang: lang)))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final text = parseTafsir(res.body);
      if (text == null) return null;
      cache[cacheKey] = text;
      await _s.write(StorageService.kTafsirCache, cache);
      return text;
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
    required this.arWaw,
    required this.arSkeleton,
    required this.en,
    required this.sw,
  });

  final int surah;
  final Ayah ayah;
  final String ar;
  final String arWaw;
  final String arSkeleton;
  final String en;
  final String sw;
}
