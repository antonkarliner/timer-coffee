import 'package:auto_route/auto_route.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/coffee_beans_provider.dart';
import '../providers/database_provider.dart';
import '../models/coffee_beans_model.dart';
import '../app_router.gr.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AddCoffeeBeansWidget extends StatefulWidget {
  final Function(String) onSelect; // Always return UUID

  const AddCoffeeBeansWidget({Key? key, required this.onSelect})
      : super(key: key);

  @override
  _AddCoffeeBeansWidgetState createState() => _AddCoffeeBeansWidgetState();
}

class _AddCoffeeBeansWidgetState extends State<AddCoffeeBeansWidget> {
  String? selectedBeanUuid;
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
          ..sort((a, b) => b.beansUuid?.compareTo(a.beansUuid ?? '') ?? 0);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Widget _buildBeanTile(CoffeeBeansModel bean, BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final databaseProvider =
        Provider.of<DatabaseProvider>(context, listen: false);

    return Semantics(
      identifier: 'coffeeBeanTile_${bean.beansUuid}',
      label:
          '${bean.name}, ${bean.roaster}, ${bean.isFavorite ? loc.favorite : loc.notFavorite}',
      child: ListTile(
        leading: Container(
          width: 40,
          child: FutureBuilder<Map<String, String?>>(
            future: databaseProvider.fetchRoasterLogoUrls(bean.roaster),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final originalUrl = snapshot.data!['original'];
                final mirrorUrl = snapshot.data!['mirror'];

                if (originalUrl != null || mirrorUrl != null) {
                  return CachedNetworkImage(
                    imageUrl: originalUrl ?? mirrorUrl!,
                    placeholder: (context, url) =>
                        const Icon(Coffeico.bag_with_bean, size: 40),
                    errorWidget: (context, url, error) {
                      if (url == originalUrl && mirrorUrl != null) {
                        return CachedNetworkImage(
                          imageUrl: mirrorUrl,
                          placeholder: (context, url) =>
                              const Icon(Coffeico.bag_with_bean, size: 40),
                          errorWidget: (context, url, error) =>
                              const Icon(Coffeico.bag_with_bean, size: 40),
                          width: 40,
                          fit: BoxFit.cover,
                        );
                      }
                      return const Icon(Coffeico.bag_with_bean, size: 40);
                    },
                    width: 40,
                    fit: BoxFit.cover,
                  );
                }
              }
              return const Icon(Coffeico.bag_with_bean, size: 40);
            },
          ),
        ),
        title: Text(bean.name),
        subtitle: Text(bean.roaster),
        trailing: bean.isFavorite
            ? Icon(
                Icons.favorite,
                color: Theme.of(context).colorScheme.onSurface,
              )
            : null,
        selected: selectedBeanUuid == bean.beansUuid,
        selectedTileColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.2)
            : Theme.of(context).primaryColor.withOpacity(0.1),
        onTap: () {
          setState(() {
            selectedBeanUuid = bean.beansUuid;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 450),
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
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    leading: Icon(
                                      Icons.add,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context).primaryColor,
                                    ),
                                    onTap: () async {
                                      final result = await context.router
                                          .push(NewBeansRoute());
                                      if (result != null && result is String) {
                                        setState(() {
                                          selectedBeanUuid = result;
                                        });
                                        await _fetchCoffeeBeans(); // Refresh the list
                                      }
                                    },
                                  ));
                            }
                            return _buildBeanTile(
                                beansList[index - 1], context);
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Semantics(
                identifier: 'nextButton',
                label: loc.next,
                child: OutlinedButton(
                  onPressed: selectedBeanUuid != null
                      ? () {
                          widget.onSelect(selectedBeanUuid!);
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
