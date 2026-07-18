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
import '../services/analytics_service.dart';

// Providers
import '../providers/recipe_provider.dart';
import '../providers/user_recipe_provider.dart';
import '../providers/user_stat_provider.dart';

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
import '../utils/app_logger.dart'; // Import AppLogger

@visibleForTesting
RecipeModel buildRuntimeRecipeForBrew({
  required RecipeModel recipe,
  required String id,
  required double coffeeAmount,
  required double waterAmount,
  required String grindSize,
  required double? waterTemperature,
  required int? sweetnessSliderPosition,
  required int? strengthSliderPosition,
  required int? coffeeChroniclerSliderPosition,
}) {
  return recipe.copyWith(
    id: id,
    coffeeAmount: coffeeAmount,
    waterAmount: waterAmount,
    grindSize: grindSize,
    waterTemp: waterTemperature ?? recipe.waterTemp,
    sweetnessSliderPosition: sweetnessSliderPosition,
    strengthSliderPosition: strengthSliderPosition,
    coffeeChroniclerSliderPosition: coffeeChroniclerSliderPosition,
  );
}

@RoutePage(name: 'RecipeDetailRoute')
class RecipeDetailScreen extends StatelessWidget {
  final String brewingMethodId;
  final String
  recipeId; // This is the ID passed in the route (could be usr-...)
  final double? prefillCoffeeAmount;
  final double? prefillWaterAmount;
  final String? prefillGrindSize;
  final double? prefillWaterTemp;

  const RecipeDetailScreen({
    super.key,
    @PathParam('brewingMethodId') required this.brewingMethodId,
    @PathParam('recipeId') required this.recipeId,
    this.prefillCoffeeAmount,
    this.prefillWaterAmount,
    this.prefillGrindSize,
    this.prefillWaterTemp,
  });

  @override
  Widget build(BuildContext context) {
    // Pass the potentially prefixed ID to the stateful widget
    return RecipeDetailBase(
      brewingMethodId: brewingMethodId,
      initialRecipeId: recipeId,
      prefillCoffeeAmount: prefillCoffeeAmount,
      prefillWaterAmount: prefillWaterAmount,
      prefillGrindSize: prefillGrindSize,
      prefillWaterTemp: prefillWaterTemp,
    );
  }
}

// The base widget that contains the actual implementation
class RecipeDetailBase extends StatefulWidget {
  final String? brewingMethodId;
  final String initialRecipeId; // The ID passed from the route
  final double? prefillCoffeeAmount;
  final double? prefillWaterAmount;
  final String? prefillGrindSize;
  final double? prefillWaterTemp;

  const RecipeDetailBase({
    super.key,
    this.brewingMethodId,
    required this.initialRecipeId,
    this.prefillCoffeeAmount,
    this.prefillWaterAmount,
    this.prefillGrindSize,
    this.prefillWaterTemp,
  });

  @override
  State<RecipeDetailBase> createState() => _RecipeDetailBaseState();
}

class _RecipeDetailBaseState extends State<RecipeDetailBase> {
  final RecipeDetailController _controller = RecipeDetailController();

  // Core state variables
  RecipeModel? _updatedRecipe;
  // Grind size of the currently attached bean (if any). Highest priority when
  // resolving the displayed grind size (bean > manual override > recipe default).
  String? _selectedBeanGrindSize;
  int _grindSuggestionRequest = 0;
  bool _brewAgainApplied = false;
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
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((AuthState data) {
          if (mounted) {
            _handleAuthenticationChange(data);
          }
        });

