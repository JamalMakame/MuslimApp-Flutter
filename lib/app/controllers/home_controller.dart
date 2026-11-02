import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../services/link_service.dart';
import '../services/location_service.dart';
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
      settings.highLatRule,
      settings.prayerOffsets,
    ], (_) => recompute());
  }

  @override
  void onReady() {
    super.onReady();
    LinkService.instance.openPending();
    checkMoved();
  }

  /// Distance in km from which a GPS user is offered to update the place.
  static const movedKm = 30.0;

  /// When the location came from GPS and the phone is now more than
  /// [movedKm] away, offer to update it (once per app start).
  Future<void> checkMoved({LocationService? location}) async {
    if (settings.locationSource.value != 'gps' || !settings.hasLocation) {
      return;
    }
    final here = await (location ?? LocationService()).current();
    if (here == null || isClosed) return;
    final km =
        Geolocator.distanceBetween(
          settings.latitude.value!,
          settings.longitude.value!,
          here.lat,
          here.lng,
        ) /
        1000;
    if (km < movedKm) return;
    final update = await Get.dialog<bool>(
      AlertDialog(
        title: Text('movedTitle'.tr),
        content: Text(
          'movedBody'.trParams({
            'km': km.round().toString(),
            'place': settings.placeLabel,
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('notNow'.tr),
          ),
          TextButton(
            key: const ValueKey('moved-update'),
            onPressed: () => Get.back(result: true),
            child: Text('updateLocation'.tr),
          ),
        ],
      ),
    );
    if (update != true) return;
    await settings.setLocation(
      lat: here.lat,
      lng: here.lng,
      city: here.city,
      country: here.country,
      source: 'gps',
    );
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
      tuning: settings.tuning,
    );
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }
}
