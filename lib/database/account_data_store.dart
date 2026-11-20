import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../utils/app_logger.dart';
import 'account_database_scope.dart';
import 'database.dart';

/// Owns the databases for this running installation. A database and its
/// providers stay bound to their original account even during an auth change.
class AccountDataStore {
  AccountDataStore({
    required this.auth,
    required this.prefs,
    required this.supabaseUrl,
    required this.supabaseKey,
    AppDatabase Function(AccountDatabaseScope)? databaseFactory,
  }) : _databaseFactory = databaseFactory ?? _openDatabase;

  final GoTrueClient auth;
  final SharedPreferences prefs;
  final String supabaseUrl;
  final String supabaseKey;
  final AppDatabase Function(AccountDatabaseScope) _databaseFactory;
  final _databases = <String, AppDatabase>{};
  static const _offlineKey = 'accountDataGuestPartition';
  static const _offlineHandoffPrefix = 'accountDataGuestHandoff.';
  static const _verifiedHandoffPrefix = 'accountDataVerifiedGuestHandoff.';
  Future<void>? _anonymousStartup;

  static AppDatabase _openDatabase(AccountDatabaseScope scope) =>
      AppDatabase.withDefault(accountScope: scope);

  String? get currentUserId => auth.currentSession?.user.id;

  AppDatabase openAccount(String userId) => _open('user:$userId', userId);

  Future<AppDatabase> openCurrent() async {
    final user = auth.currentSession?.user;
    if (user != null) {
      if (user.isAnonymous) {
        // Auth emits the new session before the startup call returns. Wait for
        // that call to bind the offline partition before mounting the guest.
        await _anonymousStartup;
      }
      await _restoreOfflinePartition(user.id);
      for (final key in prefs.getKeys().where(
        (key) => key.startsWith(_verifiedHandoffPrefix),
      )) {
        if (prefs.getString(key) != user.id) continue;
        try {
          await _restoreVerifiedGuest(
            key.substring(_verifiedHandoffPrefix.length),
            user.id,
          );
        } catch (error) {
          AppLogger.warning('Could not restore verified guest data', errorObject: error);
        }
      }
      // Never reuse the previous signed-out interval after a sign-in.
      if (currentUserId == user.id) await prefs.remove(_offlineKey);
      return openAccount(user.id);
    }
    var partitionId = prefs.getString(_offlineKey);
    if (partitionId == null || _isClaimedOfflinePartition(partitionId)) {
      partitionId = 'offline:${const Uuid().v4()}';
      await prefs.setString(_offlineKey, partitionId);
    }
    return _open(partitionId, null);
  }

  bool _isClaimedOfflinePartition(String partitionId) => prefs.getKeys().any(
    (key) =>
        key.startsWith(_offlineHandoffPrefix) &&
        prefs.getString(key) == partitionId,
  );

  Future<void> startAnonymousSession() => _anonymousStartup ??=
      _claimOfflinePartition().whenComplete(() => _anonymousStartup = null);

  Future<void> _claimOfflinePartition() async {
    if (currentUserId != null) return;
    final result = await auth.signInAnonymously();
    final user = result.user;
    // The bounded startup wait can expire while guest creation is in flight.
    // At that point the app may have opened an offline partition already.
    final offlinePartition = prefs.getString(_offlineKey);
    if (user == null ||
        !user.isAnonymous ||
        currentUserId != user.id ||
        offlinePartition == null ||
        _isClaimedOfflinePartition(offlinePartition)) {
      return;
    }

    // Only this fresh guest can recover the offline rows, including if this
    // process exits before copying finishes.
    final saved = await prefs.setString(
      '$_offlineHandoffPrefix${user.id}',
      offlinePartition,
    );
    if (!saved) throw StateError('Could not persist the offline handoff');
  }

