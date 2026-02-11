import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/app_router.gr.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/recipe_model.dart';
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:coffee_timer/utils/icon_utils.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _PulseEntry {
  final int? id;
  final String recipeId;
  final DateTime createdAt;
  final double waterAmount;

  const _PulseEntry({
    required this.id,
    required this.recipeId,
    required this.createdAt,
    required this.waterAmount,
  });

  String get dedupeKey =>
      id?.toString() ?? '$recipeId-${createdAt.toIso8601String()}';
}

class _RecipeResolution {
  final String title;
  final String? brewingMethodId;

  const _RecipeResolution({required this.title, required this.brewingMethodId});

  bool get isOpenable => brewingMethodId != null && brewingMethodId!.isNotEmpty;
}

enum _PulseTimeBucket {
  recent,
  lastHour,
  today,
  yesterday,
  thisWeek,
  thisMonth,
  thisYear,
  lastYear,
}

class _PulseSection {
  final _PulseTimeBucket bucket;
  final List<_PulseEntry> entries;

  const _PulseSection({
    required this.bucket,
    required this.entries,
  });
}

class _PulseSummary {
  final int brews;
  final double liters;

  const _PulseSummary({
    required this.brews,
    required this.liters,
  });
}

class _PinnedPulseHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeaderExtent;
  final double maxHeaderExtent;
  final Widget Function(BuildContext context, double collapseT) builder;

  const _PinnedPulseHeaderDelegate({
    required this.minHeaderExtent,
    required this.maxHeaderExtent,
    required this.builder,
  });

  @override
  double get minExtent => minHeaderExtent;

  @override
  double get maxExtent => maxHeaderExtent;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final range = (maxHeaderExtent - minHeaderExtent).abs();
    final double collapseT = range <= 0
        ? 0.0
        : (shrinkOffset / (maxHeaderExtent - minHeaderExtent))
            .clamp(0.0, 1.0)
            .toDouble();
    final double currentExtent = (maxHeaderExtent - shrinkOffset)
        .clamp(minHeaderExtent, maxHeaderExtent)
        .toDouble();
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: overlapsContent ? 0.5 : 0,
      child: SizedBox(
        height: currentExtent,
        width: double.infinity,
        child: builder(context, collapseT),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedPulseHeaderDelegate oldDelegate) {
    return oldDelegate.minHeaderExtent != minHeaderExtent ||
        oldDelegate.maxHeaderExtent != maxHeaderExtent ||
        oldDelegate.builder != builder;
  }
}

class PulseScreen extends StatefulWidget {
  const PulseScreen({super.key});

  @override
  State<PulseScreen> createState() => _PulseScreenState();
}

