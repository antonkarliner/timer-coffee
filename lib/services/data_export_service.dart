import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/database.dart';
import '../models/coffee_beans_model.dart';
import '../models/user_stat_model.dart';
import '../utils/app_logger.dart';
import '../utils/input_validator.dart';

/// Maximum serialized size (bytes) of the local dump the `export-user-data`
/// edge function will accept. Mirrors the backend's 5 MB cap (plan 035,
/// Phase 2) so an oversized payload is rejected client-side instead of making
/// a doomed round-trip.
const int kDataExportMaxPayloadBytes = 5 * 1024 * 1024;

// ---------------------------------------------------------------------------
// Result types
// ---------------------------------------------------------------------------

/// Outcome of a `request` or `confirm` call to the `export-user-data` edge
/// function. Carries no user-facing strings by design — this service owns no
/// localization; Phase 4's UI is responsible for mapping each case to
/// localized copy.
sealed class DataExportResult {
  const DataExportResult();
}

/// The action completed: either the code was sent, or the export was
/// triggered and an email with the download link is on its way.
class DataExportSuccess extends DataExportResult {
  const DataExportSuccess();
}

/// The email address failed validation; no request was made (or the backend
/// rejected it as malformed).
class DataExportInvalidEmail extends DataExportResult {
  const DataExportInvalidEmail();
}

/// Too many requests. Covers both the per-user/per-email 24h cap on
/// `request` and the max-attempts lockout on `confirm` — the backend
/// responds with HTTP 429 in both cases.
class DataExportRateLimited extends DataExportResult {
  const DataExportRateLimited();
}

/// The submitted code did not match the active request.
/// [attemptsRemaining] is populated when the backend reports it.
class DataExportIncorrectCode extends DataExportResult {
  const DataExportIncorrectCode({this.attemptsRemaining});

  final int? attemptsRemaining;
}

/// No active (unconsumed, unexpired) code request exists for this user —
/// e.g. the code expired, was already consumed, or none was ever requested.
class DataExportExpiredOrNoRequest extends DataExportResult {
  const DataExportExpiredOrNoRequest();
}

/// The assembled local dump exceeds the backend's size cap. Returned either
/// client-side (before the call is made) or after the backend rejects it.
class DataExportPayloadTooLarge extends DataExportResult {
  const DataExportPayloadTooLarge();
}

/// A network/timeout failure talking to the edge function (no HTTP response
/// to interpret).
class DataExportNetworkError extends DataExportResult {
  const DataExportNetworkError();
}

/// Anything else unexpected — an HTTP error whose shape/status didn't match
/// any known case.
class DataExportUnknownError extends DataExportResult {
  const DataExportUnknownError();
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Assembles the user's local Drift data for the self-serve data-export flow
/// (plan 035) and drives the two-step `export-user-data` edge function:
/// request a one-time code, then confirm it (which bundles the local dump
/// with the request so the backend can merge it with the user's remote
/// data).
///
/// This service owns no UI or localized strings by design: every outcome is
/// a typed [DataExportResult] so Phase 4's UI layer can localize each case.
class DataExportService {
  DataExportService({required AppDatabase database, SupabaseClient? client})
    : _database = database,
      _clientOverride = client;

  final AppDatabase _database;
  final SupabaseClient? _clientOverride;

  /// Resolved lazily so constructing this service never requires Supabase to
  /// be initialized (useful for tests that only exercise [buildLocalDump]).
  SupabaseClient get _client => _clientOverride ?? Supabase.instance.client;

  static const String _functionName = 'export-user-data';

  /// Reads every user-content Drift table and returns a JSON-safe bundle
  /// matching the shape the `export-user-data` edge function expects:
  /// `brews`, `beans`, `recipePreferences`, `customRecipes`, `recipeSteps`,
  /// `recipeLocalizations`, plus empty arrays for the entities that have no
  /// local equivalent (`publicProfile`, `reviews`, `reviewReplies`).
  ///
  /// Excludes catalog/reference data — the shipped recipe catalog, brewing
  /// methods, supported locales, coffee facts, help content, and recipe
  /// collections are never user-owned and are never included. Custom
  /// recipes are identified by the `usr-` id prefix (mirrors
  /// [RecipesDao.getUserRecipes], the same convention the backend uses via
  /// `vendor_id = 'usr-{user_id}'`); their steps and localizations are
  /// filtered to match so the catalog's steps/localizations never leak in.
  Future<Map<String, dynamic>> buildLocalDump() async {
    final beans = await _database.coffeeBeansDao.fetchAllCoffeeBeans();
    final stats = await _database.userStatsDao.fetchAllStats();
    final preferences = await _database
        .select(_database.userRecipePreferences)
        .get();

    // Custom (user-created) recipes only — never the shipped catalog.
    final customRecipes = await _database.recipesDao.getUserRecipes();
    final customRecipeIds = customRecipes.map((r) => r.id).toList();

    List<Step> steps = const [];
    List<RecipeLocalization> localizations = const [];
    if (customRecipeIds.isNotEmpty) {
      steps = await (_database.select(
        _database.steps,
      )..where((t) => t.recipeId.isIn(customRecipeIds))).get();
      localizations = await (_database.select(
        _database.recipeLocalizations,
      )..where((t) => t.recipeId.isIn(customRecipeIds))).get();
    }

    return {
      'brews': stats.map(_userStatToJson).toList(),
      'beans': beans.map(_coffeeBeanToJson).toList(),
      'recipePreferences': preferences.map(_recipePreferenceToJson).toList(),
      'customRecipes': customRecipes.map(_recipeToJson).toList(),
      'recipeSteps': steps.map(_stepToJson).toList(),
      'recipeLocalizations': localizations
          .map(_recipeLocalizationToJson)
          .toList(),
      // No local equivalent for these — the backend fills them in remotely,
      // scoped to the verified JWT user_id.
      'publicProfile': const [],
      'reviews': const [],
      'reviewReplies': const [],
    };
  }

