import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../services/prayer_log_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/celebration.dart';

/// Tips for the prayer missed most, then general ones (i18n keys).
const prayerTips = {
  'fajr': ['tipFajr1', 'tipFajr2', 'tipFajr3'],
  'dhuhr': ['tipDhuhr1', 'tipDhuhr2'],
  'asr': ['tipAsr1', 'tipAsr2'],
  'maghrib': ['tipMaghrib1', 'tipMaghrib2'],
  'isha': ['tipIsha1', 'tipIsha2'],
};
const generalTips = ['tipGeneral1', 'tipGeneral2'];

/// The message for [stats] (i18n already applied).
String standingMessage(PrayerStats stats) {
  final params = {
    'pct': '${(stats.rate * 100).round()}',
    'n': '${stats.missed}',
    'd': '${stats.days}',
    'prayer': (stats.weakest ?? 'fajr').tr,
  };
  return switch (stats.standing) {
    PrayerStanding.none => 'standingNone'.tr,
    PrayerStanding.strong => 'standingStrong'.trParams(params),
    PrayerStanding.steady => 'standingSteady'.trParams(params),
    PrayerStanding.slipping => 'standingSlipping'.trParams(params),
    PrayerStanding.struggling => 'standingStruggling'.trParams(params),
  };
}

/// Toggles [prayer] on [day] and celebrates when that completes the day.
Future<void> togglePrayer(
  BuildContext context,
  DateTime day,
  String prayer,
) async {
  final done = await PrayerLogService.instance.toggle(day, prayer);
  if (done && context.mounted) celebrate(context, 'allFiveDone'.tr);
}

/// Daily check-off of the five prayers, with history, streaks, per-prayer
/// consistency, and encouragement or a warning with tips.
class PrayerTrackerScreen extends StatefulWidget {
  const PrayerTrackerScreen({super.key});

  @override
  State<PrayerTrackerScreen> createState() => _PrayerTrackerScreenState();
}

class _PrayerTrackerScreenState extends State<PrayerTrackerScreen> {
  var _dayOffset = 0;
  var _period = 7;

