import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'prayer_service.dart';

/// One scheduled prayer reminder.
class PrayerReminder {
  const PrayerReminder(this.id, this.key, this.time);
  final int id;
  final String key;
  final DateTime time;
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

  static const days = 7;
  static const _channelId = 'prayer_times';
  static const _channelName = 'Prayer Times';
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
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
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

  /// The next [days] × 5 reminders after [now], in time order. Starts one
  /// calendar day back so a location far from the device's time zone still
  /// gets a full week. Ids are stable per (day offset, prayer).
  static List<PrayerReminder> plan(
    List<PrayerSlot> Function(DateTime date) slotsOn,
    DateTime now,
  ) {
    final out = <PrayerReminder>[];
    for (var d = -1; d <= days; d++) {
      final date = DateTime(now.year, now.month, now.day + d);
      for (final slot in slotsOn(date)) {
        final i = _prayers.indexOf(slot.key);
        if (i < 0 || !slot.time.isAfter(now)) continue;
        out.add(PrayerReminder(110 + d * 10 + i, slot.key, slot.time));
      }
    }
    out.sort((a, b) => a.time.compareTo(b.time));
    return out.take(days * _prayers.length).toList();
  }

  /// Schedules [plan] unless the same [signature] is already scheduled.
  /// [title] and [body] give the localized text for a prayer key.
  Future<void> schedule({
    required String signature,
    required List<PrayerReminder> reminders,
    required String Function(String key) title,
    required String Function(String key) body,
  }) async {
    if (signature == _scheduledFor) return;
    await init();
    await _plugin.cancelAll();
    final exact =
        defaultTargetPlatform == TargetPlatform.android &&
        (await _android?.canScheduleExactNotifications() ?? false);
    for (final r in reminders) {
      await _plugin.zonedSchedule(
        r.id,
        title(r.key),
        body(r.key),
        tz.TZDateTime.from(r.time, tz.UTC),
        const NotificationDetails(
          iOS: DarwinNotificationDetails(presentSound: true),
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
    _scheduledFor = signature;
    _cleared = false;
  }

  Future<void> cancelAll() async {
    if (_cleared) return;
    await init();
    await _plugin.cancelAll();
    _scheduledFor = null;
    _cleared = true;
  }
}
