// lib/screens/roaster_profile_screen.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/bean_review_model.dart';
import '../models/roaster_profile_model.dart';
import '../providers/bean_review_provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/roaster_profile_provider.dart';
import '../services/analytics_service.dart';
import '../theme/design_tokens.dart';
import '../widgets/base_buttons.dart';
import '../widgets/containers/section_card.dart';
import '../widgets/roaster_logo.dart';
import '../widgets/smart_back_button.dart';
import '../widgets/roaster_profile/aggregate_rating.dart';
import '../widgets/roaster_profile/review_card.dart';
import '../widgets/roaster_profile/review_form.dart';
import '../services/feature_flags/feature_flags_repository.dart';
import '../services/roaster_color_service.dart';
import '../utils/icon_utils.dart';
import '../utils/roaster_background_color.dart';
import '../app_router.gr.dart';

@RoutePage()
class RoasterProfileScreen extends StatefulWidget {
  final String slug;

  const RoasterProfileScreen({
    super.key,
    @PathParam('slug') required this.slug,
  });

  @override
  State<RoasterProfileScreen> createState() => _RoasterProfileScreenState();
}

class _RoasterProfileScreenState extends State<RoasterProfileScreen> {
  RoasterProfileModel? _profile;
  List<Map<String, dynamic>> _recipes = [];
  bool _loadingProfile = true;
  String? _error;
  RoasterColorResult? _roasterColorResult;

