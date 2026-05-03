// lib/providers/roasters_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:coffee_timer/models/roaster_profile_model.dart';
import 'package:coffee_timer/utils/app_logger.dart';

class RoastersProvider extends ChangeNotifier {
  List<RoasterProfileModel> _roasters = [];
  List<String> _countries = [];
  Map<String, int> _countryCounts = {};

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

  String _searchQuery = '';
  String? _countryFilter;

  Timer? _debounce;

  static const int _pageSize = 30;

  // Getters
  List<RoasterProfileModel> get roasters => _roasters;
  List<String> get countries => _countries;
  Map<String, int> get countryCounts => _countryCounts;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get countryFilter => _countryFilter;
  bool get hasActiveFilter => _countryFilter != null;

  /// Loads the distinct country list once on screen init.
  Future<void> loadCountries() async {
    if (_countries.isNotEmpty) return;
    try {
      final response = await Supabase.instance.client
          .rpc('get_roaster_countries');
      if (response == null) return;
      final rows = List<Map<String, dynamic>>.from(
        (response as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
      _countries = rows
          .map((r) => r['country'] as String)
          .where((c) => c.isNotEmpty)
          .toList();
      _countryCounts = {
        for (final r in rows)
          r['country'] as String: (r['roaster_count'] as num).toInt(),
      };
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error loading roaster countries', errorObject: e);
    }
  }

  /// Resets list and fetches page 0. Call when filters or search change.
  Future<void> loadInitial() async {
    _roasters = [];
    _hasMore = true;
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final results = await _fetchPage(0);
      _roasters = results;
      _hasMore = results.length >= _pageSize;
    } catch (e) {
      AppLogger.error('Error loading roasters', errorObject: e);
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Appends the next page. Call when the scroll nears the bottom.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final results = await _fetchPage(_roasters.length);
      _roasters = [..._roasters, ...results];
      _hasMore = results.length >= _pageSize;
    } catch (e) {
      AppLogger.error('Error loading more roasters', errorObject: e);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Updates search query with 350 ms debounce before reloading.
  void setSearchQuery(String query) {
    _searchQuery = query;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), loadInitial);
    // Notify immediately so the AppBar clear button reacts.
    notifyListeners();
  }

  /// Sets the country filter and reloads immediately.
  void setCountryFilter(String? country) {
    if (_countryFilter == country) return;
    _countryFilter = country;
    loadInitial();
  }

  /// Clears all filters and reloads.
  void clearFilters() {
    _countryFilter = null;
    _searchQuery = '';
    _debounce?.cancel();
    loadInitial();
  }

  Future<List<RoasterProfileModel>> _fetchPage(int offset) async {
    final response = await Supabase.instance.client.rpc(
      'list_roaster_profiles',
      params: {
        'p_search': _searchQuery.isEmpty ? null : _searchQuery,
        'p_country': _countryFilter,
        'p_offset': offset,
        'p_limit': _pageSize,
      },
    );
    if (response == null) return [];
    return List<Map<String, dynamic>>.from(
      (response as List).map((e) => Map<String, dynamic>.from(e as Map)),
    ).map((json) {
      // list_roaster_profiles RPC omits coffee_roaster_id; provide a default
      // so RoasterProfileModel.fromJson doesn't crash on null cast.
      json['coffee_roaster_id'] ??= 0;
      return RoasterProfileModel.fromJson(json);
    }).toList();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
