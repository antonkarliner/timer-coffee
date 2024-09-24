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

@RoutePage()
class CoffeeBeansScreen extends StatefulWidget {
  const CoffeeBeansScreen({Key? key}) : super(key: key);

  @override
  _CoffeeBeansScreenState createState() => _CoffeeBeansScreenState();
}

class _CoffeeBeansScreenState extends State<CoffeeBeansScreen> {
  bool isEditMode = false;

  void toggleEditMode() {
    setState(() {
      isEditMode = !isEditMode;
    });
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
        future: coffeeBeansProvider.fetchAllCoffeeBeans(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // Sort the list in descending order based on the UUID
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
