import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/rendering.dart';
import '../app_router.gr.dart';
import '../providers/coffee_beans_provider.dart';
import '../models/coffee_beans_model.dart';
import 'package:coffeico/coffeico.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/roaster_logo.dart';

enum SortOption { dateAdded, name, roaster, origin }

enum ViewMode { list, grid }

class FilterOptions {
  List<String> selectedRoasters;
  List<String> selectedOrigins;
  bool isFavoriteOnly;

  FilterOptions({
    required this.selectedRoasters,
    required this.selectedOrigins,
    this.isFavoriteOnly = false,
  });
}

@RoutePage()
class CoffeeBeansScreen extends StatefulWidget {
  const CoffeeBeansScreen({Key? key}) : super(key: key);

  @override
  _CoffeeBeansScreenState createState() => _CoffeeBeansScreenState();
}

class _CoffeeBeansScreenState extends State<CoffeeBeansScreen> {
  bool isEditMode = false;
  List<String> selectedRoasters = [];
  List<String> selectedOrigins = [];
  bool isFavoriteOnly = false;

  List<String> roasters = [];
  List<String> origins = [];

  // New state variables for enhanced features
  SortOption _currentSort = SortOption.dateAdded;
  ViewMode _viewMode = ViewMode.list;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // BottomAppBar hide-on-scroll logic
  bool _isBottomBarVisible = true;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isBottomBarVisible) {
        setState(() {
          _isBottomBarVisible = false;
        });
      }
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isBottomBarVisible) {
        setState(() {
          _isBottomBarVisible = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _loadFilterOptions() async {
    final coffeeBeansProvider =
        Provider.of<CoffeeBeansProvider>(context, listen: false);
    roasters = await coffeeBeansProvider.fetchAllDistinctRoasters();
    origins = await coffeeBeansProvider.fetchAllDistinctOrigins();
    setState(() {});
  }

  void toggleEditMode() {
    setState(() {
      isEditMode = !isEditMode;
    });
  }

  void _showFilterDialog() async {
    final loc = AppLocalizations.of(context)!;

    final result = await showModalBottomSheet<FilterOptions>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        List<String> tempSelectedRoasters = List.from(selectedRoasters);
        List<String> tempSelectedOrigins = List.from(selectedOrigins);
        bool tempIsFavoriteOnly = isFavoriteOnly;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            // Function to update origins based on selected roasters
            void updateOrigins() async {
              final coffeeBeansProvider =
                  Provider.of<CoffeeBeansProvider>(context, listen: false);
              origins = await coffeeBeansProvider
                  .fetchOriginsForRoasters(tempSelectedRoasters);
              setState(() {
                tempSelectedOrigins = tempSelectedOrigins
                    .where((origin) => origins.contains(origin))
                    .toList();
              });
            }

            return SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    title: Row(
                      children: [
                        Text('${loc.roaster}: '),
                        Expanded(
                          child: Text(
                            tempSelectedRoasters.isEmpty
                                ? loc.all
                                : tempSelectedRoasters.join(', '),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors
                                      .grey[300] // Light color for dark mode
                                  : Colors
                                      .grey[700], // Dark color for light mode
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (context) {
                          List<String> dialogSelectedRoasters =
                              List.from(tempSelectedRoasters);
                          return StatefulBuilder(
                            builder: (BuildContext context,
                                StateSetter dialogSetState) {
                              return AlertDialog(
                                title: Text(loc.selectRoaster),
                                content: Container(
                                  width: double.maxFinite,
                                  child: ListView(
                                    shrinkWrap: true,
                                    children: roasters.map((roaster) {
                                      return CheckboxListTile(
                                        title: Text(roaster),
                                        value: dialogSelectedRoasters
                                            .contains(roaster),
                                        onChanged: (bool? value) {
                                          dialogSetState(() {
                                            if (value == true) {
                                              if (!dialogSelectedRoasters
                                                  .contains(roaster)) {
                                                dialogSelectedRoasters
                                                    .add(roaster);
                                              }
                                            } else {
                                              dialogSelectedRoasters
                                                  .remove(roaster);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    child: Text(loc.cancel),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                  TextButton(
                                    child: Text(loc.ok),
                                    onPressed: () {
                                      tempSelectedRoasters =
                                          List.from(dialogSelectedRoasters);
                                      updateOrigins(); // Update origins when roasters change
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                      setState(() {}); // Update the trailing text
                    },
                  ),
                  ListTile(
                    title: Row(
                      children: [
                        Text('${loc.origin}: '),
                        Expanded(
                          child: Text(
                            tempSelectedOrigins.isEmpty
                                ? loc.all
                                : tempSelectedOrigins.join(', '),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors
                                      .grey[300] // Light color for dark mode
                                  : Colors
                                      .grey[700], // Dark color for light mode
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (context) {
                          List<String> dialogSelectedOrigins =
                              List.from(tempSelectedOrigins);
                          return StatefulBuilder(
                            builder: (BuildContext context,
                                StateSetter dialogSetState) {
                              return AlertDialog(
                                title: Text(loc.selectOrigin),
                                content: Container(
                                  width: double.maxFinite,
                                  child: ListView(
                                    shrinkWrap: true,
                                    children: origins.map((origin) {
                                      return CheckboxListTile(
                                        title: Text(origin),
                                        value: dialogSelectedOrigins
                                            .contains(origin),
                                        onChanged: (bool? value) {
                                          dialogSetState(() {
                                            if (value == true) {
                                              if (!dialogSelectedOrigins
                                                  .contains(origin)) {
                                                dialogSelectedOrigins
                                                    .add(origin);
                                              }
                                            } else {
                                              dialogSelectedOrigins
                                                  .remove(origin);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    child: Text(loc.cancel),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                  TextButton(
                                    child: Text(loc.ok),
                                    onPressed: () {
                                      tempSelectedOrigins =
                                          List.from(dialogSelectedOrigins);
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                      setState(() {}); // Update the trailing text
                    },
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                    title: Text(loc.showFavoritesOnly),
                    trailing: Checkbox(
                      value: tempIsFavoriteOnly,
                      onChanged: (value) {
                        setState(() {
                          tempIsFavoriteOnly = value!;
                        });
                      },
                    ),
                    onTap: () {
                      setState(() {
                        tempIsFavoriteOnly = !tempIsFavoriteOnly;
                      });
                    },
                  ),
                  ButtonBar(
                    children: [
                      TextButton(
                        child: Text(loc.resetFilters),
                        onPressed: () {
                          Navigator.pop(
                            context,
                            FilterOptions(
                              selectedRoasters: [],
                              selectedOrigins: [],
                              isFavoriteOnly: false,
                            ),
                          );
                        },
                      ),
                      OutlinedButton(
                        child: Text(loc.apply),
                        onPressed: () {
                          Navigator.pop(
                            context,
                            FilterOptions(
                              selectedRoasters: tempSelectedRoasters,
                              selectedOrigins: tempSelectedOrigins,
                              isFavoriteOnly: tempIsFavoriteOnly,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedRoasters = result.selectedRoasters;
        selectedOrigins = result.selectedOrigins;
        isFavoriteOnly = result.isFavoriteOnly;
        // Update the origins list based on the new selected roasters
        _updateOrigins();
      });
    }
  }

  void _updateOrigins() async {
    final coffeeBeansProvider =
        Provider.of<CoffeeBeansProvider>(context, listen: false);

    if (selectedRoasters.isEmpty) {
      // If no roasters are selected, fetch all origins
      origins = await coffeeBeansProvider.fetchAllDistinctOrigins();
    } else {
      // Fetch origins for the selected roasters
      origins =
          await coffeeBeansProvider.fetchOriginsForRoasters(selectedRoasters);
    }

    // Update the state to reflect changes in the origins list
    setState(() {});
  }

  // Helper methods for new features
  List<CoffeeBeansModel> _sortBeans(List<CoffeeBeansModel> beans) {
    switch (_currentSort) {
      case SortOption.dateAdded:
        // Sort by UUID in descending order (newest first)
        beans.sort((a, b) => b.beansUuid.compareTo(a.beansUuid));
        break;
      case SortOption.name:
        beans.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.roaster:
        beans.sort((a, b) => a.roaster.compareTo(b.roaster));
        break;
      case SortOption.origin:
        beans.sort((a, b) => a.origin.compareTo(b.origin));
        break;
    }
    return beans;
  }

  List<CoffeeBeansModel> _filterBeans(List<CoffeeBeansModel> beans) {
    if (_searchQuery.isEmpty) return beans;

    return beans.where((bean) {
      final query = _searchQuery.toLowerCase();
      return bean.name.toLowerCase().contains(query) ||
          bean.roaster.toLowerCase().contains(query) ||
          bean.origin.toLowerCase().contains(query) ||
          (bean.tastingNotes?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _showSortDialog() {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.sortBy),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: SortOption.values.map((option) {
            String title;
            switch (option) {
              case SortOption.dateAdded:
                title = loc.dateAdded;
                break;
              case SortOption.name:
                title = loc.name;
                break;
              case SortOption.roaster:
                title = loc.roaster;
                break;
              case SortOption.origin:
                title = loc.origin;
                break;
            }

            return RadioListTile<SortOption>(
              title: Text(title),
              value: option,
              groupValue: _currentSort,
              onChanged: (value) {
                setState(() {
                  _currentSort = value!;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      selectedRoasters.clear();
      selectedOrigins.clear();
      isFavoriteOnly = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  bool get _hasActiveFilters {
    return selectedRoasters.isNotEmpty ||
        selectedOrigins.isNotEmpty ||
        isFavoriteOnly ||
        _searchQuery.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final coffeeBeansProvider = Provider.of<CoffeeBeansProvider>(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          identifier: 'coffeeBeansAppBar',
          label: loc.coffeebeans,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Coffeico.bag_with_bean),
              const SizedBox(width: 8),
              Text(loc.coffeebeans),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
                _viewMode == ViewMode.list ? Icons.grid_view : Icons.view_list),
            onPressed: () {
              setState(() {
                _viewMode =
                    _viewMode == ViewMode.list ? ViewMode.grid : ViewMode.list;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: loc.searchBeans,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Filter Chips
          if (_hasActiveFilters)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (selectedRoasters.isNotEmpty)
                    ...selectedRoasters.map((roaster) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(roaster),
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            deleteIconColor:
                                Theme.of(context).colorScheme.onPrimary,
                            onSelected: (bool value) {
                              // Do nothing - we only want delete functionality
                            },
                            onDeleted: () {
                              setState(() {
                                selectedRoasters.remove(roaster);
                              });
                            },
                          ),
                        )),
                  if (selectedOrigins.isNotEmpty)
                    ...selectedOrigins.map((origin) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(origin),
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            deleteIconColor:
                                Theme.of(context).colorScheme.onPrimary,
                            onSelected: (bool value) {
                              // Do nothing - we only want delete functionality
                            },
                            onDeleted: () {
                              setState(() {
                                selectedOrigins.remove(origin);
                              });
                            },
                          ),
                        )),
                  if (isFavoriteOnly)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(loc.favorites),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        deleteIconColor:
                            Theme.of(context).colorScheme.onPrimary,
                        onSelected: (bool value) {
                          // Do nothing - we only want delete functionality
                        },
                        onDeleted: () {
                          setState(() {
                            isFavoriteOnly = false;
                          });
                        },
                      ),
                    ),
                  if (_searchQuery.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text('${loc.searchPrefix}$_searchQuery'),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        deleteIconColor:
                            Theme.of(context).colorScheme.onPrimary,
                        onSelected: (bool value) {
                          // Do nothing - we only want delete functionality
                        },
                        onDeleted: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text(loc.clearAll),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: _clearFilters,
                    ),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: FutureBuilder<List<CoffeeBeansModel>>(
              future: coffeeBeansProvider.fetchFilteredCoffeeBeans(
                roasters: selectedRoasters.isNotEmpty ? selectedRoasters : null,
                origins: selectedOrigins.isNotEmpty ? selectedOrigins : null,
                isFavorite: isFavoriteOnly ? true : null,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  var filteredData = _filterBeans(snapshot.data!);
                  // Apply user sort (default is dateAdded which sorts newest first)
                  var sortedData = _sortBeans(filteredData);

                  if (sortedData.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            loc.noBeansMatchSearch,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _clearFilters,
                            child: Text(loc.clearFilters),
                          ),
                        ],
                      ),
                    );
                  }

                  return _viewMode == ViewMode.list
                      ? ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16.0),
                          itemCount: sortedData.length,
                          itemBuilder: (context, index) {
                            final bean = sortedData[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: CoffeeBeanCard(
                                key: ValueKey(bean.beansUuid),
                                bean: bean,
                                isEditMode: isEditMode,
                                onDelete: () async {
                                  await coffeeBeansProvider
                                      .deleteCoffeeBeans(bean.beansUuid!);
                                  setState(() {});
                                },
                              ),
                            );
                          },
                        )
                      : GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16.0),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                          ),
                          itemCount: sortedData.length,
                          itemBuilder: (context, index) {
                            final bean = sortedData[index];
                            return CoffeeBeanGridCard(
                              key: ValueKey(bean.beansUuid),
                              bean: bean,
                              isEditMode: isEditMode,
                              onDelete: () async {
                                await coffeeBeansProvider
                                    .deleteCoffeeBeans(bean.beansUuid!);
                                setState(() {});
                              },
                            );
                          },
                        );
                } else if (snapshot.hasData && snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Coffeico.bag_with_bean,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loc.nocoffeebeans,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result =
                                await context.router.push(NewBeansRoute());
                            if (result != null && result is String) {
                              setState(() {});
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: Text(loc.addBeans),
                        ),
                      ],
                    ),
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedScale(
        scale: _isBottomBarVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedOpacity(
          opacity: _isBottomBarVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !_isBottomBarVisible,
            child: Semantics(
              identifier: 'addCoffeeBeansButton',
              label: loc.addBeans,
              child: FloatingActionButton(
                onPressed: () async {
                  final result = await context.router.push(NewBeansRoute());
                  if (result != null && result is String) {
                    setState(() {});
                  }
                },
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _isBottomBarVisible ? kBottomNavigationBarHeight : 0,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(
                      Theme.of(context).brightness == Brightness.dark ? 31 : 20,
                    ),
                width: 1,
              ),
            ),
            color: Theme.of(context).bottomAppBarTheme.color ??
                Theme.of(context).colorScheme.surface,
          ),
          child: IgnorePointer(
            ignoring: !_isBottomBarVisible,
            child: AnimatedOpacity(
              opacity: _isBottomBarVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: BottomAppBar(
                shape: const CircularNotchedRectangle(),
                notchMargin: 8,
                color: Colors.transparent,
                elevation: 0,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.filter_list, size: 28),
                      tooltip: loc.filter,
                      onPressed: _showFilterDialog,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(isEditMode ? Icons.done : Icons.edit_note,
                          size: 28),
                      tooltip: loc.toggleEditMode,
                      onPressed: toggleEditMode,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CoffeeBeanGridCard extends StatelessWidget {
  final CoffeeBeansModel bean;
  final bool isEditMode;
  final VoidCallback onDelete;

  const CoffeeBeanGridCard({
    Key? key,
    required this.bean,
    required this.isEditMode,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // same neutral gradient as hero header
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgStart = isLight ? Colors.grey.shade200 : Colors.grey.shade800;
    final bgEnd = isLight ? Colors.grey.shade100 : Colors.grey.shade700;
    // icon tint
    final iconColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    final coffeeBeansProvider =
        Provider.of<CoffeeBeansProvider>(context, listen: false);
    final databaseProvider =
        Provider.of<DatabaseProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;

    return Semantics(
      identifier: 'coffeeBeanGridCard_${bean.beansUuid}',
      label: '${bean.name}, ${bean.roaster}, ${bean.origin}',
      child: GestureDetector(
        onTap: () =>
            context.router.push(CoffeeBeansDetailRoute(uuid: bean.beansUuid!)),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bgStart, bgEnd],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with favorite
                if (bean.isFavorite)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const Spacer(),
                        Icon(
                          Icons.favorite,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),

                // Logo section
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8.0),
                    child: FutureBuilder<Map<String, String?>>(
                      future: databaseProvider
                          .fetchCachedRoasterLogoUrls(bean.roaster),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final originalUrl = snapshot.data!['original'];
                          final mirrorUrl = snapshot.data!['mirror'];
                          if (originalUrl != null || mirrorUrl != null) {
                            return RoasterLogo(
                              originalUrl: originalUrl,
                              mirrorUrl: mirrorUrl,
                              height: 60,
                              borderRadius: 8.0,
                              forceFit: BoxFit.contain,
                            );
                          }
                        }
                        return Icon(
                          Coffeico.bag_with_bean,
                          size: 60,
                          color: iconColor,
                        );
                      },
                    ),
                  ),
                ),

                // Text information
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bean.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface, // ensure contrast
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bean.roaster,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bean.origin,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                if (isEditMode)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(
                            bean.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: bean.isFavorite
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withOpacity(0.6),
                            size: 20,
                          ),
                          onPressed: () async {
                            await coffeeBeansProvider.toggleFavoriteStatus(
                              bean.beansUuid!,
                              !bean.isFavorite,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => ConfirmDeleteDialog(
                                title: loc.confirmDeleteTitle,
                                content: loc.confirmDeleteMessage,
                                confirmLabel: loc.delete,
                                cancelLabel: loc.cancel,
                              ),
                            );
                            if (confirmed == true) onDelete();
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CoffeeBeanCard extends StatelessWidget {
  final CoffeeBeansModel bean;
  final bool isEditMode;
  final VoidCallback onDelete;

  const CoffeeBeanCard({
    Key? key,
    required this.bean,
    required this.isEditMode,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // neutral gradient
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgStart = isLight ? Colors.grey.shade200 : Colors.grey.shade800;
    final bgEnd = isLight ? Colors.grey.shade100 : Colors.grey.shade700;
    final iconColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    const double logoHeight = 80.0;
    const double maxWidthFactor = 2.0;

    final coffeeBeansProvider =
        Provider.of<CoffeeBeansProvider>(context, listen: false);
    final databaseProvider =
        Provider.of<DatabaseProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;

    return Semantics(
      identifier: 'coffeeBeanCard_${bean.beansUuid}',
      label: '${bean.name}, ${bean.roaster}, ${bean.origin}',
      child: GestureDetector(
        onTap: () =>
            context.router.push(CoffeeBeansDetailRoute(uuid: bean.beansUuid!)),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bgStart, bgEnd],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // ───────── LOGO SLOT ─────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: logoHeight,
                        maxHeight: logoHeight,
                        minWidth: logoHeight,
                        maxWidth: logoHeight * maxWidthFactor,
                      ),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                        child: FutureBuilder<Map<String, String?>>(
                          future: databaseProvider
                              .fetchCachedRoasterLogoUrls(bean.roaster),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final originalUrl = snapshot.data!['original'];
                              final mirrorUrl = snapshot.data!['mirror'];
                              if (originalUrl != null || mirrorUrl != null) {
                                return RoasterLogo(
                                  originalUrl: originalUrl,
                                  mirrorUrl: mirrorUrl,
                                  height: logoHeight,
                                  borderRadius: 8.0,
                                  forceFit: BoxFit.contain,
                                );
                              }
                            }
                            return Icon(
                              Coffeico.bag_with_bean,
                              size: logoHeight,
                              color: iconColor,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  // ───────── TEXT SECTION ─────────
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bean.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bean.roaster,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bean.origin,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ───────── ACTION BUTTONS ─────────
                  if (isEditMode)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.red),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => ConfirmDeleteDialog(
                            title: loc.confirmDeleteTitle,
                            content: loc.confirmDeleteMessage,
                            confirmLabel: loc.delete,
                            cancelLabel: loc.cancel,
                          ),
                        );
                        if (confirmed == true) onDelete();
                      },
                    ),
                  IconButton(
                    icon: Icon(
                      bean.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: bean.isFavorite
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.6),
                    ),
                    onPressed: () async {
                      await coffeeBeansProvider.toggleFavoriteStatus(
                        bean.beansUuid!,
                        !bean.isFavorite,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
