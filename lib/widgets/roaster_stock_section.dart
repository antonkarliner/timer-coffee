import 'dart:async';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/bean_recommendation_model.dart';
import 'package:coffee_timer/providers/recommendation_provider.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/clients/roaster_stock_client.dart';
import 'package:coffee_timer/services/feature_flags/feature_flags_repository.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/utils/country_names.dart';
import 'package:coffee_timer/utils/stock_attribute_labels.dart';
import 'package:coffee_timer/utils/stock_links.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/widgets/containers/section_card.dart';
import 'package:coffee_timer/widgets/stock_bean_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The roaster profile's "In stock now" section (plan 017, phase 5d): the
/// beans the roaster currently sells, fetched from the public
/// `get_roaster_stock` RPC.
///
/// Renders NOTHING unless the feature is available (the `bean_recommendations`
/// flag or `FOR_YOU_DEBUG`) and the fetch came back with at least one item —
/// no skeleton, no spinner, no empty and no error state, exactly like the
/// Hub's "For you" card. When the flag is off it also makes no network call.
///
/// The client and the sign-in lookup are injectable so tests can fake them;
/// defaults read the real Supabase session.
class RoasterStockSection extends StatefulWidget {
  // Not const: the optional Supabase-backed defaults are runtime values.
  RoasterStockSection({
    super.key,
    required this.slug,
    required this.roasterName,
    this.highlightStockId,
    this.logoUrl,
    this.logoMirrorUrl,
    RoasterStockClient? client,
    String? Function()? currentUserId,
  })  : client = client ?? SupabaseRoasterStockClient(Supabase.instance.client),
        currentUserId = currentUserId ??
            (() => Supabase.instance.client.auth.currentUser?.id);

  /// The roaster's profile slug.
  final String slug;

  /// The roaster's display name (kept for the call site's readability; the
  /// section shows stock items, whose cards carry bean names).
  final String roasterName;

  /// The stock item requested by the incoming profile link, if still in stock.
  final String? highlightStockId;

  /// Roaster logo fallbacks for stock items without a product photo.
  final String? logoUrl;
  final String? logoMirrorUrl;

  final RoasterStockClient client;

  /// Current user id, or null when signed out. The referred-click RPC raises
  /// for sessions without a user, so the section only logs clicks when this
  /// returns one.
  final String? Function() currentUserId;

  @override
  State<RoasterStockSection> createState() => _RoasterStockSectionState();
}

class _RoasterStockSectionState extends State<RoasterStockSection> {
  /// How many cards to show before the user expands.
  static const int _collapsedCount = 4;

  /// Upper bound of a fetch, matching the RPC's default.
  static const int _fetchLimit = 30;

  RoasterStockResult? _result;
  bool _loading = false;
  String? _loadedSlug;
  bool _shownTracked = false;
  bool _highlightScrollScheduled = false;

  // SectionCard owns the header toggle; mirror it to guard deferred scrolling.
  bool _sectionExpanded = true;

  /// Widget state only — never persisted. Collapsed shows up to
  /// [_collapsedCount] cards; expanding reveals everything fetched.
  bool _expanded = false;

  /// Whether the feature is available, read the way
  /// `settings_privacy_data_screen.dart` reads it.
  bool get _featureAvailable {
    final flags = context.watch<Map<String, bool>?>();
    return const bool.fromEnvironment('FOR_YOU_DEBUG') ||
        (flags?[FeatureFlagKeys.beanRecommendations] ?? false);
  }

  @override
  void initState() {
    super.initState();
    // After the first frame, never inside build.
    _scheduleLoad();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The feature flag is watched in build; when it flips on while the
    // section is mounted, this re-schedules the (still once-per-slug) load.
    _scheduleLoad();
  }

