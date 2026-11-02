import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/quran_controller.dart';
import '../../data/models.dart';
import '../../routes/app_pages.dart';
import '../../services/quran_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/floating_nav_pill.dart';

/// Quran index — search, Surahs/Ayat segment, continue-reading card,
/// surah tiles with gold-ring numerals + Makki/Madani chips.
class QuranIndexScreen extends GetView<QuranController> {
  const QuranIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      bottomNavigationBar: const FloatingNavPill(active: 'quran'),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.bookmark_border,
                  size: 18,
                  color: AppColors.sage,
                ),
                const SizedBox(width: 60),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'alQuranKareem'.tr,
                        style: AppTheme.body(
                          10,
                          weight: FontWeight.w700,
                          color: AppColors.gold,
                          letterSpacing: 1.4,
                        ),
                      ),
                      Text(
                        'holyQuran'.tr,
                        style: AppTheme.headline(21, weight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.tune, size: 18, color: AppColors.sage),
                const SizedBox(width: 24),
              ],
            ),
            const SizedBox(height: 14),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                onChanged: controller.onQueryChanged,
                decoration: InputDecoration(
                  hintText: 'searchSurahAyah'.tr,
                  hintStyle: AppTheme.body(13, color: AppColors.sage),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.sage,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(color: AppColors.hairline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(color: AppColors.emerald),
                  ),
                ),
                style: AppTheme.body(13.5),
              ),
            ),
            const SizedBox(height: 12),

            // Segment
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Obx(
                () => Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SegBtn(
                          icon: Icons.menu_book,
                          label: 'surahs'.tr,
                          selected: !controller.searchAyahs.value,
                          onTap: () => controller.setSegment(false),
                        ),
                      ),
                      Expanded(
                        child: _SegBtn(
                          icon: Icons.format_list_numbered,
                          label: 'ayat'.tr,
                          selected: controller.searchAyahs.value,
                          onTap: () => controller.setSegment(true),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Expanded(
              child: Obx(() {
                if (controller.searchAyahs.value) {
                  return _AyahResults(controller: controller);
                }
                final list = controller.visibleSurahs;
                final last = controller.lastRead.value;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
                  children: [
                    if (last != null)
                      _ContinueCard(
                        surah: QuranService.instance.surah(last.$1),
                        ayah: last.$2,
                        page: last.$3,
                      ),
                    const SizedBox(height: 6),
                    // Column headers
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Text(
                            'allSurahs'.trParams({'count': '${list.length}'}),
                            style: AppTheme.body(
                              10.5,
                              weight: FontWeight.w700,
                              color: AppColors.sage,
                              letterSpacing: 0.9,
                            ),
                          ),
                          Text(
                            ' · ${'juzCount'.tr}',
                            style: AppTheme.body(10.5, color: AppColors.sage),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: controller.toggleSort,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.sort,
                                  size: 14,
                                  color: AppColors.emerald,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  controller.sortByRevelation.value
                                      ? 'orderRevelation'.tr
                                      : 'orderStandard'.tr,
                                  style: AppTheme.body(
                                    10.5,
                                    weight: FontWeight.w600,
                                    color: AppColors.emerald,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final s in list) ...[
                      _SurahTile(
                        surah: s,
                        bookmarked: controller.bookmarked.value.contains(
                          s.number,
                        ),
                        onBookmark: () => controller.toggleBookmark(s.number),
                        onTap: () => Get.toNamed(
                          Routes.reader(s.number),
                        )?.then((_) => controller.refreshLastRead()),
                      ),
                      // Juz-30 divider like the mockup
                      if (s.number == 105)
                        _JuzDivider(
                          label: '${'juz'.tr.toUpperCase()} 30 · ‘AMMA',
                        ),
                    ],
                    if (list.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(30),
                        child: Center(
                          child: Text(
                            'noResults'.tr,
                            style: AppTheme.body(13, color: AppColors.sage),
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegBtn extends StatelessWidget {
  const _SegBtn({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.emerald : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? Colors.white : AppColors.sage,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.body(
                12.5,
                weight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.sage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.surah,
    required this.ayah,
    required this.page,
  });

  final Surah surah;
  final int ayah;
  final int page;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: appCardDecoration(),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.goldTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bookmark, color: AppColors.gold, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'continueReading'.tr,
                  style: AppTheme.body(
                    9.5,
                    weight: FontWeight.w700,
                    color: AppColors.sage,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${surah.nameSimple}, ${'ayahN'.trParams({'n': '$ayah'})}',
                  style: AppTheme.headline(14, weight: FontWeight.w700),
                ),
                Text(
                  '${'juz'.tr} ${surah.juzStart} · ${'page'.tr} $page',
                  style: AppTheme.body(11, color: AppColors.sage),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => Get.toNamed(
              Routes.reader(surah.number, ayah: ayah),
            )?.then((_) => Get.find<QuranController>().refreshLastRead()),
            icon: Text(
              'resume'.tr,
              style: AppTheme.body(
                12,
                weight: FontWeight.w700,
                color: AppColors.emerald,
              ),
            ),
            label: const Icon(
              Icons.chevron_right,
              color: AppColors.emerald,
              size: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  const _SurahTile({
    required this.surah,
    required this.bookmarked,
    required this.onBookmark,
    required this.onTap,
  });

  final Surah surah;
  final bool bookmarked;
  final VoidCallback onBookmark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: appCardDecoration(),
          child: Row(
            children: [
              // Gold-ring number circle
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.ivory,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.55),
                    width: 1.4,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${surah.number}',
                  style: AppTheme.headline(
                    15,
                    weight: FontWeight.w700,
                    color: AppColors.emeraldDeep,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          surah.nameSimple,
                          style: AppTheme.headline(
                            14.5,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            surah.nameTranslated,
                            style: AppTheme.body(
                              11.5,
                              color: AppColors.sage,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${surah.ayahs} ${'ayahsUnit'.tr} · ${'order'.tr} ${surah.revelationOrder}',
                      style: AppTheme.body(11, color: AppColors.sage),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    surah.nameArabic,
                    textDirection: TextDirection.rtl,
                    style: AppTheme.quran(
                      17,
                      weight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onBookmark,
                        child: Icon(
                          bookmarked ? Icons.bookmark : Icons.bookmark_border,
                          size: 15,
                          color: bookmarked ? AppColors.gold : AppColors.sage,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.goldTint,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          surah.revelation == 'makki'
                              ? 'makki'.tr
                              : 'madani'.tr,
                          style: AppTheme.body(
                            9.5,
                            weight: FontWeight.w700,
                            color: AppColors.emeraldDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JuzDivider extends StatelessWidget {
  const _JuzDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: AppColors.hairline)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.goldTint,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_border, size: 12, color: AppColors.gold),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: AppTheme.body(
                    10.5,
                    weight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.star_border, size: 12, color: AppColors.gold),
              ],
            ),
          ),
          Expanded(child: Container(height: 1, color: AppColors.hairline)),
        ],
      ),
    );
  }
}

class _AyahResults extends StatelessWidget {
  const _AyahResults({required this.controller});
  final QuranController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.hasAyahQuery) {
      return _SearchMessage(
        key: const ValueKey('ayah-search-hint'),
        icon: Icons.search,
        text: 'searchAyahHint'.tr,
      );
    }
    if (controller.ayahResults.isEmpty) {
      return _SearchMessage(
        key: const ValueKey('ayah-search-empty'),
        icon: Icons.search_off,
        text: 'searchNoMatches'.trParams({'q': controller.query.value.trim()}),
      );
    }
    final results = controller.ayahResults;
    final limited = controller.resultsLimited.value;
    return ListView.builder(
      key: const ValueKey('ayah-search-results'),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
      itemCount: results.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              limited
                  ? 'searchLimited'.trParams({'n': '${results.length}'})
                  : 'searchCount'.trParams({'n': '${results.length}'}),
              style: AppTheme.body(
                10.5,
                weight: FontWeight.w700,
                color: AppColors.sage,
                letterSpacing: 0.6,
              ),
            ),
          );
        }
        final r = results[i - 1];
        return _AyahResultTile(
          result: r,
          onTap: () => Get.toNamed(
            Routes.reader(r.surahNumber, ayah: r.ayahNumber),
          )?.then((_) => controller.refreshLastRead()),
        );
      },
    );
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 0, 36, 110),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.sage, size: 26),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTheme.body(13, color: AppColors.sage, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _AyahResultTile extends StatelessWidget {
  const _AyahResultTile({required this.result, required this.onTap});
  final AyahSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = result;
    final surah = QuranService.instance.surah(r.surahNumber);
    final source = switch (r.matchLanguage) {
      'en' => 'matchEn'.tr,
      'sw' => 'matchSw'.tr,
      _ => 'matchAr'.tr,
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('ayah-result-${r.verseKey}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: appCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${surah.nameSimple} ${r.verseKey}',
                      style: AppTheme.headline(13, weight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldTint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      source,
                      style: AppTheme.body(
                        9.5,
                        weight: FontWeight.w700,
                        color: AppColors.emeraldDeep,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                r.text,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: AppTheme.quran(16, height: 1.9),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (r.matchedTranslation != null) ...[
                const SizedBox(height: 6),
                Text(
                  r.matchedTranslation!,
                  style: AppTheme.body(12, color: AppColors.ink, height: 1.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
