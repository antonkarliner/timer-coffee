import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../../theme/design_tokens.dart';
import '../fields/labeled_field.dart';

class RecipeBasicInfoCard extends StatelessWidget {
  final TextEditingController recipeNameController;
  final TextEditingController shortDescriptionController;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onShortDescriptionChanged;

  const RecipeBasicInfoCard({
    super.key,
    required this.recipeNameController,
    required this.shortDescriptionController,
    required this.onNameChanged,
    required this.onShortDescriptionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LabeledField(
              label: l10n.recipeCreationScreenRecipeNameLabel,
              controller: recipeNameController,
              textCapitalization: TextCapitalization.none,
              onChanged: onNameChanged,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.recipeCreationScreenRecipeNameValidator;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.fieldGap),
            LabeledField(
              label: l10n.recipeCreationScreenShortDescriptionLabel,
              controller: shortDescriptionController,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.none,
              isMultiline: true,
              maxLines: 3,
              onChanged: onShortDescriptionChanged,
            ),
          ],
        ),
      ),
    );
  }
}
