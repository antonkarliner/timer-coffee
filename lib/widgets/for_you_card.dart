import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_router.gr.dart';
import '../models/bean_recommendation_model.dart';
import '../providers/recommendation_provider.dart';
import '../services/analytics_service.dart';
import '../theme/design_tokens.dart';
import '../utils/country_names.dart';
import '../utils/stock_links.dart';
import 'base_buttons.dart';
import 'stock_bean_card.dart';

/// The Hub's "For you" card (plan 017, phase 5a; restyled in phase 5d): up
/// to [maxItems] in-stock beans picked for the user by the recommendation
/// backend, each rendered as its own [StockBeanCard].
///
/// Renders NOTHING unless the provider is ready with at least one pick —
/// no skeleton, no spinner, no empty and no error state: most users will
/// never have picks, and a placeholder that appears and then vanishes reads
/// worse than a card that simply arrives. The [AnimatedSize] keeps the Hub
/// list from jumping when the card appears or a row is dismissed.
class ForYouCard extends StatefulWidget {
  const ForYouCard({super.key, this.maxItems = 3});

  /// Upper bound on the rows shown, regardless of how many picks exist.
  final int maxItems;

  @override
  State<ForYouCard> createState() => _ForYouCardState();
}

class _ForYouCardState extends State<ForYouCard> {
  /// Language tag the card last passed to
  /// [RecommendationProvider.ensureLoaded]; null until the first post-frame
  /// call, which [didChangeDependencies] uses to skip the initial pass (so
  /// `ensureLoaded` really fires only after the first frame).
  String? _localeTag;
  bool _shownTracked = false;
  final Set<String> _unavailableStatusesTracked = {};

  /// Widget state only — never persisted. A freshly created card starts
  /// collapsed, showing the first pick; expanding reveals up to
  /// [ForYouCard.maxItems].
  bool _expanded = false;

