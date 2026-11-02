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
    final daySix = zanzibar(DateTime(2026, 11, 8)).first.time;
    expect(fajrs.first.time, dayOne);
    expect(fajrs.last.time, daySix);
    expect(
      fajrs.first.time.hour * 60 + fajrs.first.time.minute,
      isNot(daySix.hour * 60 + daySix.minute),
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
}
