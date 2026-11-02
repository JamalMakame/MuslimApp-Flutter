import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/qibla_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/floating_nav_pill.dart';

/// Qibla compass — degree-tick dial, gold Kaaba marker, emerald needle,
/// bearing/distance metrics, calibration chip, geodesic fallback card.
class QiblaScreen extends GetView<QiblaController> {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    return Scaffold(
      backgroundColor: AppColors.ivory,
      bottomNavigationBar: const FloatingNavPill(active: 'home'),
      body: SafeArea(
        child: Obx(() {
          final bearing = controller.qiblaBearing;
          final heading = controller.heading.value;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
            children: [
              // Top row: back + status chips
              Row(
                children: [
                  _RoundIconBtn(icon: Icons.arrow_back, onTap: Get.back),
                  const Spacer(),
                  _Chip(
                    dot: controller.calibrated.value
                        ? AppColors.gold
                        : Colors.orange,
                    label: controller.calibrated.value
                        ? 'calibrated'.tr
                        : 'needsCalibration'.tr,
                  ),
                  const SizedBox(width: 8),
                  _Chip(icon: Icons.location_on, label: settings.placeLabel),
                ],
              ),
              const SizedBox(height: 16),

              // Title block
              Row(
                children: [
                  Text(
                    'prayerOrientation'.tr,
                    style: AppTheme.body(
                      10.5,
                      weight: FontWeight.w700,
                      color: AppColors.sage,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 36, height: 1, color: AppColors.hairline),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'qiblaDirection'.tr,
                      style: AppTheme.headline(24, weight: FontWeight.w800),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldTint,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'bearingLabel'.trParams({
                        'deg': bearing.round().toString(),
                      }),
                      style: AppTheme.body(
                        11.5,
                        weight: FontWeight.w700,
                        color: AppColors.emerald,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'qiblaDesc'.tr,
                style: AppTheme.body(13, color: AppColors.sage),
              ),
              const SizedBox(height: 18),

              // Compass card
              Container(
                decoration: appCardDecoration(radius: 24),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    SizedBox(
                      width: 246,
                      height: 246,
                      child: CustomPaint(
                        painter: _CompassPainter(
                          needleAngle: heading == null
                              ? bearing * math.pi / 180
                              : controller.needleAngle,
                          heading: heading,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.mosque,
                            color: AppColors.emeraldDeep,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (heading == null)
                      Text(
                        'compassUnavailable'.tr,
                        style: AppTheme.body(
                          11.5,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    const Divider(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'currentBearing'.tr,
                                style: AppTheme.body(
                                  9.5,
                                  weight: FontWeight.w700,
                                  color: AppColors.sage,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${bearing.round()}°',
                                style: AppTheme.headline(
                                  28,
                                  weight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.hairline,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'distanceToMakkah'.tr,
                                style: AppTheme.body(
                                  9.5,
                                  weight: FontWeight.w700,
                                  color: AppColors.sage,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_fmtKm(controller.distanceKm)} ${'km'.tr}',
                                style: AppTheme.headline(
                                  20,
                                  weight: FontWeight.w800,
                                  color: AppColors.emerald,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Alignment tip
              Container(
                decoration: appCardDecoration(),
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.goldTint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.screen_rotation,
                        size: 17,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'alignmentTip'.tr,
                            style: AppTheme.body(13.5, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'alignmentTipBody'.tr,
                            style: AppTheme.body(
                              11.5,
                              color: AppColors.sage,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Geodesic fallback
              Row(
                children: [
                  Text(
                    'noCompass'.tr,
                    style: AppTheme.body(
                      10.5,
                      weight: FontWeight.w700,
                      color: AppColors.sage,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'geodesic'.tr,
                    style: AppTheme.body(10.5, color: AppColors.sage),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: appCardDecoration(),
                padding: const EdgeInsets.all(14),
                child: _GeodesicRow(bearing: bearing),
              ),
            ],
          );
        }),
      ),
    );
  }

  String _fmtKm(int km) {
    final s = km.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}

class _GeodesicRow extends StatelessWidget {
  const _GeodesicRow({required this.bearing});
  final double bearing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.emerald,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, color: AppColors.gold),
                    const SizedBox(width: 5),
                    Text(
                      'makkah'.tr,
                      style: AppTheme.body(
                        10.5,
                        weight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Transform.rotate(
                    angle: bearing * math.pi / 180,
                    child: Icon(
                      Icons.navigation,
                      color: AppColors.emerald,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.hairline),
                    ),
                    child: Text(
                      'youHere'.trParams({
                        'place': Get.find<SettingsController>().placeLabel,
                      }),
                      style: AppTheme.body(
                        10.5,
                        weight: FontWeight.w600,
                        color: AppColors.emerald,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({this.dot, this.icon, required this.label});
  final Color? dot;
  final IconData? icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null)
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            )
          else
            Icon(icon, size: 13, color: AppColors.emerald),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTheme.body(
              10.5,
              weight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconBtn extends StatelessWidget {
  const _RoundIconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.hairline),
        ),
        child: Icon(icon, size: 19, color: AppColors.ink),
      ),
    );
  }
}

/// Degree ticks + gold Kaaba marker + emerald needle.
class _CompassPainter extends CustomPainter {
  _CompassPainter({required this.needleAngle, required this.heading});

  /// Radians, direction the needle points on the dial.
  final double needleAngle;
  final double? heading;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    // Disc
    canvas.drawCircle(
      c,
      r - 5,
      Paint()
        ..color = AppColors.ivory
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      c,
      r - 5,
      Paint()
        ..color = AppColors.hairline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawCircle(
      c,
      r - 5,
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Ticks — rotate the whole dial by -heading so N follows reality.
    final dialRot = -(heading ?? 0) * math.pi / 180;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(dialRot);

    final major = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final minor = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.6)
      ..strokeWidth = 0.8;

    for (var deg = 0; deg < 360; deg += 10) {
      final isMajor = deg % 30 == 0;
      final len = isMajor ? 9.0 : 5.0;
      final rad = deg * math.pi / 180;
      final p1 = Offset(math.sin(rad) * (r - 16), -math.cos(rad) * (r - 16));
      final p2 = Offset(
        math.sin(rad) * (r - 16 - len),
        -math.cos(rad) * (r - 16 - len),
      );
      canvas.drawLine(p1, p2, isMajor ? major : minor);
    }

    // Cardinal letters
    const dirs = {'N': 0.0, 'E': 90.0, 'S': 180.0, 'W': 270.0};
    for (final e in dirs.entries) {
      final rad = e.value * math.pi / 180;
      final tp = TextPainter(
        text: TextSpan(
          text: e.key,
          style: TextStyle(
            color: e.key == 'N' ? AppColors.emerald : AppColors.sage,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final p = Offset(math.sin(rad) * (r - 34), -math.cos(rad) * (r - 34));
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
    canvas.restore();

    // Kaaba marker at qibla bearing (fixed on dial)
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(needleAngle);
    final markerY = -(r - 16);
    canvas.drawCircle(
      Offset(0, markerY),
      13,
      Paint()..color = AppColors.goldTint,
    );
    canvas.drawCircle(
      Offset(0, markerY),
      13,
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final kaabaPaint = Paint()..color = AppColors.emeraldDeep;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(0, markerY), width: 9, height: 9),
      kaabaPaint,
    );
    canvas.restore();

    // Emerald needle toward marker
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(needleAngle);
    final needle = Paint()
      ..color = AppColors.emerald
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, Offset(0, -(r - 34)), needle);
    canvas.drawCircle(
      Offset.zero,
      8,
      Paint()
        ..color = AppColors.surface
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset.zero,
      8,
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) =>
      old.needleAngle != needleAngle || old.heading != heading;
}
