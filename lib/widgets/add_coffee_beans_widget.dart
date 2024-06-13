import 'package:auto_route/auto_route.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/coffee_beans_provider.dart';
import '../models/coffee_beans_model.dart';
import '../app_router.gr.dart'; // Import the generated router file
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddCoffeeBeansWidget extends StatefulWidget {
  final Function(int) onSelect;

  const AddCoffeeBeansWidget({Key? key, required this.onSelect})
      : super(key: key);

  @override
  _AddCoffeeBeansWidgetState createState() => _AddCoffeeBeansWidgetState();
}

class _AddCoffeeBeansWidgetState extends State<AddCoffeeBeansWidget> {
  int? selectedBeanId;
  final ScrollController _scrollController = ScrollController();
  List<CoffeeBeansModel> beansList = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchCoffeeBeans();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Additional logic if needed when scrolling
  }

  Future<void> _fetchCoffeeBeans() async {
    try {
      final coffeeBeansProvider =
          Provider.of<CoffeeBeansProvider>(context, listen: false);
      final beans = await coffeeBeansProvider.fetchAllCoffeeBeans();
      setState(() {
        beansList = beans
          ..sort((a, b) => b.id.compareTo(a.id)); // Sort in reverse order
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxHeight: 450), // Adjust the max height
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Semantics(
                identifier: 'selectCoffeeBeansAppBar',
                label: loc.selectCoffeeBeans,
                child: Text(loc.selectCoffeeBeans),
              ),
              automaticallyImplyLeading: false,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            Expanded(
              child: isLoading
                  ? Center(
                      child: Semantics(
                        identifier: 'loadingIndicator',
                        label: loc.loading,
                        child: const CircularProgressIndicator(),
                      ),
                    )
                  : error != null
                      ? Center(
                          child: Semantics(
                            identifier: 'errorText',
                            label: loc.error(error!),
                            child: Text(loc.error(error!)),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: beansList.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Semantics(
                                identifier: 'addNewBeansTile',
                                label: loc.addNewBeans,
                                child: ListTile(
                                  title: Text(
                                    loc.addNewBeans,
                                    style: TextStyle(
                                        color: Theme.of(context).primaryColor),
                                  ),
                                  leading: Icon(Icons.add,
                                      color: Theme.of(context).primaryColor),
                                  onTap: () async {
                                    final result = await context.router
                                        .push(NewBeansRoute());
                                    if (result != null && result is int) {
                                      setState(() {
                                        selectedBeanId = result;
                                      });
                                    }
                                  },
                                ),
                              );
                            }
                            final bean = beansList[index - 1];
                            return Semantics(
                              identifier: 'coffeeBeanTile_${bean.id}',
                              label:
                                  '${bean.name}, ${bean.roaster}, ${bean.isFavorite ? loc.favorite : loc.notFavorite}',
                              child: ListTile(
                                leading: const Icon(Coffeico.bag_with_bean),
                                title: Text(bean.name),
                                subtitle: Text(bean.roaster),
                                trailing: bean.isFavorite
                                    ? Icon(
                                        Icons.favorite,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onBackground,
                                      )
                                    : null,
                                selected: selectedBeanId == bean.id,
                                selectedTileColor: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1),
                                onTap: () {
                                  setState(() {
                                    selectedBeanId = bean.id;
                                  });
                                },
                              ),
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Semantics(
                identifier: 'nextButton',
                label: loc.next,
                child: OutlinedButton(
                  onPressed: selectedBeanId != null
                      ? () {
                          widget.onSelect(selectedBeanId!);
                        }
                      : null,
                  child: Text(loc.next),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
