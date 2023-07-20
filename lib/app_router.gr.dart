// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i6;
import 'package:coffee_timer/screens/about_screen.dart' as _i2;
import 'package:coffee_timer/screens/coffee_tips_screen.dart' as _i1;
import 'package:coffee_timer/screens/home_screen.dart' as _i5;
import 'package:coffee_timer/screens/recipe_detail_screen.dart' as _i4;
import 'package:coffee_timer/screens/recipe_list_screen.dart' as _i3;
import 'package:flutter/material.dart' as _i7;

abstract class $AppRouter extends _i6.RootStackRouter {
  $AppRouter({super.navigatorKey});

  @override
  final Map<String, _i6.PageFactory> pagesMap = {
    CoffeeTipsRoute.name: (routeData) {
      return _i6.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i1.CoffeeTipsScreen(),
      );
    },
    AboutRoute.name: (routeData) {
      return _i6.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i2.AboutScreen(),
      );
    },
    RecipeListRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<RecipeListRouteArgs>(
          orElse: () => RecipeListRouteArgs(
              brewingMethodId: pathParams.optString('brewingMethodId')));
      return _i6.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i3.RecipeListScreen(
          key: args.key,
          brewingMethodId: args.brewingMethodId,
        ),
      );
    },
    RecipeDetailRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<RecipeDetailRouteArgs>(
          orElse: () => RecipeDetailRouteArgs(
                parent: pathParams.getString('parent'),
                recipeId: pathParams.getString('id'),
              ));
      return _i6.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i4.RecipeDetailScreen(
          key: args.key,
          parent: args.parent,
          recipeId: args.recipeId,
        ),
      );
    },
    HomeRoute.name: (routeData) {
      return _i6.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i5.HomeScreen(),
      );
    },
  };
}

/// generated route for
/// [_i1.CoffeeTipsScreen]
class CoffeeTipsRoute extends _i6.PageRouteInfo<void> {
  const CoffeeTipsRoute({List<_i6.PageRouteInfo>? children})
      : super(
          CoffeeTipsRoute.name,
          initialChildren: children,
        );

  static const String name = 'CoffeeTipsRoute';

  static const _i6.PageInfo<void> page = _i6.PageInfo<void>(name);
}

/// generated route for
/// [_i2.AboutScreen]
class AboutRoute extends _i6.PageRouteInfo<void> {
  const AboutRoute({List<_i6.PageRouteInfo>? children})
      : super(
          AboutRoute.name,
          initialChildren: children,
        );

  static const String name = 'AboutRoute';

  static const _i6.PageInfo<void> page = _i6.PageInfo<void>(name);
}

/// generated route for
/// [_i3.RecipeListScreen]
class RecipeListRoute extends _i6.PageRouteInfo<RecipeListRouteArgs> {
  RecipeListRoute({
    _i7.Key? key,
    String? brewingMethodId,
    List<_i6.PageRouteInfo>? children,
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

  static const _i6.PageInfo<RecipeListRouteArgs> page =
      _i6.PageInfo<RecipeListRouteArgs>(name);
}

class RecipeListRouteArgs {
  const RecipeListRouteArgs({
    this.key,
    this.brewingMethodId,
  });

  final _i7.Key? key;

  final String? brewingMethodId;

  @override
  String toString() {
    return 'RecipeListRouteArgs{key: $key, brewingMethodId: $brewingMethodId}';
  }
}

/// generated route for
/// [_i4.RecipeDetailScreen]
class RecipeDetailRoute extends _i6.PageRouteInfo<RecipeDetailRouteArgs> {
  RecipeDetailRoute({
    _i7.Key? key,
    required String parent,
    required String recipeId,
    List<_i6.PageRouteInfo>? children,
  }) : super(
          RecipeDetailRoute.name,
          args: RecipeDetailRouteArgs(
            key: key,
            parent: parent,
            recipeId: recipeId,
          ),
          rawPathParams: {
            'parent': parent,
            'id': recipeId,
          },
          initialChildren: children,
        );

  static const String name = 'RecipeDetailRoute';

  static const _i6.PageInfo<RecipeDetailRouteArgs> page =
      _i6.PageInfo<RecipeDetailRouteArgs>(name);
}

class RecipeDetailRouteArgs {
  const RecipeDetailRouteArgs({
    this.key,
    required this.parent,
    required this.recipeId,
  });

  final _i7.Key? key;

  final String parent;

  final String recipeId;

  @override
  String toString() {
    return 'RecipeDetailRouteArgs{key: $key, parent: $parent, recipeId: $recipeId}';
  }
}

/// generated route for
/// [_i5.HomeScreen]
class HomeRoute extends _i6.PageRouteInfo<void> {
  const HomeRoute({List<_i6.PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static const _i6.PageInfo<void> page = _i6.PageInfo<void>(name);
}
