import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/env/env.dart';
import 'package:coffee_timer/models/supported_locale_model.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/purchase_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show SystemChrome, SystemUiMode, SystemUiOverlay, rootBundle;
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';
import 'models/brewing_method_model.dart';
import './providers/recipe_provider.dart';
import './providers/theme_provider.dart';
import './providers/coffee_beans_provider.dart';
import './providers/user_recipe_provider.dart';
import './app_router.dart';
import './app_router.gr.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'models/recipe_model.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import './providers/snow_provider.dart';
import 'widgets/global_snow_overlay.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:coffee_timer/services/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'notifiers/card_expansion_notifier.dart';
import 'firebase_options.dart';
import './providers/user_stat_provider.dart';
import './providers/beans_stats_provider.dart';
import 'package:coffee_timer/utils/app_logger.dart';
import 'package:coffee_timer/utils/log_config.dart';

/// Custom log handler that intercepts and sanitizes all Supabase library logs
/// Prevents sensitive data exposure by ensuring all logs go through AppLogger
class SupabaseLogInterceptor {
  static bool _isInitialized = false;
  static bool _isLogging = false; // Prevent recursive logging

  static void initialize() {
    if (_isInitialized) return; // Prevent multiple initializations
    _isInitialized = true;

    // Override debugPrint to catch any direct console output from Supabase
    // This is a targeted approach that doesn't disrupt the logging system
    if (!LogConfig.isReleaseMode) {
      // In debug mode, we want to see sanitized logs
      debugPrint = (String? message, {int? wrapWidth}) {
        // Prevent recursive logging
        if (_isLogging) return;

        if (message != null && message.contains('supabase')) {
          _isLogging = true;
          try {
            final sanitized = AppLogger.sanitize(message);
            // Use direct print to avoid recursive call to AppLogger.debug
            print('[SUPABASE] ${sanitized}');
          } finally {
            _isLogging = false;
          }
          return; // Don't print the original message
        }
        // For non-Supabase messages, let them through normally
        if (message != null) {
          _isLogging = true;
          try {
            // Use direct print to avoid recursive call to AppLogger.debug
            print(message);
          } finally {
            _isLogging = false;
          }
        }
      };
    }
  }

