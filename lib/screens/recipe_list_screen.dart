import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/rendering.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_provider.dart';
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart';
import '../widgets/favorite_button.dart';
import '../utils/icon_utils.dart';
import '../providers/user_recipe_provider.dart';
import 'package:coffee_timer/l10n/app_localizations.dart'; // Added import
import '../widgets/confirm_delete_dialog.dart';
import '../utils/app_logger.dart'; // Import AppLogger

@RoutePage()
class RecipeListScreen extends StatefulWidget {
  final String? brewingMethodId;

  const RecipeListScreen({
    Key? key,
    @PathParam('brewingMethodId') this.brewingMethodId,
  }) : super(key: key);

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  bool _isEditMode = false;

  // BottomAppBar hide-on-scroll logic
  bool _isBottomBarVisible = true;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isBottomBarVisible) {
        setState(() {
          _isBottomBarVisible = false;
        });
      }
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isBottomBarVisible) {
        setState(() {
          _isBottomBarVisible = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _deleteRecipe(RecipeModel recipe) async {
    try {
      await Provider.of<UserRecipeProvider>(context, listen: false)
          .deleteUserRecipe(recipe.id);
      await Provider.of<RecipeProvider>(context, listen: false)
          .fetchAllRecipes();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.recipeDeletedSuccess)), // Changed
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!
                .recipeDeleteError(e.toString()))), // Changed
      );
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
    Provider.of<RecipeProvider>(context, listen: false).fetchAllRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          identifier: 'recipeListBackButton',
          child: const BackButton(),
        ),
        title: Row(
          children: [
            Semantics(
              identifier: 'brewingMethodIcon_${widget.brewingMethodId}',
              child: getIconByBrewingMethod(widget.brewingMethodId),
            ),
            const SizedBox(width: 8),
            FutureBuilder<String>(
              future: Provider.of<RecipeProvider>(context, listen: false)
                  .getBrewingMethodName(widget.brewingMethodId ?? ""),
              builder: (context, snapshot) => Text(snapshot.data ??
                  AppLocalizations.of(context)!.loadingEllipsis), // Changed
            ),
          ],
        ),
        // No actions here; moved to BottomAppBar
      ),
      body: Semantics(
        identifier: 'recipeListBody',
        child: Consumer<RecipeProvider>(
          builder: (context, recipeProvider, child) {
            // Filter recipes by brewingMethodId
            List<RecipeModel> recipes = recipeProvider.recipes
                .where(
                    (r) => r.brewingMethodId == (widget.brewingMethodId ?? ""))
                .toList()
              ..sort((a, b) {
                final aIsUser = a.id.startsWith('usr-');
                final bIsUser = b.id.startsWith('usr-');

                // System recipes first, sorted by numeric ID
                if (!aIsUser && !bIsUser) {
                  return int.parse(a.id).compareTo(int.parse(b.id));
                }

                // User recipes after system, sorted by creation time (timestamp part of ID)
                if (aIsUser && bIsUser) {
                  try {
                    // More robust timestamp extraction - get everything after the second hyphen
                    // This handles cases where user IDs might contain hyphens themselves
                    final aIdStr = a.id;
                    final bIdStr = b.id;

                    // Find the position of the second hyphen
                    final aSecondHyphen =
                        aIdStr.indexOf('-', aIdStr.indexOf('-') + 1);
                    final bSecondHyphen =
                        bIdStr.indexOf('-', bIdStr.indexOf('-') + 1);

                    // If we can find the second hyphen in both IDs
                    if (aSecondHyphen > 0 && bSecondHyphen > 0) {
                      // Extract everything after the second hyphen as the timestamp
                      final aTimestampStr = aIdStr.substring(aSecondHyphen + 1);
                      final bTimestampStr = bIdStr.substring(bSecondHyphen + 1);

                      // Try to parse as integers for comparison
                      try {
                        final aTimestamp = int.parse(aTimestampStr);
                        final bTimestamp = int.parse(bTimestampStr);
                        return aTimestamp.compareTo(bTimestamp);
                      } catch (e) {
                        // If integer parsing fails, compare as strings
                        return aTimestampStr.compareTo(bTimestampStr);
                      }
                    }
                  } catch (e) {
                    // If any exception occurs during the process, log it and fall back
                    AppLogger.error('Error sorting user recipes',
                        errorObject: e);
                  }

                  // Fall back to string comparison of the entire ID
                  return a.id.compareTo(b.id);
                }

                return aIsUser
                    ? 1
                    : -1; // User recipes always come after system
              });
            if (recipes.isEmpty) {
              return Center(
                  child: Text(
                      AppLocalizations.of(context)!.noRecipesFound)); // Changed
            }
            return ListView.builder(
              controller: _scrollController,
              itemCount: recipes.length,
              itemBuilder: (BuildContext context, int index) {
                RecipeModel recipe = recipes[index];
                return Semantics(
                  identifier: 'recipeListItem_${recipe.id}',
                  child: ListTile(
                    title: Text(recipe.name),
                    onTap: () => navigateToRecipeDetail(recipe),
                    trailing: _isEditMode && recipe.id.startsWith('usr-')
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FavoriteButton(recipeId: recipe.id),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: Colors.red),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => ConfirmDeleteDialog(
                                      title: AppLocalizations.of(context)!
                                          .confirmDeleteTitle,
                                      content: AppLocalizations.of(context)!
                                          .confirmDeleteMessage,
                                      confirmLabel:
                                          AppLocalizations.of(context)!.delete,
                                      cancelLabel:
                                          AppLocalizations.of(context)!.cancel,
                                    ),
                                  );
                                  if (confirmed == true) {
                                    _deleteRecipe(recipe);
                                  }
                                },
                              ),
                            ],
                          )
                        : Semantics(
                            identifier: 'favoriteButton_${recipe.id}',
                            child: FavoriteButton(recipeId: recipe.id),
                          ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: AnimatedScale(
        scale: _isBottomBarVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedOpacity(
          opacity: _isBottomBarVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !_isBottomBarVisible,
            child: FloatingActionButton(
              onPressed: () {
                context.router.push(RecipeCreationRoute(
                    brewingMethodId: widget.brewingMethodId));
              },
              child: const Icon(Icons.add),
              // backgroundColor removed to use default
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: true, // Apply bottom safe area
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _isBottomBarVisible ? kBottomNavigationBarHeight : 0,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(
                      Theme.of(context).brightness == Brightness.dark ? 31 : 20,
                    ),
                width: 1,
              ),
            ),
            // Ensure background color matches theme to avoid issues during animation
            color: Theme.of(context).bottomAppBarTheme.color ??
                Theme.of(context).colorScheme.surface,
          ),
          child: IgnorePointer(
            ignoring: !_isBottomBarVisible,
            child: AnimatedOpacity(
              opacity: _isBottomBarVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: BottomAppBar(
                shape: const CircularNotchedRectangle(),
                notchMargin: 8,
                // Important: Ensure BottomAppBar color is transparent if its parent AnimatedContainer has color
                // Or ensure AnimatedContainer's color is what you want for the BottomAppBar background
                color: Colors
                    .transparent, // Or match theme, but ensure no double backgrounds
                elevation:
                    0, // Elevation might be handled by AnimatedContainer's border or decoration
                child: Row(
                  children: [
                    const Spacer(),
                    IconButton(
                      icon: Icon(_isEditMode ? Icons.check : Icons.edit_note,
                          size: 28),
                      tooltip: 'Toggle edit mode',
                      onPressed: _toggleEditMode,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void navigateToRecipeDetail(RecipeModel recipe) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
            ],
          ),
        );
      },
    );
    try {
      await Provider.of<RecipeProvider>(context, listen: false)
          .ensureDataReady();
      // Try to fetch the recipe by id to confirm it exists.
      await Provider.of<RecipeProvider>(context, listen: false)
          .getRecipeById(recipe.id);
      Navigator.pop(context);
      context.router.push(RecipeDetailRoute(
        brewingMethodId: recipe.brewingMethodId,
        recipeId: recipe.id,
      ));
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!
                .recipeLoadError(e.toString()))), // Changed
      );
    }
  }
}
