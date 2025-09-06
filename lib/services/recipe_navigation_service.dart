import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_provider.dart';
import '../providers/user_recipe_provider.dart';
import '../screens/recipe_creation_screen.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

/// Result class for navigation operations
class NavigationResult {
  final bool success;
  final String? errorMessage;
  final RecipeModel? recipe;

  const NavigationResult({
    required this.success,
    this.errorMessage,
    this.recipe,
  });

  factory NavigationResult.success({RecipeModel? recipe}) {
    return NavigationResult(success: true, recipe: recipe);
  }

  factory NavigationResult.failure(String errorMessage) {
    return NavigationResult(success: false, errorMessage: errorMessage);
  }
}

/// Result class for recipe copying operations
class CopyResult {
  final bool success;
  final String? newRecipeId;
  final String? errorMessage;
  final RecipeModel? copiedRecipe;

  const CopyResult({
    required this.success,
    this.newRecipeId,
    this.errorMessage,
    this.copiedRecipe,
  });

  factory CopyResult.success(String newRecipeId, RecipeModel copiedRecipe) {
    return CopyResult(
      success: true,
      newRecipeId: newRecipeId,
      copiedRecipe: copiedRecipe,
    );
  }

  factory CopyResult.failure(String errorMessage) {
    return CopyResult(success: false, errorMessage: errorMessage);
  }
}

/// Service for handling recipe navigation operations
class RecipeNavigationService {
  RecipeNavigationService._();

  /// Navigates to edit recipe screen with import status checks
  static Future<NavigationResult> navigateToEditRecipe({
    required BuildContext context,
    required RecipeModel recipe,
    required String effectiveRecipeId,
    required VoidCallback onRecipeUpdated,
  }) async {
    if (!context.mounted) {
      return NavigationResult.failure('Context not mounted');
    }

    final l10n = AppLocalizations.of(context)!;

    try {
      // Check if recipe is imported and show confirmation dialog
      if (recipe.isImported == true) {
        final bool? confirm =
            await _showEditImportedRecipeDialog(context, l10n);

        if (confirm != true) {
          return NavigationResult.success(); // User cancelled
        }

        // User confirmed - copy the recipe and edit the copy
        final copyResult = await _copyRecipeForEditing(context, recipe, l10n);
        if (!copyResult.success) {
          return NavigationResult.failure(copyResult.errorMessage!);
        }

        // Navigate to edit the copied recipe
        if (context.mounted && copyResult.copiedRecipe != null) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RecipeCreationScreen(
                recipe: copyResult.copiedRecipe!,
                redirectToNewDetailOnSave: true,
              ),
            ),
          );
          onRecipeUpdated();
          return NavigationResult.success(recipe: copyResult.copiedRecipe);
        }
      } else {
        // Recipe is not imported - edit directly
        if (context.mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RecipeCreationScreen(recipe: recipe),
            ),
          );
          onRecipeUpdated();
          return NavigationResult.success(recipe: recipe);
        }
      }

      return NavigationResult.failure('Navigation failed');
    } catch (e) {
      return NavigationResult.failure(
          'Error during navigation: ${e.toString()}');
    }
  }

  /// Navigates to copy recipe and edit the copy
  static Future<NavigationResult> navigateToCopyRecipe({
    required BuildContext context,
    required RecipeModel recipeToCopy,
  }) async {
    if (!context.mounted) {
      return NavigationResult.failure('Context not mounted');
    }

    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final copyResult = await _copyRecipe(context, recipeToCopy, l10n);

      if (!context.mounted) {
        return NavigationResult.failure('Context not mounted after copy');
      }

      if (copyResult.success && copyResult.copiedRecipe != null) {
        // Show success message
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.recipeCopySuccess)),
        );

        // Navigate to edit the copied recipe
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RecipeCreationScreen(
              recipe: copyResult.copiedRecipe!,
              redirectToNewDetailOnSave: true,
            ),
          ),
        );

        return NavigationResult.success(recipe: copyResult.copiedRecipe);
      } else {
        // Show error message
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(copyResult.errorMessage!)),
        );
        return NavigationResult.failure(copyResult.errorMessage!);
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.recipeCopyError(e.toString()))),
        );
      }
      return NavigationResult.failure('Error copying recipe: ${e.toString()}');
    }
  }

  /// Shows confirmation dialog for editing imported recipes
  static Future<bool?> _showEditImportedRecipeDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editImportedRecipeTitle),
        content: Text(l10n.editImportedRecipeBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.editImportedRecipeButtonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.editImportedRecipeButtonCopy),
          ),
        ],
      ),
    );
  }

  /// Copies a recipe for editing (used when editing imported recipes)
  static Future<CopyResult> _copyRecipeForEditing(
    BuildContext context,
    RecipeModel recipe,
    AppLocalizations l10n,
  ) async {
    if (!context.mounted) {
      return CopyResult.failure('Context not mounted');
    }

    try {
      final userRecipeProvider =
          Provider.of<UserRecipeProvider>(context, listen: false);
      final recipeProvider =
          Provider.of<RecipeProvider>(context, listen: false);

      final newRecipeId = await userRecipeProvider.copyUserRecipe(recipe);

      if (!context.mounted) {
        return CopyResult.failure('Context not mounted after copy');
      }

      if (newRecipeId != null) {
        final updatedRecipe = await recipeProvider.getRecipeById(newRecipeId);

        if (updatedRecipe != null) {
          // Clear import status for the copied recipe
          await userRecipeProvider.clearImportStatus(newRecipeId);
          return CopyResult.success(newRecipeId, updatedRecipe);
        } else {
          return CopyResult.failure(l10n.recipeLoadErrorGeneric);
        }
      } else {
        return CopyResult.failure(
            l10n.recipeCopyError(l10n.recipeCopyErrorOperationFailed));
      }
    } catch (e) {
      return CopyResult.failure(
          'Error copying recipe for editing: ${e.toString()}');
    }
  }

  /// Copies a recipe (general copy operation)
  static Future<CopyResult> _copyRecipe(
    BuildContext context,
    RecipeModel recipeToCopy,
    AppLocalizations l10n,
  ) async {
    if (!context.mounted) {
      return CopyResult.failure('Context not mounted');
    }

    try {
      final userRecipeProvider =
          Provider.of<UserRecipeProvider>(context, listen: false);
      final recipeProvider =
          Provider.of<RecipeProvider>(context, listen: false);

      final String? newRecipeId =
          await userRecipeProvider.copyUserRecipe(recipeToCopy);

      if (!context.mounted) {
        return CopyResult.failure('Context not mounted after copy');
      }

      if (newRecipeId != null) {
        await recipeProvider.fetchAllRecipes();

        if (!context.mounted) {
          return CopyResult.failure('Context not mounted after refresh');
        }

        final RecipeModel? newRecipe =
            await recipeProvider.getRecipeById(newRecipeId);

        if (!context.mounted) {
          return CopyResult.failure('Context not mounted after loading');
        }

        if (newRecipe != null) {
          return CopyResult.success(newRecipeId, newRecipe);
        } else {
          return CopyResult.failure(
              l10n.recipeCopyError(l10n.recipeCopyErrorLoadingEdit));
        }
      } else {
        return CopyResult.failure(
            l10n.recipeCopyError(l10n.recipeCopyErrorOperationFailed));
      }
    } catch (e) {
      return CopyResult.failure(l10n.recipeCopyError(e.toString()));
    }
  }
}
