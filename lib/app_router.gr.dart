// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i15;
import 'package:coffee_timer/models/recipe_model.dart' as _i17;
import 'package:coffee_timer/screens/account_screen.dart' as _i1;
import 'package:coffee_timer/screens/brew_diary_screen.dart' as _i2;
import 'package:coffee_timer/screens/coffee_beans_detail_screen.dart' as _i4;
import 'package:coffee_timer/screens/coffee_beans_screen.dart' as _i5;
import 'package:coffee_timer/screens/donation_screen.dart' as _i6;
import 'package:coffee_timer/screens/favorite_recipes_screen.dart' as _i7;
import 'package:coffee_timer/screens/home_screen.dart' as _i3;
import 'package:coffee_timer/screens/new_beans_screen.dart' as _i8;
import 'package:coffee_timer/screens/recipe_creation_screen.dart' as _i9;
import 'package:coffee_timer/screens/recipe_detail_screen.dart' as _i10;
import 'package:coffee_timer/screens/recipe_list_screen.dart' as _i11;
import 'package:coffee_timer/screens/settings_screen.dart' as _i12;
import 'package:coffee_timer/screens/stats_screen.dart' as _i13;
import 'package:coffee_timer/screens/yearly_stats_story_screen.dart' as _i14;
import 'package:flutter/material.dart' as _i16;

abstract class $AppRouter extends _i15.RootStackRouter {
  $AppRouter({super.navigatorKey});

  @override
  final Map<String, _i15.PageFactory> pagesMap = {
    AccountRoute.name: (routeData) {
      return _i15.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i1.AccountScreen(),
      );
    },
    BrewDiaryRoute.name: (routeData) {
      return _i15.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i2.BrewDiaryScreen(),
      );
    },
    BrewTabRoute.name: (routeData) {
      return _i15.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i3.BrewTabScreen(),
      );
    },
    BrewingMethodsRoute.name: (routeData) {
      return _i15.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i3.BrewingMethodsScreen(),
      );
    },
    CoffeeBeansDetailRoute.name: (routeData) {
      final args = routeData.argsAs<CoffeeBeansDetailRouteArgs>();
      return _i15.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i4.CoffeeBeansDetailScreen(
          key: args.key,
          uuid: args.uuid,
        ),
      );
    },
    CoffeeBeansRoute.name: (routeData) {
      return _i15.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i5.CoffeeBeansScreen(),
      );
    },
    DonationRoute.name: (routeData) {
      return _i15.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i6.DonationScreen(),
      );
    },
    FavoriteRecipesRoute.name: (routeData) {
      return _i15.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i7.FavoriteRecipesScreen(),
      );
    },
    HomeRoute.name: (routeData) {
      return _i15.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i3.HomeScreen(),
      );
    },
    HubHomeRoute.name: (routeData) {
      return _i15.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i3.HubHomeScreen(),
      );
    },
    HubTabRoute.name: (routeData) {
      return _i15.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i3.HubTabScreen(),
      );
    },
    NewBeansRoute.name: (routeData) {
      final args = routeData.argsAs<NewBeansRouteArgs>(
          orElse: () => const NewBeansRouteArgs());
      return _i15.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i8.NewBeansScreen(
          key: args.key,
          uuid: args.uuid,
        ),
      );
    },
    RecipeCreationRoute.name: (routeData) {
      final args = routeData.argsAs<RecipeCreationRouteArgs>(
          orElse: () => const RecipeCreationRouteArgs());
      return _i15.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i9.RecipeCreationScreen(
          key: args.key,
          recipe: args.recipe,
          brewingMethodId: args.brewingMethodId,
        ),
      );
    },
    RecipeDetailRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<RecipeDetailRouteArgs>(
          orElse: () => RecipeDetailRouteArgs(
                brewingMethodId: pathParams.getString('brewingMethodId'),
                recipeId: pathParams.getString('recipeId'),
              ));
      return _i15.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i10.RecipeDetailScreen(
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
      return _i15.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i11.RecipeListScreen(
          key: args.key,
          brewingMethodId: args.brewingMethodId,
        ),
      );
    },
    SettingsRoute.name: (routeData) {
      return _i15.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i12.SettingsScreen(),
      );
    },
    StatsRoute.name: (routeData) {
      final args = routeData.argsAs<StatsRouteArgs>(
          orElse: () => const StatsRouteArgs());
      return _i15.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i13.StatsScreen(key: args.key),
      );
    },
    YearlyStatsStoryRoute.name: (routeData) {
      return _i15.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i14.YearlyStatsStoryScreen(),
      );
    },
  };
}

/// generated route for
/// [_i1.AccountScreen]
class AccountRoute extends _i15.PageRouteInfo<void> {
  const AccountRoute({List<_i15.PageRouteInfo>? children})
      : super(
          AccountRoute.name,
          initialChildren: children,
        );

  static const String name = 'AccountRoute';

  static const _i15.PageInfo<void> page = _i15.PageInfo<void>(name);
}

