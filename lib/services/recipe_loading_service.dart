import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_provider.dart';
import '../controllers/recipe_detail_controller.dart';
import '../utils/input_validator.dart';

/// Result class for recipe loading operations
class RecipeLoadResult {
  final RecipeModel? recipe;
  final String? brewingMethodName;
  final String? errorMessage;
  final bool isSuccess;

  const RecipeLoadResult({
    this.recipe,
    this.brewingMethodName,
    this.errorMessage,
    required this.isSuccess,
  });

  /// Factory constructor for successful result
  factory RecipeLoadResult.success({
    required RecipeModel recipe,
    required String brewingMethodName,
  }) {
    return RecipeLoadResult(
      recipe: recipe,
      brewingMethodName: brewingMethodName,
      isSuccess: true,
    );
  }

  /// Factory constructor for error result
  factory RecipeLoadResult.error(String errorMessage) {
    return RecipeLoadResult(
      errorMessage: errorMessage,
      isSuccess: false,
    );
  }
}

/// Service responsible for loading recipe details with retry logic and controller initialization
class RecipeLoadingService {
  /// Maximum number of retry attempts for recipe loading
  static const int _maxAttempts = 5;

  /// Backoff duration between retry attempts
  static const Duration _backoffDuration = Duration(milliseconds: 120);

  /// Loads recipe details with retry logic and fetches brewing method name
  ///
  /// This method handles:
  /// - Recipe loading with retry mechanism (up to 5 attempts with backoff)
  /// - Brewing method name resolution
  /// - Error handling and debug logging
  ///
  /// Returns a [RecipeLoadResult] containing the loaded recipe, brewing method name,
  /// or error information if the operation fails.
  static Future<RecipeLoadResult> loadRecipeWithRetry(
    BuildContext context,
    String recipeIdToLoad,
  ) async {
    try {
      final recipeProvider =
          Provider.of<RecipeProvider>(context, listen: false);
      final l10n = AppLocalizations.of(context)!;

      // Retry loop to tolerate momentary visibility lag after import/transactions
      RecipeModel? recipeModel;
      for (int attempt = 1; attempt <= _maxAttempts; attempt++) {
        recipeModel = await recipeProvider.getRecipeById(recipeIdToLoad);
        if (recipeModel != null) {
          break;
        }

        // Debug diagnostics to help identify timing/visibility issues
        debugPrint(
            "DEBUG: RecipeLoadingService attempt $attempt/$_maxAttempts for id=$recipeIdToLoad returned null. "
            "Retrying after ${_backoffDuration.inMilliseconds}ms");

        if (attempt < _maxAttempts) {
          await Future.delayed(_backoffDuration);
        }
      }

      if (recipeModel == null) {
        return RecipeLoadResult.error(l10n.recipeLoadErrorGeneric);
      }

      // Fetch brewing method name
      String brewingMethodName = l10n.unknownBrewingMethod;
      try {
        brewingMethodName = await recipeProvider
            .fetchBrewingMethodName(recipeModel.brewingMethodId);
      } catch (e) {
        debugPrint("DEBUG: Error fetching brewing method name: $e");
        // Continue with default name if fetching fails
      }

      return RecipeLoadResult.success(
        recipe: recipeModel,
        brewingMethodName: brewingMethodName,
      );
    } catch (e) {
      debugPrint(
          "DEBUG: Error in RecipeLoadingService.loadRecipeWithRetry: $e");
      return RecipeLoadResult.error("Error loading recipe");
    }
  }

  /// Initializes the controller with recipe data and slider positions
  ///
  /// This method handles:
  /// - Setting initial coffee and water amounts (custom or default)
  /// - Configuring slider positions for special recipes (106, 1002)
  /// - Proper state initialization for the controller
  static void initializeController(
    RecipeDetailController controller,
    RecipeModel recipe,
  ) {
    // Calculate amounts to use (custom amounts take precedence)
    final double customCoffee =
        recipe.customCoffeeAmount ?? recipe.coffeeAmount;
    final double customWater = recipe.customWaterAmount ?? recipe.waterAmount;

    // Set initial amounts in controller
    controller.setInitialAmounts(
      coffeeAmount: customCoffee,
      waterAmount: customWater,
    );

    // Set slider positions for special recipes
    controller.sweetnessSliderPosition = recipe.sweetnessSliderPosition;
    controller.strengthSliderPosition = recipe.strengthSliderPosition;
    controller.coffeeChroniclerSliderPosition =
        recipe.coffeeChroniclerSliderPosition ?? 0;
  }

  /// Loads recipe details and initializes controller in one operation
  ///
  /// This is a convenience method that combines recipe loading and controller
  /// initialization for common use cases.
  ///
  /// Returns a [RecipeLoadResult] and updates the controller if successful.
  static Future<RecipeLoadResult> loadRecipeAndInitializeController(
    BuildContext context,
    String recipeIdToLoad,
    RecipeDetailController controller,
  ) async {
    final result = await loadRecipeWithRetry(context, recipeIdToLoad);

    if (result.isSuccess && result.recipe != null) {
      initializeController(controller, result.recipe!);
    }

    return result;
  }

  /// Validates if a recipe ID is valid for loading
  static bool isValidRecipeId(String? recipeId) {
    // Use proper validation from InputValidator
    return InputValidator.isValidRecipeId(recipeId ?? '');
  }

  /// Creates a debug log entry for recipe loading operations
  static void logRecipeLoadingAttempt(
      String recipeId, int attempt, int maxAttempts) {
    debugPrint(
        "DEBUG: RecipeLoadingService - Loading recipe '$recipeId' (attempt $attempt/$maxAttempts)");
  }

  /// Creates a debug log entry for successful recipe loading
  static void logRecipeLoadingSuccess(String recipeId, String recipeName) {
    debugPrint(
        "DEBUG: RecipeLoadingService - Successfully loaded recipe '$recipeId': $recipeName");
  }

  /// Creates a debug log entry for failed recipe loading
  static void logRecipeLoadingFailure(String recipeId, String error) {
    debugPrint(
        "DEBUG: RecipeLoadingService - Failed to load recipe '$recipeId': $error");
  }
}
