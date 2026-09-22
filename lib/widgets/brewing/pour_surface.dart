import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'brew_fill_ring_painter.dart';

// ── Pour liquid surface: frames, the live listenable, ripple geometry ──
//
// Performance plumbing for the Pour brewing presentation (plan 066): the
// liquid repaints on every wave tick, but the countdown/instruction/next-step
// content around it must not rebuild. The screen derives one immutable
// [PourSurfaceFrame] per animation tick and hands it to a
// [PourSurfaceController]; the liquid painter (`repaint`) and the text
// clipper (`reclip`) listen to the controller, so a tick only repaints the
// surface layers — no widget rebuild.

/// Horizontal position of the last drop, as a fraction of the width.
///
/// Public because the painter's drop and the ripple field below must agree on
/// where the drop lands. (Moved here from pour_liquid_painter.dart with the
/// ripple geometry.)
const double pourDropX = 0.5;

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
///
/// (Moved here from pour_liquid_painter.dart, which re-exports it: it now
/// also feeds the shared primary-path cache below.)
double pourCanvasLevel(double level, double headroom, Size size) {
  if (size.height <= 0) return level;
  final double room = headroom.clamp(0.0, size.height);
  return level * (1 - room / size.height);
}

/// The last drop's ripple, with its per-frame coefficients hoisted out of the
/// per-sample path loop.
///
/// `pourRippleOffset(x, size, progress)` used to recompute the packet width,
/// wavelength, fade and the bob's time terms for every 4px sample of the wave
/// path — three paths per frame. All of those depend only on
/// [PourSurfaceFrame.rippleProgress] and [size], so this class computes them
/// once per frame and [offsetAt] keeps only the per-x arithmetic — the same
/// operations, with the loop-invariants already evaluated. The formula and
/// the visual geometry are unchanged.
class PourRippleField {
  factory PourRippleField.of(Size size, double rippleProgress) {
    final double p = rippleProgress;
    final double impactX = size.width * pourDropX;
    final double width = _pourRipplePacketWidth * (1 + _pourRippleSpread * p);
    final double wavelength =
        _pourRippleWavelength * (1 + _pourRippleStretch * p);
    final double travelled = size.width * _pourRippleReach * p;
    final double fade = math.pow(1 - p, 1.5).toDouble();
    final double spreadLoss = math.sqrt(_pourRipplePacketWidth / width);
    final double bobTime = (1 - p) * math.exp(-4 * p);
    final double bobPhase = math.sin(2 * math.pi * _pourImpactBobCycles * p);
    return PourRippleField._(
      impactX,
      width,
      wavelength,
      travelled,
      fade,
      spreadLoss,
      bobTime,
      bobPhase,
    );
  }

  const PourRippleField._(
    this._impactX,
    this._width,
    this._wavelength,
    this._travelled,
    this._fade,
    this._spreadLoss,
    this._bobTime,
    this._bobPhase,
  );

  final double _impactX;
  final double _width;
  final double _wavelength;
  final double _travelled;
  final double _fade;
  final double _spreadLoss;
  final double _bobTime;
  final double _bobPhase;

  /// How much the ripple raises the surface at [x], px (negative = dip).
  double offsetAt(double x) {
    final double fromImpact = x - _impactX;

    // Outgoing packets, spreading as they travel. Height falls as the packet
    // widens (energy spread over more water), on top of the fade over time.
    final double distance = fromImpact.abs() - _travelled;
    final double envelope = math.exp(
      -(distance * distance) / (2 * _width * _width),
    );
    final double outgoing =
        -_pourRippleAmplitude *
        _fade *
        _spreadLoss *
        envelope *
        math.cos(2 * math.pi * distance / _wavelength);

    // The impact point bobbing: starts level (the outgoing trough already
    // makes the dip), springs up, and settles.
    final double bob =
        _pourImpactBobAmplitude *
        _bobTime *
        math.exp(
          -(fromImpact * fromImpact) /
              (2 * _pourImpactBobWidth * _pourImpactBobWidth),
        ) *
        _bobPhase;

    return outgoing + bob;
  }
}

/// How much the last drop's ripple raises the liquid surface at [x], px.
///
/// Kept as the shared entry point to the ripple maths; inside per-sample path
/// loops prefer a hoisted [PourRippleField] instead.
double pourRippleOffset(double x, Size size, double rippleProgress) =>
    PourRippleField.of(size, rippleProgress).offsetAt(x);

