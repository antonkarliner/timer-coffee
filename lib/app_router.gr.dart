// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i20;
import 'package:coffee_timer/models/recipe_model.dart' as _i23;
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
import 'package:coffee_timer/screens/notification_debug_screen.dart' as _i12;
import 'package:coffee_timer/screens/recipe_creation_screen.dart' as _i13;
import 'package:coffee_timer/screens/recipe_detail_screen.dart' as _i14;
import 'package:coffee_timer/screens/recipe_list_screen.dart' as _i15;
import 'package:coffee_timer/screens/settings_screen.dart' as _i16;
import 'package:coffee_timer/screens/stats_screen.dart' as _i17;
import 'package:coffee_timer/screens/user_recipe_management_screen.dart'
    as _i18;
import 'package:coffee_timer/screens/yearly_stats_story_screen.dart' as _i19;
import 'package:flutter/foundation.dart' as _i21;
import 'package:flutter/material.dart' as _i22;

/// generated route for
/// [_i1.AccountScreen]
class AccountRoute extends _i20.PageRouteInfo<AccountRouteArgs> {
  AccountRoute({
    _i21.Key? key,
    required String userId,
    List<_i20.PageRouteInfo>? children,
  }) : super(
          AccountRoute.name,
          args: AccountRouteArgs(key: key, userId: userId),
          rawPathParams: {'userId': userId},
          initialChildren: children,
        );

  static const String name = 'AccountRoute';

  static _i20.PageInfo page = _i20.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<AccountRouteArgs>(
        orElse: () => AccountRouteArgs(userId: pathParams.getString('userId')),
      );
      return _i1.AccountScreen(key: args.key, userId: args.userId);
    },
  );
}

class AccountRouteArgs {
  const AccountRouteArgs({this.key, required this.userId});

  final _i21.Key? key;

  final String userId;

  @override
  String toString() {
    return 'AccountRouteArgs{key: $key, userId: $userId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AccountRouteArgs) return false;
    return key == other.key && userId == other.userId;
  }

  @override
  int get hashCode => key.hashCode ^ userId.hashCode;
}

/// generated route for
/// [_i2.BrewDiaryScreen]
class BrewDiaryRoute extends _i20.PageRouteInfo<void> {
  const BrewDiaryRoute({List<_i20.PageRouteInfo>? children})
      : super(BrewDiaryRoute.name, initialChildren: children);

  static const String name = 'BrewDiaryRoute';

  static _i20.PageInfo page = _i20.PageInfo(
    name,
    builder: (data) {
      return const _i2.BrewDiaryScreen();
    },
  );
}

/// generated route for
/// [_i3.BrewingMethodsScreen]
class BrewingMethodsRoute extends _i20.PageRouteInfo<void> {
  const BrewingMethodsRoute({List<_i20.PageRouteInfo>? children})
      : super(BrewingMethodsRoute.name, initialChildren: children);

  static const String name = 'BrewingMethodsRoute';

  static _i20.PageInfo page = _i20.PageInfo(
    name,
    builder: (data) {
      return const _i3.BrewingMethodsScreen();
    },
  );
}

/// generated route for
/// [_i4.CoffeeBeansDetailScreen]
class CoffeeBeansDetailRoute
    extends _i20.PageRouteInfo<CoffeeBeansDetailRouteArgs> {
  CoffeeBeansDetailRoute({
    _i22.Key? key,
    required String uuid,
    List<_i20.PageRouteInfo>? children,
  }) : super(
          CoffeeBeansDetailRoute.name,
          args: CoffeeBeansDetailRouteArgs(key: key, uuid: uuid),
          initialChildren: children,
        );

  static const String name = 'CoffeeBeansDetailRoute';

  static _i20.PageInfo page = _i20.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CoffeeBeansDetailRouteArgs>();
      return _i4.CoffeeBeansDetailScreen(key: args.key, uuid: args.uuid);
    },
  );
}

class CoffeeBeansDetailRouteArgs {
  const CoffeeBeansDetailRouteArgs({this.key, required this.uuid});

  final _i22.Key? key;

  final String uuid;

