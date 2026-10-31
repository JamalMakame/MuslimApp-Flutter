import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'prayer_service.dart';

/// Local daily prayer reminders. Schedules one notification per prayer
/// time (excluding sunrise); re-scheduled whenever times/setting change.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channelId = 'prayer_times';
  static const _channelName = 'Prayer Times';

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

  Future<bool> requestPermission() async {
    await init();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final granted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return granted ?? true;
  }

  /// Schedule today's remaining prayer notifications (idempotent).
  Future<void> scheduleFor(
    PrayerDay day,
    String Function(String key) nameOf,
  ) async {
    await init();
    await cancelAll();
    var id = 100;
    for (final slot in day.slots) {
      if (slot.key == 'sunrise') continue;
      if (slot.time.isBefore(DateTime.now())) continue;
      await _plugin.zonedSchedule(
        id++,
        nameOf(slot.key),
        slot.key,
        tz.TZDateTime.from(slot.time, tz.local),
        const NotificationDetails(
          iOS: DarwinNotificationDetails(presentSound: true),
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
