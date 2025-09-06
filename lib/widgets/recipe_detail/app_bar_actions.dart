import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/recipe_detail/unpublish_recipe_dialog.dart';

/// Stateless actions row for the Recipe Detail AppBar.
/// All business logic is delegated to callbacks; this file contains only UI.
class RecipeDetailAppBarActions extends StatelessWidget {
  final bool isUserRecipe;
  final bool isSharing;
  final String idForActions;
  final bool isPublic;
  final VoidCallback? onEdit;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onUnpublish;
  final Widget favoriteButton;

  const RecipeDetailAppBarActions({
    Key? key,
    required this.isUserRecipe,
    required this.isSharing,
    required this.idForActions,
    required this.isPublic,
    this.onEdit,
    this.onCopy,
    this.onShare,
    this.onUnpublish,
    required this.favoriteButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];

    // Add privacy icon for user recipes (usr-)
    if (isUserRecipe && idForActions.startsWith('usr-')) {
      print(
          'DEBUG: RecipeDetailAppBarActions - id: $idForActions, isPublic: $isPublic');
      actions.add(
        IconButton(
          icon: Icon(isPublic ? Icons.visibility : Icons.visibility_off),
          tooltip: isPublic
              ? AppLocalizations.of(context)!.recipePublicTooltip
              : AppLocalizations.of(context)!.recipePrivateTooltip,
          onPressed: isPublic
              ? () async {
                  final result = await UnpublishRecipeDialog.show(context);
                  if (result == true) {
                    onUnpublish?.call();
                  }
                }
              : null,
        ),
      );
    }

    if (isUserRecipe) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: AppLocalizations.of(context)?.edit ?? 'Edit',
          onPressed: onEdit,
        ),
      );
    }

    // Only show copy for non-user recipes and exclude 106, 1002 (keeps current behavior parity)
    if (!isUserRecipe && idForActions != '106' && idForActions != '1002') {
      actions.add(
        IconButton(
          icon: const Icon(Icons.copy),
          tooltip: MaterialLocalizations.of(context).copyButtonLabel,
          onPressed: onCopy,
        ),
      );
    }

    actions.add(
      IconButton(
        icon: Icon(defaultTargetPlatform == TargetPlatform.iOS
            ? CupertinoIcons.share
            : Icons.share),
        onPressed: isSharing ? null : onShare,
      ),
    );

    actions.add(favoriteButton);

    return Row(mainAxisSize: MainAxisSize.min, children: actions);
  }
}
