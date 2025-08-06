import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Models and Controllers
import '../models/recipe_model.dart';
import '../controllers/recipe_detail_controller.dart';

// Services
import '../services/recipe_import_sharing_service.dart';
import '../services/recipe_loading_service.dart';
import '../services/recipe_navigation_service.dart';
import '../services/bean_selection_service.dart';

// Providers
import '../providers/recipe_provider.dart';

// Widgets
import '../widgets/recipe_detail/loading_error_states.dart';
import '../widgets/recipe_detail/recipe_detail_app_bar.dart';
import '../widgets/recipe_detail/recipe_content_builder.dart';
import '../widgets/recipe_detail/floating_nav_button.dart';
import '../widgets/add_coffee_beans_widget.dart';

// Screens
import '../screens/preparation_screen.dart';

// Utils and Localization
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../webhelper/web_helper.dart' as web;

@RoutePage(name: 'RecipeDetailRoute')
class RecipeDetailScreen extends StatelessWidget {
  final String brewingMethodId;
  final String
      recipeId; // This is the ID passed in the route (could be usr-...)

  const RecipeDetailScreen({
    Key? key,
    @PathParam('brewingMethodId') required this.brewingMethodId,
    @PathParam('recipeId') required this.recipeId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Pass the potentially prefixed ID to the stateful widget
    return RecipeDetailBase(
      brewingMethodId: brewingMethodId,
      initialRecipeId: recipeId,
    );
  }
}

// The base widget that contains the actual implementation
class RecipeDetailBase extends StatefulWidget {
  final String? brewingMethodId;
  final String initialRecipeId; // The ID passed from the route

  const RecipeDetailBase({
    Key? key,
    this.brewingMethodId,
    required this.initialRecipeId,
  }) : super(key: key);

  @override
  _RecipeDetailBaseState createState() => _RecipeDetailBaseState();
}

class _RecipeDetailBaseState extends State<RecipeDetailBase> {
  final RecipeDetailController _controller = RecipeDetailController();

  // Core state variables
  RecipeModel? _updatedRecipe;
  String _brewingMethodName = "";
  String?
      _effectiveRecipeId; // The ID used to load the recipe (might change after import)

  // Loading and error state
  bool _isLoading = true;
  bool _importCheckComplete = false;
  String? _errorMessage;
  bool _isSharing = false; // Flag to prevent double taps on share

  // Authentication state change handling
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _effectiveRecipeId = widget.initialRecipeId; // Start with the initial ID

    // Set up authentication state change listener
    _authStateSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen(
      (AuthState data) {
        if (mounted) {
          _handleAuthenticationChange(data);
        }
      },
    );

