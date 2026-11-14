// Tests for the journey card's "try another recipe" suggestion rule
// (plan 065 Phase 4). Pure selection logic — no database involved.

import 'package:coffee_timer/models/brew_step_model.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/utils/journey_recipe_suggestion.dart';
import 'package:flutter_test/flutter_test.dart';

RecipeModel _recipe(String id, String methodId) => RecipeModel(
  id: id,
  name: 'Recipe $id',
  brewingMethodId: methodId,
  coffeeAmount: 15,
  waterAmount: 250,
  grindSize: 'Medium',
  brewTime: const Duration(minutes: 3),
  shortDescription: '',
  steps: const <BrewStepModel>[],
);

({String recipeId, String brewingMethodId}) _brew(
  String recipeId,
  String methodId,
) => (recipeId: recipeId, brewingMethodId: methodId);

void main() {
  test('zero brews suggest nothing', () async {
    final suggestion = await suggestJourneyRecipe(
      [],
      (_) async => [_recipe('other', 'v60')],
    );
    expect(suggestion, isNull);
  });

  test('one brew is too early — suggest nothing', () async {
    final suggestion = await suggestJourneyRecipe(
      [_brew('recipe-1', 'v60')],
      (_) async => [_recipe('other', 'v60')],
    );
    expect(suggestion, isNull);
  });

  test('two brews on one recipe suggest the first other recipe of the method',
      () async {
    final catalog = {
      'v60': [_recipe('recipe-1', 'v60'), _recipe('recipe-2', 'v60')],
    };
    final suggestion = await suggestJourneyRecipe(
      [_brew('recipe-1', 'v60'), _brew('recipe-1', 'v60')],
      (methodId) async => catalog[methodId] ?? [],
    );
    expect(suggestion?.id, 'recipe-2');
  });

  test('two brews on two recipes suggest nothing — milestone already done',
      () async {
    final suggestion = await suggestJourneyRecipe(
      [_brew('recipe-1', 'v60'), _brew('recipe-2', 'v60')],
      (_) async => [_recipe('other', 'v60')],
    );
    expect(suggestion, isNull);
  });

  test('a method with only the brewed recipe suggests nothing', () async {
    final suggestion = await suggestJourneyRecipe(
      [_brew('recipe-1', 'v60'), _brew('recipe-1', 'v60')],
      (_) async => [_recipe('recipe-1', 'v60')],
    );
    expect(suggestion, isNull);
  });

  test('when the brewed recipe is first in the list, the second is returned',
      () async {
    final suggestion = await suggestJourneyRecipe(
      [_brew('recipe-a', 'v60'), _brew('recipe-a', 'v60')],
      (_) async => [_recipe('recipe-a', 'v60'), _recipe('recipe-b', 'v60')],
    );
    expect(suggestion?.id, 'recipe-b');
  });

  test('three brews on one recipe behave like two', () async {
    final suggestion = await suggestJourneyRecipe(
      [
        _brew('recipe-1', 'v60'),
        _brew('recipe-1', 'v60'),
        _brew('recipe-1', 'v60'),
      ],
      (_) async => [_recipe('recipe-1', 'v60'), _recipe('recipe-3', 'v60')],
    );
    expect(suggestion?.id, 'recipe-3');
  });
}