  @override
  Widget build(BuildContext context) {
    final log = PrayerLogService.instance;
    final locale = Get.locale?.languageCode ?? 'en';
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(title: Text('prayerTracker'.tr)),
      body: Obx(() {
        log.version.value;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final day = DateTime(today.year, today.month, today.day - _dayOffset);
        final prayed = log.prayedOn(day);
        final stats = log.stats(_period, now);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                reverse: true,
                itemCount: 7,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final d = DateTime(today.year, today.month, today.day - i);
                  final n = log.prayedOn(d).length;
                  final selected = i == _dayOffset;
                  return GestureDetector(
                    key: ValueKey('tracker-day-$i'),
                    onTap: () => setState(() => _dayOffset = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 54,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.brand : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: n == 5 ? AppColors.gold : AppColors.hairline,
                          width: n == 5 ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            i == 0
                                ? 'today'.tr
                                : DateFormat('EEE', locale).format(d),
                            style: AppTheme.body(
                              11,
                              weight: FontWeight.w600,
                              color: selected ? Colors.white : AppColors.sage,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$n/5',
                            style: AppTheme.body(
                              14,
                              weight: FontWeight.w800,
                              color: selected ? Colors.white : AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _dayOffset == 0
                              ? 'didYouPrayToday'.tr
                              : DateFormat('EEE, d MMM y', locale).format(day),
                          style: AppTheme.headline(16),
                        ),
                      ),
                      Text(
                        '${prayed.length}/5',
                        key: const ValueKey('tracker-count'),
                        style: AppTheme.headline(16, color: AppColors.emerald),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final p in PrayerLogService.prayers)
                    PrayerCheckTile(
                      key: ValueKey('track-$p'),
                      prayer: p,
                      prayed: prayed.contains(p),
                      onTap: () => togglePrayer(context, day, p),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _InsightCard(stats: stats),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('howYouAreDoing'.tr, style: AppTheme.headline(16)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      SegmentedButton<int>(
                        key: const ValueKey('tracker-period'),
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(value: 7, label: Text('days7'.tr)),
                          ButtonSegment(value: 30, label: Text('days30'.tr)),
                        ],
                        selected: {_period},
                        onSelectionChanged: (s) =>
                            setState(() => _period = s.first),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _Stat(
                        key: const ValueKey('tracker-streak'),
                        value: '${log.streak(now)}',
                        label: 'streakLabel'.tr,
                        icon: Icons.local_fire_department,
                      ),
                      _Stat(
                        value: '${log.bestStreak()}',
                        label: 'bestStreak'.tr,
                        icon: Icons.emoji_events_outlined,
                      ),
                      _Stat(
                        value: '${stats.fullDays}/${stats.days}',
                        label: 'fullDays'.tr,
                        icon: Icons.check_circle_outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final p in PrayerLogService.prayers)
                    _RateBar(
                      key: ValueKey('rate-$p'),
                      label: p.tr,
                      rate: stats.rateOf(p),
                      empty: stats.days == 0,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('last5Weeks'.tr, style: AppTheme.headline(16)),
                  const SizedBox(height: 10),
                  _History(
                    today: today,
                    selected: _dayOffset,
                    onSelect: (i) => setState(() => _dayOffset = i),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.hairline),
    ),
    child: child,
  );
}

/// One prayer with an animated check circle.
class PrayerCheckTile extends StatelessWidget {
  const PrayerCheckTile({
    super.key,
    required this.prayer,
    required this.prayed,
    required this.onTap,
  });
  final String prayer;
  final bool prayed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              prayer.tr,
              style: AppTheme.body(
                15,
                weight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          PrayedCheck(prayed: prayed),
        ],
      ),
    ),
  );
}

/// A check circle that pops when marked.
class PrayedCheck extends StatelessWidget {
  const PrayedCheck({super.key, required this.prayed, this.size = 30});
  final bool prayed;
  final double size;

  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: prayed ? 1.0 : 0.9,
    duration: const Duration(milliseconds: 250),
    curve: Curves.elasticOut,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: prayed ? AppColors.emerald : Colors.transparent,
        border: Border.all(
          color: prayed ? AppColors.emerald : AppColors.hairline,
          width: 2,
        ),
      ),
      child: prayed
          ? Icon(Icons.check, size: size * 0.6, color: Colors.white)
          : null,
    ),
  );
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.stats});
  final PrayerStats stats;

  @override
  Widget build(BuildContext context) {
    final standing = stats.standing;
    final warn =
        standing == PrayerStanding.slipping ||
        standing == PrayerStanding.struggling;
    final good =
        standing == PrayerStanding.strong || standing == PrayerStanding.steady;
    final weakest = stats.weakest;
    final tips = [
      if (weakest != null && standing != PrayerStanding.strong)
        ...prayerTips[weakest]!,
      if (warn) ...generalTips,
    ];
    final color = warn
        ? const Color(0xFFB4462F)
        : good
        ? AppColors.emerald
        : AppColors.sage;
    return Container(
      key: const ValueKey('tracker-insight'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                warn
                    ? Icons.warning_amber_rounded
                    : good
                    ? Icons.auto_awesome
                    : Icons.info_outline,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  warn
                      ? 'standingWarnTitle'.tr
                      : good
                      ? 'standingGoodTitle'.tr
                      : 'prayerTracker'.tr,
                  style: AppTheme.headline(15, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            standingMessage(stats),
            key: const ValueKey('tracker-message'),
            style: AppTheme.body(13.5, color: AppColors.ink),
          ),
          if (tips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'waysToImprove'.tr,
              style: AppTheme.body(
                12,
                weight: FontWeight.w700,
                color: AppColors.sage,
              ),
            ),
            for (final t in tips)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        t.tr,
                        key: ValueKey('tip-$t'),
                        style: AppTheme.body(13, color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
  });
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: AppColors.gold, size: 20),
        const SizedBox(height: 4),
        Text(value, style: AppTheme.headline(18)),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTheme.body(11, color: AppColors.sage),
        ),
      ],
    ),
  );
}

class _RateBar extends StatelessWidget {
  const _RateBar({
    super.key,
    required this.label,
    required this.rate,
    required this.empty,
  });
  final String label;
  final double rate;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    final color = rate >= 0.9
        ? AppColors.emerald
        : rate >= 0.6
        ? AppColors.gold
        : const Color(0xFFB4462F);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: AppTheme.body(
                13,
                weight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: empty ? 0 : rate),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 10,
                  color: color,
                  backgroundColor: AppColors.hairline,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              empty ? '–' : '${(rate * 100).round()}%',
              textAlign: TextAlign.end,
              style: AppTheme.body(
                13,
                weight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The last 35 days, oldest first, shaded by how many prayers were marked;
/// tapping one opens it for marking.
class _History extends StatelessWidget {
  const _History({
    required this.today,
    required this.selected,
    required this.onSelect,
  });
  final DateTime today;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final log = PrayerLogService.instance;
    return GridView.count(
      key: const ValueKey('tracker-history'),
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: [
        for (var i = 34; i >= 0; i--)
          Builder(
            builder: (_) {
              final d = DateTime(today.year, today.month, today.day - i);
              final n = log.prayedOn(d).length;
              return GestureDetector(
                key: ValueKey('tracker-history-$i'),
                onTap: () => onSelect(i),
                child: Container(
                  decoration: BoxDecoration(
                    color: n == 0
                        ? AppColors.hairline.withValues(alpha: 0.5)
                        : AppColors.emerald.withValues(alpha: 0.2 + n * 0.16),
                    borderRadius: BorderRadius.circular(6),
                    border: i == selected
                        ? Border.all(color: AppColors.ink, width: 2)
                        : i == 0
                        ? Border.all(color: AppColors.gold)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${d.day}',
                    style: AppTheme.body(
                      10,
                      color: n >= 4 ? Colors.white : AppColors.sage,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