class _PulseScreenState extends State<PulseScreen>
    with SingleTickerProviderStateMixin {
  static const int _pageSize = 50;
  static const int _loadMoreBatchSize = 20;
  static const int _maxEntriesRetained = 1000;

  final List<_PulseEntry> _entries = <_PulseEntry>[];
  final Set<String> _seenKeys = <String>{};
  final Set<String> _enteringKeys = <String>{};
  final Set<String> _highlightedKeys = <String>{};
  final Map<String, _RecipeResolution> _recipeCache =
      <String, _RecipeResolution>{};
  final ScrollController _scrollController = ScrollController();
  final Map<_PulseTimeBucket, GlobalKey> _sectionKeys =
      <_PulseTimeBucket, GlobalKey>{
    for (final bucket in _PulseTimeBucket.values)
      bucket: GlobalKey(debugLabel: 'pulse-${bucket.name}'),
  };

  RealtimeChannel? _channel;
  Timer? _relativeTimeTicker;
  DateTime? _oldestLoadedAt;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  _PulseTimeBucket _activeSummaryBucket = _PulseTimeBucket.recent;
  final Map<_PulseTimeBucket, _PulseSummary> _backendSummary =
      <_PulseTimeBucket, _PulseSummary>{};
  // Persists whether each section header was last seen at-or-above the anchor.
  // Survives across scroll callbacks so disposed headers keep their state.
  final Map<_PulseTimeBucket, bool> _headerAboveAnchor =
      <_PulseTimeBucket, bool>{};
  late final AnimationController _summaryDotPulseController;
  late final Animation<double> _summaryDotScale;
  late final Animation<double> _summaryDotOpacity;

  @override
  void initState() {
    super.initState();
    _summaryDotPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    final pulseCurve = CurvedAnimation(
      parent: _summaryDotPulseController,
      curve: Curves.easeInOutCubic,
    );
    _summaryDotScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.65),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.65, end: 1.0),
        weight: 40,
      ),
    ]).animate(pulseCurve);
    _summaryDotOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.6),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 0.0),
        weight: 55,
      ),
    ]).animate(pulseCurve);
    _scrollController.addListener(_onScroll);
    _loadInitialFeed();
    _startRealtime();
    _relativeTimeTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted || _entries.isEmpty) return;
      setState(() {});
      _loadBackendSummary();
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    // Hot reload can leave stale realtime callbacks alive after class-shape edits.
    _restartRealtimeSubscription();
  }

  @override
  void dispose() {
    _summaryDotPulseController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _relativeTimeTicker?.cancel();
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
    }
    super.dispose();
  }

  void _restartRealtimeSubscription() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
    }
    if (!mounted) return;
    _startRealtime();
  }

  Future<void> _loadInitialFeed() async {
    try {
      final parsed = await _fetchFeedPage(limit: _pageSize);

      if (!mounted) return;
      setState(() {
        _entries
          ..clear()
          ..addAll(parsed);
        _seenKeys
          ..clear()
          ..addAll(parsed.map((e) => e.dedupeKey));
        _headerAboveAnchor.clear();
        _oldestLoadedAt = parsed.isEmpty ? null : parsed.last.createdAt;
        _hasMore = parsed.length >= _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
        _activeSummaryBucket = _defaultActiveBucketForCurrentData();
      });
      _scheduleSummaryBucketSync();
      _loadBackendSummary();

      for (final entry in parsed) {
        _resolveRecipe(entry.recipeId);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<List<_PulseEntry>> _fetchFeedPage({
    required int limit,
    DateTime? olderThan,
  }) async {
    var query = Supabase.instance.client
        .from('global_stats')
        .select('id, recipe_id, created_at, water_amount')
        .gte('water_amount', 50)
        .lte('water_amount', 5000);

    if (olderThan != null) {
      query = query.lt('created_at', olderThan.toUtc().toIso8601String());
    }

    final rows = await query
        .order('created_at', ascending: false)
        .limit(limit)
        .timeout(const Duration(seconds: 5));

    final parsed = <_PulseEntry>[];
    for (final dynamic row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final recipeId = row['recipe_id']?.toString();
      final createdAtRaw = row['created_at'];
      final waterRaw = row['water_amount'];
      if (recipeId == null || createdAtRaw == null || waterRaw == null) {
        continue;
      }

      final createdAt = _parseCreatedAt(createdAtRaw);
      if (createdAt == null) continue;
      final waterAmount = (waterRaw as num?)?.toDouble() ??
          double.tryParse(waterRaw.toString());
      if (waterAmount == null) continue;

      parsed.add(_PulseEntry(
        id: (row['id'] as num?)?.toInt(),
        recipeId: recipeId,
        createdAt: createdAt,
        waterAmount: waterAmount,
      ));
    }

    return parsed;
  }

  void _onScroll() {
    _updateActiveSummaryFromViewport();
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter > 280) return;
    _loadMoreFeed();
  }

  Future<void> _loadMoreFeed() async {
    if (_isLoading || _isLoadingMore || !_hasMore || _oldestLoadedAt == null) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final older = await _fetchFeedPage(
        limit: _loadMoreBatchSize,
        olderThan: _oldestLoadedAt,
      );

      if (!mounted) return;
      if (older.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
        return;
      }

      final toAppend = <_PulseEntry>[];
      for (final entry in older) {
        if (_seenKeys.contains(entry.dedupeKey)) continue;
        toAppend.add(entry);
      }

      setState(() {
        _entries.addAll(toAppend);
        _seenKeys.addAll(toAppend.map((e) => e.dedupeKey));
        _oldestLoadedAt = older.last.createdAt;
        _hasMore = older.length >= _loadMoreBatchSize;
        _isLoadingMore = false;

        if (_entries.length > _maxEntriesRetained) {
          final removedCount = _entries.length - _maxEntriesRetained;
          final start = _entries.length - removedCount;
          final removed = _entries.sublist(start);
          _entries.removeRange(start, _entries.length);
          for (final item in removed) {
            _seenKeys.remove(item.dedupeKey);
            _enteringKeys.remove(item.dedupeKey);
            _highlightedKeys.remove(item.dedupeKey);
          }
        }
      });
      _scheduleSummaryBucketSync();
      _loadBackendSummary();

      for (final entry in toAppend) {
        _resolveRecipe(entry.recipeId);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _startRealtime() {
    final client = Supabase.instance.client;
    _channel = client.channel('public:pulse_feed')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'global_stats',
        callback: (payload) {
          final record = payload.newRecord;

          final recipeId = record['recipe_id']?.toString();
          final createdAtRaw = record['created_at'];
          final waterRaw = record['water_amount'];
          if (recipeId == null || createdAtRaw == null || waterRaw == null) {
            return;
          }
          final water = (waterRaw as num).toDouble();
          if (water < 50 || water > 5000) return;

          final createdAt = _parseCreatedAt(createdAtRaw);
          if (createdAt == null) return;

          final entry = _PulseEntry(
            id: (record['id'] as num?)?.toInt(),
            recipeId: recipeId,
            createdAt: createdAt,
            waterAmount: water,
          );

          if (!mounted) return;
          if (_seenKeys.contains(entry.dedupeKey)) return;

          setState(() {
            _entries.insert(0, entry);
            _seenKeys.add(entry.dedupeKey);
            _enteringKeys.add(entry.dedupeKey);
            _highlightedKeys.add(entry.dedupeKey);
            if (_entries.length > _maxEntriesRetained) {
              final removed = _entries.removeLast();
              _seenKeys.remove(removed.dedupeKey);
              _enteringKeys.remove(removed.dedupeKey);
              _highlightedKeys.remove(removed.dedupeKey);
            }
          });
          _scheduleSummaryBucketSync();
          _loadBackendSummary();
          _triggerSummaryDotPulse();

          _animateEntry(entry.dedupeKey);
          _resolveRecipe(entry.recipeId);
        },
      )
      ..subscribe();
  }

  void _triggerSummaryDotPulse() {
    if (!mounted) return;
    _summaryDotPulseController.forward(from: 0);
  }

  Future<void> _handlePullToRefresh() async {
    _triggerSummaryDotPulse();
    await _loadInitialFeed();
  }

  Future<void> _resolveRecipe(String recipeId) async {
    if (!mounted) return;
    if (_recipeCache.containsKey(recipeId)) return;

    final l10n = AppLocalizations.of(context)!;
    final unknownRecipeLabel = l10n.unknownRecipe;
    final pulseUserRecipeLabel = l10n.pulseUserRecipe;
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);

    try {
      final RecipeModel? localRecipe =
          await recipeProvider.getRecipeById(recipeId);
      if (localRecipe != null) {
        if (!mounted) return;
        final resolved = _RecipeResolution(
          title: localRecipe.name.trim().isEmpty
              ? unknownRecipeLabel
              : _displayRecipeTitle(localRecipe.name),
          brewingMethodId: localRecipe.brewingMethodId,
        );
        if (!mounted) return;
        setState(() {
          _recipeCache[recipeId] = resolved;
        });
        return;
      }
    } catch (_) {
      // Fall back to remote lookup.
    }

    try {
      if (!mounted) return;
      final locale = Localizations.localeOf(context).languageCode;
      final response = await Supabase.instance.client
          .from('user_recipes')
          .select(
              'id, ispublic, is_deleted, brewing_method_id, user_recipe_localizations(name, locale)')
          .eq('id', recipeId)
          .eq('ispublic', true)
          .eq('is_deleted', false)
          .maybeSingle()
          .timeout(const Duration(seconds: 2));

      if (response is Map<String, dynamic>) {
        final List<dynamic> localizations =
            (response['user_recipe_localizations'] as List<dynamic>?) ??
                const <dynamic>[];

        String title = pulseUserRecipeLabel;
        final localizedFirst =
            localizations.cast<Map<String, dynamic>?>().firstWhere(
                  (row) => row?['locale']?.toString() == locale,
                  orElse: () => null,
                );
        final fallbackFirst =
            localizations.cast<Map<String, dynamic>?>().firstWhere(
                  (row) =>
                      (row?['name']?.toString().trim().isNotEmpty ?? false),
                  orElse: () => null,
                );

        final maybeName = (localizedFirst?['name'] ?? fallbackFirst?['name'])
            ?.toString()
            .trim();
        if (maybeName != null && maybeName.isNotEmpty) {
          title = _displayRecipeTitle(maybeName);
        }

        final resolved = _RecipeResolution(
          title: title,
          brewingMethodId: response['brewing_method_id']?.toString(),
        );

        if (!mounted) return;
        setState(() {
          _recipeCache[recipeId] = resolved;
        });
        return;
      }
    } catch (_) {
      // Fall through to generic fallback.
    }

    if (!mounted) return;
    setState(() {
      _recipeCache[recipeId] = _RecipeResolution(
        title: pulseUserRecipeLabel,
        brewingMethodId: null,
      );
    });
  }

  void _openRecipe(_PulseEntry entry, _RecipeResolution recipe) {
    if (!recipe.isOpenable) return;
    context.router.push(RecipeDetailRoute(
      brewingMethodId: recipe.brewingMethodId!,
      recipeId: entry.recipeId,
    ));
  }

  void _animateEntry(String key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 24), () {
        if (!mounted) return;
        if (!_enteringKeys.contains(key)) return;
        setState(() {
          _enteringKeys.remove(key);
        });
      });
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        if (!_highlightedKeys.contains(key)) return;
        setState(() {
          _highlightedKeys.remove(key);
        });
      });
    });
  }

  String _displayRecipeTitle(String value) {
    final normalized = value.replaceAll('_', ' ').trim();
    return normalized.isEmpty
        ? AppLocalizations.of(context)!.unknownRecipe
        : normalized;
  }

  Widget _buildEntryIcon(BuildContext context, _RecipeResolution recipe) {
    final icon = getIconByBrewingMethod(recipe.brewingMethodId);
    return Icon(
      icon.icon ?? Icons.local_cafe_outlined,
      size: 18,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
    );
  }

  String _formatRelativeTime(DateTime createdAt) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final diff = now.difference(createdAt.toLocal());
    if (diff.isNegative || diff.inSeconds < 45) {
      return l10n.relativeTimeJustNow;
    }
    if (diff.inMinutes < 60) {
      final minutes = diff.inMinutes;
      return l10n.relativeTimeMinutesAgo(minutes);
    }
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      if (minutes == 0) {
        return l10n.relativeTimeHoursAgo(hours);
      }
      return l10n.relativeTimeHoursMinutesAgo(hours, minutes);
    }
    if (diff.inDays < 30) {
      final days = diff.inDays;
      return l10n.relativeTimeDaysAgo(days);
    }
    final months = (diff.inDays / 30).floor();
    if (months < 12) {
      return l10n.relativeTimeMonthsAgo(months);
    }
    final years = (diff.inDays / 365).floor();
    return l10n.relativeTimeYearsAgo(years);
  }

  DateTime? _parseCreatedAt(dynamic createdAtRaw) {
    if (createdAtRaw == null) return null;
    final rawText = createdAtRaw.toString().trim();
    if (rawText.isEmpty) return null;

    final parsed = DateTime.tryParse(rawText);
    if (parsed == null) return null;
    if (parsed.isUtc) return parsed.toUtc();

    final hasTimezoneSuffix =
        RegExp(r'(Z|[+-]\d{2}(?::?\d{2})?)$', caseSensitive: false)
            .hasMatch(rawText);
    if (hasTimezoneSuffix) return parsed.toUtc();

    // Treat timezone-less backend timestamps as UTC for consistent bucketing.
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    );
  }

  _PulseTimeBucket _bucketForEntry(DateTime createdAt) {
    final now = DateTime.now();
    final localCreated = createdAt.toLocal();
    final diff = now.difference(localCreated);

    if (diff.isNegative || diff.inMinutes < 15) {
      return _PulseTimeBucket.recent;
    }

    if (diff.inMinutes < 60) {
      return _PulseTimeBucket.lastHour;
    }

    final startOfToday = DateTime(now.year, now.month, now.day);
    if (!localCreated.isBefore(startOfToday)) {
      return _PulseTimeBucket.today;
    }

    // Use constructor-based subtraction so Dart resolves to the correct
    // calendar midnight even across DST transitions (Duration(days:1) would
    // subtract exactly 24h which can miss by ±1h during spring/fall switch).
    final startOfYesterday = DateTime(now.year, now.month, now.day - 1);
    if (!localCreated.isBefore(startOfYesterday)) {
      return _PulseTimeBucket.yesterday;
    }

    final startOfWeek =
        DateTime(now.year, now.month, now.day - (now.weekday - 1));
    if (!localCreated.isBefore(startOfWeek)) {
      return _PulseTimeBucket.thisWeek;
    }

    final startOfMonth = DateTime(now.year, now.month);
    if (!localCreated.isBefore(startOfMonth)) {
      return _PulseTimeBucket.thisMonth;
    }

    final startOfYear = DateTime(now.year);
    if (!localCreated.isBefore(startOfYear)) {
      return _PulseTimeBucket.thisYear;
    }

    return _PulseTimeBucket.lastYear;
  }

  List<_PulseSection> _buildSections() {
    final grouped = <_PulseTimeBucket, List<_PulseEntry>>{
      for (final bucket in _PulseTimeBucket.values) bucket: <_PulseEntry>[],
    };
    for (final entry in _entries) {
      grouped[_bucketForEntry(entry.createdAt)]!.add(entry);
    }

    return <_PulseSection>[
      for (final bucket in _PulseTimeBucket.values)
        if (grouped[bucket]!.isNotEmpty)
          _PulseSection(bucket: bucket, entries: grouped[bucket]!),
    ];
  }

  _PulseSummary _summaryForBucket(_PulseTimeBucket bucket) {
    final backend = _backendSummary[bucket];
    if (backend != null) return backend;

    final now = DateTime.now();
    int brews = 0;
    double liters = 0;
    for (final entry in _entries) {
      if (!_isInSummaryRange(entry.createdAt, bucket, now)) continue;
      brews += 1;
      liters += entry.waterAmount / 1000.0;
    }
    return _PulseSummary(
      brews: brews,
      liters: liters,
    );
  }

  Future<void> _loadBackendSummary() async {
    try {
      final response = await Supabase.instance.client.rpc(
        'global_stats_live_summary',
        params: {
          'p_now': DateTime.now().toUtc().toIso8601String(),
          'p_utc_offset_minutes': DateTime.now().timeZoneOffset.inMinutes,
        },
      ).timeout(const Duration(seconds: 4));

      if (response is! List) return;

      final next = <_PulseTimeBucket, _PulseSummary>{};
      for (final dynamic row in response) {
        if (row is! Map<String, dynamic>) continue;
        final period = row['period']?.toString();
        if (period == null) continue;

        _PulseTimeBucket? bucket;
        switch (period) {
          case 'recent':
            bucket = _PulseTimeBucket.recent;
            break;
          case 'last_hour':
            bucket = _PulseTimeBucket.lastHour;
            break;
          case 'today':
            bucket = _PulseTimeBucket.today;
            break;
          case 'yesterday':
            bucket = _PulseTimeBucket.yesterday;
            break;
          case 'this_week':
            bucket = _PulseTimeBucket.thisWeek;
            break;
          case 'this_month':
            bucket = _PulseTimeBucket.thisMonth;
            break;
          case 'this_year':
            bucket = _PulseTimeBucket.thisYear;
            break;
          case 'last_year':
            bucket = _PulseTimeBucket.lastYear;
            break;
        }
        if (bucket == null) continue;

        final brews = (row['brew_count'] as num?)?.toInt() ??
            int.tryParse(row['brew_count']?.toString() ?? '') ??
            0;
        final liters = (row['water_liters'] as num?)?.toDouble() ??
            double.tryParse(row['water_liters']?.toString() ?? '') ??
            0.0;

        next[bucket] = _PulseSummary(brews: brews, liters: liters);
      }

      if (!mounted) return;
      setState(() {
        _backendSummary
          ..clear()
          ..addAll(next);
      });
    } catch (_) {
      // Keep local fallback summaries if backend aggregation is unavailable.
    }
  }

  bool _isInSummaryRange(
    DateTime createdAt,
    _PulseTimeBucket bucket,
    DateTime now,
  ) {
    final localCreated = createdAt.toLocal();
    final diff = now.difference(localCreated);
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfYesterday = DateTime(now.year, now.month, now.day - 1);
    final startOfWeek =
        DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month);
    final startOfYear = DateTime(now.year);

    switch (bucket) {
      case _PulseTimeBucket.recent:
        return diff.isNegative || diff.inMinutes < 15;
      case _PulseTimeBucket.lastHour:
        return diff.isNegative || diff.inMinutes < 60;
      case _PulseTimeBucket.today:
        return !localCreated.isBefore(startOfToday);
      case _PulseTimeBucket.yesterday:
        return !localCreated.isBefore(startOfYesterday) &&
            localCreated.isBefore(startOfToday);
      case _PulseTimeBucket.thisWeek:
        return !localCreated.isBefore(startOfWeek);
      case _PulseTimeBucket.thisMonth:
        return !localCreated.isBefore(startOfMonth);
      case _PulseTimeBucket.thisYear:
        return !localCreated.isBefore(startOfYear);
      case _PulseTimeBucket.lastYear:
        return localCreated.isBefore(startOfYear);
    }
  }

  double _summaryHeaderMaxExtentForContext(BuildContext context) {
    final textScale =
        (MediaQuery.textScalerOf(context).scale(14.0) / 14.0).clamp(1.0, 1.4);
    return 128 + ((textScale - 1.0) * 36);
  }

  double _summaryHeaderMinExtentForContext(BuildContext context) {
    final textScale =
        (MediaQuery.textScalerOf(context).scale(14.0) / 14.0).clamp(1.0, 1.4);
    return 72 + ((textScale - 1.0) * 18);
  }

  _PulseTimeBucket _defaultActiveBucketForCurrentData() {
    final sections = _buildSections();
    if (sections.isEmpty) return _PulseTimeBucket.recent;
    for (final section in sections) {
      if (section.bucket == _activeSummaryBucket) {
        return _activeSummaryBucket;
      }
    }
    return sections.first.bucket;
  }

  void _scheduleSummaryBucketSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateActiveSummaryFromViewport();
    });
  }

  void _updateActiveSummaryFromViewport() {
    if (!_scrollController.hasClients || !mounted || _entries.isEmpty) return;
    final sections = _buildSections();
    if (sections.isEmpty) return;

    final media = MediaQuery.maybeOf(context);
    final topInset = media?.padding.top ?? 0;
    final anchorY = topInset +
        kToolbarHeight +
        _summaryHeaderMinExtentForContext(context) +
        2;

    // For each section header, determine whether it is at-or-above the anchor.
    // Live screen position is authoritative; when a header has been disposed by
    // the SliverList (off-screen) we fall back to the last-known state stored
    // in _headerAboveAnchor.  If it was never observed, we stop the scan —
    // we cannot tell which side of the anchor it sits on.
    _PulseTimeBucket nextBucket = sections.first.bucket;
    for (var i = 0; i < sections.length; i++) {
      final bucket = sections[i].bucket;

      // Try to get a live screen position.
      double? y;
      final ctx = _sectionKeys[bucket]?.currentContext;
      if (ctx != null) {
        final ro = ctx.findRenderObject();
        if (ro is RenderBox && ro.hasSize) {
          y = ro.localToGlobal(Offset.zero).dy;
        }
      }

      bool? isAbove;
      if (y != null) {
        isAbove = y <= anchorY;
        _headerAboveAnchor[bucket] = isAbove;
      } else {
        // Header disposed — use last-known state.
        isAbove = _headerAboveAnchor[bucket];
      }

      if (isAbove == null) {
        // Never observed — stop. Everything beyond is uncertain.
        break;
      }
      if (isAbove) {
        nextBucket = bucket;
      } else {
        // First header that is below the anchor — the previous section
        // (already stored in nextBucket) is the active one.
        break;
      }
    }

    if (nextBucket != _activeSummaryBucket) {
      setState(() {
        _activeSummaryBucket = nextBucket;
      });
    }
  }

  String _bucketLabel(BuildContext context, _PulseTimeBucket bucket) {
    final l10n = AppLocalizations.of(context)!;
    switch (bucket) {
      case _PulseTimeBucket.recent:
        return l10n.timePeriodRecent;
      case _PulseTimeBucket.lastHour:
        return l10n.timePeriodLastHour;
      case _PulseTimeBucket.today:
        return l10n.timePeriodToday;
      case _PulseTimeBucket.yesterday:
        return l10n.timePeriodYesterday;
      case _PulseTimeBucket.thisWeek:
        return l10n.timePeriodThisWeek;
      case _PulseTimeBucket.thisMonth:
        return l10n.timePeriodThisMonth;
      case _PulseTimeBucket.thisYear:
        return l10n.timePeriodThisYear;
      case _PulseTimeBucket.lastYear:
        return l10n.timePeriodLastYear;
    }
  }

  double _lerp(double from, double to, double t) {
    return from + ((to - from) * t);
  }

  Widget _buildSummaryHeader(BuildContext context,
      {required double collapseT}) {
    final summary = _summaryForBucket(_activeSummaryBucket);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final double t = collapseT.clamp(0.0, 1.0).toDouble();
    final double metricsVisibility =
        (1.0 - (t * 1.25)).clamp(0.0, 1.0).toDouble();
    final double compactVisibility =
        ((t - 0.45) / 0.55).clamp(0.0, 1.0).toDouble();
    final outerVerticalPadding = _lerp(8, 3, t);
    final cardVerticalPadding = _lerp(10, 7, t);
    final rowSpacing = _lerp(8, 4, t);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, outerVerticalPadding, 16, outerVerticalPadding),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: 10, vertical: cardVerticalPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    alignment: Alignment.center,
                    width: 14,
                    height: 14,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        FadeTransition(
                          opacity: _summaryDotOpacity,
                          child: ScaleTransition(
                            scale: _summaryDotScale,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    colorScheme.primary.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.9),
                                  width: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.pulseLiveSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontSize: _lerp(14, 13, t),
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _bucketLabel(context, _activeSummaryBucket),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: textTheme.labelMedium?.copyWith(
                          fontSize: _lerp(15, 13, t),
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: rowSpacing),
              ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: metricsVisibility,
                  child: Opacity(
                    opacity: metricsVisibility,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSummaryMetric(
                            context,
                            label: l10n.pulseBrewsLabel,
                            value: l10n.pulseBrewsCount(summary.brews),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryMetric(
                            context,
                            label: l10n.coffeeBrewed,
                            value:
                                '${summary.liters.toStringAsFixed(2)} ${l10n.litersUnit}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ClipRect(
                child: Align(
                  alignment: Alignment.topLeft,
                  heightFactor: compactVisibility,
                  child: Opacity(
                    opacity: compactVisibility,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${l10n.pulseBrewsCount(summary.brews)} • ${summary.liters.toStringAsFixed(2)} ${l10n.litersUnit}',
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryMetric(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                fontSize: 11,
                height: 1.1,
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: textTheme.titleSmall?.copyWith(
                fontSize: 15,
                height: 1.15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, _PulseTimeBucket bucket) {
    return Container(
      key: _sectionKeys[bucket],
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Text(
        _bucketLabel(context, bucket),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: 0.72,
                  ),
            ),
      ),
    );
  }

  List<Widget> _buildGroupedFeedChildren(
      BuildContext context, List<_PulseSection> sections) {
    final widgets = <Widget>[];
    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      widgets.add(_buildSectionHeader(context, section.bucket));
      for (final entry in section.entries) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildAnimatedEntryCard(context, entry),
        ));
      }
      if (i != sections.length - 1) {
        widgets.add(const SizedBox(height: 4));
      }
    }

    if (_isLoadingMore) {
      widgets.add(
        const Padding(
          padding: EdgeInsets.only(top: 6, bottom: 4),
          child: Center(
            child: SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildAnimatedEntryCard(BuildContext context, _PulseEntry entry) {
    final l10n = AppLocalizations.of(context)!;
    final isEntering = _enteringKeys.contains(entry.dedupeKey);
    final isHighlighted = _highlightedKeys.contains(entry.dedupeKey);
    final recipe = _recipeCache[entry.recipeId] ??
        _RecipeResolution(title: l10n.loadingEllipsis, brewingMethodId: null);

    return AnimatedSlide(
      key: ValueKey('pulse-${entry.dedupeKey}'),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      offset: isEntering ? const Offset(0, -0.22) : Offset.zero,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutBack,
        scale: isEntering ? 0.94 : 1.0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
          opacity: isEntering ? 0.0 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isHighlighted
                  ? Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEntryIcon(context, recipe),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: _buildBrewedRecipeLabel(
                              context,
                              entry,
                              recipe,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatRelativeTime(entry.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.65),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timeline,
              size: 44,
              color: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: 0.5,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noData,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _loadInitialFeed();
                _loadBackendSummary();
              },
              icon: const Icon(Icons.refresh),
              label: Text(l10n.refresh),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections();
    final groupedChildren = _buildGroupedFeedChildren(context, sections);
    final summaryHeaderMaxExtent = _summaryHeaderMaxExtentForContext(context);
    final summaryHeaderMinExtent = _summaryHeaderMinExtentForContext(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Symbols.vital_signs),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.pulseTitle),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: _handlePullToRefresh,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _PinnedPulseHeaderDelegate(
                          minHeaderExtent: summaryHeaderMinExtent,
                          maxHeaderExtent: summaryHeaderMaxExtent,
                          builder: (context, collapseT) => _buildSummaryHeader(
                              context,
                              collapseT: collapseT),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate(groupedChildren),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  List<Widget> _buildBrewedRecipeLabel(
    BuildContext context,
    _PulseEntry entry,
    _RecipeResolution recipe,
  ) {
    final l10n = AppLocalizations.of(context)!;
    const marker = '__recipe_name__';
    final template = l10n.pulseSomeoneBrewed(marker);
    final parts = template.split(marker);
    final widgets = <Widget>[];

    Widget recipeLink() {
      return GestureDetector(
        onTap: recipe.isOpenable ? () => _openRecipe(entry, recipe) : null,
        child: Text(
          recipe.title,
          style: TextStyle(
            color: recipe.isOpenable
                ? Theme.of(context).colorScheme.secondary
                : null,
            decoration: TextDecoration.none,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (parts.length == 1) {
      return <Widget>[Text(template.replaceAll(marker, recipe.title))];
    }

    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isNotEmpty) {
        widgets.add(Text(part));
      }
      if (i != parts.length - 1) {
        widgets.add(recipeLink());
      }
    }

    return widgets;
  }
}
