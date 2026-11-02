import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_pages.dart';
import '../../services/quran_service.dart';
import '../../theme/app_theme.dart';

/// Juz tab: the 30 juz, each opening into where its 8 hizb quarters start.
class JuzList extends StatelessWidget {
  const JuzList({super.key});

  static String firstWords(String text) =>
      text.replaceFirst('۞', '').trim().split(' ').take(5).join(' ');

  @override
  Widget build(BuildContext context) {
    final quran = QuranService.instance;
    return ListView.builder(
      key: const ValueKey('juz-list'),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
      itemCount: QuranService.juzCount,
      itemBuilder: (context, i) {
        final juz = i + 1;
        final (s, a) = quran.juzStart(juz)!;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: appCardDecoration(),
          // ListTiles paint on the nearest Material; keep it above the card.
          child: Material(
            type: MaterialType.transparency,
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                key: ValueKey('juz-tile-$juz'),
                leading: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.goldTint,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$juz',
                    style: AppTheme.headline(
                      13,
                      weight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                ),
                title: Text(
                  '${'juz'.tr} $juz',
                  style: AppTheme.headline(14, weight: FontWeight.w700),
                ),
                subtitle: Text(
                  'juzStartsAt'.trParams({
                    'ref': '${quran.surah(s).nameSimple} $s:$a',
                  }),
                  style: AppTheme.body(11, color: AppColors.sage),
                ),
                children: [
                  for (var q = juz * 8 - 7; q <= juz * 8; q++)
                    _QuarterRow(quarter: q),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuarterRow extends StatelessWidget {
  const _QuarterRow({required this.quarter});

  final int quarter;

  @override
  Widget build(BuildContext context) {
    final quran = QuranService.instance;
    final (s, a) = quran.hizbQuarterStart(quarter)!;
    final ayah = quran.ayahAt(s, a)!;
    return ListTile(
      key: ValueKey('quarter-row-$quarter'),
      dense: true,
      leading: SizedBox(
        width: 64,
        child: Text(
          '${'hizb'.tr} ${ayah.hizbLabel}',
          style: AppTheme.body(
            11,
            weight: FontWeight.w700,
            color: AppColors.gold,
          ),
        ),
      ),
      title: Text(
        JuzList.firstWords(ayah.text),
        textDirection: TextDirection.rtl,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.quran(16, height: 1.7),
      ),
      subtitle: Text(
        '${quran.surah(s).nameSimple} $s:$a',
        style: AppTheme.body(11, color: AppColors.sage),
      ),
      onTap: () => Get.toNamed(Routes.reader(s, ayah: a)),
    );
  }
}
