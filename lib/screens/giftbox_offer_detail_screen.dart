import 'dart:io' show Platform;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../models/gift_offer_model.dart';
import '../providers/database_provider.dart';
import '../providers/snow_provider.dart';
import '../theme/design_tokens.dart';
import '../utils/app_logger.dart';
import '../widgets/gift_discount_chip.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../utils/region_labels.dart';

@RoutePage()
class GiftBoxOfferDetailScreen extends StatefulWidget {
  final String slug;
  const GiftBoxOfferDetailScreen({
    super.key,
    @PathParam('slug') required this.slug,
  });

  @override
  State<GiftBoxOfferDetailScreen> createState() =>
      _GiftBoxOfferDetailScreenState();
}

class _GiftBoxOfferDetailScreenState extends State<GiftBoxOfferDetailScreen> {
  static const _installIdKey = 'giftbox_install_id';

  GiftOffer? _offer;
  bool _loading = true;
  String? _error;
  Locale? _lastLocale;
  int _promoCopySeq = 0;
  bool _showPromoCopied = false;

  Future<String?> _getOrCreateInstallId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var iid = prefs.getString(_installIdKey);
      iid ??= const Uuid().v4();
      await prefs.setString(_installIdKey, iid);
      return iid;
    } catch (_) {
      return null; // still fine: tracking without iid
    }
  }

  Future<String?> _getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      return null;
    }
  }

  String _platformParam() {
    if (kIsWeb) {
      return switch (defaultTargetPlatform) {
        TargetPlatform.iOS => 'ios',
        TargetPlatform.android => 'android',
        _ => 'web',
      };
    }
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'other';
  }

  Future<Uri> _buildTrackedOfferUri(GiftOffer offer) async {
    final slug = (offer.slug ?? widget.slug).trim();

    // Fallback: no slug? open direct partner URL
    if (slug.isEmpty || offer.websiteUrl == null || offer.websiteUrl!.isEmpty) {
      return Uri.parse(offer.websiteUrl ?? '');
    }

    final locale = Localizations.localeOf(context).toLanguageTag();
    final platform = _platformParam();

    final iid = await _getOrCreateInstallId();
    final appVersion = await _getAppVersion();

    return Uri.https('timer.coffee', '/go/$slug', {
      'src': 'app',
      'p': platform,
      'l': locale,
      if (appVersion != null) 'v': appVersion,
      if (iid != null) 'iid': iid,
    });
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
      _offer = null;
      _showPromoCopied = false;
    });
    try {
      final db = context.read<DatabaseProvider>();
      final offer = await db.fetchGiftOfferBySlug(
        widget.slug,
        locale: locale,
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _offer = offer;
        _loading = false;
        if (offer == null) _error = l10n.holidayGiftBoxOfferUnavailable;
      });
    } catch (e) {
      AppLogger.error('GiftBox offer load failed (slug=${widget.slug})',
          errorObject: e);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _offer = null;
        _loading = false;
        _error = l10n.holidayGiftBoxOfferUnavailable;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isSnowing = context.watch<SnowEffectProvider>().isSnowing;
    final offer = _offer;
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
        title: Text(offer?.partnerName ?? l10n.holidayGiftBoxTitle),
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
          child: _buildBody(theme, l10n, offer),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations l10n, GiftOffer? offer) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (offer == null) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        children: [
          Text(_error ?? l10n.holidayGiftBoxOfferUnavailable,
              style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: () => _load(Localizations.localeOf(context)),
            child: Text(l10n.holidayGiftBoxRetry),
          ),
        ],
      );
    }

    final validityLabel = _validityLabel(context, l10n, offer);
    final hasTerms = offer.termsAndConditions != null &&
        offer.termsAndConditions!.isNotEmpty;
    final showCta = offer.websiteUrl != null;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      children: [
        _heroImage(offer),
        if (_expiringSoonLabel(l10n, offer.validTo) case final String label)
          ...[
            const SizedBox(height: AppSpacing.sm),
            _ExpiringSoonBanner(label: label),
          ],
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
            if (validityLabel != null)
              _chip(validityLabel, theme, leadingIcon: Icons.event),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (offer.description != null && offer.description!.isNotEmpty) ...[
          Text(offer.description!, style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.base),
        ],
        if (offer.promoCode != null) ...[
          _promoField(context, theme, l10n, offer),
          const SizedBox(height: AppSpacing.base),
        ],
        if (hasTerms) _termsCard(theme, l10n, offer),
        if (showCta) ...[
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final uri = await _buildTrackedOfferUri(offer);
                  await _launchUri(uri);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
      ],
    );
  }

  String? _expiringSoonLabel(AppLocalizations l10n, DateTime? validTo) {
    if (validTo == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final localValidTo = validTo.toLocal();
    final validToDate =
        DateTime(localValidTo.year, localValidTo.month, localValidTo.day);
    final daysLeft = validToDate.difference(today).inDays;
    if (daysLeft < 0 || daysLeft > 7) return null;
    return l10n.holidayGiftBoxEndsInDays(daysLeft);
  }

  Widget _heroImage(GiftOffer offer) {
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
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    GiftOffer offer,
  ) {
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
                    child: _showPromoCopied
                        ? Text(
                            l10n.holidayGiftBoxPromoCopied,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              offer.promoCode!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                  letterSpacing: 1.0,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ]),
                            ),
                          ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _copyCode(offer.promoCode!),
                    icon: Icon(_showPromoCopied ? Icons.check : Icons.copy),
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

  Widget _termsCard(ThemeData theme, AppLocalizations l10n, GiftOffer offer) {
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

  String? _validityLabel(
    BuildContext context,
    AppLocalizations l10n,
    GiftOffer offer,
  ) {
    if (offer.validTo != null) {
      return l10n.holidayGiftBoxValidUntil(
        _formatDate(context, offer.validTo!),
      );
    }
    return l10n.holidayGiftBoxValidWhileAvailable;
  }

  Widget _meta(ThemeData theme, AppLocalizations l10n, GiftOffer offer) {
    final validTo = offer.validTo != null
        ? l10n.holidayGiftBoxValidUntil(_formatDate(context, offer.validTo!))
        : l10n.holidayGiftBoxValidWhileAvailable;
    final updated = offer.updatedAt != null
        ? l10n.holidayGiftBoxUpdated(_formatDate(context, offer.updatedAt!))
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

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.yMMMd(locale).format(date.toLocal());
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

  void _copyCode(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
    Clipboard.setData(ClipboardData(text: trimmed));
    final seq = ++_promoCopySeq;
    setState(() => _showPromoCopied = true);
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted || _promoCopySeq != seq) return;
      setState(() => _showPromoCopied = false);
    });
  }

  Future<void> _launchUri(Uri uri) async {
    if (uri.toString().isEmpty) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotOpenLink)),
      );
    }
  }
}

class _ExpiringSoonBanner extends StatelessWidget {
  final String label;
  const _ExpiringSoonBanner({required this.label});

  @override
  Widget build(BuildContext context) {
    if (label.trim().isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final bg = theme.colorScheme.errorContainer;
    final fg = theme.colorScheme.onErrorContainer;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 16, color: fg),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
