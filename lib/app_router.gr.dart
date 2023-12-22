// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i9;
import 'package:coffee_timer/screens/about_screen.dart' as _i1;
import 'package:coffee_timer/screens/coffee_tips_screen.dart' as _i2;
import 'package:coffee_timer/screens/donation_screen.dart' as _i3;
import 'package:coffee_timer/screens/home_screen.dart' as _i4;
import 'package:coffee_timer/screens/onboarding_screen.dart' as _i5;
import 'package:coffee_timer/screens/recipe_detail_screen.dart' as _i6;
import 'package:coffee_timer/screens/recipe_list_screen.dart' as _i7;
import 'package:coffee_timer/screens/settings_screen.dart' as _i8;
import 'package:flutter/material.dart' as _i10;

abstract class $AppRouter extends _i9.RootStackRouter {
  $AppRouter({super.navigatorKey});

  @override
  final Map<String, _i9.PageFactory> pagesMap = {
    AboutRoute.name: (routeData) {
      return _i9.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i1.AboutScreen(),
      );
    },
    CoffeeTipsRoute.name: (routeData) {
      return _i9.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i2.CoffeeTipsScreen(),
      );
    },
    DonationRoute.name: (routeData) {
      return _i9.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i3.DonationScreen(),
      );
    },
    HomeRoute.name: (routeData) {
      return _i9.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i4.HomeScreen(),
      );
    },
    OnboardingRoute.name: (routeData) {
      return _i9.AutoRoutePage<dynamic>(
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
      return _i9.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i6.RecipeDetailScreen(
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
      return _i9.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i7.RecipeListScreen(
          key: args.key,
          brewingMethodId: args.brewingMethodId,
        ),
      );
    },
    SettingsRoute.name: (routeData) {
      return _i9.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i8.SettingsScreen(),
      );
    },
  };
}

/// generated route for
/// [_i1.AboutScreen]
class AboutRoute extends _i9.PageRouteInfo<void> {
  const AboutRoute({List<_i9.PageRouteInfo>? children})
      : super(
          AboutRoute.name,
          initialChildren: children,
        );

  static const String name = 'AboutRoute';

  static const _i9.PageInfo<void> page = _i9.PageInfo<void>(name);
}

/// generated route for
/// [_i2.CoffeeTipsScreen]
class CoffeeTipsRoute extends _i9.PageRouteInfo<void> {
  const CoffeeTipsRoute({List<_i9.PageRouteInfo>? children})
      : super(
          CoffeeTipsRoute.name,
          initialChildren: children,
        );

  static const String name = 'CoffeeTipsRoute';

  static const _i9.PageInfo<void> page = _i9.PageInfo<void>(name);
}

/// generated route for
/// [_i3.DonationScreen]
class DonationRoute extends _i9.PageRouteInfo<void> {
  const DonationRoute({List<_i9.PageRouteInfo>? children})
      : super(
          DonationRoute.name,
          initialChildren: children,
        );

  static const String name = 'DonationRoute';

  static const _i9.PageInfo<void> page = _i9.PageInfo<void>(name);
}

/// generated route for
/// [_i4.HomeScreen]
class HomeRoute extends _i9.PageRouteInfo<void> {
  const HomeRoute({List<_i9.PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static const _i9.PageInfo<void> page = _i9.PageInfo<void>(name);
}

/// generated route for
/// [_i5.OnboardingScreen]
class OnboardingRoute extends _i9.PageRouteInfo<void> {
  const OnboardingRoute({List<_i9.PageRouteInfo>? children})
      : super(
          OnboardingRoute.name,
          initialChildren: children,
        );

  static const String name = 'OnboardingRoute';

  static const _i9.PageInfo<void> page = _i9.PageInfo<void>(name);
}

/// generated route for
/// [_i6.RecipeDetailScreen]
class RecipeDetailRoute extends _i9.PageRouteInfo<RecipeDetailRouteArgs> {
  RecipeDetailRoute({
    _i10.Key? key,
    required String brewingMethodId,
    required String recipeId,
    List<_i9.PageRouteInfo>? children,
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

  static const _i9.PageInfo<RecipeDetailRouteArgs> page =
      _i9.PageInfo<RecipeDetailRouteArgs>(name);
}

class RecipeDetailRouteArgs {
  const RecipeDetailRouteArgs({
    this.key,
    required this.brewingMethodId,
    required this.recipeId,
  });

  final _i10.Key? key;

  final String brewingMethodId;

  final String recipeId;

  @override
  String toString() {
    return 'RecipeDetailRouteArgs{key: $key, brewingMethodId: $brewingMethodId, recipeId: $recipeId}';
  }
}

/// generated route for
/// [_i7.RecipeListScreen]
class RecipeListRoute extends _i9.PageRouteInfo<RecipeListRouteArgs> {
  RecipeListRoute({
    _i10.Key? key,
    String? brewingMethodId,
    List<_i9.PageRouteInfo>? children,
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

  static const _i9.PageInfo<RecipeListRouteArgs> page =
      _i9.PageInfo<RecipeListRouteArgs>(name);
}

class RecipeListRouteArgs {
  const RecipeListRouteArgs({
    this.key,
    this.brewingMethodId,
  });

  final _i10.Key? key;

  final String? brewingMethodId;

  @override
  String toString() {
    return 'RecipeListRouteArgs{key: $key, brewingMethodId: $brewingMethodId}';
  }
}

/// generated route for
/// [_i8.SettingsScreen]
class SettingsRoute extends _i9.PageRouteInfo<void> {
  const SettingsRoute({List<_i9.PageRouteInfo>? children})
      : super(
          SettingsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsRoute';

  static const _i9.PageInfo<void> page = _i9.PageInfo<void>(name);
}
