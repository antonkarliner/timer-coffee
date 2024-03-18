part of 'database.dart';

@DriftAccessor(tables: [RecipeLocalizations])
class RecipeLocalizationsDao extends DatabaseAccessor<AppDatabase>
    with _$RecipeLocalizationsDaoMixin {
  final AppDatabase db;
  RecipeLocalizationsDao(this.db) : super(db);

  Future<RecipeLocalization?> getLocalizationForRecipe(
      String recipeId, String locale) async {
    return (select(db.recipeLocalizations)
          ..where((tbl) =>
              tbl.recipeId.equals(recipeId) & tbl.locale.equals(locale)))
        .getSingleOrNull();
  }
}
