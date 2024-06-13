import 'dart:async';
import 'package:coffee_timer/models/brew_step_model.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:drift/drift.dart';
import 'connection/connection.dart' show connect;
import '../models/brewing_method_model.dart';
import '../models/vendor_model.dart';
import '../models/supported_locale_model.dart';
import '../models/coffee_fact_model.dart';
import '../models/contributor_model.dart';
import '../models/user_stat_model.dart';
import '../models/launch_popup_model.dart';
import '../models/coffee_beans_model.dart';
import '../database/schema_versions.dart';
part 'database.g.dart';
part 'recipes_dao.dart';
part 'steps_dao.dart';
part 'recipe_localization_dao.dart';
part 'user_recipe_preferences_dao.dart';
part 'brewing_methods_dao.dart';
part 'vendors_dao.dart';
part 'supported_locales_dao.dart';
part 'coffee_facts_dao.dart';
part 'contributors_dao.dart';
part 'user_stats_dao.dart';
part 'launch_popups_dao.dart';
part 'coffee_beans_dao.dart';

class Vendors extends Table {
  TextColumn get vendorId =>
      text().named('vendor_id').withLength(min: 1, max: 255)();
  TextColumn get vendorName => text().named('vendor_name')();
  TextColumn get vendorDescription => text().named('vendor_description')();
  TextColumn get bannerUrl => text().named('banner_url').nullable()();
  BoolColumn get active => boolean().named('active')();

  @override
  Set<Column> get primaryKey => {vendorId};
}

class SupportedLocales extends Table {
  TextColumn get locale =>
      text().named('locale').withLength(min: 1, max: 255)();
  TextColumn get localeName =>
      text().named('locale_name').withLength(min: 1, max: 255)();

  @override
  Set<Column> get primaryKey => {locale};
}

class BrewingMethods extends Table {
  TextColumn get brewingMethodId =>
      text().named('brewing_method_id').withLength(min: 1, max: 255)();
  TextColumn get brewingMethod =>
      text().named('brewing_method').withLength(min: 1, max: 255)();
  BoolColumn get showOnMain =>
      boolean().named('show_on_main').withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {brewingMethodId};
}

