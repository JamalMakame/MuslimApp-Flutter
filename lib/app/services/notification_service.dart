import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'prayer_service.dart';

/// One scheduled prayer reminder.
class PrayerReminder {
  const PrayerReminder(this.id, this.key, this.time, {this.lead = 0});
  final int id;

  /// A prayer key, [azkarMorning] / [azkarEvening] or [reading].
  final String key;
  final DateTime time;

  /// Minutes before the prayer (0 = at its time).
  final int lead;
}

/// Local prayer reminders: one-shot notifications at each prayer time
/// (sunrise excluded) for the next [days] days, rescheduled only when the
/// inputs (location, method, madhab, language, day) change.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  String? _scheduledFor;
  bool _cleared = false;
  Future<void> _queue = Future.value();

  /// Runs [op] after every earlier schedule/cancel has finished, so a
  /// cancel can never be overtaken by a schedule that started before it.
  /// Errors reach the caller; the queue itself carries on.
  Future<void> _serial(Future<void> Function() op) {
    final run = _queue.then((_) => op());
    _queue = run.catchError((Object _) {});
    return run;
  }

  static const days = 7;
  static const _channelId = 'prayer_times';
  static const _channelName = 'Prayer Times';
  static const adhanChannelId = 'prayer_adhan';
  static const _adhanChannelName = 'Adhan';

  /// Bundled recording: `res/raw/adhan.mp3` (full) and `Runner/adhan.caf`
  /// (first 26 s; iOS plays at most 30 s of a notification sound).
  static const adhanSoundIos = 'adhan.caf';
  static const adhanSoundAndroid = 'adhan';

  /// The adhan plays only at a prayer's own time, not for early, azkar or
  /// reading reminders.
  static bool usesAdhan(PrayerReminder r, {required bool adhan}) =>
      adhan && r.lead == 0 && _prayers.contains(r.key);

  static NotificationDetails details(PrayerReminder r, {required bool adhan}) {
    final withAdhan = usesAdhan(r, adhan: adhan);
    return NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentSound: true,
        sound: withAdhan ? adhanSoundIos : null,
      ),
      android: AndroidNotificationDetails(
        withAdhan ? adhanChannelId : _channelId,
        withAdhan ? _adhanChannelName : _channelName,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        color: const Color(0xFF0E6B5C),
        sound: withAdhan
            ? const RawResourceAndroidNotificationSound(adhanSoundAndroid)
            : null,
      ),
    );
  }

  static const _prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    const init = InitializationSettings(
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      android: AndroidInitializationSettings('@drawable/ic_notification'),
    );
    await _plugin.initialize(init);
    _ready = true;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// Asks for notification permission (iOS, Android 13+).
  Future<bool> requestPermission() async {
    await init();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final granted =
        await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        await _android?.requestNotificationsPermission();
    return granted ?? true;
  }

  static const azkarMorning = 'azkarMorningNotify';
  static const azkarEvening = 'azkarEveningNotify';

  /// Minutes after Fajr / Asr for the morning / evening azkar reminder.
  static const azkarDelay = 20;

  static const reading = 'readNotify';

  /// The next [days] days of reminders after [now], in time order. Starts
  /// one calendar day back so a location far from the device's time zone
  /// still gets a full week. [leads] gives minutes before each prayer
  /// (missing = at its time, negative = off); [azkar] adds the morning and
  /// evening azkar reminders; [readingAt] (minutes after midnight) adds a
  /// daily Quran reading reminder. Ids are stable per (day offset, slot).
  static List<PrayerReminder> plan(
    List<PrayerSlot> Function(DateTime date) slotsOn,
    DateTime now, {
    Map<String, int> leads = const {},
    bool azkar = false,
    int? readingAt,
  }) {
    final out = <PrayerReminder>[];
    final per =
        _prayers.where((p) => (leads[p] ?? 0) >= 0).length +
        (azkar ? 2 : 0) +
        (readingAt != null ? 1 : 0);
    for (var d = -1; d <= days; d++) {
      final date = DateTime(now.year, now.month, now.day + d);
      if (readingAt != null) {
        final at = DateTime(
          date.year,
          date.month,
          date.day,
          readingAt ~/ 60,
          readingAt % 60,
        );
        if (at.isAfter(now)) out.add(PrayerReminder(310 + d, reading, at));
      }
      for (final slot in slotsOn(date)) {
        final i = _prayers.indexOf(slot.key);
        if (i < 0) continue;
        final lead = leads[slot.key] ?? 0;
        final at = slot.time.subtract(Duration(minutes: lead));
        if (lead >= 0 && at.isAfter(now)) {
          out.add(PrayerReminder(110 + d * 10 + i, slot.key, at, lead: lead));
        }
        if (!azkar || (slot.key != 'fajr' && slot.key != 'asr')) continue;
        final z = slot.time.add(const Duration(minutes: azkarDelay));
        if (z.isAfter(now)) {
          final morning = slot.key == 'fajr';
          out.add(
            PrayerReminder(
              210 + d * 10 + (morning ? 0 : 1),
              morning ? azkarMorning : azkarEvening,
              z,
            ),
          );
        }
      }
    }
    out.sort((a, b) => a.time.compareTo(b.time));
    return out.take(days * per).toList();
  }

  /// Schedules [plan] unless the same [signature] is already scheduled.
  /// [title] and [body] give the localized text for a prayer key.
  Future<void> schedule({
    required String signature,
    required List<PrayerReminder> reminders,
    required String Function(PrayerReminder r) title,
    required String Function(PrayerReminder r) body,
    bool adhan = false,
  }) => _serial(() async {
    if (signature == _scheduledFor) return;
    await init();
    await _plugin.cancelAll();
    _scheduledFor = null;
    _cleared = true;
    final exact =
        defaultTargetPlatform == TargetPlatform.android &&
        (await _android?.canScheduleExactNotifications() ?? false);
    for (final r in reminders) {
      await _plugin.zonedSchedule(
        r.id,
        title(r),
        body(r),
        tz.TZDateTime.from(r.time, tz.UTC),
        details(r, adhan: adhan),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
    _scheduledFor = signature;
    _cleared = false;
  });

  Future<void> cancelAll() => _serial(() async {
    if (_cleared) return;
    await init();
    await _plugin.cancelAll();
    _scheduledFor = null;
    _cleared = true;
  });
}
