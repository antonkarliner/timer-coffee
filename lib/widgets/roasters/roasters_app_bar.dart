// lib/widgets/roasters/roasters_app_bar.dart

import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/app_bar_title.dart';
import 'package:coffee_timer/widgets/smart_back_button.dart';

class RoastersAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Height of the outlined search field under the toolbar. Like My Beans'
  /// field, the decoration sets only `border: InputBorder.none`, so the app
  /// theme's `inputDecorationTheme` enabled/focused outlines draw the rounded
  /// box. The height is driven by the prefix icon's interactive-area
  /// constraints (kMinInteractiveDimension), which is font-metric independent;
  /// the value is measured in `roasters_app_bar_test.dart`.
  static const double searchFieldHeight = 48.0;

  /// Height of the `bottom` slot: the field plus its bottom padding.
  static const double bottomHeight = searchFieldHeight + AppSpacing.sm;

  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String searchQuery;
  final bool hasActiveFilter;
  final VoidCallback onFilterPressed;
  final VoidCallback onSearchCleared;
  final ValueChanged<String> onSearchChanged;

  const RoastersAppBar({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchQuery,
    required this.hasActiveFilter,
    required this.onFilterPressed,
    required this.onSearchCleared,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AppBar(
      elevation: 0,
      leading: const SmartBackButton(),
      title: AppBarTitle(
        text: loc.roastersCatalogTitle,
        icon: Icons.storefront_outlined,
      ),
      actions: [
        Badge(
          isLabelVisible: hasActiveFilter,
          child: IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: loc.filterByCountry,
            onPressed: onFilterPressed,
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(bottomHeight),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.base,
            0,
            AppSpacing.base,
            AppSpacing.sm,
          ),
          child: TextField(
            controller: searchController,
            focusNode: searchFocusNode,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: loc.searchRoasters,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onSearchCleared,
                    )
                  : null,
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + bottomHeight);
}
