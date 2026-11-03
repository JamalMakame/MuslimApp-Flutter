import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:get/get.dart';

import '../../theme/app_theme.dart';
import 'motion.dart';

/// A burst of confetti over the whole screen with [message] in a banner,
/// gone after a few seconds. Plays `assets/rive/celebration.riv` instead of
/// the confetti when it is bundled. Does nothing without an overlay.
void celebrate(BuildContext? context, String message) {
  final overlay = context == null
      ? null
      : Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  HapticFeedback.mediumImpact();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Celebration(message: message, onDone: entry.remove),
  );
  overlay.insert(entry);
}

/// [celebrate] with [message] when [reached] is true.
void celebrateIf(bool reached, String message) {
  if (reached) celebrate(Get.overlayContext, message);
}

class _Celebration extends StatefulWidget {
  const _Celebration({required this.message, required this.onDone});
  final String message;
  final VoidCallback onDone;

  @override
  State<_Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<_Celebration>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti = ConfettiController(
    duration: const Duration(seconds: 2),
  )..play();
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onDone();
        })
        ..forward();

  @override
  void dispose() {
    _c.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pop = CurvedAnimation(
      parent: _c,
      curve: const Interval(0, 0.2, curve: Curves.elasticOut),
    );
    final fade = CurvedAnimation(parent: _c, curve: const Interval(0.85, 1));
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: DeenRive(
              'celebration',
              fit: BoxFit.cover,
              fallback: Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirection: math.pi / 2,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.06,
                  numberOfParticles: 18,
                  gravity: 0.25,
                  colors: const [
                    AppColors.gold,
                    AppColors.brand,
                    Color(0xFFF4D58D),
                    Color(0xFF2BB673),
                    Colors.white,
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.55),
            child: FadeTransition(
              opacity: ReverseAnimation(fade),
              child: ScaleTransition(
                scale: pop,
                child: Material(
                  key: const ValueKey('celebration'),
                  color: Colors.transparent,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.gold),
                      boxShadow: const [
                        BoxShadow(color: Color(0x400A4A3F), blurRadius: 24),
                      ],
                    ),
                    child: Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: AppTheme.body(
                        15,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
