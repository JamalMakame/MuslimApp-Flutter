import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../controllers/home_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../routes/app_pages.dart';
import '../../services/hijri_date_service.dart';
import '../../services/prayer_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/floating_nav_pill.dart';

/// Salah Times home — date header, location chip, emerald next-prayer
/// hero, prayer tiles (current highlighted gold), Qibla card,
/// daily inspiration.
class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    return Scaffold(
      backgroundColor: AppColors.ivory,
      bottomNavigationBar: const FloatingNavPill(active: 'home'),
      body: SafeArea(
        child: Obx(() {
          final day = controller.day.value;
          final locale = settings.localeCode.value;
          final now = controller.currentDate.value;
          final hijri = HijriDateService.on(now, controller.hijriOffset.value);
          final hijriLabel =
              '${hijri.hDay} '
              '${HijriDateService.monthName(hijri.hMonth, locale)} '
              '${hijri.hYear}';
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 110),
            children: [
              // ---- Header -------------------------------------------------
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'salahTimes'.tr,
                          style: AppTheme.headline(22, weight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        InkWell(
                          key: const ValueKey('home-calendar-link'),
                          onTap: () async {
                            final home = controller;
                            await Get.toNamed(Routes.calendar);
                            if (!home.isClosed) home.recompute();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    '${DateFormat('EEE d MMM y', locale).format(now)} · $hijriLabel',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.body(
                                      12,
                                      color: AppColors.sage,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.emerald,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.toNamed(Routes.settings),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.hairline),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 13,
                            color: AppColors.emerald,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            settings.placeLabel,
                            style: AppTheme.body(
                              11,
                              weight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ---- Hero ---------------------------------------------------
              if (day != null)
                _HeroCard(day: day, locale: locale, hijriLabel: hijriLabel),
              if (day == null)
                _Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.location_searching,
                          color: AppColors.emerald,
                          size: 30,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'setLocationFirst'.tr,
                          style: AppTheme.body(13, color: AppColors.sage),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // ---- Prayer tiles -------------------------------------------
              if (day != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'todaySchedule'.tr,
                    style: AppTheme.body(
                      11,
                      weight: FontWeight.w700,
                      color: AppColors.sage,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                _Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < day.slots.length; i++) ...[
                        if (i > 0)
                          const Divider(height: 1, indent: 16, endIndent: 16),
                        _PrayerTile(
                          slot: day.slots[i],
                          isCurrent:
                              day.slots[i].key == day.currentKey ||
                              (day.slots[i].key == 'sunrise' &&
                                  day.currentKey == 'sunrise'),
                          isNext: day.slots[i].key == day.nextKey,
                          locale: locale,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ---- Qibla card ---------------------------------------------
              _Card(
                onTap: () => Get.toNamed(Routes.qibla),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: AppColors.goldTint,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.explore,
                          color: AppColors.gold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'qiblaFinder'.tr,
                              style: AppTheme.body(
                                13.5,
                                weight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'faceKaaba'.tr,
                              style: AppTheme.body(11.5, color: AppColors.sage),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.sage,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ---- Daily inspiration --------------------------------------
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'dailyInspiration'.tr,
                  style: AppTheme.body(
                    11,
                    weight: FontWeight.w700,
                    color: AppColors.sage,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _InspirationCard(
                      icon: Icons.auto_stories,
                      label: 'ayahOfDay'.tr,
                      arabic:
                          '﴿ٱللَّهُ لَا إِلَٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ﴾',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InspirationCard(
                      icon: Icons.format_quote,
                      label: 'hadithOfDay'.tr,
                      arabic: '',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _InspirationCard(
                      icon: Icons.star_border,
                      label: 'nameOfAllah'.tr,
                      arabic: 'ٱلرَّحْمَٰن',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InspirationCard(
                      icon: Icons.volunteer_activism,
                      label: 'duaOfDay'.tr,
                      arabic: '',
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(decoration: appCardDecoration(), child: child),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.day,
    required this.locale,
    required this.hijriLabel,
  });
  final PrayerDay day;
  final String locale;
  final String hijriLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.emerald, AppColors.emeraldDeep],
        ),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330A4A3F),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          // Corner ornament
          PositionedDirectional(
            top: -30,
            end: -30,
            child: Icon(
              Icons.star_purple500_outlined,
              size: 130,
              color: AppColors.gold.withValues(alpha: 0.08),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      'nextPrayer'.tr.toUpperCase(),
                      style: AppTheme.body(
                        10,
                        weight: FontWeight.w700,
                        color: AppColors.goldTint,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    hijriLabel,
                    style: AppTheme.body(
                      11,
                      color: AppColors.ivory.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                day.nextKey.tr,
                style: AppTheme.headline(
                  30,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('h:mm a', locale).format(day.nextTime),
                style: AppTheme.body(
                  16,
                  weight: FontWeight.w600,
                  color: AppColors.ivory.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.goldTint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 13,
                      color: AppColors.emeraldDeep,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'inTime'.trParams({
                        'time': PrayerService.remainingLabel(day.remaining),
                      }),
                      style: AppTheme.body(
                        12,
                        weight: FontWeight.w700,
                        color: AppColors.emeraldDeep,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrayerTile extends StatelessWidget {
  const _PrayerTile({
    required this.slot,
    required this.isCurrent,
    required this.isNext,
    required this.locale,
  });

  final PrayerSlot slot;
  final bool isCurrent;
  final bool isNext;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final active = isCurrent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: active ? AppColors.goldTint : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? AppColors.gold : AppColors.ivory,
              border: Border.all(
                color: active ? AppColors.gold : AppColors.hairline,
              ),
            ),
            child: Icon(
              switch (slot.key) {
                'fajr' => Icons.dark_mode_outlined,
                'sunrise' => Icons.wb_twilight,
                'dhuhr' => Icons.wb_sunny_outlined,
                'asr' => Icons.light_mode_outlined,
                'maghrib' => Icons.nightlight_outlined,
                _ => Icons.nights_stay_outlined,
              },
              size: 16,
              color: active ? AppColors.emeraldDeep : AppColors.sage,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.key.tr,
                  style: AppTheme.body(
                    14,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                if (active)
                  Text(
                    'currentPrayer'.tr,
                    style: AppTheme.body(
                      10.5,
                      weight: FontWeight.w600,
                      color: AppColors.emeraldDeep,
                    ),
                  ),
              ],
            ),
          ),
          if (isNext)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'nextPrayer'.tr,
                  style: AppTheme.body(
                    9.5,
                    weight: FontWeight.w600,
                    color: AppColors.emerald,
                  ),
                ),
              ),
            ),
          Text(
            DateFormat('h:mm a', locale).format(slot.time),
            style: AppTheme.body(
              13,
              weight: FontWeight.w700,
              color: active ? AppColors.emeraldDeep : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _InspirationCard extends StatelessWidget {
  const _InspirationCard({
    required this.icon,
    required this.label,
    required this.arabic,
  });

  final IconData icon;
  final String label;
  final String arabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: appCardDecoration(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.goldTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: AppColors.gold),
          ),
          const SizedBox(height: 10),
          Text(label, style: AppTheme.body(12.5, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          if (arabic.isNotEmpty)
            Text(
              arabic,
              textDirection: TextDirection.rtl,
              style: AppTheme.quran(13, color: AppColors.sage, height: 1.6),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          else
            Text('·', style: AppTheme.body(12, color: AppColors.sage)),
        ],
      ),
    );
  }
}