  /// Requests a 6-digit OTP be emailed to [email]. Validates the address
  /// client-side first (cheap guard; the backend validates too).
  Future<DataExportResult> requestCode(String email) async {
    final trimmed = email.trim();
    if (!InputValidator.isValidEmail(trimmed)) {
      return const DataExportInvalidEmail();
    }

    try {
      await _client.functions.invoke(
        _functionName,
        body: {'action': 'request', 'email': trimmed},
      );
      return const DataExportSuccess();
    } on FunctionException catch (error) {
      return _resultFromException(error);
    } catch (error) {
      AppLogger.error(
        'export-user-data request failed',
        errorObject: AppLogger.sanitize(error),
      );
      return const DataExportNetworkError();
    }
  }

  /// Confirms [code], assembling the local dump and sending it along so the
  /// backend can merge it with the user's remote data and email a download
  /// link. Guards the payload size client-side before making the call.
  Future<DataExportResult> confirmAndSend(String code) async {
    final trimmedCode = code.trim();

    final Map<String, dynamic> localData;
    try {
      localData = await buildLocalDump();
    } catch (error) {
      AppLogger.error(
        'Failed to assemble local export dump',
        errorObject: AppLogger.sanitize(error),
      );
      return const DataExportUnknownError();
    }

    final serializedSize = utf8.encode(jsonEncode(localData)).length;
    if (serializedSize > kDataExportMaxPayloadBytes) {
      return const DataExportPayloadTooLarge();
    }

    try {
      await _client.functions.invoke(
        _functionName,
        body: {
          'action': 'confirm',
          'code': trimmedCode,
          'localData': localData,
        },
      );
      return const DataExportSuccess();
    } on FunctionException catch (error) {
      return _resultFromException(error);
    } catch (error) {
      AppLogger.error(
        'export-user-data confirm failed',
        errorObject: AppLogger.sanitize(error),
      );
      return const DataExportNetworkError();
    }
  }

  // ---------------------------------------------------------------------
  // Error mapping
  // ---------------------------------------------------------------------

  /// Maps a [FunctionException] (thrown by `functions.invoke` for any
  /// non-2xx response) to a typed [DataExportResult]. The backend's exact
  /// error strings are only fully specified for the "incorrect code" case
  /// (`{error: "Incorrect code.", attemptsRemaining: N}`); other 400s
  /// (expired / already consumed / no active request) are distinguished by
  /// best-effort message matching, falling back to
  /// [DataExportExpiredOrNoRequest] for confirm-shaped 400s that don't match
  /// anything more specific.
  DataExportResult _resultFromException(FunctionException error) {
    final details = error.details;
    final Map<String, dynamic>? body = details is Map
        ? Map<String, dynamic>.from(details)
        : null;
    final message = (body?['error'] as String?)?.toLowerCase() ?? '';

    // 429 covers both the request-side 24h rate limit and the confirm-side
    // max-attempts lockout.
    if (error.status == 429) {
      return const DataExportRateLimited();
    }

    if (body != null && body.containsKey('attemptsRemaining')) {
      final remaining = body['attemptsRemaining'];
      return DataExportIncorrectCode(
        attemptsRemaining: remaining is int
            ? remaining
            : int.tryParse('$remaining'),
      );
    }

    if (message.contains('incorrect')) {
      return const DataExportIncorrectCode();
    }

    if (error.status == 413 ||
        message.contains('large') ||
        message.contains('size')) {
      return const DataExportPayloadTooLarge();
    }

    if (message.contains('email')) {
      return const DataExportInvalidEmail();
    }

    if (error.status == 400) {
      return const DataExportExpiredOrNoRequest();
    }

    return const DataExportUnknownError();
  }

