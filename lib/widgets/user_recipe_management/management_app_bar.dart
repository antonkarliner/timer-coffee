import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../../controllers/user_recipe_management_controller.dart';

class ManagementAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final UserRecipeManagementController controller;
  final VoidCallback onToggleEdit;
  final VoidCallback? onCreate;

  const ManagementAppBar({
    super.key,
    required this.title,
    required this.controller,
    required this.onToggleEdit,
    this.onCreate,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppBar(
      leading: const BackButton(),
      title: Text(title),
      actions: [
        if (onCreate != null)
          IconButton(
            tooltip: l10n.createRecipe,
            icon: const Icon(Icons.add),
            onPressed: onCreate,
          ),
        ValueListenableBuilder<bool>(
          valueListenable: controller.editMode,
          builder: (context, isEdit, _) {
            return IconButton(
              tooltip: isEdit ? l10n.ok : l10n.edit,
              icon: Icon(isEdit ? Icons.check : Icons.edit_note),
              onPressed: onToggleEdit,
            );
          },
        ),
      ],
    );
  }
}
