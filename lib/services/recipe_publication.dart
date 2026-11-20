import 'package:drift/drift.dart' as drift;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/network_timeouts.dart';
import '../database/database.dart';
import '../utils/app_logger.dart';

bool ownsUserRecipe(String id, String? vendorId, String? userId) =>
    userId != null &&
    vendorId == 'usr-$userId' &&
    id.startsWith('usr-$userId-');

String? localRecipeOwner(AppDatabase? db, String? userId) {
  final scope = db?.accountScope;
  if (scope == null) return userId;
  if (!scope.isActive) return null;
  if (scope.userId == null) return userId == null ? 'anonymous' : null;
  return scope.userId == userId ? userId : null;
}

String importedRecipeId(String userId, String sourceRecipeId) =>
    'usr-$userId-${const Uuid().v5(Namespace.url.value, sourceRecipeId).replaceAll('-', '')}';

bool isExactImportedRecipe(String recipeId, String userId, String sourceId) {
  final base = importedRecipeId(userId, sourceId);
  return recipeId == base || recipeId.startsWith('$base-');
}

class PendingRecipeWithdrawal implements Exception {
  const PendingRecipeWithdrawal();
}

String pendingRecipeWithdrawalPrefix(String userId) =>
    'pendingRecipeWithdrawal:$userId:';

String pendingRecipeWithdrawalKey(String userId, String recipeId) =>
    '${pendingRecipeWithdrawalPrefix(userId)}$recipeId';

/// Updates the local audience only after the owner's remote row confirms it.
Future<bool> confirmRecipeWithdrawal(
  AppDatabase db,
  SupabaseClient client,
  String userId,
  String recipeId,
) async {
  User? currentUser() => db.accountScope == null
      ? client.auth.currentUser
      : db.accountScope!.currentUser;
  if (currentUser()?.id != userId || !recipeId.startsWith('usr-$userId-')) {
    return false;
  }

  try {
    final row = await client
        .from('user_recipes')
        .update({
          'ispublic': false,
          'last_modified': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', recipeId)
        .eq('vendor_id', 'usr-$userId')
        .select('ispublic')
        .maybeSingle()
        .timeout(NetworkTimeouts.handshake);
    if (currentUser()?.id != userId || row?['ispublic'] != false) {
      return false;
    }

    await db.recipesDao.updateRecipe(
      recipeId,
      const RecipesCompanion(isPublic: drift.Value(false)),
    );
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(pendingRecipeWithdrawalKey(userId, recipeId));
  } catch (error) {
    AppLogger.warning('Recipe withdrawal is pending', errorObject: error);
    return false;
  }
}
