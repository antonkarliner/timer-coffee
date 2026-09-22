import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import 'brew_fill_ring_painter.dart';
import 'pour_liquid_painter.dart';
import 'pour_surface.dart';

/// The "Pour" brewing presentation (plan 066): the classic screen's
/// information, in the classic screen's order, with coffee rising behind it.
///
/// ## Hierarchy
///
/// Top to bottom it follows the production layout, whose order is deliberate:
///
///  1. the **step countdown**, dominant — time is the thing that moves and
///     presses, so it leads;
///  2. the **instruction**, directly beneath it;
///  3. the **next step**, small and secondary, bottom-left, so it never
///     competes for attention.
///
/// The step number lives in the screen's app bar, and pause in the screen's
/// floating button; neither belongs to this view.
///
/// An earlier version put the instruction above the countdown and added an
/// "elapsed / total" row under it. Both were wrong. The order inverted what
/// the production screen gets right, and the total row was a second moving
/// number restating what the liquid already shows. The liquid is now the one
/// and only whole-brew indicator — ambient, read at a glance, never a number
/// — while the countdown is the precise per-step time. Two questions ("where
/// am I in this step?", "how far through the brew?"), two channels, nothing
/// competing.
///
/// Presentation only: no state, no animation, no provider reads. Every value
/// arrives through the constructor, already localized and already formatted;
/// the caller owns the timers and the reduced-motion decision
/// (`waveAmplitude: 0` flattens the liquid surface).
///
/// ## Text colour follows the liquid line
///
/// The cup starts empty and fills as the brew runs, so any given line of text
/// may be above the coffee (dry) or below it (submerged), and the boundary
/// sweeps across it mid-brew. A single colour cannot serve both: white is
/// invisible on the light theme's pure-white surface (contrast 1.00), and
/// `onSurface` is near-invisible on the coffee.
///
/// So the content is laid out **twice**, in the same coordinate space as the
/// liquid painter:
///
///  * a **dry** copy in the scheme's `onSurface` / `onSurfaceVariant`, and
///  * a **submerged** copy in white, clipped to the very same wave path the
///    painter fills with.
///
/// The clip is per-pixel, so a glyph that straddles the surface is drawn part
/// dry and part submerged and the colour change tracks the wave exactly,
/// rather than popping when some threshold is crossed.
///
/// Only the dry copy carries `Semantics`: the two copies are identical
/// otherwise, and duplicating the identifiers would break every
/// `findsOneWidget` that looks them up. Note `ExcludeSemantics` would not do
/// here — the tests match `Semantics` *widgets* in the widget tree, not
/// nodes in the semantics tree.
///
/// ## Stable shape, stable position
///
/// Widget shape is intentionally **stable** in every state (see the remount
/// trap in CLAUDE.md — swapping the widget type at a tree position destroys
/// the subtree element and re-runs `initState` on whatever lives there): the
/// next-step, leading and trailing slots are always present and collapse to
/// `SizedBox.shrink()` when empty, the paused label is an always-present
/// `Visibility`, and [opacity] is applied with an always-present `Opacity`.
/// `withSemantics` is fixed per copy, so it never swaps a type either.
///
/// Position is stable too. The height is split into three fixed-proportion
/// regions, and each block is anchored to the region edge nearest its
/// neighbour, so nothing moves when content changes size:
///
///  * the countdown is bottom-anchored in the top region and the instruction
///    top-anchored in the middle one, so the two meet at a fixed boundary and
///    a longer instruction grows *downward*, away from the numbers;
///  * the next step is bottom-anchored in the bottom region and grows upward;
///  * the paused label keeps its space when hidden, so pausing does not nudge
///    the countdown up.
class PourBrewingView extends StatelessWidget {
  const PourBrewingView({
    super.key,
    required this.instruction,
    required this.nextLabel,
    required this.nextInstruction,
    required this.countdownBuilder,
    required this.level,
    required this.wavePhase,
    required this.waveAmplitude,
    required this.fillColor,
    required this.isPaused,
    required this.pausedLabel,
    required this.opacity,
    this.leading,
    this.trailing,
    this.bottomClearance = 0,
    this.dropProgress,
    this.rippleProgress,
    this.headroom = 0,
    this.surface,
  });