  @override
  String toString() {
    return 'CoffeeBeansDetailRouteArgs{key: $key, uuid: $uuid}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CoffeeBeansDetailRouteArgs) return false;
    return key == other.key && uuid == other.uuid;
  }

  @override
  int get hashCode => key.hashCode ^ uuid.hashCode;
}

/// generated route for
/// [_i5.CoffeeBeansScreen]
class CoffeeBeansRoute extends _i20.PageRouteInfo<void> {
  const CoffeeBeansRoute({List<_i20.PageRouteInfo>? children})
      : super(CoffeeBeansRoute.name, initialChildren: children);

  static const String name = 'CoffeeBeansRoute';

  static _i20.PageInfo page = _i20.PageInfo(
    name,
    builder: (data) {
      return const _i5.CoffeeBeansScreen();
    },
  );
}

/// generated route for
/// [_i6.DonationScreen]
class DonationRoute extends _i20.PageRouteInfo<void> {
  const DonationRoute({List<_i20.PageRouteInfo>? children})
      : super(DonationRoute.name, initialChildren: children);

  static const String name = 'DonationRoute';

  static _i20.PageInfo page = _i20.PageInfo(
    name,
    builder: (data) {
      return _i6.DonationScreen();
    },
  );
}

/// generated route for
/// [_i7.FavoriteRecipesScreen]
class FavoriteRecipesRoute extends _i20.PageRouteInfo<void> {
  const FavoriteRecipesRoute({List<_i20.PageRouteInfo>? children})
      : super(FavoriteRecipesRoute.name, initialChildren: children);

  static const String name = 'FavoriteRecipesRoute';

  static _i20.PageInfo page = _i20.PageInfo(
    name,
    builder: (data) {
      return _i7.FavoriteRecipesScreen();
    },
  );
}

/// generated route for
/// [_i8.HomeScreen]
class HomeRoute extends _i20.PageRouteInfo<void> {
  const HomeRoute({List<_i20.PageRouteInfo>? children})
      : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i20.PageInfo page = _i20.PageInfo(
    name,
    builder: (data) {
      return const _i8.HomeScreen();
    },
  );
}

/// generated route for
/// [_i9.HubHomeScreen]
class HubHomeRoute extends _i20.PageRouteInfo<void> {
  const HubHomeRoute({List<_i20.PageRouteInfo>? children})
      : super(HubHomeRoute.name, initialChildren: children);

  static const String name = 'HubHomeRoute';

  static _i20.PageInfo page = _i20.PageInfo(
    name,
    builder: (data) {
      return const _i9.HubHomeScreen();
    },
  );
}

/// generated route for
/// [_i10.InfoScreen]
class InfoRoute extends _i20.PageRouteInfo<void> {
  const InfoRoute({List<_i20.PageRouteInfo>? children})
      : super(InfoRoute.name, initialChildren: children);

  static const String name = 'InfoRoute';

  static _i20.PageInfo page = _i20.PageInfo(
    name,
    builder: (data) {
      return const _i10.InfoScreen();
    },
  );
}

/// generated route for
/// [_i11.NewBeansScreen]
class NewBeansRoute extends _i20.PageRouteInfo<NewBeansRouteArgs> {
  NewBeansRoute({
    _i22.Key? key,
    String? uuid,
    List<_i20.PageRouteInfo>? children,
  }) : super(
          NewBeansRoute.name,
          args: NewBeansRouteArgs(key: key, uuid: uuid),
          initialChildren: children,
        );

  static const String name = 'NewBeansRoute';

  static _i20.PageInfo page = _i20.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NewBeansRouteArgs>(
        orElse: () => const NewBeansRouteArgs(),
      );
      return _i11.NewBeansScreen(key: args.key, uuid: args.uuid);
    },
  );
}

class NewBeansRouteArgs {
  const NewBeansRouteArgs({this.key, this.uuid});

  final _i22.Key? key;

  final String? uuid;

  @override
  String toString() {
    return 'NewBeansRouteArgs{key: $key, uuid: $uuid}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NewBeansRouteArgs) return false;
    return key == other.key && uuid == other.uuid;
  }

