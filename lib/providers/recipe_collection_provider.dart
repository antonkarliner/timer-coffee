import 'package:flutter/foundation.dart';

import '../database/database.dart';
import '../models/recipe_collection_model.dart';
import '../models/recipe_model.dart';
import '../services/collection_new_badge_service.dart';

class RecipeCollectionProvider extends ChangeNotifier {
  final AppDatabase _db;
  final CollectionNewBadgeService _badgeService;

  RecipeCollectionProvider(this._db, this._badgeService);

  List<RecipeCollectionModel> _collections = const [];
  String? _loadedForLocale;

  List<RecipeCollectionModel> get collections => _collections;

  Future<void> fetchAll(String locale) async {
    if (_loadedForLocale == locale && _collections.isNotEmpty) {
      // Refresh in background but keep showing the cached list immediately.
    }
    final result = await _db.recipeCollectionsDao.getAllCollections(locale);
    final membersByCollection =
        await _db.recipeCollectionsDao.getMemberPairsByCollection();
    await _badgeService.reconcile(membersByCollection);
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
