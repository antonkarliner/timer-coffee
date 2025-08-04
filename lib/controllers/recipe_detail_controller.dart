import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Controller for Recipe Detail feature responsible for:
/// - Amounts and ratio logic (coffee/water, editing focus, initialRatio)
/// - Slider state for special recipe IDs (106 sweetness/strength, 1002 chronicler size)
/// - Bean selection state (uuid/name/logo URLs), with imperative load/update hooks
///
/// This controller is UI-agnostic and exposes ChangeNotifier for the view to subscribe.
/// Business logic that requires Providers/Supabase should be delegated from the screen
/// for Phase 2, and later moved into services in Phase 3+.
class RecipeDetailController extends ChangeNotifier {
  // --- Amounts / Ratio ---
  final TextEditingController coffeeController = TextEditingController();
  final TextEditingController waterController = TextEditingController();

  double initialRatio = 16.0; // default ratio
  bool editingCoffee = false;
  double? originalCoffee;
  double? originalWater;

  // --- Sliders (special IDs) ---
  int sweetnessSliderPosition = 1; // for id 106
  int strengthSliderPosition = 2; // for id 106
  int coffeeChroniclerSliderPosition = 0; // for id 1002

  // --- Bean selection state ---
  String? selectedBeanUuid;
  String? selectedBeanName;
  String? originalRoasterLogoUrl;
  String? mirrorRoasterLogoUrl;

  // --- Lifecycle / disposal ---
  @override
  void dispose() {
    coffeeController.dispose();
    waterController.dispose();
    super.dispose();
  }

  // --- Initialize amounts for a loaded recipe ---
  void setInitialAmounts({
    required double coffeeAmount,
    required double waterAmount,
  }) {
    originalCoffee = coffeeAmount;
    originalWater = waterAmount;

    // Ensure amounts are positive before calculating ratio
    if (coffeeAmount > 0) {
      initialRatio = waterAmount / coffeeAmount;
    } else {
      initialRatio = 16.0; // Default if invalid
    }

    coffeeController.text = coffeeAmount.toString();
    waterController.text = waterAmount.toString();
    notifyListeners();
  }

  // Method to handle amount updates and potentially slider updates for recipe 1002
  void updateAmounts(String effectiveRecipeId) {
    final coffeeText = coffeeController.text;
    final waterText = waterController.text;

    if (coffeeText.isEmpty ||
        waterText.isEmpty ||
        double.tryParse(coffeeText.replaceAll(',', '.')) == null ||
        double.tryParse(waterText.replaceAll(',', '.')) == null) {
      return;
    }

    double newCoffee = double.parse(coffeeText.replaceAll(',', '.'));
    double newWater = double.parse(waterText.replaceAll(',', '.'));

    // Ensure initialRatio is valid before using it
    if (initialRatio <= 0) {
      if (originalCoffee != null &&
          (originalCoffee ?? 0) > 0 &&
          originalWater != null) {
        initialRatio = (originalWater ?? 0) / (originalCoffee ?? 1);
      } else {
        initialRatio = 16.0; // Fallback default
      }
    }

    if (editingCoffee) {
      final newWaterAmount = newCoffee * initialRatio;
      waterController.text = newWaterAmount.toStringAsFixed(1);
      newWater = newWaterAmount;
    } else {
      final newCoffeeAmount = newWater / initialRatio;
      coffeeController.text = newCoffeeAmount.toStringAsFixed(1);
      newCoffee = newCoffeeAmount;
    }

    // For recipe id 1002, update slider position based on amounts
    if (effectiveRecipeId == '1002') {
      int newSliderPosition = coffeeChroniclerSliderPosition;

      if (newCoffee <= 26 || newWater <= 416) {
        newSliderPosition = 0; // Standard
      } else if ((newCoffee > 26 && newCoffee < 37) ||
          (newWater > 416 && newWater < 592)) {
        newSliderPosition = 1; // Medium
      } else if (newCoffee >= 37 || newWater >= 592) {
        newSliderPosition = 2; // XL
      }

      if (newSliderPosition != coffeeChroniclerSliderPosition) {
        coffeeChroniclerSliderPosition = newSliderPosition;
      }
    }
    notifyListeners();
  }

  void setEditingCoffee(bool value) {
    editingCoffee = value;
    // No notify to avoid rebuilds on focus only
  }

  // --- Slider wiring for id 106 ---
  void setSweetnessPosition(int v) {
    sweetnessSliderPosition = v;
    notifyListeners();
  }

  void setStrengthPosition(int v) {
    strengthSliderPosition = v;
    notifyListeners();
  }

  // --- Slider wiring for id 1002 (Coffee Chronicler) ---
  /// Updates the chronicler size and returns mapped coffee/water amounts if the caller wants to apply them.
  /// Returns null if no mapping should be applied (keeps current values).
  Map<String, double>? setChroniclerPositionAndMapAmounts(int v) {
    coffeeChroniclerSliderPosition = v;
    // Return mapping; caller decides whether to apply based on current recipe ID.
    switch (v) {
      case 0:
        return {'coffee': 20, 'water': 320};
      case 1:
        return {'coffee': 30, 'water': 480};
      case 2:
        return {'coffee': 45, 'water': 720};
      default:
        return null;
    }
  }

  void applyAmounts(double coffee, double water) {
    coffeeController.text = coffee.toString();
    waterController.text = water.toString();
    initialRatio = water / coffee;
    notifyListeners();
  }

  // --- Bean selection state updates ---
  void setBeanSelection({
    required String? uuid,
    required String? name,
    required String? originalUrl,
    required String? mirrorUrl,
  }) {
    selectedBeanUuid = uuid;
    selectedBeanName = name;
    originalRoasterLogoUrl = originalUrl;
    mirrorRoasterLogoUrl = mirrorUrl;
    notifyListeners();
  }

  void clearBeanSelection() {
    selectedBeanUuid = null;
    selectedBeanName = null;
    originalRoasterLogoUrl = null;
    mirrorRoasterLogoUrl = null;
    notifyListeners();
  }
}