/// generated route for
/// [_i2.BrewDiaryScreen]
class BrewDiaryRoute extends _i15.PageRouteInfo<void> {
  const BrewDiaryRoute({List<_i15.PageRouteInfo>? children})
      : super(
          BrewDiaryRoute.name,
          initialChildren: children,
        );

  static const String name = 'BrewDiaryRoute';

  static const _i15.PageInfo<void> page = _i15.PageInfo<void>(name);
}

/// generated route for
/// [_i3.BrewTabScreen]
class BrewTabRoute extends _i15.PageRouteInfo<void> {
  const BrewTabRoute({List<_i15.PageRouteInfo>? children})
      : super(
          BrewTabRoute.name,
          initialChildren: children,
        );

  static const String name = 'BrewTabRoute';

  static const _i15.PageInfo<void> page = _i15.PageInfo<void>(name);
}

/// generated route for
/// [_i3.BrewingMethodsScreen]
class BrewingMethodsRoute extends _i15.PageRouteInfo<void> {
  const BrewingMethodsRoute({List<_i15.PageRouteInfo>? children})
      : super(
          BrewingMethodsRoute.name,
          initialChildren: children,
        );

  static const String name = 'BrewingMethodsRoute';

  static const _i15.PageInfo<void> page = _i15.PageInfo<void>(name);
}

/// generated route for
/// [_i4.CoffeeBeansDetailScreen]
class CoffeeBeansDetailRoute
    extends _i15.PageRouteInfo<CoffeeBeansDetailRouteArgs> {
  CoffeeBeansDetailRoute({
    _i16.Key? key,
    required String uuid,
    List<_i15.PageRouteInfo>? children,
  }) : super(
          CoffeeBeansDetailRoute.name,
          args: CoffeeBeansDetailRouteArgs(
            key: key,
            uuid: uuid,
          ),
          initialChildren: children,
        );

  static const String name = 'CoffeeBeansDetailRoute';

  static const _i15.PageInfo<CoffeeBeansDetailRouteArgs> page =
      _i15.PageInfo<CoffeeBeansDetailRouteArgs>(name);
}

class CoffeeBeansDetailRouteArgs {
  const CoffeeBeansDetailRouteArgs({
    this.key,
    required this.uuid,
  });

  final _i16.Key? key;

  final String uuid;

  @override
  String toString() {
    return 'CoffeeBeansDetailRouteArgs{key: $key, uuid: $uuid}';
  }
}

/// generated route for
/// [_i5.CoffeeBeansScreen]
class CoffeeBeansRoute extends _i15.PageRouteInfo<void> {
  const CoffeeBeansRoute({List<_i15.PageRouteInfo>? children})
      : super(
          CoffeeBeansRoute.name,
          initialChildren: children,
        );

  static const String name = 'CoffeeBeansRoute';

  static const _i15.PageInfo<void> page = _i15.PageInfo<void>(name);
}

/// generated route for
/// [_i6.DonationScreen]
class DonationRoute extends _i15.PageRouteInfo<void> {
  const DonationRoute({List<_i15.PageRouteInfo>? children})
      : super(
          DonationRoute.name,
          initialChildren: children,
        );

  static const String name = 'DonationRoute';

  static const _i15.PageInfo<void> page = _i15.PageInfo<void>(name);
}

/// generated route for
/// [_i7.FavoriteRecipesScreen]
class FavoriteRecipesRoute extends _i15.PageRouteInfo<void> {
  const FavoriteRecipesRoute({List<_i15.PageRouteInfo>? children})
      : super(
          FavoriteRecipesRoute.name,
          initialChildren: children,
        );

  static const String name = 'FavoriteRecipesRoute';

  static const _i15.PageInfo<void> page = _i15.PageInfo<void>(name);
}

