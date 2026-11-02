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

  Future<void> sync() async {
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
    final now = DateTime.now();
    await notifications.schedule(
      signature: [
        lat,
        lng,
        method,
        madhab,
        code,
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
        ),
        now,
      ),
      title: (key) => _t(code, key),
      body: (key) =>
          _t(code, 'prayerNotifyBody').replaceAll('@prayer', _t(code, key)),
    );
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.onClose();
  }
}
