import 'package:flutter/material.dart';

import 'brew_fill_ring_painter.dart';

/// Paints the "Pour" brewing layout's liquid: a rectangle of coffee rising
/// from the bottom of the canvas up to [level], whose surface is the shared
/// two-layer sine wave from [buildBrewWavePath] — the exact maths the
/// end-of-brew ring fill uses, so both brewing presentations draw the same
/// liquid in light and dark.
///
/// Paint order per frame: the primary wave surface at [wavePhase] in
/// [fillColor], then a second wave at `wavePhase + secondaryWavePhaseOffset`
/// in `fillColor` at reduced alpha — exactly the two-call structure
/// `BrewFillRingPainter` uses. The canvas rect is clipped first so a wave
/// crest can never paint above the widget's own bounds. No `saveLayer`
/// anywhere — one `clipRect` plus two `drawPath` calls, which stays cheap on
/// web/Skwasm and older Android.
///
/// Reduced motion is entirely the caller's concern: passing
/// `waveAmplitude: 0` yields a flat surface, so this painter has no motion
/// flag or special case of its own.
class PourLiquidPainter extends CustomPainter {
  PourLiquidPainter({
    required this.level,
    required this.wavePhase,
    required this.waveAmplitude,
    required this.fillColor,
  });

  /// Liquid height, 0 (empty) .. 1 (full). At 0 or below nothing is painted.
  final double level;

  /// Wave surface phase, radians.
  final double wavePhase;

  /// Wave surface amplitude, px. The caller passes 0 for reduced motion.
  final double waveAmplitude;

  /// Body colour of the liquid. The secondary wave layer is this colour at
  /// reduced alpha, not a second hex.
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (level <= 0) return;

    canvas.save();
    // Keep a wave crest inside the widget's own bounds.
    canvas.clipRect(Offset.zero & size);
    canvas.drawPath(
      buildBrewWavePath(
        size: size,
        fillLevel: level,
        waveAmplitude: waveAmplitude,
        phase: wavePhase,
      ),
      Paint()..color = fillColor,
    );
    canvas.drawPath(
      buildBrewWavePath(
        size: size,
        fillLevel: level,
        waveAmplitude: waveAmplitude,
        phase: wavePhase + secondaryWavePhaseOffset,
      ),
      Paint()..color = fillColor.withValues(alpha: secondaryWaveAlpha),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PourLiquidPainter oldDelegate) {
    return oldDelegate.level != level ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.waveAmplitude != waveAmplitude ||
        oldDelegate.fillColor != fillColor;
  }
}
