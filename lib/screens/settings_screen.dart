import 'dart:io';

import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auto_route/auto_route.dart';
import 'package:app_settings/app_settings.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';

import '../app_router.gr.dart';
import '../controllers/settings_controller.dart';
import '../database/database.dart';
import '../models/brewing_method_model.dart';
import '../providers/recipe_provider.dart';
import '../providers/snow_provider.dart';
import '../providers/theme_provider.dart';
import '../services/notification_service.dart';
import '../services/onboarding_service.dart';
import '../utils/app_logger.dart';
import '../widgets/fields/time_field.dart';
import '../widgets/settings/index.dart';

@RoutePage()
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    Key? key,
    @QueryParam('section') this.section,
  }) : super(key: key);

  final String? section;

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsController _controller;

  final _notificationsKey = GlobalKey();
  final _brewingMethodsKey = GlobalKey();
  final _notificationsController = ExpansibleController();
  final _brewingMethodsController = ExpansibleController();

  @override
  void initState() {
    super.initState();
    _controller = SettingsController();
    _controller.loadUserData();
    _controller.initIconApi();
    _controller.initNotificationSettings();
    if (widget.section != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSection(widget.section!);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _notificationsController.dispose();
    _brewingMethodsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context);
    Provider.of<ThemeProvider>(context); // listen for theme changes
    final snowEffectProvider = Provider.of<SnowEffectProvider>(context);

    // Prepare brewing methods data
    final allBrewingMethods =
        Provider.of<List<BrewingMethodModel>>(context, listen: false);
    final methodsWithRecipes = <String>{};
    for (var recipe in recipeProvider.recipes) {
      methodsWithRecipes.add(recipe.brewingMethodId);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
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
              ThemeLocaleTiles(
                localizedThemeMode: _getLocalizedThemeModeText(),
                languageNameFuture:
                    _getLanguageName(recipeProvider.currentLocale),
                onThemeTap: _changeTheme,
                onLocaleTap: _changeLocale,
              ),
              const DateTimeFormatSection(),
              if (!kIsWeb)
                KeyedSubtree(
                  key: _notificationsKey,
                  child: NotificationsSection(
                    controller: _notificationsController,
                    isLoading: _controller.isLoading,
                    masterNotificationsEnabled:
                        _controller.masterNotificationsEnabled,
                    systemPermissionDenied: _controller.systemPermissionDenied,
                    statusText: _getNotificationStatusText(),
                    onMasterToggled: _handleToggleNotifications,
                    onOpenNotificationSettings: _openNotificationSettings,
                    notificationToggles:
                        _controller.masterNotificationsEnabled &&
                                !_controller.isLoading
                            ? _buildNotificationToggles(context)
                            : [],
                  ),
                ),
              if (!kIsWeb &&
                  (Platform.isAndroid || Platform.isIOS) &&
                  _controller.iconApiAvailable)
                AppIconSelector(
                  isDefaultIcon: _controller.isDefaultIcon,
                  localIconState: _controller.localIconState,
                  onIconSelected: _handleIconSelected,
                ),
              KeyedSubtree(
                key: _brewingMethodsKey,
                child: BrewingMethodsSection(
                  controller: _brewingMethodsController,
                  allBrewingMethods: allBrewingMethods,
                  methodsWithRecipes: methodsWithRecipes,
                  shownIds: recipeProvider.shownBrewingMethodIds.value,
                  hiddenIds: recipeProvider.hiddenBrewingMethodIds.value,
                  onPreferenceChanged: (methodId, value) {
                    recipeProvider.setUserBrewingMethodPreference(
                        methodId, value);
                  },
                ),
              ),
              const CollectionsSection(),
              const AnalyticsPrivacySection(),
              const AdvancedFeaturesSection(),
              _buildAboutSection(context, snowEffectProvider),
              if (SettingsController.showNotifDebugPanel && !kIsWeb)
                const DebugNotificationPanel(),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Section deep-link scroll/expand
  // ---------------------------------------------------------------------------

  void _scrollToSection(String section) {
    GlobalKey? key;
    switch (section) {
      case 'notifications':
        if (!kIsWeb) {
          _notificationsController.expand();
          key = _notificationsKey;
        }
        break;
      case 'brewingMethods':
        _brewingMethodsController.expand();
        key = _brewingMethodsKey;
        break;
    }
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // About (placeholder — empty section)
  // ---------------------------------------------------------------------------

  Widget _buildAboutSection(
      BuildContext context, SnowEffectProvider snowEffectProvider) {
    return Semantics(
      identifier: 'aboutSection',
      child: Column(
        children: [],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Theme / Locale (bottom sheet dialogs require BuildContext)
  // ---------------------------------------------------------------------------

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
                  title:
                      Text(AppLocalizations.of(context)!.settingsthemelight),
                  onTap: () => Navigator.pop(context, ThemeMode.light),
                ),
              ),
              Semantics(
                identifier: 'themeDarkListTile',
                child: ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title:
                      Text(AppLocalizations.of(context)!.settingsthemedark),
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

    context.router.replace(SettingsRoute());
  }

  // ---------------------------------------------------------------------------
  // Icon handler
  // ---------------------------------------------------------------------------

  Future<void> _handleIconSelected(String iconName) async {
    final success = await _controller.setIcon(iconName);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Icon change failed: $iconName')),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Notifications (dialog/snackbar logic stays in screen)
  // ---------------------------------------------------------------------------

  String _getNotificationStatusText() {
    if (_controller.isLoading) return '';
    return _controller.masterNotificationsEnabled
        ? AppLocalizations.of(context)!.notificationsEnabled
        : AppLocalizations.of(context)!.notificationsDisabled;
  }

  Future<void> _handleToggleNotifications(bool enabled) async {
    final result = await _controller.toggleNotifications(enabled);
    if (result == ToggleNotificationResult.permissionDenied && mounted) {
      _showSettingsDialog();
    }
  }

  List<Widget> _buildNotificationToggles(BuildContext context) {
    final notificationService = NotificationService.instance;

    return NotificationToggles(
      morningReminderEnabled: _controller.morningReminderEnabled,
      morningReminderTime: _controller.morningReminderTime,
      weeklySummaryEnabled: _controller.weeklySummaryEnabled,
      beanFreshnessEnabled: _controller.beanFreshnessEnabled,
      onMorningChanged: (value) => _onOptionalToggleChanged(
        value,
        notificationService.settings.setMorningReminderEnabled,
      ),
      onWeeklyChanged: (value) => _onOptionalToggleChanged(
        value,
        notificationService.settings.setWeeklySummaryEnabled,
      ),
      onBeanFreshnessChanged: (value) => _onOptionalToggleChanged(
        value,
        notificationService.settings.setBeanFreshnessEnabled,
      ),
      onPickMorningTime: _pickMorningReminderTime,
    ).buildToggles(context);
  }

  Future<void> _pickMorningReminderTime() async {
    final picked = await showAppTimePicker(
      context: context,
      initialTime: _controller.morningReminderTime,
    );
    if (picked == null || !mounted) return;
    final database = Provider.of<AppDatabase>(context, listen: false);
    final onboarding = Provider.of<OnboardingService>(context, listen: false);
    final locale = Localizations.localeOf(context).languageCode;
    await _controller.updateMorningReminderTime(
      picked,
      database: database,
      onboarding: onboarding,
      locale: locale,
    );
  }

  Future<void> _onOptionalToggleChanged(
    bool value,
    Future<void> Function(bool) setter,
  ) async {
    final database = Provider.of<AppDatabase>(context, listen: false);
    final onboarding = Provider.of<OnboardingService>(context, listen: false);
    final locale = Localizations.localeOf(context).languageCode;
    await _controller.onOptionalToggleChanged(
      value,
      setter,
      database: database,
      onboarding: onboarding,
      locale: locale,
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.notificationsDisabledDialogTitle),
          content: Text(l10n.notificationsDisabledDialogContent),
          actions: [
            AppTextButton(
              label: l10n.cancel,
              onPressed: () => Navigator.of(context).pop(),
              isFullWidth: false,
              height: AppButton.heightMedium,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            AppElevatedButton(
              label: l10n.openSettings,
              onPressed: () async {
                Navigator.of(context).pop();
                await _openNotificationSettings();
              },
              isFullWidth: false,
              height: AppButton.heightMedium,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ],
        );
      },
    );
  }

  Future<void> _openNotificationSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    } catch (e) {
      AppLogger.error('Error opening notification settings', errorObject: e);
      try {
        await AppSettings.openAppSettings();
      } catch (fallbackError) {
        AppLogger.error('Error opening general app settings',
            errorObject: fallbackError);
      }
    }
  }
}