    // Use WidgetsBinding to ensure context is available for AppLocalizations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _brewingMethodName =
              AppLocalizations.of(context)?.unknownBrewingMethod ??
              "Unknown Brewing Method";
        });
        _loadInitialRecipeAndBean();
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
          _loadInitialRecipeAndBean();
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

  Future<void> _loadInitialRecipeAndBean() async {
    await _performInitialRecipeCheck();
    if (!mounted) return;
    await _loadSelectedBean();
    if (!mounted || _updatedRecipe == null || _brewAgainApplied) return;

    final hasPrefill =
        widget.prefillCoffeeAmount != null ||
        widget.prefillWaterAmount != null ||
        widget.prefillGrindSize != null ||
        widget.prefillWaterTemp != null;
    if (!hasPrefill) return;

    _controller.applyBrewAgainPrefill(
      coffeeAmount: widget.prefillCoffeeAmount,
      waterAmount: widget.prefillWaterAmount,
      grindSize: widget.prefillGrindSize,
      waterTemp: widget.prefillWaterTemp,
    );
    _brewAgainApplied = true;
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
      // RecipeLoadingService just set the grind field to the recipe's base value
      // (customGrindSize ?? grindSize). Re-apply the bean's grind size on top if
      // a bean with one is attached, so the priority order is respected
      // regardless of whether recipe or bean finished loading first.
      _applyGrindSizePriority();
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
      AppLogger.debug('Auth state change - user is null or anonymous');
      return;
    }

    final currentUserId = user.id;
    AppLogger.debug('Auth state change detected for user: $currentUserId');

    // Check if we have an effective recipe ID to work with
    if (_effectiveRecipeId == null) {
      AppLogger.debug('No effective recipe ID to check');
      return;
    }

    final currentRecipeId = _effectiveRecipeId!;
    AppLogger.debug('Current effective recipe ID: $currentRecipeId');

    // Only process user-created recipes (those with 'usr-' prefix)
    if (!currentRecipeId.startsWith('usr-')) {
      AppLogger.debug('Recipe ID does not start with usr-, skipping auth sync');
      return;
    }

    try {
      // If the recipe already belongs to the current user, nothing to do.
      final ownsRecipePrefix = 'usr-$currentUserId-';
      if (currentRecipeId.startsWith(ownsRecipePrefix)) {
        AppLogger.debug(
          'Recipe ID already belongs to current user, no remap needed',
        );
        return;
      }

      // We need to attempt a remap to the current user's namespace.
      // Robust timestamp extraction: take the last hyphen-separated token.
      final parts = currentRecipeId.split('-');
      if (parts.length < 3) {
        AppLogger.debug(
          'Invalid usr-* recipe ID format, cannot extract timestamp for remap',
        );
        return;
      }
      final timestamp = parts.last;
      AppLogger.debug(
        'Remap path: extracted timestamp="$timestamp" from "$currentRecipeId"',
      );

      final newRecipeId = 'usr-$currentUserId-$timestamp';
      AppLogger.debug('Attempting remap to newRecipeId="$newRecipeId"');

      // Regardless of whether the old usr-ID exists locally, we try loading the new ID.
      if (!mounted) return;
      final newResult =
          await RecipeLoadingService.loadRecipeAndInitializeController(
            context,
            newRecipeId,
            RecipeDetailController(), // Temporary controller for checking
          );

      if (newResult.isSuccess && newResult.recipe != null) {
        AppLogger.debug(
          'Remap succeeded: found recipe under newRecipeId="$newRecipeId". Updating effectiveRecipeId and reloading details.',
        );
        if (!mounted) return;
        setState(() {
          _effectiveRecipeId = newRecipeId;
        });
        await _loadRecipeDetails(newRecipeId);
        AppLogger.debug(
          'Effective recipe ID updated from "$currentRecipeId" to "$newRecipeId"',
        );
      } else {
        AppLogger.debug(
          'Remap attempt: recipe not found under newRecipeId="$newRecipeId". Leaving effectiveRecipeId unchanged.',
        );
      }
    } catch (e) {
      AppLogger.debug(
        'Error during authentication change handling',
        errorObject: e,
      );
    }
  }

  /// Loads selected bean using BeanSelectionService
  Future<void> _loadSelectedBean() async {
    if (!mounted) return;

    const service = BeanSelectionService();
    final result = await service.loadSelectedBean(context);

    if (!mounted) return;

    _selectedBeanGrindSize = result.grindSize;
    if (result.uuid == null) {
      _selectedBeanGrindSize = null;
      _controller.clearBeanSelection();
    } else {
      _controller.setBeanSelection(
        uuid: result.uuid,
        name: result.name,
        originalUrl: result.originalLogoUrl,
        mirrorUrl: result.mirrorLogoUrl,
      );
    }
    _applyGrindSizePriority();
  }

  /// Resolves the grind size shown on the recipe screen using the priority:
  /// attached bean's grind size > recipe's saved manual override > recipe default.
  /// Safe to call after either the recipe or the bean finishes loading.
  void _applyGrindSizePriority() {
    final recipe = _updatedRecipe;
    if (recipe == null) {
      _controller.clearGrindSuggestion();
      return;
    }
    final beanGrind = _selectedBeanGrindSize?.trim();
    if (beanGrind != null && beanGrind.isNotEmpty) {
      _controller.applyBeanGrindSize(beanGrind);
    } else {
      _controller.resetGrindSizeToFallback(
        recipe.customGrindSize ?? recipe.grindSize,
      );
    }
    unawaited(_loadGrindSuggestion());
  }

  Future<void> _loadGrindSuggestion() async {
    final request = ++_grindSuggestionRequest;
    final beanUuid = _controller.selectedBeanUuid;
    final brewingMethodId = _updatedRecipe?.brewingMethodId;
    if (beanUuid == null || brewingMethodId == null) {
      _controller.clearGrindSuggestion();
      return;
    }

    final suggestion = await Provider.of<UserStatProvider>(
      context,
      listen: false,
    ).latestGrindSuggestionForBeanAndMethod(beanUuid, brewingMethodId);
    if (!mounted ||
        request != _grindSuggestionRequest ||
        beanUuid != _controller.selectedBeanUuid ||
        brewingMethodId != _updatedRecipe?.brewingMethodId) {
      return;
    }
    if (suggestion == null) {
      _controller.clearGrindSuggestion();
    } else {
      _controller.setGrindSuggestion(
        suggestion.grindSize,
        suggestion.tasteBalance,
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
            if (context.mounted) Navigator.of(context).pop();
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
      _selectedBeanGrindSize = result.grindSize;
      _controller.setBeanSelection(
        uuid: result.uuid,
        name: result.name,
        originalUrl: result.originalLogoUrl,
        mirrorUrl: result.mirrorLogoUrl,
      );
    } else {
      await service.clearSelectedBean(context);
      if (!mounted) return;
      _selectedBeanGrindSize = null;
      _controller.clearBeanSelection();
    }
    _applyGrindSizePriority();
  }

  /// Handles recipe sharing using RecipeImportSharingService
  void _onShare(BuildContext context) async {
    if (_isSharing) return; // Prevent double taps

    final String shareRecipeId = _effectiveRecipeId ?? widget.initialRecipeId;

    if (_updatedRecipe == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.recipeLoadErrorGeneric)));
      return;
    }

    if (!mounted) return;
    setState(() => _isSharing = true);

    final result = await RecipeImportSharingService.shareRecipe(
      context: context,
      recipe: _updatedRecipe!,
      shareRecipeId: shareRecipeId,
    );
    AppLogger.debug(
      'Share result - success: ${result.success}, resolvedRecipeId: ${result.resolvedRecipeId}',
    );

    if (result.success) {
      AnalyticsService.instance.track(
        'recipe_shared',
        properties: {
          'recipe_id': shareRecipeId,
          'brewing_method_id': _updatedRecipe?.brewingMethodId,
        },
      );
    }

    // If service remapped to a stable usr-<user>-<timestamp> id during share, persist it.
    if (result.success && result.resolvedRecipeId != null) {
      final newId = result.resolvedRecipeId!;
      if (mounted && _effectiveRecipeId != newId) {
        setState(() {
          _effectiveRecipeId = newId;
        });
        // Refresh to ensure UI and dependent logic align with the new id.
        await _loadRecipeDetails(newId);
      }
    }

    // Only user recipes should be marked public in local user-recipe storage.
    final String effectiveSharedId = result.resolvedRecipeId ?? shareRecipeId;
    final bool isUserRecipe = effectiveSharedId.startsWith('usr-');
    if (result.success && isUserRecipe && context.mounted) {
      setState(() {
        _updatedRecipe = _updatedRecipe?.copyWith(isPublic: true);
      });
      if (_updatedRecipe != null) {
        final userRecipeProvider = Provider.of<UserRecipeProvider>(
          context,
          listen: false,
        );
        await userRecipeProvider.updateUserRecipe(
          _updatedRecipe!.copyWith(isPublic: true),
        );
      }
      AppLogger.debug(
        'Updated local user recipe database and state - isPublic: true',
      );
    } else if (result.success && !isUserRecipe) {
      AppLogger.debug(
        'Skipping local user-recipe persistence after sharing built-in recipe: $effectiveSharedId',
      );
    }

    if (mounted) {
      setState(() => _isSharing = false);
    }

    AppLogger.debug(
      'After sharing, recipe $shareRecipeId isPublic: ${_updatedRecipe?.isPublic}',
    );
  }

  /// Navigates to edit recipe using RecipeNavigationService
  void _navigateToEditRecipe(BuildContext context, RecipeModel recipe) async {
    await RecipeNavigationService.navigateToEditRecipe(
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
    BuildContext context,
    RecipeModel recipeToCopy,
  ) async {
    await RecipeNavigationService.navigateToCopyRecipe(
      context: context,
      recipeToCopy: recipeToCopy,
    );
  }

  /// Handles unpublishing of a user recipe
  void _onUnpublish(BuildContext context) async {
    final recipe = _updatedRecipe;
    if (recipe == null) return;

    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final userRecipeProvider = Provider.of<UserRecipeProvider>(
        context,
        listen: false,
      );
      await userRecipeProvider.unpublishRecipe(_effectiveRecipeId ?? recipe.id);

      if (!context.mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.recipeUnpublishSuccess)),
      );

      // Refresh the recipe data to reflect the privacy status change
      await _loadRecipeDetails(_effectiveRecipeId ?? recipe.id);
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.recipeUnpublishError(e.toString()))),
        );
      }
    }
  }

  /// Saves custom amounts and navigates to preparation screen
  Future<void> _saveCustomAmountsAndNavigate(
    BuildContext context,
    RecipeModel recipe,
  ) async {
    // Use _effectiveRecipeId when saving
    final String idToSave = _effectiveRecipeId ?? widget.initialRecipeId;

    // Ensure context is valid before accessing Providers
    if (!context.mounted) return;

    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    double customCoffeeAmount =
        double.tryParse(
          _controller.coffeeController.text.replaceAll(',', '.'),
        ) ??
        recipe.coffeeAmount;
    double customWaterAmount =
        double.tryParse(
          _controller.waterController.text.replaceAll(',', '.'),
        ) ??
        recipe.waterAmount;

    final String controllerGrind = _controller.grindSizeController.text.trim();
    // Value used for the actual brew — the attached bean's grind size takes
    // effect here when present.
    final String? effectiveGrindSize = controllerGrind.isEmpty
        ? null
        : controllerGrind;

    // Value persisted as the recipe's manual override. If the displayed grind
    // size came from the attached bean (and wasn't manually edited since),
    // leave the recipe's saved override untouched so attaching a bean does not
    // clobber it (layered priority: bean > manual override > default).
    final String? grindSizeToPersist = _controller.grindSizeFromBean
        ? recipe.customGrindSize
        : effectiveGrindSize;
    final double? waterTempToPersist = _controller.waterTemperatureFromRecipe
        ? recipe.customWaterTemp
        : _controller.waterTemperature;

    await recipeProvider.saveCustomAmounts(
      idToSave,
      customCoffeeAmount,
      customWaterAmount,
      customGrindSize: grindSizeToPersist,
      customWaterTemp: waterTempToPersist,
    );

    // Use effective ID for slider logic check
    if (idToSave == '106' || idToSave == '1002') {
      await recipeProvider.saveSliderPositions(
        idToSave,
        sweetnessSliderPosition: idToSave == '106'
            ? _controller.sweetnessSliderPosition
            : null,
        strengthSliderPosition: idToSave == '106'
            ? _controller.strengthSliderPosition
            : null,
        coffeeChroniclerSliderPosition: idToSave == '1002'
            ? _controller.coffeeChroniclerSliderPosition
            : null,
      );
    }

    final updatedRecipeForNav = buildRuntimeRecipeForBrew(
      recipe: recipe,
      id: idToSave,
      coffeeAmount: customCoffeeAmount,
      waterAmount: customWaterAmount,
      grindSize: effectiveGrindSize ?? recipe.grindSize,
      waterTemperature: _controller.waterTemperature,
      sweetnessSliderPosition: idToSave == '106'
          ? _controller.sweetnessSliderPosition
          : null,
      strengthSliderPosition: idToSave == '106'
          ? _controller.strengthSliderPosition
          : null,
      coffeeChroniclerSliderPosition: idToSave == '1002'
          ? _controller.coffeeChroniclerSliderPosition
          : null,
    );

    // Ensure context is valid before navigating
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreparationScreen(
          recipe: updatedRecipeForNav,
          brewingMethodName: _brewingMethodName,
          coffeeChroniclerSliderPosition:
              updatedRecipeForNav.coffeeChroniclerSliderPosition,
        ),
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
          onUnpublish: () => _onUnpublish(context),
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
