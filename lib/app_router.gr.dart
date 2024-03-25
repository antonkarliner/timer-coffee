// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i13;
import 'package:coffee_timer/screens/coffee_tips_screen.dart' as _i1;
import 'package:coffee_timer/screens/donation_screen.dart' as _i2;
import 'package:coffee_timer/screens/favorite_recipes_screen.dart' as _i3;
import 'package:coffee_timer/screens/home_screen.dart' as _i4;
import 'package:coffee_timer/screens/onboarding_screen.dart' as _i5;
import 'package:coffee_timer/screens/recipe_detail_screen.dart' as _i6;
import 'package:coffee_timer/screens/recipe_detail_tk_screen.dart' as _i7;
import 'package:coffee_timer/screens/recipe_list_screen.dart' as _i8;
import 'package:coffee_timer/screens/settings_screen.dart' as _i9;
import 'package:coffee_timer/screens/vendor_recipe_detail_screen.dart' as _i10;
import 'package:coffee_timer/screens/vendors_recipe_list_screen.dart' as _i11;
import 'package:coffee_timer/screens/vendors_screen.dart' as _i12;
import 'package:flutter/foundation.dart' as _i15;
import 'package:flutter/material.dart' as _i14;

abstract class $AppRouter extends _i13.RootStackRouter {
  $AppRouter({super.navigatorKey});

  @override
  final Map<String, _i13.PageFactory> pagesMap = {
    CoffeeTipsRoute.name: (routeData) {
      return _i13.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i1.CoffeeTipsScreen(),
      );
    },
    DonationRoute.name: (routeData) {
      return _i13.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i2.DonationScreen(),
      );
    },
    FavoriteRecipesRoute.name: (routeData) {
      return _i13.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i3.FavoriteRecipesScreen(),
      );
    },
    HomeRoute.name: (routeData) {
      return _i13.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i4.HomeScreen(),
      );
    },
    OnboardingRoute.name: (routeData) {
      return _i13.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i5.OnboardingScreen(),
      );
    },
    RecipeDetailRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<RecipeDetailRouteArgs>(
          orElse: () => RecipeDetailRouteArgs(
                brewingMethodId: pathParams.getString('brewingMethodId'),
                recipeId: pathParams.getString('recipeId'),
              ));
      return _i13.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i6.RecipeDetailScreen(
          key: args.key,
          brewingMethodId: args.brewingMethodId,
          recipeId: args.recipeId,
        ),
      );
    },
    RecipeDetailTKRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<RecipeDetailTKRouteArgs>(
          orElse: () => RecipeDetailTKRouteArgs(
                brewingMethodId: pathParams.getString('brewingMethodId'),
                recipeId: pathParams.getString('recipeId'),
              ));
      return _i13.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i7.RecipeDetailTKScreen(
          key: args.key,
          brewingMethodId: args.brewingMethodId,
          recipeId: args.recipeId,
        ),
      );
    },
    RecipeListRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<RecipeListRouteArgs>(
          orElse: () => RecipeListRouteArgs(
              brewingMethodId: pathParams.optString('brewingMethodId')));
      return _i13.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i8.RecipeListScreen(
          key: args.key,
          brewingMethodId: args.brewingMethodId,
        ),
      );
    },
    SettingsRoute.name: (routeData) {
      return _i13.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i9.SettingsScreen(),
      );
    },
    VendorRecipeDetailRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<VendorRecipeDetailRouteArgs>(
          orElse: () => VendorRecipeDetailRouteArgs(
                vendorId: pathParams.getString('vendorId'),
                recipeId: pathParams.getString('recipeId'),
              ));
      return _i13.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i10.VendorRecipeDetailScreen(
          key: args.key,
          vendorId: args.vendorId,
          recipeId: args.recipeId,
        ),
      );
    },
    VendorsRecipeListRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<VendorsRecipeListRouteArgs>(
          orElse: () => VendorsRecipeListRouteArgs(
              vendorId: pathParams.getString('vendorId')));
      return _i13.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i11.VendorsRecipeListScreen(
          key: args.key,
          vendorId: args.vendorId,
        ),
      );
    },
    VendorsRoute.name: (routeData) {
      return _i13.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i12.VendorsScreen(),
      );
    },
  };
}

