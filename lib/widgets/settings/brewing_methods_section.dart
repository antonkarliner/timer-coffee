import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

import '../../models/brewing_method_model.dart';
import '../app_switch_list_tile.dart';

/// Brewing methods visibility settings — lets users show/hide methods.
class BrewingMethodsSection extends StatelessWidget {
  const BrewingMethodsSection({
    super.key,
    required this.allBrewingMethods,
    required this.methodsWithRecipes,
    required this.shownIds,
    required this.hiddenIds,
    required this.onPreferenceChanged,
    this.controller,
  });

  final List<BrewingMethodModel> allBrewingMethods;
  final Set<String> methodsWithRecipes;
  final Set<String> shownIds;
  final Set<String> hiddenIds;
  final void Function(String methodId, bool value) onPreferenceChanged;
  final ExpansibleController? controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      identifier: 'brewingMethodsSettingsExpansionTile',
      child: ExpansionTile(
        controller: controller,
        title: Text(l10n.settingsBrewingMethodsTitle),
        children: allBrewingMethods.map((method) {
          final hasRecipes = methodsWithRecipes.contains(method.brewingMethodId);
          final isShownByUser = shownIds.contains(method.brewingMethodId);
          final isHiddenByUser = hiddenIds.contains(method.brewingMethodId);

          bool switchValue;
          if (isShownByUser) {
            switchValue = true;
          } else if (isHiddenByUser) {
            switchValue = false;
          } else {
            switchValue = hasRecipes;
          }

          return AppSwitchListTile(
            title: method.brewingMethod,
            value: switchValue,
            onChanged: (value) =>
                onPreferenceChanged(method.brewingMethodId, value),
          );
        }).toList(),
      ),
    );
  }
}
