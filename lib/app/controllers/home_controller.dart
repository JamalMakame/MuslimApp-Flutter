import 'dart:async';

import 'package:get/get.dart';

import '../services/notification_service.dart';
import '../services/prayer_service.dart';
import '../services/storage_service.dart';
import 'settings_controller.dart';

/// Prayer times for Home — recomputed when settings/location change,
/// countdown ticks every 30s.
class HomeController extends GetxController {
  final settings = Get.find<SettingsController>();
  final _prayers = PrayerService();

  final day = Rx<PrayerDay?>(null);
  final currentDate = DateTime.now().obs;
  final hijriOffset = StorageService.instance
      .readInt(StorageService.kMoonOffset)
      .obs;
  Timer? _ticker;

  /// Rotating daily-inspiration index.
  final inspirationIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    recompute();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => recompute());
    everAll([
      settings.latitude,
      settings.longitude,
      settings.calcMethod,
      settings.madhab,
    ], (_) => recompute());
    ever(settings.notifyPrayers, (_) => _syncNotifications());
  }

  void recompute() {
    currentDate.value = DateTime.now();
    hijriOffset.value = StorageService.instance.readInt(
      StorageService.kMoonOffset,
    );
    if (!settings.hasLocation) return;
    day.value = _prayers.compute(
      lat: settings.latitude.value!,
      lng: settings.longitude.value!,
      method: settings.calcMethod.value,
      madhab: settings.madhab.value,
    );
    _syncNotifications();
  }

  bool _askedPermission = false;

  Future<void> _syncNotifications() async {
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
    final now = DateTime.now();
    final signature = [
      lat,
      lng,
      method,
      madhab,
      Get.locale?.languageCode,
      now.year,
      now.month,
      now.day,
    ].join('|');
    await notifications.schedule(
      signature: signature,
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
      title: (key) => key.tr,
      body: (key) => 'prayerNotifyBody'.trParams({'prayer': key.tr}),
    );
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }
}
