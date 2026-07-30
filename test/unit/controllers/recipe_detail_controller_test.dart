import 'package:flutter_test/flutter_test.dart';
import 'package:coffee_timer/controllers/recipe_detail_controller.dart';

void main() {
  late RecipeDetailController controller;

  setUp(() {
    controller = RecipeDetailController();
  });

  tearDown(() {
    controller.dispose();
  });

  group('initial state', () {
    test('default ratio is 16.0', () {
      expect(controller.initialRatio, 16.0);
    });

    test('no bean selected initially', () {
      expect(controller.selectedBeanUuid, isNull);
      expect(controller.selectedBeanName, isNull);
      expect(controller.originalRoasterLogoUrl, isNull);
      expect(controller.mirrorRoasterLogoUrl, isNull);
    });

    test('default slider positions', () {
      expect(controller.sweetnessSliderPosition, 1);
      expect(controller.strengthSliderPosition, 2);
      expect(controller.coffeeChroniclerSliderPosition, 0);
    });

    test('editingCoffee defaults to false', () {
      expect(controller.editingCoffee, isFalse);
    });
  });

  group('water temperature provenance', () {
    test('initial effective temperature is recipe-derived', () {
      controller.setInitialWaterTemperature(93);

      expect(controller.waterTemperature, 93);
      expect(controller.waterTemperatureFromRecipe, isTrue);
    });

    test('editing temperature marks it as a manual override', () {
      controller.setInitialWaterTemperature(93);
      controller.markWaterTemperatureManuallyEdited(91.5);

      expect(controller.waterTemperature, 91.5);
      expect(controller.waterTemperatureFromRecipe, isFalse);
    });

    test(
      'emptying temperature clears the field but effective value falls back '
      'to the loaded value',
      () {
        controller.setInitialWaterTemperature(93);
        controller.markWaterTemperatureManuallyEdited(91);
        controller.markWaterTemperatureManuallyEdited(null);

        expect(controller.waterTemperature, isNull);
        expect(controller.waterTemperatureFromRecipe, isTrue);
        expect(controller.effectiveWaterTemperature, 93);
      },
    );

    test('emptying genuinely null temperature does not invent a default', () {
      controller.setInitialWaterTemperature(null);
      controller.markWaterTemperatureManuallyEdited(91);
      controller.markWaterTemperatureManuallyEdited(null);

      expect(controller.waterTemperature, isNull);
      expect(controller.waterTemperatureFromRecipe, isTrue);
      expect(controller.effectiveWaterTemperature, isNull);
    });
  });

  group('applyBrewAgainPrefill', () {
    test('applies brew values as manual overrides', () {
      controller.grindSizeFromBean = true;
      controller.setInitialWaterTemperature(93);

      controller.applyBrewAgainPrefill(
        coffeeAmount: 18.5,
        waterAmount: 300,
        grindSize: '24 clicks',
        waterTemp: 91.5,
      );

      expect(controller.coffeeController.text, '18.5');
      expect(controller.waterController.text, '300.0');
      expect(controller.grindSizeController.text, '24 clicks');
      expect(controller.grindSizeFromBean, isFalse);
      expect(controller.waterTemperature, 91.5);
      expect(controller.waterTemperatureFromRecipe, isFalse);
    });
  });

  group('setInitialAmounts', () {
    test('sets controller text for coffee and water', () {
      controller.setInitialAmounts(coffeeAmount: 25.0, waterAmount: 400.0);
      expect(controller.coffeeController.text, '25.0');
      expect(controller.waterController.text, '400.0');
    });

    test('computes correct ratio', () {
      controller.setInitialAmounts(coffeeAmount: 20.0, waterAmount: 320.0);
      expect(controller.initialRatio, closeTo(16.0, 0.001));
    });

    test('stores original coffee and water values', () {
      controller.setInitialAmounts(coffeeAmount: 20.0, waterAmount: 320.0);
      expect(controller.originalCoffee, 20.0);
      expect(controller.originalWater, 320.0);
    });

    test('uses default ratio when coffeeAmount is 0', () {
      controller.setInitialAmounts(coffeeAmount: 0.0, waterAmount: 400.0);
      expect(controller.initialRatio, 16.0);
    });

    test('notifies listeners', () {
      bool notified = false;
      controller.addListener(() => notified = true);
      controller.setInitialAmounts(coffeeAmount: 20.0, waterAmount: 320.0);
      expect(notified, isTrue);
    });
  });

  group('updateAmounts - editing coffee (maintains ratio)', () {
    setUp(() {
      controller.setInitialAmounts(coffeeAmount: 20.0, waterAmount: 320.0);
      controller.editingCoffee = true;
    });

    test('changing coffee updates water proportionally', () {
      controller.coffeeController.text = '25';
      controller.updateAmounts('other-recipe');
      final water = double.parse(controller.waterController.text);
      expect(water, closeTo(400.0, 0.1));
    });

    test('halving coffee halves water', () {
      controller.coffeeController.text = '10';
      controller.updateAmounts('other-recipe');
      final water = double.parse(controller.waterController.text);
      expect(water, closeTo(160.0, 0.1));
    });
  });

  group('updateAmounts - editing water (maintains ratio)', () {
    setUp(() {
      controller.setInitialAmounts(coffeeAmount: 20.0, waterAmount: 320.0);
      controller.editingCoffee = false;
    });

    test('changing water updates coffee proportionally', () {
      controller.waterController.text = '400';
      controller.updateAmounts('other-recipe');
      final coffee = double.parse(controller.coffeeController.text);
      expect(coffee, closeTo(25.0, 0.1));
    });
  });

  group('updateAmounts - invalid input is ignored', () {
    setUp(() {
      controller.setInitialAmounts(coffeeAmount: 20.0, waterAmount: 320.0);
    });

    test('does not crash on empty coffee text', () {
      controller.editingCoffee = true;
      controller.coffeeController.text = '';
      expect(() => controller.updateAmounts('other-recipe'), returnsNormally);
    });

    test('does not crash on non-numeric coffee text', () {
      controller.editingCoffee = true;
      controller.coffeeController.text = 'abc';
      expect(() => controller.updateAmounts('other-recipe'), returnsNormally);
    });
  });

  group('chronicler slider mapping (setChroniclerPositionAndMapAmounts)', () {
    test('position 0 → 20g coffee / 320ml water', () {
      final result = controller.setChroniclerPositionAndMapAmounts(0);
      expect(result, {'coffee': 20.0, 'water': 320.0});
    });

    test('position 1 → 30g coffee / 480ml water', () {
      final result = controller.setChroniclerPositionAndMapAmounts(1);
      expect(result, {'coffee': 30.0, 'water': 480.0});
    });

    test('position 2 → 45g coffee / 720ml water', () {
      final result = controller.setChroniclerPositionAndMapAmounts(2);
      expect(result, {'coffee': 45.0, 'water': 720.0});
    });

    test('invalid position returns null', () {
      final result = controller.setChroniclerPositionAndMapAmounts(5);
      expect(result, isNull);
    });

    test('updates coffeeChroniclerSliderPosition', () {
      controller.setChroniclerPositionAndMapAmounts(2);
      expect(controller.coffeeChroniclerSliderPosition, 2);
    });
  });

  group('updateAmounts - recipe 1002 syncs chronicler slider', () {
    setUp(() {
      controller.setInitialAmounts(coffeeAmount: 20.0, waterAmount: 320.0);
    });

    test('coffee ≥ 37 maps slider to position 2 (XL)', () {
      controller.editingCoffee = true;
      controller.coffeeController.text = '45';
      controller.updateAmounts('1002');
      expect(controller.coffeeChroniclerSliderPosition, 2);
    });

    test('coffee ≤ 26 maps slider to position 0 (Standard)', () {
      controller.coffeeChroniclerSliderPosition = 2;
      controller.editingCoffee = true;
      controller.coffeeController.text = '20';
      controller.updateAmounts('1002');
      expect(controller.coffeeChroniclerSliderPosition, 0);
    });

    test('coffee between 26 and 37 maps to position 1 (Medium)', () {
      controller.editingCoffee = true;
      controller.coffeeController.text = '30';
      controller.updateAmounts('1002');
      expect(controller.coffeeChroniclerSliderPosition, 1);
    });

    test('non-1002 recipe does not change chronicler slider', () {
      controller.editingCoffee = true;
      controller.coffeeController.text = '45';
      controller.updateAmounts('other-recipe');
      expect(controller.coffeeChroniclerSliderPosition, 0);
    });
  });

  group('bean selection', () {
    test('setBeanSelection stores all four fields', () {
      controller.setBeanSelection(
        uuid: 'uuid-123',
        name: 'Ethiopian Yirgacheffe',
        originalUrl: 'https://example.com/logo.png',
        mirrorUrl: 'https://mirror.com/logo.png',
      );
      expect(controller.selectedBeanUuid, 'uuid-123');
      expect(controller.selectedBeanName, 'Ethiopian Yirgacheffe');
      expect(controller.originalRoasterLogoUrl, 'https://example.com/logo.png');
      expect(controller.mirrorRoasterLogoUrl, 'https://mirror.com/logo.png');
    });

    test('clearBeanSelection nulls all fields', () {
      controller.setBeanSelection(
        uuid: 'uuid-123',
        name: 'Test Bean',
        originalUrl: 'https://example.com/logo.png',
        mirrorUrl: null,
      );
      controller.clearBeanSelection();
      expect(controller.selectedBeanUuid, isNull);
      expect(controller.selectedBeanName, isNull);
      expect(controller.originalRoasterLogoUrl, isNull);
      expect(controller.mirrorRoasterLogoUrl, isNull);
    });

    test('setBeanSelection triggers notifyListeners', () {
      bool notified = false;
      controller.addListener(() => notified = true);
      controller.setBeanSelection(
        uuid: 'u',
        name: 'n',
        originalUrl: null,
        mirrorUrl: null,
      );
      expect(notified, isTrue);
    });

    test('clearBeanSelection triggers notifyListeners', () {
      bool notified = false;
      controller.addListener(() => notified = true);
      controller.clearBeanSelection();
      expect(notified, isTrue);
    });
  });

  group('slider positions (id 106)', () {
    test('setSweetnessPosition updates value and notifies', () {
      bool notified = false;
      controller.addListener(() => notified = true);
      controller.setSweetnessPosition(3);
      expect(controller.sweetnessSliderPosition, 3);
      expect(notified, isTrue);
    });

    test('setStrengthPosition updates value and notifies', () {
      bool notified = false;
      controller.addListener(() => notified = true);
      controller.setStrengthPosition(0);
      expect(controller.strengthSliderPosition, 0);
      expect(notified, isTrue);
    });
  });

  group('applyAmounts', () {
    test('sets controller text for both fields', () {
      controller.applyAmounts(30.0, 480.0);
      expect(controller.coffeeController.text, '30.0');
      expect(controller.waterController.text, '480.0');
    });

    test('updates initialRatio', () {
      controller.applyAmounts(30.0, 480.0);
      expect(controller.initialRatio, closeTo(16.0, 0.001));
    });

    test('notifies listeners', () {
      bool notified = false;
      controller.addListener(() => notified = true);
      controller.applyAmounts(20.0, 320.0);
      expect(notified, isTrue);
    });
  });

  group('currentCoffeeAmount / currentWaterAmount', () {
    test('parses controller text', () {
      controller.coffeeController.text = '20.5';
      expect(controller.currentCoffeeAmount, 20.5);
    });

    test('falls back to originalCoffee on empty text', () {
      controller.setInitialAmounts(coffeeAmount: 22.0, waterAmount: 352.0);
      controller.coffeeController.text = '';
      expect(controller.currentCoffeeAmount, 22.0);
    });

    test('falls back to originalWater on empty text', () {
      controller.setInitialAmounts(coffeeAmount: 22.0, waterAmount: 352.0);
      controller.waterController.text = '';
      expect(controller.currentWaterAmount, 352.0);
    });

    test('handles comma decimal separator', () {
      controller.coffeeController.text = '20,5';
      expect(controller.currentCoffeeAmount, 20.5);
    });

    test('falls back to 0 when text is invalid and no original set', () {
      controller.coffeeController.text = 'not-a-number';
      expect(controller.currentCoffeeAmount, 0.0);
    });
  });

  group('grind suggestion', () {
    test(
      'shows only when suggestion differs from field (case-insensitive)',
      () {
        controller.grindSizeController.text = 'Fine ';
        controller.setGrindSuggestion('fine', null);
        expect(controller.shouldShowGrindSuggestion, isFalse);

        controller.setGrindSuggestion('Medium fine', null);
        expect(controller.shouldShowGrindSuggestion, isTrue);
      },
    );

    test('apply uses stored value as-is when taste is neutral', () {
      controller.setGrindSuggestion('24', 0);
      controller.applyGrindSuggestion();
      expect(controller.grindSizeController.text, '24');
    });

    test('apply adjusts integer grind finer on sour', () {
      controller.setGrindSuggestion('24', -1);
      controller.applyGrindSuggestion();
      expect(controller.grindSizeController.text, '23');
    });

    test('apply adjusts integer grind coarser on bitter', () {
      controller.setGrindSuggestion('24', 1);
      controller.applyGrindSuggestion();
      expect(controller.grindSizeController.text, '25');
    });

    test('apply keeps non-numeric grind as-is even when directional', () {
      controller.setGrindSuggestion('medium-fine', 1);
      controller.applyGrindSuggestion();
      expect(controller.grindSizeController.text, 'medium-fine');
    });

    test('apply keeps decimal grind as-is (integer gate)', () {
      controller.setGrindSuggestion('2.4', -1);
      controller.applyGrindSuggestion();
      expect(controller.grindSizeController.text, '2.4');
    });

    test('apply keeps integers below 2 as-is', () {
      controller.setGrindSuggestion('1', 1);
      controller.applyGrindSuggestion();
      expect(controller.grindSizeController.text, '1');
    });

    test('apply clears the suggestion (chip dismissed)', () {
      controller.setGrindSuggestion('24', -1);
      controller.applyGrindSuggestion();
      expect(controller.shouldShowGrindSuggestion, isFalse);
      expect(controller.suggestedGrindSize, isNull);
    });

    test('manual grind edit clears the suggestion', () {
      controller.setGrindSuggestion('24', null);
      controller.markGrindSizeManuallyEdited();
      expect(controller.suggestedGrindSize, isNull);
    });
  });
}