/// generated route for
/// [_i1.CoffeeTipsScreen]
class CoffeeTipsRoute extends _i13.PageRouteInfo<void> {
  const CoffeeTipsRoute({List<_i13.PageRouteInfo>? children})
      : super(
          CoffeeTipsRoute.name,
          initialChildren: children,
        );

  static const String name = 'CoffeeTipsRoute';

  static const _i13.PageInfo<void> page = _i13.PageInfo<void>(name);
}

/// generated route for
/// [_i2.DonationScreen]
class DonationRoute extends _i13.PageRouteInfo<void> {
  const DonationRoute({List<_i13.PageRouteInfo>? children})
      : super(
          DonationRoute.name,
          initialChildren: children,
        );

  static const String name = 'DonationRoute';

  static const _i13.PageInfo<void> page = _i13.PageInfo<void>(name);
}

/// generated route for
/// [_i3.FavoriteRecipesScreen]
class FavoriteRecipesRoute extends _i13.PageRouteInfo<void> {
  const FavoriteRecipesRoute({List<_i13.PageRouteInfo>? children})
      : super(
          FavoriteRecipesRoute.name,
          initialChildren: children,
        );

  static const String name = 'FavoriteRecipesRoute';

  static const _i13.PageInfo<void> page = _i13.PageInfo<void>(name);
}

