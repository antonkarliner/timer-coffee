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

  Future<List<RecipeModel>> getAllRecipes(String locale) async {
    final recipeDatas = await select(recipes).get();
    return await _getRecipeModelsFromQuery(recipeDatas, locale);
  }

  Future<List<RecipeModel>> fetchRecipesForBrewingMethod(
      String brewingMethodId, String locale) async {
    final recipeDatas = await (select(recipes)
          ..where((tbl) => tbl.brewingMethodId.equals(brewingMethodId)))
        .get();
    return await _getRecipeModelsFromQuery(recipeDatas, locale);
  }

  Future<List<RecipeModel>> _getRecipeModelsFromQuery(
      List<Recipe> queryResult, String locale) async {
    List<RecipeModel> recipeModels = [];
    for (final recipeData in queryResult) {
      final localizationData = await db.recipeLocalizationsDao
          .getLocalizationForRecipe(recipeData.id, locale);
      final List<BrewStepModel> steps = await db.stepsDao
          .getLocalizedBrewStepsForRecipe(recipeData.id, locale);
      final preferences = await db.userRecipePreferencesDao
          .getPreferencesForRecipe(recipeData.id);

      recipeModels.add(RecipeModel(
        id: recipeData.id,
        name: localizationData?.name ?? recipeData.id,
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

  Future<Map<String, DateTime>> fetchIdsAndLastModifiedDates() async {
    final queryResult = await select(recipes).map((row) {
      return MapEntry(row.id, row.lastModified ?? DateTime(0));
    }).get();
    return Map.fromEntries(queryResult);
  }

  Future<void> insertOrUpdateRecipe(RecipesCompanion recipe) async {
    await into(recipes).insertOnConflictUpdate(recipe);
  }

  Future<DateTime?> fetchLastModified() async {
    final query = select(recipes)
      ..orderBy([(t) => OrderingTerm(expression: t.lastModified, mode: OrderingMode.desc)])
      ..limit(1);
    final result = await query.getSingleOrNull();
    return result?.lastModified;
  }
}
