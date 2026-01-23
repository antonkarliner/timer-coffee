import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';

/// Dialog that asks user if they want to import a recipe
class RecipeImportDialog extends StatelessWidget {
  final String recipeName;

  const RecipeImportDialog({
    Key? key,
    required this.recipeName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.recipeImportTitle),
      content: Text(l10n.recipeImportBody(recipeName)),
      actions: <Widget>[
        AppTextButton(
          label: l10n.dialogCancel,
          onPressed: () => Navigator.of(context).pop(false),
          isFullWidth: false,
          height: AppButton.heightSmall,
          padding: AppButton.paddingSmall,
        ),
        AppTextButton(
          label: l10n.dialogImport,
          onPressed: () => Navigator.of(context).pop(true),
          isFullWidth: false,
          height: AppButton.heightSmall,
          padding: AppButton.paddingSmall,
        ),
      ],
    );
  }
}

/// Dialog that asks user if they want to update a recipe
class RecipeUpdateDialog extends StatelessWidget {
  final String recipeName;

  const RecipeUpdateDialog({
    Key? key,
    required this.recipeName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.recipeUpdateAvailableTitle),
      content: Text(l10n.recipeUpdateAvailableBody(recipeName)),
      actions: <Widget>[
        AppTextButton(
          label: l10n.dialogCancel,
          onPressed: () => Navigator.of(context).pop(false),
          isFullWidth: false,
          height: AppButton.heightSmall,
          padding: AppButton.paddingSmall,
        ),
        AppTextButton(
          label: l10n.dialogUpdate,
          onPressed: () => Navigator.of(context).pop(true),
          isFullWidth: false,
          height: AppButton.heightSmall,
          padding: AppButton.paddingSmall,
        ),
      ],
    );
  }
}

/// Helper class to show import/update dialogs
class ImportUpdateDialogs {
  /// Shows the import dialog and returns user's choice
  static Future<bool?> showImportDialog(
    BuildContext context,
    String recipeName,
  ) async {
    if (!context.mounted) return false;

    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => RecipeImportDialog(
        recipeName: recipeName,
      ),
    );
  }

  /// Shows the update dialog and returns user's choice
  static Future<bool?> showUpdateDialog(
    BuildContext context,
    String recipeName,
  ) async {
    if (!context.mounted) return false;

    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => RecipeUpdateDialog(
        recipeName: recipeName,
      ),
    );
  }
}
