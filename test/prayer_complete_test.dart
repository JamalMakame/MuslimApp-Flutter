import 'package:flutter_test/flutter_test.dart';
import 'package:fquran_app/app/controllers/settings_controller.dart';
import 'package:fquran_app/app/i18n/app_translations.dart';
import 'package:fquran_app/app/services/notification_service.dart';
import 'package:fquran_app/app/services/prayer_service.dart';

void main() {
  final prayers = PrayerService();
  List<PrayerSlot> at(
    DateTime date, {
    double lat = -6.1659,
    double lng = 39.2026,
    String method = 'mwl',
    PrayerTuning tuning = const PrayerTuning(),
  }) => prayers.slotsOn(
    date,
    lat: lat,
    lng: lng,
    method: method,
    madhab: 'shafi',
    tuning: tuning,
  );

  test('every method computes six ordered times', () {
    for (final m in SettingsController.methods) {
      final s = at(DateTime(2026, 11, 2), method: m);
      expect(s.map((e) => e.key), PrayerService.keys, reason: m);
      for (var i = 1; i < s.length; i++) {
        expect(s[i].time.isAfter(s[i - 1].time), isTrue, reason: m);
      }
    }
    expect(
      at(DateTime(2026, 11, 2), method: 'tehran')[5].time,
      isNot(at(DateTime(2026, 11, 2), method: 'mwl')[5].time),
    );
  });

  test('per-prayer offsets move only that prayer', () {
    final day = DateTime(2026, 11, 2);
    final base = at(day);
    final tuned = at(
      day,
      tuning: const PrayerTuning(offsets: {'fajr': 3, 'isha': -2}),
    );
    expect(tuned[0].time.difference(base[0].time).inMinutes, 3);
    expect(tuned[5].time.difference(base[5].time).inMinutes, -2);
    expect(tuned[2].time, base[2].time);
  });

  test('the high-latitude rule changes Fajr in a northern summer', () {
    final day = DateTime(2026, 6, 21);
    PrayerSlot fajr(String rule) => at(
      day,
      lat: 59.33,
      lng: 18.06,
      tuning: PrayerTuning(highLat: rule),
    ).first;
    expect(fajr('seventh').time, isNot(fajr('middle').time));
  });

  group('reminder plan', () {
    List<PrayerSlot> z(DateTime d) => at(d);
    final fajr = z(DateTime(2026, 11, 2)).first.time;
    final now = fajr.subtract(const Duration(hours: 1));

    test('a reminder can fire minutes before, or be off', () {
      final plan = NotificationService.plan(
        z,
        now,
        leads: const {'fajr': 10, 'dhuhr': -1},
      );
      expect(plan.first.key, 'fajr');
      expect(plan.first.lead, 10);
      expect(fajr.difference(plan.first.time).inMinutes, 10);
      expect(plan.map((r) => r.key), isNot(contains('dhuhr')));
      expect(plan, hasLength(NotificationService.days * 4));
    });

    test('azkar reminders follow Fajr and Asr', () {
      final plan = NotificationService.plan(z, now, azkar: true);
      final morning = plan.firstWhere(
        (r) => r.key == NotificationService.azkarMorning,
      );
      expect(
        morning.time.difference(fajr).inMinutes,
        NotificationService.azkarDelay,
      );
      expect(
        plan.where((r) => r.key == NotificationService.azkarEvening),
        isNotEmpty,
      );
      expect(plan.map((r) => r.id).toSet(), hasLength(plan.length));
      expect(plan, hasLength(NotificationService.days * 7));
    });

    test('azkar reminders work with every prayer reminder off', () {
      final plan = NotificationService.plan(
        z,
        now,
        leads: {for (final k in PrayerService.keys) k: -1},
        azkar: true,
      );
      expect(plan.map((r) => r.key).toSet(), {
        NotificationService.azkarMorning,
        NotificationService.azkarEvening,
      });
      expect(plan, hasLength(NotificationService.days * 2));
    });
  });

  test('new strings exist in every language', () {
    final t = DeenTranslations().keys;
    const keys = [
      'highLatRule',
      'hl_middle',
      'hl_seventh',
      'hl_angle',
      'prayerTuning',
      'reminderBefore',
      'azkarReminders',
      'azkarMorningNotify',
      'azkarEveningNotify',
      'azkarNotifyBody',
      'prayerSoonBody',
      'monthlyTimetable',
      'movedTitle',
      'movedBody',
      ...SettingsController.methods,
    ];
    for (final loc in t.keys) {
      for (final k in keys) {
        if (k == 'umm_al_qura') continue;
        expect(t[loc]![k], isNotNull, reason: '$loc $k');
      }
    }
  });
}