@TableIndex(name: 'idx_recipes_last_modified', columns: {#lastModified})
class Recipes extends Table {
  TextColumn get id => text().named('id').withLength(min: 1, max: 255)();
  TextColumn get brewingMethodId => text()
      .named('brewing_method_id')
      .references(BrewingMethods, #brewingMethodId, onDelete: KeyAction.cascade)
      .withLength(min: 1, max: 255)();
  RealColumn get coffeeAmount => real().named('coffee_amount')();
  RealColumn get waterAmount => real().named('water_amount')();
  RealColumn get waterTemp => real().named('water_temp')();
  IntColumn get brewTime =>
      integer().named('brew_time')(); // Brew time in seconds
  TextColumn get vendorId => text()
      .named('vendor_id')
      .references(Vendors, #vendorId, onDelete: KeyAction.setNull)
      .nullable()();
  DateTimeColumn get lastModified =>
      dateTime().named('last_modified').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class RecipeLocalizations extends Table {
  TextColumn get id => text().named('id').withLength(min: 1, max: 255)();
  TextColumn get recipeId => text()
      .named('recipe_id')
      .references(Recipes, #id, onDelete: KeyAction.cascade)();
  TextColumn get locale => text()
      .named('locale')
      .references(SupportedLocales, #locale, onDelete: KeyAction.cascade)
      .withLength(min: 2, max: 10)();
  TextColumn get name => text().named('name')();
  TextColumn get grindSize =>
      text().named('grind_size').withLength(min: 1, max: 255)();
  TextColumn get shortDescription => text().named('short_description')();

  @override
  Set<Column> get primaryKey => {id};
}

class Steps extends Table {
  TextColumn get id => text().named('id').withLength(min: 1, max: 255)();
  TextColumn get recipeId => text()
      .named('recipe_id')
      .references(Recipes, #id, onDelete: KeyAction.cascade)();
  IntColumn get stepOrder => integer().named('step_order')();
  TextColumn get description => text().named('description')();
  TextColumn get time => text().named('time')();
  TextColumn get locale => text()
      .named('locale')
      .references(SupportedLocales, #locale, onDelete: KeyAction.cascade)
      .withLength(min: 2, max: 10)();

  @override
  Set<Column> get primaryKey => {id};
}

class UserRecipePreferences extends Table {
  TextColumn get recipeId => text()
      .named('recipe_id')
      .references(Recipes, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get lastUsed => dateTime().named('last_used').nullable()();
  BoolColumn get isFavorite => boolean().named('is_favorite')();
  IntColumn get sweetnessSliderPosition => integer()
      .named('sweetness_slider_position')
      .withDefault(const Constant(1))();
  IntColumn get strengthSliderPosition => integer()
      .named('strength_slider_position')
      .withDefault(const Constant(2))();
  RealColumn get customCoffeeAmount =>
      real().named('custom_coffee_amount').nullable()();
  RealColumn get customWaterAmount =>
      real().named('custom_water_amount').nullable()();

  @override
  Set<Column> get primaryKey => {recipeId};
}

class CoffeeFacts extends Table {
  TextColumn get id => text().named('id').withLength(min: 1, max: 255)();
  TextColumn get fact => text().named('fact')();
  TextColumn get locale => text()
      .named('locale')
      .references(SupportedLocales, #locale, onDelete: KeyAction.cascade)
      .withLength(min: 2, max: 10)();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_launch_popups_created_at', columns: {#createdAt})
class LaunchPopups extends Table {
  IntColumn get id => integer().named('id')();
  TextColumn get content => text().named('content')();
  TextColumn get locale => text()
      .named('locale')
      .references(SupportedLocales, #locale, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class Contributors extends Table {
  TextColumn get id => text().named('id').withLength(min: 1, max: 255)();
  TextColumn get content => text().named('content')();
  TextColumn get locale => text()
      .named('locale')
      .references(SupportedLocales, #locale, onDelete: KeyAction.cascade)
      .withLength(min: 2, max: 10)();

  @override
  Set<Column> get primaryKey => {id};
}

class UserStats extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get recipeId =>
      text().named('recipe_id').references(Recipes, #id)();
  RealColumn get coffeeAmount => real().named('coffee_amount')();
  RealColumn get waterAmount => real().named('water_amount')();
  IntColumn get sweetnessSliderPosition =>
      integer().named('sweetness_slider_position')();
  IntColumn get strengthSliderPosition =>
      integer().named('strength_slider_position')();
  TextColumn get brewingMethodId => text()
      .named('brewing_method_id')
      .references(BrewingMethods, #brewingMethodId)();
  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
  TextColumn get notes => text().named('notes').nullable()();
  TextColumn get beans => text().named('beans').nullable()();
  TextColumn get roaster => text().named('roaster').nullable()();
  RealColumn get rating => real().named('rating').nullable()();
  IntColumn get coffeeBeansId =>
      integer().named('coffee_beans_id').nullable()();
  BoolColumn get isMarked =>
      boolean().named('is_marked').withDefault(const Constant(false))();
}

class CoffeeBeans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get roaster => text().named('roaster')();
  TextColumn get name => text().named('name')();
  TextColumn get origin => text().named('origin')();
  TextColumn get variety => text().named('variety').nullable()();
  TextColumn get tastingNotes => text().named('tasting_notes').nullable()();
  TextColumn get processingMethod =>
      text().named('processing_method').nullable()();
  IntColumn get elevation => integer().named('elevation').nullable()();
  DateTimeColumn get harvestDate =>
      dateTime().named('harvest_date').nullable()();
  DateTimeColumn get roastDate => dateTime().named('roast_date').nullable()();
  TextColumn get region => text().named('region').nullable()();
  TextColumn get roastLevel => text().named('roast_level').nullable()();
  RealColumn get cuppingScore => real().named('cupping_score').nullable()();
  TextColumn get notes => text().named('notes').nullable()();
  BoolColumn get isFavorite =>
      boolean().named('is_favorite').withDefault(const Constant(false))();
}

@DriftDatabase(
  tables: [
    Vendors,
    SupportedLocales,
    BrewingMethods,
    Recipes,
    RecipeLocalizations,
    Steps,
    UserRecipePreferences,
    CoffeeFacts,
    LaunchPopups,
    Contributors,
    UserStats,
    CoffeeBeans
  ],
  daos: [
    RecipesDao,
    StepsDao,
    RecipeLocalizationsDao,
    UserRecipePreferencesDao,
    BrewingMethodsDao,
    VendorsDao,
    SupportedLocalesDao,
    CoffeeFactsDao,
    ContributorsDao,
    UserStatsDao,
    LaunchPopupsDao,
    CoffeeBeansDao
  ],
)
class AppDatabase extends _$AppDatabase {
  final bool enableForeignKeyConstraints;

  AppDatabase({this.enableForeignKeyConstraints = true})
      : super(_openConnection());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
      // Apply foreign key constraints based on the boolean flag
      beforeOpen: (details) async {
        if (enableForeignKeyConstraints) {
          await customStatement('PRAGMA foreign_keys = ON');
        }
      },
      onUpgrade: stepByStep(
        from1To2: (m, schema) async {
          await m.addColumn(schema.vendors, schema.vendors.bannerUrl);
        },
        from2To3: (m, schema) async {
          await m.createIndex(schema.idxRecipesLastModified);
        },
        from3To4: (m, schema) async {
          await m.createTable(contributors);
          await m.addColumn(brewingMethods, brewingMethods.showOnMain);
        },
        from4To5: (m, schema) async {
          await m.createTable(userStats);
        },
        from5To6: (m, schema) async {
          await m.createTable(launchPopups);
          await m.createIndex(schema.idxLaunchPopupsCreatedAt);
          await m.deleteTable('StartPopups');
        },
        from6To7: (m, schema) async {
          await m.addColumn(userStats, userStats.coffeeBeansId);
          await m.addColumn(userStats, userStats.isMarked);
          await m.createTable(coffeeBeans);
        },
      ));
}

DatabaseConnection _openConnection() {
  return DatabaseConnection.delayed(connect());
}
