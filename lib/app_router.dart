// lib/app_router.dart

import 'app_router.gr.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'services/analytics_service.dart';

/// Tracks screen views via [AnalyticsService] on every push navigation.
class AnalyticsRouteObserver extends AutoRouterObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    final name = route.settings.name;
    if (name != null) {
      AnalyticsService.instance.track(
        'screen_viewed',
        properties: {'screen_name': name},
      );
    }
  }
}

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          page: OnboardingRoute.page,
          path: '/onboarding',
        ),
        AutoRoute(
          page: HomeRoute.page,
          path: '/',
          children: [
            AutoRoute(path: '', page: BrewingMethodsRoute.page),
            AutoRoute(path: 'beans', page: CoffeeBeansRoute.page),
            AutoRoute(path: 'hub', page: HubHomeRoute.page),
          ],
        ),
        AutoRoute(
          page: RecipeListRoute.page,
          path: '/recipes/:brewingMethodId',
        ),
        AutoRoute(
          page: RecipeDetailRoute.page,
          path: '/recipes/:brewingMethodId/:recipeId',
        ),
        AutoRoute(
          page: CollectionDetailRoute.page,
          path: '/collections/:collectionId',
        ),
        AutoRoute(
          page: DonationRoute.page,
          path: '/donate',
        ),
        AutoRoute(
          page: SettingsRoute.page,
          path: '/settings',
        ),
        AutoRoute(
          page: FavoriteRecipesRoute.page,
          path: '/favorites',
        ),
        AutoRoute(
          page: BrewDiaryRoute.page,
          path: '/brewdiary',
        ),
        AutoRoute(
          page: ManualBrewEntryRoute.page,
          path: '/brewdiary/add',
        ),
        AutoRoute(
          page: StatsRoute.page,
          path: '/stats',
        ),
        AutoRoute(
          page: ExtractionCalculatorRoute.page,
          path: '/calculator',
        ),
        AutoRoute(
          page: CoffeeBeansDetailRoute.page,
          path: '/beans/:beanId',
        ),
        AutoRoute(
          page: NewBeansRoute.page,
          path: '/new_beans',
        ),
        AutoRoute(
          page: YearlyStatsStoryRoute.page,
          path: '/yearly_stats_story',
        ),
        AutoRoute(
          page: YearlyStatsStory25Route.page,
          path: '/yearly_stats_story_25',
        ),
        AutoRoute(
          page: RecipeCreationRoute.page,
          path: '/create_recipe',
        ),
        AutoRoute(
          page: AccountRoute.page, // Add route for AccountScreen
          path: '/user/:userId',
        ),
        // New Info route
        AutoRoute(
          page: InfoRoute.page,
          path: '/info',
        ),
        // Help / FAQ / Manuals
        AutoRoute(
          page: HelpHomeRoute.page,
          path: '/help',
        ),
        AutoRoute(
          page: HelpCategoryRoute.page,
          path: '/help/category/:categorySlug',
        ),
        AutoRoute(
          page: HelpArticleRoute.page,
          path: '/help/article/:slug',
        ),
        AutoRoute(
          page: GiftBoxListRoute.page,
          path: '/giftbox',
        ),
        AutoRoute(
          page: GiftBoxOfferDetailRoute.page,
          path: '/giftbox/:slug',
        ),
        // User Recipe Management route
        AutoRoute(
          page: UserRecipeManagementRoute.page,
          path: '/user-recipes',
        ),
        AutoRoute(
          page: NotificationDebugRoute.page,
          path: '/debug/notifications',
        ),
        AutoRoute(
          page: MomentsDebugRoute.page,
          path: '/debug/moments',
        ),
        AutoRoute(
          page: PulseRoute.page,
          path: '/pulse',
        ),
        AutoRoute(
          page: RoastersRoute.page,
          path: '/roasters',
        ),
        AutoRoute(
          page: RoasterProfileRoute.page,
          path: '/roaster/:slug',
        ),
      ];
}