  /// Empty space above a full cup, px — where the surface stops at level 1.
  /// The screen passes a thin band under the app bar: with no cup drawn, the
  /// whole body reads as the vessel, so a full brew should fill it (operator
  /// call, 2026-09-19 — a mid-screen "brim" read as unfinished). The band
  /// keeps wave crests off the app bar and gives the last drop its drip.
  final double headroom;

  /// The ending's last drop, falling: 0..1, or null when none is falling.
  final double? dropProgress;

  /// The ending's ripple from where the drop landed: 0..1, or null.
  final double? rippleProgress;

  /// The current step's resolved description, already localized.
  final String instruction;

  /// Already-localized label above the next-step preview, e.g. "Next:".
  final String nextLabel;

  /// The next step's description, already localized, or null for the last
  /// step. The slot itself is always present in the tree.
  final String? nextInstruction;

  /// Builds the countdown content in the given colour. Called once per copy
  /// (dry and submerged), so it must be cheap and must not carry `Semantics`
  /// of its own — this view applies `stepTimeCounter` to the dry copy.
  final Widget Function(Color color) countdownBuilder;

  /// Liquid height, 0 (empty) .. 1 (full): progress through the whole brew.
  final double level;

  /// Wave surface phase, radians.
  final double wavePhase;

  /// Wave surface amplitude, px. Pass 0 for reduced motion (flat surface).
  final double waveAmplitude;

  /// Body colour of the liquid — `AppBrewColors.brewFill(scheme)` from the
  /// caller, so both brewing presentations share one colour family.
  final Color fillColor;

  /// Whether the brew is paused. Shows [pausedLabel] under the countdown; the
  /// label's space is reserved either way.
  final bool isPaused;

  /// Already-localized "paused" state label.
  final String pausedLabel;

  /// Whole-view opacity, 0..1, used by the end sequence. Always applied via
  /// an always-present `Opacity`, never by conditionally wrapping.
  final double opacity;

  /// Optional slot for the manual step-back arrow, built in the colour the
  /// copy needs. Always present in the tree; empty when null. It is a builder
  /// for the same reason [countdownBuilder] is: it sits beside the countdown,
  /// where the liquid reaches it, so a fixed colour would leave it
  /// near-black on the coffee once submerged.
  final Widget Function(Color color)? leading;

  /// Optional slot for the manual step-forward arrow. Same contract as
  /// [leading].
  final Widget Function(Color color)? trailing;

  /// Vertical room left free at the bottom for the screen's floating action
  /// button.
  final double bottomClearance;

  /// The live liquid-frame source, when the caller drives the surface with a
  /// [PourSurfaceController] instead of rebuilding this view per wave tick.
  ///
  /// When non-null, the painter's `repaint` and the clipper's `reclip` are
  /// wired to it and both read its current [PourSurfaceFrame] at paint time,
  /// so an animation-only tick repaints the liquid and the submerged text
  /// layer without rebuilding any content. The level/wavePhase/waveAmplitude/
  /// dropProgress/rippleProgress constructor fields above remain the geometry
  /// of record for rebuild-driven callers (they are also kept up to date by
  /// the screen, so tests reading them off the widget see the live values).
  /// When null, this view behaves exactly as before: those fields drive the
  /// painter and the clipper, and shouldRepaint/shouldReclip compare them.
  final PourSurfaceController? surface;

  /// How the height above the bottom clearance is split between the
  /// countdown, instruction and next-step regions. Fixed proportions, so a
  /// block that changes size cannot move its neighbours.
  ///
  /// The countdown/instruction boundary lands at 5/13, about 38% of the
  /// content height — where the production screen puts its timer ring. The
  /// instruction region is sized for its worst case, three lines of 32px at
  /// a 1.5 accessibility text scale on a 320x690 screen; the next-step region
  /// for its 16/20 two-line preview.
  static const int _countdownRegionFlex = 5;
  static const int _instructionRegionFlex = 5;
  static const int _nextRegionFlex = 3;

