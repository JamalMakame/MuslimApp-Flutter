import 'package:adhan/adhan.dart';

/// One prayer's computed data for the UI.
class PrayerSlot {
  final String key; // fajr/sunrise/dhuhr/asr/maghrib/isha
  final DateTime time;
  const PrayerSlot(this.key, this.time);
}

class PrayerDay {
  /// Ordered slots for display.
  final List<PrayerSlot> slots;

  /// i18n key of the prayer currently in effect.
  final String currentKey;

  /// i18n key + time of the next prayer.
  final String nextKey;
  final DateTime nextTime;

  /// Remaining until [nextTime].
  final Duration remaining;

  /// Formatted via intl at presentation time — service keeps raw values.
  final DateTime now;

  const PrayerDay({
    required this.slots,
    required this.currentKey,
    required this.nextKey,
    required this.nextTime,
    required this.remaining,
    required this.now,
  });
}

/// Local prayer-time engine (adhan). No network; coords are passed in.
class PrayerService {
  CalculationParameters _paramsFor(String method, String madhab) {
    final params = switch (method) {
      'mwl' => CalculationMethod.muslim_world_league.getParameters(),
      'egypt' => CalculationMethod.egyptian.getParameters(),
      'karachi' => CalculationMethod.karachi.getParameters(),
      'isna' => CalculationMethod.north_america.getParameters(),
      _ => CalculationMethod.umm_al_qura.getParameters(),
    };
    params.madhab = madhab == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
    return params;
  }

  PrayerDay compute({
    required double lat,
    required double lng,
    required String method,
    required String madhab,
  }) {
    final params = _paramsFor(method, madhab);
    final times = PrayerTimes(
      Coordinates(lat, lng),
      DateComponents.from(DateTime.now()),
      params,
    );

    final slots = <PrayerSlot>[
      PrayerSlot('fajr', times.fajr),
      PrayerSlot('sunrise', times.sunrise),
      PrayerSlot('dhuhr', times.dhuhr),
      PrayerSlot('asr', times.asr),
      PrayerSlot('maghrib', times.maghrib),
      PrayerSlot('isha', times.isha),
    ];

    String keyOf(Prayer p) => switch (p) {
      Prayer.fajr => 'fajr',
      Prayer.sunrise => 'sunrise',
      Prayer.dhuhr => 'dhuhr',
      Prayer.asr => 'asr',
      Prayer.maghrib => 'maghrib',
      _ => 'isha',
    };

    var next = times.nextPrayer();
    var nextTime = times.timeForPrayer(next);
    if (next == Prayer.none || nextTime == null) {
      // Past isha — next is tomorrow's fajr.
      next = Prayer.fajr;
      final tomorrow = PrayerTimes(
        Coordinates(lat, lng),
        DateComponents.from(DateTime.now().add(const Duration(days: 1))),
        params,
      );
      nextTime = tomorrow.fajr;
    }

    return PrayerDay(
      slots: slots,
      currentKey: keyOf(times.currentPrayer()),
      nextKey: keyOf(next),
      nextTime: nextTime,
      remaining: nextTime.difference(DateTime.now()),
      now: DateTime.now(),
    );
  }

  /// Countdown label like "2h 14m".
  static String remainingLabel(Duration d) {
    if (d.isNegative) return '0m';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }
}
