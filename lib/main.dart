import 'dart:async';
import 'dart:io';
import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/env/env.dart';
import 'package:coffee_timer/models/supported_locale_model.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/purchase_manager.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show SystemChrome, SystemUiMode, SystemUiOverlay;
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
import 'package:coffee_timer/services/notification_migration_service.dart';
import 'services/feature_flags/feature_flags_repository.dart';
import 'package:url_launcher/url_launcher.dart';

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

/// Top-level function to launch external URLs with delayed execution
/// This is used by _checkPendingUrlLaunch during app initialization
Future<void> _launchExternalUrlTopLevel(Uri uri) async {
  try {
    // Enhanced logging for URL launch process
    AppLogger.debug('Starting external URL launch process (top-level): $uri');
    AppLogger.debug('Current platform: ${defaultTargetPlatform}');
    AppLogger.debug('App state: ${WidgetsBinding.instance.lifecycleState}');

    // Ensure the app is fully initialized before launching URL
    // This is critical for reliability when app is launched from terminated state
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        AppLogger.debug('App frame ready, proceeding with URL launch: $uri');

        // Use platform-appropriate launch modes
        final launchModes = _getLaunchModesForPlatform();
        AppLogger.debug('Available launch modes for platform: $launchModes');

        // Track launch attempts for better debugging
        int attemptNumber = 0;
        final totalAttempts = launchModes.length + 1; // +1 for default mode

        for (final mode in launchModes) {
          attemptNumber++;
          try {
            AppLogger.debug(
                'Launch attempt $attemptNumber/$totalAttempts: mode=$mode, uri=$uri');
            final launched = await launchUrl(uri, mode: mode);
            if (launched) {
              AppLogger.debug(
                  'Successfully launched external URL: $uri in mode: $mode (attempt $attemptNumber/$totalAttempts)');
              return;
            } else {
              AppLogger.warning(
                  'URL launch returned false in mode $mode: $uri (attempt $attemptNumber/$totalAttempts)');
            }
          } catch (e) {
            AppLogger.warning(
              'Failed to launch URL in $mode: $uri (attempt $attemptNumber/$totalAttempts)',
              errorObject: e,
            );
          }
        }

        // If all launch modes failed, try the default mode
        attemptNumber++;
        AppLogger.debug(
            'Final attempt $attemptNumber/$totalAttempts: trying default launch mode');
        final defaultLaunched = await launchUrl(uri);
        if (!defaultLaunched) {
          AppLogger.warning(
              'Failed to open external URL with all $totalAttempts launch modes: $uri');
        } else {
          AppLogger.debug(
              'Successfully launched external URL with default mode: $uri');
        }
      } catch (e) {
        AppLogger.error('Error during delayed URL launch: $uri',
            errorObject: e);
      }
    });
  } catch (e) {
    AppLogger.error('Error scheduling external URL launch: $uri',
        errorObject: e);
  }
}

Future<void> _checkPendingUrlLaunch(SharedPreferences prefs) async {
  try {
    AppLogger.debug(
        'Checking for pending external URL launch (iOS terminated state recovery)');

    final pendingUrl = prefs.getString('pending_external_url');
    if (pendingUrl != null && pendingUrl.isNotEmpty) {
      AppLogger.debug(
          'Found pending external URL from iOS terminated state: $pendingUrl');
      AppLogger.debug(
          'Attempting to launch pending URL during app initialization');

      final uri = Uri.tryParse(pendingUrl);
      if (uri != null) {
        try {
          AppLogger.debug('Pending URL parsed successfully: $uri');

          // Use the top-level URL launch function which handles delayed execution
          await _launchExternalUrlTopLevel(uri);

          // Clean up after successful launch attempt
          AppLogger.debug('Cleaning up pending URL after launch attempt');
          await prefs.remove('pending_external_url');
        } catch (e) {
          AppLogger.error(
              'Error launching pending external URL during app init: $uri',
              errorObject: e);
          // Clean up even if launch failed to prevent retry loops
          await prefs.remove('pending_external_url');
        }
      } else {
        AppLogger.warning(
            'Pending URL failed to parse, cleaning up: $pendingUrl');
        await prefs.remove('pending_external_url');
      }
    } else {
      AppLogger.debug('No pending external URL found (normal app launch)');
    }
  } catch (e) {
    AppLogger.error(
        'Error checking pending URL launch during app initialization',
        errorObject: e);
  }
}