  Future<void> _restoreOfflinePartition(String guestUserId) async {
    final key = '$_offlineHandoffPrefix$guestUserId';
    final partition = prefs.getString(key);
    if (partition == null) return;
    await copyAccountData(
      source: _open(partition, null),
      destination: openAccount(guestUserId),
      sourceUserId: partition,
      destinationUserId: guestUserId,
      includePrivateRows: true,
    );
    if (prefs.getString(_offlineKey) == partition &&
        !await prefs.remove(_offlineKey)) {
      throw StateError('Could not retire the previous offline partition');
    }
    await prefs.remove(key);
  }

  AppDatabase _open(String partitionId, String? userId) =>
      _databases.putIfAbsent(
        partitionId,
        () => _databaseFactory(
          AccountDatabaseScope(
            userId: userId,
            partitionId: partitionId,
            supabaseUrl: supabaseUrl,
            supabaseKey: supabaseKey,
            currentSession: () => auth.currentSession,
          ),
        ),
      );

  /// The old database has no owners for beans, brews or recipe preferences.
  /// Keep their original file intact and recover only explicitly owned recipes.
  Future<void> recoverLegacyRecipes(String userId) async {
    final key = 'legacyRecipesRecovered.$userId';
    if (prefs.getBool(key) == true) return;
    final legacy = AppDatabase.withDefault();
    try {
      await copyAccountData(
        source: legacy,
        destination: openAccount(userId),
        sourceUserId: userId,
        destinationUserId: userId,
        includePrivateRows: false,
      );
      await prefs.setBool(key, true);
    } catch (error) {
      AppLogger.warning('Could not recover legacy recipes', errorObject: error);
    } finally {
      await legacy.close();
    }
  }

  /// Carries a fully scoped guest partition to the destination authenticated by
  /// the account migration service. The source stays intact for retry/recovery.
  Future<void> migrateVerifiedGuest(
    String sourceUserId,
    String destinationUserId,
  ) async {
    if (sourceUserId == destinationUserId) return;
    final pendingKey = '$_verifiedHandoffPrefix$sourceUserId';
    if (prefs.containsKey('accountDataMigrated.$sourceUserId')) return;
    final pendingDestination = prefs.getString(pendingKey);
    if (pendingDestination != null && pendingDestination != destinationUserId) {
      throw StateError('Guest handoff already belongs to another destination');
    }
    if (!await prefs.setString(pendingKey, destinationUserId)) {
      throw StateError('Could not persist the verified guest handoff');
    }
    await _restoreVerifiedGuest(sourceUserId, destinationUserId);
  }

  Future<void> _restoreVerifiedGuest(
    String sourceUserId,
    String destinationUserId,
  ) async {
    final pendingKey = '$_verifiedHandoffPrefix$sourceUserId';
    final completedKey = 'accountDataMigrated.$sourceUserId';
    if (prefs.getString(pendingKey) != destinationUserId) return;
    if (prefs.getString(completedKey) == destinationUserId) {
      await prefs.remove(pendingKey);
      return;
    }
    await recoverLegacyRecipes(sourceUserId);
    await copyAccountData(
      source: openAccount(sourceUserId),
      destination: openAccount(destinationUserId),
      sourceUserId: sourceUserId,
      destinationUserId: destinationUserId,
      includePrivateRows: true,
    );
    if (!await prefs.setString(completedKey, destinationUserId)) {
      throw StateError('Could not persist the completed guest handoff');
    }
    await prefs.remove(pendingKey);
  }
}

