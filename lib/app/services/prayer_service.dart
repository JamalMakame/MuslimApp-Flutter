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

/// The user's fine-tuning on top of a method: the high-latitude rule and
/// per-prayer minute offsets (fajr, sunrise, dhuhr, asr, maghrib, isha).
class PrayerTuning {
  final String highLat; // middle | seventh | angle
  final Map<String, int> offsets;
  const PrayerTuning({this.highLat = 'middle', this.offsets = const {}});

  String get signature =>
      [highLat, for (final k in PrayerService.keys) offsets[k] ?? 0].join(',');
}

/// Local prayer-time engine (adhan). No network; coords are passed in.
class PrayerService {
  static const keys = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];

  CalculationParameters _paramsFor(
    String method,
    String madhab, [
    PrayerTuning tuning = const PrayerTuning(),
  ]) {
    final params = switch (method) {
      'mwl' => CalculationMethod.muslim_world_league.getParameters(),
      'egypt' => CalculationMethod.egyptian.getParameters(),
      'karachi' => CalculationMethod.karachi.getParameters(),
      'isna' => CalculationMethod.north_america.getParameters(),
      'dubai' => CalculationMethod.dubai.getParameters(),
      'kuwait' => CalculationMethod.kuwait.getParameters(),
      'qatar' => CalculationMethod.qatar.getParameters(),
      'singapore' => CalculationMethod.singapore.getParameters(),
      'turkey' => CalculationMethod.turkey.getParameters(),
      'tehran' => CalculationMethod.tehran.getParameters(),
      'moonsighting' =>
        CalculationMethod.moon_sighting_committee.getParameters(),
      _ => CalculationMethod.umm_al_qura.getParameters(),
    };
    params.madhab = madhab == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
    params.highLatitudeRule = switch (tuning.highLat) {
      'seventh' => HighLatitudeRule.seventh_of_the_night,
      'angle' => HighLatitudeRule.twilight_angle,
      _ => HighLatitudeRule.middle_of_the_night,
    };
    final o = tuning.offsets;
    params.adjustments
      ..fajr = o['fajr'] ?? 0
      ..sunrise = o['sunrise'] ?? 0
      ..dhuhr = o['dhuhr'] ?? 0
      ..asr = o['asr'] ?? 0
      ..maghrib = o['maghrib'] ?? 0
      ..isha = o['isha'] ?? 0;
    return params;
  }

  /// The six slots (fajr…isha, with sunrise) for one calendar [date].
  List<PrayerSlot> slotsOn(
    DateTime date, {
    required double lat,
    required double lng,
    required String method,
    required String madhab,
    PrayerTuning tuning = const PrayerTuning(),
  }) {
    final t = PrayerTimes(
      Coordinates(lat, lng),
      DateComponents.from(date),
      _paramsFor(method, madhab, tuning),
    );
    return [
      PrayerSlot('fajr', t.fajr),
      PrayerSlot('sunrise', t.sunrise),
      PrayerSlot('dhuhr', t.dhuhr),
      PrayerSlot('asr', t.asr),
      PrayerSlot('maghrib', t.maghrib),
      PrayerSlot('isha', t.isha),
    ];
  }

  PrayerDay compute({
    required double lat,
    required double lng,
    required String method,
    required String madhab,
    PrayerTuning tuning = const PrayerTuning(),
  }) {
    final params = _paramsFor(method, madhab, tuning);
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
