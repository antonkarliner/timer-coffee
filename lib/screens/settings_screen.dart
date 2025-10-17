import 'dart:io';

import 'package:coffee_timer/models/contributor_model.dart';
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
import 'package:flutter_dynamic_icon_plus/flutter_dynamic_icon_plus.dart';
import 'package:flutter/services.dart';

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

  bool get _isDefault =>
      _localIconState == null || _localIconState == 'Default';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initIconApi(); //  ← NEW
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
          if (!kIsWeb &&
              (Platform.isAndroid || Platform.isIOS) &&
              _iconApiAvailable)
            _buildIconSelector(context),
          _buildBrewingMethodsSettings(
              context, recipeProvider), // Added section
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
        print('DEBUG: Native getCurrentIcon returned: $current');

        if (mounted) {
          setState(() {
            _iconApiAvailable = true;
            _currentIconName = current;
            _localIconState = current;
          });
        }
      } else {
        // iOS - use the plugin
        final supported = await FlutterDynamicIconPlus.supportsAlternateIcons;
        final current =
            supported ? await FlutterDynamicIconPlus.alternateIconName : null;

        print(
            'DEBUG: iOS - Icon API supported: $supported, current icon: $current');

        if (mounted) {
          setState(() {
            _iconApiAvailable = supported;
            _currentIconName = current;
            _localIconState = current == null ? 'Default' : current;
          });
        }
      }
    } catch (e) {
      print('DEBUG: Icon API init error: $e');
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
      print(
          'DEBUG: ==================== ICON CHANGE START ====================');
      print('DEBUG: Current state before change: $_localIconState');
      print('DEBUG: Requested icon change to: $iconName');

      bool success = false;

      if (Platform.isAndroid) {
        // Use native method for Android
        print('DEBUG: Using native method for Android');
        success =
            await _iconChannel.invokeMethod('setIcon', {'iconName': iconName});
        print('DEBUG: Native setIcon returned: $success');
      } else {
        // Use plugin for iOS
        print('DEBUG: Using plugin for iOS');
        final actualIconName = iconName == 'Default' ? null : iconName;
        await FlutterDynamicIconPlus.setAlternateIconName(
            iconName: actualIconName);
        success = true;
        print('DEBUG: Plugin setIcon completed');
      }

      if (success) {
        // Update local state
        if (mounted) {
          setState(() {
            _localIconState = iconName;
          });
        }

        print('DEBUG: Local state updated to: $iconName');
        print(
            'DEBUG: ==================== ICON CHANGE END ====================');
      } else {
        throw Exception('Icon change failed');
      }
    } catch (e) {
      print('DEBUG: Icon change error: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
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
    await prefs.setString('locale', newLocale.toString());

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
}