    // Use WidgetsBinding to ensure context is available for AppLocalizations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _brewingMethodName =
              AppLocalizations.of(context)?.unknownBrewingMethod ??
                  "Unknown Brewing Method";
        });
        _performInitialRecipeCheck(); // Start the check
        _loadSelectedBean();
      }
    });
  }

  @override
  void didUpdateWidget(covariant RecipeDetailBase oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRecipeId != widget.initialRecipeId) {
      setState(() {
        _effectiveRecipeId = widget.initialRecipeId;
        _isLoading = true;
        _importCheckComplete = false;
        _errorMessage = null;
        _updatedRecipe = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _performInitialRecipeCheck();
          _loadSelectedBean();
        }
      });
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Performs the initial recipe check using RecipeImportSharingService
  Future<void> _performInitialRecipeCheck() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _importCheckComplete = false;
      _errorMessage = null;
    });

    final result = await RecipeImportSharingService.performInitialRecipeCheck(
      context: context,
      potentialImportId: widget.initialRecipeId,
    );

    if (!mounted) return;

    if (result.success && result.newRecipeId != null) {
      _effectiveRecipeId = result.newRecipeId;
      await _loadRecipeDetails(_effectiveRecipeId!);
    } else {
      setState(() => _errorMessage = result.errorMessage);
    }

    setState(() {
      _isLoading = false;
      _importCheckComplete = true;
    });
  }

  /// Loads recipe details using RecipeLoadingService
  Future<void> _loadRecipeDetails(String recipeIdToLoad) async {
    if (!mounted) return;

    final result = await RecipeLoadingService.loadRecipeAndInitializeController(
      context,
      recipeIdToLoad,
      _controller,
    );

    if (!mounted) return;

    if (result.isSuccess && result.recipe != null) {
      setState(() {
        _brewingMethodName = result.brewingMethodName ?? _brewingMethodName;
        _updatedRecipe = result.recipe;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _errorMessage = result.errorMessage;
        _updatedRecipe = null;
      });
    }
  }

  /// Handles authentication state changes and updates recipe ID if needed
  Future<void> _handleAuthenticationChange(AuthState authState) async {
    if (!mounted) return;

    final user = authState.session?.user;
    if (user == null || user.isAnonymous) {
      print('DEBUG: Auth state change - user is null or anonymous');
      return;
    }

    final currentUserId = user.id;
    print('DEBUG: Auth state change detected for user: $currentUserId');

    // Check if we have an effective recipe ID to work with
    if (_effectiveRecipeId == null) {
      print('DEBUG: No effective recipe ID to check');
      return;
    }

    final currentRecipeId = _effectiveRecipeId!;
    print('DEBUG: Current effective recipe ID: $currentRecipeId');

    // Only process user-created recipes (those with 'usr-' prefix)
    if (!currentRecipeId.startsWith('usr-')) {
      print('DEBUG: Recipe ID does not start with usr-, skipping auth sync');
      return;
    }

    try {
      // If the recipe already belongs to the current user, nothing to do.
      final ownsRecipePrefix = 'usr-$currentUserId-';
      if (currentRecipeId.startsWith(ownsRecipePrefix)) {
        print(
            'DEBUG: Recipe ID already belongs to current user, no remap needed');
        return;
      }

      // We need to attempt a remap to the current user's namespace.
      // Robust timestamp extraction: take the last hyphen-separated token.
      final parts = currentRecipeId.split('-');
      if (parts.length < 3) {
        print(
            'DEBUG: Invalid usr-* recipe ID format, cannot extract timestamp for remap');
        return;
      }
      final timestamp = parts.last;
      print(
          'DEBUG: Remap path: extracted timestamp="$timestamp" from "$currentRecipeId"');

      final newRecipeId = 'usr-$currentUserId-$timestamp';
      print('DEBUG: Attempting remap to newRecipeId="$newRecipeId"');

      // Regardless of whether the old usr-ID exists locally, we try loading the new ID.
      if (!mounted) return;
      final newResult =
          await RecipeLoadingService.loadRecipeAndInitializeController(
        context,
        newRecipeId,
        RecipeDetailController(), // Temporary controller for checking
      );

      if (newResult.isSuccess && newResult.recipe != null) {
        print(
            'DEBUG: Remap succeeded: found recipe under newRecipeId="$newRecipeId". Updating effectiveRecipeId and reloading details.');
        if (!mounted) return;
        setState(() {
          _effectiveRecipeId = newRecipeId;
        });
        await _loadRecipeDetails(newRecipeId);
        print(
            'DEBUG: Effective recipe ID updated from "$currentRecipeId" to "$newRecipeId"');
      } else {
        print(
            'DEBUG: Remap attempt: recipe not found under newRecipeId="$newRecipeId". Leaving effectiveRecipeId unchanged.');
      }
    } catch (e) {
      print('DEBUG: Error during authentication change handling: $e');
    }
  }

  /// Loads selected bean using BeanSelectionService
  Future<void> _loadSelectedBean() async {
    if (!mounted) return;

    const service = BeanSelectionService();
    final result = await service.loadSelectedBean(context);

    if (!mounted) return;

    if (result == null) {
      _controller.clearBeanSelection();
    } else {
      _controller.setBeanSelection(
        uuid: result.uuid,
        name: result.name,
        originalUrl: result.originalLogoUrl,
        mirrorUrl: result.mirrorLogoUrl,
      );
    }
  }

  /// Opens the add beans popup
  void _openAddBeansPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AddCoffeeBeansWidget(
          onSelect: (String selectedBeanUuid) async {
            await _updateSelectedBean(selectedBeanUuid);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  /// Updates selected bean using BeanSelectionService
  Future<void> _updateSelectedBean(String? uuid) async {
    if (!mounted) return;

    const service = BeanSelectionService();
    if (uuid != null) {
      final result = await service.updateSelectedBean(context, uuid);
      if (!mounted) return;
      if (result != null) {
        _controller.setBeanSelection(
          uuid: result.uuid,
          name: result.name,
          originalUrl: result.originalLogoUrl,
          mirrorUrl: result.mirrorLogoUrl,
        );
      }
    } else {
      await service.clearSelectedBean(context);
      if (!mounted) return;
      _controller.clearBeanSelection();
    }
  }

  /// Handles recipe sharing using RecipeImportSharingService
  void _onShare(BuildContext context) async {
    if (_isSharing) return; // Prevent double taps

    final String shareRecipeId = _effectiveRecipeId ?? widget.initialRecipeId;

    if (_updatedRecipe == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.recipeLoadErrorGeneric)));
      return;
    }

    if (!mounted) return;

    setState(() => _isSharing = true);

    final result = await RecipeImportSharingService.shareRecipe(
      context: context,
      recipe: _updatedRecipe!,
      shareRecipeId: shareRecipeId,
    );

    // If service remapped to a stable usr-<user>-<timestamp> id during share, persist it
    if (result.success && result.resolvedRecipeId != null) {
      final newId = result.resolvedRecipeId!;
      if (mounted && _effectiveRecipeId != newId) {
        setState(() {
          _effectiveRecipeId = newId;
        });
        // Optionally refresh to ensure UI and any dependent logic align with new id
        await _loadRecipeDetails(newId);
      }
    }

    if (mounted) {
      setState(() => _isSharing = false);
    }
  }

  /// Navigates to edit recipe using RecipeNavigationService
  void _navigateToEditRecipe(BuildContext context, RecipeModel recipe) async {
    final result = await RecipeNavigationService.navigateToEditRecipe(
      context: context,
      recipe: recipe,
      effectiveRecipeId: _effectiveRecipeId ?? widget.initialRecipeId,
      onRecipeUpdated: () async {
        if (_effectiveRecipeId != null) {
          await _loadRecipeDetails(_effectiveRecipeId!);
        }
      },
    );
  }

  /// Navigates to copy recipe using RecipeNavigationService
  Future<void> _navigateToCopyRecipe(
      BuildContext context, RecipeModel recipeToCopy) async {
    final result = await RecipeNavigationService.navigateToCopyRecipe(
      context: context,
      recipeToCopy: recipeToCopy,
    );
  }

  /// Saves custom amounts and navigates to preparation screen
  Future<void> _saveCustomAmountsAndNavigate(
      BuildContext context, RecipeModel recipe) async {
    // Use _effectiveRecipeId when saving
    final String idToSave = _effectiveRecipeId ?? widget.initialRecipeId;

    // Ensure context is valid before accessing Providers
    if (!mounted) return;

    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    double customCoffeeAmount = double.tryParse(
            _controller.coffeeController.text.replaceAll(',', '.')) ??
        recipe.coffeeAmount;
    double customWaterAmount = double.tryParse(
            _controller.waterController.text.replaceAll(',', '.')) ??
        recipe.waterAmount;

    await recipeProvider.saveCustomAmounts(
        idToSave, customCoffeeAmount, customWaterAmount);

    // Use effective ID for slider logic check
    if (idToSave == '106' || idToSave == '1002') {
      await recipeProvider.saveSliderPositions(
        idToSave,
        sweetnessSliderPosition:
            idToSave == '106' ? _controller.sweetnessSliderPosition : null,
        strengthSliderPosition:
            idToSave == '106' ? _controller.strengthSliderPosition : null,
        coffeeChroniclerSliderPosition: idToSave == '1002'
            ? _controller.coffeeChroniclerSliderPosition
            : null,
      );
    }

    RecipeModel updatedRecipeForNav = recipe.copyWith(
      id: idToSave, // Ensure the ID passed to next screen is the effective one
      coffeeAmount: customCoffeeAmount,
      waterAmount: customWaterAmount,
      sweetnessSliderPosition:
          idToSave == '106' ? _controller.sweetnessSliderPosition : null,
      strengthSliderPosition:
          idToSave == '106' ? _controller.strengthSliderPosition : null,
      coffeeChroniclerSliderPosition: idToSave == '1002'
          ? _controller.coffeeChroniclerSliderPosition
          : null,
    );

    // Ensure context is valid before navigating
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreparationScreen(
            recipe: updatedRecipeForNav,
            brewingMethodName: _brewingMethodName,
            coffeeChroniclerSliderPosition:
                updatedRecipeForNav.coffeeChroniclerSliderPosition),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator until check is complete
    if (_isLoading || !_importCheckComplete) {
      return const RecipeLoadingState();
    }

    // Show error message if something went wrong during the check/import
    if (_errorMessage != null) {
      return RecipeErrorState(errorMessage: _errorMessage);
    }

    // If check is complete but recipe is still null (shouldn't happen if error handling is right, but safety check)
    if (_updatedRecipe == null) {
      return const RecipeNotFoundState();
    }

    // --- Main Content Build ---
    RecipeModel recipe = _updatedRecipe!;
    final l10n = AppLocalizations.of(context)!;

    if (kIsWeb) {
      web.document.title = l10n.recipeDetailWebTitle(recipe.name);
    }

    final double fabHeight = 76.0 + 16.0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: RecipeDetailAppBar(
          recipe: recipe,
          brewingMethodName: _brewingMethodName,
          idForActions: _effectiveRecipeId ?? widget.initialRecipeId,
          isSharing: _isSharing,
          onEdit: () => _navigateToEditRecipe(context, recipe),
          onCopy: () => _navigateToCopyRecipe(context, recipe),
          onShare: () => _onShare(context),
        ),
        body: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, fabHeight),
                  child: SingleChildScrollView(
                    child: RecipeContentBuilder(
                      recipe: recipe,
                      controller: _controller,
                      effectiveRecipeId: _effectiveRecipeId,
                      onSelectBeans: () => _openAddBeansPopup(context),
                      onClearBeanSelection: () => _updateSelectedBean(null),
                      onCoffeeAmountChanged: () {
                        final id = _effectiveRecipeId;
                        if (id != null) {
                          _controller.updateAmounts(id);
                        }
                      },
                      onWaterAmountChanged: () {
                        final id = _effectiveRecipeId;
                        if (id != null) {
                          _controller.updateAmounts(id);
                        }
                      },
                      onCoffeeFocus: () => _controller.setEditingCoffee(true),
                      onWaterFocus: () => _controller.setEditingCoffee(false),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16.0,
                  right: 16.0,
                  child: FloatingNavButton(
                    onPressed: () =>
                        _saveCustomAmountsAndNavigate(context, recipe),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
