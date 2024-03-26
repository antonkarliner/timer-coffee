import 'dart:async';
import 'package:coffee_timer/models/brew_step_model.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:drift/drift.dart';
import 'connection/connection.dart' show connect;
import '../models/brewing_method_model.dart';
import '../models/vendor_model.dart';
import '../models/supported_locale_model.dart';
import '../models/coffee_fact_model.dart';
import '../models/start_popup_model.dart';
part 'database.g.dart';
part 'recipes_dao.dart';
part 'steps_dao.dart';
part 'recipe_localization_dao.dart';
part 'user_recipe_preferences_dao.dart';
part 'brewing_methods_dao.dart';
part 'vendors_dao.dart';
part 'supported_locales_dao.dart';
part 'coffee_facts_dao.dart';
part 'start_popups_dao.dart';

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

  @override
  Set<Column> get primaryKey => {brewingMethodId};
}

class Recipes extends Table {
  TextColumn get id => text().named('id').withLength(min: 1, max: 255)();
  TextColumn get brewingMethodId => text()
      .named('brewing_method_id')
      .customConstraint(
          'REFERENCES brewing_methods(brewing_method_id) NOT NULL')
      .withLength(min: 1, max: 255)();
  RealColumn get coffeeAmount => real().named('coffee_amount')();
  RealColumn get waterAmount => real().named('water_amount')();
  RealColumn get waterTemp => real().named('water_temp')();
  IntColumn get brewTime =>
      integer().named('brew_time')(); // Brew time in seconds
  TextColumn get vendorId => text()
      .named('vendor_id')
      .customConstraint('REFERENCES vendors(vendor_id)')
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
      .customConstraint('REFERENCES recipes(id) NOT NULL')();
  TextColumn get locale => text()
      .named('locale')
      .customConstraint('REFERENCES supported_locales(locale) NOT NULL')
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
      .customConstraint('REFERENCES recipes(id) NOT NULL')();
  IntColumn get stepOrder => integer().named('step_order')();
  TextColumn get description => text().named('description')();
  TextColumn get time => text().named('time')();
  TextColumn get locale => text()
      .named('locale')
      .customConstraint('REFERENCES supported_locales(locale) NOT NULL')
      .withLength(min: 2, max: 10)();

  @override
  Set<Column> get primaryKey => {id};
}

class UserRecipePreferences extends Table {
  TextColumn get recipeId => text()
      .named('recipe_id')
      .customConstraint('REFERENCES recipes(id) NOT NULL')();
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
      .customConstraint('REFERENCES supported_locales(locale) NOT NULL')
      .withLength(min: 2, max: 10)();

  @override
  Set<Column> get primaryKey => {id};
}

class StartPopups extends Table {
  TextColumn get id => text().named('id').withLength(min: 1, max: 255)();
  TextColumn get content => text().named('content')();
  TextColumn get appVersion => text().named('app_version')();
  TextColumn get locale => text()
      .named('locale')
      .customConstraint('REFERENCES supported_locales(locale) NOT NULL')();

  @override
  Set<Column> get primaryKey => {id};
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
    StartPopups,
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
    StartPopupsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  final bool enableForeignKeyConstraints;

  AppDatabase({this.enableForeignKeyConstraints = true})
      : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        // Apply foreign key constraints based on the boolean flag
        beforeOpen: (details) async {
          if (enableForeignKeyConstraints) {
            await customStatement('PRAGMA foreign_keys = ON');
          }
        },
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.addColumn(vendors, vendors.bannerUrl);
          }
        },
      );
}

DatabaseConnection _openConnection() {
  return DatabaseConnection.delayed(connect());
}
