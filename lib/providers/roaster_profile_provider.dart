// lib/providers/roaster_profile_provider.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coffee_timer/models/roaster_profile_model.dart';
import 'package:coffee_timer/utils/app_logger.dart';

class RoasterProfileProvider extends ChangeNotifier {
  // In-memory cache keyed by slug
  final Map<String, RoasterProfileModel> _profileCache = {};
  // Cache for roaster name → slug lookups (null means no profile found)
  final Map<String, String?> _nameSlugCache = {};
  // Cache for roaster name → profile ID lookups (null means no profile found)
  final Map<String, String?> _nameProfileIdCache = {};
  // Cache for vendorId → profile lookups (null means no profile found)
  final Map<String, RoasterProfileModel?> _vendorIdProfileCache = {};

  /// Returns a cached profile or fetches from Supabase.
  Future<RoasterProfileModel?> fetchProfile(String slug) async {
    if (_profileCache.containsKey(slug)) {
      return _profileCache[slug];
    }
    try {
      final response = await Supabase.instance.client
          .rpc('get_roaster_profile', params: {'p_slug': slug});
      if (response == null) return null;
      final profile = RoasterProfileModel.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
      _profileCache[slug] = profile;
      return profile;
    } catch (error) {
      AppLogger.error(
        'Error fetching roaster profile',
        errorObject: AppLogger.sanitize(error),
      );
      return null;
    }
  }

  /// Fetches recipes created by the roaster admin user.
  /// Returns raw JSON list; the caller maps to RecipeModel as needed.
  Future<List<Map<String, dynamic>>> fetchProfileRecipes(
    String adminUserId, {
    String locale = 'en',
  }) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'get_roaster_recipes',
        params: {'p_admin_user_id': adminUserId, 'p_locale': locale},
      );
      if (response == null) return [];
      return List<Map<String, dynamic>>.from(
        (response as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
    } catch (error) {
      AppLogger.error(
        'Error fetching roaster recipes',
        errorObject: AppLogger.sanitize(error),
      );
      return [];
    }
  }

  /// Checks if a roaster name has an active profile. Returns the slug or null.
  /// Uses unaccent-normalised server-side matching.
  Future<String?> fetchRoasterSlugByName(String roasterName) async {
    final key = roasterName.trim().toLowerCase();
    if (_nameSlugCache.containsKey(key)) {
      return _nameSlugCache[key];
    }
    try {
      final response = await Supabase.instance.client.rpc(
        'get_roaster_profile_by_name',
        params: {'p_roaster_name': roasterName.trim()},
      );
      if (response != null) {
        final map = response as Map;
        _nameSlugCache[key] = map['slug'] as String?;
        _nameProfileIdCache[key] = map['id'] as String?;
      } else {
        _nameSlugCache[key] = null;
        _nameProfileIdCache[key] = null;
      }
      return _nameSlugCache[key];
    } catch (error) {
      AppLogger.error(
        'Error fetching roaster slug by name',
        errorObject: AppLogger.sanitize(error),
      );
      return null;
    }
  }

  /// Returns the roaster profile UUID for the given roaster name, or null.
  /// Reuses the same RPC result as [fetchRoasterSlugByName].
  Future<String?> fetchRoasterProfileIdByName(String roasterName) async {
    final key = roasterName.trim().toLowerCase();
    if (_nameProfileIdCache.containsKey(key)) {
      return _nameProfileIdCache[key];
    }
    // Calling fetchRoasterSlugByName will populate both caches.
    await fetchRoasterSlugByName(roasterName);
    return _nameProfileIdCache[key];
  }

  /// Looks up the active roaster profile for a recipe's vendorId (format: 'usr-UUID').
  /// Returns null if none found or vendorId is invalid.
  Future<RoasterProfileModel?> fetchRoasterProfileByVendorId(
      String vendorId) async {
    if (_vendorIdProfileCache.containsKey(vendorId)) {
      return _vendorIdProfileCache[vendorId];
    }
    try {
      final response = await Supabase.instance.client.rpc(
        'get_roaster_profile_by_vendor_id',
        params: {'p_vendor_id': vendorId},
      );
      if (response == null) {
        _vendorIdProfileCache[vendorId] = null;
        return null;
      }
      final profile = RoasterProfileModel.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
      _vendorIdProfileCache[vendorId] = profile;
      _profileCache[profile.slug] = profile;
      return profile;
    } catch (error) {
      AppLogger.error(
        'Error fetching roaster profile by vendor id',
        errorObject: AppLogger.sanitize(error),
      );
      _vendorIdProfileCache[vendorId] = null;
      return null;
    }
  }

  void clearCache() {
    _profileCache.clear();
    _nameSlugCache.clear();
    _nameProfileIdCache.clear();
    _vendorIdProfileCache.clear();
    notifyListeners();
  }
}