  // Review state
  bool _loadingReviews = true;
  bool _loadingMore = false;
  bool _hasMorePages = true;
  bool _translatingAll = false;
  static const int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadingProfile && _profile == null && _error == null) {
      _loadProfile();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profileProvider =
        Provider.of<RoasterProfileProvider>(context, listen: false);
    final reviewProvider =
        Provider.of<BeanReviewProvider>(context, listen: false);
    final locale = Localizations.localeOf(context).languageCode;

    final profile = await profileProvider.fetchProfile(widget.slug);
    if (!mounted) return;

    if (profile == null) {
      setState(() {
        _loadingProfile = false;
        _error = 'Profile not found';
      });
      return;
    }

    AnalyticsService.instance.track(
      'roaster_profile_viewed',
      properties: {
        'roaster_slug': profile.slug,
        'roaster_name': profile.roasterName,
        'roaster_id': profile.id,
        'verified': profile.adminUserId != null &&
            profile.adminUserId!.isNotEmpty,
      },
    );

    // Load recipes (only if admin user exists) and initial reviews in parallel
    final adminUserId = profile.adminUserId;
    final futures = await Future.wait([
      if (adminUserId != null && adminUserId.isNotEmpty)
        profileProvider.fetchProfileRecipes(adminUserId, locale: locale)
      else
        Future.value(<Map<String, dynamic>>[]),
      reviewProvider.fetchReviewsForRoaster(
        profile.id,
        offset: 0,
        limit: _pageSize,
      ),
      reviewProvider.fetchAggregateRating(profile.id),
    ]);

    if (!mounted) return;
    final initialReviews = futures[1] as List<BeanReviewModel>;
    setState(() {
      _profile = profile;
      _recipes = futures[0] as List<Map<String, dynamic>>;
      _loadingProfile = false;
      _loadingReviews = false;
      _hasMorePages = initialReviews.length >= _pageSize;
    });

    // Analyse logo color for screen background tinting (gated by feature flag)
    final flags =
        Provider.of<FeatureFlagsRepository>(context, listen: false);
    if (flags.roasterBackendColor) {
      final RoasterColorResult colorResult;
      if (profile.dominantColorHex != null) {
        colorResult =
            RoasterColorService.fromBackendHex(profile.dominantColorHex);
      } else {
        colorResult = await RoasterColorService.instance.analyseLogoColor(
          profile.roasterLogoUrl,
          profile.roasterLogoMirrorUrl,
        );
      }
      if (mounted) {
        setState(() => _roasterColorResult = colorResult);
      }
    }
  }

  void _onScroll() {
    if (_loadingMore || _profile == null || !_hasMorePages) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreReviews();
    }
  }

  Future<void> _loadMoreReviews() async {
    final reviewProvider =
        Provider.of<BeanReviewProvider>(context, listen: false);
    final currentCount =
        reviewProvider.reviewsForRoaster(_profile!.id).length;

    setState(() => _loadingMore = true);
    final newReviews = await reviewProvider.fetchReviewsForRoaster(
      _profile!.id,
      offset: currentCount,
      limit: _pageSize,
    );
    if (mounted) {
      setState(() {
        _loadingMore = false;
        if (newReviews.length < _pageSize) _hasMorePages = false;
      });
    }
  }

  Future<void> _openReviewForm({
    BeanReviewModel? existingReview,
  }) async {
    if (_profile == null) return;
    final submitted = await showReviewForm(
      context,
      roasterProfileId: _profile!.id,
      roasterName: _profile!.roasterName,
      existingReview: existingReview,
      sourceScreen: 'roaster_profile',
    );
    if (submitted && mounted) {
      // Reload reviews and ratings
      final reviewProvider =
          Provider.of<BeanReviewProvider>(context, listen: false);
      setState(() => _loadingReviews = true);
      await reviewProvider.fetchReviewsForRoaster(
        _profile!.id,
        offset: 0,
        limit: _pageSize,
      );
      await reviewProvider.fetchAggregateRating(_profile!.id);
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  /// Filters the visible reviews down to those that need translation
  /// (non-empty text, source language unknown or different from reader,
  /// no cached translation result yet).
  List<String> _collectTranslatableReviewIds(
    List<BeanReviewModel> reviews,
    BeanReviewProvider provider,
    String readerLocale,
  ) {
    final reader = readerLocale.toLowerCase();
    final ids = <String>[];
    for (final r in reviews) {
      if (r.reviewText == null || r.reviewText!.isEmpty) continue;
      final detected = r.detectedSourceLocale?.toLowerCase();
      if (detected != null && detected == reader) continue;
      final cached = provider.cachedTranslation(
        reviewId: r.id,
        targetLocale: readerLocale,
      );
      if (cached != null) continue;
      ids.add(r.id);
    }
    return ids;
  }

  Future<void> _translateAllReviews(
    BeanReviewProvider provider,
    List<String> reviewIds,
    String readerLocale,
  ) async {
    setState(() => _translatingAll = true);
    await provider.fetchTranslationsBatch(
      reviewIds: reviewIds,
      targetLocale: readerLocale,
    );
    if (mounted) setState(() => _translatingAll = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _roasterColorResult != null
          ? roasterBackgroundColor(
              result: _roasterColorResult!,
              brightness: Theme.of(context).brightness,
            )
          : null,
      appBar: AppBar(
        leading: const SmartBackButton(),
        title: Text(_profile?.roasterName ?? ''),
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(context, l10n),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    final profile = _profile!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id;
    final isRoasterAdmin = currentUserId != null &&
        currentUserId == profile.adminUserId;
    final isVerified = profile.adminUserId != null &&
        profile.adminUserId!.isNotEmpty;

    final bgStart =
        isLight ? Colors.grey.shade400 : Colors.grey.shade800;
    final bgEnd =
        isLight ? Colors.grey.shade300 : Colors.grey.shade700;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Hero header card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.base,
              AppSpacing.base,
              AppSpacing.base,
              AppSpacing.sm,
            ),
            child: Card(
              elevation: 4,
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [bgStart, bgEnd],
                  ),
                ),
                child: Column(
                  children: [
                    // Logo area with padding
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.lg,
                        AppSpacing.xl,
                        AppSpacing.lg,
                      ),
                      child: Center(
                        child: RoasterLogo(
                          originalUrl: profile.roasterLogoUrl,
                          mirrorUrl: profile.roasterLogoMirrorUrl,
                          height: 140,
                          width: 220,
                          borderRadius: AppRadius.card,
                          forceFit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // Separator + location/links area
                    if (profile.locationLabel != null ||
                        _hasLinks(profile) ||
                        isVerified) ...[
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: colorScheme.onSurface.withOpacity(0.15),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        child: Column(
                          children: [
                            if (profile.locationLabel != null)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: AppIconSize.medium,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    profile.locationLabel!,
                                    style: AppTextStyles.body,
                                  ),
                                  if (isVerified) ...[
                                    const SizedBox(width: AppSpacing.xs),
                                    Icon(
                                      Icons.verified,
                                      size: AppIconSize.medium,
                                      color: colorScheme.tertiary,
                                    ),
                                  ],
                                ],
                              )
                            else if (isVerified)
                              Icon(
                                Icons.verified,
                                size: AppIconSize.medium,
                                color: colorScheme.tertiary,
                              ),
                            if (_hasLinks(profile)) ...[
                              if (profile.locationLabel != null)
                                const SizedBox(height: AppSpacing.xs),
                              _LinksRow(profile: profile),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),

        // About / description section
        if (profile.description != null &&
            profile.description!.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.sm,
              ),
              child: SectionCard(
                title: l10n.about,
                icon: Icons.info_outline,
                isCollapsible: false,
                child: Text(
                  profile.description!,
                  style: AppTextStyles.body,
                ),
              ),
            ),
          ),

        // Recipes section
        if (_recipes.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.sm,
              ),
              child: SectionCard(
                title: l10n.roasterRecipes,
                icon: Icons.menu_book_outlined,
                isCollapsible: true,
                initiallyExpanded: true,
                paddingChild: false,
                child: _RecipeList(recipes: _recipes),
              ),
            ),
          ),

        // Reviews section — unified card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.sm,
            ),
            child: SectionCard(
              title: l10n.roasterReviews,
              icon: Symbols.rate_review,
              isCollapsible: false,
              paddingChild: false,
              trailing: AppTextButton(
                label: l10n.writeReview,
                onPressed: _openReviewForm,
                isFullWidth: false,
              ),
              child: Consumer<BeanReviewProvider>(
                builder: (context, reviewProvider, _) {
                  final summary =
                      reviewProvider.ratingSummary(profile.id);
                  final reviews =
                      reviewProvider.reviewsForRoaster(profile.id);
                  final readerLocale = context
                      .watch<RecipeProvider>()
                      .currentLocale
                      .languageCode
                      .toLowerCase();
                  final translatableIds = _collectTranslatableReviewIds(
                    reviews,
                    reviewProvider,
                    readerLocale,
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.cardPadding,
                          AppSpacing.sm,
                          AppSpacing.cardPadding,
                          AppSpacing.sm,
                        ),
                        child: AggregateRating(
                          avgRating: summary?.avgRating,
                          reviewCount: summary?.reviewCount ?? 0,
                        ),
                      ),
                      if (translatableIds.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.cardPadding,
                            0,
                            AppSpacing.cardPadding,
                            AppSpacing.sm,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _translatingAll
                                ? const SizedBox(
                                    width: AppIconSize.small,
                                    height: AppIconSize.small,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : AppTextButton(
                                    label: l10n.translateAllReviews,
                                    onPressed: () => _translateAllReviews(
                                      reviewProvider,
                                      translatableIds,
                                      readerLocale,
                                    ),
                                    isFullWidth: false,
                                  ),
                          ),
                        ),
                      if (_loadingReviews)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.base),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (reviews.isNotEmpty) ...[
                        const Divider(height: 1),
                        ...reviews.indexed.map(
                          ((int, BeanReviewModel) entry) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            child: ReviewCard(
                              review: entry.$2,
                              isRoasterAdmin: isRoasterAdmin,
                              initiallyExpanded: entry.$1 == 0,
                              onEdit: () => _openReviewForm(
                                  existingReview: entry.$2),
                            ),
                          ),
                        ),
                      ],
                      if (_loadingMore)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.base),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        // Disclaimer — collapsible, collapsed by default
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.base,
              AppSpacing.sm,
              AppSpacing.base,
              AppSpacing.sm,
            ),
            child: SectionCard(
              title: l10n.roasterDisclaimerTitle,
              icon: Icons.info_outline,
              isCollapsible: true,
              initiallyExpanded: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DisclaimerItem(text: l10n.roasterDisclaimerTrademark),
                  const SizedBox(height: AppSpacing.sm),
                  _DisclaimerItem(text: l10n.roasterDisclaimerReviews),
                  const SizedBox(height: AppSpacing.sm),
                  _DisclaimerItem(text: l10n.roasterDisclaimerDetails),
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
      ],
    );
  }

  bool _hasLinks(RoasterProfileModel p) =>
      p.websiteUrl != null ||
      p.instagramUrl != null ||
      p.twitterUrl != null ||
      p.facebookUrl != null ||
      p.tiktokUrl != null;
}

