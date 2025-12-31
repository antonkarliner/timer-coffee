import 'dart:async';
import 'dart:convert';
import 'package:coffee_timer/env/env.dart';
import 'package:coffeico/coffeico.dart';
import 'package:auto_size_text_plus/auto_size_text_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/database_provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/user_stat_provider.dart';
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart'; // Ensure this import is correct
import '../webhelper/web_helper.dart' as web;
import '../purchase_manager.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import '../providers/user_recipe_provider.dart'; // Import UserRecipeProvider
// Added import
import 'package:http/http.dart' as http; // Import http package
import 'package:coffee_timer/services/feature_flags/feature_flags_repository.dart';
// Import for RecipeCreationScreen
// Import AppDatabase and Recipe
import '../widgets/launch_popup.dart';
import '../utils/app_logger.dart'; // Import AppLogger

@RoutePage()
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late Locale initialLocale;
  bool _showBanner = false; // Banner flag
  String? _detectedCountry;
  late final Future<int> _yearlyBrews2025Future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (kIsWeb) {
      web.document.title = 'Timer.Coffee App';
      _fetchCountryAndBanner();
    }

    // Set up PurchaseManager callbacks
    PurchaseManager().setDeliverProductCallback(_showThankYouPopup);
    PurchaseManager().setPurchaseErrorCallback(_showErrorDialog);

    // Correctly obtain initialLocale from the Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure context is valid before accessing Provider
      if (mounted) {
        initialLocale = Provider.of<Locale>(context, listen: false);
        if (kIsWeb) {
          var recipeProvider =
              Provider.of<RecipeProvider>(context, listen: false);
          var tempLocale =
              const Locale('av'); // An example temporary locale for simulation
          recipeProvider.setLocale(tempLocale).then((_) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                // Check mounted again before accessing provider
                recipeProvider.setLocale(
                    initialLocale); // Revert to the initial app locale
              }
            });
          });
        }
      }
    });

    // Add post frame callback to check for recipes needing moderation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only check for moderation if user is authenticated and not anonymous
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && !user.isAnonymous) {
        _checkRecipesNeedingModeration();

        // Also trigger the post-login moderation check from UserRecipeProvider
        final userRecipeProvider =
            Provider.of<UserRecipeProvider>(context, listen: false);
        userRecipeProvider.checkModerationAfterLogin().catchError((e) {
          AppLogger.error("Failed to perform post-login moderation check",
              errorObject: e);
        });
      } else {
        AppLogger.debug(
            "Skipping moderation check - user not authenticated or anonymous");
      }
    });

    _yearlyBrews2025Future = _loadYearlyBrews2025();
  }

  Future<void> _checkRecipesNeedingModeration() async {
    if (!mounted) return; // Ensure the widget is still mounted

    // Skip moderation check for anonymous users
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      AppLogger.debug("Skipping moderation check for anonymous user");
      return;
    }

    final dbProvider = Provider.of<DatabaseProvider>(context, listen: false);
    final userRecipeProvider =
        Provider.of<UserRecipeProvider>(context, listen: false);

    try {
      AppLogger.debug("Starting moderation check for user: ${user.id}");

      // Use the public method from DatabaseProvider with timeout
      final flaggedRecipes = await dbProvider
          .getRecipesNeedingModeration()
          .timeout(const Duration(seconds: 5));

      AppLogger.debug(
          "Found ${flaggedRecipes.length} recipes needing moderation");

      if (flaggedRecipes.isEmpty || !mounted) {
        AppLogger.debug("No recipes need moderation or widget not mounted");
        return;
      }

      // Fetch names and store brewingMethodId with error handling
      List<Map<String, String>> flaggedRecipeDetails = [];
      for (final recipe in flaggedRecipes) {
        if (!mounted) break; // Early exit if widget unmounted

        try {
          // Fetch name using UserRecipeProvider with timeout
          final name = await userRecipeProvider
              .getUserRecipeName(recipe.id)
              .timeout(const Duration(seconds: 2));

          flaggedRecipeDetails.add({
            'id': recipe.id,
            'name': name ?? recipe.id, // Use recipe ID as fallback
            'brewingMethodId': recipe.brewingMethodId,
          });

          AppLogger.debug(
              "Added recipe to moderation list: ${recipe.id} (${name ?? 'unnamed'})");
        } catch (e) {
          AppLogger.warning(
              "Could not fetch name for flagged recipe ${recipe.id}",
              errorObject: e);
          // Still add with fallback name
          flaggedRecipeDetails.add({
            'id': recipe.id,
            'name': recipe.id, // Fallback to ID
            'brewingMethodId': recipe.brewingMethodId,
          });
        }
      }

      if (flaggedRecipeDetails.isEmpty || !mounted) {
        AppLogger.debug("No valid recipe details found or widget unmounted");
        return;
      }

      final firstFlaggedRecipe = flaggedRecipeDetails.first;
      final recipeNames =
          flaggedRecipeDetails.map((r) => "'${r['name']}'").join(', ');

      AppLogger.debug("Showing moderation popup for recipes: $recipeNames");

      final l10n = AppLocalizations.of(context)!;

      showDialog(
        context: context,
        barrierDismissible: false, // Prevent accidental dismissal
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(l10n.moderationReviewNeededTitle),
            content: Text(l10n.moderationReviewNeededMessage(recipeNames)),
            actions: [
              TextButton(
                child: Text(l10n.dismiss),
                onPressed: () {
                  AppLogger.debug("User dismissed moderation popup");
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text(l10n.reviewRecipeButton),
                onPressed: () {
                  AppLogger.debug(
                      "User chose to review recipe: ${firstFlaggedRecipe['id']}");
                  Navigator.of(context).pop();
                  // Navigate to recipe detail with error handling
                  try {
                    context.router.push(RecipeDetailRoute(
                      recipeId: firstFlaggedRecipe['id']!,
                      brewingMethodId: firstFlaggedRecipe['brewingMethodId']!,
                    ));
                  } catch (e) {
                    AppLogger.error("Failed to navigate to recipe detail",
                        errorObject: e);
                    // Could show a snackbar here if needed
                  }
                },
              ),
            ],
          );
        },
      );

      AppLogger.debug("Moderation popup displayed successfully");
    } on TimeoutException catch (e) {
      AppLogger.error("Timeout while checking for recipes needing moderation",
          errorObject: e);
      // Don't show error to user, just log it
    } catch (e, stackTrace) {
      AppLogger.error(
          "Unexpected error checking for recipes needing moderation",
          errorObject: e,
          stackTrace: stackTrace);
      // Don't show error dialog to user as this is a background check
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PurchaseManager().setDeliverProductCallback(null);
    PurchaseManager().setPurchaseErrorCallback(null);
    super.dispose();
  }

  Future<void> _fetchCountryAndBanner() async {
    try {
      // Use HTTPS endpoint from country.is
      final response = await http.get(Uri.parse('https://api.country.is/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final detected = data['country']?.toString() ?? '';
        AppLogger.info('Detected country: $detected');
        if (mounted) {
          // Check mounted before setState
          setState(() {
            _detectedCountry = detected;
          });
        }

        // Read the target banner country from your Env file.
        final bannerCountry = Env.bannerCountry;
        AppLogger.debug('Banner Country (env): $bannerCountry');

        if (bannerCountry.isNotEmpty && detected == bannerCountry) {
          if (mounted) {
            // Check mounted before setState
            setState(() {
              _showBanner = true;
            });
          }
        }
      } else {
        AppLogger.warning('Failed to fetch country: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching country', errorObject: e);
    }
  }

  Future<int> _loadYearlyBrews2025() async {
    final userStatProvider =
        Provider.of<UserStatProvider>(context, listen: false);
    final start = DateTime(2025, 1, 1);
    final end = DateTime(2026, 1, 1);
    try {
      final statsAll = await userStatProvider.fetchAllUserStats();
      final brews2025 = statsAll
          .where((s) =>
              !s.isDeleted &&
              !s.createdAt.isBefore(start) &&
              s.createdAt.isBefore(end))
          .length;
      AppLogger.debug('Home banner: 2025 brews=$brews2025');
      return brews2025;
    } catch (e) {
      AppLogger.error('Home banner: failed to load 2025 brews',
          errorObject: e);
      return 0;
    }
  }

  void _showThankYouPopup(PurchaseDetails details) {
    if (mounted) {
      final l10n = AppLocalizations.of(context)!; // Get localizations
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(l10n.donationok),
            content: Text(l10n.donationtnx),
            actions: [
              TextButton(
                child: Text(l10n.ok),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _showErrorDialog(IAPError error) {
    if (mounted) {
      final l10n = AppLocalizations.of(context)!; // Get localizations
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(l10n.donationerr),
            content: Text(l10n.donationerrmsg),
            actions: [
              TextButton(
                child: Text(l10n.ok),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context); // Get localizations safely
    final flags = context.watch<Map<String, bool>>();
    final showGiftBanner = flags[FeatureFlagKeys.holidayGiftBox] ?? false;
    final showYearlyStats25Banner =
        flags[FeatureFlagKeys.yearlyStatsStory25Banner] ?? false;

    // Handle case where localizations are null during initialization
    if (l10n == null) {
      return Scaffold(
        appBar: buildPlatformSpecificAppBar(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return AutoTabsRouter.tabBar(
      routes: [
        BrewingMethodsRoute(),
        CoffeeBeansRoute(),
        HubHomeRoute(),
      ],
      builder: (context, child, tabController) {
        final tabsRouter = AutoTabsRouter.of(context);

        return Scaffold(
          appBar: buildPlatformSpecificAppBar(),
          body: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // Launch popup trigger (side-effect only, renders nothing)
              LaunchPopupWidget(),

              if (showYearlyStats25Banner)
                FutureBuilder<int>(
                  future: _yearlyBrews2025Future,
                  builder: (context, snapshot) {
                    final brews2025 = snapshot.data ?? 0;
                    final title = brews2025 > 3
                        ? l10n.yearlyStats25Slide1Title
                        : l10n.yearlyStats25AppBarTitleSimple;
                    return _YearlyStats25Banner(
                      title: title,
                      onTap: () {
                        context.router.push(const YearlyStatsStory25Route());
                      },
                    );
                  },
                ),

              // Holiday gift box banner (feature-flagged)
              if (showGiftBanner) _GiftBoxBanner(onTap: () {
                context.router.push(const GiftBoxListRoute());
              }),

              // Show banner only on web if _showBanner is true.
              if (kIsWeb && _showBanner)
                Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.onSurface,
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Timer.Coffee stands with Palestine', // Skipped localization as requested
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                          width: 10), // Spacing between image and text.
                      // Display the image from the URL.
                      Image.network(
                        'https://i.ibb.co/4g4J6ZML/palectine-coffee.png',
                        height: 30, // Adjust height as needed.
                      ),
                    ],
                  ),
                ),
              Expanded(child: child),
            ],
          ),
          // active tab's content
          bottomNavigationBar: ConvexAppBar.builder(
            count: 3,
            controller: tabController, // <-- keep bar & swipes in sync
            backgroundColor: Theme.of(context).colorScheme.onSurface,
            itemBuilder: _CustomTabBuilder([
              TabItem(
                  icon: Coffeico.coffee_maker,
                  title: l10n.homescreenbrewcoffee),
              TabItem(icon: Coffeico.bag_with_bean, title: l10n.myBeans),
              TabItem(icon: Icons.dashboard, title: l10n.homescreenmore),
            ], context),
            onTap: tabsRouter.setActiveIndex, // taps still change page
          ),
        );
      },
    );
  }

  PreferredSizeWidget buildPlatformSpecificAppBar() {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return CupertinoNavigationBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        middle: Text('Timer.Coffee', // Skipped localization as requested
            style: TextStyle(
                fontFamily: 'Inter',
                color: Theme.of(context).appBarTheme.foregroundColor)),
      );
    } else {
      return AppBar(
        title: const Text('Timer.Coffee'), // Skipped localization as requested
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      );
    }
  }
}

class _CustomTabBuilder extends DelegateBuilder {
  final List<TabItem> items;
  final BuildContext context;

  _CustomTabBuilder(this.items, this.context);

  @override
  Widget build(BuildContext context, int index, bool active) {
    Color activeColor = Theme.of(context).brightness == Brightness.light
        ? Colors.white
        : Colors.black;
    Color inactiveColor = Theme.of(context).brightness == Brightness.light
        ? Colors.white.withAlpha((255 * 0.5).round())
        : Colors.black.withAlpha((255 * 0.5).round());

    var item = items[index];
    return Semantics(
      identifier: 'tabItem_$index',
      label: item.title ?? "",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            item.icon,
            color: active ? activeColor : inactiveColor,
          ),
          Text(item.title ?? "",
              style: TextStyle(
                color: active ? activeColor : inactiveColor,
              )),
        ],
      ),
    );
  }
}

