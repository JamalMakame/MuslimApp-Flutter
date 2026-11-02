import 'dart:math' as math;

import 'package:get/get.dart';

import 'storage_service.dart';

/// A plan to read the whole Quran (604 pages) in [days] days from [start].
class Khatmah {
  const Khatmah(this.start, this.days, this.done);
  final DateTime start;
  final int days;

  /// Pages read since the plan started.
  final Set<int> done;

  static const pages = 604;

  /// First and last page of day [day] (0-based) of an [days]-day plan.
  static (int, int) portion(int day, int days) =>
      (pages * day ~/ days + 1, pages * (day + 1) ~/ days);

  /// Today's day of the plan, 0-based and clamped to the plan.
  int dayIndex(DateTime today) =>
      HabitService.daysBetween(start, today).clamp(0, days - 1);

  (int, int) todayPortion(DateTime today) => portion(dayIndex(today), days);

  bool get complete => done.length >= pages;

  /// The first unread page up to the end of today's portion (so a missed
  /// day is caught up first); null when the plan is on track for today.
  int? nextPage(DateTime today) {
    final end = todayPortion(today).$2;
    for (var p = 1; p <= end; p++) {
      if (!done.contains(p)) return p;
    }
    return null;
  }

  /// Pages still to read to be on track by the end of today.
  int remainingToday(DateTime today) {
    final end = todayPortion(today).$2;
    var n = 0;
    for (var p = 1; p <= end; p++) {
      if (!done.contains(p)) n++;
    }
    return n;
  }
}

/// Memorisation state of one ayah: [level] successful reviews in a row and
/// the [next] day it is due for review.
class HifzEntry {
  const HifzEntry(this.level, this.next);
  final int level;
  final DateTime next;
  bool get memorised => level > 0;
}

/// Reading habits and memorisation progress, all on-device: pages read per
/// day (daily goal and streak), the Khatmah plan, the daily reading
/// reminder time, and a spaced-review list of memorised ayahs.
class HabitService {
  HabitService._();
  static final HabitService instance = HabitService._();

  final _s = StorageService.instance;

  /// Bumped on every change so `Obx` widgets rebuild.
  final version = 0.obs;

  /// Minutes after midnight for the daily reading reminder; -1 = off.
  late final readReminder = _s.readInt(StorageService.kReadReminder, -1).obs;

  static const goals = [0, 1, 2, 4, 5, 10, 20];
  static const planLengths = [7, 10, 15, 20, 30, 60];

  /// Days until the next review after the n-th success in a row.
  static const intervals = [1, 3, 7, 14, 30, 60];

  static String key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime parse(String s) {
    final p = s.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }

  /// Calendar days from [a] to [b], ignoring the time of day and DST.
  static int daysBetween(DateTime a, DateTime b) => DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

