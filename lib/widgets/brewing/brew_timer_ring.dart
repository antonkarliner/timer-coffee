import 'package:flutter/material.dart';

import 'brew_fill_ring_painter.dart';

/// The brewing timer ring (plan 061 Direction B): a circular track with the
/// step-progress arc, plus an optional "pour complete" liquid fill whose
/// surface is a two-layer sine wave. Presentation only — all animation state
/// arrives as plain values; the caller drives them from its own controller.
///
/// Widget shape is intentionally **stable**: it always returns the same
/// `SizedBox > Stack > [CustomPaint, Opacity(countdown)]` tree whether the
/// ring is empty, mid-brew, or in the end sequence. Swapping the widget type
/// at a tree position makes Flutter destroy and recreate the subtree element,
/// which re-runs `initState` on the countdown (see CLAUDE.md's remount trap),
/// so state changes are passed as painter values instead.
class BrewTimerRing extends StatelessWidget {
  const BrewTimerRing({
    super.key,
    required this.diameter,
    required this.progress,
    required this.fillLevel,
    required this.wavePhase,
    required this.waveAmplitude,
    required this.ringColor,
    required this.trackColor,
    required this.fillColor,
    required this.strokeWidth,
    required this.countdownOpacity,
    this.countdown,
  });

  /// Ring diameter in logical px (120–132 depending on screen width).
  final double diameter;

  /// Arc sweep as a fraction of a full circle, 0..1, from 12 o'clock
  /// clockwise.
  final double progress;

  /// Liquid height inside the ring, 0 (empty) .. 1 (full). 0 draws no fill.
  final double fillLevel;

  /// Wave surface phase, radians.
  final double wavePhase;

  /// Wave surface amplitude, px. Already decayed by the caller.
  final double waveAmplitude;

  /// Colour of the progress arc.
  final Color ringColor;

  /// Colour of the full track circle.
  final Color trackColor;

  /// Body colour of the liquid.
  final Color fillColor;

  /// Stroke width of track and arc.
  final double strokeWidth;

  /// Visual opacity of the countdown slot, 0..1. The slot itself is always
  /// present in the tree (R3); only its paint opacity changes.
  final double countdownOpacity;

  /// The countdown content (e.g. the step time). Held inside an always-present
  /// opacity slot; may be null, in which case the slot is empty.
  final Widget? countdown;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: BrewFillRingPainter(
                progress: progress,
                fillLevel: fillLevel,
                wavePhase: wavePhase,
                waveAmplitude: waveAmplitude,
                ringColor: ringColor,
                trackColor: trackColor,
                fillColor: fillColor,
                strokeWidth: strokeWidth,
              ),
            ),
          ),
          // Always present; visually faded but never *removed* — removal
          // would change the tree shape and remount the countdown (R3).
          Opacity(
            opacity: countdownOpacity.clamp(0.0, 1.0),
            child: countdown ?? const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
