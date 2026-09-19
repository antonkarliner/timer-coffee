import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'brew_fill_ring_painter.dart';

/// Horizontal position of the last drop, as a fraction of the width.
const double _pourDropX = 0.5;

/// The last drop's radius, px. First tried at 7, which read as a speck at
/// phone scale — easy to miss entirely.
const double _pourDropRadius = 10.5;

/// Peak height of the ripple the last drop raises, px.
const double _pourRippleAmplitude = 8.0;

/// How far the ripple's two fronts travel by the time it dies out, as a
/// fraction of the width — far enough to reach the screen's edges.
const double _pourRippleReach = 0.55;

/// Width of each travelling wave packet at impact (Gaussian sigma), px. It
/// widens as it travels — see [_pourRippleSpread].
const double _pourRipplePacketWidth = 28.0;

/// Wavelength of the ripple at impact, px. It lengthens as it travels —
/// see [_pourRippleStretch].
const double _pourRippleWavelength = 46.0;

/// How much wider each packet is by the time it dies out (1 = twice as
/// wide). A packet that keeps one fixed shape the whole way read as a
/// graphic sliding across the surface; real ripples spread and flatten.
const double _pourRippleSpread = 1.2;

/// How much longer the ripple's wavelength is by the time it dies out.
const double _pourRippleStretch = 0.5;

/// Peak height of the bob at the impact point, px.
const double _pourImpactBobAmplitude = 6.0;

/// Width of the impact bob (Gaussian sigma), px.
const double _pourImpactBobWidth = 16.0;

/// How many times the impact point bobs up and down before it settles.
const double _pourImpactBobCycles = 2.5;

/// Converts a cup [level] (0 empty .. 1 full) into a fraction of the whole
/// canvas height, for a cup whose "full" line is [headroom] px below the top
/// of the canvas. Shared by the painter and the view's text clipper so the
/// coffee and the text's colour boundary sit at the same height.
double pourCanvasLevel(double level, double headroom, Size size) {
  if (size.height <= 0) return level;
  final double room = headroom.clamp(0.0, size.height);
  return level * (1 - room / size.height);
}

/// How much the last drop's ripple raises the liquid surface at [x], px.
///
/// The view is a side-on cross-section of the cup, so the familiar top-down
/// image of a ring spreading out would not read. Side-on, a drop landing
/// does two things, and this models both:
///
/// * It punches a small dip at the impact point, which springs back as a
///   bump and bobs a couple of times before settling — a damped oscillation
///   pinned to the impact.
/// * It sends a wave packet travelling outward in *both* directions. Each
///   packet leaves as a trough (the crater's edge), and spreads out and
///   flattens as it goes — wider, longer-waved and lower — instead of
///   sliding along as one fixed shape.
///
/// Everything dies away to exactly zero at [rippleProgress] 1.
///
/// Shared by [PourLiquidPainter] and the view's text clipper, so the
/// coffee's surface and the text's colour boundary ripple as one.
double pourRippleOffset(double x, Size size, double rippleProgress) {
  final double p = rippleProgress;
  final double impactX = size.width * _pourDropX;
  final double fromImpact = x - impactX;

  // Outgoing packets, spreading as they travel. Height falls as the packet
  // widens (energy spread over more water), on top of the fade over time.
  final double width = _pourRipplePacketWidth * (1 + _pourRippleSpread * p);
  final double wavelength =
      _pourRippleWavelength * (1 + _pourRippleStretch * p);
  final double travelled = size.width * _pourRippleReach * p;
  final double distance = fromImpact.abs() - travelled;
  final double envelope = math.exp(
    -(distance * distance) / (2 * width * width),
  );
  final double spreadLoss = math.sqrt(_pourRipplePacketWidth / width);
  final double fade = math.pow(1 - p, 1.5).toDouble();
  final double outgoing =
      -_pourRippleAmplitude *
      fade *
      spreadLoss *
      envelope *
      math.cos(2 * math.pi * distance / wavelength);

  // The impact point bobbing: starts level (the outgoing trough already
  // makes the dip), springs up, and settles.
  final double bob =
      _pourImpactBobAmplitude *
      (1 - p) *
      math.exp(-4 * p) *
      math.exp(
        -(fromImpact * fromImpact) /
            (2 * _pourImpactBobWidth * _pourImpactBobWidth),
      ) *
      math.sin(2 * math.pi * _pourImpactBobCycles * p);

  return outgoing + bob;
}