  static DateTime _date(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Days in a row ending today (or yesterday, while today is still open)
  /// on which at least max([goal], 1) pages were read.
  static int streak(Map<String, int> pagesPerDay, DateTime today, int goal) {
    final target = math.max(goal, 1);
    bool met(DateTime d) => (pagesPerDay[key(d)] ?? 0) >= target;
    var d = _date(today);
    if (!met(d)) d = DateTime(d.year, d.month, d.day - 1);
    var n = 0;
    while (met(d)) {
      n++;
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return n;
  }

  void _bump() => version.value++;

  /// Resets in-memory state after local data was erased.
  void reset() {
    readReminder.value = -1;
    _bump();
  }

  // ---- Reading log ---------------------------------------------------------

  Map<String, Set<int>> get _log {
    final raw = _s.read<Map>(StorageService.kReadLog) ?? const {};
    return {
      for (final e in raw.entries)
        '${e.key}': {
          for (final p in (e.value as List? ?? const []))
            if (p is num) p.toInt(),
        },
    };
  }

  /// Pages read per day, by [key].
  Map<String, int> get pagesPerDay => {
    for (final e in _log.entries) e.key: e.value.length,
  };

  int pagesOn(DateTime d) => _log[key(d)]?.length ?? 0;

  /// Counts [page] as read today (once per day) and towards the Khatmah.
  Future<void> recordPage(int page, [DateTime? now]) async {
    if (page < 1 || page > Khatmah.pages) return;
    final today = now ?? DateTime.now();
    final log = _log;
    final day = log.putIfAbsent(key(today), () => <int>{});
    var changed = day.add(page);
    if (changed) {
      final oldest = _date(today).subtract(const Duration(days: 400));
      log.removeWhere((k, _) => parse(k).isBefore(oldest));
      await _s.write(StorageService.kReadLog, {
        for (final e in log.entries) e.key: e.value.toList()..sort(),
      });
    }
    final plan = khatmah;
    if (plan != null && !plan.done.contains(page)) {
      await _writeKhatmah(Khatmah(plan.start, plan.days, {...plan.done, page}));
      changed = true;
    }
    if (changed) _bump();
  }

  int get goal => _s.readInt(StorageService.kReadGoal);

  Future<void> setGoal(int pages) async {
    await _s.write(StorageService.kReadGoal, pages);
    _bump();
  }

  int currentStreak([DateTime? now]) =>
      streak(pagesPerDay, now ?? DateTime.now(), goal);

  // ---- Khatmah ---------------------------------------------------------------

  Khatmah? get khatmah {
    final raw = _s.read<Map>(StorageService.kKhatmah);
    if (raw == null || raw['start'] is! String || raw['days'] is! num) {
      return null;
    }
    return Khatmah(
      parse(raw['start'] as String),
      (raw['days'] as num).toInt(),
      {
        for (final p in (raw['done'] as List? ?? const []))
          if (p is num) p.toInt(),
      },
    );
  }

  Future<void> _writeKhatmah(Khatmah k) => _s.write(StorageService.kKhatmah, {
    'start': key(k.start),
    'days': k.days,
    'done': k.done.toList()..sort(),
  });

  Future<void> startKhatmah(int days, [DateTime? now]) async {
    await _writeKhatmah(Khatmah(_date(now ?? DateTime.now()), days, const {}));
    _bump();
  }

  Future<void> stopKhatmah() async {
    await _s.remove(StorageService.kKhatmah);
    _bump();
  }

  // ---- Reading reminder ------------------------------------------------------

  Future<void> setReadReminder(int minutes) async {
    readReminder.value = minutes;
    await _s.write(StorageService.kReadReminder, minutes);
  }

  // ---- Memorisation ----------------------------------------------------------

  Map<String, HifzEntry> get hifz {
    final raw = _s.read<Map>(StorageService.kHifz) ?? const {};
    final out = <String, HifzEntry>{};
    for (final e in raw.entries) {
      final v = e.value;
      if (v is Map && v['l'] is num && v['d'] is String) {
        out['${e.key}'] = HifzEntry(
          (v['l'] as num).toInt(),
          parse(v['d'] as String),
        );
      }
    }
    return out;
  }

  HifzEntry? hifzOf(int surah, int ayah) => hifz['$surah:$ayah'];

  /// Records a self-test: [ok] moves the ayah one step along [intervals];
  /// otherwise it is due again tomorrow and starts over.
  Future<void> markHifz(int surah, int ayah, bool ok, [DateTime? now]) async {
    final today = _date(now ?? DateTime.now());
    final all = hifz;
    final k = '$surah:$ayah';
    final level = ok ? math.min((all[k]?.level ?? 0) + 1, intervals.length) : 0;
    final wait = ok ? intervals[level - 1] : 1;
    all[k] = HifzEntry(
      level,
      DateTime(today.year, today.month, today.day + wait),
    );
    await _writeHifz(all);
  }

  Future<void> forgetHifz(int surah, int ayah) async {
    final all = hifz..remove('$surah:$ayah');
    await _writeHifz(all);
  }

  Future<void> _writeHifz(Map<String, HifzEntry> all) async {
    await _s.write(StorageService.kHifz, {
      for (final e in all.entries)
        e.key: {'l': e.value.level, 'd': key(e.value.next)},
    });
    _bump();
  }

  /// Memorised ayahs per surah.
  Map<int, int> get memorisedPerSurah {
    final out = <int, int>{};
    for (final e in hifz.entries) {
      if (!e.value.memorised) continue;
      final s = int.parse(e.key.split(':').first);
      out[s] = (out[s] ?? 0) + 1;
    }
    return out;
  }

  int get memorisedTotal => hifz.values.where((e) => e.memorised).length;

  /// Ayahs due for review on or before [today], oldest first.
  List<(int, int)> dueOn(DateTime today) {
    final d = _date(today);
    final due = [
      for (final e in hifz.entries)
        if (!e.value.next.isAfter(d)) (e.key, e.value.next),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    return [
      for (final (k, _) in due)
        (int.parse(k.split(':')[0]), int.parse(k.split(':')[1])),
    ];
  }
}
