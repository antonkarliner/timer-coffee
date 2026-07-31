// lib/widgets/finish/whats_new_card.dart
//
// Finish-screen duplicate of the home-screen launch popup (plan 039, Item C
// / Phase C2). Occupies the same single-card slot as the anniversary/
// in-sync/bean-review-nudge/coffee-fact cards, ranked below the review nudge
// (decision D3) — see `finish_slot_resolver.dart`.
//
// Deliberately a PASSIVE card, not a modal: the friction Item C exists to
// fix was never "home screen", it was a blocking dialog standing between the
// user and their goal. This card shows a teaser and taps to expand the full
// markdown in a dialog, matching `launch_popup.dart`'s content rendering.
//
// The card is dependency-injected / widget-testable, mirroring
// `bean_review_nudge_card.dart`'s shape: the caller supplies the resolved
// [popup], [locale], [budgetService], and [prefs]; the card owns its own
// render-gated bookkeeping (impression recording + an independent,
// finish-only seen-state key) so a reflex-dismissal of the home popup can
// never suppress this exposure, and vice versa (plan 039, "Independent
// seen-state per surface").
//
// Emits the same three analytics events C1 added to `launch_popup.dart` —
// `popup_shown`, `popup_dismissed`, `popup_link_tapped` — but tagged
// `source_screen: 'finish'` instead of `'home'`, so the two surfaces are
// distinguishable in the same analytics dimension.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../models/launch_popup_model.dart';
import '../../services/analytics_service.dart';
import '../../services/engagement_budget_service.dart';
import '../../theme/design_tokens.dart';
import '../base_buttons.dart';

/// Source-screen tag on every popup analytics event fired from this card —
/// mirrors `launch_popup.dart`'s `_kSourceScreen` ('home'), but 'finish' so
/// the dimension stays consistent across both surfaces per plan 039.
const String kWhatsNewCardSourceScreen = 'finish';

/// Prefs key prefix for this card's independent seen-state, kept separate
/// from the home popup's `lastPopupId_<locale>` (plan 039, "Independent
/// seen-state per surface" — sharing one flag would let a reflex-Close at
/// home suppress the finish exposure too).
String whatsNewCardSeenKey(String locale) => 'lastPopupIdSeenAtFinish_$locale';

class WhatsNewCard extends StatefulWidget {
  final LaunchPopupModel popup;
  final String locale;
  final EngagementBudgetService budgetService;
  final SharedPreferences prefs;

  const WhatsNewCard({
    super.key,
    required this.popup,
    required this.locale,
    required this.budgetService,
    required this.prefs,
  });

  @override
  State<WhatsNewCard> createState() => _WhatsNewCardState();
}

class _WhatsNewCardState extends State<WhatsNewCard> {
  bool _impressionRecorded = false;

  @override
  void initState() {
    super.initState();
    // Impression bookkeeping is render-gated, matching
    // BeanReviewNudgeCard: only this card's own first frame writes the
    // finish-only seen-state and burns a budget entry, never the upstream
    // slot decision.
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordImpression());
  }

  Future<void> _recordImpression() async {
    if (_impressionRecorded) return;
    _impressionRecorded = true;

    await widget.prefs.setInt(
      whatsNewCardSeenKey(widget.locale),
      widget.popup.id,
    );

    // Shares its dedup key with the home popup's `home_popup` entry when the
    // `askId` (the popup id) matches, so the two surfaces' exposures of the
    // same popup count once toward the engagement budget cap — see
    // EngagementBudgetService's dedup rule and plan 039's "home + finish
    // popup exposures of the same popup_id count once" rule. Without this
    // call that rule is dead code in production (nothing else writes a
    // `finish_popup` entry).
    await widget.budgetService.recordAsk(
      surface: EngagementSurface.finishPopup,
      askId: widget.popup.id.toString(),
    );

    AnalyticsService.maybeInstance?.track('popup_shown', properties: {
      'popup_id': widget.popup.id,
      'source_screen': kWhatsNewCardSourceScreen,
      'locale': widget.locale,
    });
  }

  Future<void> _openExpanded() async {
    // showDialog<bool> resolves to `true` only when the Close button popped
    // it explicitly; a barrier tap or the system back gesture resolves to
    // `null` — the same `dismiss_method` derivation as `launch_popup.dart`.
    final closedExplicitly = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          title: Text(AppLocalizations.of(context)!.whatsnewtitle),
          content: SingleChildScrollView(child: _buildMarkdown(context)),
          actions: <Widget>[
            AppTextButton(
              label: AppLocalizations.of(context)!.whatsnewclose,
              isFullWidth: false,
              height: AppButton.heightSmall,
              padding: AppButton.paddingSmall,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    AnalyticsService.maybeInstance?.track('popup_dismissed', properties: {
      'popup_id': widget.popup.id,
      'source_screen': kWhatsNewCardSourceScreen,
      'dismiss_method': closedExplicitly == true ? 'close' : 'barrier_or_back',
    });
  }

  Widget _buildMarkdown(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyMedium;
    final linkColor = Colors.lightBlue;

    final styleSheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: baseStyle,
      a: baseStyle?.copyWith(color: linkColor),
    );

    return MarkdownBody(
      data: widget.popup.content,
      styleSheet: styleSheet,
      selectable: false,
      softLineBreak: true,
      onTapLink: (text, href, title) async {
        if (href == null) return;
        final hrefType = href.startsWith('app://') ? 'deep_link' : 'external';
        AnalyticsService.maybeInstance?.track('popup_link_tapped', properties: {
          'popup_id': widget.popup.id,
          'source_screen': kWhatsNewCardSourceScreen,
          'href_type': hrefType,
        });
        if (href.startsWith('app://')) {
          final routePath = href.substring(6);
          if (context.mounted) {
            context.router.pushPath(routePath);
          }
          return;
        }
        final uri = Uri.parse(href);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.couldNotOpenLink),
              ),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Semantics(
      identifier: 'whatsNewCard',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        child: Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: _openExpanded,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Symbols.campaign,
                        color: theme.colorScheme.primary,
                        size: AppIconSize.medium,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        l10n.whatsnewtitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.finishWhatsNewCardSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