  static void dispose() {
    _isInitialized = false;
    _isLogging = false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsBinding.instance);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top]);

  // Initialize Supabase log interceptor FIRST
  SupabaseLogInterceptor.initialize();

  // Then initialize AppLogger
  LogConfig.initialize();

  // Initialize Firebase with timeout protection
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        AppLogger.warning('Firebase initialization timed out');
        throw TimeoutException(
            'Firebase initialization timed out after 10 seconds',
            const Duration(seconds: 10));
      },
    );
    AppLogger.debug('Firebase initialized successfully');
  } catch (e) {
    AppLogger.error('Failed to initialize Firebase', errorObject: e);
    // Continue app startup even if Firebase fails, but functionality will be limited
    rethrow; // Let calling code handle the error appropriately
  }

  if (!kIsWeb) {
    // Initialize timezone data for scheduling
    tz.initializeTimeZones();
    // Initialize NotificationService early to ensure proper setup with timeout protection
    try {
      await NotificationService.instance.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          AppLogger.warning('NotificationService initialization timed out');
          // Continue app startup even if notifications fail
        },
      );
      AppLogger.debug('NotificationService initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize NotificationService',
          errorObject: e);
      // Continue app startup even if notifications fail
    }
  }

  // Initialize PurchaseManager (no-op on unsupported platforms)
  final purchaseManager = PurchaseManager();
  unawaited(purchaseManager.restorePurchasesIfSupported());

  // Initialize Supabase with timeout protection
  try {
    await Supabase.initialize(url: Env.supaUrl, anonKey: Env.supaKey).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        AppLogger.warning('Supabase initialization timed out');
        throw TimeoutException(
            'Supabase initialization timed out after 10 seconds',
            const Duration(seconds: 10));
      },
    );
    AppLogger.debug('Supabase initialized successfully');
  } catch (e) {
    AppLogger.error('Failed to initialize Supabase', errorObject: e);
    // Continue app startup even if Supabase fails, but functionality will be limited
    rethrow; // Let calling code handle the error appropriately
  }

  // Check if there is an existing session or logged-in user
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) {
    // No session found, proceed with anonymous sign-in
    final authResult = await Supabase.instance.client.auth.signInAnonymously();
    if (authResult.user == null) {
      // Handle error
    } else {
      // Successfully signed in
    }
  }

  final user = Supabase.instance.client.auth.currentUser;
  if (!kIsWeb && user != null) {
    // Note: NotificationService will be initialized lazily when first accessed
    // FCM will be handled when user explicitly enables notifications
    AppLogger.debug(
        'User authenticated, notifications will be setup when enabled');
  }
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstLaunch = prefs.getBool('firstLaunched') ?? true;
  bool hasPerformedUuidBackfill =
      prefs.getBool('hasPerformedUuidBackfill') ?? false;

  final AppDatabase database =
      AppDatabase.withDefault(enableForeignKeyConstraints: !isFirstLaunch);

  final supportedLocalesDao = SupportedLocalesDao(database);
  final brewingMethodsDao = BrewingMethodsDao(database);

  // Initialize databaseProvider before passing it to CoffeeTimerApp
  // Defer fetching until after database initialization

  String themeModeString = prefs.getString('themeMode') ?? 'system';
  ThemeMode themeMode = ThemeMode.values.firstWhere(
      (e) => e.toString().split('.').last == themeModeString,
      orElse: () => ThemeMode.system);
  String? savedLocaleCode = prefs.getString('locale');
  Locale systemLocale =
      Locale(WidgetsBinding.instance.window.locale.languageCode);
  // Choose an initial locale BEFORE DB init so first-launch uses correct language.
  // Constrain to generated l10n locales to avoid empty/unsynced DB lists on first run.
  final List<Locale> genSupported = AppLocalizations.supportedLocales;
  Locale initialLocale = const Locale('en'); // default
  if (savedLocaleCode != null) {
    initialLocale = Locale(savedLocaleCode);
  } else if (genSupported
      .any((l) => l.languageCode == systemLocale.languageCode)) {
    initialLocale = systemLocale;
  }

  final DatabaseProvider databaseProvider = DatabaseProvider(database);
  await databaseProvider.initializeDatabase(
      isFirstLaunch: isFirstLaunch, locale: initialLocale.languageCode);

  // Re-fetch supported locales after initialization to ensure they are populated
  final List<SupportedLocaleModel> updatedSupportedLocales =
      await supportedLocalesDao.getAllSupportedLocales();
  List<Locale> updatedLocaleList =
      updatedSupportedLocales.map((locale) => Locale(locale.locale)).toList();

  // Now that DB is initialized, fetch supported locales and brewing methods
  final List<SupportedLocaleModel> supportedLocalesModels =
      await supportedLocalesDao.getAllSupportedLocales();
  final List<BrewingMethodModel> brewingMethods =
      await brewingMethodsDao.getAllBrewingMethods();

  // Prefer DB locales if available; otherwise fall back to generated ones
  final List<Locale> dbLocales =
      supportedLocalesModels.map((l) => Locale(l.locale)).toList();
  final List<Locale> effectiveSupportedLocales =
      dbLocales.isNotEmpty ? dbLocales : AppLocalizations.supportedLocales;

  // Re-check initial locale against effectiveSupportedLocales; if not present, fallback to en
  if (!effectiveSupportedLocales
      .any((l) => l.languageCode == initialLocale.languageCode)) {
    initialLocale = const Locale('en');
  }

  final appRouter = AppRouter();
  usePathUrlStrategy();

  final coffeeBeansProvider = CoffeeBeansProvider(database, databaseProvider);
  final userStatProvider = UserStatProvider(database, coffeeBeansProvider);
  final beansStatsProvider = BeansStatsProvider(database);

  if (!hasPerformedUuidBackfill) {
    // Perform backfill operations
    await coffeeBeansProvider.backfillMissingUuids();
    await userStatProvider.backfillMissingStatUuids();
    await userStatProvider.backfillMissingCoffeeBeansUuids();

    // Mark backfill as completed
    await prefs.setBool('hasPerformedUuidBackfill', true);
  }
  try {
    await Future.wait([
      databaseProvider
          .fetchAndInsertUserPreferencesFromSupabase()
          .timeout(const Duration(seconds: 10))
          .catchError((e) => AppLogger.error('User preferences sync timed out',
              errorObject: e)),
      userStatProvider
          .syncNewUserStats()
          .timeout(const Duration(seconds: 10))
          .catchError((e) =>
              AppLogger.error('User stats sync timed out', errorObject: e)),
      coffeeBeansProvider
          .syncNewCoffeeBeans()
          .timeout(const Duration(seconds: 10))
          .catchError((e) =>
              AppLogger.error('Coffee beans sync timed out', errorObject: e)),
    ]);
  } catch (e) {
    AppLogger.error('Error during parallel sync operations', errorObject: e);
    // Continue app startup even if sync fails
  }

  AppLogger.debug('Supported locales (effective): $effectiveSupportedLocales');
  AppLogger.debug('Initial locale chosen: $initialLocale');
  runApp(
    CoffeeTimerApp(
      database: database,
      databaseProvider: databaseProvider,
      supportedLocales: effectiveSupportedLocales,
      brewingMethods: brewingMethods,
      initialLocale: initialLocale,
      themeMode: themeMode,
      appRouter: appRouter,
      coffeeBeansProvider: coffeeBeansProvider,
      userStatProvider: userStatProvider,
      beansStatsProvider: beansStatsProvider,
    ),
  );

  if (isFirstLaunch) {
    await prefs.setBool('firstLaunched', false);
  }

  FlutterNativeSplash.remove();
}

