import 'package:flutter/material.dart';

import 'brew_fill_ring_painter.dart';
import 'pour_surface.dart';

// The ripple geometry and `pourCanvasLevel` moved to pour_surface.dart, where
// the per-frame ripple coefficients and the shared primary-path cache live;
// re-exported so existing importers keep resolving them from here.
export 'pour_surface.dart' show pourCanvasLevel, pourRippleOffset, pourDropX;

/// The last drop's radius, px. First tried at 7, which read as a speck at
/// phone scale — easy to miss entirely.
const double _pourDropRadius = 10.5;

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
///
/// Live frames: when [surface] is given, every paint reads the controller's
/// current [PourSurfaceFrame] — that is what lets a wave tick repaint the
/// liquid through the controller's `repaint` listenable without the widget
/// tree rebuilding. The constructor's level/phase/amplitude fields are then
/// only the fallback values used when no [surface] is supplied (tests, and
/// any caller that drives the painter through plain widget rebuilds).
class PourLiquidPainter extends CustomPainter {
  PourLiquidPainter({
    required this.level,
    required this.wavePhase,
    required this.waveAmplitude,
    required this.fillColor,
    this.dropProgress,
    this.rippleProgress,
    this.headroom = 0,
    this.surface,
  }) : super(repaint: surface);

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

  /// The live frame source, when the caller drives repaints through a
  /// [PourSurfaceController] instead of widget rebuilds. Also wired as this
  /// painter's `repaint` listenable.
  final PourSurfaceController? surface;

  /// The static frame built from the constructor fields — what gets painted
  /// when there is no [surface].
  late final PourSurfaceFrame _staticFrame = PourSurfaceFrame(
    level: level,
    wavePhase: wavePhase,
    waveAmplitude: waveAmplitude,
    dropProgress: dropProgress,
    rippleProgress: rippleProgress,
    headroom: headroom,
  );

  /// The frame this paint draws: the live one when a surface drives the
  /// repaints, otherwise the constructor values.
  PourSurfaceFrame get _frame => surface?.frame ?? _staticFrame;

  @override
  void paint(Canvas canvas, Size size) {
    final PourSurfaceFrame frame = _frame;
    if (frame.level <= 0) return;
    final double canvasLevel = pourCanvasLevel(
      frame.level,
      frame.headroom,
      size,
    );

    // Hoisted once per paint (not per 4px sample): the ripple's per-frame
    // coefficients.
    final double? ripple = frame.rippleProgress;
    final double Function(double x)? surfaceOffset = ripple == null
        ? null
        : (surface?.rippleFor(frame, size) ?? PourRippleField.of(size, ripple))
              .offsetAt;

    canvas.save();
    // Keep a wave crest — or the drop, before it enters — inside the
    // widget's own bounds.
    canvas.clipRect(Offset.zero & size);
    canvas.drawPath(
      // The primary path comes from the surface's cache when there is one,
      // so this fill and the text clipper's clip are literally the same
      // object, built from the same frame snapshot.
      surface?.primaryPathFor(frame, size) ??
          buildBrewWavePath(
            size: size,
            fillLevel: canvasLevel,
            waveAmplitude: frame.waveAmplitude,
            phase: frame.wavePhase,
            surfaceOffset: surfaceOffset,
          ),
      Paint()..color = fillColor,
    );
    canvas.drawPath(
      buildBrewWavePath(
        size: size,
        fillLevel: canvasLevel,
        waveAmplitude: frame.waveAmplitude,
        phase: frame.wavePhase + secondaryWavePhaseOffset,
        surfaceOffset: surfaceOffset,
      ),
      Paint()..color = fillColor.withValues(alpha: secondaryWaveAlpha),
    );
    final double? drop = frame.dropProgress;
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
    final double x = size.width * pourDropX;
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
    if (oldDelegate.fillColor != fillColor) return true;
    final PourSurfaceController? oldSurface = oldDelegate.surface;
    final PourSurfaceController? newSurface = surface;
    if ((oldSurface == null) != (newSurface == null)) return true;
    if (newSurface != null) {
      // Live mode: frame changes arrive through the repaint listenable, so a
      // replacement painter only needs to repaint if the fill colour moved
      // (checked above) or the frame source itself changed.
      return oldSurface != newSurface;
    }
    // Static mode: the constructor fields are the geometry.
    return oldDelegate._staticFrame != _staticFrame;
  }
}
