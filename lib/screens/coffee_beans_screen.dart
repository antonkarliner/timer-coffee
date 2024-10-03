import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_router.gr.dart';
import '../providers/coffee_beans_provider.dart';
import '../models/coffee_beans_model.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
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
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          Semantics(
            identifier: 'toggleEditModeButton',
            label: loc.toggleEditMode,
            child: IconButton(
              icon: Icon(isEditMode ? Icons.done : Icons.edit_note),
              onPressed: toggleEditMode,
            ),
          ),
        ],
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
      floatingActionButton: Semantics(
        identifier: 'addCoffeeBeansButton',
        label: loc.addBeans,
        child: FloatingActionButton(
          onPressed: () async {
            final result = await context.router.push(NewBeansRoute());
            if (result != null && result is String) {
              setState(() {}); // Refresh the list after adding new beans
            }
          },
          child: const Icon(Icons.add),
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
    final coffeeBeansProvider =
        Provider.of<CoffeeBeansProvider>(context, listen: false);
    final databaseProvider =
        Provider.of<DatabaseProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;

    return Semantics(
      identifier: 'coffeeBeanCard_${bean.beansUuid}',
      label: '${bean.name}, ${bean.roaster}, ${bean.origin}',
      child: GestureDetector(
        onTap: () {
          context.router.push(CoffeeBeansDetailRoute(uuid: bean.beansUuid!));
        },
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.2,
                  child: FutureBuilder<Map<String, String?>>(
                    future: databaseProvider.fetchRoasterLogoUrls(bean.roaster),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final originalUrl = snapshot.data!['original'];
                        final mirrorUrl = snapshot.data!['mirror'];

                        if (originalUrl != null || mirrorUrl != null) {
                          return ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: CachedNetworkImage(
                                imageUrl: originalUrl ?? mirrorUrl!,
                                placeholder: (context, url) => const Icon(
                                    Coffeico.bag_with_bean,
                                    size: 40),
                                errorWidget: (context, url, error) {
                                  if (url == originalUrl && mirrorUrl != null) {
                                    return CachedNetworkImage(
                                      imageUrl: mirrorUrl,
                                      placeholder: (context, url) => const Icon(
                                          Coffeico.bag_with_bean,
                                          size: 40),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Coffeico.bag_with_bean,
                                              size: 40),
                                      width: 40,
                                      fit: BoxFit.cover,
                                    );
                                  }
                                  return const Icon(Coffeico.bag_with_bean,
                                      size: 40);
                                },
                                width: 40,
                                fit: BoxFit.cover,
                              ));
                        }
                      }
                      return const Icon(Coffeico.bag_with_bean, size: 40);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        identifier: 'beanName_${bean.beansUuid}',
                        label: loc.name,
                        child: Text(bean.name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 4),
                      Semantics(
                        identifier: 'beanRoaster_${bean.beansUuid}',
                        label: loc.roaster,
                        child: Text(bean.roaster,
                            style: const TextStyle(fontSize: 14)),
                      ),
                      const SizedBox(height: 4),
                      Semantics(
                        identifier: 'beanOrigin_${bean.beansUuid}',
                        label: loc.origin,
                        child: Text(bean.origin,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey)),
                      ),
                    ],
                  ),
                ),
                if (isEditMode)
                  Semantics(
                    identifier: 'deleteBeanButton_${bean.beansUuid}',
                    label: loc.delete,
                    child: IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.red),
                      onPressed: onDelete,
                    ),
                  ),
                Semantics(
                  identifier: 'favoriteBeanButton_${bean.beansUuid}',
                  label: bean.isFavorite ? loc.removeFavorite : loc.addFavorite,
                  child: IconButton(
                    icon: Icon(
                      bean.isFavorite ? Icons.favorite : Icons.favorite_border,
                    ),
                    onPressed: () async {
                      await coffeeBeansProvider.toggleFavoriteStatus(
                          bean.beansUuid!, !bean.isFavorite);
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
