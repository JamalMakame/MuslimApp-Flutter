import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/quran_service.dart';
import '../../theme/app_theme.dart';

/// Tafsir bottom sheet (20px radius + grab handle) — ayah Arabic,
/// Sahih Intl. quote, Ibn Kathir commentary, Share/Copy/Done.
/// Content fetched lazily + cached; shows loading/unavailable states.
Future<void> showTafsirSheet({
  required int surahNumber,
  required int ayahNumber,
  required String ayahText,
}) async {
  final translation = QuranService.instance.translation(
    surahNumber,
    ayahNumber,
    'en',
  );

  Get.bottomSheet(
    SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: Get.height * 0.78),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 52,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 14),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'tafsirKathir'.tr,
                    style: AppTheme.body(
                      11,
                      weight: FontWeight.w700,
                      color: AppColors.gold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: Get.back,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.ivory,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, size: 17, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Ayah card
                  Container(
                    decoration: appCardDecoration(),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'surahN'.trParams({'n': '$surahNumber'}),
                              style: AppTheme.body(
                                10,
                                weight: FontWeight.w600,
                                color: AppColors.sage,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  'ayahN'.trParams({'n': '$ayahNumber'}),
                                  style: AppTheme.headline(
                                    16,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.goldTint,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    QuranService.instance
                                                .surah(surahNumber)
                                                .revelation ==
                                            'makki'
                                        ? 'makki'.tr
                                        : 'madani'.tr,
                                    style: AppTheme.body(
                                      9.5,
                                      weight: FontWeight.w700,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ayahText,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: AppTheme.quran(
                              18,
                              height: 1.9,
                              color: AppColors.emeraldDeep,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Translation quote
                  if (translation.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.ivory,
                        borderRadius: BorderRadius.circular(14),
                        border: const Border(
                          left: BorderSide(color: AppColors.gold, width: 3),
                        ),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '"$translation"',
                            style: AppTheme.body(
                              13.5,
                              color: AppColors.ink,
                              fontStyle: FontStyle.italic,
                              height: 1.55,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'sahihIntl'.tr,
                            style: AppTheme.body(
                              9.5,
                              weight: FontWeight.w700,
                              color: AppColors.sage,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Commentary
                  Row(
                    children: [
                      Text(
                        'commentary'.tr,
                        style: AppTheme.body(
                          10.5,
                          weight: FontWeight.w700,
                          color: AppColors.sage,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.menu_book,
                            size: 13,
                            color: AppColors.emerald,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'fullExegesis'.tr,
                            style: AppTheme.body(
                              11,
                              weight: FontWeight.w600,
                              color: AppColors.emerald,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _TafsirBody(verseKey: '$surahNumber:$ayahNumber'),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.hairline)),
              ),
              child: Row(
                children: [
                  _ActionBtn(
                    icon: Icons.share,
                    label: 'share'.tr,
                    onTap: () => Share.share(
                      '$ayahText\n\n$translation\n\n($surahNumber:$ayahNumber)',
                    ),
                  ),
                  const SizedBox(width: 14),
                  _ActionBtn(
                    icon: Icons.copy,
                    label: 'copy'.tr,
                    onTap: () async {
                      await Clipboard.setData(
                        ClipboardData(
                          text:
                              '$ayahText\n\n$translation\n\n($surahNumber:$ayahNumber)',
                        ),
                      );
                      Get.rawSnackbar(
                        messageText: Text(
                          'copied'.tr,
                          style: AppTheme.body(12, color: Colors.white),
                        ),
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.brandDeep,
                        duration: const Duration(seconds: 2),
                        borderRadius: 12,
                        margin: const EdgeInsets.all(16),
                      );
                    },
                  ),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    onPressed: Get.back,
                    child: Text(
                      'done'.tr,
                      style: AppTheme.body(
                        13.5,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  );
}

class _TafsirBody extends StatelessWidget {
  const _TafsirBody({required this.verseKey});
  final String verseKey;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: QuranService.instance.tafsir(
        verseKey,
        lang: Get.locale?.languageCode ?? 'en',
      ),
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.emerald,
                ),
              ),
            ),
          );
        }
        final text = snap.data;
        if (text == null || text.isEmpty) {
          return Text(
            'tafsirUnavailable'.tr,
            style: AppTheme.body(13, color: AppColors.sage),
          );
        }
        return Text(
          text,
          style: AppTheme.body(13.5, color: AppColors.ink, height: 1.65),
        );
      },
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.emerald),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTheme.body(
              13,
              weight: FontWeight.w600,
              color: AppColors.emerald,
            ),
          ),
        ],
      ),
    );
  }
}
