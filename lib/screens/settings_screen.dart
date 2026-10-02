import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:coffeico_plus/coffeico_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_router.gr.dart';
import '../controllers/settings_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/brewing_method_model.dart';
import '../models/notification_mode.dart';
import '../providers/recipe_provider.dart';
import '../providers/theme_provider.dart';
import '../services/analytics_service.dart';
import '../services/advanced_features_service.dart';
import '../services/brew_alert_preference.dart';
import '../services/date_time_format_service.dart';
import '../services/settings_analytics.dart';
import '../widgets/account/account_entry_tile.dart';
import '../widgets/settings/settings_list.dart';

/// Maps a legacy `?section=` deep-link value to the Settings category page
/// that now owns that section (`timercoffee:///settings?section=…`).
///
/// Returns null when there is no target — unknown values, and
/// `notifications` on web, where the notifications page has no content — so
/// the caller stays on the root and reports nothing.
@visibleForTesting
SettingsTarget? settingsTargetForLegacySection(
  String section, {
  required bool isWeb,
}) {
  switch (section) {
    case 'notifications':
      return isWeb ? null : SettingsTarget.notifications;
    case 'brewingMethods':
      return SettingsTarget.homeScreen;
    case 'advancedFeatures':
    case 'immersiveBrewing':
      // The layout row is the first row of the brewing page, so the old
      // scroll-to-tile behaviour needs no replacement.
      return SettingsTarget.brewing;
    default:
      return null;
  }
}

/// Subtitle (and whether it renders in the error colour) for the
/// notifications row on the Settings root.
///
/// `@visibleForTesting` because the row's controller always takes its catch
/// path under the test runner (`NotificationService.initialize()` cannot
/// run there), which leaves master-off and the blocked state unreachable in
/// a widget test — this pure function is the only way to pin the branch
/// mapping.
@visibleForTesting
({String? subtitle, bool isError}) notificationsRootSubtitle({
  required bool isLoading,
  required bool systemPermissionDenied,
  required bool masterEnabled,
  required int enabledReminderCount,
  required AppLocalizations l10n,
}) {
  if (isLoading) return (subtitle: null, isError: false);
  if (systemPermissionDenied && masterEnabled) {
    return (subtitle: l10n.settingsNotificationsSummaryBlocked, isError: true);
  }
  if (!masterEnabled) {
    return (subtitle: l10n.settingsNotificationsSummaryOff, isError: false);
  }
  return (
    subtitle: l10n.settingsNotificationsSummaryOn(enabledReminderCount),
    isError: false,
  );
}

