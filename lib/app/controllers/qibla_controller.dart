import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_compass/flutter_compass.dart';
import 'package:get/get.dart';

import 'settings_controller.dart';

/// Qibla compass — device heading + great-circle bearing to Makkah.
class QiblaController extends GetxController {
  final settings = Get.find<SettingsController>();

  static const makkahLat = 21.4225;
  static const makkahLng = 39.8262;

  /// Device compass heading in degrees (0=N). null = sensor missing.
  final heading = Rx<double?>(null);
  final calibrated = true.obs;
  StreamSubscription<CompassEvent>? _sub;

  /// Degrees from user position to the Kaaba.
  double get qiblaBearing {
    final lat = settings.latitude.value;
    final lng = settings.longitude.value;
    if (lat == null || lng == null) return 0;
    final phi1 = lat * math.pi / 180;
    final phi2 = makkahLat * math.pi / 180;
    final dLambda = (makkahLng - lng) * math.pi / 180;
    final y = math.sin(dLambda);
    final x =
        math.cos(phi1) * math.tan(phi2) - math.sin(phi1) * math.cos(dLambda);
    final deg = math.atan2(y, x) * 180 / math.pi;
    return (deg + 360) % 360;
  }

  /// Haversine km to Makkah.
  int get distanceKm {
    final lat = settings.latitude.value;
    final lng = settings.longitude.value;
    if (lat == null || lng == null) return 0;
    const r = 6371.0;
    final dPhi = (makkahLat - lat) * math.pi / 180;
    final dLambda = (makkahLng - lng) * math.pi / 180;
    final a =
        math.sin(dPhi / 2) * math.sin(dPhi / 2) +
        math.cos(lat * math.pi / 180) *
            math.cos(makkahLat * math.pi / 180) *
            math.sin(dLambda / 2) *
            math.sin(dLambda / 2);
    return (2 * r * math.asin(math.sqrt(a))).round();
  }

  /// Compass-relative needle angle (radians) for the dial painter.
  double get needleAngle {
    final h = heading.value ?? 0;
    return (qiblaBearing - h) * math.pi / 180;
  }

  @override
  void onInit() {
    super.onInit();
    _sub = FlutterCompass.events?.listen((event) {
      heading.value = event.heading;
      calibrated.value = (event.accuracy ?? 0) >= 0;
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
