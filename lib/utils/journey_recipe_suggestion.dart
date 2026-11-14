// Picks the recipe the journey card's "try another recipe" milestone
// suggests.
//
// Kept as a pure, DB-free function so the selection rule can be unit-tested
// without a database; callers supply the brew history and the per-method
// recipe lookup.

import '../models/recipe_model.dart';

/// Suggests a recipe for the journey card's "try another recipe" milestone,
/// or null when there is nothing honest to suggest.
///
/// [brews] is the user's brew history as (recipeId, brewingMethodId) pairs,
/// newest first (as `UserStatsDao.fetchAllStats` returns). Mirrors the
/// recipe-exploration notification
/// (`LocalNotificationSchedulerService._scheduleRecipeExplorationNudge`) so
/// the card and the notification never point at different recipes: the most
/// brews' brewing method wins (ties keep first-seen order), and within a
/// method the first recipe from [fetchRecipesForMethod] that the user has
/// not brewed is suggested.
///
/// Rules:
/// - Fewer than two brews → null. One brew is too early — the morning-after
///   reminder owns that moment.
/// - Brews span more than one recipe → null; the milestone is already done.
/// - Otherwise the first recipe of the (ranked) method's list that differs
///   from the single brewed recipe, or null when the method list holds no
///   other recipe.
Future<RecipeModel?> suggestJourneyRecipe(
  List<({String recipeId, String brewingMethodId})> brews,
  Future<List<RecipeModel>> Function(String methodId) fetchRecipesForMethod,
) async {
  if (brews.length < 2) return null;

  final brewedRecipeIds = brews.map((brew) => brew.recipeId).toSet();
  if (brewedRecipeIds.length != 1) return null;
  final brewedRecipeId = brews.first.recipeId;

  // Comfort zone first — same method ranking as the exploration nudge.
  final methodBrewCounts = <String, int>{};
  for (final brew in brews) {
    methodBrewCounts[brew.brewingMethodId] =
        (methodBrewCounts[brew.brewingMethodId] ?? 0) + 1;
  }
  final rankedMethods = methodBrewCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  for (final method in rankedMethods) {
    final recipes = await fetchRecipesForMethod(method.key);
    for (final recipe in recipes) {
      if (recipe.id != brewedRecipeId) return recipe;
    }
  }
  return null;
}
