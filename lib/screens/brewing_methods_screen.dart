import 'package:coffeico_plus/coffeico_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import '../models/brewing_method_model.dart';
import '../providers/recipe_provider.dart';
import '../models/recipe_model.dart';
import '../app_router.gr.dart';
import '../services/analytics_service.dart';
import '../services/moments_service.dart';
import '../services/onboarding_service.dart';
import '../theme/design_tokens.dart';
import '../utils/icon_utils.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../widgets/coffee_journey_card.dart';
import '../widgets/collections_carousel.dart';

@RoutePage()
class BrewingMethodsScreen extends StatefulWidget {
  const BrewingMethodsScreen({super.key});

  @override
  State<BrewingMethodsScreen> createState() => _BrewingMethodsScreenState();
}

class _BrewingMethodsScreenState extends State<BrewingMethodsScreen> {
  /// Height (px) of a single quick-action row, used to size the pinned header.
  /// One [ListTile] row when expanded; one icon-button row when compact.
  static const double _actionRowHeight = 56.0;

  /// Cached "last used recipe" so the pinned header's extent stays stable
  /// across rebuilds (the future is re-fetched each build for freshness, but
  /// we keep the last resolved value as [FutureBuilder.initialData] so the
  /// action count — and therefore the header height — never thrashes).
  RecipeModel? _lastRecipe;

  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final allBrewingMethods = Provider.of<List<BrewingMethodModel>>(context);

    // Determine which brewing methods have recipes
    final methodsWithRecipes = <String>{};
    for (var recipe in recipeProvider.recipes) {
      methodsWithRecipes.add(recipe.brewingMethodId);
    }

    // Get user preferences
    final shownIds = recipeProvider.shownBrewingMethodIds.value;
    final hiddenIds = recipeProvider.hiddenBrewingMethodIds.value;

    final filteredBrewingMethods = allBrewingMethods.where((method) {
      bool hasRecipes = methodsWithRecipes.contains(method.brewingMethodId);
      bool isShownByUser = shownIds.contains(method.brewingMethodId);
      bool isHiddenByUser = hiddenIds.contains(method.brewingMethodId);

      if (isShownByUser) return true;
      if (isHiddenByUser) return false;
      return hasRecipes;
    }).toList();

    // Calculate the bottom padding
    final bottomPadding =
        MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight;

    final onboarding = context.watch<OnboardingService>();
    final showCollections =
        onboarding.firstBrewDone &&
        !(onboarding.shouldShowJourneyCard && !onboarding.journeyCollapsed);

