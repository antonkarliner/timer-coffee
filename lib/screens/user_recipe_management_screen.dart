import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/user_recipe_management_controller.dart';
import '../providers/recipe_provider.dart';
import '../providers/user_recipe_provider.dart';
import '../models/recipe_model.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/favorite_button.dart';
import '../utils/icon_utils.dart';
import '../app_router.gr.dart';
import '../widgets/recipe_detail/unpublish_recipe_dialog.dart';
import '../widgets/user_recipe_management/management_app_bar.dart';
import '../widgets/user_recipe_management/created_list_section.dart';
import '../widgets/user_recipe_management/imported_list_section.dart';
import '../widgets/user_recipe_management/recipe_list_item.dart';

@RoutePage()
class UserRecipeManagementScreen extends StatefulWidget {
  const UserRecipeManagementScreen({super.key});

  @override
  State<UserRecipeManagementScreen> createState() =>
      _UserRecipeManagementScreenState();
}

class _UserRecipeManagementScreenState
    extends State<UserRecipeManagementScreen> {
  late final UserRecipeManagementController _controller;

  @override
  void initState() {
    super.initState();
    _controller = UserRecipeManagementController();

    // Ensure recipes are loaded similarly to RecipeListScreen
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await Provider.of<RecipeProvider>(context, listen: false)
            .ensureDataReady();
        // Optionally refresh to latest
        await Provider.of<RecipeProvider>(context, listen: false)
            .fetchAllRecipes();
      } catch (_) {
        // Swallow, UI shows empty states if needed
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _deleteRecipe(BuildContext context, RecipeModel recipe) async {
    try {
      await Provider.of<UserRecipeProvider>(context, listen: false)
          .deleteUserRecipe(recipe.id);
      await Provider.of<RecipeProvider>(context, listen: false)
          .fetchAllRecipes();
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.userRecipesSnackbarDeleted)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete recipe: $e')),
      );
    }
  }

  Future<void> _unpublishRecipe(
      BuildContext context, RecipeModel recipe) async {
    final confirmed = await UnpublishRecipeDialog.show(context);
    if (confirmed != true) return;

    final l10n = AppLocalizations.of(context)!;

    try {
      await Provider.of<UserRecipeProvider>(context, listen: false)
          .unpublishRecipe(recipe.id);
      await Provider.of<RecipeProvider>(context, listen: false)
          .fetchAllRecipes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.recipeUnpublishSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.recipeUnpublishError(e.toString()))),
        );
      }
    }
  }

  Future<void> _navigateToDetail(
      BuildContext context, RecipeModel recipe) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Dialog(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [CircularProgressIndicator()],
        ),
      ),
    );
    try {
      await Provider.of<RecipeProvider>(context, listen: false)
          .ensureDataReady();
      await Provider.of<RecipeProvider>(context, listen: false)
          .getRecipeById(recipe.id);
      if (mounted) Navigator.pop(context);
      if (!mounted) return;
      context.router.push(RecipeDetailRoute(
        brewingMethodId: recipe.brewingMethodId,
        recipeId: recipe.id,
      ));
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.recipeLoadError(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: ManagementAppBar(
        title: l10n.userRecipesTitle,
        controller: _controller,
        onToggleEdit: () async {
          _controller.toggleEdit();
          // Refresh recipes to reflect potential UI changes or states
          await Provider.of<RecipeProvider>(context, listen: false)
              .fetchAllRecipes();
        },
        onCreate: () => context.router.push(RecipeCreationRoute()),
      ),
      body: Consumer<RecipeProvider>(
        builder: (context, recipeProvider, _) {
          final recipes = recipeProvider.recipes;

          // Classification rules:
          // Created by you: id startsWith 'usr-' and isImported != true
          // Imported by you: isImported == true
          final createdByYou = recipes
              .where((r) => r.id.startsWith('usr-') && (r.isImported != true))
              .toList();
          final importedByYou =
              recipes.where((r) => r.isImported == true).toList();

          return CustomScrollView(
            controller: _controller.scrollController,
            slivers: [
              CreatedListSection(
                title: l10n.userRecipesSectionCreated,
                emptyHint: l10n.userRecipesEmpty,
                recipes: createdByYou,
                editModeListenable: _controller.editMode,
                itemBuilder: (ctx, recipe) => RecipeListItem(
                  recipe: recipe,
                  isEditable: true, // created list supports delete in edit mode
                  isInEditModeListenable: _controller.editMode,
                  onTap: () => _navigateToDetail(context, recipe),
                  onUnpublish: () => _unpublishRecipe(context, recipe),
                  onDelete: () async {
                    final l10n = AppLocalizations.of(context)!;
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => ConfirmDeleteDialog(
                        title: l10n.userRecipesDeleteTitle,
                        content: l10n.userRecipesDeleteMessage,
                        confirmLabel: l10n.userRecipesDeleteConfirm,
                        cancelLabel: l10n.userRecipesDeleteCancel,
                      ),
                    );
                    if (confirmed == true) {
                      await _deleteRecipe(context, recipe);
                    }
                  },
                ),
              ),
              ImportedListSection(
                title: l10n.userRecipesSectionImported,
                emptyHint: l10n.userRecipesEmpty,
                recipes: importedByYou,
                isEditable: true, // Enable delete for imported recipes
                itemBuilder: (ctx, recipe) => RecipeListItem(
                  recipe: recipe,
                  isEditable:
                      true, // imported list now supports delete in edit mode
                  isInEditModeListenable: _controller.editMode,
                  onTap: () => _navigateToDetail(context, recipe),
                  onDelete: () async {
                    final l10n = AppLocalizations.of(context)!;
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => ConfirmDeleteDialog(
                        title: l10n.userRecipesDeleteTitle,
                        content: l10n.userRecipesDeleteMessage,
                        confirmLabel: l10n.userRecipesDeleteConfirm,
                        cancelLabel: l10n.userRecipesDeleteCancel,
                      ),
                    );
                    if (confirmed == true) {
                      await _deleteRecipe(context, recipe);
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
