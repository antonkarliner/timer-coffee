import 'package:auto_route/auto_route.dart';
import 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends $AppRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          page: HomeRoute.page,
          path: '/',
        ),
        AutoRoute(
          page: RecipeListRoute.page,
          path: '/recipes/:brewingMethodId',
        ),
        AutoRoute(
            page: RecipeDetailRoute.page,
            path: '/recipes/:brewingMethodId/:recipeId'),
        AutoRoute(
          page: AboutRoute.page,
          path: '/about',
        ),
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
          initial: true,
        ),
      ];
}
