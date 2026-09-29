import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/providers/user_recipe_provider.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late UserRecipeProvider provider;

  const oldUserId = '853ecd55-8925-4866-95df-312efabedb14';
  const newUserId = '9d17bd53-b5e7-42dd-8e4f-98a516ca7282';
  const oldRecipeId = 'usr-$oldUserId-1790703549547';
  const newRecipeId = 'usr-$newUserId-1790703549547';

  setUp(() async {
    db = AppDatabase(
      NativeDatabase.memory(),
      enableForeignKeyConstraints: true,
    );
    provider = UserRecipeProvider(db);
    await db
        .into(db.brewingMethods)
        .insert(
          BrewingMethodsCompanion.insert(
            brewingMethodId: 'method-1',
            brewingMethod: 'V60',
          ),
        );
    await db
        .into(db.supportedLocales)
        .insert(
          SupportedLocalesCompanion.insert(locale: 'en', localeName: 'English'),
        );
    await db
        .into(db.recipeCollections)
        .insert(
          RecipeCollectionsCompanion.insert(id: 'collection-1', emoji: '☕'),
        );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertRecipe(String id, String vendorId) async {
    await db
        .into(db.recipes)
        .insert(
          RecipesCompanion.insert(
            id: id,
            brewingMethodId: 'method-1',
            coffeeAmount: 15,
            waterAmount: 250,
            waterTemp: 93,
            brewTime: 180,
            vendorId: Value(vendorId),
          ),
        );
  }

  test('migrates only valid anonymous recipe IDs after sign-in', () async {
    await insertRecipe(oldRecipeId, 'usr-$oldUserId');
    await db
        .into(db.steps)
        .insert(
          StepsCompanion.insert(
            id: 'step-1',
            recipeId: oldRecipeId,
            stepOrder: 1,
            description: 'Bloom',
            time: '45',
            locale: 'en',
          ),
        );
    await db
        .into(db.recipeLocalizations)
        .insert(
          RecipeLocalizationsCompanion.insert(
            id: 'localization-1',
            recipeId: oldRecipeId,
            locale: 'en',
            name: 'Anonymous recipe',
            grindSize: 'Medium-fine',
            shortDescription: 'Created before sign-in',
          ),
        );
    await db
        .into(db.userStats)
        .insert(
          UserStatsCompanion.insert(
            statUuid: 'stat-1',
            recipeId: oldRecipeId,
            coffeeAmount: 15,
            waterAmount: 250,
            sweetnessSliderPosition: 1,
            strengthSliderPosition: 2,
            brewingMethodId: 'method-1',
            versionVector: '{}',
          ),
        );
    await db
        .into(db.userRecipePreferences)
        .insert(
          UserRecipePreferencesCompanion.insert(
            recipeId: oldRecipeId,
            isFavorite: true,
          ),
        );
    await db
        .into(db.recipeCollectionMembers)
        .insert(
          RecipeCollectionMembersCompanion.insert(
            collectionId: 'collection-1',
            recipeId: oldRecipeId,
          ),
        );

    const otherRecipeId = 'usr-other-user-1790703549548';
    await insertRecipe(otherRecipeId, 'usr-other-user');

    const malformedRecipeId = 'recipe-without-owner-prefix';
    await insertRecipe(malformedRecipeId, 'usr-$oldUserId');

    await provider.updateUserRecipeIdsAfterLogin(oldUserId, newUserId);

    final migratedRecipe = await (db.select(
      db.recipes,
    )..where((recipe) => recipe.id.equals(newRecipeId))).getSingle();
    expect(migratedRecipe.vendorId, 'usr-$newUserId');
    expect(
      await (db.select(
        db.recipes,
      )..where((recipe) => recipe.id.equals(oldRecipeId))).get(),
      isEmpty,
    );

    final migratedStep = await (db.select(
      db.steps,
    )..where((step) => step.id.equals('step-1'))).getSingle();
    expect(migratedStep.recipeId, newRecipeId);
    final migratedLocalization =
        await (db.select(db.recipeLocalizations)..where(
              (localization) => localization.id.equals('localization-1'),
            ))
            .getSingle();
    expect(migratedLocalization.recipeId, newRecipeId);
    final migratedStat = await (db.select(
      db.userStats,
    )..where((stat) => stat.statUuid.equals('stat-1'))).getSingle();
    expect(migratedStat.recipeId, newRecipeId);
    final migratedPreferences =
        await (db.select(db.userRecipePreferences)
              ..where((preference) => preference.recipeId.equals(newRecipeId)))
            .getSingle();
    expect(migratedPreferences.isFavorite, isTrue);
    final migratedCollectionMember =
        await (db.select(db.recipeCollectionMembers)
              ..where((member) => member.collectionId.equals('collection-1')))
            .getSingle();
    expect(migratedCollectionMember.recipeId, newRecipeId);

    expect(
      await (db.select(
        db.recipeLocalizations,
      )..where((row) => row.recipeId.equals(oldRecipeId))).get(),
      isEmpty,
    );
    expect(
      await (db.select(
        db.steps,
      )..where((row) => row.recipeId.equals(oldRecipeId))).get(),
      isEmpty,
    );
    expect(
      await (db.select(
        db.userStats,
      )..where((row) => row.recipeId.equals(oldRecipeId))).get(),
      isEmpty,
    );
    expect(
      await (db.select(
        db.userRecipePreferences,
      )..where((row) => row.recipeId.equals(oldRecipeId))).get(),
      isEmpty,
    );
    expect(
      await (db.select(
        db.recipeCollectionMembers,
      )..where((row) => row.recipeId.equals(oldRecipeId))).get(),
      isEmpty,
    );

    final otherRecipe = await (db.select(
      db.recipes,
    )..where((recipe) => recipe.id.equals(otherRecipeId))).getSingle();
    expect(otherRecipe.vendorId, 'usr-other-user');

    final malformedRecipe = await (db.select(
      db.recipes,
    )..where((recipe) => recipe.id.equals(malformedRecipeId))).getSingle();
    expect(malformedRecipe.vendorId, 'usr-$oldUserId');

    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  });
}
