import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_router.gr.dart';
import '../models/bean_recommendation_model.dart';
import '../providers/recommendation_provider.dart';
import '../services/analytics_service.dart';
import '../theme/design_tokens.dart';
import '../utils/country_names.dart';
import 'base_buttons.dart';
import 'roaster_logo.dart';

/// Adds Timer.Coffee UTM parameters to a recommendation's product link.
///
/// Only http/https URLs are accepted — anything else (or an unparseable
/// string) returns null and the link is not offered. UTM parameters the
/// roaster already put on their link are preserved, not overwritten.
@visibleForTesting
Uri? buildForYouProductUrl(String? rawUrl) {
  if (rawUrl == null) return null;
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri == null) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (uri.host.isEmpty) return null;
  Map<String, String> params;
  try {
    params = Map<String, String>.from(uri.queryParameters);
  } on FormatException {
    // Malformed percent-encoding in the query: open the link as-is rather
    // than lose it (or crash) over attribution.
    return uri;
  }
  const utm = {
    'utm_source': 'timer.coffee',
    'utm_medium': 'app',
    'utm_campaign': 'for_you',
  };
  utm.forEach((key, value) => params.putIfAbsent(key, () => value));
  return uri.replace(queryParameters: params);
}

/// The Hub's "For you" card (plan 017, phase 5a): up to [maxItems] in-stock
/// beans picked for the user by the recommendation backend.
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

  /// Capture the rendered state, then report after the frame. Lifetime
  /// guards survive rebuilds, locale changes and optimistic dismissals.
  void _scheduleVisibilityAnalytics(RecommendationProvider provider) {
    final items = provider.state == RecommendationState.ready
        ? provider.items.take(widget.maxItems).toList(growable: false)
        : const <BeanRecommendation>[];
    final status = provider.state == RecommendationState.hidden
        ? provider.unavailableStatus
        : null;
    final country = provider.lastCountryCode;
    if ((_shownTracked || items.isEmpty) &&
        (status == null || _unavailableStatusesTracked.contains(status))) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_shownTracked && items.isNotEmpty) {
        _shownTracked = true;
        final modes =
            items.map((item) => item.mode ?? 'unknown').toSet().toList()
              ..sort();
        AnalyticsService.maybeInstance?.track(
          'for_you_shown',
          properties: {'count': items.length, 'modes': modes.join(',')},
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
    final items = provider.items.take(widget.maxItems).toList(growable: false);

    // Container matches CoffeeJourneyCard exactly so the two Hub cards line
    // up: flat card, AppRadius.card, outlineVariant hairline, same margins.
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: AppStroke.border,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.forYouTitle, style: AppTextStyles.sectionHeader),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.forYouSubtitle,
                style: AppTextStyles.caption.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final (index, item) in items.indexed) ...[
                if (index > 0)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: theme.colorScheme.outlineVariant,
                  ),
                Semantics(
                  identifier: 'forYouItem_$index',
                  child: _ForYouRow(item: item, index: index),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One recommended bean. Stateless on purpose: the provider owns all state
/// and notifies on every change.
class _ForYouRow extends StatelessWidget {
  const _ForYouRow({required this.item, required this.index});

  final BeanRecommendation item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final slug = item.roasterSlug;
    final hasSlug = slug != null && slug.isNotEmpty;
    final productUri = buildForYouProductUrl(item.productUrl);

    final roasterLine = item.mode == 'your_roaster'
        ? '${item.roasterName}'
              '${l10n.summarySeparator}${l10n.forYouYourRoaster}'
        : item.roasterName;
    final reasonLine = _reasonOrOriginLine(l10n, Localizations.localeOf(context));

    return InkWell(
      // Tapping the row body (not the buttons) opens the roaster's profile.
      onTap: hasSlug
          ? () {
              _track('for_you_pick_tapped');
              context.router.push(RoasterProfileRoute(slug: slug));
            }
          : null,
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RoasterLogo(
              originalUrl: item.roasterLogoUrl,
              mirrorUrl: item.roasterLogoMirrorUrl,
              placeholderIcon: Icons.storefront_outlined,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.beanName,
                    style: AppTextStyles.itemTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    roasterLine,
                    style: AppTextStyles.caption.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (reasonLine != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      reasonLine,
                      style: AppTextStyles.body,
                      // Reasons run to ~140 characters; three lines cut
                      // most of them off on a phone.
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  // Wrap, not Row: the two localized labels together can
                  // exceed a 320 pt row and must wrap onto a second line.
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (productUri != null)
                        Semantics(
                          identifier: 'forYouView_$index',
                          child: AppTextButton(
                            label: l10n.forYouViewAtRoaster,
                            onPressed: () {
                              _openAtRoaster(context, productUri);
                            },
                            isFullWidth: false,
                            // No leading inset: the label lines up with
                            // the text above it.
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
    _track('for_you_link_opened');
    final provider = context.read<RecommendationProvider>();
    // Fire-and-forget attribution; it must never delay opening the page.
    unawaited(provider.logLinkOpened(item.stockId));
    unawaited(_launch(uri));
  }

  Future<void> _launch(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // No app on this device can open the link; nothing to show.
    }
  }

  void _dismiss(BuildContext context) {
    _track('for_you_dismissed');
    // Not awaited: the provider notifies and the row disappears.
    unawaited(context.read<RecommendationProvider>().dismiss(item.stockId));
  }

  void _track(String event) {
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