List<LaunchMode> _getLaunchModesForPlatform() {
  if (kIsWeb) {
    return const [LaunchMode.platformDefault];
  } else if (defaultTargetPlatform == TargetPlatform.android) {
    // Android: prefer external browser, fallback to in-app browser
    return const [
      LaunchMode.externalApplication,
      LaunchMode.externalNonBrowserApplication,
      LaunchMode.inAppBrowserView,
      LaunchMode.inAppWebView,
    ];
  } else if (defaultTargetPlatform == TargetPlatform.iOS) {
    // iOS: prefer external browser, fallback to SFSafariViewController
    return const [
      LaunchMode.externalApplication,
      LaunchMode.inAppBrowserView,
    ];
  } else {
    // Desktop and other platforms
    return const [LaunchMode.externalApplication];
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
    // Use silent initialization to prevent iOS system dialogs on first startup
    try {
      await NotificationService.instance.initialize(silentInit: true).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          AppLogger.warning('NotificationService initialization timed out');
          // Continue app startup even if notifications fail
        },
      );
      AppLogger.debug(
          'NotificationService initialized successfully (silent mode)');
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

  // Check for pending external URL launch (iOS terminated state fix)
  await _checkPendingUrlLaunch(prefs);

  bool isFirstLaunch = prefs.getBool('firstLaunched') ?? true;
  bool hasPerformedUuidBackfill =
      prefs.getBool('hasPerformedUuidBackfill') ?? false;

  // Determine platform/build for feature flags
  final packageInfo = await PackageInfo.fromPlatform();
  final buildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
  final platform = kIsWeb
      ? 'web'
      : Platform.isIOS
          ? 'ios'
          : 'android';

  final featureFlagsRepository = FeatureFlagsRepository(
    remote: SupabaseFeatureFlagsDataSource(Supabase.instance.client),
    local: LocalFeatureFlagsStore(prefs),
    platform: platform,
    buildNumber: buildNumber,
    fetchTimeout: const Duration(seconds: 3),
  );
  // Kick off refresh but don't block startup
  unawaited(featureFlagsRepository.refresh());

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

  // Perform notification migration if needed
  try {
    await NotificationMigrationService.instance.performMigrationIfNeeded();
  } catch (e) {
    AppLogger.error('Error during notification migration', errorObject: e);
    // Continue app startup even if migration fails
  }

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
      featureFlagsRepository: featureFlagsRepository,
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
  final FeatureFlagsRepository featureFlagsRepository;

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
    required this.featureFlagsRepository,
  }) : super(key: key);

  @override
  _CoffeeTimerAppState createState() => _CoffeeTimerAppState();
}

class _CoffeeTimerAppState extends State<CoffeeTimerApp> {
  StreamSubscription<String?>? _notificationTapSubscription;

  @override
  void initState() {
    super.initState();
    _setupNotificationTapHandler();
  }

  @override
  void dispose() {
    _notificationTapSubscription?.cancel();
    widget.featureFlagsRepository.dispose();
    super.dispose();
  }

