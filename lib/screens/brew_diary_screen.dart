import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/app_router.gr.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/models/diary_group.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/brew_markdown_export_service.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:coffee_timer/utils/diary_digest.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/widgets/containers/section_card.dart';
import 'package:coffee_timer/widgets/smart_back_button.dart';
import 'package:coffee_timer/widgets/brew_diary/brew_detail_sheet.dart';
import 'package:coffee_timer/widgets/brew_diary/brew_entry_card.dart';
import 'package:coffee_timer/widgets/brew_diary/brew_export_action.dart';
import 'package:coffee_timer/widgets/brew_diary/diary_filter_bar.dart';
import 'package:coffee_timer/widgets/brew_diary/diary_filter_sheet.dart';
import 'package:coffee_timer/widgets/brew_diary/diary_group_list.dart';
import 'package:coffee_timer/widgets/brew_diary/journey_view.dart';
import 'package:coffee_timer/widgets/brew_diary/month_strip.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

@RoutePage()
class BrewDiaryScreen extends StatefulWidget {
  const BrewDiaryScreen({super.key, this.initialExpandedStatUuid});

  final String? initialExpandedStatUuid;

  @override
  State<BrewDiaryScreen> createState() => _BrewDiaryScreenState();
}

class _BrewDiaryScreenState extends State<BrewDiaryScreen> {
  late Future<List<DiaryEntry>> _entriesFuture;
  late Future<List<TopDiaryMethod>> _topMethodsFuture;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, Future<Map<String, String?>>> _logoFutures = {};
  final Set<String> _pendingBookmarkUuids = {};
  List<DiaryEntry>? _entriesOverride;
  // Latest resolved entry list, cached during build for analytics call
  // sites (search debounce, filter-change reporting) that need
  // `_filteredEntries`'s `result_count` outside of the build method.
  List<DiaryEntry>? _lastKnownEntries;
  Timer? _searchDebounceTimer;
  String? _lastReportedSearchQuery;
  String? _loadedLocale;
  _PendingTimelineNavigation? _pendingNavigation;
  bool _navigationScheduled = false;
  bool _initialDeepLinkHandled = false;
  bool _initialDeepLinkTerminal = false;
  bool _timelineTopVisible = true;
  DateTime? _displayedMonth;
  bool _monthStripExpanded = false;
  String _search = '';
  Set<String> _selectedMethodIds = {};
  Set<String> _selectedBeanUuids = {};
  Set<String> _selectedOrigins = {};
  Set<String> _selectedTags = {};
  double? _ratingThreshold;
  bool _hasNotes = false;
  bool _hasExtractionYield = false;
  bool _ratingFourPlus = false;
  bool _bookmarkedOnly = false;
  bool _groupByBean = false;

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions.addListener(
      _handleTimelinePositionsChanged,
    );
    if (widget.initialExpandedStatUuid case final statUuid?) {
      _pendingNavigation = _PendingEntryNavigation(
        statUuid: statUuid,
        openDetails: true,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    if (_loadedLocale != locale) {
      _loadedLocale = locale;
      _loadEntries();
    }
  }

  void _loadEntries() {
    final locale =
        _loadedLocale ?? Localizations.localeOf(context).languageCode;
    final loc = AppLocalizations.of(context)!;
    final provider = context.read<UserStatProvider>();
    _entriesOverride = null;
    _entriesFuture = _fetchEntries(
      provider,
      locale,
      unknownRecipe: loc.unknownRecipe,
    );
    _topMethodsFuture = provider.topMethodsLast90Days(locale);
  }

  Future<List<DiaryEntry>> _fetchEntries(
    UserStatProvider provider,
    String locale, {
    required String unknownRecipe,
  }) async {
    try {
      final entries = await provider.fetchDiaryEntries(locale);
      return [
        for (final entry in entries)
          if (entry.recipeName.isEmpty)
            entry.copyWith(recipeName: unknownRecipe)
          else
            entry,
      ];
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load Brew Diary entries',
        errorObject: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(
      _handleTimelinePositionsChanged,
    );
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTimelinePositionsChanged() {
    final topVisible = _itemPositionsListener.itemPositions.value.any(
      (position) =>
          position.index == 0 &&
          position.itemLeadingEdge < 1 &&
          position.itemTrailingEdge > 0,
    );
    if (!mounted || topVisible == _timelineTopVisible) return;
    setState(() => _timelineTopVisible = topVisible);
  }

  void _refresh() {
    setState(_loadEntries);
  }

  Future<Map<String, String?>>? _logoUrls(DiaryEntry entry) {
    final roaster = entry.roaster;
    if (roaster == null || roaster.isEmpty) return null;
    return _logoFutures.putIfAbsent(
      roaster,
      () =>
          context.read<DatabaseProvider>().fetchCachedRoasterLogoUrls(roaster),
    );
  }

  Future<Map<String, String?>>? _groupLogoUrls(DiaryGroup group) {
    final roaster = group.roaster;
    if (roaster == null || roaster.isEmpty) return null;
    return _logoFutures.putIfAbsent(
      roaster,
      () =>
          context.read<DatabaseProvider>().fetchCachedRoasterLogoUrls(roaster),
    );
  }

  DiaryGroup? _journeyGroupForEntry(DiaryEntry entry) {
    final beanUuid = entry.coffeeBeansUuid?.trim();
    final entries = _lastKnownEntries;
    if (beanUuid == null || beanUuid.isEmpty || entries == null) return null;
    final currentEntries = [
      for (final loadedEntry in entries)
        if (loadedEntry.statUuid == entry.statUuid) entry else loadedEntry,
    ];
    return DiaryGroup.build(
      currentEntries,
    ).where((group) => group.key == beanUuid).firstOrNull;
  }

  Future<void> _openDetails(DiaryEntry entry, {required String source}) async {
    await showBrewDetailSheet(
      context,
      entry: entry,
      logoUrls: _logoUrls(entry),
      onOpenBeanJourney: (journeyEntry) {
        final journeyGroup = _journeyGroupForEntry(journeyEntry);
        if (journeyGroup == null) return;
        final navigator = Navigator.of(context);
        navigator.pop();
        navigator
            .push(
              MaterialPageRoute(
                builder: (_) => JourneyView(
                  group: journeyGroup,
                  logoUrls: _groupLogoUrls(journeyGroup),
                ),
              ),
            )
            .then((_) {
              if (mounted) _refresh();
            });
      },
      analyticsSource: source,
    );
    if (mounted) _refresh();
  }

  Future<void> _toggleBookmark(DiaryEntry entry) async {
    if (_pendingBookmarkUuids.contains(entry.statUuid)) return;
    final nextValue = !entry.isMarked;
    setState(() => _pendingBookmarkUuids.add(entry.statUuid));

    try {
      await context.read<UserStatProvider>().updateUserStat(
        statUuid: entry.statUuid,
        isMarked: nextValue,
      );
      AnalyticsService.maybeInstance?.track(
        'diary_bookmark_toggled',
        properties: {'bookmarked': nextValue, 'source': 'card'},
      );
      final initiallyLoadedEntries = await _entriesFuture;
      if (!mounted) return;
      setState(() {
        final loadedEntries = _entriesOverride ?? initiallyLoadedEntries;
        _entriesOverride = [
          for (final loadedEntry in loadedEntries)
            if (loadedEntry.statUuid == entry.statUuid)
              loadedEntry.copyWith(isMarked: nextValue)
            else
              loadedEntry,
        ];
        _pendingBookmarkUuids.remove(entry.statUuid);
      });
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to update diary bookmark',
        errorObject: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() => _pendingBookmarkUuids.remove(entry.statUuid));
      }
    }
  }

  DateTime _localCivilDay(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  bool _isOnLocalDay(DiaryEntry entry, DateTime day) =>
      _localCivilDay(entry.createdAt) == _localCivilDay(day);

  void _scrollToDay(
    DateTime day,
    List<DiaryEntry> entries,
    List<DiaryEntry> filteredEntries,
  ) {
    final normalizedDay = _localCivilDay(day);
    final hasRenderedTarget = filteredEntries.any(
      (entry) => _isOnLocalDay(entry, normalizedDay),
    );
    if (hasRenderedTarget) {
      _queueTimelineDayNavigation(normalizedDay);
      return;
    }

    final hasDiaryTarget = entries.any(
      (entry) => _isOnLocalDay(entry, normalizedDay),
    );
    if (!hasDiaryTarget || !_hasAnyFilter) return;

    _searchController.clear();
    setState(() {
      _resetFilters();
      _pendingNavigation = _PendingDayNavigation(normalizedDay);
    });
    _showFeedback(AppLocalizations.of(context)!.diaryFiltersClearedForDay);
  }

  void _queueTimelineDayNavigation(DateTime day) {
    if (_navigationScheduled) return;
    setState(() {
      _pendingNavigation = _PendingDayNavigation(_localCivilDay(day));
    });
  }

  void _schedulePendingNavigation(
    List<DiaryEntry> entries,
    List<_TimelineItem> timelineItems,
  ) {
    final pending = _pendingNavigation;
    if (pending == null || _navigationScheduled) return;
    if (pending is _PendingEntryNavigation &&
        pending.openDetails &&
        (_initialDeepLinkHandled || _initialDeepLinkTerminal)) {
      return;
    }

    DiaryEntry? entryTarget;
    late final int targetIndex;
    late final double alignment;
    switch (pending) {
      case _PendingEntryNavigation(:final statUuid, :final openDetails):
        entryTarget = entries
            .where((entry) => entry.statUuid == statUuid)
            .firstOrNull;
        if (entryTarget == null) {
          _pendingNavigation = null;
          if (openDetails) _markInitialDeepLinkMissing();
          return;
        }
        targetIndex = timelineItems.indexWhere(
          (item) => switch (item) {
            _EntryItem(:final entry) => entry.statUuid == statUuid,
            _ => false,
          },
        );
        alignment = 0.1;
      case _PendingDayNavigation(:final day):
        targetIndex = timelineItems.indexWhere(
          (item) => switch (item) {
            _DateHeaderItem(day: final headerDay) => headerDay == day,
            _ => false,
          },
        );
        alignment = 0;
    }
    if (targetIndex < 0) {
      _pendingNavigation = null;
      return;
    }

    _navigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (!_itemScrollController.isAttached) {
        _navigationScheduled = false;
        setState(() {});
        return;
      }

      final scroll = _itemScrollController.scrollTo(
        index: targetIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        alignment: alignment,
      );
      if (identical(_pendingNavigation, pending)) {
        _pendingNavigation = null;
      }
      final opensDetails = switch (pending) {
        _PendingEntryNavigation(:final openDetails) => openDetails,
        _PendingDayNavigation() => false,
      };
      if (opensDetails) _initialDeepLinkHandled = true;
      _navigationScheduled = false;
      await scroll;
      if (mounted && opensDetails && entryTarget != null) {
        // The only path that sets `opensDetails` is the initial
        // `widget.initialExpandedStatUuid` deep link (see initState).
        await _openDetails(entryTarget, source: 'deep_link');
      }
    });
  }