  @override
  int get hashCode => key.hashCode ^ uuid.hashCode;
}

/// generated route for
/// [_i12.NotificationDebugScreen]
class NotificationDebugRoute
    extends _i20.PageRouteInfo<NotificationDebugRouteArgs> {
  NotificationDebugRoute({_i22.Key? key, List<_i20.PageRouteInfo>? children})
      : super(
          NotificationDebugRoute.name,
          args: NotificationDebugRouteArgs(key: key),
          initialChildren: children,
        );

  static const String name = 'NotificationDebugRoute';

  static _i20.PageInfo page = _i20.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NotificationDebugRouteArgs>(
        orElse: () => const NotificationDebugRouteArgs(),
      );
      return _i12.NotificationDebugScreen(key: args.key);
    },
  );
}

class NotificationDebugRouteArgs {
  const NotificationDebugRouteArgs({this.key});

  final _i22.Key? key;

  @override
  String toString() {
    return 'NotificationDebugRouteArgs{key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NotificationDebugRouteArgs) return false;
    return key == other.key;
  }

  @override
  int get hashCode => key.hashCode;
}

/// generated route for
/// [_i13.RecipeCreationScreen]
class RecipeCreationRoute extends _i20.PageRouteInfo<RecipeCreationRouteArgs> {
  RecipeCreationRoute({
    _i22.Key? key,
    _i23.RecipeModel? recipe,
    String? brewingMethodId,
    bool redirectToNewDetailOnSave = false,
    List<_i20.PageRouteInfo>? children,
  }) : super(
          RecipeCreationRoute.name,
          args: RecipeCreationRouteArgs(
            key: key,
            recipe: recipe,
            brewingMethodId: brewingMethodId,
            redirectToNewDetailOnSave: redirectToNewDetailOnSave,
          ),
          initialChildren: children,
        );

  static const String name = 'RecipeCreationRoute';

  static _i20.PageInfo page = _i20.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RecipeCreationRouteArgs>(
        orElse: () => const RecipeCreationRouteArgs(),
      );
      return _i13.RecipeCreationScreen(
        key: args.key,
        recipe: args.recipe,
        brewingMethodId: args.brewingMethodId,
        redirectToNewDetailOnSave: args.redirectToNewDetailOnSave,
      );
    },
  );
}

class RecipeCreationRouteArgs {
  const RecipeCreationRouteArgs({
    this.key,
    this.recipe,
    this.brewingMethodId,
    this.redirectToNewDetailOnSave = false,
  });

  final _i22.Key? key;

  final _i23.RecipeModel? recipe;

  final String? brewingMethodId;

  final bool redirectToNewDetailOnSave;

  @override
  String toString() {
    return 'RecipeCreationRouteArgs{key: $key, recipe: $recipe, brewingMethodId: $brewingMethodId, redirectToNewDetailOnSave: $redirectToNewDetailOnSave}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RecipeCreationRouteArgs) return false;
    return key == other.key &&
        recipe == other.recipe &&
        brewingMethodId == other.brewingMethodId &&
        redirectToNewDetailOnSave == other.redirectToNewDetailOnSave;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      recipe.hashCode ^
      brewingMethodId.hashCode ^
      redirectToNewDetailOnSave.hashCode;
}

/// generated route for
/// [_i14.RecipeDetailScreen]
class RecipeDetailRoute extends _i20.PageRouteInfo<RecipeDetailRouteArgs> {
  RecipeDetailRoute({
    _i22.Key? key,
    required String brewingMethodId,
    required String recipeId,
    List<_i20.PageRouteInfo>? children,
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

  static _i20.PageInfo page = _i20.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<RecipeDetailRouteArgs>(
        orElse: () => RecipeDetailRouteArgs(
          brewingMethodId: pathParams.getString('brewingMethodId'),
          recipeId: pathParams.getString('recipeId'),
        ),
      );
      return _i14.RecipeDetailScreen(
        key: args.key,
        brewingMethodId: args.brewingMethodId,
        recipeId: args.recipeId,
      );
    },
  );
}

class RecipeDetailRouteArgs {
  const RecipeDetailRouteArgs({
    this.key,
    required this.brewingMethodId,
    required this.recipeId,
  });

