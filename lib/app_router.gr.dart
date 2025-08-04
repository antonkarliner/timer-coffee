// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i18;
import 'package:coffee_timer/models/recipe_model.dart' as _i21;
import 'package:coffee_timer/screens/account_screen.dart' as _i1;
import 'package:coffee_timer/screens/brew_diary_screen.dart' as _i2;
import 'package:coffee_timer/screens/brewing_methods_screen.dart' as _i3;
import 'package:coffee_timer/screens/coffee_beans_detail_screen.dart' as _i4;
import 'package:coffee_timer/screens/coffee_beans_screen.dart' as _i5;
import 'package:coffee_timer/screens/donation_screen.dart' as _i6;
import 'package:coffee_timer/screens/favorite_recipes_screen.dart' as _i7;
import 'package:coffee_timer/screens/home_screen.dart' as _i8;
import 'package:coffee_timer/screens/hub_home_screen.dart' as _i9;
import 'package:coffee_timer/screens/info_screen.dart' as _i10;
import 'package:coffee_timer/screens/new_beans_screen.dart' as _i11;
import 'package:coffee_timer/screens/recipe_creation_screen.dart' as _i12;
import 'package:coffee_timer/screens/recipe_detail_screen.dart' as _i13;
import 'package:coffee_timer/screens/recipe_list_screen.dart' as _i14;
import 'package:coffee_timer/screens/settings_screen.dart' as _i15;
import 'package:coffee_timer/screens/stats_screen.dart' as _i16;
import 'package:coffee_timer/screens/yearly_stats_story_screen.dart' as _i17;
import 'package:flutter/foundation.dart' as _i19;
import 'package:flutter/material.dart' as _i20;

abstract class $AppRouter extends _i18.RootStackRouter {
  $AppRouter({super.navigatorKey});

  @override
  final Map<String, _i18.PageFactory> pagesMap = {
    AccountRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<AccountRouteArgs>(
          orElse: () =>
              AccountRouteArgs(userId: pathParams.getString('userId')));
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i1.AccountScreen(
          key: args.key,
          userId: args.userId,
        ),
      );
    },
    BrewDiaryRoute.name: (routeData) {
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i2.BrewDiaryScreen(),
      );
    },
    BrewingMethodsRoute.name: (routeData) {
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i3.BrewingMethodsScreen(),
      );
    },
    CoffeeBeansDetailRoute.name: (routeData) {
      final args = routeData.argsAs<CoffeeBeansDetailRouteArgs>();
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i4.CoffeeBeansDetailScreen(
          key: args.key,
          uuid: args.uuid,
        ),
      );
    },
    CoffeeBeansRoute.name: (routeData) {
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i5.CoffeeBeansScreen(),
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
        child: const _i8.HomeScreen(),
      );
    },
    HubHomeRoute.name: (routeData) {
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i9.HubHomeScreen(),
      );
    },
    InfoRoute.name: (routeData) {
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i10.InfoScreen(),
      );
    },
    NewBeansRoute.name: (routeData) {
      final args = routeData.argsAs<NewBeansRouteArgs>(
          orElse: () => const NewBeansRouteArgs());
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i11.NewBeansScreen(
          key: args.key,
          uuid: args.uuid,
        ),
      );
    },
    RecipeCreationRoute.name: (routeData) {
      final args = routeData.argsAs<RecipeCreationRouteArgs>(
          orElse: () => const RecipeCreationRouteArgs());
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i12.RecipeCreationScreen(
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
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i13.RecipeDetailScreen(
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
        child: _i14.RecipeListScreen(
          key: args.key,
          brewingMethodId: args.brewingMethodId,
        ),
      );
    },
    SettingsRoute.name: (routeData) {
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i15.SettingsScreen(),
      );
    },
    StatsRoute.name: (routeData) {
      final args = routeData.argsAs<StatsRouteArgs>(
          orElse: () => const StatsRouteArgs());
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i16.StatsScreen(key: args.key),
      );
    },
    YearlyStatsStoryRoute.name: (routeData) {
      return _i18.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i17.YearlyStatsStoryScreen(),
      );
    },
  };
}

/// generated route for
/// [_i1.AccountScreen]
class AccountRoute extends _i18.PageRouteInfo<AccountRouteArgs> {
  AccountRoute({
    _i19.Key? key,
    required String userId,
    List<_i18.PageRouteInfo>? children,
  }) : super(
          AccountRoute.name,
          args: AccountRouteArgs(
            key: key,
            userId: userId,
          ),
          rawPathParams: {'userId': userId},
          initialChildren: children,
        );

  static const String name = 'AccountRoute';

  static const _i18.PageInfo<AccountRouteArgs> page =
      _i18.PageInfo<AccountRouteArgs>(name);
}

class AccountRouteArgs {
  const AccountRouteArgs({
    this.key,
    required this.userId,
  });

