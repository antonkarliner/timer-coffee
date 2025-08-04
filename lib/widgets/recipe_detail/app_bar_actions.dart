import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

/// Stateless actions row for the Recipe Detail AppBar.
/// All business logic is delegated to callbacks; this file contains only UI.
class RecipeDetailAppBarActions extends StatelessWidget {
  final bool isUserRecipe;
  final bool isSharing;
  final String idForActions;
  final VoidCallback? onEdit;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final Widget favoriteButton;

  const RecipeDetailAppBarActions({
    Key? key,
    required this.isUserRecipe,
    required this.isSharing,
    required this.idForActions,
    this.onEdit,
    this.onCopy,
    this.onShare,
    required this.favoriteButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];

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
