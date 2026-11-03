import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/app_theme.dart';
import '../widgets/motion.dart';

/// The developer's dedication of Deen to his parents and his wife.
class DedicationScreen extends StatelessWidget {
  const DedicationScreen({super.key});

  static const father = 'Abdalla Makame';
  static const mothers = [
    'Zuhura Mohammed Amour',
    'Hawa Ibrahim Saburi',
    'Jaria Suleiman',
  ];
  static const wife = 'Nassra Khalfan Said';

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      const _Hero(),
      _Card(
        children: [
          Text(
            'dedicationIntro'.tr,
            textAlign: TextAlign.center,
            style: AppTheme.body(14.5, height: 1.6),
          ),
          const SizedBox(height: 18),
          _Label('dedicationFather'.tr),
          const _Name(father),
          const SizedBox(height: 14),
          _Label('dedicationMothers'.tr),
          for (final m in mothers) _Name(m),
          const SizedBox(height: 18),
          const _Divider(),
          const SizedBox(height: 14),
          Text(
            'dedicationThawab'.tr,
            textAlign: TextAlign.center,
            style: AppTheme.body(
              14,
              height: 1.6,
              color: AppColors.goldInk,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
      _Card(
        children: [
          Icon(Icons.favorite_rounded, color: AppColors.gold, size: 22),
          const SizedBox(height: 8),
          _Label('dedicationWife'.tr),
          const _Name(wife),
        ],
      ),
      _Card(
        children: [
          Text(
            'dedicationThanks'.tr,
            textAlign: TextAlign.center,
            style: AppTheme.body(14, height: 1.6),
          ),
        ],
      ),
      const _Verse(),
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          '— Jamal Makame',
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          style: AppTheme.headline(15, color: AppColors.emeraldDeep),
        ),
      ),
      Text(
        'dedicationRole'.tr,
        textAlign: TextAlign.center,
        style: AppTheme.body(12, color: AppColors.sage),
      ),
    ];
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(title: Text('dedication'.tr)),
      body: ListView(
        key: const ValueKey('dedication-list'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          for (var i = 0; i < sections.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: FadeSlideIn(index: i, child: sections[i]),
            ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, AppColors.brandDeep],
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.gold,
            size: 28,
          ),
          const SizedBox(height: 6),
          Text(
            'إهداء',
            textDirection: TextDirection.rtl,
            style: AppTheme.quran(34, color: AppColors.gold, height: 1.6),
          ),
          Text(
            'dedicationDesc'.tr,
            textAlign: TextAlign.center,
            style: AppTheme.body(
              14,
              color: AppColors.onBrand,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
      decoration: appCardDecoration(radius: 18),
      child: Column(children: children),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text.toUpperCase(),
        textAlign: TextAlign.center,
        style: AppTheme.body(
          11,
          weight: FontWeight.w700,
          color: AppColors.sage,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Name extends StatelessWidget {
  const _Name(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        name,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        style: AppTheme.headline(18, color: AppColors.emeraldDeep),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.hairline)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
        ),
        Expanded(child: Divider(color: AppColors.hairline)),
      ],
    );
  }
}

class _Verse extends StatelessWidget {
  const _Verse();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.goldTint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            'رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: AppTheme.quran(22, color: AppColors.goldInk, height: 1.9),
          ),
          if (Get.locale?.languageCode != 'ar') ...[
            const SizedBox(height: 6),
            Text(
              'dedicationVerse'.tr,
              textAlign: TextAlign.center,
              style: AppTheme.body(
                13,
                height: 1.5,
                fontStyle: FontStyle.italic,
                color: AppColors.ink,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'dedicationVerseRef'.tr,
            style: AppTheme.body(11.5, color: AppColors.sage),
          ),
        ],
      ),
    );
  }
}
