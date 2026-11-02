import 'package:get/get.dart';

import '../data/models.dart';
import '../routes/app_pages.dart';
import '../services/quran_service.dart';

/// Quran index: offline search (surah names / ayah text), sort mode,
/// continue-reading + bookmarks.
class QuranController extends GetxController {
  final _quran = QuranService.instance;

  final query = ''.obs;

  /// 0 Surahs · 1 Juz · 2 Ayat.
  final segment = 0.obs;
  bool get searchAyahs => segment.value == 2;
  final sortByRevelation = false.obs;
  final ayahResults = <AyahSearchResult>[].obs;
  Rxn<(int, int, int)> get lastRead => _quran.lastReadRx;

  /// True when the result list was cut at [QuranService.defaultSearchLimit].
  final resultsLimited = false.obs;

  bool get hasAyahQuery => _normalizedLength(query.value) >= 2;

  List<Surah> get visibleSurahs {
    var list = _quran.surahs.toList();
    final q = query.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((s) {
        return s.nameSimple.toLowerCase().contains(q) ||
            s.nameTranslated.toLowerCase().contains(q) ||
            s.nameArabic.contains(q) ||
            s.nameOrnate.contains(q) ||
            s.number.toString() == q;
      }).toList();
    }
    if (sortByRevelation.value) {
      list.sort((a, b) => a.revelationOrder.compareTo(b.revelationOrder));
    }
    return list;
  }

  void onQueryChanged(String q) {
    query.value = q;
    _runAyahSearch();
  }

  void setSegment(int i) {
    segment.value = i;
    _runAyahSearch();
  }

  void _runAyahSearch() {
    if (!searchAyahs || !hasAyahQuery) {
      ayahResults.clear();
      resultsLimited.value = false;
      return;
    }
    const limit = QuranService.defaultSearchLimit;
    final results = _quran.searchAyahs(
      query.value,
      locale: Get.locale?.languageCode ?? 'en',
      limit: limit + 1,
    );
    resultsLimited.value = results.length > limit;
    ayahResults.assignAll(results.take(limit));
  }

  static int _normalizedLength(String q) {
    final t = q.trim();
    if (RegExp(r'\d').hasMatch(t)) return t.length;
    return QuranService.normalizeLatin(QuranService.normalizeArabic(t)).length;
  }

  void toggleSort() => sortByRevelation.toggle();

  /// A surah without bookmarks gets one on its first ayah; one with
  /// bookmarks opens the Bookmarks list.
  Future<void> surahBookmarkTap(int surahNumber) async {
    if (_quran.bookmarkedSurahs.contains(surahNumber)) {
      await Get.toNamed(Routes.bookmarks);
    } else {
      await _quran.saveBookmark(surahNumber, 1);
    }
  }

  void refreshLastRead() => lastRead.value = _quran.lastRead;
}