/// generated route for
/// [_i4.HomeScreen]
class HomeRoute extends _i13.PageRouteInfo<void> {
  const HomeRoute({List<_i13.PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static const _i13.PageInfo<void> page = _i13.PageInfo<void>(name);
}

/// generated route for
/// [_i5.OnboardingScreen]
class OnboardingRoute extends _i13.PageRouteInfo<void> {
  const OnboardingRoute({List<_i13.PageRouteInfo>? children})
      : super(
          OnboardingRoute.name,
          initialChildren: children,
        );

  static const String name = 'OnboardingRoute';

  static const _i13.PageInfo<void> page = _i13.PageInfo<void>(name);
}

/// generated route for
/// [_i6.RecipeDetailScreen]
class RecipeDetailRoute extends _i13.PageRouteInfo<RecipeDetailRouteArgs> {
  RecipeDetailRoute({
    _i14.Key? key,
    required String brewingMethodId,
    required String recipeId,
    List<_i13.PageRouteInfo>? children,
  }) : super(
          RecipeDetailRoute.name,
          args: RecipeDetailRouteArgs(
            key: key,
            brewingMethodId: brewingMethodId,
            recipeId: recipeId,
          ),
          rawPathParams: {
            'brewingMethodId': brewingMethodId,
            'recipeId': recipeId,
          },
          initialChildren: children,
        );

  static const String name = 'RecipeDetailRoute';

  static const _i13.PageInfo<RecipeDetailRouteArgs> page =
      _i13.PageInfo<RecipeDetailRouteArgs>(name);
}

class RecipeDetailRouteArgs {
  const RecipeDetailRouteArgs({
    this.key,
    required this.brewingMethodId,
    required this.recipeId,
  });

  final _i14.Key? key;

  final String brewingMethodId;

  final String recipeId;

  @override
  String toString() {
    return 'RecipeDetailRouteArgs{key: $key, brewingMethodId: $brewingMethodId, recipeId: $recipeId}';
  }
}

/// generated route for
/// [_i7.RecipeDetailTKScreen]
class RecipeDetailTKRoute extends _i13.PageRouteInfo<RecipeDetailTKRouteArgs> {
  RecipeDetailTKRoute({
    _i14.Key? key,
    required String brewingMethodId,
    required String recipeId,
    List<_i13.PageRouteInfo>? children,
  }) : super(
          RecipeDetailTKRoute.name,
          args: RecipeDetailTKRouteArgs(
            key: key,
            brewingMethodId: brewingMethodId,
            recipeId: recipeId,
          ),
          rawPathParams: {
            'brewingMethodId': brewingMethodId,
            'recipeId': recipeId,
          },
          initialChildren: children,
        );

  static const String name = 'RecipeDetailTKRoute';

  static const _i13.PageInfo<RecipeDetailTKRouteArgs> page =
      _i13.PageInfo<RecipeDetailTKRouteArgs>(name);
}

class RecipeDetailTKRouteArgs {
  const RecipeDetailTKRouteArgs({
    this.key,
    required this.brewingMethodId,
    required this.recipeId,
  });

  final _i14.Key? key;

  final String brewingMethodId;

  final String recipeId;

  @override
  String toString() {
    return 'RecipeDetailTKRouteArgs{key: $key, brewingMethodId: $brewingMethodId, recipeId: $recipeId}';
  }
}

/// generated route for
/// [_i8.RecipeListScreen]
class RecipeListRoute extends _i13.PageRouteInfo<RecipeListRouteArgs> {
  RecipeListRoute({
    _i14.Key? key,
    String? brewingMethodId,
    List<_i13.PageRouteInfo>? children,
  }) : super(
          RecipeListRoute.name,
          args: RecipeListRouteArgs(
            key: key,
            brewingMethodId: brewingMethodId,
          ),
          rawPathParams: {'brewingMethodId': brewingMethodId},
          initialChildren: children,
        );

  static const String name = 'RecipeListRoute';

  static const _i13.PageInfo<RecipeListRouteArgs> page =
      _i13.PageInfo<RecipeListRouteArgs>(name);
}

class RecipeListRouteArgs {
  const RecipeListRouteArgs({
    this.key,
    this.brewingMethodId,
  });

  final _i14.Key? key;

  final String? brewingMethodId;

  @override
  String toString() {
    return 'RecipeListRouteArgs{key: $key, brewingMethodId: $brewingMethodId}';
  }
}

/// generated route for
/// [_i9.SettingsScreen]
class SettingsRoute extends _i13.PageRouteInfo<void> {
  const SettingsRoute({List<_i13.PageRouteInfo>? children})
      : super(
          SettingsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsRoute';

  static const _i13.PageInfo<void> page = _i13.PageInfo<void>(name);
}

/// generated route for
/// [_i10.VendorRecipeDetailScreen]
class VendorRecipeDetailRoute
    extends _i13.PageRouteInfo<VendorRecipeDetailRouteArgs> {
  VendorRecipeDetailRoute({
    _i14.Key? key,
    required String vendorId,
    required String recipeId,
    List<_i13.PageRouteInfo>? children,
  }) : super(
          VendorRecipeDetailRoute.name,
          args: VendorRecipeDetailRouteArgs(
            key: key,
            vendorId: vendorId,
            recipeId: recipeId,
          ),
          rawPathParams: {
            'vendorId': vendorId,
            'recipeId': recipeId,
          },
          initialChildren: children,
        );

  static const String name = 'VendorRecipeDetailRoute';

  static const _i13.PageInfo<VendorRecipeDetailRouteArgs> page =
      _i13.PageInfo<VendorRecipeDetailRouteArgs>(name);
}

class VendorRecipeDetailRouteArgs {
  const VendorRecipeDetailRouteArgs({
    this.key,
    required this.vendorId,
    required this.recipeId,
  });

  final _i14.Key? key;

  final String vendorId;

  final String recipeId;

  @override
  String toString() {
    return 'VendorRecipeDetailRouteArgs{key: $key, vendorId: $vendorId, recipeId: $recipeId}';
  }
}

/// generated route for
/// [_i11.VendorsRecipeListScreen]
class VendorsRecipeListRoute
    extends _i13.PageRouteInfo<VendorsRecipeListRouteArgs> {
  VendorsRecipeListRoute({
    _i15.Key? key,
    required String vendorId,
    List<_i13.PageRouteInfo>? children,
  }) : super(
          VendorsRecipeListRoute.name,
          args: VendorsRecipeListRouteArgs(
            key: key,
            vendorId: vendorId,
          ),
          rawPathParams: {'vendorId': vendorId},
          initialChildren: children,
        );

  static const String name = 'VendorsRecipeListRoute';

  static const _i13.PageInfo<VendorsRecipeListRouteArgs> page =
      _i13.PageInfo<VendorsRecipeListRouteArgs>(name);
}

class VendorsRecipeListRouteArgs {
  const VendorsRecipeListRouteArgs({
    this.key,
    required this.vendorId,
  });

  final _i15.Key? key;

  final String vendorId;

  @override
  String toString() {
    return 'VendorsRecipeListRouteArgs{key: $key, vendorId: $vendorId}';
  }
}

/// generated route for
/// [_i12.VendorsScreen]
class VendorsRoute extends _i13.PageRouteInfo<void> {
  const VendorsRoute({List<_i13.PageRouteInfo>? children})
      : super(
          VendorsRoute.name,
          initialChildren: children,
        );

  static const String name = 'VendorsRoute';

  static const _i13.PageInfo<void> page = _i13.PageInfo<void>(name);
}
