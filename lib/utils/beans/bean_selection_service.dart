import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/coffee_beans_provider.dart';
import '../../providers/database_provider.dart';

class BeanSelection {
  final String? uuid;
  final String? name;
  final String? originalLogoUrl;
  final String? mirrorLogoUrl;

  const BeanSelection({
    required this.uuid,
    required this.name,
    required this.originalLogoUrl,
    required this.mirrorLogoUrl,
  });

  BeanSelection copyWith({
    String? uuid,
    String? name,
    String? originalLogoUrl,
    String? mirrorLogoUrl,
  }) {
    return BeanSelection(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      originalLogoUrl: originalLogoUrl ?? this.originalLogoUrl,
      mirrorLogoUrl: mirrorLogoUrl ?? this.mirrorLogoUrl,
    );
  }

  static const empty = BeanSelection(
    uuid: null,
    name: null,
    originalLogoUrl: null,
    mirrorLogoUrl: null,
  );
}

/// Centralizes bean selection side-effects (SharedPreferences + provider lookups)
/// so multiple screens can reuse the behavior consistently.
class BeanSelectionService {
  const BeanSelectionService();

  /// Loads the current selection from SharedPreferences and enriches with
  /// bean name and cached roaster logo URLs (if available).
  Future<BeanSelection> loadSelectedBean(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final uuid = prefs.getString('selectedBeanUuid');
    if (uuid == null) return BeanSelection.empty;

    final coffeeBeansProvider =
        Provider.of<CoffeeBeansProvider>(context, listen: false);
    final bean = await coffeeBeansProvider.fetchCoffeeBeansByUuid(uuid);

    if (bean == null) {
      // Bean no longer exists, clear persisted selection.
      await prefs.remove('selectedBeanUuid');
      return BeanSelection.empty;
    }

    String? originalUrl;
    String? mirrorUrl;

    if (bean.roaster != null) {
      final databaseProvider =
          Provider.of<DatabaseProvider>(context, listen: false);
      final logoUrls =
          await databaseProvider.fetchCachedRoasterLogoUrls(bean.roaster);
      originalUrl = logoUrls['original'];
      mirrorUrl = logoUrls['mirror'];
    }

    return BeanSelection(
      uuid: uuid,
      name: bean.name,
      originalLogoUrl: originalUrl,
      mirrorLogoUrl: mirrorUrl,
    );
  }

  /// Updates the selection to the given uuid, persists it,
  /// and returns enriched selection details.
  Future<BeanSelection> updateSelectedBean(
      BuildContext context, String uuid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedBeanUuid', uuid);

    final coffeeBeansProvider =
        Provider.of<CoffeeBeansProvider>(context, listen: false);
    final bean = await coffeeBeansProvider.fetchCoffeeBeansByUuid(uuid);

    String? originalUrl;
    String? mirrorUrl;

    if (bean != null && bean.roaster != null) {
      final databaseProvider =
          Provider.of<DatabaseProvider>(context, listen: false);
      final logoUrls =
          await databaseProvider.fetchCachedRoasterLogoUrls(bean.roaster);
      originalUrl = logoUrls['original'];
      mirrorUrl = logoUrls['mirror'];
    }

    return BeanSelection(
      uuid: uuid,
      name: bean?.name,
      originalLogoUrl: originalUrl,
      mirrorLogoUrl: mirrorUrl,
    );
  }

  /// Clears the current selection from SharedPreferences and returns empty.
  Future<BeanSelection> clearSelectedBean(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selectedBeanUuid');
    return BeanSelection.empty;
  }
}