  void _setupNotificationTapHandler() {
    _notificationTapSubscription =
        NotificationService.instance.onNotificationTapped.listen((payload) {
      final deepLink = payload?.trim();
      if (deepLink == null || deepLink.isEmpty) return;

      // Ensure router is attached before navigating/launching.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_handleNotificationDeepLink(deepLink));
      });
    });
  }

  Future<void> _handleNotificationDeepLink(String deepLink) async {
    try {
      AppLogger.info('🔔 NOTIFICATION TAP: Starting deep link handling');
      AppLogger.debug('Raw deep_link: $deepLink');

      // NEW: Enhanced logging for link processing
      final uri = Uri.tryParse(deepLink);
      final isExternalUrl = uri != null &&
          uri.isAbsolute &&
          (uri.scheme.toLowerCase() == 'https' ||
              uri.scheme.toLowerCase() == 'http') &&
          uri.host.isNotEmpty;

      AppLogger.debug(
          'Link processing details - deepLink: $deepLink, isExternalUrl: $isExternalUrl, uriScheme: ${uri?.scheme}, uriHost: ${uri?.host}');

      // Prioritize external URLs - open in browser immediately
      if (isExternalUrl) {
        AppLogger.info(
            '🌐 EXTERNAL URL: Detected external URL, launching browser: $deepLink');
        AppLogger.info('🌐 EXTERNAL URL: Platform: ${defaultTargetPlatform}');
        await _launchExternalUrl(uri!);
        return;
      }

      // Handle internal routes (starting with /)
      if (deepLink.startsWith('/')) {
        AppLogger.info('📱 INTERNAL ROUTE: Navigating to: $deepLink');
        await _navigateToRoute(deepLink);
        return;
      }

      // Handle app deep links (timercoffee:// or app://)
      if (uri != null) {
        final scheme = uri.scheme.toLowerCase();
        if (scheme == 'timercoffee' || scheme == 'app') {
          final routePath = _routePathFromAppDeepLink(uri);
          if (routePath != null) {
            AppLogger.info('📱 APP DEEP LINK: Navigating to: $routePath');
            await _navigateToRoute(routePath);
            return;
          } else {
            AppLogger.warning(
                '📱 APP DEEP LINK: Could not extract route from: $deepLink');
          }
        } else {
          AppLogger.debug('Unknown scheme: $scheme for deep_link: $deepLink');
        }
      }

      AppLogger.warning(
          '⚠️ UNSUPPORTED LINK: Ignoring unsupported deep_link: $deepLink');
    } catch (e, stackTrace) {
      AppLogger.error(
          '❌ ERROR: Error handling notification deep_link: $deepLink',
          errorObject: e,
          stackTrace: stackTrace);
    }
  }

  Future<void> _launchExternalUrl(Uri uri) async {
    try {
      // Enhanced logging for URL launch process
      AppLogger.info('🚀 URL LAUNCH: Starting external URL launch process');
      AppLogger.info('🚀 URL LAUNCH: URI: $uri');
      AppLogger.info('🚀 URL LAUNCH: Platform: ${defaultTargetPlatform}');
      AppLogger.info(
          '🚀 URL LAUNCH: App state: ${WidgetsBinding.instance.lifecycleState}');

      // Ensure the app is fully initialized before launching URL
      // This is critical for reliability when app is launched from terminated state
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          AppLogger.info(
              '🚀 URL LAUNCH: App frame ready, proceeding with URL launch: $uri');

          // Use platform-appropriate launch modes
          final launchModes = _getLaunchModesForPlatform();
          AppLogger.info(
              '🚀 URL LAUNCH: Available launch modes for platform: $launchModes');

          // Track launch attempts for better debugging
          int attemptNumber = 0;
          final totalAttempts = launchModes.length + 1; // +1 for default mode

          for (final mode in launchModes) {
            attemptNumber++;
            try {
              AppLogger.info(
                  '🚀 URL LAUNCH: Attempt $attemptNumber/$totalAttempts: mode=$mode, uri=$uri');
              final launched = await launchUrl(uri, mode: mode);
              if (launched) {
                AppLogger.info(
                    '✅ URL LAUNCH SUCCESS: Launched $uri in mode: $mode (attempt $attemptNumber/$totalAttempts)');
                return;
              } else {
                AppLogger.warning(
                    '⚠️ URL LAUNCH FAILED: Launch returned false in mode $mode: $uri (attempt $attemptNumber/$totalAttempts)');
              }
            } catch (e, stackTrace) {
              AppLogger.warning(
                '❌ URL LAUNCH ERROR: Failed in $mode: $uri (attempt $attemptNumber/$totalAttempts)',
                errorObject: e,
                stackTrace: stackTrace,
              );
            }
          }

          // If all launch modes failed, try the default mode
          attemptNumber++;
          AppLogger.info(
              '🚀 URL LAUNCH: Final attempt $attemptNumber/$totalAttempts: trying default launch mode');
          final defaultLaunched = await launchUrl(uri);
          if (!defaultLaunched) {
            AppLogger.error(
                '❌ URL LAUNCH FAILED: All $totalAttempts launch modes failed for: $uri');
            // Show error to user or fallback to internal handling
            _showUrlLaunchError(uri);
          } else {
            AppLogger.info(
                '✅ URL LAUNCH SUCCESS: Launched with default mode: $uri');
          }
        } catch (e, stackTrace) {
          AppLogger.error(
              '❌ URL LAUNCH ERROR: Error during delayed URL launch: $uri',
              errorObject: e,
              stackTrace: stackTrace);
          _showUrlLaunchError(uri);
        }
      });
    } catch (e, stackTrace) {
      AppLogger.error(
          '❌ URL LAUNCH ERROR: Error scheduling external URL launch: $uri',
          errorObject: e,
          stackTrace: stackTrace);
      _showUrlLaunchError(uri);
    }
  }

  List<LaunchMode> _getLaunchModesForPlatform() {
    if (kIsWeb) {
      return const [LaunchMode.platformDefault];
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android: prefer external browser, fallback to in-app browser
      return const [
        LaunchMode.externalApplication,
        LaunchMode.externalNonBrowserApplication,
        LaunchMode.inAppBrowserView,
        LaunchMode.inAppWebView,
      ];
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS: prefer external browser, fallback to SFSafariViewController
      return const [
        LaunchMode.externalApplication,
        LaunchMode.inAppBrowserView,
      ];
    } else {
      // Desktop and other platforms
      return const [LaunchMode.externalApplication];
    }
  }

  void _showUrlLaunchError(Uri uri) {
    // This could show a snackbar or dialog to the user
    // indicating that the URL couldn't be opened
    AppLogger.warning(
        'Failed to launch URL: $uri - consider showing user feedback');
  }

  String? _routePathFromAppDeepLink(Uri uri) {
    final String routePath;
    if (uri.host.isNotEmpty) {
      routePath = '/${uri.host}${uri.path}';
    } else {
      routePath = uri.path;
    }

    if (routePath.isEmpty || routePath == '/') return null;

    final normalized = routePath.startsWith('/') ? routePath : '/$routePath';
    return uri.hasQuery ? '$normalized?${uri.query}' : normalized;
  }

  Future<void> _navigateToRoute(String routePath) async {
    try {
      await widget.appRouter.pushNamed(routePath);
    } catch (e) {
      AppLogger.warning('Failed to navigate to deep_link route: $routePath');
    }
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
        Provider<FeatureFlagsRepository>.value(
            value: widget.featureFlagsRepository),
        StreamProvider<Map<String, bool>>(
          create: (_) => widget.featureFlagsRepository.stream,
          initialData: widget.featureFlagsRepository.currentFlags,
        ),
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
