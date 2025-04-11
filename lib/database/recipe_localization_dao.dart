part of 'database.dart';

@DriftAccessor(tables: [RecipeLocalizations])
class RecipeLocalizationsDao extends DatabaseAccessor<AppDatabase>
    with _$RecipeLocalizationsDaoMixin {
  final AppDatabase db;
  RecipeLocalizationsDao(this.db) : super(db);

  Future<RecipeLocalization?> getLocalizationForRecipe(
      String recipeId, String locale) async {
    late final Selectable<RecipeLocalization> query;

    if (recipeId.startsWith('usr-')) {
      // For user recipes, ignore the locale and fetch the first available localization
      query = select(db.recipeLocalizations)
        ..where((tbl) => tbl.recipeId.equals(recipeId));
    } else {
      // For standard recipes, fetch based on recipeId and locale
      query = select(db.recipeLocalizations)
        ..where(
            (tbl) => tbl.recipeId.equals(recipeId) & tbl.locale.equals(locale));
    }

    final results = await query.get();

    // Return the first result if available, otherwise null
    return results.isEmpty ? null : results.first;
  }

  Future<void> insertOrUpdateLocalization(
      RecipeLocalizationsCompanion localization) async {
    await into(recipeLocalizations).insertOnConflictUpdate(localization);
  }

  Future<void> deleteLocalization(String recipeId, String locale) async {
    await (delete(recipeLocalizations)
          ..where((tbl) =>
              tbl.recipeId.equals(recipeId) & tbl.locale.equals(locale)))
        .go();
  }

  Future<void> deleteLocalizationsForRecipe(String recipeId) async {
    await (delete(recipeLocalizations)
          ..where((tbl) => tbl.recipeId.equals(recipeId)))
        .go();
  }

  Future<List<RecipeLocalization>> getLocalizationsForRecipe(
      String recipeId) async {
    final query = select(db.recipeLocalizations)
      ..where((tbl) => tbl.recipeId.equals(recipeId));
    return query.get();
  }
}
