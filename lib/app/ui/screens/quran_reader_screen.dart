import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/reader_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../routes/app_pages.dart';
import '../../theme/app_theme.dart';
import '../widgets/floating_nav_pill.dart';
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
                  Obx(
                    () => _RoundIconBtn(
                      icon: c.bookmarked.value
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: c.bookmarked.value ? AppColors.gold : null,
                      onTap: () async {
                        await c.toggleBookmark();
                        Get.rawSnackbar(
                          messageText: Text(
                            'bookmarkSaved'.tr,
                            style: AppTheme.body(12, color: Colors.white),
                          ),
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.emeraldDeep,
                          duration: const Duration(seconds: 1),
                          borderRadius: 12,
                          margin: const EdgeInsets.all(16),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ---- Chips row --------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: AppColors.goldTint,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${s.juzStart}',
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
                      'juzPage'.trParams({
                        'juz': '${s.juzStart}',
                        'page': '${s.pageStart}',
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
                  const SizedBox(width: 6),
                  _ChipBtn(
                    icon: Icons.graphic_eq,
                    label: 'hifzMode'.tr,
                    onTap: () async {
                      if (c.playing.value) await c.player.pause();
                      Get.toNamed(Routes.memorize(s.number));
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

            // ---- Mushaf canvas ---------------------------------------------
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  Container(
                    decoration: appCardDecoration(radius: 16),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.35),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      child: Column(
                        children: [
                          // Surah cartouche
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.goldTint,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'surahHeader'.trParams({
                                    'name': s.nameSimple.toUpperCase(),
                                  }),
                                  style: AppTheme.body(
                                    11,
                                    weight: FontWeight.w800,
                                    color: AppColors.emeraldDeep,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                                Text(
                                  '${s.nameTranslated} · ${'revelation'.trParams({'order': '${s.revelationOrder}'})}',
                                  style: AppTheme.body(
                                    9.5,
                                    color: AppColors.sage,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (s.number != 1 && s.number != 9) ...[
                            const SizedBox(height: 18),
                            Text(
                              basmala,
                              textDirection: TextDirection.rtl,
                              style: AppTheme.quran(
                                24 * settings.quranScale,
                                color: AppColors.emerald,
                                height: 1.5,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          const Divider(color: AppColors.hairline, height: 1),
                          const SizedBox(height: 14),

                          // Flowing ayah text w/ medallions
                          Obx(() {
                            final scale = settings.textScale.value;
                            final size = [19.0, 21.0, 26.0][scale];
                            final highlight = c.highlightAyah.value;
                            return Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    for (final a in c.ayahs) ...[
                                      WidgetSpan(
                                        child: SizedBox(
                                          key: c.ayahKey(a.numberInSurah),
                                          width: 0,
                                          height: size,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '${a.text} ',
                                        style:
                                            AppTheme.quran(
                                              size,
                                              height: 2.05,
                                            ).copyWith(
                                              backgroundColor:
                                                  highlight == a.numberInSurah
                                                  ? AppColors.goldTint
                                                  : null,
                                            ),
                                      ),
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: GestureDetector(
                                          onTap: () => showTafsirSheet(
                                            surahNumber: s.number,
                                            ayahNumber: a.numberInSurah,
                                            ayahText: a.text,
                                          ),
                                          child: _AyahMedallion(
                                            n: a.numberInSurah,
                                            isSajda: a.sajda,
                                          ),
                                        ),
                                      ),
                                      const TextSpan(text: ' '),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }),

                          // Translations
                          Obx(() {
                            if (!c.showTrans.value) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              children: [
                                const SizedBox(height: 14),
                                const Divider(color: AppColors.hairline),
                                const SizedBox(height: 8),
                                for (final a in c.ayahs)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 7,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              alignment: Alignment.center,
                                              decoration: const BoxDecoration(
                                                color: AppColors.goldTint,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                '${a.numberInSurah}',
                                                style: AppTheme.body(
                                                  9.5,
                                                  weight: FontWeight.w700,
                                                  color: AppColors.gold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 7),
                                            GestureDetector(
                                              onTap: () => showTafsirSheet(
                                                surahNumber: s.number,
                                                ayahNumber: a.numberInSurah,
                                                ayahText: a.text,
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
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          c.translationOf(a.numberInSurah),
                                          style: AppTheme.body(
                                            13,
                                            color: AppColors.ink,
                                            height: 1.55,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          }),
                          const SizedBox(height: 12),
                          const Divider(color: AppColors.hairline),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.circle,
                                size: 7,
                                color: AppColors.emerald,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'hafsRecitation'.tr,
                                style: AppTheme.body(
                                  10.5,
                                  color: AppColors.sage,
                                ),
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
                        ],
                      ),
                    ),
                  ),
                ],
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
                child: const Icon(
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
                    Text(
                      'fullSurah'.trParams({
                        'name': controller.surah.nameSimple,
                      }),
                      style: AppTheme.headline(13.5, weight: FontWeight.w700),
                    ),
                    Text(
                      'misharyAlafasy'.tr,
                      style: AppTheme.body(11, color: AppColors.sage),
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
              const Icon(Icons.repeat, color: AppColors.sage, size: 18),
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
              const Icon(Icons.skip_previous, color: AppColors.ink, size: 26),
              const SizedBox(width: 14),
              const Icon(Icons.replay_10, color: AppColors.ink, size: 24),
              const SizedBox(width: 14),
              Obx(
                () => GestureDetector(
                  onTap: controller.toggleAudio,
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: const BoxDecoration(
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
              const Icon(Icons.forward_10, color: AppColors.ink, size: 24),
              const SizedBox(width: 14),
              const Icon(Icons.skip_next, color: AppColors.ink, size: 26),
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
  const _RoundIconBtn({required this.icon, required this.onTap, this.color});

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