class CoffeeTimerApp extends StatefulWidget {
  final AppDatabase database;
  final DatabaseProvider databaseProvider;
  final List<Locale> supportedLocales;
  final List<BrewingMethodModel> brewingMethods;
  final Locale initialLocale;
  final ThemeMode themeMode;
  final AppRouter appRouter;
  final CoffeeBeansProvider coffeeBeansProvider;
  final UserStatProvider userStatProvider;
  final BeansStatsProvider beansStatsProvider;

  const CoffeeTimerApp({
    Key? key,
    required this.database,
    required this.databaseProvider,
    required this.supportedLocales,
    required this.brewingMethods,
    required this.initialLocale,
    required this.themeMode,
    required this.appRouter,
    required this.coffeeBeansProvider,
    required this.userStatProvider,
    required this.beansStatsProvider,
  }) : super(key: key);

  @override
  _CoffeeTimerAppState createState() => _CoffeeTimerAppState();
}

class _CoffeeTimerAppState extends State<CoffeeTimerApp> {
  @override
  void initState() {
    super.initState();
    _setupNotificationTapHandler(context);
  }

  void _setupNotificationTapHandler(BuildContext context) {
    NotificationService.instance.onNotificationTapped.listen((payload) {
      if (payload == null) return;

      // Example deep link handling
      if (payload.startsWith('/')) {
        widget.appRouter.pushNamed(payload);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: widget.database),
        ChangeNotifierProvider<RecipeProvider>(
          create: (_) => RecipeProvider(
              widget.initialLocale,
              widget.supportedLocales,
              widget.database,
              widget.databaseProvider),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(widget.themeMode),
        ),
        ChangeNotifierProvider<SnowEffectProvider>(
          create: (_) => SnowEffectProvider(),
        ),
        Provider<List<BrewingMethodModel>>(
          create: (_) => widget.brewingMethods,
        ),
        Provider<Locale>.value(value: widget.initialLocale),
        Provider<DatabaseProvider>.value(value: widget.databaseProvider),
        ChangeNotifierProvider<CoffeeBeansProvider>.value(
            value: widget.coffeeBeansProvider),
        ChangeNotifierProvider<CardExpansionNotifier>(
          create: (_) => CardExpansionNotifier(),
        ),
        ChangeNotifierProvider<UserStatProvider>.value(
            value: widget.userStatProvider),
        ChangeNotifierProvider<BeansStatsProvider>.value(
            value: widget.beansStatsProvider),
        ChangeNotifierProvider<UserRecipeProvider>(
          create: (_) => UserRecipeProvider(widget.database),
        ),
        Provider<NotificationService>.value(
            value: NotificationService.instance),
      ],
      child: Consumer2<ThemeProvider, SnowEffectProvider>(
        builder: (context, themeProvider, snowProvider, child) {
          return MaterialApp.router(
            locale: Provider.of<RecipeProvider>(context, listen: true)
                .currentLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: widget.supportedLocales,
            routerConfig: widget.appRouter.config(),
            builder: (context, router) => Stack(
              children: [
                router!,
                GlobalSnowOverlay(isSnowing: snowProvider.isSnowing),
              ],
            ),
            debugShowCheckedModeBanner: false,
            title: 'Timer.Coffee',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
          );
        },
      ),
    );
  }
}

class PurchaseHandler {
  static void deliverProduct(
      BuildContext context, PurchaseDetails purchaseDetails) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.donationok),
          content: Text(AppLocalizations.of(context)!.donationtnx),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static void handleError(BuildContext context, IAPError error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.donationerr),
          content: Text(AppLocalizations.of(context)!.donationerrmsg),
          actions: [
            TextButton(
              child: const Text("OK"),
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
