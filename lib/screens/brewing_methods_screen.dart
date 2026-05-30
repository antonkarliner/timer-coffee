import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import '../models/brewing_method_model.dart';
import '../providers/recipe_provider.dart';
import '../models/recipe_model.dart';
import '../app_router.gr.dart';
import '../services/moments_service.dart';
import '../services/onboarding_service.dart';
import '../theme/design_tokens.dart';
import '../utils/icon_utils.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../widgets/coffee_journey_card.dart';
import '../widgets/collections_carousel.dart';

@RoutePage()
class BrewingMethodsScreen extends StatelessWidget {
  const BrewingMethodsScreen({super.key});

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
      child: Column(
        children: [
          const _CoffeeDayBanner(),
          const CoffeeJourneyCard(),
          if (showCollections) const CollectionsCarousel(),
          buildFixedContent(context, recipeProvider),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Divider(
              color: Theme.of(
                context,
              ).dividerColor.withAlpha((255 * 0.3).round()),
              thickness: 0.7,
              height: 0,
              indent: 16.0,
              endIndent: 16.0,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredBrewingMethods.length,
              itemBuilder: (BuildContext context, int index) {
                final brewingMethod = filteredBrewingMethods[index];
                return Semantics(
                  identifier: 'brewingMethod_${brewingMethod.brewingMethodId}',
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
              },
              // Add padding to the bottom of the ListView
              padding: EdgeInsets.only(bottom: bottomPadding),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFixedContent(
    BuildContext context,
    RecipeProvider recipeProvider,
  ) {
    final l10n = AppLocalizations.of(context)!; // Get localizations
    return FutureBuilder<RecipeModel?>(
      future: recipeProvider.getLastUsedRecipe(),
      builder: (context, snapshot) {
        RecipeModel? mostRecentRecipe = snapshot.data;
        return Column(
          children: [
            Semantics(
              identifier: 'favoriteRecipes',
              label: l10n.favoriterecipes,
              child: ListTile(
                leading: const Icon(Icons.favorite),
                title: Text(l10n.favoriterecipes),
                onTap: () {
                  context.router.push(const FavoriteRecipesRoute());
                },
              ),
            ),
            Semantics(
              identifier: 'createRecipe',
              label: l10n.createRecipe,
              child: ListTile(
                leading: const Icon(Icons.add),
                title: Text(l10n.createRecipe),
                onTap: () {
                  context.router.push(RecipeCreationRoute());
                },
              ),
            ),
            if (mostRecentRecipe != null)
              Semantics(
                identifier: 'lastRecipe_${mostRecentRecipe.id}',
                label: '${l10n.lastrecipe}${mostRecentRecipe.name}',
                child: ListTile(
                  leading: getIconByBrewingMethod(
                    mostRecentRecipe.brewingMethodId,
                  ),
                  title: Text('${l10n.lastrecipe} ${mostRecentRecipe.name}'),
                  onTap: () {
                    context.router.push(
                      RecipeDetailRoute(
                        brewingMethodId: mostRecentRecipe.brewingMethodId,
                        recipeId: mostRecentRecipe.id,
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Dismissible banner shown at the top of the Brewing Methods tab on
/// October 1st (International Coffee Day). Renders nothing on every other
/// day, or when the user has dismissed it for the current calendar year.
class _CoffeeDayBanner extends StatelessWidget {
  const _CoffeeDayBanner();

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
                    onPressed: () => moments.dismissCoffeeDayThisYear(),
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