  /// Capture the rendered state, then report after the frame. Lifetime
  /// guards survive rebuilds, locale changes and optimistic dismissals.
  /// `for_you_shown`'s `count` is the rows visible at that moment — 1 while
  /// collapsed — and `available` is the picks the card could show
  /// (≤ [ForYouCard.maxItems]).
  void _scheduleVisibilityAnalytics(RecommendationProvider provider) {
    final available = provider.state == RecommendationState.ready
        ? provider.items.take(widget.maxItems).toList(growable: false)
        : const <BeanRecommendation>[];
    final visible = available
        .take(_expanded ? available.length : 1)
        .toList(growable: false);
    final status = provider.state == RecommendationState.hidden
        ? provider.unavailableStatus
        : null;
    final country = provider.lastCountryCode;
    if ((_shownTracked || visible.isEmpty) &&
        (status == null || _unavailableStatusesTracked.contains(status))) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_shownTracked && visible.isNotEmpty) {
        _shownTracked = true;
        final modes =
            visible.map((item) => item.mode ?? 'unknown').toSet().toList()
              ..sort();
        AnalyticsService.maybeInstance?.track(
          'for_you_shown',
          properties: {
            'count': visible.length,
            'modes': modes.join(','),
            'available': available.length,
          },
        );
      }
      if (status != null && _unavailableStatusesTracked.add(status)) {
        AnalyticsService.maybeInstance?.track(
          'for_you_unavailable',
          properties: {
            'status': status,
            'country': ?country,
          },
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // After the first frame: Localizations is not resolvable during
    // initState, and ensureLoaded must never run synchronously inside build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tag = Localizations.localeOf(context).toLanguageTag();
      _localeTag = tag;
      unawaited(context.read<RecommendationProvider>().ensureLoaded(tag));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Locale changed (the first pass is handled by initState's post-frame
    // callback). The provider de-duplicates, so a redundant call is cheap —
    // but this tag check keeps it to one call per locale.
    if (_localeTag == null) return;
    final tag = Localizations.localeOf(context).toLanguageTag();
    if (tag == _localeTag) return;
    _localeTag = tag;
    unawaited(context.read<RecommendationProvider>().ensureLoaded(tag));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecommendationProvider>();
    _scheduleVisibilityAnalytics(provider);
    final ready =
        provider.state == RecommendationState.ready &&
        provider.items.isNotEmpty;
    return Semantics(
      identifier: 'forYouCard',
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: AlignmentDirectional.topCenter,
        child: ready ? _buildCard(context, provider) : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildCard(BuildContext context, RecommendationProvider provider) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final available = provider.items
        .take(widget.maxItems)
        .toList(growable: false);
    // Collapsed shows the first pick only; expanded shows up to maxItems.
    final visible = available
        .take(_expanded ? available.length : 1)
        .toList(growable: false);

    // Phase 5d restyle: no enclosing card — a section header that lines up
    // with the Hub's SettingsSection headers (same horizontal inset), then
    // each pick as its own StockBeanCard, then the expand control. The only
    // outer padding is vertical; the base side margins live on each piece.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title row with the hide control at its trailing edge — the Row
          // is direction-aware, so "trailing" stays trailing in RTL. Same
          // inset as SettingsSectionHeader so the Hub headers line up.
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.base,
              AppSpacing.sm,
              AppSpacing.base,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.forYouTitle,
                    // Same style as the Hub's own section headers ("Your
                    // Coffee"), so the block reads as one more section.
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                Semantics(
                  identifier: 'forYouHide',
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      size: AppIconSize.small,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: _hideFromCard,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    // The journey card's zero-constraints button shrinks
                    // below the 44×44 minimum tap target; this one keeps
                    // the full-size Material target via a token (48 ≥ 44).
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.xxl,
                      minHeight: AppSpacing.xxl,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.base,
              0,
              AppSpacing.base,
              0,
            ),
            child: Text(
              l10n.forYouSubtitle,
              style: AppTextStyles.caption.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // One card per pick.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: Column(
              children: [
                for (final (index, item) in visible.indexed) ...[
                  if (index > 0) const SizedBox(height: AppSpacing.sm),
                  Semantics(
                    identifier: 'forYouItem_$index',
                    child: _ForYouRow(item: item, index: index),
                  ),
                ],
                // Show more / Show less — hidden entirely for a single pick,
                // and gone again when dismissals shrink the card back to one.
                // AnimatedSize (around the column above) animates the change.
                if (available.length > 1) ...[
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
                // Plan 086: the way in to the taste profile that drives these
                // picks. It sits here, not on the Account page alone, because
                // anonymous users get suggestions too but have no Account page.
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Semantics(
                    identifier: 'forYouTasteProfile',
                    child: AppTextButton(
                      label: l10n.tasteProfileTitle,
                      onPressed: () =>
                          context.router.push(const TasteProfileRoute()),
                      isFullWidth: false,
                      padding: const EdgeInsetsDirectional.only(
                        end: AppSpacing.base,
                        top: AppSpacing.xs,
                        bottom: AppSpacing.xs,
                      ),
                      textStyle: AppTextStyles.body,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Expands, or collapses back. Expansion is widget state only — never
  /// persisted — and collapsing fires nothing.
  void _toggleExpanded() {
    final expanding = !_expanded;
    setState(() => _expanded = expanding);
    if (!expanding) return;
    // Rows shown after the expand, computed at tap time so a dismissal that
    // raced the tap cannot report a stale number.
    final count = context
        .read<RecommendationProvider>()
        .items
        .take(widget.maxItems)
        .length;
    AnalyticsService.maybeInstance?.track(
      'for_you_expanded',
      properties: {'count': count},
    );
  }

  /// Hides the card from the card itself: opts out via the provider (which
  /// notifies, so the card unmounts) and offers an Undo snackbar. Everything
  /// the Undo action needs — provider, messenger, strings, locale tag — is
  /// captured before the opt-out lands: the action fires after this State is
  /// gone, and touching `context` or `mounted` there is a real crash path,
  /// not a style nit.
  void _hideFromCard() {
    final provider = context.read<RecommendationProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    AnalyticsService.maybeInstance?.track(
      'for_you_setting_toggled',
      properties: {'enabled': false, 'source': 'card'},
    );
    unawaited(provider.setOptedOut(true));
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(l10n.forYouHiddenMessage),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () {
            AnalyticsService.maybeInstance?.track(
              'for_you_setting_toggled',
              properties: {'enabled': true, 'source': 'card_undo'},
            );
            // Sequential on purpose: the provider must be re-enabled
            // before the reload, or ensureLoaded would only hit the
            // opt-out gate again.
            unawaited(
              provider
                  .setOptedOut(false)
                  .then((_) => provider.ensureLoaded(localeTag)),
            );
          },
        ),
      ),
    );
  }
}

/// One recommended bean, rendered as its own [StockBeanCard]. Stateless on
/// purpose: the provider owns all state and notifies on every change.
class _ForYouRow extends StatelessWidget {
  const _ForYouRow({required this.item, required this.index});

  final BeanRecommendation item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final slug = item.roasterSlug;
    final hasSlug = slug != null && slug.isNotEmpty;
    final productUri = buildStockProductUrl(
      item.productUrl,
      campaign: 'for_you',
    );

    final roasterLine = item.mode == 'your_roaster'
        ? '${item.roasterName}'
              '${l10n.summarySeparator}${l10n.forYouYourRoaster}'
        : item.roasterName;
    final reasonLine = _reasonOrOriginLine(l10n, Localizations.localeOf(context));

    return StockBeanCard(
      title: item.beanName,
      subtitle: roasterLine,
      body: reasonLine,
      imageUrl: item.imageUrl,
      logoUrl: item.roasterLogoUrl,
      logoMirrorUrl: item.roasterLogoMirrorUrl,
      // Tapping the card body (not the buttons) opens the roaster's profile.
      onTap: hasSlug
          ? () {
              _track(context, 'for_you_pick_tapped');
              context.router.push(RoasterProfileRoute(
                slug: slug,
                highlightStockId: item.stockId,
              ));
            }
          : null,
      actions: [
        if (productUri != null)
          Semantics(
            identifier: 'forYouView_$index',
            child: AppTextButton(
              label: l10n.forYouViewAtRoaster,
              onPressed: () {
                _openAtRoaster(context, productUri);
              },
              isFullWidth: false,
              // No leading inset: the label lines up with the text above it.
              padding: const EdgeInsetsDirectional.only(
                end: AppSpacing.base,
                top: AppSpacing.xs,
                bottom: AppSpacing.xs,
              ),
              textStyle: AppTextStyles.body,
            ),
          ),
        Semantics(
          identifier: 'forYouDismiss_$index',
          child: AppTextButton(
            label: l10n.forYouNotForMe,
            onPressed: () {
              _dismiss(context);
            },
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

  /// The pick's reason; when the server sent none, the origin countries
  /// (" · "-joined, codes the app cannot name are skipped). Null when there
  /// is nothing at all to show — no placeholder on purpose.
  String? _reasonOrOriginLine(AppLocalizations l10n, Locale locale) {
    final reason = item.reason;
    if (reason != null && reason.trim().isNotEmpty) return reason;
    final names = <String>[];
    for (final code in item.originCountryCodes) {
      final name = localizedCountryName(code, locale);
      if (name != null && name.trim().isNotEmpty) names.add(name);
    }
    if (names.isEmpty) return null;
    return names.join(l10n.summarySeparator);
  }

  void _openAtRoaster(BuildContext context, Uri uri) {
    _track(context, 'for_you_link_opened');
    final provider = context.read<RecommendationProvider>();
    // Fire-and-forget attribution; it must never delay opening the page.
    unawaited(provider.logLinkOpened(item.stockId));
    unawaited(launchStockProductLink(uri));
  }

  void _dismiss(BuildContext context) {
    _track(context, 'for_you_dismissed');
    // Not awaited: the provider notifies and the row disappears.
    unawaited(context.read<RecommendationProvider>().dismiss(item.stockId));
  }

  void _track(BuildContext context, String event) {
    AnalyticsService.maybeInstance?.track(
      event,
      properties: {
        'stock_id': item.stockId,
        'position': index,
        'mode': item.mode ?? 'unknown',
      },
    );
  }
}
