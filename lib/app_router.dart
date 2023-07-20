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
          children: [
            AutoRoute(
              page: RecipeDetailRoute.page,
              path: ':id',
            ),
          ],
        ),
        AutoRoute(
          page: AboutRoute.page,
          path: '/about',
        ),
        AutoRoute(
          page: CoffeeTipsRoute.page,
          path: '/tips',
        ),
      ];
}
