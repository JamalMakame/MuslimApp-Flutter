import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../services/notification_service.dart';
import '../services/prayer_service.dart';
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

  Future<void> _sync() async {
    final notifications = NotificationService.instance;
    if (!settings.notifyPrayers.value || !settings.hasLocation) {
      await notifications.cancelAll();
      return;
    }
    if (!_askedPermission) {
      _askedPermission = true;
      await notifications.requestPermission();
    }
    final lat = settings.latitude.value!;
    final lng = settings.longitude.value!;
    final method = settings.calcMethod.value;
    final madhab = settings.madhab.value;
    final code = settings.localeCode.value;
    final tuning = settings.tuning;
    final leads = Map.of(settings.prayerLeads);
    final azkar = settings.azkarReminders.value;
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
        now.year,
        now.month,
        now.day,
      ].join('|'),
      reminders: NotificationService.plan(
        (date) => _prayers.slotsOn(
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
      ),
      title: (r) => _t(code, r.key),
      body: (r) => switch (r.key) {
        NotificationService.azkarMorning ||
        NotificationService.azkarEvening => _t(code, 'azkarNotifyBody'),
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
