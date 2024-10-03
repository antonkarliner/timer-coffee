// lib/app_router.dart

import 'app_router.gr.dart';
import 'package:auto_route/auto_route.dart';

@AutoRouterConfig()
class AppRouter extends $AppRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          page: HomeRoute.page,
          path: '/',
          children: [
            AutoRoute(
              path: '',
              page: BrewTabRoute.page,
              children: [
                AutoRoute(path: '', page: BrewingMethodsRoute.page),
              ],
            ),
            AutoRoute(
              path: 'hub',
              page: HubTabRoute.page,
              children: [
                AutoRoute(path: '', page: HubHomeRoute.page),
              ],
            ),
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
        // Removed RecipeDetailTKRoute and VendorRecipeDetailRoute
        AutoRoute(
          page: CoffeeTipsRoute.page,
          path: '/tips',
        ),
        AutoRoute(
          page: DonationRoute.page,
          path: '/donate',
        ),
        AutoRoute(
          page: OnboardingRoute.page,
          path: '/firstlaunch',
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
          page: VendorsRoute.page,
          path: '/explore',
        ),
        AutoRoute(
          page: VendorsRecipeListRoute.page,
          path: '/explore/:vendorId',
        ),
        AutoRoute(
          page: VendorRecipeDetailRoute.page,
          path: '/explore/:vendorId/:recipeId',
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
          page: CoffeeBeansRoute.page,
          path: '/beans',
        ),
        AutoRoute(
          page: CoffeeBeansDetailRoute.page,
          path: '/beans/:beanId',
        ),
        AutoRoute(
          page: NewBeansRoute.page,
          path: '/new_beans',
        ),
      ];
}
