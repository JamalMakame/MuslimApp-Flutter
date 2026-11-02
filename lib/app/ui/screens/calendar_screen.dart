import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../controllers/calendar_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/floating_nav_pill.dart';

/// Hijri calendar — hero date card, dual-numbered month grid, sacred
/// days list, moon-sighting calibration. Reached from the Home header.
class CalendarScreen extends GetView<CalendarController> {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    return Scaffold(
      backgroundColor: AppColors.ivory,
      bottomNavigationBar: const FloatingNavPill(active: 'home'),
      body: SafeArea(
        child: Obx(() {
          final today = controller.todayHijri;
          final phase = controller.moonPhase(today.hDay);
          final locale = settings.localeCode.value;
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 110),
            children: [
              // ---- Context header ------------------------------------------
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: AppColors.emerald),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      settings.placeLabel,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(
                        12,
                        weight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  _RoundBtn(
                    icon: Icons.nights_stay_outlined,
                    tooltip: 'adjustMoon'.tr,
                    onTap: () => Get.dialog(
                      AlertDialog(
                        title: Text('adjustMoon'.tr),
                        content: Text('moonHelp'.tr),
                        actions: [
                          TextButton(
                            onPressed: Get.back,
                            child: Text('done'.tr),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ---- Title row ------------------------------------------------
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'calEyebrow'.tr,
                          style: AppTheme.body(
                            11,
                            weight: FontWeight.w700,
                            color: AppColors.gold,
                          ).copyWith(letterSpacing: 1.4),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'calTitle'.tr,
                          style: AppTheme.headline(24, weight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: controller.resetToToday,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        'today'.tr,
                        style: AppTheme.body(
                          12,
                          weight: FontWeight.w700,
                          color: AppColors.emerald,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ---- Hero date card -------------------------------------------
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.brand, AppColors.brandDeep],
                  ),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.brightness_2,
                                size: 13,
                                color: AppColors.gold,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'moonPhaseFmt'.trParams({'phase': phase.tr}),
                                  style: AppTheme.body(
                                    11,
                                    weight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.95),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'calendarBasis'.tr,
                            style: AppTheme.body(
                              10,
                              weight: FontWeight.w600,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        '${today.hDay} ${controller.monthName(today.hMonth)} ${today.hYear}',
                        style: AppTheme.headline(
                          23,
                          weight: FontWeight.w800,
                          color: const Color(0xFFE5C378),
                        ),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          DateFormat(
                            'EEEE, d MMMM y',
                            locale,
                          ).format(controller.todayGreg),
                          style: AppTheme.body(
                            13,
                            weight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'localCalibration'.tr,
                          style: AppTheme.body(
                            11,
                            weight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: const Color(0xB307362E),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              _StepBtn(
                                label: '-1d',
                                tooltip: 'offsetBack'.tr,
                                onTap: controller.offset.value > -2
                                    ? () => controller.bumpOffset(-1)
                                    : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text(
                                  'offsetCompact'.trParams({
                                    'n': '${controller.offset.value}',
                                  }),
                                  style: AppTheme.body(
                                    11,
                                    weight: FontWeight.w600,
                                    color: const Color(0xFFE5C378),
                                  ),
                                ),
                              ),
                              _StepBtn(
                                label: '+1d',
                                tooltip: 'offsetForward'.tr,
                                onTap: controller.offset.value < 2
                                    ? () => controller.bumpOffset(1)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ---- Month header + chevrons -----------------------------------
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.primary.value == 'hijri'
                              ? controller.viewedMonthTitle
                              : DateFormat('MMMM y', locale).format(
                                  DateTime(
                                    controller.gYear.value,
                                    controller.gMonth.value,
                                  ),
                                ),
                          style: AppTheme.headline(18, weight: FontWeight.w800),
                        ),
                        Text(
                          controller.primary.value == 'hijri'
                              ? controller.gregorianRange
                              : controller.hijriRange,
                          style: AppTheme.body(
                            12,
                            weight: FontWeight.w500,
                            color: AppColors.sage,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _RoundBtn(
                    icon: Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_right
                        : Icons.chevron_left,
                    tooltip: 'previousMonth'.tr,
                    onTap: controller.prevMonth,
                  ),
                  const SizedBox(width: 6),
                  _RoundBtn(
                    icon: Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left
                        : Icons.chevron_right,
                    tooltip: 'nextMonth'.tr,
                    onTap: controller.nextMonth,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ---- Primary toggle --------------------------------------------
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Row(
                  children: [
                    for (final (key, label) in [
                      ('hijri', 'hijriPrimary'.tr),
                      ('gregorian', 'gregorianPrimary'.tr),
                    ])
                      Expanded(
                        child: GestureDetector(
                          onTap: () => controller.setPrimary(key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: controller.primary.value == key
                                  ? AppColors.emerald
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                label,
                                style: AppTheme.body(
                                  13,
                                  weight: FontWeight.w600,
                                  color: controller.primary.value == key
                                      ? Colors.white
                                      : AppColors.sage,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ---- Month grid ------------------------------------------------
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (final l in controller.weekdayLetters())
                          Expanded(
                            child: Center(
                              child: Text(
                                l.toUpperCase(),
                                style: AppTheme.body(
                                  11,
                                  weight: FontWeight.w600,
                                  color: AppColors.sage,
                                ).copyWith(letterSpacing: 0.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 7,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 0.72,
                      mainAxisSpacing: 2,
                      children: [
                        for (final c in controller.cells) _DayCell(cell: c),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(height: 1, color: AppColors.hairline),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _LegendDot(color: AppColors.emerald, filled: true),
                        const SizedBox(width: 5),
                        Text(
                          'currentDay'.tr,
                          style: AppTheme.body(
                            10,
                            weight: FontWeight.w500,
                            color: AppColors.sage,
                          ),
                        ),
                        const _LegendDot(color: AppColors.gold),
                        const SizedBox(width: 5),
                        Text(
                          'whiteDays'.tr,
                          style: AppTheme.body(
                            10,
                            weight: FontWeight.w500,
                            color: AppColors.sage,
                          ),
                        ),
                        if (controller.primary.value == 'hijri')
                          Text(
                            'daysCycle'.tr,
                            style: AppTheme.body(
                              10,
                              weight: FontWeight.w500,
                              color: AppColors.sage,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ---- Upcoming occasions -----------------------------------------
              Text(
                'upcomingOccasions'.tr,
                style: AppTheme.body(
                  11,
                  weight: FontWeight.w700,
                  color: AppColors.sage,
                ).copyWith(letterSpacing: 1.2),
              ),
              const SizedBox(height: 4),
              Text(
                'sacredDays'.tr,
                style: AppTheme.headline(17, weight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              for (final o in controller.occasions.take(4))
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.hairline),
                  ),
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
                          Icons.auto_awesome,
                          size: 17,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.title,
                              style: AppTheme.body(
                                13,
                                weight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              o.subtitle,
                              style: AppTheme.body(11, color: AppColors.sage),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldTint,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          o.daysUntil > 0
                              ? 'inDays'.trParams({'n': '${o.daysUntil}'})
                              : 'upcoming'.tr,
                          style: AppTheme.body(
                            11,
                            weight: FontWeight.w600,
                            color: AppColors.emerald,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'calendarNote'.tr,
                  style: AppTheme.body(11, color: AppColors.sage),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.cell});
  final CalCell cell;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: cell.isToday ? AppColors.emerald : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: cell.isWhite && !cell.isToday
            ? Border.all(color: AppColors.gold.withValues(alpha: 0.45))
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${cell.primary}',
            style: AppTheme.body(
              14,
              weight: FontWeight.w700,
              color: cell.isToday
                  ? Colors.white
                  : cell.inMonth
                  ? AppColors.ink
                  : AppColors.hairline,
            ),
          ),
          Text(
            '${cell.secondary}',
            style: AppTheme.body(
              9,
              color: cell.isToday
                  ? AppColors.goldTint
                  : AppColors.sage.withValues(alpha: cell.inMonth ? 0.7 : 0.3),
            ),
          ),
          const SizedBox(height: 1),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cell.isWhite || cell.isFirst
                  ? AppColors.gold
                  : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, this.filled = false});
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: filled ? color : AppColors.goldTint,
      border: Border.all(color: color),
    ),
  );
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onTap,
    style: IconButton.styleFrom(
      backgroundColor: AppColors.surface,
      shape: CircleBorder(side: BorderSide(color: AppColors.hairline)),
      minimumSize: const Size(44, 44),
    ),
    icon: Icon(icon, size: 19, color: AppColors.sage),
  );
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.label,
    required this.tooltip,
    required this.onTap,
  });
  final String label;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Semantics(
      label: tooltip,
      button: true,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Text(
              label,
              style: AppTheme.body(
                11,
                weight: FontWeight.w600,
                color: onTap == null
                    ? Colors.white38
                    : Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
