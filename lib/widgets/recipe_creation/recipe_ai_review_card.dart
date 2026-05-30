import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/app_switch_list_tile.dart';
import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';

class RecipeAiReviewCard extends StatelessWidget {
  final bool aiReviewEnabled;
  final bool aiReviewAvailable;
  final ValueChanged<bool> onAiReviewChanged;
  final VoidCallback onInfoPressed;

  const RecipeAiReviewCard({
    super.key,
    required this.aiReviewEnabled,
    required this.aiReviewAvailable,
    required this.onAiReviewChanged,
    required this.onInfoPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Expanded(
            child: AppSwitchListTile(
              title: l10n.recipeCreationAiReviewToggle,
              subtitle: aiReviewAvailable
                  ? l10n.recipeCreationAiReviewConsentInline
                  : l10n.recipeCreationAiReviewUnavailable,
              value: aiReviewAvailable && aiReviewEnabled,
              onChanged: onAiReviewChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
            child: IconButton(
              tooltip: l10n.recipeCreationAiReviewConsentTitle,
              icon: const Icon(Icons.info_outline),
              onPressed: onInfoPressed,
            ),
          ),
        ],
      ),
    );
  }
}
