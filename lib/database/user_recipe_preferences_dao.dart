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
    // Check if the entry exists.
    final existingPreference = await (select(userRecipePreferences)
          ..where((tbl) => tbl.recipeId.equals(recipeId)))
        .getSingleOrNull();

    UserRecipePreferencesCompanion preferencesCompanion;

    if (existingPreference == null) {
      // If creating a new entry, default isFavorite to false if not provided.
      preferencesCompanion = UserRecipePreferencesCompanion(
        recipeId: Value(recipeId),
        isFavorite: Value(isFavorite ?? false),
        lastUsed: Value(DateTime.now()),
        sweetnessSliderPosition: sweetnessSliderPosition == null
            ? Value.absent()
            : Value(sweetnessSliderPosition),
        strengthSliderPosition: strengthSliderPosition == null
            ? Value.absent()
            : Value(strengthSliderPosition),
        customCoffeeAmount: customCoffeeAmount == null
            ? Value.absent()
            : Value(customCoffeeAmount),
        customWaterAmount: customWaterAmount == null
            ? Value.absent()
            : Value(customWaterAmount),
      );
      await into(userRecipePreferences).insert(preferencesCompanion);
    } else {
      // If updating an existing entry, only include isFavorite if explicitly provided.
      preferencesCompanion = UserRecipePreferencesCompanion(
        lastUsed: Value(DateTime.now()),
        sweetnessSliderPosition: sweetnessSliderPosition == null
            ? Value.absent()
            : Value(sweetnessSliderPosition),
        strengthSliderPosition: strengthSliderPosition == null
            ? Value.absent()
            : Value(strengthSliderPosition),
        customCoffeeAmount: customCoffeeAmount == null
            ? Value.absent()
            : Value(customCoffeeAmount),
        customWaterAmount: customWaterAmount == null
            ? Value.absent()
            : Value(customWaterAmount),
      );

      if (isFavorite != null) {
        preferencesCompanion =
            preferencesCompanion.copyWith(isFavorite: Value(isFavorite));
      }

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

  Future<void> insertOrUpdateMultiplePreferences(
      List<UserRecipePreferencesCompanion> preferences) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(userRecipePreferences, preferences);
    });
  }

// Also add this method to fetch all preferences
  Future<List<UserRecipePreference>> getAllPreferences() {
    return select(userRecipePreferences).get();
  }
}
