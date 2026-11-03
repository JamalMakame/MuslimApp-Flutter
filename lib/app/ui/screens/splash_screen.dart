import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:get/get.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../controllers/app_controller.dart';
import '../../routes/app_pages.dart';
import '../../theme/app_theme.dart';
import '../widgets/motion.dart';

/// Emerald splash — geometric star rosette + dome emblem, gold
/// progress hairline. Routes once bundled data is parsed.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  )..repeat();
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..forward();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);
  late final Worker _readyWorker;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    final app = Get.find<AppController>();
    _readyWorker = ever(app.ready, (_) => _go());
    _progress.addStatusListener((s) {
      if (s == AnimationStatus.completed) _go();
    });
  }

  void _go() {
    final app = Get.find<AppController>();
    if (_navigated || !app.ready.value || !_progress.isCompleted) {
      return;
    }
    _navigated = true;
    Get.offAllNamed(app.onboarded ? Routes.home : Routes.onboarding);
  }

  @override
  void dispose() {
    _readyWorker.dispose();
    _spin.dispose();
    _pulse.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hijri = HijriCalendar.now();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          key: const ValueKey('splash-background'),
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.brand, Color(0xFF0B5448), AppColors.brandDeep],
            ),
          ),
          child: SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Gold hairline frame
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    const Spacer(flex: 2),
                    // Rosette + emblem
                    SizedBox(
                      width: 208,
                      height: 208,
                      child: DeenRive(
                        'splash',
                        fallback: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Ambient glow
                            Container(
                              width: 170,
                              height: 170,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gold.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 80,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            RotationTransition(
                              turns: _spin,
                              child: CustomPaint(
                                size: const Size(208, 208),
                                painter: _RosettePainter(),
                              ),
                            ),
                            ScaleTransition(
                              scale: Tween(begin: 0.94, end: 1.04).animate(
                                CurvedAnimation(
                                  parent: _pulse,
                                  curve: Curves.easeInOut,
                                ),
                              ),
                              child: Container(
                                width: 128,
                                height: 128,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.brandDeep.withValues(
                                    alpha: 0.55,
                                  ),
                                  border: Border.all(
                                    color: AppColors.gold.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                                child: Image.asset(
                                  'assets/images/deen_dome.png',
                                  width: 64,
                                  height: 64,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _progress,
                        curve: const Interval(0, 0.3, curve: Curves.easeOut),
                      ),
                      child: Text(
                        'appName'.tr,
                        style: AppTheme.headline(
                          42,
                          weight: FontWeight.w800,
                          color: AppColors.onBrand,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'tagline'.tr.toUpperCase(),
                      style: AppTheme.body(
                        11,
                        weight: FontWeight.w500,
                        color: AppColors.onBrand.withValues(alpha: 0.7),
                        letterSpacing: 3.4,
                      ),
                    ),
                    const Spacer(flex: 3),
                    // Progress hairline
                    SizedBox(
                      width: 176,
                      child: AnimatedBuilder(
                        animation: _progress,
                        builder: (_, __) => LinearProgressIndicator(
                          value: _progress.value,
                          minHeight: 2,
                          backgroundColor: AppColors.gold.withValues(
                            alpha: 0.2,
                          ),
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.gold,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      final app = Get.find<AppController>();
                      if (!app.bootFailed.value) {
                        return Text(
                          'preparing'.tr,
                          style: AppTheme.body(
                            12,
                            color: AppColors.onBrand.withValues(alpha: 0.6),
                          ),
                        );
                      }
                      return Column(
                        children: [
                          Text(
                            'bootFailed'.tr,
                            textAlign: TextAlign.center,
                            style: AppTheme.body(
                              12,
                              color: AppColors.onBrand.withValues(alpha: 0.8),
                            ),
                          ),
                          TextButton(
                            key: const ValueKey('boot-retry'),
                            onPressed: app.retryBoot,
                            child: Text(
                              'retry'.tr,
                              style: AppTheme.body(
                                13,
                                weight: FontWeight.w700,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 8),
                    Text(
                      'hijriYear'.trParams({'year': '${hijri.hYear}'}),
                      style: AppTheme.body(
                        10,
                        weight: FontWeight.w500,
                        color: AppColors.gold.withValues(alpha: 0.45),
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 8-pointed star rosette — two rotated squares + rings in thin gold.
class _RosettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawCircle(c, 96, paint..strokeWidth = 0.5);
    canvas.drawCircle(c, 90, paint..strokeWidth = 0.8);

    final side = 128.0;
    for (final angle in [0.0, math.pi / 4]) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: side, height: side),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
    canvas.drawCircle(c, 56, paint..strokeWidth = 0.7);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
