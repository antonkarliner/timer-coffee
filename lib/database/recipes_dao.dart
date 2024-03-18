part of 'database.dart';

@DriftAccessor(
    tables: [Recipes, RecipeLocalizations, Steps, UserRecipePreferences])
class RecipesDao extends DatabaseAccessor<AppDatabase> with _$RecipesDaoMixin {
  final AppDatabase db;

  RecipesDao(this.db) : super(db);

  Future<RecipeModel?> getRecipeModelById(
      String recipeId, String locale) async {
    final recipeData = await (select(recipes)
          ..where((tbl) => tbl.id.equals(recipeId)))
        .getSingleOrNull();
    if (recipeData == null) return null;

    final localizationData = await db.recipeLocalizationsDao
        .getLocalizationForRecipe(recipeId, locale);
    final List<BrewStepModel> steps =
        await db.stepsDao.getLocalizedBrewStepsForRecipe(recipeId, locale);
    final preferences =
        await db.userRecipePreferencesDao.getPreferencesForRecipe(recipeId);

    return RecipeModel(
      id: recipeId,
      name: localizationData?.name ?? '',
      brewingMethodId: recipeData.brewingMethodId,
      coffeeAmount: recipeData.coffeeAmount,
      waterAmount: recipeData.waterAmount,
      waterTemp: recipeData.waterTemp,
      grindSize: localizationData?.grindSize ?? '',
      brewTime: Duration(seconds: recipeData.brewTime),
      shortDescription: localizationData?.shortDescription ?? '',
      steps: steps,
      lastUsed: preferences?.lastUsed,
      isFavorite: preferences?.isFavorite ?? false,
      sweetnessSliderPosition: preferences?.sweetnessSliderPosition ?? 1,
      strengthSliderPosition: preferences?.strengthSliderPosition ?? 2,
      customCoffeeAmount: preferences?.customCoffeeAmount,
      customWaterAmount: preferences?.customWaterAmount,
      vendorId: recipeData.vendorId,
    );
  }

  // New method to fetch all recipes for a given locale
  Future<List<RecipeModel>> getAllRecipes(String locale) async {
    final recipeDatas = await select(recipes).get();
    List<RecipeModel> recipeModels = [];

    for (final recipeData in recipeDatas) {
      final localizationData = await db.recipeLocalizationsDao
          .getLocalizationForRecipe(recipeData.id, locale);
      final List<BrewStepModel> steps = await db.stepsDao
          .getLocalizedBrewStepsForRecipe(recipeData.id, locale);
      final preferences = await db.userRecipePreferencesDao
          .getPreferencesForRecipe(recipeData.id);

      recipeModels.add(RecipeModel(
        id: recipeData.id,
        name: localizationData?.name ??
            recipeData.id, // Fallback to ID if name is not available
        brewingMethodId: recipeData.brewingMethodId,
        coffeeAmount: recipeData.coffeeAmount,
        waterAmount: recipeData.waterAmount,
        waterTemp: recipeData.waterTemp,
        grindSize: localizationData?.grindSize ?? '',
        brewTime: Duration(seconds: recipeData.brewTime),
        shortDescription: localizationData?.shortDescription ?? '',
        steps: steps,
        lastUsed: preferences?.lastUsed,
        isFavorite: preferences?.isFavorite ?? false,
        sweetnessSliderPosition: preferences?.sweetnessSliderPosition ?? 1,
        strengthSliderPosition: preferences?.strengthSliderPosition ?? 2,
        customCoffeeAmount: preferences?.customCoffeeAmount,
        customWaterAmount: preferences?.customWaterAmount,
        vendorId: recipeData.vendorId,
      ));
    }

    return recipeModels;
  }
}
