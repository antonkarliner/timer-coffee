import 'package:auto_route/auto_route.dart';
import 'package:auto_size_text_plus/auto_size_text_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:coffee_timer/l10n/app_localizations.dart';

import '../models/gift_offer_model.dart';
import '../app_router.gr.dart';
import '../providers/database_provider.dart';
import '../providers/snow_provider.dart';
import '../services/region_service.dart';
import '../theme/design_tokens.dart';
import '../utils/app_logger.dart';
import '../widgets/gift_discount_chip.dart';
import '../utils/region_labels.dart';

@RoutePage()
class GiftBoxListScreen extends StatefulWidget {
  const GiftBoxListScreen({super.key});

  @override
  State<GiftBoxListScreen> createState() => _GiftBoxListScreenState();
}

class _GiftBoxListScreenState extends State<GiftBoxListScreen> {
  late final RegionService _regionService;
  List<GiftOffer> _offers = [];
  bool _loading = true;
  String? _regionCode;
  String? _error;
  bool _showInfo = false;
  Locale? _lastLocale;

  @override
  void initState() {
    super.initState();
    _regionService = RegionService(Supabase.instance.client);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_lastLocale == null || _lastLocale != locale) {
      _lastLocale = locale;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(locale));
    }
  }

  Future<void> _load(Locale locale) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final db = Provider.of<DatabaseProvider>(context, listen: false);
      final detectedRegion =
          await _regionService.detectRegion(localeCode: locale.toLanguageTag());
      final offers = await db.fetchGiftBoxOffers(
          locale: locale, regionCode: detectedRegion);
      if (!mounted) return;
      setState(() {
        _offers = offers;
        _regionCode = detectedRegion;
        _loading = false;
      });
    } catch (e) {
      AppLogger.error('GiftBox load failed', errorObject: e);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _error = l10n.holidayGiftBoxLoadFailed;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isSnowing = context.watch<SnowEffectProvider>().isSnowing;
    final base = theme.colorScheme.surfaceVariant;
    final festiveRed = const Color(0xFFE53935);
    final festiveGreen = const Color(0xFF43A047);
    final festiveGold = const Color(0xFFFFD54F);
    final tint = theme.brightness == Brightness.dark ? 0.30 : 0.42;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(base, festiveRed, tint)!,
        Color.lerp(base, festiveGold, tint * 0.85)!,
        Color.lerp(base, festiveGreen, tint)!,
      ],
    );
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.holidayGiftBoxTitle),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: l10n.snow,
            onPressed: () =>
                context.read<SnowEffectProvider>().toggleSnowEffect(),
            icon: Icon(
              Icons.ac_unit,
              color: isSnowing
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primary.withOpacity(0.75),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: Padding(
          padding: EdgeInsets.only(
            top: kToolbarHeight + MediaQuery.of(context).padding.top,
          ),
          child: RefreshIndicator(
            onRefresh: () => _load(Localizations.localeOf(context)),
            child: _buildBody(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        children: [
          Text(_error ?? l10n.holidayGiftBoxLoadFailed,
              style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
              onPressed: () => _load(Localizations.localeOf(context)),
              child: Text(l10n.holidayGiftBoxRetry)),
        ],
      );
    }
    if (_offers.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.holidayGiftBoxNoOffers,
              style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.holidayGiftBoxNoOffersSub,
              style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      itemCount: _offers.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _header(theme);
        final offer = _offers[index - 1];
        return Padding(
          padding: EdgeInsets.only(
              bottom: index == _offers.length ? 0 : AppSpacing.base),
          child: GiftOfferCard(
            offer: offer,
            onTap: () => _openDetail(offer),
          ),
        );
      },
    );
  }

  Widget _header(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _showInfo = !_showInfo),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.holidayGiftBoxInfoTrigger,
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700)),
                Icon(_showInfo ? Icons.expand_less : Icons.expand_more,
                    size: 18),
              ],
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _showInfo
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                l10n.holidayGiftBoxInfoBody,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.start,
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _openDetail(GiftOffer offer) {
    final slug = offer.slug?.trim();
    if (slug == null || slug.isEmpty) {
      AppLogger.error('GiftBox offer is missing slug (id=${offer.id})');
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.holidayGiftBoxOfferUnavailable)),
      );
      return;
    }
    context.router.push(GiftBoxOfferDetailRoute(slug: slug));
  }
}

class GiftOfferCard extends StatelessWidget {
  final GiftOffer offer;
  final VoidCallback onTap;
  const GiftOfferCard({super.key, required this.offer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final discountChip = buildDiscountChip(context, offer);
    return Material(
      borderRadius: BorderRadius.circular(AppRadius.card),
      color: theme.colorScheme.surface,
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _image(),
                  const SizedBox(width: AppSpacing.base),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AutoSizeText(
                                offer.partnerName,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                                maxLines: 2,
                                minFontSize: 14,
                                stepGranularity: 0.5,
                                wrapWords: false,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (discountChip != null)
                              Flexible(
                                fit: FlexFit.loose,
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 120,
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.topRight,
                                      child: discountChip,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          alignment: WrapAlignment.start,
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            ...offer.regions
                                .map((r) => _chip(
                                    localizeRegion(
                                        r, AppLocalizations.of(context)!),
                                    theme))
                                .toList(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (offer.description != null && offer.description!.isNotEmpty)
                Text(
                  offer.description!,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: AppSpacing.base),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: onTap,
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
                  child: Text(l10n.holidayGiftBoxViewDetails),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, ThemeData theme,
      {Color? color, Color? textColor}) {
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
          Icon(Icons.location_on, size: 14, color: fg),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: fg)),
        ],
      ),
    );
  }

  Widget _image() {
    if (offer.imageUrl == null || offer.imageUrl!.isEmpty) {
      return _placeholderBox();
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 72,
        maxWidth: 92,
        minHeight: 60,
        maxHeight: 80,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Image.network(
            offer.imageUrl!,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _placeholderBox(),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _placeholderBox();
            },
          ),
        ),
      ),
    );
  }

  Widget _placeholderBox() {
    return Container(
      width: 92,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: const Icon(Icons.image_not_supported, size: 24),
    );
  }
}

class _PromoCodeBadge extends StatelessWidget {
  final String code;
  const _PromoCodeBadge({required this.code});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.holidayGiftBoxPromoCopied)));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(code, style: theme.textTheme.labelMedium),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.copy, size: 16),
          ],
        ),
      ),
    );
  }
}
