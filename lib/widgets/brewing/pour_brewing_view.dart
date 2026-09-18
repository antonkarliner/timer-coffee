import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import 'brew_fill_ring_painter.dart';
import 'pour_liquid_painter.dart';

/// The "Pour" brewing presentation (plan 066 phase 1): the current
/// instruction at display size at the top, the next step ghosted beneath it,
/// and the lower screen filled with liquid — the same
/// [AppBrewColors.brewFill] coffee the end-of-brew ring fill uses — that
/// rises with brew progress, with the countdown living inside the liquid as
/// large numerals.
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
/// ## Stable shape
///
/// Widget shape is intentionally **stable** in every state (see the remount
/// trap in CLAUDE.md — swapping the widget type at a tree position destroys
/// the subtree element and re-runs `initState` on whatever lives there): the
/// next-step, paused, leading and trailing slots are always present and
/// collapse to `SizedBox.shrink()` when empty, and [opacity] is applied with
/// an always-present `Opacity`. `withSemantics` is fixed per copy, so it
/// never swaps a type at a position either.
///
/// The height is split into two fixed-proportion regions — the instruction
/// above, the countdown group below — so that a step whose instruction wraps
/// to a different number of lines cannot shift the numbers as the step
/// changes. Each region centres its own content and is line-capped, so the
/// text can grow and shrink inside it without moving anything else.
class PourBrewingView extends StatelessWidget {
  const PourBrewingView({
    super.key,
    required this.instruction,
    required this.nextInstruction,
    required this.countdownBuilder,
    required this.elapsedText,
    required this.totalText,
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
  });

  /// The current step's resolved description, already localized.
  final String instruction;

  /// The next step's description, already localized, or null for the last
  /// step. The slot itself is always present in the tree.
  final String? nextInstruction;

  /// Builds the countdown content in the given colour. Called once per copy
  /// (dry and submerged), so it must be cheap and must not carry `Semantics`
  /// of its own — this view applies `stepTimeCounter` to the dry copy.
  final Widget Function(Color color) countdownBuilder;

  /// Already-formatted elapsed brew time, e.g. "02:14".
  final String elapsedText;

  /// Already-formatted total brew time, e.g. "04:00".
  final String totalText;

  /// Liquid height, 0 (empty) .. 1 (full).
  final double level;

  /// Wave surface phase, radians.
  final double wavePhase;

  /// Wave surface amplitude, px. Pass 0 for reduced motion (flat surface).
  final double waveAmplitude;

  /// Body colour of the liquid — `AppBrewColors.brewFill(scheme)` from the
  /// caller, so both brewing presentations share one colour family.
  final Color fillColor;

  /// Whether the brew is paused. Toggles the paused slot's content between
  /// [pausedLabel] and an empty box; the slot is always present.
  final bool isPaused;

  /// Already-localized "paused" state label.
  final String pausedLabel;

  /// Whole-view opacity, 0..1, used by the end sequence. Always applied via
  /// an always-present `Opacity`, never by conditionally wrapping.
  final double opacity;

  /// Optional slot for the manual step-back arrow, built in the colour the
  /// copy needs. Always present in the tree; empty when null. It is a builder
  /// for the same reason [countdownBuilder] is: it sits beside the countdown,
  /// low enough that the liquid reaches it, so a fixed colour would leave it
  /// near-black on the coffee once submerged.
  final Widget Function(Color color)? leading;

  /// Optional slot for the manual step-forward arrow. Same contract as
  /// [leading].
  final Widget Function(Color color)? trailing;

  /// Vertical room left free at the bottom for the screen's floating action
  /// button.
  final double bottomClearance;

  /// The instruction is the one deliberate exception to the project type
  /// ramp, whose top is 32 (`AppTextStyles.display`). This screen has a single
  /// job — tell you what to do right now — and at 32 the instruction did not
  /// carry the screen against the liquid. Capped at three lines, so the
  /// longest real step text still fits.
  static const double _instructionFontSize = 40.0;