  @override
  void didUpdateWidget(RoasterStockSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slug != widget.slug) _scheduleLoad();
  }

  void _scheduleLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadOnce());
    });
  }

  /// One fetch per slug. Quietly does nothing when the feature is off —
  /// hidden sections must not touch the network.
  Future<void> _loadOnce() async {
    final slug = widget.slug;
    if (_loadedSlug == slug || _loading) return;
    final flags = context.read<Map<String, bool>?>();
    final available = const bool.fromEnvironment('FOR_YOU_DEBUG') ||
        (flags?[FeatureFlagKeys.beanRecommendations] ?? false);
    if (!available) return;
    _loadedSlug = slug;
    _loading = true;
    try {
      final result =
          await widget.client.fetchRoasterStock(slug, limit: _fetchLimit);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (_) {
      // No error state on purpose: the section stays invisible.
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_featureAvailable) return const SizedBox.shrink();
    final items = _result?.items ?? const <RoasterStockItem>[];
    // Loading, error and empty all render nothing — no spinner, no empty
    // state, no error text.
    if (items.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final pickIds = _currentPickIds();
    final highlighted =
        items.any((item) => item.stockId == widget.highlightStockId);
    final ordered = _orderWithPicksFirst(items, pickIds);
    final visible = _expanded
        ? ordered
        : ordered.take(_collapsedCount).toList(growable: false);
    _scheduleShownAnalytics(ordered, pickIds, highlighted: highlighted);
    if (highlighted) _scheduleHighlightScroll();

    return SectionCard(
      title: l10n.roasterStockTitle,
      icon: Icons.storefront_outlined,
      isCollapsible: true,
      initiallyExpanded: true,
      onExpansionChanged: (expanded) => _sectionExpanded = expanded,
      paddingChild: false,
      semanticIdentifier: 'roasterStockSection',
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (index, item) in visible.indexed) ...[
              if (index > 0) const SizedBox(height: AppSpacing.sm),
              Semantics(
                identifier: 'roasterStockItem_$index',
                child: _stockCard(
                  context,
                  item,
                  index,
                  l10n,
                  isPick: pickIds.contains(item.stockId) ||
                      item.stockId == widget.highlightStockId,
                ),
              ),
            ],
            if (ordered.length > _collapsedCount) ...[
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppTextButton(
                  label: _expanded ? l10n.showLess : l10n.showMore,
                  onPressed: _toggleExpanded,
                  isFullWidth: false,
                  padding: const EdgeInsetsDirectional.only(
                    end: AppSpacing.base,
                    top: AppSpacing.xs,
                    bottom: AppSpacing.xs,
                  ),
                  textStyle: AppTextStyles.body,
                ),
              ),
            ],
            // Source note — part of the section (inside the same
            // `items.isEmpty` gate), under the cards and the expand control.
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              identifier: 'roasterStockSourceNote',
              child: Text(
                l10n.stockSourceNote,
                style: AppTextStyles.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The user's current picks, when the provider is in scope — read with
  /// `context.watch` so re-ordering follows live dismissals. Everything the
  /// section shows must also work without the provider, hence the catch.
  Set<String> _currentPickIds() {
    try {
      final recommendations = context.watch<RecommendationProvider>();
      if (recommendations.state != RecommendationState.ready) {
        return const <String>{};
      }
      return recommendations.items.map((item) => item.stockId).toSet();
    } on ProviderNotFoundException {
      return const <String>{};
    }
  }

  /// The linked bean goes before the user's other "For you" picks, keeping
  /// the roaster-list order within each remaining group.
  List<RoasterStockItem> _orderWithPicksFirst(
    List<RoasterStockItem> items,
    Set<String> pickIds,
  ) {
    final highlighted = items
        .where((item) => item.stockId == widget.highlightStockId)
        .toList(growable: false);
    if (pickIds.isEmpty && highlighted.isEmpty) return items;
    final pinned = items
        .where((item) =>
            pickIds.contains(item.stockId) &&
            item.stockId != widget.highlightStockId)
        .toList(growable: false);
    if (pinned.isEmpty && highlighted.isEmpty) return items;
    final rest = items
        .where((item) =>
            !pickIds.contains(item.stockId) &&
            item.stockId != widget.highlightStockId)
        .toList(growable: false);
    return [...highlighted, ...pinned, ...rest];
  }

  /// Wait until the highlighted cards have layout, then reveal the section
  /// once. Rebuilds and subsequent expansion must not move the user again.
  void _scheduleHighlightScroll() {
    if (!_sectionExpanded || _highlightScrollScheduled) return;
    _highlightScrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sectionExpanded || Scrollable.maybeOf(context) == null) {
        return;
      }
      unawaited(Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 250),
        alignment: 0.1,
      ));
    });
  }

  Widget _stockCard(
    BuildContext context,
    RoasterStockItem item,
    int index,
    AppLocalizations l10n, {
    required bool isPick,
  }) {
    final productUri = buildStockProductUrl(
      item.productUrl,
      campaign: 'roaster_profile',
    );
    void open() => _openProduct(context, item, index, isPick, productUri!);
    return StockBeanCard(
      title: item.beanName,
      subtitle: _secondaryLine(context, l10n, item, isPick),
      imageUrl: item.imageUrl,
      logoUrl: widget.logoUrl,
      logoMirrorUrl: widget.logoMirrorUrl,
      // Tapping the card does the same as the button.
      onTap: productUri != null ? open : null,
      actions: [
        if (productUri != null)
          Semantics(
            identifier: 'roasterStockView_$index',
            child: AppTextButton(
              label: l10n.forYouViewAtRoaster,
              onPressed: open,
              isFullWidth: false,
              padding: const EdgeInsetsDirectional.only(
                end: AppSpacing.base,
                top: AppSpacing.xs,
                bottom: AppSpacing.xs,
              ),
              textStyle: AppTextStyles.body,
            ),
          ),
      ],
    );
  }

  /// Origins, process, up to three recognized flavours, then decaf and the
  /// "For you" marker. The flavour list stays together as one summary part.
  String? _secondaryLine(
    BuildContext context,
    AppLocalizations l10n,
    RoasterStockItem item,
    bool isPick,
  ) {
    final names = <String>[];
    final locale = Localizations.localeOf(context);
    for (final code in item.originCountryCodes) {
      final name = localizedCountryName(code, locale);
      if (name != null && name.trim().isNotEmpty) names.add(name);
    }
    final process = stockProcessLabel(l10n, item.processFamily);
    if (process != null) names.add(process);
    final flavors = item.flavorFamilies
        .map((value) => stockFlavorLabel(l10n, value))
        .whereType<String>()
        .take(3);
    // Preserve translated casing; Arabic and Persian use the Arabic comma.
    final listSeparator =
        const {'ar', 'fa'}.contains(locale.languageCode) ? '، ' : ', ';
    if (flavors.isNotEmpty) names.add(flavors.join(listSeparator));
    if (item.isDecaf) names.add(l10n.roasterStockDecaf);
    if (isPick) names.add(l10n.forYouTitle);
    if (names.isEmpty) return null;
    return names.join(l10n.summarySeparator);
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  /// `roaster_stock_shown` once per section lifetime, reported after the
  /// frame. `count` is what is shown initially, `total` everything fetched,
  /// `picks` how many of the user's picks were pinned first. Never a bean or
  /// roaster name.
  void _scheduleShownAnalytics(
    List<RoasterStockItem> ordered,
    Set<String> pickIds, {
    required bool highlighted,
  }) {
    if (_shownTracked) return;
    _shownTracked = true;
    final count = ordered.length < _collapsedCount
        ? ordered.length
        : _collapsedCount;
    final pickCount =
        ordered.where((item) => pickIds.contains(item.stockId)).length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AnalyticsService.maybeInstance?.track(
        'roaster_stock_shown',
        properties: {
          'count': count,
          'total': ordered.length,
          'picks': pickCount,
          'highlighted': highlighted,
        },
      );
    });
  }

  void _openProduct(
    BuildContext context,
    RoasterStockItem item,
    int index,
    bool isPick,
    Uri uri,
  ) {
    AnalyticsService.maybeInstance?.track(
      'roaster_stock_link_opened',
      properties: {
        'stock_id': item.stockId,
        'position': index,
        'is_pick': isPick,
      },
    );
    // Fire-and-forget attribution, signed-in users only; it must never
    // delay or break opening the page.
    if (widget.currentUserId() != null) {
      unawaited(_logClick(item.stockId));
    }
    unawaited(launchStockProductLink(uri));
  }

  Future<void> _logClick(String stockId) async {
    try {
      await widget.client.logReferredClick(stockId);
    } catch (_) {
      // Best-effort attribution; a failure changes nothing.
    }
  }
}
