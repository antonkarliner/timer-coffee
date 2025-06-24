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
        // No actions here; moved to BottomAppBar
      ),
      body: FutureBuilder<List<CoffeeBeansModel>>(
        future: coffeeBeansProvider.fetchFilteredCoffeeBeans(
          roasters: selectedRoasters.isNotEmpty ? selectedRoasters : null,
          origins: selectedOrigins.isNotEmpty ? selectedOrigins : null,
          isFavorite: isFavoriteOnly ? true : null,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final sortedData = snapshot.data!
              ..sort((a, b) => b.beansUuid!.compareTo(a.beansUuid!));

            return ListView.builder(
              controller: _scrollController,
              itemCount: sortedData.length,
              itemBuilder: (context, index) {
                final bean = sortedData[index];
                return CoffeeBeanCard(
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
          } else {
            return Center(
              child: Semantics(
                identifier: 'coffeeBeansEmpty',
                label: loc.nocoffeebeans,
                child: Text(loc.nocoffeebeans),
              ),
            );
          }
        },
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
                // backgroundColor removed to use default
                onPressed: () async {
                  final result = await context.router.push(NewBeansRoute());
                  if (result != null && result is String) {
                    setState(() {}); // Refresh the list after adding new beans
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
        bottom: true, // Apply bottom safe area
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _isBottomBarVisible ? kBottomNavigationBarHeight : 0,
          // Correctly formatted decoration and child:
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
    // ---- tweak these two numbers if you like ------------------------------
    const double logoHeight = 80.0; // vertical real-estate for every mark
    const double maxWidthFactor = 2.0; // 56 × 2 = 112 px maximum width allowed
    // -----------------------------------------------------------------------

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
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
                    // FittedBox scales the logo DOWN to fit, never up.
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
                          return const Icon(
                            Coffeico.bag_with_bean,
                            size: logoHeight,
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
                      Semantics(
                        identifier: 'beanName_${bean.beansUuid}',
                        label: loc.name,
                        child: Text(
                          bean.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Semantics(
                        identifier: 'beanRoaster_${bean.beansUuid}',
                        label: loc.roaster,
                        child: Text(
                          bean.roaster,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Semantics(
                        identifier: 'beanOrigin_${bean.beansUuid}',
                        label: loc.origin,
                        child: Text(
                          bean.origin,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ───────── ACTION BUTTONS ─────────
                if (isEditMode)
                  Semantics(
                    identifier: 'deleteBeanButton_${bean.beansUuid}',
                    label: loc.delete,
                    child: IconButton(
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
                  ),
                Semantics(
                  identifier: 'favoriteBeanButton_${bean.beansUuid}',
                  label: bean.isFavorite ? loc.removeFavorite : loc.addFavorite,
                  child: IconButton(
                    icon: Icon(bean.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border),
                    onPressed: () async {
                      await coffeeBeansProvider.toggleFavoriteStatus(
                        bean.beansUuid!,
                        !bean.isFavorite,
                      );
                    },
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