/// One immutable snapshot of the Pour liquid's geometry, good for a single
/// rendered frame.
///
/// Everything the liquid painter and the text clipper derive their curves
/// from: the fill [level] (0 empty .. 1 full), the wave [wavePhase] and
/// [waveAmplitude], the ending's [dropProgress] and [rippleProgress] (null
/// outside their windows), and the [headroom] band under the app bar. Frames
/// are value-compared ([==]) and only ever replaced, never mutated, so they
/// are safe cache keys for the shared primary path.
@immutable
class PourSurfaceFrame {
  const PourSurfaceFrame({
    required this.level,
    required this.wavePhase,
    required this.waveAmplitude,
    this.dropProgress,
    this.rippleProgress,
    this.headroom = 0,
  });

  /// Liquid height, 0 (empty) .. 1 (full).
  final double level;

  /// Wave surface phase, radians. Monotonic — never wraps.
  final double wavePhase;

  /// Wave surface amplitude, px. 0 for a flat (reduced-motion/web) surface.
  final double waveAmplitude;

  /// The last drop's fall, 0..1, or null when no drop is falling.
  final double? dropProgress;

  /// The last drop's ripple, 0..1, or null when there is no ripple.
  final double? rippleProgress;

  /// Empty space above a full cup, px. See [pourCanvasLevel].
  final double headroom;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PourSurfaceFrame &&
        other.level == level &&
        other.wavePhase == wavePhase &&
        other.waveAmplitude == waveAmplitude &&
        other.dropProgress == dropProgress &&
        other.rippleProgress == rippleProgress &&
        other.headroom == headroom;
  }

  @override
  int get hashCode => Object.hash(
    level,
    wavePhase,
    waveAmplitude,
    dropProgress,
    rippleProgress,
    headroom,
  );
}

/// Holds the current [PourSurfaceFrame] and tells the surface's render
/// objects when it changes.
///
/// This is the repaint vehicle that lets a wave tick skip the widget rebuild:
/// the screen's tick listener replaces [frame] here, and the liquid painter's
/// `repaint` and the text clipper's `reclip` (both wired to this listenable)
/// mark their render objects for paint — nothing above them rebuilds.
///
/// The controller also owns the one shared primary wave path: the painter
/// fills with it and the text clipper clips with it, so the text's colour
/// boundary is not a second approximation of the surface but the very same
/// [Path]. The cache is a single entry keyed by frame identity and size —
/// frames are immutable and replaced on every geometry change, so identity is
/// a complete invalidation key; there is no unbounded growth.
///
/// Owned by the brewing screen's State, which creates it in initState and
/// disposes it in dispose — nothing in the widget tree disposes it for the
/// screen (the view deliberately leaves a supplied controller alone).
class PourSurfaceController extends ChangeNotifier {
  PourSurfaceController([PourSurfaceFrame? initial])
    : _frame =
          initial ??
          const PourSurfaceFrame(level: 0, wavePhase: 0, waveAmplitude: 0);

  PourSurfaceFrame _frame;

  /// The frame the surface currently paints with.
  PourSurfaceFrame get frame => _frame;

  /// Replaces the frame and notifies the painter and the clipper. Writing an
  /// equal frame is a no-op, so redundant writes (listener + rebuild in the
  /// same animation frame) cost nothing.
  set frame(PourSurfaceFrame value) {
    if (value == _frame) return;
    _frame = value;
    notifyListeners();
  }

  // The single cached primary path. Both keys must match for a hit; a frame
  // object is only ever current while its values are, because [frame] is
  // replaced (never mutated) whenever the geometry changes.
  PourSurfaceFrame? _cachedPathFrame;
  Size? _cachedPathSize;
  Path? _cachedPath;
  PourRippleField? _cachedRipple;

  void _prepareGeometry(PourSurfaceFrame frame, Size size) {
    if (identical(_cachedPathFrame, frame) && _cachedPathSize == size) return;
    _cachedPathFrame = frame;
    _cachedPathSize = size;
    _cachedPath = null;
    final ripple = frame.rippleProgress;
    _cachedRipple = ripple == null ? null : PourRippleField.of(size, ripple);
  }

  /// Shared coefficients for both waves and the text clip, once per frame.
  PourRippleField? rippleFor(PourSurfaceFrame frame, Size size) {
    _prepareGeometry(frame, size);
    return _cachedRipple;
  }

  /// One primary path shared by the painter and clipper for this frame/size.
  Path primaryPathFor(PourSurfaceFrame frame, Size size) {
    _prepareGeometry(frame, size);
    return _cachedPath ??= buildBrewWavePath(
      size: size,
      fillLevel: pourCanvasLevel(frame.level, frame.headroom, size),
      waveAmplitude: frame.waveAmplitude,
      phase: frame.wavePhase,
      surfaceOffset: _cachedRipple?.offsetAt,
    );
  }

  @override
  void dispose() {
    // Drop the cached geometry before super so a disposed controller holds
    // no path.
    _cachedPathFrame = null;
    _cachedPathSize = null;
    _cachedPath = null;
    _cachedRipple = null;
    super.dispose();
  }
}
