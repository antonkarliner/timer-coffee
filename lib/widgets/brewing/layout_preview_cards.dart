import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import '../../visual/color_schemes.dart';
import 'brew_timer_ring.dart';
import 'next_step_preview.dart';
import 'pour_brewing_view.dart';

/// What the user picked in the one-time layout picker (plan 067 Phase 3).
enum LayoutChoice { classic, pour }

/// The two brewing-screen layouts side by side, each card a frozen live
/// preview of that screen showing [instruction]. Shared by the Play-tap
/// picker, the Brewing settings page and the Preparation gear sheet, so all
/// three show the same choice. A tap reports the card through [onSelected];
/// the [current] card carries the selection ring and check badge.
class LayoutPreviewCards extends StatelessWidget {
  const LayoutPreviewCards({
    super.key,
    required this.current,
    required this.onSelected,
    required this.instruction,
    required this.nextInstruction,
    required this.stepSeconds,
  });

  final LayoutChoice current;
  final ValueChanged<LayoutChoice> onSelected;
  final String instruction;
  final String? nextInstruction;
  final int stepSeconds;

  /// Logical canvas both live previews are laid out on before being scaled
  /// into their card. A small phone's width, tall enough for the classic
  /// card's ring + instruction + next-step stack at its worst realistic
  /// (two-line) case, so the FittedBox below never clips or overflows.
  static const double _previewCanvasWidth = 390;
  static const double _previewCanvasHeight = 400;

  /// Each card's preview height: roughly the card's inner width on a 375–430
  /// wide phone, so the square-ish canvas fills the card and the preview
  /// text stays legible (88 was checked on the simulator and was not). The
  /// whole sheet stays around 65% of a 375×667 screen; if a large text scale
  /// pushes it past the screen, the sheet scrolls instead of overflowing.
  static const double _previewSlotHeight = 168;

  /// The classic ring's diameter on the preview canvas — the emphasized size
  /// the production screen uses on a 390-wide screen
  /// (brewTimerRingDiameterForWidth at 390).
  static const double _previewRingDiameter = 132;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _choiceCard(
              context,
              choice: LayoutChoice.classic,
              label: loc.layoutPickerClassic,
              identifier: 'layoutChoiceClassicCard',
              preview: _classicPreview(context, loc),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _choiceCard(
              context,
              choice: LayoutChoice.pour,
              label: loc.layoutPickerImmersive,
              identifier: 'layoutChoiceImmersiveCard',
              preview: _immersivePreview(context, loc),
            ),
          ),
        ],
      ),
    );
  }

  /// One tappable card: the live preview and its label. One button in
  /// semantics — the preview is wrapped in ExcludeSemantics so brewing-test
  /// identifiers (`brewingStepDescription` & co.) never leave it.
  Widget _choiceCard(
    BuildContext context, {
    required LayoutChoice choice,
    required String label,
    required String identifier,
    required Widget preview,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isCurrent = choice == current;

    return Semantics(
      identifier: identifier,
      button: true,
      selected: isCurrent,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => onSelected(choice),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isCurrent
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: isCurrent ? AppStroke.focus : AppStroke.border,
            ),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: _previewSlotHeight,
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: IgnorePointer(
                        child: ExcludeSemantics(
                          child: MediaQuery.removePadding(
                            context: context,
                            removeTop: true,
                            removeBottom: true,
                            removeLeft: true,
                            removeRight: true,
                            child: SizedBox(
                              width: _previewCanvasWidth,
                              height: _previewCanvasHeight,
                              child: preview,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Excluded: the card's Semantics already carries this label,
                  // so it would otherwise be read twice.
                  ExcludeSemantics(
                    child: Text(label, style: AppTextStyles.fieldLabel),
                  ),
                ],
              ),
              PositionedDirectional(
                top: AppSpacing.xs,
                end: AppSpacing.xs,
                child: isCurrent
                    ? const SelectionCheckBadge()
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The immersive body itself, frozen mid-brew: static liquid frame at
  /// ~55% full, a small wave, the real countdown/instruction/next-step
  /// content. `surface` stays null, so the painter and clipper fall back to
  /// the static frame built from the constructor values.
  Widget _immersivePreview(BuildContext context, AppLocalizations loc) {
    return PourBrewingView(
      instruction: instruction,
      nextLabel: '${loc.next}:',
      nextInstruction: nextInstruction,
      countdownBuilder: (color) => FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$stepSeconds',
              style: AppTextStyles.display.copyWith(color: color),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              loc.secondsAbbreviation,
              style: AppTextStyles.headline.copyWith(color: color),
            ),
          ],
        ),
      ),
      level: 0.55,
      wavePhase: 1.0,
      waveAmplitude: 4,
      fillColor: AppBrewColors.brewFill(Theme.of(context).colorScheme),
      isPaused: false,
      pausedLabel: loc.liveActivityPaused,
      opacity: 1,
    );
  }

  /// The classic body's stack — ring with the step time inside, the current
  /// instruction under it, then the next-step preview — mirroring the
  /// production layout without extracting anything from
  /// brewing_process_screen.dart.
  Widget _classicPreview(BuildContext context, AppLocalizations loc) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color trackColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF5A5A5A)
        : const Color(0xFFE4E4E4);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrewTimerRing(
            diameter: _previewRingDiameter,
            progress: 0.35,
            fillLevel: 0,
            wavePhase: 0,
            waveAmplitude: 0,
            ringColor: colorScheme.secondary,
            trackColor: trackColor,
            fillColor: AppBrewColors.brewFill(colorScheme),
            strokeWidth: 8,
            countdownOpacity: 1,
            countdown: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$stepSeconds',
                  style: TextStyle(
                    fontSize: _previewRingDiameter / 6,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  ' ${loc.secondsAbbreviation}',
                  style: TextStyle(
                    fontSize: _previewRingDiameter / 7.5,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            instruction,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headline.copyWith(height: 1.3),
          ),
          const SizedBox(height: AppSpacing.base),
          if (nextInstruction != null)
            NextStepPreview(
              label: '${loc.next}:',
              description: nextInstruction!,
            ),
        ],
      ),
    );
  }
}

/// The check that marks the selected option among visual choices (layout
/// cards, app icons). Decorative to screen readers: the option's own
/// semantics carry `selected`.
class SelectionCheckBadge extends StatelessWidget {
  const SelectionCheckBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ExcludeSemantics(
      child: Container(
        width: AppIconSize.medium,
        height: AppIconSize.medium,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check,
          size: AppIconSize.small,
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }
}
