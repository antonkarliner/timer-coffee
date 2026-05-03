// lib/widgets/roasters/roasters_app_bar.dart

import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/smart_back_button.dart';

class RoastersAppBar extends StatelessWidget implements PreferredSizeWidget {
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
      scrolledUnderElevation: 0,
      elevation: 0,
      leading: const SmartBackButton(),
      title: TextField(
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
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
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
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
