import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_router.gr.dart';
import '../providers/coffee_beans_provider.dart';
import '../models/coffee_beans_model.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
              const Icon(Coffeico.bag_with_bean), // Add your desired icon here
              const SizedBox(width: 8), // Adjust spacing as needed
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Semantics(
                identifier: 'coffeeBeansLoading',
                label: loc.loading,
                child: const CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Semantics(
                identifier: 'coffeeBeansError',
                label: loc.error(snapshot.error.toString()),
                child: Text(loc.error(snapshot.error.toString())),
              ),
            );
          } else if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final bean = snapshot.data![index];
                return CoffeeBeanCard(
                  bean: bean,
                  isEditMode: isEditMode,
                  onDelete: () async {
                    await coffeeBeansProvider.deleteCoffeeBeans(bean.id);
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
          onPressed: () {
            context.router.push(NewBeansRoute());
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
    final loc = AppLocalizations.of(context)!;

    return Semantics(
      identifier: 'coffeeBeanCard_${bean.id}',
      label: '${bean.name}, ${bean.roaster}, ${bean.origin}',
      child: GestureDetector(
        onTap: () {
          context.router.push(CoffeeBeansDetailRoute(id: bean.id));
        },
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.2,
                  child: const Icon(Coffeico.bag_with_bean, size: 40),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        identifier: 'beanName_${bean.id}',
                        label: loc.name,
                        child: Text(bean.name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 4),
                      Semantics(
                        identifier: 'beanRoaster_${bean.id}',
                        label: loc.roaster,
                        child: Text(bean.roaster,
                            style: const TextStyle(fontSize: 14)),
                      ),
                      const SizedBox(height: 4),
                      Semantics(
                        identifier: 'beanOrigin_${bean.id}',
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
                    identifier: 'deleteBeanButton_${bean.id}',
                    label: loc.delete,
                    child: IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.red),
                      onPressed: onDelete,
                    ),
                  ),
                Semantics(
                  identifier: 'favoriteBeanButton_${bean.id}',
                  label: bean.isFavorite ? loc.removeFavorite : loc.addFavorite,
                  child: IconButton(
                    icon: Icon(
                      bean.isFavorite ? Icons.favorite : Icons.favorite_border,
                    ),
                    onPressed: () async {
                      await coffeeBeansProvider.toggleFavoriteStatus(
                          bean.id, bean.isFavorite);
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