/// Copy data in a single destination transaction. Recipe dependencies are
/// selected from the same source snapshot. Only a proven partition can supply
/// ownerless rows, and only its own custom recipes can be renamed.
Future<void> copyAccountData({
  required AppDatabase source,
  required AppDatabase destination,
  required String sourceUserId,
  required String destinationUserId,
  required bool includePrivateRows,
}) async {
  final sourceVendor = 'usr-$sourceUserId';
  final destinationVendor = 'usr-$destinationUserId';
  final isOfflineSource =
      includePrivateRows &&
      source.accountScope?.userId == null &&
      source.accountScope?.partitionId == sourceUserId &&
      sourceUserId.startsWith('offline:');
  const legacyOfflineVendor = 'usr-anonymous';
  await source.transaction(() async {
    final brews = includePrivateRows
        ? await source.select(source.userStats).get()
        : <UserStat>[];
    final beans = includePrivateRows
        ? await source.select(source.coffeeBeans).get()
        : <CoffeeBean>[];
    final preferences = includePrivateRows
        ? await source.select(source.userRecipePreferences).get()
        : <UserRecipePreference>[];
    final referencedIds = {
      ...brews.map((brew) => brew.recipeId),
      ...preferences.map((pref) => pref.recipeId),
    };
    final recipes =
        await (source.select(source.recipes)..where(
              (table) =>
                  table.vendorId.equals(sourceVendor) |
                  (isOfflineSource
                      ? table.id.like('$legacyOfflineVendor-%') &
                            (table.vendorId.isNull() |
                                table.vendorId.equals(legacyOfflineVendor))
                      : const Constant(false)) |
                  table.id.isIn(referencedIds),
            ))
            .get();
    final ids = <String, String>{};
    final recipesToCopy = <Recipe>[];
    for (final recipe in recipes) {
      final isScopedOwner =
          recipe.vendorId == sourceVendor &&
          recipe.id.startsWith('$sourceVendor-');
      final isLegacyOfflineOwner =
          isOfflineSource &&
          recipe.id.startsWith('$legacyOfflineVendor-') &&
          (recipe.vendorId == null || recipe.vendorId == legacyOfflineVendor);
      final isOwned = isScopedOwner || isLegacyOfflineOwner;
      final originalVendor = isLegacyOfflineOwner
          ? legacyOfflineVendor
          : sourceVendor;
      if (!isOwned &&
          (!includePrivateRows ||
              (recipe.id.startsWith('usr-') && !recipe.isPublic))) {
        continue;
      }
      final newId = isOwned && sourceUserId != destinationUserId
          ? '$destinationVendor${recipe.id.substring(originalVendor.length)}'
          : recipe.id;
      ids[recipe.id] = newId;
      recipesToCopy.add(
        recipe.copyWith(
          id: newId,
          vendorId: isOwned ? Value(destinationVendor) : Value(recipe.vendorId),
          lastModified: newId == recipe.id
              ? Value(recipe.lastModified)
              : Value(DateTime.now().toUtc()),
        ),
      );
    }

    final steps = await (source.select(
      source.steps,
    )..where((table) => table.recipeId.isIn(ids.keys))).get();
    final localizations = await (source.select(
      source.recipeLocalizations,
    )..where((table) => table.recipeId.isIn(ids.keys))).get();
    final methods = await source.select(source.brewingMethods).get();
    final locales = await source.select(source.supportedLocales).get();

    await destination.batch((batch) {
      const mode = InsertMode.insertOrIgnore;
      batch.insertAll(destination.brewingMethods, methods, mode: mode);
      batch.insertAll(destination.supportedLocales, locales, mode: mode);
      batch.insertAll(destination.recipes, recipesToCopy, mode: mode);
      batch.insertAll(
        destination.steps,
        steps.map((step) => step.copyWith(recipeId: ids[step.recipeId]!)),
        mode: mode,
      );
      batch.insertAll(
        destination.recipeLocalizations,
        localizations.map((loc) => loc.copyWith(recipeId: ids[loc.recipeId]!)),
        mode: mode,
      );
      batch.insertAll(destination.coffeeBeans, beans, mode: mode);
      batch.insertAll(
        destination.userStats,
        brews
            .where((brew) => ids.containsKey(brew.recipeId))
            .map((brew) => brew.copyWith(recipeId: ids[brew.recipeId]!)),
        mode: mode,
      );
      batch.insertAll(
        destination.userRecipePreferences,
        preferences
            .where((pref) => ids.containsKey(pref.recipeId))
            .map((pref) => pref.copyWith(recipeId: ids[pref.recipeId]!)),
        mode: mode,
      );
    });
  });
}