  Future<void> _scrollBackToCalendar() async {
    if (_navigationScheduled || !_itemScrollController.isAttached) return;
    setState(() => _navigationScheduled = true);
    await _itemScrollController.scrollTo(
      index: 0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      alignment: 0,
    );
    if (mounted) setState(() => _navigationScheduled = false);
  }

  void _markInitialDeepLinkMissing() {
    if (_initialDeepLinkHandled || _initialDeepLinkTerminal) return;
    _initialDeepLinkTerminal = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showFeedback(AppLocalizations.of(context)!.diaryBrewNotFound);
    });
  }

  void _showFeedback(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildEmptyCharm(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Center(
      child: Semantics(
        identifier: 'brewDiaryEmpty',
        label: loc.mts_emptyDiaryTitle,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_cafe_outlined,
                size: AppIconSize.large,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                loc.mts_emptyDiaryTitle,
                style: AppTextStyles.sectionHeader,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.base),
              AppTextButton(
                label: loc.mts_emptyDiaryAction,
                icon: Icons.local_cafe,
                onPressed: () => context.router.navigate(const HomeRoute()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasAnyFilter =>
      _search.isNotEmpty ||
      _selectedMethodIds.isNotEmpty ||
      _selectedBeanUuids.isNotEmpty ||
      _selectedOrigins.isNotEmpty ||
      _selectedTags.isNotEmpty ||
      _ratingThreshold != null ||
      _hasNotes ||
      _hasExtractionYield ||
      _ratingFourPlus ||
      _bookmarkedOnly;

  void _clearFilters(List<DiaryEntry> entries) {
    _searchController.clear();
    setState(_resetFilters);
    _reportFiltersChanged('clear', entries);
  }

  void _resetFilters() {
    _search = '';
    _selectedMethodIds = {};
    _selectedBeanUuids = {};
    _selectedOrigins = {};
    _selectedTags = {};
    _ratingThreshold = null;
    _hasNotes = false;
    _hasExtractionYield = false;
    _ratingFourPlus = false;
    _bookmarkedOnly = false;
  }

  List<DiaryEntry> _filteredEntries(List<DiaryEntry> entries) {
    final search = _search.trim().toLowerCase();
    final effectiveRating = _ratingFourPlus
        ? (_ratingThreshold == null || _ratingThreshold! < 4
              ? 4.0
              : _ratingThreshold)
        : _ratingThreshold;
    return entries.where((entry) {
      final matchesMethod =
          _selectedMethodIds.isEmpty ||
          _selectedMethodIds.contains(entry.brewingMethodId);
      final matchesBean =
          _selectedBeanUuids.isEmpty ||
          (entry.coffeeBeansUuid != null &&
              _selectedBeanUuids.contains(entry.coffeeBeansUuid));
      final matchesOrigin =
          _selectedOrigins.isEmpty ||
          (entry.origin != null &&
              _selectedOrigins.contains(entry.origin!.trim()));
      final matchesTags =
          _selectedTags.isEmpty || entry.tagList.any(_selectedTags.contains);
      final matchesRating =
          effectiveRating == null ||
          (entry.rating != null && entry.rating! >= effectiveRating);
      final matchesNotes =
          !_hasNotes || (entry.notes?.trim().isNotEmpty ?? false);
      final matchesExtraction =
          !_hasExtractionYield || entry.extractionYieldPercent != null;
      final matchesBookmark = !_bookmarkedOnly || entry.isMarked;
      final matchesSearch =
          search.isEmpty ||
          [entry.recipeName, entry.beanName, entry.roaster, entry.notes]
              .whereType<String>()
              .any((value) => value.toLowerCase().contains(search));
      return matchesMethod &&
          matchesBean &&
          matchesOrigin &&
          matchesTags &&
          matchesRating &&
          matchesNotes &&
          matchesExtraction &&
          matchesBookmark &&
          matchesSearch;
    }).toList();
  }

  /// Single chokepoint for `diary_filters_changed`. `entries` should be the
  /// same unfiltered list the caller used to build the currently-visible
  /// timeline, so `result_count` matches what the UI renders; pass null
  /// (sends `result_count: -1`) only when entries genuinely aren't loaded.
  void _reportFiltersChanged(String source, List<DiaryEntry>? entries) {
    final resultCount = entries == null ? -1 : _filteredEntries(entries).length;
    AnalyticsService.maybeInstance?.track(
      'diary_filters_changed',
      properties: {
        'source': source,
        'methods': _selectedMethodIds.length,
        'beans': _selectedBeanUuids.length,
        'origins': _selectedOrigins.length,
        'tags': _selectedTags.length,
        'rating_threshold': _ratingThreshold,
        'has_notes': _hasNotes,
        'has_extraction': _hasExtractionYield,
        'bookmarked': _bookmarkedOnly,
        'rating_four_plus': _ratingFourPlus,
        'result_count': resultCount,
      },
    );
  }

  /// Debounced ~1s after the search query settles. Skips empty queries and
  /// consecutive duplicates (this screen session); skips entirely if
  /// entries haven't loaded yet rather than sending an unreliable count.
  void _reportSearchUsed(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty || trimmed == _lastReportedSearchQuery) return;
    final entries = _lastKnownEntries;
    if (entries == null) return;
    _lastReportedSearchQuery = trimmed;
    AnalyticsService.maybeInstance?.track(
      'diary_search_used',
      properties: {
        'query_length': trimmed.length,
        'result_count': _filteredEntries(entries).length,
      },
    );
  }

  void _handleSearchChanged(String value) {
    setState(() => _search = value);
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      _reportSearchUsed(value);
    });
  }

  Future<void> _openFilters(List<DiaryEntry> entries) async {
    final selection = await showDiaryFilterSheet(
      context,
      entries: entries,
      initialSelection: DiaryFilterSelection(
        methodIds: _selectedMethodIds,
        beanUuids: _selectedBeanUuids,
        origins: _selectedOrigins,
        tags: _selectedTags,
        ratingThreshold: _ratingThreshold,
        hasNotes: _hasNotes,
        hasExtractionYield: _hasExtractionYield,
      ),
    );
    if (selection == null || !mounted) return;
    setState(() {
      _selectedMethodIds = {...selection.methodIds};
      _selectedBeanUuids = {...selection.beanUuids};
      _selectedOrigins = {...selection.origins};
      _selectedTags = {...selection.tags};
      _ratingThreshold = selection.ratingThreshold;
      _hasNotes = selection.hasNotes;
      _hasExtractionYield = selection.hasExtractionYield;
    });
    _reportFiltersChanged('sheet', entries);
  }

  Widget _buildNoMatches(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: Semantics(
        identifier: 'brewDiaryNoMatches',
        label: loc.diaryNoMatches,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            loc.diaryNoMatches,
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadError(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: Semantics(
        identifier: 'brewDiaryLoadError',
        label: loc.diaryLoadError,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.diaryLoadError,
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.base),
              AppTextButton(label: loc.retry, onPressed: _refresh),
            ],
          ),
        ),
      ),
    );
  }

  List<_TimelineItem> _buildTimelineItems({
    required List<DiaryEntry> entries,
    required List<DiaryEntry> filteredEntries,
    required DateFormat dateFormat,
    required DateTime now,
  }) {
    final items = <_TimelineItem>[const _MonthStripItem()];
    final memories = onThisDay(entries, now);
    if (memories.isNotEmpty) items.add(_MemoryItem(memories.first));
    if (filteredEntries.isEmpty) {
      items.add(const _NoMatchesItem());
      return items;
    }

    DateTime? previousDay;
    final currentWeekStart = diaryWeekStart(now);
    var weekStartIndex = 0;
    while (weekStartIndex < filteredEntries.length) {
      final weekStart = diaryWeekStart(
        filteredEntries[weekStartIndex].createdAt,
      );
      var weekEndIndex = weekStartIndex + 1;
      while (weekEndIndex < filteredEntries.length &&
          diaryWeekStart(filteredEntries[weekEndIndex].createdAt) ==
              weekStart) {
        weekEndIndex++;
      }
      final digest = buildWeekDigest(
        filteredEntries.sublist(weekStartIndex, weekEndIndex),
      );
      if (digest != null && weekStart != currentWeekStart) {
        items.add(_WeekDigestItem(digest));
      }

      for (final entry in filteredEntries.sublist(
        weekStartIndex,
        weekEndIndex,
      )) {
        final day = _localCivilDay(entry.createdAt);
        if (day != previousDay) {
          items.add(
            _DateHeaderItem(
              day: day,
              label: dateFormat.format(entry.createdAt.toLocal()),
            ),
          );
          previousDay = day;
        }
        items.add(_EntryItem(entry));
      }
      weekStartIndex = weekEndIndex;
    }
    return items;
  }

  Widget _buildMemoryCard(
    BuildContext context,
    DiaryEntry entry,
    DateTime now,
  ) {
    final loc = AppLocalizations.of(context)!;
    final years = now.toLocal().year - entry.createdAt.toLocal().year;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.base),
      child: Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openDetails(entry, source: 'card'),
          child: SectionCard(
            title: loc.diaryOnThisDayTitle(years),
            subtitle: loc.diaryOnThisDaySubtitle(
              entry.beanName ?? entry.recipeName,
              entry.methodName,
            ),
            icon: Icons.history,
            isCollapsible: false,
            showDivider: false,
            paddingChild: false,
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekDigestCard(
    BuildContext context,
    DiaryWeekDigest digest,
    DateFormat dateFormat,
  ) {
    final loc = AppLocalizations.of(context)!;
    final summary = <String>[loc.diaryMonthBrews(digest.brewCount)];
    if (digest.topMethodName != null) summary.add(digest.topMethodName!);
    if (digest.bestCup case final bestCup?) {
      summary.add(
        loc.diaryWeekBest(bestCup.label, bestCup.rating.toStringAsFixed(1)),
      );
    }
    final dialIn = digest.dialIn;
    final weekEnd = digest.weekStart.add(const Duration(days: 6));
    void openStats() {
      context.router.push(
        StatsRoute(
          initialStartDate: _civilDateParameter(digest.weekStart),
          initialEndDate: _civilDateParameter(weekEnd),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.base),
      child: Semantics(
        button: true,
        onTap: openStats,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: openStats,
          child: SectionCard(
            title: loc.diaryWeekOf(dateFormat.format(digest.weekStart)),
            subtitle: summary.join(' · '),
            icon: Icons.auto_awesome,
            trailing: const Icon(Icons.chevron_right, size: AppIconSize.medium),
            isCollapsible: false,
            showDivider: false,
            paddingChild: false,
            semanticIdentifier: 'diaryWeekDigest',
            child: dialIn == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.cardPadding,
                      0,
                      AppSpacing.cardPadding,
                      AppSpacing.cardPadding,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        loc.diaryDialedIn(dialIn.beanName, dialIn.methodName),
                        style: AppTextStyles.body,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final fmtSvc = context.watch<DateTimeFormatService>();
    final dateFormat = DateFormat(
      fmtSvc.datePattern(loc.dateFormat),
      Localizations.localeOf(context).toString(),
    );

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          identifier: 'brewDiaryBackButton',
          child: SmartBackButton(),
        ),
        title: Semantics(
          identifier: 'brewDiaryAppBar',
          label: loc.brewdiary,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.library_books, size: AppIconSize.medium),
              const SizedBox(width: AppSpacing.sm),
              Text(loc.brewdiary),
            ],
          ),
        ),
        actions: [
          // Wraps the same `_entriesFuture` the body listens to so the
          // button reactively enables once entries load, independent of
          // whether the outer State itself rebuilds — `FutureBuilder`
          // manages its own rebuild on completion, `_lastKnownEntries`
          // (mutated deep inside the body's own FutureBuilder) would not.
          FutureBuilder<List<DiaryEntry>>(
            future: _entriesFuture,
            builder: (context, snapshot) {
              final hasEntries =
                  (_entriesOverride ?? snapshot.data)?.isNotEmpty ?? false;
              return Semantics(
                identifier: 'shareDiaryButton',
                child: IconButton(
                  key: const Key('shareDiaryButton'),
                  // Produces a .md file, so it reads as a save/download rather
                  // than a send. See `brewExportIcon`.
                  icon: brewExportIcon(),
                  onPressed: hasEntries
                      ? () => shareBrewExport(
                          context,
                          entries: _lastKnownEntries ?? const [],
                          scope: BrewExportScope.wholeDiary,
                        )
                      : null,
                ),
              );
            },
          ),
          Semantics(
            identifier: 'addBrewEntryButton',
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result = await context.router.push(
                  const ManualBrewEntryRoute(),
                );
                if (result == true && mounted) _refresh();
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<DiaryEntry>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildLoadError(context);
          }
          final entries = _entriesOverride ?? snapshot.data;
          if (entries == null) {
            return const Center(child: CircularProgressIndicator());
          }
          _lastKnownEntries = entries;
          if (entries.isEmpty) {
            if (_pendingNavigation case _PendingEntryNavigation(
              openDetails: true,
            )) {
              _pendingNavigation = null;
              _markInitialDeepLinkMissing();
            }
            return _buildEmptyCharm(context);
          }
          final monthBounds = DiaryMonthBounds.fromEntries(entries);
          final displayedMonth = monthBounds.clamp(
            _displayedMonth ?? monthBounds.currentMonth,
          );
          _displayedMonth = displayedMonth;
          final filteredEntries = _filteredEntries(entries);

          final is24h = fmtSvc.use24Hour(
            MediaQuery.of(context).alwaysUse24HourFormat,
          );
          final timeFormat = DateFormat(
            is24h ? 'HH:mm' : 'hh:mm a',
            Localizations.localeOf(context).toString(),
          );
          final now = DateTime.now();
          final timelineItems = _buildTimelineItems(
            entries: entries,
            filteredEntries: filteredEntries,
            dateFormat: dateFormat,
            now: now,
          );
          if (!_groupByBean) {
            _schedulePendingNavigation(entries, timelineItems);
          }

          return Column(
            children: [
              DiaryAxisControl(
                groupedByBean: _groupByBean,
                onTimelineSelected: () => setState(() => _groupByBean = false),
                onBeansSelected: () => setState(() => _groupByBean = true),
              ),
              if (!_groupByBean)
                FutureBuilder<List<TopDiaryMethod>>(
                  future: _topMethodsFuture,
                  builder: (context, methodsSnapshot) => DiaryFilterBar(
                    searchController: _searchController,
                    topMethods: methodsSnapshot.data ?? const [],
                    selectedMethodIds: _selectedMethodIds,
                    selectedTags: _selectedTags,
                    ratingFourPlus: _ratingFourPlus,
                    bookmarkedOnly: _bookmarkedOnly,
                    hasAnyFilter: _hasAnyFilter,
                    onSearchChanged: _handleSearchChanged,
                    onOpenFilters: () => _openFilters(entries),
                    onClearAll: () => _clearFilters(entries),
                    onRatingFourPlusChanged: (value) {
                      setState(() => _ratingFourPlus = value);
                      _reportFiltersChanged('chip', entries);
                    },
                    onBookmarkedChanged: (value) {
                      setState(() => _bookmarkedOnly = value);
                      _reportFiltersChanged('chip', entries);
                    },
                    onMethodChanged: (methodId, selected) {
                      setState(() {
                        selected
                            ? _selectedMethodIds.add(methodId)
                            : _selectedMethodIds.remove(methodId);
                      });
                      _reportFiltersChanged('chip', entries);
                    },
                    onTagRemoved: (tag) {
                      setState(() => _selectedTags.remove(tag));
                      _reportFiltersChanged('chip', entries);
                    },
                  ),
                ),
              Expanded(
                child: _groupByBean
                    ? DiaryGroupList(
                        groups: DiaryGroup.build(entries),
                        logoUrlsForGroup: _groupLogoUrls,
                        onGroupTap: (group) async {
                          // The detail sheet only pops `true` on delete; edits
                          // mutate silently, so reload unconditionally on
                          // return — same contract as the timeline path.
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => JourneyView(
                                group: group,
                                logoUrls: _groupLogoUrls(group),
                              ),
                            ),
                          );
                          if (mounted) _refresh();
                        },
                        onShare: (group) => shareBrewExport(
                          context,
                          entries: group.entries,
                          scope: BrewExportScope.byBean,
                          // The group's own title, so the exported file is
                          // named after the bean card the user tapped.
                          label: group.title,
                        ),
                      )
                    : ScrollablePositionedList.builder(
                        itemScrollController: _itemScrollController,
                        itemPositionsListener: _itemPositionsListener,
                        padding: const EdgeInsets.all(AppSpacing.base),
                        itemCount: timelineItems.length,
                        itemBuilder: (context, index) {
                          return switch (timelineItems[index]) {
                            _MonthStripItem() => MonthStrip(
                              entries: entries,
                              displayedMonth: displayedMonth,
                              expanded: _monthStripExpanded,
                              onDisplayedMonthChanged: (month) => setState(
                                () =>
                                    _displayedMonth = monthBounds.clamp(month),
                              ),
                              onExpandedChanged: (expanded) => setState(
                                () => _monthStripExpanded = expanded,
                              ),
                              onDayTap: (day) =>
                                  _scrollToDay(day, entries, filteredEntries),
                            ),
                            _MemoryItem(:final entry) => _buildMemoryCard(
                              context,
                              entry,
                              now,
                            ),
                            _WeekDigestItem(:final digest) =>
                              _buildWeekDigestCard(context, digest, dateFormat),
                            _DateHeaderItem(:final day, :final label) =>
                              Semantics(
                                identifier: _dateHeaderIdentifier(day),
                                header: true,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.base,
                                  ),
                                  child: Text(
                                    label,
                                    style: AppTextStyles.sectionHeader,
                                  ),
                                ),
                              ),
                            _EntryItem(:final entry) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                BrewEntryCard(
                                  entry: entry,
                                  formattedTime: timeFormat.format(
                                    entry.createdAt.toLocal(),
                                  ),
                                  logoUrls: _logoUrls(entry),
                                  tasteLabels: [
                                    loc.tasteSour,
                                    loc.tasteBalanced,
                                    loc.tasteBitter,
                                  ],
                                  onTap: () =>
                                      _openDetails(entry, source: 'card'),
                                  onBookmarkToggle: () =>
                                      _toggleBookmark(entry),
                                  bookmarkTogglePending: _pendingBookmarkUuids
                                      .contains(entry.statUuid),
                                ),
                                const SizedBox(height: AppSpacing.base),
                              ],
                            ),
                            _NoMatchesItem() => Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.xxl,
                              ),
                              child: _buildNoMatches(context),
                            ),
                          };
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton:
          !_groupByBean &&
              !_timelineTopVisible &&
              !_navigationScheduled &&
              _itemScrollController.isAttached
          ? Semantics(
              identifier: 'diaryBackToCalendarButton',
              label: loc.diaryBackToCalendar,
              button: true,
              child: FloatingActionButton.small(
                tooltip: loc.diaryBackToCalendar,
                onPressed: _scrollBackToCalendar,
                child: const Icon(Icons.arrow_upward),
              ),
            )
          : null,
    );
  }
}

