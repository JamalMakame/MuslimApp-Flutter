import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../services/habit_service.dart';
import '../services/notification_service.dart';
import '../services/prayer_service.dart';
import '../services/prayer_widget.dart';
import 'settings_controller.dart';

/// Keeps the week of prayer reminders current for the whole app lifetime,
/// not only while Home is open: on start, on resume, every 15 minutes, and
/// whenever location, calculation, language or the reminder switch changes.
class PrayerReminderController extends GetxController
    with WidgetsBindingObserver {
  final settings = Get.find<SettingsController>();
  final _prayers = PrayerService();
  Timer? _timer;
  bool _askedPermission = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    everAll([
      settings.latitude,
      settings.longitude,
      settings.calcMethod,
      settings.madhab,
      settings.localeCode,
      settings.notifyPrayers,
      settings.highLatRule,
      settings.prayerOffsets,
      settings.prayerLeads,
      settings.azkarReminders,
      HabitService.instance.readReminder,
    ], (_) => sync());
    _timer = Timer.periodic(const Duration(minutes: 15), (_) => sync());
    sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) sync();
  }

  String _t(String code, String key) =>
      Get.translations[code]?[key] ?? Get.translations['en']?[key] ?? key;

  /// A failed run leaves no signature behind, so the next tick retries.
  Future<void> sync() async {
    try {
      await _sync();
    } catch (e) {
      debugPrint('Prayer reminders not scheduled: $e');
    }
  }

  Future<void> _widget() async {
    if (!settings.hasLocation) return;
    final code = settings.localeCode.value;
    final now = DateTime.now();
    final slots = [
      for (var d = 0; d < 3; d++)
        ..._prayers.slotsOn(
          DateTime(now.year, now.month, now.day + d),
          lat: settings.latitude.value ?? 0,
          lng: settings.longitude.value ?? 0,
          method: settings.calcMethod.value,
          madhab: settings.madhab.value,
          tuning: settings.tuning,
        ),
    ];
    await PrayerWidget.update(
      prayers: PrayerWidget.payload(slots, now, (k) => _t(code, k)),
      label: _t(code, 'nextPrayer'),
      city: settings.city.value,
    );
  }

  Future<void> _sync() async {
    await _widget().catchError((Object e) {
      debugPrint('Prayer widget not updated: $e');
    });
    final notifications = NotificationService.instance;
    final prayersOn = settings.notifyPrayers.value;
    final azkar = settings.azkarReminders.value;
    final readAt = HabitService.instance.readReminder.value;
    final reading = readAt >= 0 ? readAt : null;
    final located = settings.hasLocation;
    if (reading == null && (!located || (!prayersOn && !azkar))) {
      await notifications.cancelAll();
      return;
    }
    if (!_askedPermission) {
      _askedPermission = true;
      await notifications.requestPermission();
    }
    final lat = settings.latitude.value ?? 0;
    final lng = settings.longitude.value ?? 0;
    final method = settings.calcMethod.value;
    final madhab = settings.madhab.value;
    final code = settings.localeCode.value;
    final tuning = settings.tuning;
    final leads = prayersOn
        ? Map.of(settings.prayerLeads)
        : {for (final k in PrayerService.keys) k: -1};
    final now = DateTime.now();
    await notifications.schedule(
      signature: [
        lat,
        lng,
        method,
        madhab,
        code,
        tuning.signature,
        [for (final k in leads.keys.toList()..sort()) '$k${leads[k]}'],
        azkar,
        located,
        reading,
        now.year,
        now.month,
        now.day,
      ].join('|'),
      reminders: NotificationService.plan(
        (date) => !located
            ? const []
            : _prayers.slotsOn(
                date,
                lat: lat,
                lng: lng,
                method: method,
                madhab: madhab,
                tuning: tuning,
              ),
        now,
        leads: leads,
        azkar: azkar,
        readingAt: reading,
      ),
      title: (r) => _t(code, r.key),
      body: (r) => switch (r.key) {
        NotificationService.azkarMorning ||
        NotificationService.azkarEvening => _t(code, 'azkarNotifyBody'),
        NotificationService.reading => _t(code, 'readNotifyBody'),
        _ when r.lead > 0 => _t(
          code,
          'prayerSoonBody',
        ).replaceAll('@prayer', _t(code, r.key)).replaceAll('@m', '${r.lead}'),
        _ => _t(
          code,
          'prayerNotifyBody',
        ).replaceAll('@prayer', _t(code, r.key)),
      },
    );
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.onClose();
  }
}