    return SafeArea(
      child: FutureBuilder<RecipeModel?>(
        future: recipeProvider.getLastUsedRecipe(),
        initialData: _lastRecipe,
        builder: (context, snapshot) {
          final RecipeModel? mostRecentRecipe = snapshot.data;
          // Memoize so the next rebuild keeps a stable header extent.
          if (snapshot.connectionState == ConnectionState.done) {
            _lastRecipe = mostRecentRecipe;
          }

          final actionCount = mostRecentRecipe != null ? 3 : 2;

          return CustomScrollView(
            slivers: [
              // Big header extras — these scroll away naturally as the user
              // scrolls down (no layout jump, since they live in the scroll).
              SliverToBoxAdapter(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _CoffeeDayBanner(),
                    const CoffeeJourneyCard(),
                    if (showCollections) const CollectionsCarousel(),
                  ],
                ),
              ),
              // Quick actions — a pinned header that collapses in lockstep with
              // the scroll: full ListTiles when expanded, a compact icon row
              // once collapsed. Because it lives inside the scroll, collapsing
              // "drags" the list up with it and nothing gets hidden until it is
              // fully compact, after which the list scrolls beneath it.
              SliverPersistentHeader(
                pinned: true,
                delegate: _QuickActionsHeaderDelegate(
                  maxExtentValue: actionCount * _actionRowHeight +
                      _QuickActionsHeaderDelegate.dividerZoneHeight,
                  minExtentValue: _actionRowHeight +
                      _QuickActionsHeaderDelegate.dividerZoneHeight,
                  background: Theme.of(context).scaffoldBackgroundColor,
                  fullChild: _buildFullActions(context, mostRecentRecipe),
                  compactChild: _buildCompactActions(context, mostRecentRecipe),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.only(bottom: bottomPadding),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final brewingMethod = filteredBrewingMethods[index];
                    return Semantics(
                      identifier:
                          'brewingMethod_${brewingMethod.brewingMethodId}',
                      label: brewingMethod.brewingMethod,
                      child: ListTile(
                        leading: getIconByBrewingMethod(
                          brewingMethod.brewingMethodId,
                        ),
                        title: Text(
                          brewingMethod.brewingMethod,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onTap: () {
                          context.router.push(
                            RecipeListRoute(
                              brewingMethodId: brewingMethod.brewingMethodId,
                            ),
                          );
                        },
                      ),
                    );
                  }, childCount: filteredBrewingMethods.length),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Expanded quick actions: one full-width [ListTile] per action, each pinned
  /// to [_actionRowHeight] so the column height exactly matches the header's
  /// max extent.
  Widget _buildFullActions(BuildContext context, RecipeModel? mostRecentRecipe) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _actionRowHeight,
          child: Semantics(
            identifier: 'favoriteRecipes',
            label: l10n.favoriterecipes,
            child: ListTile(
              leading: const Icon(Icons.favorite),
              title: Text(l10n.favoriterecipes),
              onTap: () => context.router.push(const FavoriteRecipesRoute()),
            ),
          ),
        ),
        SizedBox(
          height: _actionRowHeight,
          child: Semantics(
            identifier: 'createRecipe',
            label: l10n.createRecipe,
            child: ListTile(
              leading: const Icon(Icons.add),
              title: Text(l10n.createRecipe),
              onTap: () => context.router.push(RecipeCreationRoute()),
            ),
          ),
        ),
        if (mostRecentRecipe != null)
          SizedBox(
            height: _actionRowHeight,
            child: Semantics(
              identifier: 'lastRecipe_${mostRecentRecipe.id}',
              label: '${l10n.lastrecipe}${mostRecentRecipe.name}',
              child: ListTile(
                leading: getIconByBrewingMethod(
                  mostRecentRecipe.brewingMethodId,
                ),
                title: Text('${l10n.lastrecipe} ${mostRecentRecipe.name}'),
                onTap: () => context.router.push(
                  RecipeDetailRoute(
                    brewingMethodId: mostRecentRecipe.brewingMethodId,
                    recipeId: mostRecentRecipe.id,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Compact quick actions: a single icon-only row shown once the header has
  /// collapsed.
  Widget _buildCompactActions(
    BuildContext context,
    RecipeModel? mostRecentRecipe,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: _actionRowHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Semantics(
            identifier: 'favoriteRecipesCompact',
            label: l10n.favoriterecipes,
            button: true,
            child: IconButton(
              icon: const Icon(Icons.favorite),
              iconSize: AppIconSize.medium,
              tooltip: l10n.favoriterecipes,
              onPressed: () => context.router.push(const FavoriteRecipesRoute()),
            ),
          ),
          Semantics(
            identifier: 'createRecipeCompact',
            label: l10n.createRecipe,
            button: true,
            child: IconButton(
              icon: const Icon(Icons.add),
              iconSize: AppIconSize.medium,
              tooltip: l10n.createRecipe,
              onPressed: () => context.router.push(RecipeCreationRoute()),
            ),
          ),
          if (mostRecentRecipe != null)
            Semantics(
              identifier: 'lastRecipeCompact_${mostRecentRecipe.id}',
              label: '${l10n.lastrecipe}${mostRecentRecipe.name}',
              button: true,
              child: IconButton(
                icon: getIconByBrewingMethod(mostRecentRecipe.brewingMethodId),
                iconSize: AppIconSize.medium,
                tooltip: '${l10n.lastrecipe} ${mostRecentRecipe.name}',
                onPressed: () => context.router.push(
                  RecipeDetailRoute(
                    brewingMethodId: mostRecentRecipe.brewingMethodId,
                    recipeId: mostRecentRecipe.id,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pinned, scroll-linked header for the quick-action row. It cross-fades the
/// full [ListTile] actions into a compact icon row as the user scrolls,
/// collapsing from [maxExtentValue] down to [minExtentValue]. Living inside the
/// scroll view means the collapse consumes scroll delta — the list is "dragged"
/// up with the header (no jump) and only scrolls beneath it once fully compact.
class _QuickActionsHeaderDelegate extends SliverPersistentHeaderDelegate {
  _QuickActionsHeaderDelegate({
    required this.maxExtentValue,
    required this.minExtentValue,
    required this.background,
    required this.fullChild,
    required this.compactChild,
  });

  /// Height reserved at the bottom of the band for the separator. The [Divider]
  /// draws its hairline centred within this height, giving equal padding above
  /// and below the line.
  static const double dividerZoneHeight = 17.0;

  final double maxExtentValue;
  final double minExtentValue;
  final Color background;
  final Widget fullChild;
  final Widget compactChild;

  @override
  double get maxExtent => maxExtentValue;

  @override
  double get minExtent => minExtentValue;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final range = maxExtentValue - minExtentValue;
    // 0.0 = fully expanded, 1.0 = fully collapsed.
    final t = range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    final theme = Theme.of(context);

    return Container(
      // Opaque so the list scrolls invisibly beneath the pinned header.
      color: background,
      child: Column(
        children: [
          // Action area — cross-fades full ListTiles into the compact icon
          // row. Clipped so the full actions clip cleanly while the band
          // shrinks during the scroll-linked collapse.
          Expanded(
            child: ClipRect(
              child: Stack(
                children: [
                  // Full actions: fade out in the first half of the collapse.
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      ignoring: t > 0.5,
                      child: Opacity(
                        opacity: (1.0 - t / 0.5).clamp(0.0, 1.0),
                        child: fullChild,
                      ),
                    ),
                  ),
                  // Compact actions: fade in during the second half.
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      ignoring: t <= 0.5,
                      child: Opacity(
                        opacity: ((t - 0.5) / 0.5).clamp(0.0, 1.0),
                        child: compactChild,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Separator from the list below, with equal padding above and below
          // (the hairline is centred within [dividerZoneHeight]).
          Divider(
            height: dividerZoneHeight,
            thickness: 0.7,
            indent: 16.0,
            endIndent: 16.0,
            color: theme.dividerColor.withAlpha((255 * 0.3).round()),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _QuickActionsHeaderDelegate oldDelegate) {
    return maxExtentValue != oldDelegate.maxExtentValue ||
        minExtentValue != oldDelegate.minExtentValue ||
        background != oldDelegate.background ||
        fullChild != oldDelegate.fullChild ||
        compactChild != oldDelegate.compactChild;
  }
}

/// Dismissible banner shown at the top of the Brewing Methods tab on
/// October 1st (International Coffee Day). Renders nothing on every other
/// day, or when the user has dismissed it for the current calendar year.
class _CoffeeDayBanner extends StatelessWidget {
  const _CoffeeDayBanner();

  /// Session-scoped guard so the coffee-day impression is logged once, not on
  /// every rebuild of the (frequently rebuilt) banner.
  static bool _coffeeDayImpressionLogged = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<MomentsService>(
      builder: (context, moments, _) {
        if (!moments.isInternationalCoffeeDay) return const SizedBox.shrink();
        if (moments.isCoffeeDayDismissedThisYear()) {
          return const SizedBox.shrink();
        }

        // Mark discovery once per year, after the frame so we don't setState
        // during build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          moments.markDiscovered('coffee_day');
          // Impression: guard against the banner's frequent rebuilds so we
          // log once per session, not per frame.
          if (!_coffeeDayImpressionLogged) {
            _coffeeDayImpressionLogged = true;
            AnalyticsService.maybeInstance?.track(
              'moment_shown',
              properties: {'moment_id': 'coffee_day'},
            );
          }
        });

        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.base,
            AppSpacing.sm,
            AppSpacing.base,
            0,
          ),
          child: Material(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.base,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Coffeico.coffee_maker,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: AppIconSize.medium,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // FittedBox lets the title shrink-to-fit on narrow screens
                  // before any line-wrap happens; maxLines: 1 + ellipsis is
                  // the safety net if even the smallest scale would overflow.
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.mts_coffeeDayBanner,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.mts_coffeeDayBannerDismiss,
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: AppIconSize.medium,
                    ),
                    onPressed: () {
                      AnalyticsService.maybeInstance?.track(
                        'moment_interacted',
                        properties: {
                          'moment_id': 'coffee_day',
                          'action': 'dismiss',
                        },
                      );
                      moments.dismissCoffeeDayThisYear();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
