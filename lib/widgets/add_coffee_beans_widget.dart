import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/widgets/roaster_logo.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/coffee_beans_provider.dart';
import '../providers/database_provider.dart';
import '../models/coffee_beans_model.dart';
import '../app_router.gr.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

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
    const double logoHeight = 40.0;
    const double maxWidthFactor = 2.0; // 40 × 2 = 80 px max width

    final databaseProvider =
        Provider.of<DatabaseProvider>(context, listen: false);
    final isSelected = selectedBeanUuid == bean.beansUuid;
    final brightness = Theme.of(context).brightness;
    final selectedColor = brightness == Brightness.light
        ? Theme.of(context).primaryColor.withOpacity(0.15)
        : Colors.grey.withOpacity(0.2);
    final loc = AppLocalizations.of(context)!;

    Widget tileContent = Stack(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
          leading: SizedBox(
            height: logoHeight,
            width: logoHeight * maxWidthFactor,
            child: FutureBuilder<Map<String, String?>>(
              future: databaseProvider.fetchCachedRoasterLogoUrls(bean.roaster),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final originalUrl = snapshot.data!['original'];
                  final mirrorUrl = snapshot.data!['mirror'];

                  if (originalUrl != null || mirrorUrl != null) {
                    return RoasterLogo(
                      originalUrl: originalUrl,
                      mirrorUrl: mirrorUrl,
                      height: logoHeight,
                      width: logoHeight * maxWidthFactor,
                      borderRadius: 0, // ← no rounded corners
                      forceFit: BoxFit.contain, // ← never crop
                    );
                  }
                }
                return const Icon(Coffeico.bag_with_bean, size: logoHeight);
              },
            ),
          ),
          title: Text(bean.name),
          subtitle: Text(bean.roaster),
          onTap: () {
            setState(() => selectedBeanUuid = bean.beansUuid);
          },
        ),
        // Weight chip aligned with bean name if available
        if (bean.validatedPackageWeightGrams != null)
          Positioned(
            top: 12, // Position to align with bean name (approximately)
            right: 16, // Align with text content padding
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${bean.validatedPackageWeightGrams!.toInt()}${loc.unitGramsShort}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );

    if (isSelected) {
      tileContent = Container(
        decoration: BoxDecoration(
          color: selectedColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: tileContent,
      );
    }

    return Semantics(
      identifier: 'coffeeBeanTile_${bean.beansUuid}',
      label: '${bean.name}, ${bean.roaster}',
      child: tileContent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;

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
                      : Container(
                          decoration: BoxDecoration(
                            color: isLight ? null : null,
                            gradient: isLight
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.grey.shade400,
                                      Colors.grey.shade300
                                    ],
                                  )
                                : LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.grey.shade800,
                                      Colors.grey.shade700
                                    ],
                                  ),
                          ),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(8.0),
                            itemCount: beansList.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Semantics(
                                  identifier: 'addNewBeansTile',
                                  label: loc.addNewBeans,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
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
                                  ),
                                );
                              }
                              return _buildBeanTile(
                                  beansList[index - 1], context);
                            },
                          ),
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Semantics(
                identifier: 'nextButton',
                label: loc.next,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
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
