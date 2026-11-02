import 'package:get/get.dart';

import '../data/models.dart';
import '../services/quran_service.dart';

/// Quran index: offline search (surah names / ayah text), sort mode,
/// continue-reading + bookmarks.
class QuranController extends GetxController {
  final _quran = QuranService.instance;

  final query = ''.obs;
  final searchAyahs = false.obs; // Surahs | Ayat segment
  final sortByRevelation = false.obs;
  final ayahResults = <AyahSearchResult>[].obs;
  final bookmarked = Rx<Set<int>>(<int>{});
  final lastRead = Rx<(int, int, int)?>(null);

  /// True when the result list was cut at [QuranService.defaultSearchLimit].
  final resultsLimited = false.obs;

  bool get hasAyahQuery => _normalizedLength(query.value) >= 2;

  @override
  void onInit() {
    super.onInit();
    bookmarked.value = _quran.bookmarks;
    lastRead.value = _quran.lastRead;
  }

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

  void setSegment(bool ayahs) {
    searchAyahs.value = ayahs;
    _runAyahSearch();
  }

  void _runAyahSearch() {
    if (!searchAyahs.value || !hasAyahQuery) {
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

  Future<void> toggleBookmark(int surahNumber) async {
    await _quran.toggleBookmark(surahNumber);
    bookmarked.value = _quran.bookmarks;
  }

  void refreshLastRead() => lastRead.value = _quran.lastRead;
}
