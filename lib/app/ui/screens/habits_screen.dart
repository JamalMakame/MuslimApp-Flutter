import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_pages.dart';
import '../../services/habit_service.dart';
import '../../services/quran_service.dart';
import '../../theme/app_theme.dart';

/// Opens the reader at the start of [page].
void openPage(int page) {
  final at = QuranService.instance.pageStart(page);
  if (at != null) openQuranAt(at.$1, at.$2);
}

String _time(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
    '${(minutes % 60).toString().padLeft(2, '0')}';

/// Daily goal and streak, the Khatmah plan, the reading reminder and
/// memorisation progress.
class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final h = HabitService.instance;
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(title: Text('habits'.tr)),
      body: Obx(() {
        h.version.value;
        final today = DateTime.now();
        final goal = h.goal;
        final read = h.pagesOn(today);
        final plan = h.khatmah;
        final due = h.dueOn(today);
        final perSurah = h.memorisedPerSurah.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        final quran = QuranService.instance;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Section(
              title: 'readingGoal'.tr,
              children: [
                Text(
                  goal > 0
                      ? 'todayPages'.trParams({'n': '$read', 'g': '$goal'})
                      : 'todayPagesNoGoal'.trParams({'n': '$read'}),
                  key: const ValueKey('habits-today'),
                  style: AppTheme.body(14, weight: FontWeight.w700),
                ),
                Text(
                  'streakDays'.trParams({'n': '${h.currentStreak(today)}'}),
                  style: AppTheme.body(12, color: AppColors.sage),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final g in HabitService.goals)
                      ChoiceChip(
                        key: ValueKey('goal-$g'),
                        label: Text(
                          g == 0
                              ? 'goalOff'.tr
                              : 'pagesN'.trParams({'n': '$g'}),
                        ),
                        selected: g == goal,
                        onSelected: (_) => h.setGoal(g),
                      ),
                  ],
                ),
              ],
            ),
            _Section(
              title: 'khatmah'.tr,
              children: [
                if (plan == null) ...[
                  Text(
                    'khatmahPick'.tr,
                    style: AppTheme.body(12, color: AppColors.sage),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final d in HabitService.planLengths)
                        ActionChip(
                          key: ValueKey('plan-$d'),
                          label: Text('daysN'.trParams({'n': '$d'})),
                          onPressed: () => h.startKhatmah(d),
                        ),
                    ],
                  ),
                ] else ...[
                  Text(
                    'khatmahDay'.trParams({
                      'd': '${plan.dayIndex(today) + 1}',
                      'n': '${plan.days}',
                    }),
                    key: const ValueKey('khatmah-day'),
                    style: AppTheme.body(14, weight: FontWeight.w700),
                  ),
                  Text(
                    'portionPages'.trParams({
                      'a': '${plan.todayPortion(today).$1}',
                      'b': '${plan.todayPortion(today).$2}',
                    }),
                    style: AppTheme.body(12, color: AppColors.sage),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: plan.done.length / Khatmah.pages,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(99),
                    color: AppColors.emerald,
                    backgroundColor: AppColors.hairline,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'pagesDone'.trParams({'n': '${plan.done.length}'}),
                    style: AppTheme.body(12, color: AppColors.sage),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan.complete
                        ? 'khatmahDone'.tr
                        : plan.nextPage(today) == null
                        ? 'onTrack'.tr
                        : 'remainingPages'.trParams({
                            'n': '${plan.remainingToday(today)}',
                          }),
                    style: AppTheme.body(13, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (plan.nextPage(today) case final p?)
                        FilledButton(
                          key: const ValueKey('khatmah-start'),
                          onPressed: () => openPage(p),
                          child: Text('startReading'.tr),
                        ),
                      const Spacer(),
                      TextButton(
                        key: const ValueKey('khatmah-stop'),
                        onPressed: h.stopKhatmah,
                        child: Text('stopPlan'.tr),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            _Section(
              title: 'readReminder'.tr,
              children: [
                SwitchListTile(
                  key: const ValueKey('read-reminder'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    h.readReminder.value < 0
                        ? 'reminderOff'.tr
                        : _time(h.readReminder.value),
                    style: AppTheme.body(14, weight: FontWeight.w600),
                  ),
                  value: h.readReminder.value >= 0,
                  onChanged: (on) async {
                    if (!on) return h.setReadReminder(-1);
                    final t = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 20, minute: 0),
                    );
                    if (t != null) {
                      await h.setReadReminder(t.hour * 60 + t.minute);
                    }
                  },
                ),
              ],
            ),
            _Section(
              title: 'memorisation'.tr,
              children: [
                Text(
                  'memorisedN'.trParams({'n': '${h.memorisedTotal}'}),
                  key: const ValueKey('memorised-total'),
                  style: AppTheme.body(14, weight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'reviewDue'.tr,
                  style: AppTheme.body(12, color: AppColors.sage),
                ),
                if (due.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text('noReviewDue'.tr, style: AppTheme.body(13)),
                  ),
                if (quran.isLoaded)
                  for (final (s, a) in due.take(_dueInline)) _DueTile(s, a),
                if (quran.isLoaded && due.length > _dueInline)
                  TextButton(
                    key: const ValueKey('due-all'),
                    onPressed: () => Get.bottomSheet(
                      const _DueSheet(),
                      isScrollControlled: true,
                      backgroundColor: AppColors.surface,
                    ),
                    child: Text('allDueN'.trParams({'n': '${due.length}'})),
                  ),
                if (quran.isLoaded)
                  for (final e in perSurah)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        quran.surah(e.key).nameSimple,
                        style: AppTheme.body(13),
                      ),
                      trailing: Text(
                        'memorisedOfN'.trParams({
                          'n': '${e.value}',
                          't': '${quran.surah(e.key).ayahs}',
                        }),
                        style: AppTheme.body(12, color: AppColors.sage),
                      ),
                      onTap: () => Get.toNamed(Routes.memorize(e.key)),
                    ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.body(
              11,
              weight: FontWeight.w700,
              color: AppColors.sage,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );
}

const _dueInline = 20;

class _DueTile extends StatelessWidget {
  const _DueTile(this.surah, this.ayah);
  final int surah;
  final int ayah;

  @override
  Widget build(BuildContext context) => ListTile(
    key: ValueKey('due-$surah-$ayah'),
    contentPadding: EdgeInsets.zero,
    dense: true,
    leading: const Icon(Icons.replay, size: 18),
    title: Text(
      '${QuranService.instance.surah(surah).nameSimple} $surah:$ayah',
      style: AppTheme.body(13, weight: FontWeight.w600),
    ),
    onTap: () => Get.toNamed(Routes.memorize(surah, ayah: ayah)),
  );
}

/// Every due ayah, built lazily so a long backlog stays smooth.
class _DueSheet extends StatelessWidget {
  const _DueSheet();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Obx(() {
        final h = HabitService.instance;
        h.version.value;
        final due = h.dueOn(DateTime.now());
        return ListView.builder(
          key: const ValueKey('due-sheet'),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: due.length,
          itemBuilder: (_, i) => _DueTile(due[i].$1, due[i].$2),
        );
      }),
    ),
  );
}
