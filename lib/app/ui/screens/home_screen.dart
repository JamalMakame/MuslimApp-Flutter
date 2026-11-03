import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../controllers/home_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../data/daily_ayah.dart';
import '../../data/daily_hadith.dart';
import '../../routes/app_pages.dart';
import '../../services/azkar_service.dart';
import '../../services/habit_service.dart';
import '../../services/hijri_date_service.dart';
import '../../services/prayer_log_service.dart';
import '../../services/prayer_service.dart';
import '../../services/quran_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/floating_nav_pill.dart';
import '../widgets/motion.dart';
import 'habits_screen.dart' show openPage;
import 'prayer_tracker_screen.dart';

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
          PrayerLogService.instance.version.value;
          final locale = settings.localeCode.value;
          final now = controller.currentDate.value;
          final hijri = HijriDateService.on(now, controller.hijriOffset.value);
          final hijriLabel =
              '${hijri.hDay} '
              '${HijriDateService.monthName(hijri.hMonth, locale)} '
              '${hijri.hYear}';
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 110),
            children: staggered([
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
                                Icon(
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
                          Icon(
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
                        Icon(
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
                          prayed:
                              PrayerLogService.prayers.contains(
                                day.slots[i].key,
                              )
                              ? PrayerLogService.instance
                                    .prayedOn(day.now)
                                    .contains(day.slots[i].key)
                              : null,
                          onToggle: () =>
                              togglePrayer(context, day.now, day.slots[i].key),
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

              // ---- Prayer tracker -----------------------------------------
              Builder(
                builder: (context) {
                  final log = PrayerLogService.instance;
                  final now = DateTime.now();
                  final n = log.prayedOn(now).length;
                  final stats = log.stats(7, now);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _Card(
                      key: const ValueKey('home-tracker'),
                      onTap: () => Get.toNamed(Routes.prayerTracker),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 42,
                              height: 42,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: n / 5),
                                    duration: const Duration(milliseconds: 500),
                                    builder: (_, v, _) =>
                                        CircularProgressIndicator(
                                          value: v,
                                          strokeWidth: 4,
                                          color: AppColors.emerald,
                                          backgroundColor: AppColors.hairline,
                                        ),
                                  ),
                                  Text(
                                    '$n/5',
                                    style: AppTheme.body(
                                      11,
                                      weight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'prayerTracker'.tr,
                                    style: AppTheme.body(
                                      14,
                                      weight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  Text(
                                    '${'streakDays'.trParams({'n': '${log.streak(now)}'})} · ${switch (stats.standing) {
                                      PrayerStanding.strong || PrayerStanding.steady => 'standingGoodTitle'.tr,
                                      PrayerStanding.slipping || PrayerStanding.struggling => 'standingWarnTitle'.tr,
                                      PrayerStanding.none => 'didYouPrayToday'.tr,
                                    }}',
                                    style: AppTheme.body(
                                      12,
                                      color: AppColors.sage,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: AppColors.sage),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // ---- Continue reading ---------------------------------------
              Obx(() {
                final quran = QuranService.instance;
                final last = quran.lastReadRx.value;
                if (last == null || !quran.isLoaded) {
                  return const SizedBox.shrink();
                }
                final surah = quran.surah(last.$1);
                final at = quran.ayahAt(last.$1, last.$2);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _Card(
                    key: const ValueKey('home-continue'),
                    onTap: () =>
                        Get.toNamed(Routes.reader(last.$1, ayah: last.$2)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.goldTint,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.menu_book,
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
                                  'continueReading'.tr,
                                  style: AppTheme.body(
                                    9.5,
                                    weight: FontWeight.w700,
                                    color: AppColors.sage,
                                    letterSpacing: 0.9,
                                  ),
                                ),
                                Text(
                                  '${surah.nameSimple}, ${'ayahN'.trParams({'n': '${last.$2}'})}',
                                  style: AppTheme.body(
                                    13.5,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${'juz'.tr} ${at?.juz ?? surah.juzStart} · ${'page'.tr} ${at?.page ?? last.$3}',
                                  style: AppTheme.body(
                                    11.5,
                                    color: AppColors.sage,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'resume'.tr,
                            style: AppTheme.body(
                              12,
                              weight: FontWeight.w700,
                              color: AppColors.emerald,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.emerald,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // ---- Reading habits -----------------------------------------
              Obx(() {
                final h = HabitService.instance;
                h.version.value;
                final today = DateTime.now();
                final plan = h.khatmah;
                final goal = h.goal;
                final read = h.pagesOn(today);
                final next = plan?.nextPage(today);
                final portion = plan?.todayPortion(today);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _Card(
                    key: const ValueKey('home-habits'),
                    onTap: () => Get.toNamed(Routes.habits),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.goldTint,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.local_fire_department,
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
                                  '${goal > 0 ? 'todayPages'.trParams({'n': '$read', 'g': '$goal'}) : 'todayPagesNoGoal'.trParams({'n': '$read'})} · ${'streakDays'.trParams({'n': '${h.currentStreak(today)}'})}',
                                  style: AppTheme.body(
                                    13.5,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  plan == null
                                      ? 'habitsSetup'.tr
                                      : plan.complete
                                      ? 'khatmahDone'.tr
                                      : '${'khatmahDay'.trParams({'d': '${plan.dayIndex(today) + 1}', 'n': '${plan.days}'})} · ${'portionPages'.trParams({'a': '${portion!.$1}', 'b': '${portion.$2}'})}',
                                  style: AppTheme.body(
                                    11.5,
                                    color: AppColors.sage,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (next != null)
                            TextButton(
                              key: const ValueKey('home-khatmah-start'),
                              onPressed: () => openPage(next),
                              child: Text('startReading'.tr),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

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
                        decoration: BoxDecoration(
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
                      Icon(
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
                    child: Builder(
                      builder: (_) {
                        final quran = QuranService.instance;
                        final (s, a) = pickForDay(
                          dailyAyahs,
                          controller.currentDate.value,
                        );
                        final ayah = quran.isLoaded ? quran.ayahAt(s, a) : null;
                        return _InspirationCard(
                          key: const ValueKey('ayah-of-day'),
                          icon: Icons.auto_stories,
                          label: 'ayahOfDay'.tr,
                          arabic: ayah == null ? '' : '﴿${ayah.text}﴾',
                          onTap: ayah == null
                              ? null
                              : () => Get.toNamed(Routes.reader(s, ayah: a)),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Builder(
                      builder: (_) {
                        final h = pickForDay(
                          dailyHadith,
                          controller.currentDate.value,
                        );
                        return _InspirationCard(
                          key: const ValueKey('hadith-of-day'),
                          icon: Icons.format_quote,
                          label: 'hadithOfDay'.tr,
                          arabic: h.text,
                          reference: h.reference,
                          more: ('hadithLibrary'.tr, Routes.hadith),
                        );
                      },
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
                    child: Builder(
                      builder: (_) {
                        final pool = AzkarService.instance.dailyDuaPool;
                        final d = pool.isEmpty
                            ? null
                            : pickForDay(pool, controller.currentDate.value);
                        return _InspirationCard(
                          key: const ValueKey('dua-of-day'),
                          icon: Icons.volunteer_activism,
                          label: 'duaOfDay'.tr,
                          arabic: d?.zekr ?? '',
                          reference: d?.reference ?? '',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ]),
          );
        }),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(decoration: appCardDecoration(), child: child),
      ),
    );
    return onTap == null ? card : Pressable(child: card);
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
          colors: [AppColors.brand, AppColors.brandDeep],
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
                      color: AppColors.onBrand.withValues(alpha: 0.75),
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
                  color: AppColors.onBrand.withValues(alpha: 0.85),
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
                    Icon(
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
    required this.prayed,
    required this.onToggle,
    required this.slot,
    required this.isCurrent,
    required this.isNext,
    required this.locale,
  });

  /// Whether it was marked prayed today; null for sunrise.
  final bool? prayed;
  final VoidCallback onToggle;
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
          if (prayed != null) ...[
            const SizedBox(width: 10),
            Semantics(
              button: true,
              label: 'markPrayed'.tr,
              child: GestureDetector(
                key: ValueKey('home-prayed-${slot.key}'),
                behavior: HitTestBehavior.opaque,
                onTap: onToggle,
                child: PrayedCheck(prayed: prayed!, size: 26),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InspirationCard extends StatelessWidget {
  const _InspirationCard({
    super.key,
    required this.icon,
    required this.label,
    required this.arabic,
    this.reference = '',
    this.onTap,
    this.more,
  });

  /// An extra dialog action: (label, route).
  final (String, String)? more;
  final IconData icon;
  final String label;
  final String arabic;
  final String reference;

  /// Replaces the default "show in a dialog".
  final VoidCallback? onTap;

  void _open() => Get.dialog(
    AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(label, style: AppTheme.headline(16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              arabic,
              textDirection: TextDirection.rtl,
              style: AppTheme.quran(19, height: 1.9),
            ),
            if (reference.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                reference,
                textDirection: TextDirection.rtl,
                style: AppTheme.body(12, color: AppColors.sage),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (more != null)
          TextButton(
            key: const ValueKey('dialog-more'),
            onPressed: () {
              Get.back();
              Get.toNamed(more!.$2);
            },
            child: Text(more!.$1, style: AppTheme.body(13)),
          ),
        TextButton(
          onPressed: Get.back,
          child: Text('done'.tr, style: AppTheme.body(13)),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: arabic.isEmpty ? null : (onTap ?? _open),
      child: Container(
        decoration: appCardDecoration(),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
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
      ),
    );
  }
}
