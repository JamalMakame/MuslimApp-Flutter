import 'package:get/get.dart';

import 'habit_service.dart';
import 'storage_service.dart';

/// How regularly the five prayers were marked over a period.
enum PrayerStanding { none, strong, steady, slipping, struggling }

/// Marked prayers over [days] days: up to today once all five are marked,
/// otherwise up to yesterday, so a day in progress never lowers the numbers.
class PrayerStats {
  const PrayerStats(this.days, this.perPrayer, this.fullDays);
  final int days;
  final Map<String, int> perPrayer;
  final int fullDays;

  int get prayed => perPrayer.values.fold(0, (a, b) => a + b);
  int get missed => days * 5 - prayed;
  double get rate => days == 0 ? 0 : prayed / (days * 5);
  double rateOf(String prayer) =>
      days == 0 ? 0 : (perPrayer[prayer] ?? 0) / days;

  /// The prayer missed most often; null when nothing was missed.
  String? get weakest {
    if (days == 0) return null;
    String? least;
    for (final p in PrayerLogService.prayers) {
      if (least == null || (perPrayer[p] ?? 0) < (perPrayer[least] ?? 0)) {
        least = p;
      }
    }
    return (perPrayer[least] ?? 0) < days ? least : null;
  }

  PrayerStanding get standing => switch (rate) {
    _ when days == 0 => PrayerStanding.none,
    >= 0.9 => PrayerStanding.strong,
    >= 0.7 => PrayerStanding.steady,
    >= 0.4 => PrayerStanding.slipping,
    _ => PrayerStanding.struggling,
  };
}

/// Which of the five daily prayers the user marked as prayed, per day, kept
/// on the device for 400 days.
class PrayerLogService {
  PrayerLogService._();
  static final PrayerLogService instance = PrayerLogService._();

  static const prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  final _s = StorageService.instance;

  /// Bumped on every change so `Obx` widgets rebuild.
  final version = 0.obs;

  static DateTime _date(DateTime d) => DateTime(d.year, d.month, d.day);

  Map<String, Set<String>> get _log {
    final raw = _s.read<Map>(StorageService.kPrayerLog) ?? const {};
    return {
      for (final e in raw.entries)
        '${e.key}': {
          for (final p in (e.value as List? ?? const []))
            if (prayers.contains(p)) p as String,
        },
    };
  }

  Set<String> prayedOn(DateTime day) => _log[HabitService.key(day)] ?? {};

  bool isComplete(DateTime day) => prayedOn(day).length == prayers.length;

  /// The first day anything was marked.
  DateTime? get started {
    final keys = _log.keys.toList()..sort();
    return keys.isEmpty ? null : HabitService.parse(keys.first);
  }

  /// Marks [prayer] on [day] as prayed, or unmarks it. Future days are
  /// refused. Returns true when this completed all five for that day.
  Future<bool> toggle(DateTime day, String prayer, [DateTime? now]) async {
    final today = _date(now ?? DateTime.now());
    if (!prayers.contains(prayer) || _date(day).isAfter(today)) return false;
    final log = _log;
    final set = log.putIfAbsent(HabitService.key(day), () => <String>{});
    if (!set.remove(prayer)) set.add(prayer);
    if (set.isEmpty) log.remove(HabitService.key(day));
    final oldest = today.subtract(const Duration(days: 400));
    log.removeWhere((k, _) => HabitService.parse(k).isBefore(oldest));
    await _s.write(StorageService.kPrayerLog, {
      for (final e in log.entries)
        e.key: [
          for (final p in prayers)
            if (e.value.contains(p)) p,
        ],
    });
    version.value++;
    return set.length == prayers.length;
  }

  /// Days with all five marked, by [HabitService.key].
  Map<String, int> get _counts => {
    for (final e in _log.entries) e.key: e.value.length,
  };

  /// Full days in a row ending today (or yesterday while today is open).
  int streak([DateTime? now]) =>
      HabitService.streak(_counts, now ?? DateTime.now(), prayers.length);

  int bestStreak() {
    final full = [
      for (final e in _counts.entries)
        if (e.value == prayers.length) HabitService.parse(e.key),
    ]..sort();
    var best = 0, run = 0;
    DateTime? prev;
    for (final d in full) {
      run = prev != null && HabitService.daysBetween(prev, d) == 1
          ? run + 1
          : 1;
      if (run > best) best = run;
      prev = d;
    }
    return best;
  }

  /// The last [days] days up to today (yesterday while today is open),
  /// from the first day anything was marked.
  PrayerStats stats(int days, [DateTime? now]) {
    final today = _date(now ?? DateTime.now());
    final first = started;
    if (first == null) return const PrayerStats(0, {}, 0);
    final log = _log;
    final per = {for (final p in prayers) p: 0};
    var counted = 0, full = 0;
    final end = isComplete(today) ? 0 : 1;
    for (var i = days - 1 + end; i >= end; i--) {
      final d = DateTime(today.year, today.month, today.day - i);
      if (d.isBefore(first)) continue;
      final set = log[HabitService.key(d)] ?? const <String>{};
      counted++;
      if (set.length == prayers.length) full++;
      for (final p in set) {
        per[p] = per[p]! + 1;
      }
    }
    return PrayerStats(counted, per, full);
  }

  void reset() => version.value++;
}
