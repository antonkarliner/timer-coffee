import 'dart:async';
import 'package:coffee_timer/models/brew_step_model.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:drift/drift.dart';
import 'connection/connection.dart' show connect;
import '../models/brewing_method_model.dart';
import '../models/supported_locale_model.dart';
import '../models/coffee_fact_model.dart';
import '../models/user_stat_model.dart';
import '../models/coffee_beans_model.dart';
import 'package:coffee_timer/models/beans_stats_models.dart';
import '../database/schema_versions.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';
part 'database.g.dart';
part 'recipes_dao.dart';
part 'steps_dao.dart';
part 'recipe_localization_dao.dart';
part 'user_recipe_preferences_dao.dart';
part 'brewing_methods_dao.dart';
part 'supported_locales_dao.dart';
part 'coffee_facts_dao.dart';
part 'user_stats_dao.dart';
part 'coffee_beans_dao.dart';
part 'beans_stats_dao.dart';

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
  TextColumn get vendorId => text().named('vendor_id').nullable()();
  DateTimeColumn get lastModified =>
      dateTime().named('last_modified').nullable()();
  TextColumn get importId => text().named('import_id').nullable()();
  BoolColumn get isImported =>
      boolean().named('is_imported').withDefault(const Constant(false))();
  // New column for tracking moderation status
  BoolColumn get needsModerationReview => boolean()
      .named('needs_moderation_review')
      .withDefault(const Constant(false))();

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
  IntColumn get coffeeChroniclerSliderPosition => integer()
      .named('coffee_chronicler_slider_position')
      .withDefault(const Constant(0))();

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