  final _i22.Key? key;

  final String brewingMethodId;

  final String recipeId;

  @override
  String toString() {
    return 'RecipeDetailRouteArgs{key: $key, brewingMethodId: $brewingMethodId, recipeId: $recipeId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RecipeDetailRouteArgs) return false;
    return key == other.key &&
        brewingMethodId == other.brewingMethodId &&
        recipeId == other.recipeId;
  }

  @override
  int get hashCode =>
      key.hashCode ^ brewingMethodId.hashCode ^ recipeId.hashCode;
}

/// generated route for
/// [_i15.RecipeListScreen]
class RecipeListRoute extends _i20.PageRouteInfo<RecipeListRouteArgs> {
  RecipeListRoute({
    _i22.Key? key,
    String? brewingMethodId,
    List<_i20.PageRouteInfo>? children,
  }) : super(
          RecipeListRoute.name,
          args: RecipeListRouteArgs(key: key, brewingMethodId: brewingMethodId),
          rawPathParams: {'brewingMethodId': brewingMethodId},
          initialChildren: children,
        );

  static const String name = 'RecipeListRoute';

  static _i20.PageInfo page = _i20.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<RecipeListRouteArgs>(
        orElse: () => RecipeListRouteArgs(
          brewingMethodId: pathParams.optString('brewingMethodId'),
        ),
      );
      return _i15.RecipeListScreen(
        key: args.key,
        brewingMethodId: args.brewingMethodId,
      );
    },
  );
}

class RecipeListRouteArgs {
  const RecipeListRouteArgs({this.key, this.brewingMethodId});

  final _i22.Key? key;

  final String? brewingMethodId;

  @override
  String toString() {
    return 'RecipeListRouteArgs{key: $key, brewingMethodId: $brewingMethodId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RecipeListRouteArgs) return false;
    return key == other.key && brewingMethodId == other.brewingMethodId;
  }

  @override
  int get hashCode => key.hashCode ^ brewingMethodId.hashCode;
}

/// generated route for
/// [_i16.SettingsScreen]
class SettingsRoute extends _i20.PageRouteInfo<void> {
  const SettingsRoute({List<_i20.PageRouteInfo>? children})
      : super(SettingsRoute.name, initialChildren: children);

  static const String name = 'SettingsRoute';

  static _i20.PageInfo page = _i20.PageInfo(
    name,
    builder: (data) {
      return const _i16.SettingsScreen();
    },
  );
}

/// generated route for
/// [_i17.StatsScreen]
class StatsRoute extends _i20.PageRouteInfo<void> {
  const StatsRoute({List<_i20.PageRouteInfo>? children})
      : super(StatsRoute.name, initialChildren: children);

  static const String name = 'StatsRoute';

  static _i20.PageInfo page = _i20.PageInfo(
    name,
    builder: (data) {
      return const _i17.StatsScreen();
    },
  );
}

/// generated route for
/// [_i18.UserRecipeManagementScreen]
class UserRecipeManagementRoute extends _i20.PageRouteInfo<void> {
  const UserRecipeManagementRoute({List<_i20.PageRouteInfo>? children})
      : super(UserRecipeManagementRoute.name, initialChildren: children);

  static const String name = 'UserRecipeManagementRoute';

  static _i20.PageInfo page = _i20.PageInfo(
    name,
    builder: (data) {
      return const _i18.UserRecipeManagementScreen();
    },
  );
}

/// generated route for
/// [_i19.YearlyStatsStoryScreen]
class YearlyStatsStoryRoute extends _i20.PageRouteInfo<void> {
  const YearlyStatsStoryRoute({List<_i20.PageRouteInfo>? children})
      : super(YearlyStatsStoryRoute.name, initialChildren: children);

  static const String name = 'YearlyStatsStoryRoute';

  static _i20.PageInfo page = _i20.PageInfo(
    name,
    builder: (data) {
      return const _i19.YearlyStatsStoryScreen();
    },
  );
}
