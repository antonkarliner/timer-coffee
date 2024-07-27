// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i18;
import 'package:coffee_timer/screens/brew_diary_screen.dart' as _i1;
import 'package:coffee_timer/screens/coffee_beans_detail_screen.dart' as _i3;
import 'package:coffee_timer/screens/coffee_beans_screen.dart' as _i4;
import 'package:coffee_timer/screens/coffee_tips_screen.dart' as _i5;
import 'package:coffee_timer/screens/donation_screen.dart' as _i6;
import 'package:coffee_timer/screens/favorite_recipes_screen.dart' as _i7;
import 'package:coffee_timer/screens/home_screen.dart' as _i2;
import 'package:coffee_timer/screens/new_beans_screen.dart' as _i8;
import 'package:coffee_timer/screens/onboarding_screen.dart' as _i9;
import 'package:coffee_timer/screens/recipe_detail_screen.dart' as _i10;
import 'package:coffee_timer/screens/recipe_detail_tk_screen.dart' as _i11;
import 'package:coffee_timer/screens/recipe_list_screen.dart' as _i12;
import 'package:coffee_timer/screens/settings_screen.dart' as _i13;
import 'package:coffee_timer/screens/stats_screen.dart' as _i14;
import 'package:coffee_timer/screens/vendor_recipe_detail_screen.dart' as _i15;
import 'package:coffee_timer/screens/vendors_recipe_list_screen.dart' as _i16;
import 'package:coffee_timer/screens/vendors_screen.dart' as _i17;
import 'package:flutter/foundation.dart' as _i20;
import 'package:flutter/material.dart' as _i19;

abstract class $AppRouter extends _i18.RootStackRouter {
  $AppRouter({super.navigatorKey});

  @override
  final Map<String, _i18.PageFactory> pagesMap = {
    BrewDiaryRoute.name: (routeData) {
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i1.BrewDiaryScreen(),
      );
    },
    BrewTabRoute.name: (routeData) {
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i2.BrewTabScreen(),
      );
    },
    BrewingMethodsRoute.name: (routeData) {
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i2.BrewingMethodsScreen(),
      );
    },
    CoffeeBeansDetailRoute.name: (routeData) {
      final args = routeData.argsAs<CoffeeBeansDetailRouteArgs>();
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i3.CoffeeBeansDetailScreen(
          key: args.key,
          id: args.id,
        ),
      );
    },
    CoffeeBeansRoute.name: (routeData) {
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i4.CoffeeBeansScreen(),
      );
    },
    CoffeeTipsRoute.name: (routeData) {
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i5.CoffeeTipsScreen(),
      );
    },
    DonationRoute.name: (routeData) {
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i6.DonationScreen(),
      );
    },
    FavoriteRecipesRoute.name: (routeData) {
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i7.FavoriteRecipesScreen(),
      );
    },
    HomeRoute.name: (routeData) {
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i2.HomeScreen(),
      );
    },
    HubHomeRoute.name: (routeData) {
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i2.HubHomeScreen(),
      );
    },
    HubTabRoute.name: (routeData) {
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i2.HubTabScreen(),
      );
    },
    NewBeansRoute.name: (routeData) {
      final args = routeData.argsAs<NewBeansRouteArgs>(
          orElse: () => const NewBeansRouteArgs());
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i8.NewBeansScreen(
          key: args.key,
          id: args.id,
        ),
      );
    },
    OnboardingRoute.name: (routeData) {
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i9.OnboardingScreen(),
      );
    },
    RecipeDetailRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<RecipeDetailRouteArgs>(
          orElse: () => RecipeDetailRouteArgs(
                brewingMethodId: pathParams.getString('brewingMethodId'),
                recipeId: pathParams.getString('recipeId'),
              ));
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i10.RecipeDetailScreen(
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
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i11.RecipeDetailTKScreen(
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
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i12.RecipeListScreen(
          key: args.key,
          brewingMethodId: args.brewingMethodId,
        ),
      );
    },
    SettingsRoute.name: (routeData) {
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i13.SettingsScreen(),
      );
    },
    StatsRoute.name: (routeData) {
      final args = routeData.argsAs<StatsRouteArgs>(
          orElse: () => const StatsRouteArgs());
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i14.StatsScreen(key: args.key),
      );
    },
    VendorRecipeDetailRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<VendorRecipeDetailRouteArgs>(
          orElse: () => VendorRecipeDetailRouteArgs(
                vendorId: pathParams.getString('vendorId'),
                recipeId: pathParams.getString('recipeId'),
              ));
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i15.VendorRecipeDetailScreen(
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
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i16.VendorsRecipeListScreen(
          key: args.key,
          vendorId: args.vendorId,
        ),
      );
    },
    VendorsRoute.name: (routeData) {
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i17.VendorsScreen(),
      );
    },
  };
}

