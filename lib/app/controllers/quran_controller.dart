import 'package:get/get.dart';

import '../data/models.dart';
import '../services/quran_service.dart';

/// Quran index: search (surah local / ayah remote), sort mode,
/// continue-reading + bookmarks.
class QuranController extends GetxController {
  final _quran = QuranService.instance;

  final query = ''.obs;
  final searchAyahs = false.obs; // Surahs | Ayat segment
  final sortByRevelation = false.obs;
  final searching = false.obs;
  final ayahResults = <AyahSearchResult>[].obs;
  final bookmarked = Rx<Set<int>>(<int>{});
  final lastRead = Rx<(int, int, int)?>(null);
  final offlineSearchError = false.obs;

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

  Future<void> onQueryChanged(String q) async {
    query.value = q;
    if (!searchAyahs.value) return;
    if (q.trim().length < 2) {
      ayahResults.clear();
      return;
    }
    searching.value = true;
    offlineSearchError.value = false;
    try {
      ayahResults.value = await _quran.searchAyahs(q);
    } catch (_) {
      ayahResults.clear();
      offlineSearchError.value = true;
    } finally {
      searching.value = false;
    }
  }

  void setSegment(bool ayahs) {
    searchAyahs.value = ayahs;
    ayahResults.clear();
  }

  void toggleSort() => sortByRevelation.toggle();

  Future<void> toggleBookmark(int surahNumber) async {
    await _quran.toggleBookmark(surahNumber);
    bookmarked.value = _quran.bookmarks;
  }

  void refreshLastRead() => lastRead.value = _quran.lastRead;
}
