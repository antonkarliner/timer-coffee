import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';

/// Dialog for confirming whether to unpublish a recipe by making it private.
class UnpublishRecipeDialog extends StatelessWidget {
  const UnpublishRecipeDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.unpublishRecipeDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.unpublishRecipeDialogMessage),
          const SizedBox(height: 8),
          Text(l10n.unpublishRecipeDialogBullet1),
          Text(l10n.unpublishRecipeDialogBullet2),
          Text(l10n.unpublishRecipeDialogBullet3),
        ],
      ),
      actions: [
        AppTextButton(
          label: l10n.unpublishRecipeDialogKeepPublic,
          onPressed: () => Navigator.of(context).pop(false),
          isFullWidth: false,
          height: AppButton.heightSmall,
          padding: AppButton.paddingSmall,
        ),
        AppElevatedButton(
          label: l10n.unpublishRecipeDialogMakePrivate,
          onPressed: () => Navigator.of(context).pop(true),
          isFullWidth: false,
          height: AppButton.heightSmall,
          padding: AppButton.paddingSmall,
        ),
      ],
    );
  }

  /// Shows the unpublish confirmation dialog and returns whether to proceed.
  ///
  /// Returns `true` if the user confirms to make the recipe private,
  /// `false` if they choose to keep it public, or `null` if dismissed.
  static Future<bool?> show(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => const UnpublishRecipeDialog(),
    );
  }
}
