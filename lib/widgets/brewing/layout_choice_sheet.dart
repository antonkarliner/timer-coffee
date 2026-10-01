import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../services/layout_choice_prompt_service.dart';
import '../../theme/design_tokens.dart';
import 'layout_preview_cards.dart';

export 'layout_preview_cards.dart' show LayoutChoice;

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
            LayoutPreviewCards(
              current: current,
              onSelected: (choice) => Navigator.of(context).pop(choice),
              instruction: instruction,
              nextInstruction: nextInstruction,
              stepSeconds: stepSeconds,
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
}
