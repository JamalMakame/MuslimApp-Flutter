import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:hijri/hijri_calendar.dart';

import '../../controllers/settings_controller.dart';
import '../../controllers/tasbeeh_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/floating_nav_pill.dart';

/// Tasbeeh — phrase display, large tap dial w/ gold progress ring,
/// phrase chips, goal/lap cards, daily total + streak footer.
class TasbeehScreen extends GetView<TasbeehController> {
  const TasbeehScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      bottomNavigationBar: const FloatingNavPill(active: 'azkar'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 110),
          children: [
            // Header
            Row(
              children: [
                _RoundIconBtn(icon: Icons.arrow_back, onTap: Get.back),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'tasbeeh'.tr,
                        style: AppTheme.headline(18, weight: FontWeight.w800),
                      ),
                      Text(
                        'tapCircle'.tr,
                        style: AppTheme.body(11.5, color: AppColors.sage),
                      ),
                    ],
                  ),
                ),
                Obx(
                  () => _RoundIconBtn(
                    icon: Icons.vibration,
                    color: controller.haptics.value
                        ? AppColors.emerald
                        : AppColors.sage,
                    onTap: () => controller.toggleHaptics(),
                  ),
                ),
                const SizedBox(width: 8),
                _RoundIconBtn(icon: Icons.history, onTap: () {}),
              ],
            ),
            const SizedBox(height: 18),

            // Ornament + phrase
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 1,
                  color: AppColors.gold.withValues(alpha: 0.6),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.star, size: 12, color: AppColors.gold),
                ),
                Container(
                  width: 32,
                  height: 1,
                  color: AppColors.gold.withValues(alpha: 0.6),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Obx(
              () => Column(
                children: [
                  Text(
                    controller.phrase.key.tr,
                    style: AppTheme.headline(22, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.phrase.arabic,
                    textDirection: TextDirection.rtl,
                    style: AppTheme.quran(
                      30,
                      weight: FontWeight.w700,
                      color: AppColors.emerald,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${controller.phrase.transliteration} · ‘${controller.phrase.meaningKey.tr}’',
                    style: AppTheme.body(
                      12,
                      color: AppColors.sage,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dial
            Center(
              child: Obx(
                () => GestureDetector(
                  onTap: controller.tap,
                  child: _TapDial(
                    progress: controller.progress,
                    count: controller.count.value,
                    target: controller.target.value,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Step / reset row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TextAction(
                  icon: Icons.remove,
                  label: 'oneStep'.tr,
                  onTap: () {
                    if (controller.count.value > 0) {
                      controller.tap();
                    }
                  },
                ),
                Container(
                  width: 1,
                  height: 16,
                  color: AppColors.hairline,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                _TextAction(
                  icon: Icons.replay,
                  label: 'reset'.tr,
                  onTap: controller.reset,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Phrase selector
            Row(
              children: [
                Text(
                  'selectRecitation'.tr,
                  style: AppTheme.body(
                    10.5,
                    weight: FontWeight.w700,
                    color: AppColors.sage,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                Text(
                  'duasCount'.trParams({
                    'count': '${TasbeehController.phrases.length}',
                  }),
                  style: AppTheme.body(10.5, color: AppColors.sage),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Obx(() {
              // Register the dep in this builder's scope — reads inside
              // itemBuilder happen lazily at layout and don't register.
              final selected = controller.phraseIndex.value;
              return SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: TasbeehController.phrases.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final sel = selected == i;
                    return GestureDetector(
                      onTap: () => controller.selectPhrase(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: sel ? AppColors.emerald : AppColors.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: sel ? AppColors.emerald : AppColors.hairline,
                          ),
                        ),
                        child: Text(
                          TasbeehController.phrases[i].key.tr,
                          style: AppTheme.body(
                            12.5,
                            weight: FontWeight.w600,
                            color: sel ? Colors.white : AppColors.ink,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
            const SizedBox(height: 16),

            // Goal + completed cards
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => _StatCard(
                      icon: Icons.adjust_outlined,
                      label: 'goal'.tr,
                      value: '${controller.target.value} ${'counts'.tr}',
                      trailing: IconButton(
                        icon: Icon(
                          Icons.swap_vert,
                          size: 16,
                          color: AppColors.sage,
                        ),
                        onPressed: controller.cycleTarget,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Obx(
                    () => _StatCard(
                      icon: Icons.repeat,
                      label: 'completedT'.tr,
                      value: 'lapN'.trParams({
                        'n': '${controller.lap.value}',
                        'total':
                            '${(controller.lap.value - 1) * controller.target.value + controller.count.value}',
                      }),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Daily total + streak
            Container(
              decoration: appCardDecoration(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.goldTint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bolt,
                      size: 18,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'totalDhikrToday'.trParams({
                              'count': '${controller.totalToday.value}',
                            }),
                            style: AppTheme.body(13, weight: FontWeight.w700),
                          ),
                          Text(
                            '${DateFormat('EEE d MMM y', Get.find<SettingsController>().localeCode.value).format(DateTime.now())} · ${HijriCalendar.now().toFormat('d MMMM yyyy')}',
                            style: AppTheme.body(10.5, color: AppColors.sage),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Obx(
                    () => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.goldTint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.wb_sunny,
                            size: 14,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'dayStreak'.trParams({
                              'n': '${controller.streak.value}',
                            }),
                            style: AppTheme.body(
                              11,
                              weight: FontWeight.w700,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TapDial extends StatelessWidget {
  const _TapDial({
    required this.progress,
    required this.count,
    required this.target,
  });

  final double progress;
  final int count;
  final int target;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 236,
      height: 236,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pedestal
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.hairline),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A0A4A3F),
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
          ),
          // Inner star motif
          Icon(
            Icons.star_purple500_outlined,
            size: 150,
            color: AppColors.emeraldDeep.withValues(alpha: 0.05),
          ),
          // Rings
          CustomPaint(
            size: const Size(216, 216),
            painter: _DialPainter(progress),
          ),
          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: AppTheme.headline(
                  58,
                  weight: FontWeight.w800,
                  color: AppColors.emerald,
                ),
              ),
              Text(
                'ofTarget'.trParams({'target': '$target'}),
                style: AppTheme.body(
                  10.5,
                  weight: FontWeight.w700,
                  color: AppColors.sage,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.goldTint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'tap'.tr,
                      style: AppTheme.body(
                        10,
                        weight: FontWeight.w700,
                        color: AppColors.gold,
                        letterSpacing: 1.2,
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

class _DialPainter extends CustomPainter {
  _DialPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const r = 96.0;

    // Track
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = AppColors.hairline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // Dashed guide ring
    canvas.drawCircle(
      c,
      r - 8,
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round,
    );

    // Gold progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = AppColors.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) => old.progress != progress;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: appCardDecoration(),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.goldTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: AppColors.gold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.body(
                    9.5,
                    weight: FontWeight.w700,
                    color: AppColors.sage,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTheme.headline(13, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({
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
          Icon(icon, size: 15, color: AppColors.sage),
          const SizedBox(width: 5),
          Text(label, style: AppTheme.body(12, color: AppColors.sage)),
        ],
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
        child: Icon(icon, size: 17, color: color ?? AppColors.ink),
      ),
    );
  }
}
