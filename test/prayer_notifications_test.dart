import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fquran_app/app/i18n/app_translations.dart';
import 'package:fquran_app/app/services/notification_service.dart';
import 'package:fquran_app/app/services/prayer_service.dart';

void main() {
  final prayers = PrayerService();
  List<PrayerSlot> zanzibar(DateTime date) => prayers.slotsOn(
    date,
    lat: -6.1659,
    lng: 39.2026,
    method: 'mwl',
    madhab: 'shafi',
  );

  test('plans five one-shot reminders a day for seven days', () {
    final fajr = zanzibar(DateTime(2026, 11, 2)).first.time;
    final now = fajr.subtract(const Duration(minutes: 1));
    final plan = NotificationService.plan(zanzibar, now);
    expect(plan, hasLength(NotificationService.days * 5));
    expect(plan.map((r) => r.key), isNot(contains('sunrise')));
    expect(plan.map((r) => r.id).toSet(), hasLength(plan.length));
    for (var i = 1; i < plan.length; i++) {
      expect(plan[i].time.isAfter(plan[i - 1].time), isTrue);
    }
    expect(plan.first.key, 'fajr');
    expect(plan.first.time, fajr);
    expect(
      plan.last.time.difference(fajr).inDays,
      NotificationService.days - 1,
    );
  });

  test('skips prayers that have passed and follows each day\'s own times', () {
    final dhuhr = zanzibar(DateTime(2026, 11, 2))[2].time;
    final now = dhuhr.add(const Duration(minutes: 1));
    final plan = NotificationService.plan(zanzibar, now);
    expect(plan.every((r) => r.time.isAfter(now)), isTrue);
    expect(plan.first.key, 'asr');

    final fajrs = plan.where((r) => r.key == 'fajr').toList();
    final dayOne = zanzibar(DateTime(2026, 11, 3)).first.time;
    final daySeven = zanzibar(DateTime(2026, 11, 9)).first.time;
    expect(fajrs.first.time, dayOne);
    expect(plan, hasLength(NotificationService.days * 5));
    expect(fajrs.last.time, daySeven);
    expect(
      fajrs.first.time.hour * 60 + fajrs.first.time.minute,
      isNot(daySeven.hour * 60 + daySeven.minute),
    );
  });

  test('the reminder body is translated in every language', () {
    final keys = DeenTranslations().keys;
    for (final locale in ['en', 'ar', 'sw']) {
      final body = keys.entries
          .firstWhere((e) => e.key.startsWith(locale))
          .value['prayerNotifyBody'];
      expect(body, contains('@prayer'), reason: locale);
    }
  });

  test('the adhan plays only at a prayer\'s own time when turned on', () {
    final at = DateTime(2026, 11, 2, 12);
    final cases = {
      PrayerReminder(112, 'dhuhr', at): true,
      PrayerReminder(112, 'dhuhr', at, lead: 10): false,
      PrayerReminder(210, NotificationService.azkarMorning, at): false,
      PrayerReminder(310, NotificationService.reading, at): false,
    };
    cases.forEach((r, expected) {
      final on = NotificationService.details(r, adhan: true);
      expect(on.iOS!.sound, expected ? 'adhan.caf' : isNull, reason: r.key);
      expect(
        on.android!.channelId,
        expected ? NotificationService.adhanChannelId : 'prayer_times',
      );
      expect(
        on.android!.sound,
        expected ? isA<RawResourceAndroidNotificationSound>() : isNull,
      );
      final off = NotificationService.details(r, adhan: false);
      expect(off.iOS!.sound, isNull);
      expect(off.android!.channelId, 'prayer_times');
    });
  });
}
