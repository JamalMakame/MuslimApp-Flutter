import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../controllers/reader_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../data/models.dart';
import '../../routes/app_pages.dart';
import '../../services/quran_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/ayah_actions_sheet.dart';
import '../widgets/floating_nav_pill.dart';
import '../widgets/go_to_sheet.dart';
import '../widgets/tafsir_sheet.dart';

/// Mushaf reader — white canvas, gold inner frame, basmala cartouche,
/// flowing uthmani text with gold ayah medallions, optional translation
/// blocks, audio bar (reciter/scrubber/speed).
class QuranReaderScreen extends GetView<ReaderController> {
  const QuranReaderScreen({super.key, required this.surah});

  final int surah;

  static const basmala = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

  ReaderController get c => Get.find<ReaderController>(tag: 'reader_$surah');

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    final s = c.surah;
    return Scaffold(
      backgroundColor: AppColors.ivory,
      bottomNavigationBar: const FloatingNavPill(active: 'quran'),
      body: SafeArea(
        child: Column(
          children: [
            // ---- Header ----------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  _RoundIconBtn(icon: Icons.arrow_back, onTap: Get.back),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          s.nameSimple,
                          style: AppTheme.headline(18, weight: FontWeight.w800),
                        ),
                        Text(
                          '${'surahN'.trParams({'n': '${s.number}'})}'
                          ' · ${s.ayahs} ${'ayahsUnit'.tr} · ${s.revelation == 'makki' ? 'makki'.tr : 'madani'.tr}',
                          style: AppTheme.body(10.5, color: AppColors.sage),
                        ),
                      ],
                    ),
                  ),
                  _RoundIconBtn(
                    key: const ValueKey('reader-goto'),
                    icon: Icons.near_me_outlined,
                    onTap: () => showGoToSheet(fromSurah: s.number),
                  ),
                  const SizedBox(width: 8),
                  _RoundIconBtn(
                    key: const ValueKey('reader-mushaf'),
                    icon: Icons.auto_stories_outlined,
                    onTap: () => Get.toNamed(
                      Routes.mushaf(c.current.value?.page ?? s.pageStart),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(() {
                    final n = c.current.value?.numberInSurah ?? 1;
                    final on = c.isBookmarked(n);
                    return _RoundIconBtn(
                      key: const ValueKey('reader-bookmark'),
                      icon: on ? Icons.bookmark : Icons.bookmark_border,
                      color: on ? AppColors.gold : null,
                      onTap: () async {
                        final added = await c.toggleCurrentBookmark();
                        showReaderToast(
                          added
                              ? 'bookmarkAdded'.trParams({
                                  'ref': '${s.nameSimple} ${s.number}:$n',
                                })
                              : 'bookmarkRemoved'.tr,
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ---- Chips row --------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      key: const ValueKey('reader-position'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => showGoToSheet(fromSurah: s.number),
                      child: Obx(() {
                        final at = c.current.value ?? c.ayahs.first;
                        return Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppColors.goldTint,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${at.juz}',
                                style: AppTheme.headline(
                                  12,
                                  weight: FontWeight.w700,
                                  color: AppColors.gold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'hizbPage'.trParams({
                                  'hizb': at.hizbLabel,
                                  'page': '${at.page}',
                                }),
                                style: AppTheme.body(
                                  11.5,
                                  weight: FontWeight.w700,
                                  color: AppColors.sage,
                                  letterSpacing: 0.6,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _ChipBtn(
                    icon: Icons.graphic_eq,
                    label: 'hifzMode'.tr,
                    onTap: () async {
                      await c.pauseAudio();
                      Get.toNamed(
                        Routes.memorize(
                          s.number,
                          ayah: c.current.value?.numberInSurah,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _ChipBtn(
                    icon: Icons.text_fields,
                    label: 'A+A-',
                    onTap: () => settings.setTextScale(
                      (settings.textScale.value + 1) % 3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(
                    () => _ChipBtn(
                      icon: Icons.translate,
                      label: 'trans'.tr,
                      active: c.showTrans.value,
                      onTap: () {
                        c.showTrans.toggle();
                        settings.setShowTranslations(c.showTrans.value);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ---- Ayahs: one block each, built as they scroll in -------------
            Expanded(
              // Only the reader's own scrolling moves the saved position,
              // not a jump to an ayah.
              child: NotificationListener<UserScrollNotification>(
                onNotification: (n) {
                  if (n.direction == ScrollDirection.idle) {
                    c.saveVisiblePosition();
                  }
                  return false;
                },
                child: Obx(() {
                  final size = [19.0, 21.0, 26.0][settings.textScale.value];
                  final showTrans = c.showTrans.value;
                  final highlight = c.highlightAyah.value;
                  final playingAyah = c.playingAyah.value;
                  final marked = {
                    for (final b in QuranService.instance.bookmarksRx)
                      if (b.surah == s.number) b.ayah,
                  };
                  final count = c.ayahs.length;
                  return ScrollablePositionedList.builder(
                    itemScrollController: c.itemScroll,
                    itemPositionsListener: c.positions,
                    initialScrollIndex: c.initialIndex,
                    initialAlignment: c.initialIndex == 0 ? 0 : 0.08,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    itemCount: count + 2,
                    itemBuilder: (context, i) {
                      if (i == 0) return _SurahHeader(surah: s);
                      if (i == count + 1) return _SurahFooter(surah: s);
                      final a = c.ayahs[i - 1];
                      final n = a.numberInSurah;
                      return _AyahBlock(
                        key: c.ayahKey(n),
                        surah: s.number,
                        ayah: a,
                        size: size,
                        translation: showTrans ? c.translationOf(n) : '',
                        highlighted: highlight == n || playingAyah == n,
                        bookmarked: marked.contains(n),
                        onActions: () => showAyahActions(c, a),
                      );
                    },
                  );
                }),
              ),
            ),

            // ---- Audio player ----------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: _AudioBar(controller: c),
            ),
          ],
        ),
      ),
    );
  }
}

class _AyahMedallion extends StatelessWidget {
  const _AyahMedallion({required this.n, required this.isSajda});

  final int n;
  final bool isSajda;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSajda ? AppColors.emerald : AppColors.gold,
          width: 1.1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$n',
        style: AppTheme.body(
          8.5,
          weight: FontWeight.w700,
          color: isSajda ? AppColors.emerald : AppColors.gold,
        ),
      ),
    );
  }
}

class _AudioBar extends StatelessWidget {
  const _AudioBar({required this.controller});
  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: appCardDecoration(radius: 20),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.graphic_eq,
                  color: AppColors.emerald,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() {
                      final n = controller.playingAyah.value;
                      final name = controller.surah.nameSimple;
                      return Text(
                        n == null
                            ? 'fullSurah'.trParams({'name': name})
                            : 'playingAyah'.trParams({'name': name, 'n': '$n'}),
                        style: AppTheme.headline(13.5, weight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }),
                    Obx(
                      () => Text(
                        controller.playingAyah.value == null
                            ? 'misharyAlafasy'.tr
                            : QuranService.reciters[controller.reciter] ?? '',
                        style: AppTheme.body(11, color: AppColors.sage),
                      ),
                    ),
                  ],
                ),
              ),
              Obx(
                () => GestureDetector(
                  onTap: controller.cycleSpeed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldTint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${controller.speed.value}x',
                      style: AppTheme.body(
                        11,
                        weight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.repeat, color: AppColors.sage, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Obx(
            () => Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 5,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                  ),
                  child: Slider(
                    min: 0,
                    max: controller.duration.value.inSeconds.toDouble().clamp(
                      1,
                      double.infinity,
                    ),
                    value: controller.position.value.inSeconds.toDouble().clamp(
                      0,
                      controller.duration.value.inSeconds.toDouble(),
                    ),
                    onChanged: controller.seekTo,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ReaderController.fmt(controller.position.value),
                        style: AppTheme.body(11, color: AppColors.sage),
                      ),
                      Text(
                        ReaderController.fmt(controller.duration.value),
                        style: AppTheme.body(11, color: AppColors.sage),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.skip_previous, color: AppColors.ink, size: 26),
              const SizedBox(width: 14),
              Icon(Icons.replay_10, color: AppColors.ink, size: 24),
              const SizedBox(width: 14),
              Obx(
                () => GestureDetector(
                  onTap: controller.toggleAudio,
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: AppColors.emerald,
                      shape: BoxShape.circle,
                    ),
                    child: controller.audioLoading.value
                        ? const Padding(
                            padding: EdgeInsets.all(18),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            controller.playing.value
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 30,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Icon(Icons.forward_10, color: AppColors.ink, size: 24),
              const SizedBox(width: 14),
              Icon(Icons.skip_next, color: AppColors.ink, size: 26),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipBtn extends StatelessWidget {
  const _ChipBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.goldTint : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.gold : AppColors.hairline,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 13,
              color: active ? AppColors.emeraldDeep : AppColors.sage,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTheme.body(
                11,
                weight: FontWeight.w600,
                color: active ? AppColors.emeraldDeep : AppColors.sage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconBtn extends StatelessWidget {
  const _RoundIconBtn({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.hairline),
        ),
        child: Icon(icon, size: 19, color: color ?? AppColors.ink),
      ),
    );
  }
}

/// Surah cartouche and basmala (suppressed for Al-Fatihah, where ayah 1 is
/// the basmala, and At-Tawbah, which has none).
class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.surah});

  final Surah surah;

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: appCardDecoration(radius: 16),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.goldTint,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Column(
              children: [
                Text(
                  'surahHeader'.trParams({
                    'name': surah.nameSimple.toUpperCase(),
                  }),
                  style: AppTheme.body(
                    11,
                    weight: FontWeight.w800,
                    color: AppColors.emeraldDeep,
                    letterSpacing: 1.4,
                  ),
                ),
                Text(
                  '${surah.nameTranslated} · ${'revelation'.trParams({'order': '${surah.revelationOrder}'})}',
                  style: AppTheme.body(9.5, color: AppColors.sage),
                ),
              ],
            ),
          ),
          if (surah.number != 1 && surah.number != 9) ...[
            const SizedBox(height: 14),
            Text(
              QuranReaderScreen.basmala,
              textDirection: TextDirection.rtl,
              style: AppTheme.quran(
                24 * settings.quranScale,
                color: AppColors.emerald,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One ayah: number, Arabic, then its translation. Long-press (or the
/// "more" button) for the ayah's actions.
class _AyahBlock extends StatelessWidget {
  const _AyahBlock({
    super.key,
    required this.surah,
    required this.ayah,
    required this.size,
    required this.translation,
    required this.highlighted,
    required this.bookmarked,
    required this.onActions,
  });

  final int surah;
  final Ayah ayah;
  final double size;
  final String translation;
  final bool highlighted;
  final bool bookmarked;
  final VoidCallback onActions;

  @override
  Widget build(BuildContext context) {
    final n = ayah.numberInSurah;
    // The corpus marks most hizb quarters itself; add the missing ones.
    final mark =
        QuranService.instance.startsHizbQuarter(ayah) &&
        !ayah.text.startsWith('۞');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onActions,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: highlighted ? AppColors.goldTint : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlighted
                ? AppColors.gold.withValues(alpha: 0.5)
                : AppColors.hairline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _AyahMedallion(n: n, isSajda: ayah.sajda),
                const SizedBox(width: 6),
                Text(
                  '$surah:$n',
                  style: AppTheme.body(10.5, color: AppColors.sage),
                ),
                if (bookmarked) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.bookmark,
                    key: ValueKey('ayah-bookmarked-$n'),
                    size: 14,
                    color: AppColors.gold,
                  ),
                ],
                const Spacer(),
                InkWell(
                  key: ValueKey('ayah-more-$n'),
                  borderRadius: BorderRadius.circular(999),
                  onTap: onActions,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.more_horiz,
                      size: 20,
                      color: AppColors.sage,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  if (mark)
                    TextSpan(
                      text: '۞ ',
                      style: TextStyle(color: AppColors.gold),
                    ),
                  TextSpan(text: ayah.text),
                ],
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.start,
              style: AppTheme.quran(size, height: 2.05),
            ),
            if (translation.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                translation,
                style: AppTheme.body(13, color: AppColors.ink, height: 1.55),
              ),
            ],
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: GestureDetector(
                onTap: () => showTafsirSheet(
                  surahNumber: surah,
                  ayahNumber: n,
                  ayahText: ayah.text,
                ),
                child: Text(
                  'tafsirKathir'.tr,
                  style: AppTheme.body(
                    9,
                    weight: FontWeight.w700,
                    color: AppColors.emerald,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// End of the surah: recitation note, then previous / next surah.
class _SurahFooter extends StatelessWidget {
  const _SurahFooter({required this.surah});

  final Surah surah;

  @override
  Widget build(BuildContext context) {
    final quran = QuranService.instance;
    final n = surah.number;
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 7, color: AppColors.emerald),
              const SizedBox(width: 5),
              Text(
                'hafsRecitation'.tr,
                style: AppTheme.body(10.5, color: AppColors.sage),
              ),
              const Spacer(),
              Text(
                'mushafSharif'.tr,
                style: AppTheme.body(
                  10.5,
                  fontStyle: FontStyle.italic,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (n > 1)
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('reader-prev'),
                    onPressed: () => Get.offNamed(Routes.reader(n - 1)),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: Text(
                      'prevSurah'.trParams({
                        'name': quran.surah(n - 1).nameSimple,
                      }),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(12, weight: FontWeight.w600),
                    ),
                  ),
                ),
              if (n > 1 && n < 114) const SizedBox(width: 10),
              if (n < 114)
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('reader-next'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                    ),
                    onPressed: () => Get.offNamed(Routes.reader(n + 1)),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: Text(
                      'nextSurah'.trParams({
                        'name': quran.surah(n + 1).nameSimple,
                      }),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(
                        12,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
