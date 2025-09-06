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
      coffeeChroniclerSliderPosition:
          preferences?.coffeeChroniclerSliderPosition ?? 0,
      customCoffeeAmount: preferences?.customCoffeeAmount,
      customWaterAmount: preferences?.customWaterAmount,
      vendorId: recipeData.vendorId,
      importId: recipeData.importId, // Fetch importId
      isImported: recipeData.isImported, // Fetch isImported
      isPublic: recipeData.isPublic, // Fetch isPublic field
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
        coffeeChroniclerSliderPosition:
            preferences?.coffeeChroniclerSliderPosition ?? 0,
        customCoffeeAmount: preferences?.customCoffeeAmount,
        customWaterAmount: preferences?.customWaterAmount,
        vendorId: recipeData.vendorId,
        importId: recipeData.importId, // Fetch importId
        isImported: recipeData.isImported, // Fetch isImported
        isPublic: recipeData.isPublic, // Fetch isPublic field
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

  Future<void> deleteRecipe(String recipeId) async {
    await (delete(recipes)..where((t) => t.id.equals(recipeId))).go();
  }

  Future<DateTime?> fetchLastModified() async {
    final query = select(recipes)
      ..orderBy([
        (t) => OrderingTerm(expression: t.lastModified, mode: OrderingMode.desc)
      ])
      ..limit(1);
    final result = await query.getSingleOrNull();
    return result?.lastModified;
  }

  Future<List<Recipe>> getUserRecipes() async {
    return (select(recipes)..where((tbl) => tbl.id.like('usr-%'))).get();
  }

  Future<List<Recipe>> getImportedRecipes() async {
    return (select(recipes)
          ..where(
              (tbl) => tbl.isImported.equals(true) & tbl.importId.isNotNull()))
        .get();
  }

  // New method to find a recipe by its import ID
  Future<Recipe?> getRecipeByImportId(String importId) async {
    return (select(recipes)..where((tbl) => tbl.importId.equals(importId)))
        .getSingleOrNull();
  }

  // Get imported recipes for a specific user (used to check for initial upload)
  Future<List<Recipe>> getImportedRecipesForUserNotYetUploaded(
      String userId) async {
    return (select(recipes)
          ..where((tbl) =>
              tbl.vendorId.equals('usr-$userId') & // Belongs to the user
              tbl.isImported.equals(true))) // Is marked as imported
        .get();
  }

  // Generic update method for a recipe
  Future<int> updateRecipe(String recipeId, RecipesCompanion data) async {
    return (update(recipes)..where((tbl) => tbl.id.equals(recipeId)))
        .write(data);
  }

  // Get user recipes modified after a certain time
  // Include recipes needing moderation so they can sync their status
  Future<List<Recipe>> getUserRecipesModifiedAfter(
      DateTime? afterTime, String userId) async {
    final query = select(recipes)
      ..where((tbl) =>
          tbl.vendorId.equals('usr-$userId')); // Include all user recipes

    if (afterTime != null) {
      // Ensure comparison is done in UTC
      query.where(
          (tbl) => tbl.lastModified.isBiggerThanValue(afterTime.toUtc()));
    }

    return query.get();
  }

  // --- Methods for Moderation Flag ---

  // Set the needs_moderation_review flag to true for a specific recipe
  Future<void> setNeedsModerationReview(
      String recipeId, bool needsReview) async {
    await (update(recipes)..where((tbl) => tbl.id.equals(recipeId)))
        .write(RecipesCompanion(
      needsModerationReview: Value(needsReview),
    ));
  }

  // Get all recipes that need moderation review (only public recipes)
  Future<List<Recipe>> getRecipesNeedingModeration() async {
    return (select(recipes)
          ..where((tbl) =>
              tbl.needsModerationReview.equals(true) &
              tbl.isPublic.equals(true)))
        .get();
  }
}