/// generated route for
/// [_i3.HomeScreen]
class HomeRoute extends _i15.PageRouteInfo<void> {
  const HomeRoute({List<_i15.PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static const _i15.PageInfo<void> page = _i15.PageInfo<void>(name);
}

/// generated route for
/// [_i3.HubHomeScreen]
class HubHomeRoute extends _i15.PageRouteInfo<void> {
  const HubHomeRoute({List<_i15.PageRouteInfo>? children})
      : super(
          HubHomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HubHomeRoute';

  static const _i15.PageInfo<void> page = _i15.PageInfo<void>(name);
}

/// generated route for
/// [_i3.HubTabScreen]
class HubTabRoute extends _i15.PageRouteInfo<void> {
  const HubTabRoute({List<_i15.PageRouteInfo>? children})
      : super(
          HubTabRoute.name,
          initialChildren: children,
        );

  static const String name = 'HubTabRoute';

  static const _i15.PageInfo<void> page = _i15.PageInfo<void>(name);
}

/// generated route for
/// [_i8.NewBeansScreen]
class NewBeansRoute extends _i15.PageRouteInfo<NewBeansRouteArgs> {
  NewBeansRoute({
    _i16.Key? key,
    String? uuid,
    List<_i15.PageRouteInfo>? children,
  }) : super(
          NewBeansRoute.name,
          args: NewBeansRouteArgs(
            key: key,
            uuid: uuid,
          ),
          initialChildren: children,
        );

  static const String name = 'NewBeansRoute';

  static const _i15.PageInfo<NewBeansRouteArgs> page =
      _i15.PageInfo<NewBeansRouteArgs>(name);
}

class NewBeansRouteArgs {
  const NewBeansRouteArgs({
    this.key,
    this.uuid,
  });

  final _i16.Key? key;

  final String? uuid;

  @override
  String toString() {
    return 'NewBeansRouteArgs{key: $key, uuid: $uuid}';
  }
}

/// generated route for
/// [_i9.RecipeCreationScreen]
class RecipeCreationRoute extends _i15.PageRouteInfo<RecipeCreationRouteArgs> {
  RecipeCreationRoute({
    _i16.Key? key,
    _i17.RecipeModel? recipe,
    String? brewingMethodId,
    List<_i15.PageRouteInfo>? children,
  }) : super(
          RecipeCreationRoute.name,
          args: RecipeCreationRouteArgs(
            key: key,
            recipe: recipe,
            brewingMethodId: brewingMethodId,
          ),
          initialChildren: children,
        );

  static const String name = 'RecipeCreationRoute';

  static const _i15.PageInfo<RecipeCreationRouteArgs> page =
      _i15.PageInfo<RecipeCreationRouteArgs>(name);
}

class RecipeCreationRouteArgs {
  const RecipeCreationRouteArgs({
    this.key,
    this.recipe,
    this.brewingMethodId,
  });

  final _i16.Key? key;

  final _i17.RecipeModel? recipe;

  final String? brewingMethodId;

  @override
  String toString() {
    return 'RecipeCreationRouteArgs{key: $key, recipe: $recipe, brewingMethodId: $brewingMethodId}';
  }
}

/// generated route for
/// [_i10.RecipeDetailScreen]
class RecipeDetailRoute extends _i15.PageRouteInfo<RecipeDetailRouteArgs> {
  RecipeDetailRoute({
    _i16.Key? key,
    required String brewingMethodId,
    required String recipeId,
    List<_i15.PageRouteInfo>? children,
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

  static const _i15.PageInfo<RecipeDetailRouteArgs> page =
      _i15.PageInfo<RecipeDetailRouteArgs>(name);
}

class RecipeDetailRouteArgs {
  const RecipeDetailRouteArgs({
    this.key,
    required this.brewingMethodId,
    required this.recipeId,
  });

  final _i16.Key? key;

  final String brewingMethodId;

  final String recipeId;

  @override
  String toString() {
    return 'RecipeDetailRouteArgs{key: $key, brewingMethodId: $brewingMethodId, recipeId: $recipeId}';
  }
}

/// generated route for
/// [_i11.RecipeListScreen]
class RecipeListRoute extends _i15.PageRouteInfo<RecipeListRouteArgs> {
  RecipeListRoute({
    _i16.Key? key,
    String? brewingMethodId,
    List<_i15.PageRouteInfo>? children,
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

  static const _i15.PageInfo<RecipeListRouteArgs> page =
      _i15.PageInfo<RecipeListRouteArgs>(name);
}

class RecipeListRouteArgs {
  const RecipeListRouteArgs({
    this.key,
    this.brewingMethodId,
  });

  final _i16.Key? key;

  final String? brewingMethodId;

  @override
  String toString() {
    return 'RecipeListRouteArgs{key: $key, brewingMethodId: $brewingMethodId}';
  }
}

/// generated route for
/// [_i12.SettingsScreen]
class SettingsRoute extends _i15.PageRouteInfo<void> {
  const SettingsRoute({List<_i15.PageRouteInfo>? children})
      : super(
          SettingsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsRoute';

  static const _i15.PageInfo<void> page = _i15.PageInfo<void>(name);
}

/// generated route for
/// [_i13.StatsScreen]
class StatsRoute extends _i15.PageRouteInfo<StatsRouteArgs> {
  StatsRoute({
    _i16.Key? key,
    List<_i15.PageRouteInfo>? children,
  }) : super(
          StatsRoute.name,
          args: StatsRouteArgs(key: key),
          initialChildren: children,
        );

  static const String name = 'StatsRoute';

  static const _i15.PageInfo<StatsRouteArgs> page =
      _i15.PageInfo<StatsRouteArgs>(name);
}

class StatsRouteArgs {
  const StatsRouteArgs({this.key});

  final _i16.Key? key;

  @override
  String toString() {
    return 'StatsRouteArgs{key: $key}';
  }
}

/// generated route for
/// [_i14.YearlyStatsStoryScreen]
class YearlyStatsStoryRoute extends _i15.PageRouteInfo<void> {
  const YearlyStatsStoryRoute({List<_i15.PageRouteInfo>? children})
      : super(
          YearlyStatsStoryRoute.name,
          initialChildren: children,
        );

  static const String name = 'YearlyStatsStoryRoute';

  static const _i15.PageInfo<void> page = _i15.PageInfo<void>(name);
}