// ────────────────────────────────────────────────────────────
// Links row
// ────────────────────────────────────────────────────────────

class _LinksRow extends StatelessWidget {
  final RoasterProfileModel profile;

  const _LinksRow({required this.profile});

  Future<void> _open(String? url, String linkType) async {
    if (url == null) return;
    var uri = Uri.tryParse(url);
    if (uri == null) return;

    // For the website link, attach UTM params for future attribution.
    if (linkType == 'website') {
      uri = _withUtm(uri);
    }

    AnalyticsService.instance.track(
      'roaster_link_tapped',
      properties: {
        'link_type': linkType,
        'roaster_slug': profile.slug,
        'roaster_name': profile.roasterName,
        'roaster_id': profile.id,
      },
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Appends Timer.Coffee UTM parameters to [uri] without clobbering any UTM
  /// params the roaster may already have set on their own link.
  Uri _withUtm(Uri uri) {
    const utm = {
      'utm_source': 'timercoffee',
      'utm_medium': 'app',
      'utm_campaign': 'roaster_profile',
    };
    final params = Map<String, String>.from(uri.queryParameters);
    utm.forEach((key, value) => params.putIfAbsent(key, () => value));
    return uri.replace(queryParameters: params);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final links = <({Widget icon, String? url, String type})>[
      (
        icon: Icon(Icons.language_outlined),
        url: profile.websiteUrl,
        type: 'website',
      ),
      (
        icon: FaIcon(FontAwesomeIcons.instagram,
            color: colorScheme.primary, size: AppIconSize.medium),
        url: profile.instagramUrl,
        type: 'instagram',
      ),
      (
        icon: FaIcon(FontAwesomeIcons.xTwitter,
            color: colorScheme.primary, size: AppIconSize.medium),
        url: profile.twitterUrl,
        type: 'twitter',
      ),
      (
        icon: Icon(Icons.facebook_outlined),
        url: profile.facebookUrl,
        type: 'facebook',
      ),
      (
        icon: FaIcon(FontAwesomeIcons.tiktok,
            color: colorScheme.primary, size: AppIconSize.medium),
        url: profile.tiktokUrl,
        type: 'tiktok',
      ),
    ].where((l) => l.url != null).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: links.map((l) {
        return IconButton(
          icon: l.icon,
          color: colorScheme.primary,
          iconSize: AppIconSize.medium,
          onPressed: () => _open(l.url, l.type),
        );
      }).toList(),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Disclaimer bullet item
// ────────────────────────────────────────────────────────────

class _DisclaimerItem extends StatelessWidget {
  final String text;
  const _DisclaimerItem({required this.text});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    final style = AppTextStyles.caption.copyWith(color: color);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• ', style: style),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────
// Recipe list (simple tiles from raw RPC data)
// ────────────────────────────────────────────────────────────

class _RecipeList extends StatelessWidget {
  final List<Map<String, dynamic>> recipes;

  const _RecipeList({required this.recipes});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: recipes.map((r) {
        final name = r['name'] as String? ?? r['id'] as String? ?? '—';
        final brewingMethodId = r['brewing_method_id'] as String?;
        final recipeId = r['id'] as String?;
        return ListTile(
          leading: getIconByBrewingMethod(brewingMethodId),
          title: Text(name, style: AppTextStyles.body),
          onTap: recipeId != null && brewingMethodId != null
              ? () => context.router.push(RecipeDetailRoute(
                    brewingMethodId: brewingMethodId,
                    recipeId: recipeId,
                  ))
              : null,
        );
      }).toList(),
    );
  }
}
