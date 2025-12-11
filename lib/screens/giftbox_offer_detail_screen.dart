import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/gift_offer_model.dart';
import '../theme/design_tokens.dart';
import '../widgets/gift_discount_chip.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../utils/region_labels.dart';

@RoutePage()
class GiftBoxOfferDetailScreen extends StatelessWidget {
  final GiftOffer offer;
  const GiftBoxOfferDetailScreen({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(offer.partnerName)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        children: [
          _heroImage(),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  offer.partnerName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize:
                        (theme.textTheme.headlineSmall?.fontSize ?? 24) + 2,
                  ),
                ),
              ),
              ..._discountChip(context, offer),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              ...offer.regions
                  .map((r) => _chip(localizeRegion(r, l10n), theme,
                      leadingIcon: Icons.location_on))
                  .toList(),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (offer.description != null && offer.description!.isNotEmpty) ...[
            Text(offer.description!, style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.base),
          ],
          if (offer.promoCode != null) ...[
            _promoField(context, theme, l10n),
            const SizedBox(height: AppSpacing.base),
          ],
          if (offer.termsAndConditions != null &&
              offer.termsAndConditions!.isNotEmpty)
            _termsCard(theme, l10n),
          const SizedBox(height: AppSpacing.lg),
          if (offer.websiteUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _launchUrl(offer.websiteUrl!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(
                    (offer.cta ?? '').trim().isNotEmpty
                        ? offer.cta!.trim()
                        : l10n.holidayGiftBoxVisitSite,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _heroImage() {
    if (offer.imageUrl == null || offer.imageUrl!.isEmpty) {
      return _placeholderHero();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: Container(
        height: 240,
        width: double.infinity,
        color: Colors.grey.shade100,
        alignment: Alignment.center,
        child: Image.network(
          offer.imageUrl!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _placeholderHero(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _placeholderHero();
          },
        ),
      ),
    );
  }

  Widget _placeholderHero() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: const Center(child: Icon(Icons.image_not_supported, size: 48)),
    );
  }

  Widget _promoField(
      BuildContext context, ThemeData theme, AppLocalizations l10n) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('${l10n.holidayGiftBoxPromoCode}:',
              style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  height: 1.2)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                    color: theme.colorScheme.outlineVariant, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        offer.promoCode!,
                        style: theme.textTheme.titleMedium?.copyWith(
                            letterSpacing: 1.0,
                            fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _copyCode(context, offer.promoCode!, l10n),
                    icon: const Icon(Icons.copy),
                    splashRadius: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ]);
  }

  Widget _termsCard(ThemeData theme, AppLocalizations l10n) {
    final termsText = offer.termsAndConditions ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.holidayGiftBoxTerms}:',
          style: theme.textTheme.bodyLarge
              ?.copyWith(fontWeight: FontWeight.w600, height: 1.2),
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          termsText,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.start,
        ),
      ],
    );
  }

  Widget _meta(ThemeData theme, AppLocalizations l10n) {
    final validTo = offer.validTo != null
        ? l10n.holidayGiftBoxValidUntil(_formatDate(offer.validTo!))
        : l10n.holidayGiftBoxValidWhileAvailable;
    final updated = offer.updatedAt != null
        ? l10n.holidayGiftBoxUpdated(_formatDate(offer.updatedAt!))
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(validTo, style: theme.textTheme.bodySmall),
        if (updated != null)
          Text(updated,
              style:
                  theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
        Text(l10n.holidayGiftBoxLanguage(offer.localeUsed.toLanguageTag()),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _chip(String label, ThemeData theme,
      {Color? color, Color? textColor, IconData? leadingIcon}) {
    final bg = color ?? theme.colorScheme.surfaceVariant;
    final fg = textColor ?? theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 14, color: fg),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: fg)),
        ],
      ),
    );
  }

  List<Widget> _discountChip(BuildContext context, GiftOffer offer) {
    final chip = buildDiscountChip(context, offer);
    if (chip == null) return const [];
    return [chip];
  }

  void _copyCode(BuildContext context, String code, AppLocalizations l10n) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.holidayGiftBoxPromoCopied)));
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
