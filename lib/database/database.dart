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
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';
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

@TableIndex(
    name: 'idx_user_stats_stat_uuid_version_vector',
    columns: {#statUuid, #versionVector})
class UserStats extends Table {
  TextColumn get statUuid => text().named('stat_uuid')();
  IntColumn get id => integer().named('id').nullable()();
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
  TextColumn get coffeeBeansUuid =>
      text().named('coffee_beans_uuid').nullable()();
  TextColumn get versionVector => text().named('version_vector')();

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
  BoolColumn get isFavorite =>
      boolean().named('is_favorite').withDefault(const Constant(false))();
  TextColumn get versionVector => text().named('version_vector')();

  @override
  Set<Column> get primaryKey => {beansUuid};
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
  final Uuid _uuid = Uuid();

  AppDatabase({this.enableForeignKeyConstraints = true})
      : super(_openConnection());

  @override
  int get schemaVersion => 14;

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
            from7To8: (m, schema) async {
              // Add beansUuid column to CoffeeBeans table
              await m.addColumn(coffeeBeans, coffeeBeans.beansUuid);

              // Add coffeeBeansUuid column to UserStats table
              await m.addColumn(userStats, userStats.coffeeBeansUuid);
            },
            from8To9: (m, schema) async {
              // Add stat_uuid column to UserStats table as nullable
              await customStatement(
                  'ALTER TABLE user_stats ADD COLUMN stat_uuid TEXT');
            },
            from9To10: (m, schema) async {
              await m.dropColumn(userStats, 'user_id');
            },
            from10To11: (m, schema) async {
              // Temporarily disable foreign key constraints
              await customStatement('PRAGMA foreign_keys = OFF');

              // Check if stat_uuid column exists and if it's already the primary key
              final columns =
                  await customSelect("PRAGMA table_info('user_stats')").get();
              final statUuidColumn = columns.firstWhereOrNull(
                (column) => column.data['name'] == 'stat_uuid',
              );

              if (statUuidColumn == null) {
                // If stat_uuid doesn't exist, add it as a nullable column first
                await customStatement(
                    'ALTER TABLE user_stats ADD COLUMN stat_uuid TEXT');
              }

              final isPrimaryKey =
                  statUuidColumn != null && statUuidColumn.data['pk'] == 1;

              if (!isPrimaryKey) {
                // Generate UUIDs for any NULL stat_uuid values
                final rows = await customSelect(
                        'SELECT id FROM user_stats WHERE stat_uuid IS NULL')
                    .get();
                for (final row in rows) {
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

                // Create a new table with the desired structure
                await customStatement('''
      CREATE TABLE new_user_stats (
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

                // Copy data from the old table to the new one, providing a default value for created_at
                await customStatement('''
      INSERT INTO new_user_stats 
      SELECT 
        stat_uuid, 
        id, 
        recipe_id, 
        coffee_amount, 
        water_amount, 
        sweetness_slider_position, 
        strength_slider_position, 
        brewing_method_id, 
        COALESCE(created_at, CAST(strftime('%s', 'now') AS INTEGER)) as created_at, 
        notes, 
        beans, 
        roaster, 
        rating, 
        coffee_beans_id, 
        is_marked, 
        coffee_beans_uuid
      FROM user_stats
    ''');

                // Drop the old table
                await customStatement('DROP TABLE user_stats');

                // Rename the new table to the original name
                await customStatement(
                    'ALTER TABLE new_user_stats RENAME TO user_stats');
              }

              // Re-enable foreign key constraints
              await customStatement('PRAGMA foreign_keys = ON');
            },
            from11To12: (m, schema) async {
              // Temporarily disable foreign key constraints
              await customStatement('PRAGMA foreign_keys = OFF');

              // Check if beansUuid column exists and if it's already the primary key
              final columns =
                  await customSelect("PRAGMA table_info('coffee_beans')").get();
              final beansUuidColumn = columns.firstWhereOrNull(
                (column) => column.data['name'] == 'beans_uuid',
              );

              if (beansUuidColumn == null) {
                // If beansUuid doesn't exist, add it as a nullable column first
                await customStatement(
                    'ALTER TABLE coffee_beans ADD COLUMN beans_uuid TEXT');
              }

              final isPrimaryKey =
                  beansUuidColumn != null && beansUuidColumn.data['pk'] == 1;

              if (!isPrimaryKey) {
                // Generate UUIDs for any NULL beansUuid values
                final rows = await customSelect(
                        'SELECT id FROM coffee_beans WHERE beans_uuid IS NULL')
                    .get();
                for (final row in rows) {
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

                // Create a new table with the desired structure
                await customStatement('''
            CREATE TABLE new_coffee_beans (
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

                // Copy data from the old table to the new one
                await customStatement('''
            INSERT INTO new_coffee_beans 
            SELECT 
              beans_uuid,
              id,
              roaster,
              name,
              origin,
              variety,
              tasting_notes,
              processing_method,
              elevation,
              harvest_date,
              roast_date,
              region,
              roast_level,
              cupping_score,
              notes,
              is_favorite
            FROM coffee_beans
          ''');

                // Drop the old table
                await customStatement('DROP TABLE coffee_beans');

                // Rename the new table to the original name
                await customStatement(
                    'ALTER TABLE new_coffee_beans RENAME TO coffee_beans');
              }

              // Re-enable foreign key constraints
              await customStatement('PRAGMA foreign_keys = ON');
            },
            from12To13: (m, schema) async {
              // Step 1: Add version_vector column as nullable
              await customStatement(
                  'ALTER TABLE user_stats ADD COLUMN version_vector TEXT');

              // Step 2: Update existing rows with a default value
              await customStatement('''
    UPDATE user_stats
    SET version_vector = '{"deviceId":"legacy","version":0}'
    WHERE version_vector IS NULL
  ''');

              // Step 3: Alter the column to be NOT NULL
              // SQLite doesn't support directly changing a column to NOT NULL,
              // so we need to recreate the table

              // First, create a new table with the desired structure
              await customStatement('''
    CREATE TABLE new_user_stats (
      stat_uuid TEXT NOT NULL PRIMARY KEY,
      id INTEGER,
      recipe_id TEXT NOT NULL REFERENCES recipes(id),
      coffee_amount REAL NOT NULL,
      water_amount REAL NOT NULL,
      sweetness_slider_position INTEGER NOT NULL,
      strength_slider_position INTEGER NOT NULL,
      brewing_method_id TEXT NOT NULL REFERENCES brewing_methods(brewing_method_id),
      created_at INTEGER NOT NULL,
      notes TEXT,
      beans TEXT,
      roaster TEXT,
      rating REAL,
      coffee_beans_id INTEGER,
      is_marked INTEGER NOT NULL DEFAULT 0 CHECK (is_marked IN (0, 1)),
      coffee_beans_uuid TEXT,
      version_vector TEXT NOT NULL
    )
  ''');

              // Copy data from the old table to the new one
              await customStatement('''
    INSERT INTO new_user_stats 
    SELECT * FROM user_stats
  ''');

              // Drop the old table
              await customStatement('DROP TABLE user_stats');

              // Rename the new table to the original name
              await customStatement(
                  'ALTER TABLE new_user_stats RENAME TO user_stats');

              // Step 4: Create index on stat_uuid and version_vector
              await customStatement('''
    CREATE INDEX idx_user_stats_stat_uuid_version_vector 
    ON user_stats (stat_uuid, version_vector)
  ''');
            },
            from13To14: (m, schema) async {
              // Wrap the entire migration in a transaction
              await customStatement('BEGIN TRANSACTION');

              try {
                // Step 1: Check if version_vector column exists
                final columns =
                    await customSelect("PRAGMA table_info('coffee_beans')")
                        .get();
                final versionVectorExists = columns
                    .any((column) => column.data['name'] == 'version_vector');

                if (!versionVectorExists) {
                  // Add version_vector column as nullable if it doesn't exist
                  await customStatement(
                      'ALTER TABLE coffee_beans ADD COLUMN version_vector TEXT');
                }

                // Step 2: Update existing rows with a default value
                await customStatement('''
      UPDATE coffee_beans
      SET version_vector = '{"deviceId":"legacy","version":0}'
      WHERE version_vector IS NULL
    ''');

                // Step 3: Check if new_coffee_beans table exists and drop it if it does
                final tableExists = await customSelect(
                        "SELECT name FROM sqlite_master WHERE type='table' AND name='new_coffee_beans'")
                    .get();
                if (tableExists.isNotEmpty) {
                  await customStatement(
                      'DROP TABLE IF EXISTS new_coffee_beans');
                }

                // Step 4: Recreate the table with NOT NULL constraint
                await customStatement('''
      CREATE TABLE new_coffee_beans (
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
        is_favorite INTEGER NOT NULL DEFAULT 0 CHECK (is_favorite IN (0, 1)),
        version_vector TEXT NOT NULL
      )
    ''');

                // Step 5: Copy data from the old table to the new one, explicitly listing all columns
                await customStatement('''
      INSERT INTO new_coffee_beans (
        beans_uuid, id, roaster, name, origin, variety, tasting_notes, 
        processing_method, elevation, harvest_date, roast_date, region, 
        roast_level, cupping_score, notes, is_favorite, version_vector
      )
      SELECT 
        beans_uuid, id, roaster, name, origin, variety, tasting_notes, 
        processing_method, elevation, harvest_date, roast_date, region, 
        roast_level, cupping_score, notes, is_favorite, 
        COALESCE(version_vector, '{"deviceId":"legacy","version":0}')
      FROM coffee_beans
    ''');

                // Step 6: Drop the old table
                await customStatement('DROP TABLE coffee_beans');

                // Step 7: Rename the new table to the original name
                await customStatement(
                    'ALTER TABLE new_coffee_beans RENAME TO coffee_beans');

                // Step 8: Create index on beans_uuid and version_vector
                await customStatement('''
      CREATE INDEX idx_coffee_beans_beans_uuid_version_vector 
      ON coffee_beans (beans_uuid, version_vector)
    ''');

                // If everything succeeded, commit the transaction
                await customStatement('COMMIT');
              } catch (e) {
                // If anything went wrong, roll back the changes
                await customStatement('ROLLBACK');
                rethrow; // Re-throw the exception after rolling back
              }
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