  final _i19.Key? key;

  final String userId;

  @override
  String toString() {
    return 'AccountRouteArgs{key: $key, userId: $userId}';
  }
}

/// generated route for
/// [_i2.BrewDiaryScreen]
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
/// [_i3.BrewingMethodsScreen]
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
/// [_i4.CoffeeBeansDetailScreen]
class CoffeeBeansDetailRoute
    extends _i18.PageRouteInfo<CoffeeBeansDetailRouteArgs> {
  CoffeeBeansDetailRoute({
    _i20.Key? key,
    required String uuid,
    List<_i18.PageRouteInfo>? children,
  }) : super(
          CoffeeBeansDetailRoute.name,
          args: CoffeeBeansDetailRouteArgs(
            key: key,
            uuid: uuid,
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
    required this.uuid,
  });

  final _i20.Key? key;

  final String uuid;

  @override
  String toString() {
    return 'CoffeeBeansDetailRouteArgs{key: $key, uuid: $uuid}';
  }
}

/// generated route for
/// [_i5.CoffeeBeansScreen]
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
/// [_i8.HomeScreen]
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
/// [_i9.HubHomeScreen]
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
/// [_i10.InfoScreen]
class InfoRoute extends _i18.PageRouteInfo<void> {
  const InfoRoute({List<_i18.PageRouteInfo>? children})
      : super(
          InfoRoute.name,
          initialChildren: children,
        );

  static const String name = 'InfoRoute';

  static const _i18.PageInfo<void> page = _i18.PageInfo<void>(name);
}

/// generated route for
/// [_i11.NewBeansScreen]
class NewBeansRoute extends _i18.PageRouteInfo<NewBeansRouteArgs> {
  NewBeansRoute({
    _i20.Key? key,
    String? uuid,
    List<_i18.PageRouteInfo>? children,
  }) : super(
          NewBeansRoute.name,
          args: NewBeansRouteArgs(
            key: key,
            uuid: uuid,
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
    this.uuid,
  });

  final _i20.Key? key;

  final String? uuid;

  @override
  String toString() {
    return 'NewBeansRouteArgs{key: $key, uuid: $uuid}';
  }
}

/// generated route for
/// [_i12.RecipeCreationScreen]
class RecipeCreationRoute extends _i18.PageRouteInfo<RecipeCreationRouteArgs> {
  RecipeCreationRoute({
    _i20.Key? key,
    _i21.RecipeModel? recipe,
    String? brewingMethodId,
    List<_i18.PageRouteInfo>? children,
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

  static const _i18.PageInfo<RecipeCreationRouteArgs> page =
      _i18.PageInfo<RecipeCreationRouteArgs>(name);
}

class RecipeCreationRouteArgs {
  const RecipeCreationRouteArgs({
    this.key,
    this.recipe,
    this.brewingMethodId,
  });

  final _i20.Key? key;

  final _i21.RecipeModel? recipe;

  final String? brewingMethodId;

  @override
  String toString() {
    return 'RecipeCreationRouteArgs{key: $key, recipe: $recipe, brewingMethodId: $brewingMethodId}';
  }
}

/// generated route for
/// [_i13.RecipeDetailScreen]
class RecipeDetailRoute extends _i18.PageRouteInfo<RecipeDetailRouteArgs> {
  RecipeDetailRoute({
    _i20.Key? key,
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

  final _i20.Key? key;

  final String brewingMethodId;

  final String recipeId;

  @override
  String toString() {
    return 'RecipeDetailRouteArgs{key: $key, brewingMethodId: $brewingMethodId, recipeId: $recipeId}';
  }
}

/// generated route for
/// [_i14.RecipeListScreen]
class RecipeListRoute extends _i18.PageRouteInfo<RecipeListRouteArgs> {
  RecipeListRoute({
    _i20.Key? key,
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

  final _i20.Key? key;

  final String? brewingMethodId;

  @override
  String toString() {
    return 'RecipeListRouteArgs{key: $key, brewingMethodId: $brewingMethodId}';
  }
}

/// generated route for
/// [_i15.SettingsScreen]
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
/// [_i16.StatsScreen]
class StatsRoute extends _i18.PageRouteInfo<StatsRouteArgs> {
  StatsRoute({
    _i20.Key? key,
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

  final _i20.Key? key;

  @override
  String toString() {
    return 'StatsRouteArgs{key: $key}';
  }
}

/// generated route for
/// [_i17.YearlyStatsStoryScreen]
class YearlyStatsStoryRoute extends _i18.PageRouteInfo<void> {
  const YearlyStatsStoryRoute({List<_i18.PageRouteInfo>? children})
      : super(
          YearlyStatsStoryRoute.name,
          initialChildren: children,
        );

  static const String name = 'YearlyStatsStoryRoute';

  static const _i18.PageInfo<void> page = _i18.PageInfo<void>(name);
}
