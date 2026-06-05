// lib/screens/roasters_screen.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coffee_timer/app_router.gr.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/providers/roasters_provider.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/widgets/roasters/country_filter_sheet.dart';
import 'package:coffee_timer/widgets/roasters/roaster_tile.dart';
import 'package:coffee_timer/widgets/roasters/roasters_app_bar.dart';

@RoutePage()
class RoastersScreen extends StatefulWidget {
  const RoastersScreen({super.key});

  @override
  State<RoastersScreen> createState() => _RoastersScreenState();
}

class _RoastersScreenState extends State<RoastersScreen> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<RoastersProvider>();
    _searchController = TextEditingController(text: provider.searchQuery);
    _searchFocusNode = FocusNode();
    _scrollController = ScrollController()..addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await provider.loadCountries();
      if (provider.roasters.isEmpty) {
        await provider.loadInitial();
      }
    });
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.extentAfter < 280) {
      context.read<RoastersProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchCleared() {
    _searchController.clear();
    context.read<RoastersProvider>().setSearchQuery('');
    _searchFocusNode.unfocus();
  }

  void _onFilterPressed() {
    showCountryFilterSheet(context, context.read<RoastersProvider>());
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Consumer<RoastersProvider>(
      builder: (context, provider, _) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            appBar: RoastersAppBar(
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              searchQuery: provider.searchQuery,
              hasActiveFilter: provider.hasActiveFilter,
              onFilterPressed: _onFilterPressed,
              onSearchCleared: _onSearchCleared,
              onSearchChanged: (query) =>
                  context.read<RoastersProvider>().setSearchQuery(query),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active country filter chip row
                if (provider.hasActiveFilter)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.base,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        FilterChip(
                          label: Text(provider.countryFilter!),
                          selected: true,
                          onSelected: (_) {},
                          onDeleted: () =>
                              provider.setCountryFilter(null),
                          deleteIconColor:
                              Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ],
                    ),
                  ),
                // Main content
                Expanded(
                  child: _buildBody(context, loc, provider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations loc,
    RoastersProvider provider,
  ) {
    if (provider.isLoading && provider.roasters.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.roasters.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 56,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.35),
              ),
              SizedBox(height: AppSpacing.base),
              Text(
                loc.noInternetConnection,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                loc.noInternetConnectionDesc,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.lg),
              AppElevatedButton(
                label: loc.retry,
                onPressed: () => provider.loadInitial(),
                isFullWidth: false,
                height: AppButton.heightMedium,
                padding: AppButton.paddingMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (provider.roasters.isEmpty) {
      return Center(
        child: Text(
          provider.searchQuery.isNotEmpty
              ? loc.roastersCatalogEmptySearch(provider.searchQuery)
              : loc.roastersCatalogEmpty,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final roasters = provider.roasters;
    final itemCount =
        roasters.length + (provider.hasMore ? 1 : 0);

    return ListView.separated(
      controller: _scrollController,
      itemCount: itemCount,
      separatorBuilder: (_, index) {
        if (index < roasters.length - 1) {
          return Divider(
            height: 1,
            indent: 72,
            endIndent: AppSpacing.base,
            thickness: 0.5,
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          );
        }
        return const SizedBox.shrink();
      },
      itemBuilder: (context, index) {
        if (index >= roasters.length) {
          // Footer: load-more indicator
          return Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.base),
            child: provider.isLoadingMore
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink(),
          );
        }
        final roaster = roasters[index];
        return RoasterTile(
          roaster: roaster,
          onTap: () => context.router.push(
            RoasterProfileRoute(slug: roaster.slug),
          ),
        );
      },
    );
  }
}
