import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../services/layout_choice_prompt_service.dart';
import '../../theme/design_tokens.dart';
import '../../visual/color_schemes.dart';
import 'brew_timer_ring.dart';
import 'next_step_preview.dart';
import 'pour_brewing_view.dart';

/// What the user picked in the one-time layout picker (plan 067 Phase 3).
enum LayoutChoice { classic, pour }

/// Shows the one-time "How do you want to brew?" sheet and resolves with the
/// tapped layout, or null when the sheet was dismissed (swipe, scrim, back).
///
/// [instruction], [nextInstruction] and [stepSeconds] come from the recipe's
/// first timed step (and the one after it), already placeholder-resolved by
/// the caller, so both previews render the concrete, localized content this
/// user is about to brew with.
Future<LayoutChoice?> showLayoutChoiceSheet(
  BuildContext context, {
  required LayoutChoiceTrigger trigger,
  required LayoutChoice current,
  required String instruction,
  required String? nextInstruction,
  required int stepSeconds,
}) {
  return showModalBottomSheet<LayoutChoice>(
    context: context,
    showDragHandle: true,
    // Without this the sheet is capped at 9/16 of the screen, which forced
    // the previews down to an unreadable size. The content still scrolls if
    // a large text scale outgrows the screen.
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: _LayoutChoiceSheet(
          trigger: trigger,
          current: current,
          instruction: instruction,
          nextInstruction: nextInstruction,
          stepSeconds: stepSeconds,
        ),
      );
    },
  );
}

class _LayoutChoiceSheet extends StatelessWidget {
  const _LayoutChoiceSheet({
    required this.trigger,
    required this.current,
    required this.instruction,
    required this.nextInstruction,
    required this.stepSeconds,
  });

  final LayoutChoiceTrigger trigger;
  final LayoutChoice current;
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

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.base,
          AppSpacing.xs,
          AppSpacing.base,
          AppSpacing.base,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.layoutPickerTitle,
              style: AppTextStyles.headline,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _subtitle(loc),
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            IntrinsicHeight(
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
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              loc.layoutPickerFooter,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(AppLocalizations loc) => switch (trigger) {
    LayoutChoiceTrigger.existingUser => loc.layoutPickerSubtitleExisting,
    LayoutChoiceTrigger.secondBrew => loc.layoutPickerSubtitleSecondBrew,
    // The finish-card entry point (later phase) addresses a user who has
    // brewed before, so the second-brew copy reads correctly there too.
    LayoutChoiceTrigger.finishCard => loc.layoutPickerSubtitleSecondBrew,
  };

  /// One tappable card: the live preview, then its label, then the always
  /// present Current-badge slot. One button in semantics — the preview is
  /// wrapped in ExcludeSemantics so brewing-test identifiers
  /// (`brewingStepDescription` & co.) never leave it.
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
        onTap: () => Navigator.of(context).pop(choice),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isCurrent ? colorScheme.primary : colorScheme.outlineVariant,
              width: isCurrent ? AppStroke.focus : AppStroke.border,
            ),
          ),
          child: Column(
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
              ExcludeSemantics(child: Text(label, style: AppTextStyles.fieldLabel)),
              // Always present, so the two cards keep the same shape.
              const SizedBox(height: AppSpacing.xs),
              isCurrent
                  ? _currentBadge(context)
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _currentBadge(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.secondary,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        loc.layoutPickerCurrent,
        style: AppTextStyles.badge.copyWith(color: colorScheme.onSecondary),
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
            Text('$stepSeconds', style: AppTextStyles.display.copyWith(color: color)),
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