/// Paints the "Pour" brewing layout's liquid: a rectangle of coffee rising
/// from the bottom of the canvas up to [level], whose surface is the shared
/// two-layer sine wave from [buildBrewWavePath] — the exact maths the
/// end-of-brew ring fill uses, so both brewing presentations draw the same
/// liquid in light and dark.
///
/// Paint order per frame: the primary wave surface at [wavePhase] in
/// [fillColor], then a second wave at `wavePhase + secondaryWavePhaseOffset`
/// in `fillColor` at reduced alpha — exactly the two-call structure
/// `BrewFillRingPainter` uses — then, during the ending, the last drop. The
/// canvas rect is clipped first so nothing paints outside the widget's own
/// bounds. No `saveLayer` anywhere — one `clipRect` plus a handful of
/// `drawPath` calls, which stays cheap on web/Skwasm and older Android.
///
/// Reduced motion is entirely the caller's concern: passing
/// `waveAmplitude: 0` yields a flat surface and passing no drop or ripple
/// skips the ending's motion, so this painter has no motion flag of its own.
class PourLiquidPainter extends CustomPainter {
  PourLiquidPainter({
    required this.level,
    required this.wavePhase,
    required this.waveAmplitude,
    required this.fillColor,
    this.dropProgress,
    this.rippleProgress,
    this.headroom = 0,
  });

  /// Liquid height, 0 (empty) .. 1 (full). At 0 or below nothing is painted.
  /// "Full" is [headroom] px below the top of the canvas.
  final double level;

  /// Empty space above a full cup, px. See [pourCanvasLevel].
  final double headroom;

  /// Wave surface phase, radians.
  final double wavePhase;

  /// Wave surface amplitude, px. The caller passes 0 for reduced motion.
  final double waveAmplitude;

  /// Body colour of the liquid. The secondary wave layer is this colour at
  /// reduced alpha, not a second hex.
  final Color fillColor;

  /// The last drop's fall, 0 (just above the canvas) .. 1 (touching the
  /// surface), or null when no drop is falling.
  final double? dropProgress;

  /// The last drop's ripple, 0 (impact) .. 1 (died out), or null when there
  /// is no ripple.
  final double? rippleProgress;

  @override
  void paint(Canvas canvas, Size size) {
    if (level <= 0) return;
    final double canvasLevel = pourCanvasLevel(level, headroom, size);

    final double? ripple = rippleProgress;
    final double Function(double x)? surfaceOffset = ripple == null
        ? null
        : (double x) => pourRippleOffset(x, size, ripple);

    canvas.save();
    // Keep a wave crest — or the drop, before it enters — inside the
    // widget's own bounds.
    canvas.clipRect(Offset.zero & size);
    canvas.drawPath(
      buildBrewWavePath(
        size: size,
        fillLevel: canvasLevel,
        waveAmplitude: waveAmplitude,
        phase: wavePhase,
        surfaceOffset: surfaceOffset,
      ),
      Paint()..color = fillColor,
    );
    canvas.drawPath(
      buildBrewWavePath(
        size: size,
        fillLevel: canvasLevel,
        waveAmplitude: waveAmplitude,
        phase: wavePhase + secondaryWavePhaseOffset,
        surfaceOffset: surfaceOffset,
      ),
      Paint()..color = fillColor.withValues(alpha: secondaryWaveAlpha),
    );
    final double? drop = dropProgress;
    if (drop != null) _paintDrop(canvas, size, canvasLevel, drop);
    canvas.restore();
  }

  /// A teardrop falling under gravity (ease-in) from just above the canvas to
  /// the surface, stretching slightly as it gains speed. The surface is calm
  /// by the time it falls, so the flat-surface height is where it lands.
  void _paintDrop(
    Canvas canvas,
    Size size,
    double canvasLevel,
    double progress,
  ) {
    final double fall = Curves.easeIn.transform(progress);
    final double surfaceY = size.height * (1 - canvasLevel);
    final double x = size.width * _pourDropX;
    final double startY = -_pourDropRadius * 3;
    final double endY = surfaceY - _pourDropRadius;
    final double y = startY + (endY - startY) * fall;

    // Round at the bottom, drawn out to a point above; the point lengthens
    // with speed, which is what makes it read as falling rather than sliding.
    final double tail = _pourDropRadius * (1.6 + 1.2 * fall);
    final Path teardrop = Path()
      ..moveTo(x, y - tail)
      ..quadraticBezierTo(
        x + _pourDropRadius,
        y - _pourDropRadius * 0.4,
        x + _pourDropRadius,
        y,
      )
      ..arcToPoint(
        Offset(x - _pourDropRadius, y),
        radius: const Radius.circular(_pourDropRadius),
      )
      ..quadraticBezierTo(
        x - _pourDropRadius,
        y - _pourDropRadius * 0.4,
        x,
        y - tail,
      )
      ..close();
    canvas.drawPath(teardrop, Paint()..color = fillColor);
  }

  @override
  bool shouldRepaint(covariant PourLiquidPainter oldDelegate) {
    return oldDelegate.level != level ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.waveAmplitude != waveAmplitude ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.dropProgress != dropProgress ||
        oldDelegate.rippleProgress != rippleProgress ||
        oldDelegate.headroom != headroom;
  }
}
