import 'dart:io';
import 'dart:async';

import 'package:coffee_timer/models/contributor_model.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/recipe_provider.dart';
import '../providers/theme_provider.dart';
import '../models/brewing_method_model.dart'; // Added import
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../providers/snow_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_settings/app_settings.dart';
import 'package:coffee_timer/services/notification_service.dart';
import 'package:flutter_dynamic_icon_plus/flutter_dynamic_icon_plus.dart';
import 'package:flutter/services.dart';
import '../utils/app_logger.dart'; // Import AppLogger

@RoutePage()
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isAnonymous = true;
  String? _userId;

  String? _currentIconName; //  ← NEW
  bool _iconApiAvailable = false; //  ← NEW
  String? _localIconState; // ← NEW: Local state tracking

  // Notifications state
  bool _masterNotificationsEnabled =
      true; // User's explicit setting from SharedPreferences
  bool _notificationsEnabled = true; // Effective state (master && permission)
  bool _systemPermissionDenied = false;
  bool _isLoading = true;

  final NotificationService _notificationService = NotificationService.instance;
  StreamSubscription<bool>? _notifStateSub;
  StreamSubscription<bool>? _permSub;

  bool get _isDefault =>
      _localIconState == null || _localIconState == 'Default';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initIconApi(); //  ← NEW
    _initNotificationSettings();
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      _isAnonymous = user?.isAnonymous ?? true;
      _userId = user?.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final snowEffectProvider = Provider.of<SnowEffectProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          identifier: 'settingsBackButton',
          child: const BackButton(),
        ),
        title: Semantics(
          identifier: 'settingsTitle',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.settings),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.settings),
            ],
          ),
        ),
      ),
      body: ListView(
        children: [
          Semantics(
            identifier: 'settingsThemeTile',
            child: ListTile(
              title: Text(AppLocalizations.of(context)!.settingstheme),
              trailing: Text(_getLocalizedThemeModeText()),
              onTap: _changeTheme,
            ),
          ),
          Semantics(
            identifier: 'settingsLangTile',
            child: ListTile(
              title: Text(AppLocalizations.of(context)!.settingslang),
              trailing: FutureBuilder<String>(
                future: _getLanguageName(recipeProvider.currentLocale),
                builder:
                    (BuildContext context, AsyncSnapshot<String> snapshot) {
                  if (snapshot.hasData) {
                    return Text(snapshot.data!);
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
              onTap: _changeLocale,
            ),
          ),
          // Notification master toggle
          if (!kIsWeb)
            Semantics(
              identifier: 'settingsNotificationsTile',
              child: ListTile(
                title: Text(AppLocalizations.of(context)!.notifications),
                trailing: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_getNotificationStatusText()),
                onTap: _changeNotificationSettings,
              ),
            ),
          if (!kIsWeb &&
              (Platform.isAndroid || Platform.isIOS) &&
              _iconApiAvailable)
            _buildIconSelector(context),
          _buildBrewingMethodsSettings(
              context, recipeProvider), // Added section
          /* Commented out - Notification debug screen link
          Semantics(
            identifier: 'notificationDebugTile',
            child: ListTile(
              leading: const Icon(Icons.bug_report),
              title: Text(AppLocalizations.of(context)!.notificationDebug),
              subtitle:
                  Text(AppLocalizations.of(context)!.testNotificationSystem),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.router.push(NotificationDebugRoute()),
            ),
          ),
          */
          _buildAboutSection(context, snowEffectProvider),
        ],
      ),
    );
  }

  Widget _buildBrewingMethodsSettings(
      BuildContext context, RecipeProvider recipeProvider) {
    final allBrewingMethods =
        Provider.of<List<BrewingMethodModel>>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    final methodsWithRecipes = <String>{};
    for (var recipe in recipeProvider.recipes) {
      methodsWithRecipes.add(recipe.brewingMethodId);
    }

    final shownIds = recipeProvider.shownBrewingMethodIds.value;
    final hiddenIds = recipeProvider.hiddenBrewingMethodIds.value;

    return Semantics(
      identifier: 'brewingMethodsSettingsExpansionTile',
      child: ExpansionTile(
        title: Text(l10n.settingsBrewingMethodsTitle), // Needs localization
        children: allBrewingMethods.map((method) {
          bool hasRecipes = methodsWithRecipes.contains(method.brewingMethodId);
          bool isShownByUser = shownIds.contains(method.brewingMethodId);
          bool isHiddenByUser = hiddenIds.contains(method.brewingMethodId);

          bool switchValue;
          if (isShownByUser) {
            switchValue = true;
          } else if (isHiddenByUser) {
            switchValue = false;
          } else {
            switchValue = hasRecipes;
          }

          return SwitchListTile(
            title: Text(method.brewingMethod),
            value: switchValue,
            onChanged: (bool value) {
              recipeProvider.setUserBrewingMethodPreference(
                  method.brewingMethodId, value);
              // The RecipeProvider will notifyListeners, which should rebuild this part of the UI
              // if SettingsScreen is listening or if a ValueListenableBuilder is used for shown/hidden IDs.
              // For simplicity, we rely on the provider's notifyListeners.
            },
          );
        }).toList(),
      ),
    );
  }

  // Native method channel for icon handling
  static const MethodChannel _iconChannel =
      MethodChannel('com.coffee.timer/icon');

  // NEW: Icon API initialization
  Future<void> _initIconApi() async {
    try {
      // Check if we're on Android and use native method, otherwise use plugin
      if (Platform.isAndroid) {
        final current = await _iconChannel.invokeMethod('getCurrentIcon');
        AppLogger.debug('Native getCurrentIcon returned: $current');

        if (mounted) {
          setState(() {
            _iconApiAvailable = true;
            _currentIconName = current;
            _localIconState = current;
          });
        }
      } else {
        // iOS - use plugin
        final supported = await FlutterDynamicIconPlus.supportsAlternateIcons;
        final current =
            supported ? await FlutterDynamicIconPlus.alternateIconName : null;

        AppLogger.debug(
            'iOS - Icon API supported: $supported, current icon: $current');

        if (mounted) {
          setState(() {
            _iconApiAvailable = supported;
            _currentIconName = current;
            _localIconState = current == null ? 'Default' : current;
          });
        }
      }
    } catch (e) {
      AppLogger.error('Icon API init error', errorObject: e);
      if (mounted) {
        setState(() {
          _iconApiAvailable = false;
        });
      }
    }
  }

  // NEW: Set icon
  Future<void> _setIcon(String? iconName) async {
    if (!_iconApiAvailable) return;

    try {
      AppLogger.debug(
          '==================== ICON CHANGE START ====================');
      AppLogger.debug('Current state before change: $_localIconState');
      AppLogger.debug('Requested icon change to: $iconName');

      bool success = false;

      if (Platform.isAndroid) {
        // Use native method for Android
        AppLogger.debug('Using native method for Android');
        success =
            await _iconChannel.invokeMethod('setIcon', {'iconName': iconName});
        AppLogger.debug('Native setIcon returned: $success');
      } else {
        // Use plugin for iOS
        AppLogger.debug('Using plugin for iOS');
        final actualIconName = iconName == 'Default' ? null : iconName;
        await FlutterDynamicIconPlus.setAlternateIconName(
            iconName: actualIconName);
        success = true;
        AppLogger.debug('Plugin setIcon completed');
      }

      if (success) {
        // Update local state
        if (mounted) {
          setState(() {
            _localIconState = iconName;
          });
        }

        AppLogger.debug('Local state updated to: $iconName');
        AppLogger.debug(
            '==================== ICON CHANGE END ====================');
      } else {
        throw Exception('Icon change failed');
      }
    } catch (e) {
      AppLogger.error('Icon change error', errorObject: e);
      AppLogger.debug('Error type: ${e.runtimeType}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Icon change failed: $e')),
      );
    }
  }

  // NEW: Icon selector widget
  Widget _buildIconSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    Image _preview(String asset) =>
        Image.asset(asset, width: 40, height: 40, fit: BoxFit.contain);

    // ── default icon preview ──
    final defaultAsset = Platform.isIOS && isDark
        ? 'assets/icons/timer-coffee-icon-new-dark.png'
        : 'assets/icons/timer-coffee-icon-new-light.png';

    // ── legacy icon preview  (NEW: choose dark variant on iOS Dark Mode) ──
    final legacyAsset = Platform.isIOS && isDark
        ? 'assets/icons/ic_launcher_legacy_dark.png'
        : 'assets/icons/ic_launcher_legacy.png';

    return ExpansionTile(
      title: Text(l10n.settingsAppIcon), // your new localisation
      children: [
        ListTile(
          leading: _preview(defaultAsset),
          title: Text(l10n.settingsAppIconDefault),
          trailing: _isDefault ? const Icon(Icons.check) : null,
          // Use 'Default' to match our .Default alias
          onTap: () => _setIcon('Default'),
        ),
        ListTile(
          leading: _preview(legacyAsset),
          title: Text(l10n.settingsAppIconLegacy),
          trailing:
              _localIconState == 'Legacy' ? const Icon(Icons.check) : null,
          onTap: () => _setIcon('Legacy'), // enable .Legacy alias
        ),
      ],
    );
  }

  Widget _buildAboutSection(
      BuildContext context, SnowEffectProvider snowEffectProvider) {
    return Semantics(
      identifier: 'aboutSection',
      child: Column(
        children: [
          // Account management moved to AccountScreen
          // No account management options in Settings anymore
        ],
      ),
    );
  }

  void _changeTheme() async {
    final result = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              Semantics(
                identifier: 'themeLightListTile',
                child: ListTile(
                  leading: const Icon(Icons.light_mode),
                  title: Text(AppLocalizations.of(context)!.settingsthemelight),
                  onTap: () => Navigator.pop(context, ThemeMode.light),
                ),
              ),
              Semantics(
                identifier: 'themeDarkListTile',
                child: ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: Text(AppLocalizations.of(context)!.settingsthemedark),
                  onTap: () => Navigator.pop(context, ThemeMode.dark),
                ),
              ),
              Semantics(
                identifier: 'themeSystemListTile',
                child: ListTile(
                  leading: const Icon(Icons.brightness_medium),
                  title:
                      Text(AppLocalizations.of(context)!.settingsthemesystem),
                  onTap: () => Navigator.pop(context, ThemeMode.system),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      Provider.of<ThemeProvider>(context, listen: false).setThemeMode(result);
    }
  }

  void _changeLocale() async {
    final supportedLocales =
        await Provider.of<RecipeProvider>(context, listen: false)
            .fetchAllSupportedLocales();

    final result = await showModalBottomSheet<Locale>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: supportedLocales.length,
            itemBuilder: (BuildContext context, int index) {
              final localeModel = supportedLocales[index];
              return Semantics(
                identifier: 'locale${localeModel.locale}ListTile',
                child: ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(localeModel.localeName),
                  onTap: () =>
                      Navigator.pop(context, Locale(localeModel.locale)),
                ),
              );
            },
          ),
        );
      },
    );

    if (result != null) {
      _setLocale(result);
    }
  }

  String _getLocalizedThemeModeText() {
    var themeMode =
        Provider.of<ThemeProvider>(context, listen: false).themeMode;
    switch (themeMode) {
      case ThemeMode.light:
        return AppLocalizations.of(context)!.settingsthemelight;
      case ThemeMode.dark:
        return AppLocalizations.of(context)!.settingsthemedark;
      case ThemeMode.system:
        return AppLocalizations.of(context)!.settingsthemesystem;
      default:
        return AppLocalizations.of(context)!.settingsthemesystem;
    }
  }

  Future<String> _getLanguageName(Locale locale) async {
    return Provider.of<RecipeProvider>(context, listen: false)
        .getLocaleName(locale.languageCode);
  }

  void _setLocale(Locale newLocale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', newLocale.languageCode);

    Provider.of<RecipeProvider>(context, listen: false).setLocale(newLocale);

    context.router.replace(const SettingsRoute());
  }

  // Removed Info-only helpers from Settings: (privacy policy, version, contributor rich text)
  // Account management functionality moved to AccountScreen

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: false, forceWebView: false);
    } else {
      throw 'Could not launch $url';
    }
  }

  // ===== Notifications integration =====

  Future<void> _initNotificationSettings() async {
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _notificationsEnabled = false;
          _systemPermissionDenied = false;
        });
      }
      return;
    }

    try {
      await _notificationService.initialize();

      // Get the master setting from SharedPreferences (user's explicit choice)
      final master = await _notificationService.settings.isMasterEnabled();
      // Check actual permission status on initialization
      final hasPermission =
          await _notificationService.permissions.hasNotificationPermission;

      if (mounted) {
        setState(() {
          _masterNotificationsEnabled =
              master; // Preserve user's explicit setting
          _notificationsEnabled = master && hasPermission; // Effective state
          _systemPermissionDenied = !hasPermission;
          _isLoading = false;
        });
      }

      // Subscribe to live updates
      _notifStateSub =
          _notificationService.notificationStateStream.listen((state) {
        if (!mounted) return;
        setState(() {
          _notificationsEnabled = state;
        });
      });

      _permSub =
          _notificationService.permissions.permissionChanges.listen((hasPerm) {
        if (!mounted) return;
        setState(() {
          _systemPermissionDenied = !hasPerm;
          if (!hasPerm && _notificationsEnabled) {
            _notificationsEnabled = false;
          }
        });
      });
    } catch (e) {
      AppLogger.error('Error initializing notification settings',
          errorObject: e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getNotificationStatusText() {
    if (_isLoading) return '';

    // Show master setting status, not effective state
    // This ensures the UI reflects what the user explicitly set
    return _masterNotificationsEnabled
        ? AppLocalizations.of(context)!.notificationsEnabled
        : AppLocalizations.of(context)!.notificationsDisabled;
  }

  void _changeNotificationSettings() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              Semantics(
                identifier: 'notificationEnabledListTile',
                child: ListTile(
                  leading: const Icon(Icons.notifications),
                  title:
                      Text(AppLocalizations.of(context)!.notificationsEnabled),
                  trailing: _masterNotificationsEnabled
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.pop(context, true),
                ),
              ),
              Semantics(
                identifier: 'notificationDisabledListTile',
                child: ListTile(
                  leading: const Icon(Icons.notifications_off),
                  title:
                      Text(AppLocalizations.of(context)!.notificationsDisabled),
                  trailing: !_masterNotificationsEnabled
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.pop(context, false),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      _toggleNotifications(result);
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    if (kIsWeb) return;

    try {
      if (enabled) {
        // Check if we already have permission
        final hasPerm =
            await _notificationService.permissions.hasNotificationPermission;

        if (!hasPerm) {
          // Request permission first, following pattern from notification_debug_screen.dart
          final granted = await _notificationService.requestPermissions();

          if (!granted) {
            // Permission denied, show settings dialog
            _showSettingsDialog();
            return;
          }
        }
      }

      await _notificationService.updateMasterToggle(
        enabled: enabled,
        userId: _userId,
      );

      if (mounted) {
        setState(() {
          _masterNotificationsEnabled = enabled; // Update master setting
          // Update effective state based on both master and current permission
          _notificationsEnabled = enabled && !_systemPermissionDenied;
        });
      }
    } catch (e) {
      AppLogger.error('Error toggling notifications', errorObject: e);
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(
              AppLocalizations.of(context)!.notificationsDisabledDialogTitle),
          content: Text(
              AppLocalizations.of(context)!.notificationsDisabledDialogContent),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
              ),
              child: Text(
                l10n.cancel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.openSettings,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _openNotificationSettings();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _openAppSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    } catch (e) {
      AppLogger.error('Error opening notification settings', errorObject: e);
      try {
        await AppSettings.openAppSettings();
      } catch (fallbackError) {
        AppLogger.error('Error opening generic app settings',
            errorObject: fallbackError);
      }
    }
  }

  Future<void> _openNotificationSettings() async {
    try {
      // Try to open notification-specific settings first
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    } catch (e) {
      AppLogger.error('Error opening notification settings', errorObject: e);
      try {
        // Fallback to general app settings
        await AppSettings.openAppSettings();
      } catch (fallbackError) {
        AppLogger.error('Error opening general app settings',
            errorObject: fallbackError);
      }
    }
  }

  @override
  void dispose() {
    _notifStateSub?.cancel();
    _permSub?.cancel();
    super.dispose();
  }
}