/// generated route for
/// [_i1.BrewDiaryScreen]
class BrewDiaryRoute extends _i18.PageRouteInfo<void> {
  const BrewDiaryRoute({List<_i18.PageRouteInfo>? children})
      : super(
          BrewDiaryRoute.name,
          initialChildren: children,
        );

  static const String name = 'BrewDiaryRoute';

  static const _i18.PageInfo<void> page = _i18.PageInfo<void>(name);
}

/// generated route for
/// [_i2.BrewTabScreen]
class BrewTabRoute extends _i18.PageRouteInfo<void> {
  const BrewTabRoute({List<_i18.PageRouteInfo>? children})
      : super(
          BrewTabRoute.name,
          initialChildren: children,
        );

  static const String name = 'BrewTabRoute';

  static const _i18.PageInfo<void> page = _i18.PageInfo<void>(name);
}

/// generated route for
/// [_i2.BrewingMethodsScreen]
class BrewingMethodsRoute extends _i18.PageRouteInfo<void> {
  const BrewingMethodsRoute({List<_i18.PageRouteInfo>? children})
      : super(
          BrewingMethodsRoute.name,
          initialChildren: children,
        );

  static const String name = 'BrewingMethodsRoute';

  static const _i18.PageInfo<void> page = _i18.PageInfo<void>(name);
}

/// generated route for
/// [_i3.CoffeeBeansDetailScreen]
class CoffeeBeansDetailRoute
    extends _i18.PageRouteInfo<CoffeeBeansDetailRouteArgs> {
  CoffeeBeansDetailRoute({
    _i19.Key? key,
    required int id,
    List<_i18.PageRouteInfo>? children,
  }) : super(
          CoffeeBeansDetailRoute.name,
          args: CoffeeBeansDetailRouteArgs(
            key: key,
            id: id,
          ),
          initialChildren: children,
        );

  static const String name = 'CoffeeBeansDetailRoute';

  static const _i18.PageInfo<CoffeeBeansDetailRouteArgs> page =
      _i18.PageInfo<CoffeeBeansDetailRouteArgs>(name);
}

class CoffeeBeansDetailRouteArgs {
  const CoffeeBeansDetailRouteArgs({
    this.key,
    required this.id,
  });

  final _i19.Key? key;

  final int id;

  @override
  String toString() {
    return 'CoffeeBeansDetailRouteArgs{key: $key, id: $id}';
  }
}

/// generated route for
/// [_i4.CoffeeBeansScreen]
class CoffeeBeansRoute extends _i18.PageRouteInfo<void> {
  const CoffeeBeansRoute({List<_i18.PageRouteInfo>? children})
      : super(
          CoffeeBeansRoute.name,
          initialChildren: children,
        );

  static const String name = 'CoffeeBeansRoute';

  static const _i18.PageInfo<void> page = _i18.PageInfo<void>(name);
}

/// generated route for
/// [_i5.CoffeeTipsScreen]
class CoffeeTipsRoute extends _i18.PageRouteInfo<void> {
  const CoffeeTipsRoute({List<_i18.PageRouteInfo>? children})
      : super(
          CoffeeTipsRoute.name,
          initialChildren: children,
        );

  static const String name = 'CoffeeTipsRoute';

  static const _i18.PageInfo<void> page = _i18.PageInfo<void>(name);
}

/// generated route for
/// [_i6.DonationScreen]
class DonationRoute extends _i18.PageRouteInfo<void> {
  const DonationRoute({List<_i18.PageRouteInfo>? children})
      : super(
          DonationRoute.name,
          initialChildren: children,
        );

  static const String name = 'DonationRoute';

  static const _i18.PageInfo<void> page = _i18.PageInfo<void>(name);
}