@TableIndex(
    name: 'idx_user_stats_stat_uuid_version_vector',
    columns: {#statUuid, #versionVector})
class UserStats extends Table {
  TextColumn get statUuid => text().named('stat_uuid')();
  IntColumn get id => integer().named('id').nullable()();
  TextColumn get recipeId => text()
      .named('recipe_id')
      .references(Recipes, #id, onDelete: KeyAction.cascade)();
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
  TextColumn get coffeeBeansUuid =>
      text().named('coffee_beans_uuid').nullable()();
  TextColumn get versionVector => text().named('version_vector')();
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {statUuid};
}

@TableIndex(
    name: 'idx_coffee_beans_beans_uuid_version_vector',
    columns: {#beansUuid, #versionVector})
class CoffeeBeans extends Table {
  TextColumn get beansUuid => text().named('beans_uuid')();
  IntColumn get id => integer().named('id').nullable()();
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
  // New optional fields
  TextColumn get farmer => text().named('farmer').nullable()();
  TextColumn get farm => text().named('farm').nullable()();
  BoolColumn get isFavorite =>
      boolean().named('is_favorite').withDefault(const Constant(false))();
  TextColumn get versionVector => text().named('version_vector')();
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {beansUuid};
}

@DriftDatabase(
  tables: [
    SupportedLocales,
    BrewingMethods,
    Recipes,
    RecipeLocalizations,
    Steps,
    UserRecipePreferences,
    CoffeeFacts,
    UserStats,
    CoffeeBeans
  ],
  daos: [
    RecipesDao,
    StepsDao,
    RecipeLocalizationsDao,
    UserRecipePreferencesDao,
    BrewingMethodsDao,
    SupportedLocalesDao,
    CoffeeFactsDao,
    UserStatsDao,
    CoffeeBeansDao,
    BeansStatsDao
  ],
)
class AppDatabase extends _$AppDatabase {
  final bool enableForeignKeyConstraints;
  final Uuid _uuid = Uuid();

  AppDatabase(QueryExecutor executor, {bool? enableForeignKeyConstraints})
      : enableForeignKeyConstraints = enableForeignKeyConstraints ?? true,
        super(executor);

  AppDatabase.withDefault({bool enableForeignKeyConstraints = true})
      : this(_openConnection(),
            enableForeignKeyConstraints: enableForeignKeyConstraints);

  factory AppDatabase.fromExecutor(QueryExecutor e) => AppDatabase(e);

  @override
  int get schemaVersion =>
      27; // Incremented schema version (Phase B: launch_popups removed)

  String _generateUuidV7() {
    return _uuid.v7();
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          if (enableForeignKeyConstraints) {
            await customStatement('PRAGMA foreign_keys = ON');
          }
        },
        onUpgrade: (m, oldVersion, newVersion) async {
          await stepByStep(
            from1To2: (m, schema) async {
              // Note: Vendors table was dropped in v20, this migration might be obsolete
              // await m.addColumn(schema.vendors, schema.vendors.bannerUrl);
            },
            from2To3: (m, schema) async {
              await m.createIndex(schema.idxRecipesLastModified);
            },
            from3To4: (m, schema) async {
              //   await m.createTable(contributors);
              //   // The showOnMain column is being removed in schema v24,
              //   // so this addColumn call from an older migration is no longer needed
              //   // and would cause an error if the column definition doesn't exist in the schema object.
              //   // await m.addColumn(brewingMethods, brewingMethods.showOnMain);
            },
            from4To5: (m, schema) async {
              await m.createTable(userStats);
            },
            from5To6: (m, schema) async {
              //await m.createTable(launchPopups);
              //await m.createIndex(schema.idxLaunchPopupsCreatedAt);
              // await m.deleteTable('StartPopups'); // Use customStatement for safety
              await customStatement('DROP TABLE IF EXISTS StartPopups');
            },
            from6To7: (m, schema) async {
              await m.addColumn(userStats, userStats.coffeeBeansId);
              await m.addColumn(userStats, userStats.isMarked);
              await m.createTable(coffeeBeans);
            },
            from7To8: (m, schema) async {
              // Add beansUuid column to CoffeeBeans table as nullable
              await customStatement(
                  'ALTER TABLE coffee_beans ADD COLUMN beans_uuid TEXT');

              // Generate UUIDs for existing rows in CoffeeBeans
              final coffeeBeansRows = await customSelect(
                      'SELECT id FROM coffee_beans WHERE beans_uuid IS NULL')
                  .get();
              for (final row in coffeeBeansRows) {
                final id = row.data['id'] as int;
                final newUuid = _generateUuidV7();
                await customUpdate(
                  'UPDATE coffee_beans SET beans_uuid = ? WHERE id = ?',
                  variables: [
                    Variable.withString(newUuid),
                    Variable.withInt(id)
                  ],
                );
              }

              // Add coffeeBeansUuid column to UserStats table
              await customStatement(
                  'ALTER TABLE user_stats ADD COLUMN coffee_beans_uuid TEXT');

              // Update UserStats with corresponding CoffeeBeans UUIDs
              await customStatement('''
          UPDATE user_stats
          SET coffee_beans_uuid = (
            SELECT beans_uuid
            FROM coffee_beans
            WHERE coffee_beans.id = user_stats.coffee_beans_id
          )
          WHERE coffee_beans_id IS NOT NULL
        ''');
            },
            from8To9: (m, schema) async {
              // Add stat_uuid column to UserStats table as nullable
              await customStatement(
                  'ALTER TABLE user_stats ADD COLUMN stat_uuid TEXT');

              // Generate UUIDs for existing rows in UserStats
              final userStatsRows = await customSelect(
                      'SELECT id FROM user_stats WHERE stat_uuid IS NULL')
                  .get();
              for (final row in userStatsRows) {
                final id = row.data['id'] as int;
                final newUuid = _generateUuidV7();
                await customUpdate(
                  'UPDATE user_stats SET stat_uuid = ? WHERE id = ?',
                  variables: [
                    Variable.withString(newUuid),
                    Variable.withInt(id)
                  ],
                );
              }
            },
            from9To10: (m, schema) async {
              // await m.dropColumn(userStats, 'user_id'); // Use customStatement for safety
              await customStatement(
                  'ALTER TABLE user_stats DROP COLUMN user_id');
            },
            from10To11: (m, schema) async {
              await customStatement('PRAGMA foreign_keys = OFF');

              try {
                // Step 1: Check if stat_uuid column exists
                final columns =
                    await customSelect("PRAGMA table_info('user_stats')").get();
                final statUuidExists =
                    columns.any((column) => column.data['name'] == 'stat_uuid');

                // Step 2: Add stat_uuid column if it doesn't exist
                if (!statUuidExists) {
                  await customStatement(
                      'ALTER TABLE user_stats ADD COLUMN stat_uuid TEXT');
                }

                // Step 3: Generate and update UUIDs for rows that need them
                final rows = await customSelect(
                        'SELECT id FROM user_stats WHERE stat_uuid IS NULL')
                    .get();

                for (final row in rows) {
                  final id = row.data['id'] as int;
                  final newUuid =
                      _generateUuidV7(); // Your Dart method to generate UUID
                  await customUpdate(
                    'UPDATE user_stats SET stat_uuid = ? WHERE id = ?',
                    variables: [
                      Variable.withString(newUuid),
                      Variable.withInt(id)
                    ],
                  );
                }

                // Step 4: Create new table with desired structure
                await customStatement('''
      CREATE TABLE IF NOT EXISTS new_user_stats (
        stat_uuid TEXT NOT NULL PRIMARY KEY,
        id INTEGER,
        recipe_id TEXT NOT NULL REFERENCES recipes(id),
        coffee_amount REAL NOT NULL,
        water_amount REAL NOT NULL,
        sweetness_slider_position INTEGER NOT NULL,
        strength_slider_position INTEGER NOT NULL,
        brewing_method_id TEXT NOT NULL REFERENCES brewing_methods(brewing_method_id),
        created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER)),
        notes TEXT,
        beans TEXT,
        roaster TEXT,
        rating REAL,
        coffee_beans_id INTEGER,
        is_marked INTEGER NOT NULL DEFAULT 0 CHECK (is_marked IN (0, 1)),
        coffee_beans_uuid TEXT
      )
    ''');

                // Step 5: Copy data to new table
                await customStatement('''
      INSERT OR REPLACE INTO new_user_stats
      SELECT
        stat_uuid,
        id, recipe_id, coffee_amount, water_amount,
        sweetness_slider_position, strength_slider_position, brewing_method_id,
        COALESCE(created_at, CAST(strftime('%s', 'now') AS INTEGER)) as created_at,
        notes, beans, roaster, rating, coffee_beans_id, is_marked, coffee_beans_uuid
      FROM user_stats
    ''');

                // Step 6: Replace old table with new one
                await customStatement('DROP TABLE IF EXISTS user_stats');
                await customStatement(
                    'ALTER TABLE new_user_stats RENAME TO user_stats');
              } finally {
                await customStatement('PRAGMA foreign_keys = ON');
              }
            },
            from11To12: (m, schema) async {
              await customStatement('PRAGMA foreign_keys = OFF');

              try {
                // Step 1: Check if beans_uuid column exists
                final columns =
                    await customSelect("PRAGMA table_info('coffee_beans')")
                        .get();
                final beansUuidExists = columns
                    .any((column) => column.data['name'] == 'beans_uuid');

                // Step 2: Add beans_uuid column if it doesn't exist
                if (!beansUuidExists) {
                  await customStatement(
                      'ALTER TABLE coffee_beans ADD COLUMN beans_uuid TEXT');
                }

                // Step 3: Generate and update UUIDs for rows that need them
                final rows = await customSelect(
                        'SELECT id FROM coffee_beans WHERE beans_uuid IS NULL')
                    .get();

                for (final row in rows) {
                  final id = row.data['id'] as int;
                  final newUuid =
                      _generateUuidV7(); // Your Dart method to generate UUID
                  await customUpdate(
                    'UPDATE coffee_beans SET beans_uuid = ? WHERE id = ?',
                    variables: [
                      Variable.withString(newUuid),
                      Variable.withInt(id)
                    ],
                  );
                }

                // Step 4: Create new table with desired structure
                await customStatement('''
      CREATE TABLE IF NOT EXISTS new_coffee_beans (
        beans_uuid TEXT NOT NULL PRIMARY KEY,
        id INTEGER,
        roaster TEXT NOT NULL,
        name TEXT NOT NULL,
        origin TEXT NOT NULL,
        variety TEXT,
        tasting_notes TEXT,
        processing_method TEXT,
        elevation INTEGER,
        harvest_date INTEGER,
        roast_date INTEGER,
        region TEXT,
        roast_level TEXT,
        cupping_score REAL,
        notes TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0 CHECK (is_favorite IN (0, 1))
      )
    ''');

                // Step 5: Copy data to new table
                await customStatement('''
      INSERT OR REPLACE INTO new_coffee_beans
      SELECT
        beans_uuid,
        id, roaster, name, origin, variety, tasting_notes,
        processing_method, elevation, harvest_date, roast_date, region,
        roast_level, cupping_score, notes, is_favorite
      FROM coffee_beans
    ''');

                // Step 6: Replace old table with new one
                await customStatement('DROP TABLE IF EXISTS coffee_beans');
                await customStatement(
                    'ALTER TABLE new_coffee_beans RENAME TO coffee_beans');
              } finally {
                await customStatement('PRAGMA foreign_keys = ON');
              }
            },
            from12To13: (m, schema) async {
              // Check if version_vector column exists
              final columns =
                  await customSelect("PRAGMA table_info('user_stats')").get();
              final versionVectorExists = columns
                  .any((column) => column.data['name'] == 'version_vector');

              if (!versionVectorExists) {
                await customStatement('''
      ALTER TABLE user_stats
      ADD COLUMN version_vector TEXT
      DEFAULT '{"deviceId":"legacy","version":0}'
    ''');
              }

              await customStatement('''
    UPDATE user_stats
    SET version_vector = '{"deviceId":"legacy","version":0}'
    WHERE version_vector IS NULL
  ''');

              await customStatement('''
    CREATE INDEX IF NOT EXISTS idx_user_stats_stat_uuid_version_vector
    ON user_stats (stat_uuid, version_vector)
  ''');
            },
            from13To14: (m, schema) async {
              await customStatement('BEGIN TRANSACTION');
              try {
                // Check if version_vector column exists
                final columns =
                    await customSelect("PRAGMA table_info('coffee_beans')")
                        .get();
                final versionVectorExists = columns
                    .any((column) => column.data['name'] == 'version_vector');

                if (!versionVectorExists) {
                  await customStatement('''
        ALTER TABLE coffee_beans
        ADD COLUMN version_vector TEXT
        DEFAULT '{"deviceId":"legacy","version":0}'
      ''');
                }

                await customStatement('''
      UPDATE coffee_beans
      SET version_vector = '{"deviceId":"legacy","version":0}'
      WHERE version_vector IS NULL
    ''');

                await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_coffee_beans_beans_uuid_version_vector
      ON coffee_beans (beans_uuid, version_vector)
    ''');

                await customStatement('COMMIT');
              } catch (e) {
                await customStatement('ROLLBACK');
                rethrow;
              }
            },
            from14To15: (m, schema) async {
              await customStatement('PRAGMA busy_timeout = 30000');
              await customStatement('BEGIN TRANSACTION');
              try {
                // Check if beans_uuid column exists in coffee_beans
                final coffeeBeansColumns =
                    await customSelect("PRAGMA table_info('coffee_beans')")
                        .get();
                final beansUuidExists = coffeeBeansColumns
                    .any((column) => column.data['name'] == 'beans_uuid');

                if (!beansUuidExists) {
                  await customStatement(
                      'ALTER TABLE coffee_beans ADD COLUMN beans_uuid TEXT');
                }

                // Generate UUIDs for any rows without beans_uuid
                final coffeeBeansRows = await customSelect(
                        'SELECT id FROM coffee_beans WHERE beans_uuid IS NULL')
                    .get();
                for (final row in coffeeBeansRows) {
                  final id = row.data['id'] as int;
                  final newUuid =
                      _generateUuidV7(); // Your Dart method to generate UUID
                  await customUpdate(
                    'UPDATE coffee_beans SET beans_uuid = ? WHERE id = ?',
                    variables: [
                      Variable.withString(newUuid),
                      Variable.withInt(id)
                    ],
                  );
                }

                // Check if coffee_beans_uuid column exists in user_stats
                final userStatsColumns =
                    await customSelect("PRAGMA table_info('user_stats')").get();
                final coffeeBeansUuidExists = userStatsColumns.any(
                    (column) => column.data['name'] == 'coffee_beans_uuid');

                if (!coffeeBeansUuidExists) {
                  await customStatement(
                      'ALTER TABLE user_stats ADD COLUMN coffee_beans_uuid TEXT');
                }

                // Update user_stats with corresponding coffee_beans UUIDs
                await customStatement('''
      UPDATE user_stats
      SET coffee_beans_uuid = (
        SELECT beans_uuid
        FROM coffee_beans
        WHERE coffee_beans.id = user_stats.coffee_beans_id
      )
      WHERE coffee_beans_id IS NOT NULL AND coffee_beans_uuid IS NULL
    ''');

                await customStatement('COMMIT');
              } catch (e) {
                await customStatement('ROLLBACK');
                print('Migration failed: $e');
                rethrow;
              }
            },
            from15To16: (m, schema) async {
              await m.addColumn(userStats, userStats.isDeleted);
            },
            from16To17: (m, schema) async {
              await m.addColumn(coffeeBeans, coffeeBeans.isDeleted);
            },
            from17To18: (m, schema) async {
              await m.addColumn(userRecipePreferences,
                  userRecipePreferences.coffeeChroniclerSliderPosition);
            },
            from18To19: (m, schema) async {
              await m.alterTable(TableMigration(schema.recipes));
            },
            from19To20: (m, schema) async {
              // Drop the vendors table
              await customStatement('DROP TABLE IF EXISTS vendors');
            },
            from20To21: (m, schema) async {
              await m.addColumn(recipes, recipes.importId);
              await m.addColumn(recipes, recipes.isImported);
            },
            // Add migration from 21 to 22
            from21To22: (m, schema) async {
              // Correctly reference the column from the schema object
              await m.addColumn(
                  schema.recipes, schema.recipes.needsModerationReview);
            },
            from22To23: (m, schema) async {
              await m.alterTable(TableMigration(schema.userStats));
            },
            from23To24: (m, schema) async {
              // Migration for removing showOnMain from BrewingMethods.
              await m.dropColumn(schema.brewingMethods, 'show_on_main');
            },
            from24To25: (m, schema) async {
              // Remove Contributors table
              await customStatement('DROP TABLE IF EXISTS contributors');
            },
            from25To26: (m, schema) async {
              await m.addColumn(schema.coffeeBeans, schema.coffeeBeans.farmer);
              await m.addColumn(schema.coffeeBeans, schema.coffeeBeans.farm);
            },

            // Phase B migration: remove launch_popups table and index
            from26To27: (m, schema) async {
              // Use custom statements to safely drop index and table if present
              await customStatement(
                  'DROP INDEX IF EXISTS idx_launch_popups_created_at');
              await customStatement('DROP TABLE IF EXISTS launch_popups');
            },
          )(m, oldVersion, newVersion);
        },
        onCreate: (m) async {
          await m.createAll();
        },
      );
}

DatabaseConnection _openConnection() {
  return DatabaseConnection.delayed(connect());
}