@RoutePage()
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, @QueryParam('section') this.section});

  final String? section;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Owns the notification and app-icon state behind two of the row
  /// subtitles. Its streams keep it current while a subpage changes values,
  /// so re-running `initNotificationSettings()` on return is not needed.
  late final SettingsController _controller;

  /// Locale code the cached language-name future was started for, so the
  /// future is re-resolved only when the locale actually changes.
  String? _languageNameFutureCode;
  Future<String>? _languageNameFuture;

  @override
  void initState() {
    super.initState();
    _controller = SettingsController();
    _controller.initIconApi();
    _controller.initNotificationSettings();
    // The brewing row renders the stored alert mode; the shared
    // ValueListenable keeps it live after this initial load too.
    BrewAlertPreference.instance.load();
    if (widget.section != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _forwardLegacySection();
      });
    }
  }

  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A `?section=` link opened while Settings is already on top reuses this
    // State instead of running initState again; forward that one too.
    if (widget.section != null && widget.section != oldWidget.section) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _forwardLegacySection();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Legacy ?section= forwarding
  // ---------------------------------------------------------------------------

  /// Pushes the page that now owns the legacy section on top of the root,
  /// reporting the shortcut once per screen instance. Runs post-frame from
  /// initState; guards `mounted` because the screen can be gone by then.
  void _forwardLegacySection() {
    final section = widget.section;
    if (section == null) return;
    final target = settingsTargetForLegacySection(section, isWeb: kIsWeb);
    if (target == null || !mounted) return;
    SettingsAnalytics.shortcutTapped(
      source: ShortcutSource.deepLink,
      target: target,
      section: section,
    );
    switch (target) {
      case SettingsTarget.notifications:
        unawaited(context.router.push(const SettingsNotificationsRoute()));
      case SettingsTarget.homeScreen:
        unawaited(context.router.push(const SettingsHomeTabRoute()));
      case SettingsTarget.brewing:
        unawaited(context.router.push(const SettingsBrewingRoute()));
      default:
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Every row subtitle reads one of these; watching them here is what makes
    // a subtitle refresh when the value changes on a subpage and the user
    // comes back (the providers notify, the root rebuilds).
    final recipeProvider = context.watch<RecipeProvider>();
    context.watch<ThemeProvider>(); // appearance row: theme label
    context.watch<AdvancedFeaturesService>(); // brewing row: layout label
    context.watch<AnalyticsService>(); // privacy row: analytics summary
    context.watch<DateTimeFormatService>(); // language row: date pattern
    final methods = Provider.of<List<BrewingMethodModel>>(context);

    return SettingsPageScaffold(
      title: l10n.settings,
      children: [
        // Two headerless sections (settings_list.dart rule 2): the account
        // card alone, then the six category rows.
        SettingsSection(
          children: [
            Semantics(
              identifier: 'settingsAccountCard',
              container: true,
              child: const AccountEntryTile(
                source: AccountEntrySource.settings,
                showChevron: true,
              ),
            ),
          ],
        ),
        SettingsSection(
          children: [
            _brewingRow(context, l10n),
            _homeScreenRow(context, l10n, recipeProvider, methods),
            _notificationsRowSlot(context, l10n),
            _appearanceRowSlot(context, l10n),
            _languageRegionRow(context, l10n, recipeProvider),
            _privacyDataRow(context, l10n),
          ],
        ),
      ],
    );
  }

  /// Brewing row. The layout half comes from the watched service; the alert
  /// half from the shared notifier, so a mode changed on the Preparation
  /// screen refreshes this subtitle too.
  Widget _brewingRow(BuildContext context, AppLocalizations l10n) {
    return ValueListenableBuilder<NotificationMode>(
      valueListenable: BrewAlertPreference.instance.mode,
      builder: (context, mode, _) => SettingsNavRow(
        identifier: 'settingsBrewingRow',
        // The same glyph the Brew Coffee tab uses (home_screen.dart).
        icon: Coffeico.coffee_maker,
        title: l10n.settingsBrewingTitle,
        subtitle: '${_layoutLabel(context, l10n)}${l10n.summarySeparator}'
            '${_alertLabel(l10n, mode)}',
        onTap: () => context.router.push(const SettingsBrewingRoute()),
      ),
    );
  }

  String _layoutLabel(BuildContext context, AppLocalizations l10n) {
    final advanced = Provider.of<AdvancedFeaturesService>(
      context,
      listen: false,
    );
    return advanced.pourLayoutEnabled
        ? l10n.layoutPickerImmersive
        : l10n.layoutPickerClassic;
  }

  String _alertLabel(AppLocalizations l10n, NotificationMode mode) {
    return switch (mode) {
      NotificationMode.none => l10n.settingsBrewAlertsSilent,
      NotificationMode.vibrationOnly => l10n.settingsBrewAlertsVibration,
      NotificationMode.soundOnly => l10n.settingsBrewAlertsSound,
    };
  }

  /// Home-screen row: how many brewing methods are shown on the Home tab.
  /// Nested ValueListenableBuilders so an explicit preference change made on
  /// the subpage refreshes the subtitle even without a provider notify.
  Widget _homeScreenRow(
    BuildContext context,
    AppLocalizations l10n,
    RecipeProvider recipeProvider,
    List<BrewingMethodModel> methods,
  ) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: recipeProvider.shownBrewingMethodIds,
      builder: (context, shownIds, _) {
        return ValueListenableBuilder<Set<String>>(
          valueListenable: recipeProvider.hiddenBrewingMethodIds,
          builder: (context, hiddenIds, _) {
            // Same rule as `SettingsHomeTabScreen._switchValue`
            // (lib/screens/settings/settings_home_tab_screen.dart): an
            // explicit user choice wins; without one, a method is shown
            // exactly when it has recipes. Kept local on purpose — keep the
            // two in sync.
            final methodsWithRecipes = <String>{
              for (final recipe in recipeProvider.recipes)
                recipe.brewingMethodId,
            };
            final shown = methods
                .where(
                  (method) =>
                      shownIds.contains(method.brewingMethodId) ||
                      (!hiddenIds.contains(method.brewingMethodId) &&
                          methodsWithRecipes.contains(method.brewingMethodId)),
                )
                .length;
            return SettingsNavRow(
              identifier: 'settingsHomeScreenRow',
              icon: Icons.home_outlined,
              title: l10n.settingsHomeScreenTitle,
              subtitle: l10n.settingsMethodsShownCount(shown, methods.length),
              onTap: () => context.router.push(const SettingsHomeTabRoute()),
            );
          },
        );
      },
    );
  }

  /// Notifications row in an always-present slot (settings_list.dart rule 5):
  /// on web the slot renders an empty box, on native the row renders with no
  /// subtitle while the controller loads — the widget type at this tree
  /// position only ever differs across platforms, never across states.
  Widget _notificationsRowSlot(BuildContext context, AppLocalizations l10n) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (kIsWeb) return const SizedBox.shrink();

        final (:subtitle, :isError) = notificationsRootSubtitle(
          isLoading: _controller.isLoading,
          systemPermissionDenied: _controller.systemPermissionDenied,
          masterEnabled: _controller.masterNotificationsEnabled,
          enabledReminderCount: _controller.enabledReminderCount,
          l10n: l10n,
        );

        return SettingsNavRow(
          identifier: 'settingsNotificationsRow',
          icon: Icons.notifications_outlined,
          title: l10n.notifications,
          subtitle: subtitle,
          subtitleColor: isError ? Theme.of(context).colorScheme.error : null,
          onTap: () => context.router.push(const SettingsNotificationsRoute()),
        );
      },
    );
  }

  /// Appearance row in an always-present ListenableBuilder slot so the app
  /// icon suffix can appear once the icon API reports in without changing
  /// the tree shape.
  Widget _appearanceRowSlot(BuildContext context, AppLocalizations l10n) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final themeMode = Provider.of<ThemeProvider>(
          context,
          listen: false,
        ).themeMode;
        var subtitle = switch (themeMode) {
          ThemeMode.light => l10n.settingsthemelight,
          ThemeMode.dark => l10n.settingsthemedark,
          ThemeMode.system => l10n.settingsthemesystem,
        };
        if (!kIsWeb && _controller.iconApiAvailable) {
          subtitle = l10n.settingsAppearanceSummary(
            subtitle,
            _controller.isDefaultIcon
                ? l10n.settingsAppIconDefault
                : l10n.settingsAppIconLegacy,
          );
        }
        return SettingsNavRow(
          identifier: 'settingsAppearanceRow',
          icon: Icons.palette_outlined,
          title: l10n.settingsAppearanceTitle,
          subtitle: subtitle,
          onTap: () async {
            await context.router.push(const SettingsAppearanceRoute());
            // The Appearance page changes the icon through its own
            // controller, so re-read it here for this row's subtitle.
            if (mounted) unawaited(_controller.initIconApi());
          },
        );
      },
    );
  }

  /// Language & region row: "language · today". The language name is async
  /// (cached future, re-resolved only when the locale changes), so the date
  /// alone shows until it resolves.
  Widget _languageRegionRow(
    BuildContext context,
    AppLocalizations l10n,
    RecipeProvider recipeProvider,
  ) {
    final fmtService = Provider.of<DateTimeFormatService>(
      context,
      listen: false,
    );
    // The explicit locale matters: `Intl.defaultLocale` is never set in this
    // app, so without it the month names would stay English in every app
    // language.
    final today = DateFormat(
      fmtService.datePattern(l10n.dateFormat),
      Localizations.localeOf(context).toString(),
    ).format(DateTime.now());

    return FutureBuilder<String>(
      future: _languageName(recipeProvider),
      builder: (context, snapshot) {
        final languageName = snapshot.data;
        return SettingsNavRow(
          identifier: 'settingsLanguageRegionRow',
          icon: Icons.language,
          title: l10n.settingsLanguageRegionTitle,
          subtitle: languageName == null
              ? today
              : '$languageName${l10n.summarySeparator}$today',
          onTap: () => context.router.push(const SettingsLanguageRegionRoute()),
        );
      },
    );
  }

  Future<String> _languageName(RecipeProvider recipeProvider) {
    final code = recipeProvider.currentLocale.languageCode;
    if (_languageNameFutureCode != code) {
      _languageNameFutureCode = code;
      _languageNameFuture = recipeProvider.getLocaleName(code);
    }
    return _languageNameFuture!;
  }

  /// Privacy & data row: a one-line summary of the three usage-analytics
  /// switches.
  Widget _privacyDataRow(BuildContext context, AppLocalizations l10n) {
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    final allOn =
        analytics.brewsEnabled &&
        analytics.beansEnabled &&
        analytics.generalEnabled;
    final allOff =
        !analytics.brewsEnabled &&
        !analytics.beansEnabled &&
        !analytics.generalEnabled;
    return SettingsNavRow(
      identifier: 'settingsPrivacyDataRow',
      icon: Icons.shield_outlined,
      title: l10n.settingsPrivacyDataTitle,
      subtitle: allOn
          ? l10n.settingsAnalyticsSummaryOn
          : allOff
          ? l10n.settingsAnalyticsSummaryOff
          : l10n.settingsAnalyticsSummaryPartial,
      onTap: () => context.router.push(const SettingsPrivacyDataRoute()),
    );
  }
}
