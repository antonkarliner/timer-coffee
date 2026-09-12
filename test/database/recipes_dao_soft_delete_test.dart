import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/models/user_stat_model.dart';
import 'package:coffee_timer/utils/version_vector.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

UserStatsModel _makeStat({
  String uuid = 'stat-uuid-1',
  String recipeId = 'usr-user-1-imported',
  String brewingMethodId = 'method-1',
}) {
  return UserStatsModel(
    statUuid: uuid,
    recipeId: recipeId,
    coffeeAmount: 15,
    waterAmount: 250,
    sweetnessSliderPosition: 1,
    strengthSliderPosition: 2,
    brewingMethodId: brewingMethodId,
    createdAt: DateTime(2024, 1, 15),
    isMarked: false,
    versionVector: VersionVector.initial('device-1').toString(),
    isDeleted: false,
  );
}

/// Seeds a brewing method plus three recipes:
/// - 'recipe-live': a live catalog-style recipe
/// - 'usr-user-1-created': a live user recipe
/// - 'usr-user-1-imported': an imported, public recipe flagged for moderation
///   that the tests tombstone via [RecipesDao.softDeleteRecipe].
Future<void> _seed(AppDatabase db) async {
  // Required in the FK-enabled database (localizations and steps reference
  // supported_locales.locale); harmless in the FK-disabled one.
  await db
      .into(db.supportedLocales)
      .insert(
        SupportedLocalesCompanion.insert(locale: 'en', localeName: 'English'),
      );

  await db
      .into(db.brewingMethods)
      .insert(
        BrewingMethodsCompanion.insert(
          brewingMethodId: 'method-1',
          brewingMethod: 'V60',
        ),
      );

  await db
      .into(db.recipes)
      .insert(
        RecipesCompanion.insert(
          id: 'recipe-live',
          brewingMethodId: 'method-1',
          coffeeAmount: 15,
          waterAmount: 250,
          waterTemp: 93,
          brewTime: 180,
          lastModified: Value(DateTime(2024, 1, 1)),
        ),
      );
  await db
      .into(db.recipes)
      .insert(
        RecipesCompanion.insert(
          id: 'usr-user-1-created',
          brewingMethodId: 'method-1',
          coffeeAmount: 15,
          waterAmount: 250,
          waterTemp: 93,
          brewTime: 180,
          vendorId: const Value('usr-user-1'),
          lastModified: Value(DateTime(2024, 3, 1)),
        ),
      );
  await db
      .into(db.recipes)
      .insert(
        RecipesCompanion.insert(
          id: 'usr-user-1-imported',
          brewingMethodId: 'method-1',
          coffeeAmount: 15,
          waterAmount: 250,
          waterTemp: 93,
          brewTime: 180,
          vendorId: const Value('usr-user-1'),
          lastModified: Value(DateTime(2024, 2, 1)),
          importId: const Value('import-1'),
          isImported: const Value(true),
          isPublic: const Value(true),
          needsModerationReview: const Value(true),
        ),
      );

  for (final entry in {
    'recipe-live': 'Live recipe',
    'usr-user-1-imported': 'Imported recipe',
  }.entries) {
    await db
        .into(db.recipeLocalizations)
        .insert(
          RecipeLocalizationsCompanion.insert(
            id: '${entry.key}-en',
            recipeId: entry.key,
            locale: 'en',
            name: entry.value,
            grindSize: 'Medium',
            shortDescription: '${entry.value} description',
          ),
        );
  }

  await db
      .into(db.steps)
      .insert(
        StepsCompanion.insert(
          id: 'step-1',
          recipeId: 'usr-user-1-imported',
          stepOrder: 1,
          description: 'Bloom',
          time: '45',
          locale: 'en',
        ),
      );

  await db
      .into(db.recipeCollections)
      .insert(RecipeCollectionsCompanion.insert(id: 'col-1', emoji: '☕'));
  await db
      .into(db.recipeCollectionMembers)
      .insert(
        RecipeCollectionMembersCompanion.insert(
          collectionId: 'col-1',
          recipeId: 'recipe-live',
        ),
      );
  await db
      .into(db.recipeCollectionMembers)
      .insert(
        RecipeCollectionMembersCompanion.insert(
          collectionId: 'col-1',
          recipeId: 'usr-user-1-imported',
        ),
      );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = openTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('softDeleteRecipe', () {
    test('tombstones the row but keeps it, its localizations and its steps',
        () async {
      await _seed(db);
      await db.recipesDao.softDeleteRecipe('usr-user-1-imported');

      final row = await (db.select(db.recipes)
            ..where((r) => r.id.equals('usr-user-1-imported')))
          .getSingle();
      expect(row.isDeleted, isTrue);
      expect(row.deletedAt, isNotNull);

      final localizations = await (db.select(db.recipeLocalizations)
            ..where((l) => l.recipeId.equals('usr-user-1-imported')))
          .get();
      expect(localizations, hasLength(1));

      final steps = await (db.select(db.steps)
            ..where((s) => s.recipeId.equals('usr-user-1-imported')))
          .get();
      expect(steps, hasLength(1));
    });

    test('does not bump lastModified (catalog sync watermark)', () async {
      await _seed(db);

      await db.recipesDao.softDeleteRecipe('usr-user-1-imported');

      expect(
        await db.recipesDao.fetchLastModified(),
        DateTime(2024, 3, 1),
      );
    });

    test('keeps diary entries intact and readable with the recipe name',
        () async {
      await _seed(db);
      await db.userStatsDao.insertUserStat(_makeStat());

      await db.recipesDao.softDeleteRecipe('usr-user-1-imported');

      final stat = await db.userStatsDao.fetchStatByUuid('stat-uuid-1');
      expect(stat, isNotNull);

      final entries = await db.userStatsDao.fetchDiaryEntries('en');
      expect(entries, hasLength(1));
      expect(entries.single.recipeId, 'usr-user-1-imported');
      expect(entries.single.recipeName, 'Imported recipe');
    });
  });

  group('tombstoned recipes are hidden from browse surfaces', () {
    test('getAllRecipes', () async {
      await _seed(db);
      await db.recipesDao.softDeleteRecipe('usr-user-1-imported');

      final ids =
          (await db.recipesDao.getAllRecipes('en')).map((r) => r.id);
      expect(ids, containsAll(['recipe-live', 'usr-user-1-created']));
      expect(ids, isNot(contains('usr-user-1-imported')));
    });

    test('fetchRecipesForBrewingMethod', () async {
      await _seed(db);
      await db.recipesDao.softDeleteRecipe('usr-user-1-imported');

      final ids = (await db.recipesDao.fetchRecipesForBrewingMethod(
        'method-1',
        'en',
      )).map((r) => r.id);
      expect(ids, containsAll(['recipe-live', 'usr-user-1-created']));
      expect(ids, isNot(contains('usr-user-1-imported')));
    });

    test('getUserRecipes', () async {
      await _seed(db);
      await db.recipesDao.softDeleteRecipe('usr-user-1-imported');

      final ids = (await db.recipesDao.getUserRecipes()).map((r) => r.id);
      expect(ids, ['usr-user-1-created']);
    });

    test('getImportedRecipes', () async {
      await _seed(db);
      await db.recipesDao.softDeleteRecipe('usr-user-1-imported');

      expect(await db.recipesDao.getImportedRecipes(), isEmpty);
    });

    test('getRecipesNeedingModeration', () async {
      await _seed(db);
      await db.recipesDao.softDeleteRecipe('usr-user-1-imported');

      expect(await db.recipesDao.getRecipesNeedingModeration(), isEmpty);
    });

    test('getRecipesForCollection', () async {
      await _seed(db);
      await db.recipesDao.softDeleteRecipe('usr-user-1-imported');

      final models = await db.recipeCollectionsDao.getRecipesForCollection(
        'col-1',
        'en',
      );
      expect(models.map((r) => r.id), ['recipe-live']);
    });
  });

  group('tombstoned recipes stay visible to sync- and history-facing queries',
      () {
    test('fetchIdsAndLastModifiedDates', () async {
      await _seed(db);
      await db.recipesDao.softDeleteRecipe('usr-user-1-imported');

      final ids = (await db.recipesDao.fetchIdsAndLastModifiedDates()).keys;
      // INTENDED: the tombstone must stay visible to sync reconciliation, or
      // sync would consider the row missing locally and re-download it,
      // resurrecting the deleted recipe.
      expect(ids, contains('usr-user-1-imported'));
    });

    test('getUserRecipesModifiedAfter', () async {
      await _seed(db);
      await db.recipesDao.softDeleteRecipe('usr-user-1-imported');

      final recipes = await db.recipesDao.getUserRecipesModifiedAfter(
        null,
        'user-1',
      );
      // INTENDED: the sync upload leg must still see the tombstone so the
      // deletion state can travel up to Supabase.
      expect(recipes.map((r) => r.id), contains('usr-user-1-imported'));
    });

    test('getRecipeByImportId', () async {
      await _seed(db);
      await db.recipesDao.softDeleteRecipe('usr-user-1-imported');

      // INTENDED: a re-import must find the existing tombstoned row so it
      // updates it instead of creating a duplicate.
      final recipe = await db.recipesDao.getRecipeByImportId('import-1');
      expect(recipe, isNotNull);
      expect(recipe!.isDeleted, isTrue);
    });

    test('getRecipeModelById', () async {
      await _seed(db);
      await db.recipesDao.softDeleteRecipe('usr-user-1-imported');

      // INTENDED: a diary entry must still be able to open the recipe it was
      // brewed with — keeping history viewable is the point of tombstoning.
      final model = await db.recipesDao.getRecipeModelById(
        'usr-user-1-imported',
        'en',
      );
      expect(model, isNotNull);
      expect(model!.name, 'Imported recipe');
    });
  });

  group('_fetchAnyRecipe fallback', () {
    test('never reattaches a stat to a tombstoned recipe', () async {
      // FK constraints must be ON so the fallback path actually triggers.
      final fkDb = AppDatabase(NativeDatabase.memory());
      addTearDown(fkDb.close);
      await _seed(fkDb);
      await fkDb.recipesDao.softDeleteRecipe('usr-user-1-imported');

      // References a recipe that does not exist at all, forcing the FK
      // fallback to pick any live recipe.
      await fkDb.userStatsDao.insertUserStatWithFallback(
        _makeStat(recipeId: 'missing-recipe'),
      );

      final saved = await fkDb.userStatsDao.fetchStatByUuid('stat-uuid-1');
      expect(saved, isNotNull);
      expect(saved!.recipeId, 'recipe-live');
    });
  });
}