class _YearlyStats25Banner extends StatefulWidget {
  const _YearlyStats25Banner({
    required this.onTap,
    required this.title,
  });

  final VoidCallback onTap;
  final String title;

  @override
  State<_YearlyStats25Banner> createState() => _YearlyStats25BannerState();
}

class _YearlyStats25BannerState extends State<_YearlyStats25Banner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = theme.brightness == Brightness.light
        ? colorScheme.onPrimary
        : colorScheme.primary;
    final shimmerOpacity = theme.brightness == Brightness.dark ? 0.05 : 0.10;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth.isFinite
                      ? constraints.maxWidth
                      : MediaQuery.of(context).size.width;
                  final baseHeight = constraints.maxHeight.isFinite
                      ? constraints.maxHeight
                      : 48.0;
                  final shimmerWidth = availableWidth * 0.2;
                  final shimmerHeight = baseHeight * 1.3;
                  final travel = availableWidth + shimmerWidth * 2;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, _) {
                              final dx = -shimmerWidth +
                                  travel * _shimmerController.value;
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Transform.translate(
                                  offset: Offset(dx, 0),
                                  child: Transform.rotate(
                                    angle: -0.2,
                                    child: SizedBox(
                                      width: shimmerWidth,
                                      height: shimmerHeight,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              Colors.transparent,
                                              Colors.white
                                                  .withOpacity(shimmerOpacity),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 14),
                        child: Row(
                          children: [
                            const Text(
                              '📅',
                              style: TextStyle(fontSize: 20, height: 1),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AutoSizeText(
                                widget.title,
                                maxLines: 1,
                                minFontSize: 10,
                                stepGranularity: 0.25,
                                wrapWords: false,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward_ios,
                                size: 14, color: textColor),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GiftBoxBanner extends StatelessWidget {
  const _GiftBoxBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final base = theme.colorScheme.surfaceVariant;
    final festiveRed = const Color(0xFFE53935);
    final festiveGreen = const Color(0xFF43A047);
    final festiveGold = const Color(0xFFFFD54F);
    final tint = theme.brightness == Brightness.dark ? 0.30 : 0.42;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(base, festiveRed, tint)!,
        Color.lerp(base, festiveGold, tint * 0.85)!,
        Color.lerp(base, festiveGreen, tint)!,
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.card_giftcard,
                      color: theme.colorScheme.primary, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AutoSizeText(
                      l10n.holidayGiftBoxBannerTitle,
                      maxLines: 1,
                      minFontSize: 12,
                      stepGranularity: 0.5,
                      wrapWords: false,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios,
                      size: 14, color: theme.colorScheme.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