  // ---------------------------------------------------------------------
  // Row -> JSON-safe map conversions
  //
  // Keys are snake_case to match the remote Supabase column names (see
  // lib/database/extensions.dart for the same convention), which is what
  // the backend's per-row PK dedupe relies on, though it tolerates
  // camelCase as a fallback.
  // ---------------------------------------------------------------------

  Map<String, dynamic> _userStatToJson(UserStatsModel stat) => {
    'stat_uuid': stat.statUuid,
    'id': stat.id,
    'recipe_id': stat.recipeId,
    'coffee_amount': stat.coffeeAmount,
    'water_amount': stat.waterAmount,
    'sweetness_slider_position': stat.sweetnessSliderPosition,
    'strength_slider_position': stat.strengthSliderPosition,
    'brewing_method_id': stat.brewingMethodId,
    'created_at': stat.createdAt.toUtc().toIso8601String(),
    'notes': stat.notes,
    'beans': stat.beans,
    'roaster': stat.roaster,
    'rating': stat.rating,
    'coffee_beans_id': stat.coffeeBeansId,
    'is_marked': stat.isMarked,
    'coffee_beans_uuid': stat.coffeeBeansUuid,
    'grind_size': stat.grindSize,
    'tds_percent': stat.tdsPercent,
    'extraction_yield_percent': stat.extractionYieldPercent,
    'water_temp': stat.waterTemp,
    'taste_balance': stat.tasteBalance,
    'entry_source': stat.entrySource,
    'tags': stat.tags,
    'version_vector': stat.versionVector,
    'is_deleted': stat.isDeleted,
  };

  Map<String, dynamic> _coffeeBeanToJson(CoffeeBeansModel bean) => {
    'beans_uuid': bean.beansUuid,
    'id': bean.id,
    'roaster': bean.roaster,
    'name': bean.name,
    'origin': bean.origin,
    'variety': bean.variety,
    'tasting_notes': bean.tastingNotes,
    'processing_method': bean.processingMethod,
    'elevation': bean.elevation,
    'harvest_date': bean.harvestDate?.toUtc().toIso8601String(),
    'roast_date': bean.roastDate?.toUtc().toIso8601String(),
    'region': bean.region,
    'roast_level': bean.roastLevel,
    'grind_size': bean.grindSize,
    'cupping_score': bean.cuppingScore,
    'package_weight_grams': bean.packageWeightGrams,
    'notes': bean.notes,
    'farmer': bean.farmer,
    'farm': bean.farm,
    'is_favorite': bean.isFavorite,
    'version_vector': bean.versionVector,
    'is_deleted': bean.isDeleted,
    // A remote/CDN URL string, not raw binary — safe to include as-is. No
    // photo bytes are ever read or embedded in the dump.
    'photo_url': bean.photoUrl,
    'review_nudge_scheduled_at': bean.reviewNudgeScheduledAt
        ?.toUtc()
        .toIso8601String(),
  };

  Map<String, dynamic> _recipePreferenceToJson(
    UserRecipePreference preference,
  ) => {
    'recipe_id': preference.recipeId,
    'last_used': preference.lastUsed?.toUtc().toIso8601String(),
    'is_favorite': preference.isFavorite,
    'sweetness_slider_position': preference.sweetnessSliderPosition,
    'strength_slider_position': preference.strengthSliderPosition,
    'custom_coffee_amount': preference.customCoffeeAmount,
    'custom_water_amount': preference.customWaterAmount,
    'coffee_chronicler_slider_position':
        preference.coffeeChroniclerSliderPosition,
    'custom_grind_size': preference.customGrindSize,
    'custom_water_temp': preference.customWaterTemp,
  };

  Map<String, dynamic> _recipeToJson(Recipe recipe) => {
    'id': recipe.id,
    'brewing_method_id': recipe.brewingMethodId,
    'coffee_amount': recipe.coffeeAmount,
    'water_amount': recipe.waterAmount,
    'water_temp': recipe.waterTemp,
    'brew_time': recipe.brewTime,
    'vendor_id': recipe.vendorId,
    'last_modified': recipe.lastModified?.toUtc().toIso8601String(),
    'import_id': recipe.importId,
    'is_imported': recipe.isImported,
    'original_author_id': recipe.originalAuthorId,
    'needs_moderation_review': recipe.needsModerationReview,
    'is_public': recipe.isPublic,
  };

  Map<String, dynamic> _stepToJson(Step step) => {
    'id': step.id,
    'recipe_id': step.recipeId,
    'step_order': step.stepOrder,
    'description': step.description,
    'time': step.time,
    'locale': step.locale,
  };

  Map<String, dynamic> _recipeLocalizationToJson(
    RecipeLocalization localization,
  ) => {
    'id': localization.id,
    'recipe_id': localization.recipeId,
    'locale': localization.locale,
    'name': localization.name,
    'grind_size': localization.grindSize,
    'short_description': localization.shortDescription,
  };
}
