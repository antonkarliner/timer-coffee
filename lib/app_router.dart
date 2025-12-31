// lib/app_router.dart

import 'app_router.gr.dart';
import 'package:auto_route/auto_route.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
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
          page: StatsRoute.page,
          path: '/stats',
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
      ];
}
