part of 'database.dart';

@DriftAccessor(tables: [
  RecipeCollections,
  RecipeCollectionLocalizations,
  RecipeCollectionMembers,
])
class RecipeCollectionsDao extends DatabaseAccessor<AppDatabase>
    with _$RecipeCollectionsDaoMixin {
  final AppDatabase db;

  RecipeCollectionsDao(this.db) : super(db);

  Future<List<RecipeCollectionModel>> getAllCollections(String locale) async {
    final collections = await (select(recipeCollections)
          ..where((c) => c.isPublished.equals(true))
          ..orderBy([
            (c) => OrderingTerm(expression: c.displayOrder),
            (c) => OrderingTerm(expression: c.id),
          ]))
        .get();
    if (collections.isEmpty) return const [];

    final ids = collections.map((c) => c.id).toList();
    final locs = await (select(recipeCollectionLocalizations)
          ..where((l) => l.collectionId.isIn(ids)))
        .get();

    final byCollectionLocale = <String, Map<String, RecipeCollectionLocalization>>{};
    for (final l in locs) {
      byCollectionLocale.putIfAbsent(l.collectionId, () => {})[l.locale] = l;
    }

    return collections.map((c) {
      final perLocale = byCollectionLocale[c.id] ?? const {};
      final loc = perLocale[locale] ?? perLocale['en'] ?? perLocale.values.firstOrNull;
      return RecipeCollectionModel(
        id: c.id,
        emoji: c.emoji,
        displayOrder: c.displayOrder,
        name: loc?.name ?? c.id,
        description: loc?.description,
      );
    }).toList();
  }

  Future<RecipeCollectionModel?> getCollectionById(
      String id, String locale) async {
    final c = await (select(recipeCollections)
          ..where((t) => t.id.equals(id) & t.isPublished.equals(true)))
        .getSingleOrNull();
    if (c == null) return null;

    final locs = await (select(recipeCollectionLocalizations)
          ..where((l) => l.collectionId.equals(id)))
        .get();
    final perLocale = {for (final l in locs) l.locale: l};
    final loc = perLocale[locale] ?? perLocale['en'] ?? perLocale.values.firstOrNull;

    return RecipeCollectionModel(
      id: c.id,
      emoji: c.emoji,
      displayOrder: c.displayOrder,
      name: loc?.name ?? c.id,
      description: loc?.description,
    );
  }

  Future<List<RecipeModel>> getRecipesForCollection(
      String collectionId, String locale) async {
    final members = await (select(recipeCollectionMembers)
          ..where((m) => m.collectionId.equals(collectionId))
          ..orderBy([
            (m) => OrderingTerm(expression: m.sortOrder),
            (m) => OrderingTerm(expression: m.recipeId),
          ]))
        .get();
    if (members.isEmpty) return const [];

    final recipeIds = members.map((m) => m.recipeId).toList();
    final recipeRows = await (select(recipes)
          ..where((r) => r.id.isIn(recipeIds)))
        .get();
    final recipeById = {for (final r in recipeRows) r.id: r};
    // Preserve member sort order.
    final ordered = <Recipe>[
      for (final m in members)
        if (recipeById[m.recipeId] != null) recipeById[m.recipeId]!,
    ];

    return db.recipesDao._getRecipeModelsFromQuery(ordered, locale);
  }

  Future<Map<String, Set<String>>> getMemberPairsByCollection() async {
    final rows = await select(recipeCollectionMembers).get();
    final membersByCollection = <String, Set<String>>{};
    for (final row in rows) {
      membersByCollection
          .putIfAbsent(row.collectionId, () => <String>{})
          .add(row.recipeId);
    }
    return membersByCollection;
  }

  // --- Sync write helpers (used by database_provider.dart) ---

  Future<void> upsertCollection(RecipeCollectionsCompanion entry) async {
    await into(recipeCollections).insertOnConflictUpdate(entry);
  }

  Future<void> upsertLocalization(
      RecipeCollectionLocalizationsCompanion entry) async {
    // We don't get the auto-increment id from Supabase, so upsert keyed on
    // (collection_id, locale) using the unique constraint.
    await into(recipeCollectionLocalizations).insert(
      entry,
      onConflict: DoUpdate(
        (_) => entry,
        target: [
          recipeCollectionLocalizations.collectionId,
          recipeCollectionLocalizations.locale,
        ],
      ),
    );
  }

  Future<void> deleteLocalizationsForCollection(String collectionId) async {
    await (delete(recipeCollectionLocalizations)
          ..where((l) => l.collectionId.equals(collectionId)))
        .go();
  }

  Future<void> replaceMembersForCollection(
      String collectionId, List<RecipeCollectionMembersCompanion> rows) async {
    await transaction(() async {
      await (delete(recipeCollectionMembers)
            ..where((m) => m.collectionId.equals(collectionId)))
          .go();
      if (rows.isEmpty) return;
      await batch((b) => b.insertAll(recipeCollectionMembers, rows));
    });
  }

  Future<void> deleteCollectionsNotIn(Set<String> keep) async {
    if (keep.isEmpty) {
      await delete(recipeCollections).go();
    } else {
      await (delete(recipeCollections)..where((c) => c.id.isNotIn(keep))).go();
    }
  }

  Future<Set<String>> getAllCollectionIds() async {
    final rows = await select(recipeCollections).get();
    return rows.map((r) => r.id).toSet();
  }
}
