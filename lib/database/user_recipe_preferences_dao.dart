part of 'database.dart';

@DriftAccessor(tables: [UserRecipePreferences])
class UserRecipePreferencesDao extends DatabaseAccessor<AppDatabase>
    with _$UserRecipePreferencesDaoMixin {
  final AppDatabase db;

  UserRecipePreferencesDao(this.db) : super(db);

  Future<UserRecipePreference?> getPreferencesForRecipe(String recipeId) async {
    return (select(db.userRecipePreferences)
          ..where((tbl) => tbl.recipeId.equals(recipeId)))
        .getSingleOrNull();
  }

  Future<void> updatePreferences(String recipeId,
      {bool? isFavorite,
      int? sweetnessSliderPosition,
      int? strengthSliderPosition,
      double? customCoffeeAmount,
      double? customWaterAmount}) async {
    final entryExists = await (select(userRecipePreferences)
              ..where((tbl) => tbl.recipeId.equals(recipeId)))
            .getSingleOrNull() !=
        null;

    final preferencesCompanion = UserRecipePreferencesCompanion(
      recipeId: Value(recipeId),
      isFavorite:
          Value(isFavorite ?? false), // Default to false if not provided
      lastUsed: Value(DateTime.now()), // Always set to current date and time
      sweetnessSliderPosition: sweetnessSliderPosition == null
          ? Value.absent()
          : Value(sweetnessSliderPosition),
      strengthSliderPosition: strengthSliderPosition == null
          ? Value.absent()
          : Value(strengthSliderPosition),
      customCoffeeAmount: customCoffeeAmount == null
          ? Value.absent()
          : Value(customCoffeeAmount),
      customWaterAmount:
          customWaterAmount == null ? Value.absent() : Value(customWaterAmount),
    );

    if (!entryExists) {
      await into(userRecipePreferences).insert(preferencesCompanion);
    } else {
      await (update(userRecipePreferences)
            ..where((tbl) => tbl.recipeId.equals(recipeId)))
          .write(preferencesCompanion);
    }
  }

  Future<UserRecipePreference?> getLastUsedRecipe() async {
    return (select(userRecipePreferences)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.lastUsed)])
          ..limit(1))
        .getSingleOrNull();
  }

  // Additional method to fetch preferences for displaying or editing in the UI
  Future<Map<String, dynamic>> getRecipePreferences(String recipeId) async {
    final prefs = await getPreferencesForRecipe(recipeId);
    return {
      "isFavorite": prefs?.isFavorite,
      "lastUsed": prefs?.lastUsed,
      "sweetnessSliderPosition": prefs?.sweetnessSliderPosition,
      "strengthSliderPosition": prefs?.strengthSliderPosition,
      "customCoffeeAmount": prefs?.customCoffeeAmount,
      "customWaterAmount": prefs?.customWaterAmount,
    };
  }

  Future<List<UserRecipePreference>> getFavoritePreferences() async {
    return (select(userRecipePreferences)
          ..where((tbl) => tbl.isFavorite.equals(true)))
        .get();
  }
}
