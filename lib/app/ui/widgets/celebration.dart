import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// A burst of confetti over the whole screen, with [message] in a banner;
/// removes itself after a few seconds.
void celebrate(BuildContext context, String message) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  final confetti = ConfettiController(duration: const Duration(seconds: 2))
    ..play();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => IgnorePointer(
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: confetti,
              blastDirection: math.pi / 2,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.06,
              numberOfParticles: 18,
              gravity: 0.25,
              colors: const [
                AppColors.gold,
                Color(0xFF0E6B5C),
                Color(0xFFF4D58D),
                Color(0xFF2BB673),
                Colors.white,
              ],
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.55),
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
                ),
                child: Text(
                  message,
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
        ],
      ),
    ),
  );
  overlay.insert(entry);
  Future.delayed(const Duration(seconds: 4), () {
    entry.remove();
    confetti.dispose();
  });
}