  /// How the height above the bottom clearance is split between the
  /// instruction region and the countdown region. Fixed proportions, so a
  /// step whose instruction wraps to a different number of lines cannot move
  /// the countdown.
  ///
  /// The instruction takes the larger share because it is what has to fit:
  /// three lines at 40 logical px, times a 1.5 accessibility text scale, plus
  /// two lines of next-step, needs ~279px on a 320x690 screen — a 5:6 split
  /// left only 259 and overflowed.
  ///
  /// The countdown region aligns its content to the *top* rather than
  /// centring it, which is what actually pins the numbers: centring inside
  /// the lower region would put them at ~77% of the height, back to the
  /// bottom-heavy look the spacers had. Top-aligned, the countdown sits at
  /// the boundary — 6/11, about 55% — whatever the instruction above it does.
  static const int _instructionRegionFlex = 6;
  static const int _countdownRegionFlex = 5;

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
            child: CustomPaint(
              painter: PourLiquidPainter(
                level: level,
                wavePhase: wavePhase,
                waveAmplitude: waveAmplitude,
                fillColor: fillColor,
              ),
            ),
          ),
          // Dry copy — reads against the surface, and owns every Semantics
          // identifier in this view.
          Positioned.fill(
            child: _content(
              primary: colorScheme.onSurface,
              secondary: colorScheme.onSurfaceVariant,
              withSemantics: true,
            ),
          ),
          // Submerged copy — identical layout in white, clipped to the same
          // wave the painter fills with, so the colour boundary *is* the
          // liquid surface.
          Positioned.fill(
            child: ClipPath(
              clipper: _PourLiquidClipper(
                level: level,
                wavePhase: wavePhase,
                waveAmplitude: waveAmplitude,
              ),
              child: _content(
                primary: Colors.white,
                secondary: _submergedSecondary,
                withSemantics: false,
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
          // Two fixed-proportion regions rather than a spacer-balanced list.
          // With spacers the countdown's position depended on how tall the
          // instruction happened to be, so a step whose text wrapped to a
          // different number of lines shifted the numbers as the step
          // changed. Splitting the height by flex pins each region: the
          // instruction grows and shrinks inside its own area and nothing
          // below it moves.
          //
          // Both regions have a fixed child count in every state; the
          // conditional pieces are slots that collapse to SizedBox.shrink(),
          // never removed children.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: _instructionRegionFlex,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Both blocks are Flexible so the region's fixed height is
                    // authoritative: at a large accessibility text scale the
                    // text ellipsises a line earlier instead of overflowing
                    // the region. Chasing the flex ratio instead would only
                    // move the scale at which it breaks.
                    Flexible(
                      child: wrap(
                        'brewingStepDescription',
                        Text(
                          instruction,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.display.copyWith(
                            fontSize: _instructionFontSize,
                            fontWeight: FontWeight.w800,
                            color: primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Ghosted next-step slot: always present, empty box when
                    // there is no next step. Ghosting is a second solid
                    // colour, never an alpha fade.
                    Flexible(
                      child: nextInstruction == null
                          ? const SizedBox.shrink()
                          : Text(
                              nextInstruction!,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                height: 1.3,
                                color: secondary,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: _countdownRegionFlex,
                child: Column(
                  // Top, not centre — see _countdownRegionFlex.
                  mainAxisAlignment: MainAxisAlignment.start,
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
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '$elapsedText / $totalText',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Paused slot: always present, empty box when not paused
                    // — same rule as every other slot here.
                    wrap(
                      'brewPausedIndicator',
                      isPaused
                          ? Text(
                              pausedLabel,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: primary,
                              ),
                            )
                          : const SizedBox.shrink(),
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
/// The painter draws a second, translucent layer at a phase offset; the clip
/// follows the primary layer, which is the edge the eye reads as the surface.
class _PourLiquidClipper extends CustomClipper<Path> {
  const _PourLiquidClipper({
    required this.level,
    required this.wavePhase,
    required this.waveAmplitude,
  });

  final double level;
  final double wavePhase;
  final double waveAmplitude;

  @override
  Path getClip(Size size) {
    // An empty path clips everything away: with an empty cup the submerged
    // copy contributes nothing and the dry copy is what shows.
    if (level <= 0) return Path();
    return buildBrewWavePath(
      size: size,
      fillLevel: level,
      waveAmplitude: waveAmplitude,
      phase: wavePhase,
    );
  }

  @override
  bool shouldReclip(covariant _PourLiquidClipper oldClipper) {
    return oldClipper.level != level ||
        oldClipper.wavePhase != wavePhase ||
        oldClipper.waveAmplitude != waveAmplitude;
  }
}