/// generated route for
/// [_i7.FavoriteRecipesScreen]
class FavoriteRecipesRoute extends _i18.PageRouteInfo<void> {
  const FavoriteRecipesRoute({List<_i18.PageRouteInfo>? children})
      : super(
          FavoriteRecipesRoute.name,
          initialChildren: children,
        );

  static const String name = 'FavoriteRecipesRoute';

  static const _i18.PageInfo<void> page = _i18.PageInfo<void>(name);
}

/// generated route for
/// [_i2.HomeScreen]
class HomeRoute extends _i18.PageRouteInfo<void> {
  const HomeRoute({List<_i18.PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static const _i18.PageInfo<void> page = _i18.PageInfo<void>(name);
}

/// generated route for
/// [_i2.HubHomeScreen]
class HubHomeRoute extends _i18.PageRouteInfo<void> {
  const HubHomeRoute({List<_i18.PageRouteInfo>? children})
      : super(
          HubHomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HubHomeRoute';

  static const _i18.PageInfo<void> page = _i18.PageInfo<void>(name);
}

/// generated route for
/// [_i2.HubTabScreen]
class HubTabRoute extends _i18.PageRouteInfo<void> {
  const HubTabRoute({List<_i18.PageRouteInfo>? children})
      : super(
          HubTabRoute.name,
          initialChildren: children,
        );

  static const String name = 'HubTabRoute';

  static const _i18.PageInfo<void> page = _i18.PageInfo<void>(name);
}

/// generated route for
/// [_i8.NewBeansScreen]
class NewBeansRoute extends _i18.PageRouteInfo<NewBeansRouteArgs> {
  NewBeansRoute({
    _i19.Key? key,
    int? id,
    List<_i18.PageRouteInfo>? children,
  }) : super(
          NewBeansRoute.name,
          args: NewBeansRouteArgs(
            key: key,
            id: id,
          ),
          initialChildren: children,
        );

  static const String name = 'NewBeansRoute';

  static const _i18.PageInfo<NewBeansRouteArgs> page =
      _i18.PageInfo<NewBeansRouteArgs>(name);
}

class NewBeansRouteArgs {
  const NewBeansRouteArgs({
    this.key,
    this.id,
  });

  final _i19.Key? key;

  final int? id;

  @override
  String toString() {
    return 'NewBeansRouteArgs{key: $key, id: $id}';
  }
}

/// generated route for
/// [_i9.OnboardingScreen]
class OnboardingRoute extends _i18.PageRouteInfo<void> {
  const OnboardingRoute({List<_i18.PageRouteInfo>? children})
      : super(
          OnboardingRoute.name,
          initialChildren: children,
        );

  static const String name = 'OnboardingRoute';

  static const _i18.PageInfo<void> page = _i18.PageInfo<void>(name);
}

/// generated route for
/// [_i10.RecipeDetailScreen]
class RecipeDetailRoute extends _i18.PageRouteInfo<RecipeDetailRouteArgs> {
  RecipeDetailRoute({
    _i19.Key? key,
    required String brewingMethodId,
    required String recipeId,
    List<_i18.PageRouteInfo>? children,
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

  static const _i18.PageInfo<RecipeDetailRouteArgs> page =
      _i18.PageInfo<RecipeDetailRouteArgs>(name);
}

class RecipeDetailRouteArgs {
  const RecipeDetailRouteArgs({
    this.key,
    required this.brewingMethodId,
    required this.recipeId,
  });

  final _i19.Key? key;

  final String brewingMethodId;

  final String recipeId;

  @override
  String toString() {
    return 'RecipeDetailRouteArgs{key: $key, brewingMethodId: $brewingMethodId, recipeId: $recipeId}';
  }
}

/// generated route for
/// [_i11.RecipeDetailTKScreen]
class RecipeDetailTKRoute extends _i18.PageRouteInfo<RecipeDetailTKRouteArgs> {
  RecipeDetailTKRoute({
    _i19.Key? key,
    required String brewingMethodId,
    required String recipeId,
    List<_i18.PageRouteInfo>? children,
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

  static const _i18.PageInfo<RecipeDetailTKRouteArgs> page =
      _i18.PageInfo<RecipeDetailTKRouteArgs>(name);
}

class RecipeDetailTKRouteArgs {
  const RecipeDetailTKRouteArgs({
    this.key,
    required this.brewingMethodId,
    required this.recipeId,
  });

  final _i19.Key? key;

  final String brewingMethodId;

  final String recipeId;

  @override
  String toString() {
    return 'RecipeDetailTKRouteArgs{key: $key, brewingMethodId: $brewingMethodId, recipeId: $recipeId}';
  }
}

/// generated route for
/// [_i12.RecipeListScreen]
class RecipeListRoute extends _i18.PageRouteInfo<RecipeListRouteArgs> {
  RecipeListRoute({
    _i19.Key? key,
    String? brewingMethodId,
    List<_i18.PageRouteInfo>? children,
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

  static const _i18.PageInfo<RecipeListRouteArgs> page =
      _i18.PageInfo<RecipeListRouteArgs>(name);
}

class RecipeListRouteArgs {
  const RecipeListRouteArgs({
    this.key,
    this.brewingMethodId,
  });

  final _i19.Key? key;

  final String? brewingMethodId;

  @override
  String toString() {
    return 'RecipeListRouteArgs{key: $key, brewingMethodId: $brewingMethodId}';
  }
}

/// generated route for
/// [_i13.SettingsScreen]
class SettingsRoute extends _i18.PageRouteInfo<void> {
  const SettingsRoute({List<_i18.PageRouteInfo>? children})
      : super(
          SettingsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsRoute';

  static const _i18.PageInfo<void> page = _i18.PageInfo<void>(name);
}

/// generated route for
/// [_i14.StatsScreen]
class StatsRoute extends _i18.PageRouteInfo<StatsRouteArgs> {
  StatsRoute({
    _i19.Key? key,
    List<_i18.PageRouteInfo>? children,
  }) : super(
          StatsRoute.name,
          args: StatsRouteArgs(key: key),
          initialChildren: children,
        );

  static const String name = 'StatsRoute';

  static const _i18.PageInfo<StatsRouteArgs> page =
      _i18.PageInfo<StatsRouteArgs>(name);
}

class StatsRouteArgs {
  const StatsRouteArgs({this.key});

  final _i19.Key? key;

  @override
  String toString() {
    return 'StatsRouteArgs{key: $key}';
  }
}

/// generated route for
/// [_i15.VendorRecipeDetailScreen]
class VendorRecipeDetailRoute
    extends _i18.PageRouteInfo<VendorRecipeDetailRouteArgs> {
  VendorRecipeDetailRoute({
    _i19.Key? key,
    required String vendorId,
    required String recipeId,
    List<_i18.PageRouteInfo>? children,
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

  static const _i18.PageInfo<VendorRecipeDetailRouteArgs> page =
      _i18.PageInfo<VendorRecipeDetailRouteArgs>(name);
}

class VendorRecipeDetailRouteArgs {
  const VendorRecipeDetailRouteArgs({
    this.key,
    required this.vendorId,
    required this.recipeId,
  });

  final _i19.Key? key;

  final String vendorId;

  final String recipeId;

  @override
  String toString() {
    return 'VendorRecipeDetailRouteArgs{key: $key, vendorId: $vendorId, recipeId: $recipeId}';
  }
}

/// generated route for
/// [_i16.VendorsRecipeListScreen]
class VendorsRecipeListRoute
    extends _i18.PageRouteInfo<VendorsRecipeListRouteArgs> {
  VendorsRecipeListRoute({
    _i20.Key? key,
    required String vendorId,
    List<_i18.PageRouteInfo>? children,
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

  static const _i18.PageInfo<VendorsRecipeListRouteArgs> page =
      _i18.PageInfo<VendorsRecipeListRouteArgs>(name);
}

class VendorsRecipeListRouteArgs {
  const VendorsRecipeListRouteArgs({
    this.key,
    required this.vendorId,
  });

  final _i20.Key? key;

  final String vendorId;

  @override
  String toString() {
    return 'VendorsRecipeListRouteArgs{key: $key, vendorId: $vendorId}';
  }
}

/// generated route for
/// [_i17.VendorsScreen]
class VendorsRoute extends _i18.PageRouteInfo<void> {
  const VendorsRoute({List<_i18.PageRouteInfo>? children})
      : super(
          VendorsRoute.name,
          initialChildren: children,
        );

  static const String name = 'VendorsRoute';

  static const _i18.PageInfo<void> page = _i18.PageInfo<void>(name);
}