  /// Secondary text colour for the dry copy (the next-step preview).
  ///
  /// The production screen greys its preview with `onSurface` at 55% alpha.
  /// This is the same colour computed solid — onSurface blended 55% of the way
  /// from the surface — so it reads identically without being an alpha-faded
  /// text, and follows the theme into dark mode. `onSurfaceVariant` was tried
  /// first and is near-black in this app's light scheme, which left the
  /// preview almost as loud as the instruction it is meant to sit under.
  static Color _drySecondary(ColorScheme scheme) =>
      Color.lerp(scheme.surface, scheme.onSurface, _drySecondaryWeight)!;
  static const double _drySecondaryWeight = 0.55;

  /// Secondary text colour for the submerged copy. A warm off-white rather
  /// than a faded white: alpha-faded text is an operator-rejected pattern
  /// (design refresh 2026-07), so the hierarchy between primary and
  /// secondary text is carried by a second solid colour.
  static const Color _submergedSecondary = Color(0xFFEADFD5);

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Opacity(
      // Always present: the end sequence fades through this; making it
      // conditional would swap the widget type at the root position.
      opacity: opacity.clamp(0.0, 1.0),
      child: Stack(
        children: [
          Positioned.fill(
            // RepaintBoundary: the liquid repaints on every wave tick; the
            // boundary keeps that churn inside its own layer so the two text
            // layers never repaint for it.
            child: RepaintBoundary(
              child: CustomPaint(
                painter: PourLiquidPainter(
                  level: level,
                  wavePhase: wavePhase,
                  waveAmplitude: waveAmplitude,
                  fillColor: fillColor,
                  dropProgress: dropProgress,
                  rippleProgress: rippleProgress,
                  headroom: headroom,
                  surface: surface,
                ),
              ),
            ),
          ),
          // Dry copy — reads against the surface, and owns every Semantics
          // identifier in this view. RepaintBoundary: it only changes when
          // content data changes (a second, a pause, a step), so wave ticks
          // and clip updates must not drag it along.
          Positioned.fill(
            child: RepaintBoundary(
              child: _content(
                primary: colorScheme.onSurface,
                secondary: _drySecondary(colorScheme),
                withSemantics: true,
              ),
            ),
          ),
          // Cache the submerged content INSIDE the moving clip: only its
          // clip changes on wave ticks, so glyphs need not be repainted.
          Positioned.fill(
            child: ClipPath(
              clipper: _PourLiquidClipper(
                level: level,
                wavePhase: wavePhase,
                waveAmplitude: waveAmplitude,
                rippleProgress: rippleProgress,
                headroom: headroom,
                surface: surface,
              ),
              child: RepaintBoundary(
                child: _content(
                  primary: Colors.white,
                  secondary: _submergedSecondary,
                  withSemantics: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// One copy of the content. [withSemantics] is fixed per copy, never
  /// state-dependent, so it cannot swap a widget type at a tree position.
  Widget _content({
    required Color primary,
    required Color secondary,
    required bool withSemantics,
  }) {
    Widget wrap(String identifier, Widget child) =>
        withSemantics ? Semantics(identifier: identifier, child: child) : child;

    return SafeArea(
      child: wrap(
        'brewingStepsContent',
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.lg,
            left: AppSpacing.base,
            right: AppSpacing.base,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Countdown — bottom-anchored, so it sits on the boundary
              // with the instruction and never moves.
              Expanded(
                flex: _countdownRegionFlex,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        leading?.call(primary) ?? const SizedBox.shrink(),
                        Expanded(
                          // Kept name even though Pour has no ring: the tests
                          // match this identifier, not the widget type.
                          child: wrap(
                            'circularProgressIndicator',
                            wrap('stepTimeCounter', countdownBuilder(primary)),
                          ),
                        ),
                        trailing?.call(primary) ?? const SizedBox.shrink(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Paused label: its space is reserved even while hidden,
                    // because the countdown is bottom-anchored above it —
                    // collapsing it would push the numbers up on every pause.
                    wrap(
                      'brewPausedIndicator',
                      Visibility(
                        visible: isPaused,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: Text(
                          pausedLabel,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.fieldLabel.copyWith(
                            color: primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              // 2. Instruction — top-anchored under the countdown, so a
              // longer one grows downward, away from the numbers. Flexible,
              // so at a large text scale it ellipsises instead of
              // overflowing its region.
              Expanded(
                flex: _instructionRegionFlex,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Flexible(
                      child: wrap(
                        'brewingStepDescription',
                        Text(
                          instruction,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.display.copyWith(color: primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 3. Next step — small, secondary, bottom-left, as on the
              // production screen. Bottom-anchored, so it grows upward.
              Expanded(
                flex: _nextRegionFlex,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Always present; an empty box on the last step. Ghosted
                    // with a second solid colour, never an alpha fade.
                    Flexible(
                      child: nextInstruction == null
                          ? const SizedBox.shrink()
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 16 / 20, matching the production preview's
                                // 17 / 20 as closely as the type ramp allows.
                                Text(
                                  nextLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.body.copyWith(
                                    color: secondary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Flexible(
                                  child: Text(
                                    nextInstruction!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.title.copyWith(
                                      fontWeight: FontWeight.w400,
                                      height: 1.3,
                                      color: secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: bottomClearance),
            ],
          ),
        ),
      ),
    );
  }
}

/// Clips the submerged copy of the content to the liquid, using the very same
/// wave path [PourLiquidPainter] fills with — so the text's colour boundary
/// and the coffee's surface are the same curve, not two approximations of it.
///
/// With a [PourSurfaceController] the clip *is* the painter's primary path:
/// both come from the controller's single-entry cache for the same frame
/// snapshot and size, so they are literally one [Path] object. The
/// controller's `reclip` listenable refreshes the clip on every wave tick
/// without any widget rebuild.
///
/// The painter draws a second, translucent layer at a phase offset; the clip
/// follows the primary layer, which is the edge the eye reads as the surface.
class _PourLiquidClipper extends CustomClipper<Path> {
  // Not const: the lazily-built static frame below needs a normal
  // generative constructor. The view builds a fresh clipper per rebuild
  // anyway, so const was never exercised.
  _PourLiquidClipper({
    required this.level,
    required this.wavePhase,
    required this.waveAmplitude,
    required this.rippleProgress,
    required this.headroom,
    this.surface,
  }) : super(reclip: surface);

  final double level;
  final double headroom;
  final double wavePhase;
  final double waveAmplitude;
  final double? rippleProgress;

  /// The live frame source; also wired as this clipper's `reclip` listenable.
  /// Null means the constructor fields above drive the clip (rebuild mode).
  final PourSurfaceController? surface;

  /// The static frame built from the constructor fields — what gets used when
  /// there is no [surface].
  late final PourSurfaceFrame _staticFrame = PourSurfaceFrame(
    level: level,
    wavePhase: wavePhase,
    waveAmplitude: waveAmplitude,
    rippleProgress: rippleProgress,
    headroom: headroom,
  );

  @override
  Path getClip(Size size) {
    final PourSurfaceFrame frame = surface?.frame ?? _staticFrame;
    // An empty path clips everything away: with an empty cup the submerged
    // copy contributes nothing and the dry copy is what shows.
    if (frame.level <= 0) return Path();
    // Same cache the painter fills with — identical frame and size return
    // the identical Path object.
    return surface?.primaryPathFor(frame, size) ??
        buildBrewWavePath(
          size: size,
          fillLevel: pourCanvasLevel(frame.level, frame.headroom, size),
          waveAmplitude: frame.waveAmplitude,
          phase: frame.wavePhase,
          // The same ripple the painter applies, so the text's colour boundary
          // moves with the surface rather than cutting straight across it.
          surfaceOffset: frame.rippleProgress == null
              ? null
              : PourRippleField.of(size, frame.rippleProgress!).offsetAt,
        );
  }

  @override
  bool shouldReclip(covariant _PourLiquidClipper oldClipper) {
    final PourSurfaceController? oldSurface = oldClipper.surface;
    final PourSurfaceController? newSurface = surface;
    if ((oldSurface == null) != (newSurface == null)) return true;
    if (newSurface != null) {
      // Live mode: frame changes arrive through the reclip listenable.
      return oldSurface != newSurface;
    }
    // Static mode: the constructor fields are the geometry.
    return oldClipper._staticFrame != _staticFrame;
  }
}
