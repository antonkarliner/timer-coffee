import 'package:flutter/foundation.dart';

import '../database/database.dart';
import '../models/recipe_collection_model.dart';
import '../models/recipe_model.dart';

class RecipeCollectionProvider extends ChangeNotifier {
  final AppDatabase _db;

  RecipeCollectionProvider(this._db);

  List<RecipeCollectionModel> _collections = const [];
  String? _loadedForLocale;

  List<RecipeCollectionModel> get collections => _collections;

  Future<void> fetchAll(String locale) async {
    if (_loadedForLocale == locale && _collections.isNotEmpty) {
      // Refresh in background but keep showing the cached list immediately.
    }
    final result = await _db.recipeCollectionsDao.getAllCollections(locale);
    _collections = result;
    _loadedForLocale = locale;
    notifyListeners();
  }

  Future<RecipeCollectionModel?> getCollectionById(
      String id, String locale) {
    return _db.recipeCollectionsDao.getCollectionById(id, locale);
  }

  Future<List<RecipeModel>> fetchRecipesFor(
      String collectionId, String locale) {
    return _db.recipeCollectionsDao
        .getRecipesForCollection(collectionId, locale);
  }
}