String _dateHeaderIdentifier(DateTime day) =>
    'diaryDateHeader_${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

String _civilDateParameter(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

sealed class _TimelineItem {
  const _TimelineItem();
}

class _MonthStripItem extends _TimelineItem {
  const _MonthStripItem();
}

class _MemoryItem extends _TimelineItem {
  const _MemoryItem(this.entry);

  final DiaryEntry entry;
}

class _WeekDigestItem extends _TimelineItem {
  const _WeekDigestItem(this.digest);

  final DiaryWeekDigest digest;
}

class _DateHeaderItem extends _TimelineItem {
  const _DateHeaderItem({required this.day, required this.label});

  final DateTime day;
  final String label;
}

class _EntryItem extends _TimelineItem {
  const _EntryItem(this.entry);

  final DiaryEntry entry;
}

class _NoMatchesItem extends _TimelineItem {
  const _NoMatchesItem();
}

sealed class _PendingTimelineNavigation {
  const _PendingTimelineNavigation();
}

class _PendingEntryNavigation extends _PendingTimelineNavigation {
  const _PendingEntryNavigation({
    required this.statUuid,
    required this.openDetails,
  });

  final String statUuid;
  final bool openDetails;
}

class _PendingDayNavigation extends _PendingTimelineNavigation {
  const _PendingDayNavigation(this.day);

  final DateTime day;
}

class DiaryAxisControl extends StatefulWidget {
  const DiaryAxisControl({
    super.key,
    required this.groupedByBean,
    required this.onTimelineSelected,
    required this.onBeansSelected,
  });

  final bool groupedByBean;
  final VoidCallback onTimelineSelected;
  final VoidCallback onBeansSelected;

  @override
  State<DiaryAxisControl> createState() => _DiaryAxisControlState();
}

class _DiaryAxisControlState extends State<DiaryAxisControl>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;
  // Tracked separately from `_controller.index`: TabBar's `onTap` fires even
  // when the tapped tab is already selected (re-tap), and TabController
  // already applied the (no-op) index change by the time `onTap` runs, so
  // comparing against `_controller.index` there can't detect a no-op tap.
  late int _lastReportedIndex;

  @override
  void initState() {
    super.initState();
    _lastReportedIndex = widget.groupedByBean ? 1 : 0;
    _controller = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.groupedByBean ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant DiaryAxisControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.groupedByBean != oldWidget.groupedByBean) {
      _controller.index = widget.groupedByBean ? 1 : 0;
      _lastReportedIndex = _controller.index;
    }
  }

  void _handleTap(int index) {
    if (index != _lastReportedIndex) {
      _lastReportedIndex = index;
      AnalyticsService.maybeInstance?.track(
        'diary_axis_changed',
        properties: {'axis': index == 1 ? 'by_bean' : 'timeline'},
      );
    }
    index == 1 ? widget.onBeansSelected() : widget.onTimelineSelected();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.sm,
        AppSpacing.base,
        0,
      ),
      child: TabBar(
        controller: _controller,
        onTap: _handleTap,
        tabs: [
          Tab(text: loc.diaryAxisTimeline),
          Tab(text: loc.diaryGroupByBean),
        ],
        labelColor: scheme.onSurface,
        // Explicit greys (not scheme.onSurfaceVariant) match this app's
        // muted-text convention — see theme_provider.dart.
        unselectedLabelColor: isDark
            ? Colors.grey.shade400
            : Colors.grey.shade600,
        labelStyle: AppTextStyles.fieldLabel,
        unselectedLabelStyle: AppTextStyles.caption,
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
      ),
    );
  }
}
