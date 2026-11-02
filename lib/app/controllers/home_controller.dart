import 'dart:async';

import 'package:get/get.dart';

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
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }
}
