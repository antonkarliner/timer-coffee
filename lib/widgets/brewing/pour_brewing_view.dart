import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
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
/// Widget shape is intentionally **stable** in every state (see the remount
/// trap in CLAUDE.md — swapping the widget type at a tree position destroys
/// the subtree element and re-runs `initState` on whatever lives there): the
/// next-step, paused, leading and trailing slots are always present and
/// collapse to `SizedBox.shrink()` when empty, and [opacity] is applied with
/// an always-present `Opacity`. No widget type is ever swapped at a tree
/// position, so the caller-provided countdown is never remounted.
///
/// Colour placement follows the liquid line: everything below it (countdown
/// slot, elapsed/total, paused label) is `Colors.white` in both themes —
/// [AppBrewColors.brewFill] is dark enough for white to clear WCAG AA — and
/// everything above it uses the scheme's `onSurface`, with the ghosted next
/// step in `onSurfaceVariant`. The ghosting is a different colour, never an
/// alpha fade. The instruction block is top-anchored and line-capped, which
/// keeps it within the top ~35% of typical phone screens — the region the
/// liquid does not reach during normal brewing — without a hard height box
/// that would overflow at large text scalers.
class PourBrewingView extends StatelessWidget {
  const PourBrewingView({
    super.key,
    required this.stepLabel,
    required this.instruction,
    required this.nextInstruction,
    required this.countdown,
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

  /// Already-localized step counter, e.g. "Step 3/5". Rendered uppercase.
  final String stepLabel;

  /// The current step's resolved description, already localized.
  final String instruction;

  /// The next step's description, already localized, or null for the last
  /// step. The slot itself is always present in the tree.
  final String? nextInstruction;

  /// The countdown content (large numerals), built by the caller. Lives in
  /// an always-present slot inside the liquid.
  final Widget countdown;

  /// Already-formatted elapsed time, e.g. "02:14".
  final String elapsedText;

  /// Already-formatted total step time, e.g. "04:00".
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

  /// Optional slot for the manual step-back arrow. Always present in the
  /// tree; empty when null.
  final Widget? leading;

  /// Optional slot for the manual step-forward arrow. Always present in the
  /// tree; empty when null.
  final Widget? trailing;

  /// Vertical room left free at the bottom for the screen's floating action
  /// button.
  final double bottomClearance;

  /// Letter spacing of the uppercase step label. No spacing token exists for
  /// tracking; matches the value already used for chip labels in the app.
  static const double _stepLabelLetterSpacing = 1.0;

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
          Positioned.fill(
            child: SafeArea(
              child: Semantics(
                identifier: 'brewingStepsContent',
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.lg,
                    left: AppSpacing.base,
                    right: AppSpacing.base,
                  ),
                  // The children list below has a fixed length in every
                  // state: conditional pieces are slots that collapse to
                  // SizedBox.shrink(), never removed children.
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        stepLabel.toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: _stepLabelLetterSpacing,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Semantics(
                        identifier: 'brewingStepDescription',
                        child: Text(
                          instruction,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.display.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Ghosted next-step slot: always present, empty box
                      // when there is no next step. Ghosting is
                      // onSurfaceVariant — a different colour, never an
                      // alpha fade.
                      nextInstruction == null
                          ? const SizedBox.shrink()
                          : Text(
                              nextInstruction!,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                height: 1.3,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                      const Spacer(),
                      Row(
                        children: [
                          leading ?? const SizedBox.shrink(),
                          Expanded(
                            // Kept name even though Pour has no ring: the
                            // tests match this identifier, not the widget.
                            child: Semantics(
                              identifier: 'circularProgressIndicator',
                              child: countdown,
                            ),
                          ),
                          trailing ?? const SizedBox.shrink(),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '$elapsedText / $totalText',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      // Paused slot: always present, empty box when not
                      // paused — same rule as every other slot above.
                      Semantics(
                        identifier: 'brewPausedIndicator',
                        child: isPaused
                            ? Text(
                                pausedLabel,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      SizedBox(height: bottomClearance),
                    ],
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
