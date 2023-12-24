import 'package:auto_route/auto_route.dart';
import 'app_router.gr.dart';

// Define your guard
class RecipeGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    // Use .get method to retrieve parameter values
    final recipeId = resolver.route.pathParams.get('recipeId');
    if (recipeId == '106') {
      // Redirect to RecipeDetailTKRoute if recipeId is 106
      resolver.redirect(RecipeDetailTKRoute(
          brewingMethodId: resolver.route.pathParams.get('brewingMethodId'),
          recipeId: recipeId));
    } else {
      // Continue with the navigation as is
      resolver.next();
    }
  }
}

// Define your AppRouter with the guard applied
@AutoRouterConfig()
class AppRouter extends $AppRouter {
  final recipeGuard = RecipeGuard(); // Initialize your guard

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
            path: '/recipes/:brewingMethodId/:recipeId',
            guards: [recipeGuard]), // Apply the guard here
        // No need for a separate route for RecipeDetailTKRoute due to the guard
        AutoRoute(
            page: RecipeDetailTKRoute.page,
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
        ),
        AutoRoute(
          page: SettingsRoute.page,
          path: '/settings',
        ),
      ];
}
