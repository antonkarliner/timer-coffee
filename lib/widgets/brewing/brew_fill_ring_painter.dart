import 'dart:math' as math;

import 'package:flutter/material.dart';

// ── Wave geometry (painter math, not layout spacing) ──
//
// Shared by BrewFillRingPainter and PourLiquidPainter: both brewing
// presentations draw their liquid surface with [buildBrewWavePath], so the
// end-of-brew ring fill and the Pour view are provably the same liquid in
// both themes.

/// Horizontal sampling step of the wave surface, px.
const double _waveStepPx = 4.0;

/// Whole wave cycles across the diameter for the primary/secondary layers.
const double _waveCyclesPrimary = 1.5;
const double _waveCyclesSecondary = 2.5;

/// Phase offset and drift speed of the depth layer. The offset is public
/// because the Pour painter composes its own second layer with it too.
const double secondaryWavePhaseOffset = math.pi / 2;
const double _secondaryWaveSpeed = 1.3;

/// Alpha of the secondary wave layer. Public for the same reason as
/// [secondaryWavePhaseOffset]: the Pour painter draws its depth layer with it.
const double secondaryWaveAlpha = 0.5;

/// Builds the liquid surface shared by the brewing presentations: a composite
/// sine wave whose baseline sits at the fill level, closed down the right
/// edge, along the bottom, and up the left edge.
///
/// Pure geometry — callers own the clipping and the two-layer draw order.
Path buildBrewWavePath({
  required Size size,
  required double fillLevel,
  required double waveAmplitude,
  required double phase,
}) {
  double surfaceY(double x) {
    final double k1 = 2 * math.pi * _waveCyclesPrimary / size.width;
    final double k2 = 2 * math.pi * _waveCyclesSecondary / size.width;
    return size.height * (1 - fillLevel) -
        waveAmplitude * math.sin(k1 * x + phase) -
        0.5 * waveAmplitude * math.sin(k2 * x - _secondaryWaveSpeed * phase);
  }

  final Path path = Path()..moveTo(0, surfaceY(0));
  for (double x = _waveStepPx; x < size.width; x += _waveStepPx) {
    path.lineTo(x, surfaceY(x));
  }
  // Land the final sample exactly on the right edge.
  path.lineTo(size.width, surfaceY(size.width));
  path.lineTo(size.width, size.height);
  path.lineTo(0, size.height);
  path.close();
  return path;
}

/// Paints the brewing timer ring for plan 061 Direction B: a circular track,
/// an optional "settled liquid" fill whose surface is a two-layer sine wave,
/// and the step-progress arc on top.
///
/// Paint order per frame: track circle, then (when [fillLevel] > 0) the wave
/// fill clipped to the circle inset by [strokeWidth] / 2, then the progress
/// arc. No `saveLayer` anywhere — the fill is one `clipPath` plus two
/// `drawPath` calls, which stays cheap on web/Skwasm and older Android.
///
/// Geometry is derived entirely from `size`, never from a fixed diameter:
/// the ring is 120-132 px depending on screen width, and the wave numbers
/// (whole cycles across the diameter) keep the wavelength identical on every
/// device. The arc reproduces `CircularProgressIndicator`'s determinate
/// geometry exactly — butt caps, centreline radius
/// `(shortestSide - strokeWidth) / 2`, starting at 12 o'clock, sweeping
/// clockwise — so the custom painter is a drop-in replacement for it.
class BrewFillRingPainter extends CustomPainter {
  BrewFillRingPainter({
    required this.progress,
    required this.fillLevel,
    required this.wavePhase,
    required this.waveAmplitude,
    required this.ringColor,
    required this.trackColor,
    required this.fillColor,
    required this.strokeWidth,
    super.repaint,
  });

  /// Arc sweep as a fraction of a full circle, 0..1, drawn from 12 o'clock
  /// clockwise.
  final double progress;

  /// Liquid height inside the ring, 0 (empty) .. 1 (full).
  final double fillLevel;

  /// Wave surface phase, radians.
  final double wavePhase;

  /// Wave surface amplitude, px. Already decayed by the caller.
  final double waveAmplitude;

  /// Colour of the progress arc (the normal ring colour, also during the
  /// end sequence — plan 061 R6).
  final Color ringColor;

  /// Colour of the full track circle.
  final Color trackColor;

  /// Body colour of the liquid. The secondary wave layer is this colour at
  /// reduced alpha, not a second hex.
  final Color fillColor;

  /// Stroke width of track and arc.
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.shortestSide - strokeWidth) / 2;

    // 1. Track circle.
    final Paint trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, trackPaint);

    // 2. Liquid fill, clipped so it never spills over the stroke.
    if (fillLevel > 0) {
      canvas.save();
      final Rect clipRect = Rect.fromCircle(
        center: center,
        radius: size.shortestSide / 2 - strokeWidth / 2,
      );
      canvas.clipPath(Path()..addOval(clipRect));
      canvas.drawPath(
        buildBrewWavePath(
          size: size,
          fillLevel: fillLevel,
          waveAmplitude: waveAmplitude,
          phase: wavePhase,
        ),
        Paint()..color = fillColor,
      );
      canvas.drawPath(
        buildBrewWavePath(
          size: size,
          fillLevel: fillLevel,
          waveAmplitude: waveAmplitude,
          phase: wavePhase + secondaryWavePhaseOffset,
        ),
        Paint()..color = fillColor.withValues(alpha: secondaryWaveAlpha),
      );
      canvas.restore();
    }

    // 3. Progress arc on top. Same geometry as the determinate
    // CircularProgressIndicator this painter replaces: butt cap, start at
    // -pi/2, clockwise sweep of 2*pi*progress.
    final Paint arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = ringColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant BrewFillRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.fillLevel != fillLevel ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.waveAmplitude != waveAmplitude ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
