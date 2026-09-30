import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/brewing_method_model.dart';
import '../../providers/recipe_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/collections_preferences_service.dart';
import '../../services/settings_analytics.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/app_switch_list_tile.dart';
import '../../widgets/base_buttons.dart';
import '../../widgets/settings/settings_list.dart';

/// Home-screen settings page (Settings → Home screen): the Collections
/// visibility switch and one visibility switch per brewing method, plus a
/// reset that falls back to "shown if the method has recipes".
///
/// Not yet linked from the root Settings screen; reachable by route/deep
/// link only.
@RoutePage()
class SettingsHomeTabScreen extends StatelessWidget {
  const SettingsHomeTabScreen({super.key});

  Future<void> _setCollectionsVisible(
    CollectionsPreferencesService prefs,
    bool visible,
  ) async {
    if (visible == !prefs.dismissed) {
      return;
    }
    AnalyticsService.maybeInstance?.track(
      'collections_visibility_changed',
      properties: {'visible': visible, 'source': 'settings_home_screen'},
    );
    await prefs.setDismissed(!visible);
  }

  /// Whether a method's Home switch is on: an explicit user choice wins;
  /// without one, a method is on exactly when it has recipes. The Settings
  /// root counts shown methods with the same rule — keep the two in sync.
  bool _switchValue(
    String methodId,
    Set<String> shownIds,
    Set<String> hiddenIds,
    Set<String> methodsWithRecipes,
  ) {
    if (shownIds.contains(methodId)) {
      return true;
    }
    if (hiddenIds.contains(methodId)) {
      return false;
    }
    return methodsWithRecipes.contains(methodId);
  }

  Future<void> _confirmReset(
    BuildContext context,
    RecipeProvider recipeProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          title: Text(dialogL10n.settingsResetToDefault),
          content: Text(dialogL10n.settingsResetBrewingMethodsConfirm),
          actions: [
            AppTextButton(
              label: dialogL10n.cancel,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              isFullWidth: false,
              height: AppButton.heightMedium,
              padding: AppButton.paddingMedium,
            ),
            AppElevatedButton(
              label: dialogL10n.settingsResetToDefault,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              isFullWidth: false,
              height: AppButton.heightMedium,
              padding: AppButton.paddingMedium,
              backgroundColor: Theme.of(dialogContext).colorScheme.primary,
              foregroundColor: Theme.of(dialogContext).colorScheme.onPrimary,
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    final changed = await recipeProvider.resetBrewingMethodPreferences();
    if (changed) {
      SettingsAnalytics.brewingMethodsReset(source: SettingSource.settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final methods = Provider.of<List<BrewingMethodModel>>(context);
    final recipeProvider = context.watch<RecipeProvider>();

    return SettingsPageScaffold(
      title: l10n.settingsHomeScreenTitle,
      children: [
        Consumer<CollectionsPreferencesService>(
          builder: (context, prefs, _) {
            return Semantics(
              identifier: 'settingsCollectionsSwitch',
              container: true,
              child: AppSwitchListTile(
                title: l10n.collectionsShowOnHomeTitle,
                subtitle: l10n.collectionsShowOnHomeDescription,
                value: !prefs.dismissed,
                onChanged: (value) => _setCollectionsVisible(prefs, value),
              ),
            );
          },
        ),
        SettingsSectionHeader(title: l10n.settingsBrewingMethodsHeader),
        // Rebuilds when either ValueNotifier changes, even without a
        // provider notification. The builder always returns a Column, so
        // the widget type at this tree position is stable across states.
        ValueListenableBuilder<Set<String>>(
          valueListenable: recipeProvider.shownBrewingMethodIds,
          builder: (context, shownIds, _) {
            return ValueListenableBuilder<Set<String>>(
              valueListenable: recipeProvider.hiddenBrewingMethodIds,
              builder: (context, hiddenIds, _) {
                final methodsWithRecipes = <String>{
                  for (final recipe in recipeProvider.recipes)
                    recipe.brewingMethodId,
                };
                return Column(
                  children: [
                    for (final method in methods)
                      Semantics(
                        identifier:
                            'brewingMethodSwitch_${method.brewingMethodId}',
                        container: true,
                        child: AppSwitchListTile(
                          title: method.brewingMethod,
                          value: _switchValue(
                            method.brewingMethodId,
                            shownIds,
                            hiddenIds,
                            methodsWithRecipes,
                          ),
                          onChanged: (value) {
                            final previous = _switchValue(
                              method.brewingMethodId,
                              shownIds,
                              hiddenIds,
                              methodsWithRecipes,
                            );
                            recipeProvider.setUserBrewingMethodPreference(
                              method.brewingMethodId,
                              value,
                            );
                            SettingsAnalytics.settingChanged(
                              key: SettingKey.brewingMethodVisible,
                              value: SettingsAnalytics.onOff(value),
                              previous: SettingsAnalytics.onOff(previous),
                              brewingMethodId: method.brewingMethodId,
                              source: SettingSource.settings,
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
        // Always present; disabled while there is nothing to reset so the
        // tree keeps the same widget type in both states.
        Semantics(
          identifier: 'settingsResetBrewingMethodsButton',
          container: true,
          child: AppTextButton(
            label: l10n.settingsResetToDefault,
            onPressed:
                recipeProvider.shownBrewingMethodIds.value.isNotEmpty ||
                        recipeProvider.hiddenBrewingMethodIds.value.isNotEmpty
                    ? () => _confirmReset(context, recipeProvider)
                    : null,
            foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
