import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/app_router.gr.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/user_stat_provider.dart';
import '../providers/coffee_beans_provider.dart';
import '../models/user_stat_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/icon_utils.dart';
import '../widgets/add_coffee_beans_widget.dart';
import '../widgets/expandable_card.dart';
import '../notifiers/card_expansion_notifier.dart';

@RoutePage()
class BrewDiaryScreen extends StatefulWidget {
  const BrewDiaryScreen({Key? key}) : super(key: key);

  @override
  _BrewDiaryScreenState createState() => _BrewDiaryScreenState();
}

class _BrewDiaryScreenState extends State<BrewDiaryScreen> {
  bool isEditMode = false;

  String getSweeetnessLabel(int position) {
    final loc = AppLocalizations.of(context)!;
    switch (position) {
      case 0:
        return loc.sweet;
      case 1:
        return loc.balance;
      case 2:
        return loc.acidic;
      default:
        return loc.donationerr;
    }
  }

  String getStrengthLabel(int position) {
    final loc = AppLocalizations.of(context)!;
    switch (position) {
      case 0:
        return loc.light;
      case 1:
        return loc.balance;
      case 2:
        return loc.strong;
      default:
        return loc.donationerr;
    }
  }

  void toggleEditMode() {
    setState(() {
      isEditMode = !isEditMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userStatProvider = Provider.of<UserStatProvider>(context);
    final loc = AppLocalizations.of(context)!;

    return ChangeNotifierProvider(
      create: (_) => CardExpansionNotifier(),
      child: Scaffold(
        appBar: AppBar(
          leading: Semantics(
            identifier: 'brewDiaryBackButton',
            child: const BackButton(),
          ),
          title: Semantics(
            identifier: 'brewDiaryAppBar',
            label: loc.brewdiary,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.library_books),
                const SizedBox(width: 8),
                Text(loc.brewdiary),
              ],
            ),
          ),
          actions: [
            Semantics(
              identifier: 'toggleEditModeButton',
              child: IconButton(
                icon: Icon(isEditMode ? Icons.done : Icons.edit_note),
                onPressed: toggleEditMode,
              ),
            ),
          ],
        ),
        body: FutureBuilder<List<UserStatsModel>>(
          future: userStatProvider.fetchAllUserStats(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Semantics(
                  identifier: 'brewDiaryError',
                  label: 'Error',
                  child: Text("Error: ${snapshot.error}"),
                ),
              );
            } else if (snapshot.hasData && snapshot.data!.isEmpty) {
              return Center(
                child: Semantics(
                  identifier: 'brewDiaryEmpty',
                  label: loc.brewdiarynotfound,
                  child: Text(loc.brewdiarynotfound),
                ),
              );
            } else if (snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  UserStatsModel stat = snapshot.data![index];
                  return buildUserStatCard(context, stat);
                },
              );
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Semantics(
                  identifier: 'brewDiaryLoading',
                  label: 'Loading',
                  child: const CircularProgressIndicator(),
                ),
              );
            } else {
              return Center(
                child: Semantics(
                  identifier: 'brewDiaryEmptyFallback',
                  label: loc.brewdiarynotfound,
                  child: Text(loc.brewdiarynotfound),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget buildUserStatCard(BuildContext context, UserStatsModel stat) {
    final loc = AppLocalizations.of(context)!;
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final userStatProvider = Provider.of<UserStatProvider>(context);
    DateFormat dateFormat = DateFormat('${loc.dateFormat} ${loc.timeFormat}',
        Localizations.localeOf(context).toString());

    return FutureBuilder<List<String>>(
      future: Future.wait([
        recipeProvider.getBrewingMethodName(stat.brewingMethodId),
        recipeProvider.getLocalizedRecipeName(stat.recipeId),
      ]),
      builder: (context, namesSnapshot) {
        if (namesSnapshot.hasData) {
          return Semantics(
            key: ValueKey(stat.id), // Use stat.id as the key
            identifier: 'userStatCard_${stat.id}',
            label: '${namesSnapshot.data![1]}, ${namesSnapshot.data![0]}',
            child: Consumer<CardExpansionNotifier>(
              builder: (context, notifier, _) {
                bool isExpanded = notifier.isExpanded(stat.id);
                return ExpandableCard(
                  key: ValueKey(stat.id), // Pass the key to ExpandableCard
                  leading: getIconByBrewingMethod(stat.brewingMethodId),
                  header: namesSnapshot.data![1],
                  subtitle:
                      "${namesSnapshot.data![0]} - ${dateFormat.format(stat.createdAt.toLocal())}",
                  detail: buildDetail(context, stat),
                  trailing: isEditMode
                      ? Semantics(
                          identifier: 'deleteUserStatButton_${stat.id}',
                          child: IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.red),
                            onPressed: () async {
                              await userStatProvider.deleteUserStat(stat.id);
                              notifier.setExpansion(stat.id, false);
                            },
                          ),
                        )
                      : null,
                  isExpanded: isExpanded,
                  onExpansionChanged: (bool expanded) {
                    notifier.setExpansion(stat.id, expanded);
                  },
                );
              },
            ),
          );
        } else if (namesSnapshot.connectionState == ConnectionState.waiting) {
          return Semantics(
            identifier: 'brewDiaryCardLoading_${stat.id}',
            label: 'Loading User Stat Card',
            child: const Card(child: ListTile(title: Text("Loading..."))),
          );
        } else {
          return Semantics(
            identifier: 'brewDiaryCardError_${stat.id}',
            label: 'Error Loading User Stat Card',
            child: const Card(
                child: ListTile(title: Text("Error fetching records"))),
          );
        }
      },
    );
  }

  Widget buildDetail(BuildContext context, UserStatsModel stat) {
    final loc = AppLocalizations.of(context)!;
    TextStyle detailTextStyle = Theme.of(context).textTheme.titleMedium!;
    final userStatProvider = Provider.of<UserStatProvider>(context);
    final coffeeBeansProvider = Provider.of<CoffeeBeansProvider>(context);

    TextEditingController notesController =
        TextEditingController(text: stat.notes);
    FocusNode notesFocusNode = FocusNode();

    notesFocusNode.addListener(() {
      if (!notesFocusNode.hasFocus) {
        Provider.of<UserStatProvider>(context, listen: false)
            .updateUserStat(id: stat.id, notes: notesController.text);
      }
    });

    return Semantics(
      identifier: 'userStatDetail_${stat.id}',
      label: 'User Stat Details',
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              identifier: 'coffeeAmount_${stat.id}',
              label: '${loc.coffeeamount}: ${stat.coffeeAmount}',
              child: Text("${loc.coffeeamount}: ${stat.coffeeAmount}",
                  style: detailTextStyle),
            ),
            Semantics(
              identifier: 'waterAmount_${stat.id}',
              label: '${loc.wateramount}: ${stat.waterAmount}',
              child: Text("${loc.wateramount}: ${stat.waterAmount}",
                  style: detailTextStyle),
            ),
            if (stat.recipeId == '106')
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      identifier: 'sweetnessStrength_${stat.id}',
                      label:
                          "${getSweeetnessLabel(stat.sweetnessSliderPosition)}, ${getStrengthLabel(stat.strengthSliderPosition)}",
                      child: Text(
                          "${getSweeetnessLabel(stat.sweetnessSliderPosition)}, ${getStrengthLabel(stat.strengthSliderPosition)}",
                          style: detailTextStyle),
                    ),
                  ),
                ],
              ),
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Divider(
                thickness: 0.5,
                indent: 20,
                endIndent: 20,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: Text(
                  loc.beans,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            if (stat.coffeeBeansId == null)
              Center(
                child: Semantics(
                  identifier: 'addBeansButton_${stat.id}',
                  label: 'Add Beans Button',
                  child: OutlinedButton(
                    onPressed: () => _openAddBeansPopup(context, stat.id),
                    child: Text(loc.addBeans),
                  ),
                ),
              )
            else
              FutureBuilder(
                future: coffeeBeansProvider
                    .fetchCoffeeBeansById(stat.coffeeBeansId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.hasData) {
                    final bean = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${loc.name}: ${bean.name}',
                            style: detailTextStyle),
                        Text('${loc.roaster}: ${bean.roaster}',
                            style: detailTextStyle),
                        Text('${loc.origin}: ${bean.origin}',
                            style: detailTextStyle),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton(
                                onPressed: () {
                                  context.router.push(
                                      CoffeeBeansDetailRoute(id: bean.id));
                                },
                                child: Text(loc.details),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () async {
                                  await userStatProvider.updateUserStat(
                                      id: stat.id, coffeeBeansId: null);
                                  Provider.of<CardExpansionNotifier>(context,
                                          listen: false)
                                      .removeBean(
                                          stat.id); // Update the notifier
                                },
                                child: Text(loc.removeBeans),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    return const Center(child: Text('No beans found'));
                  }
                },
              ),
            const Divider(
              thickness: 0.5,
              indent: 20,
              endIndent: 20,
            ),
            Center(
              child: Semantics(
                identifier: 'notesLabel_${stat.id}',
                label: loc.notes,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
                  child: Text(loc.notes,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
              ),
            ),
            Semantics(
              identifier: 'notesInputField_${stat.id}',
              label: 'Notes Input Field',
              child: TextFormField(
                controller: notesController,
                focusNode: notesFocusNode,
                maxLines: null,
                keyboardType: TextInputType.multiline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddBeansPopup(BuildContext context, int statId) {
    showDialog(
      context: context,
      builder: (context) {
        return AddCoffeeBeansWidget(
          onSelect: (int selectedBeanId) async {
            await Provider.of<UserStatProvider>(context, listen: false)
                .updateUserStat(id: statId, coffeeBeansId: selectedBeanId);
            Navigator.of(context).pop(); // Close the dialog
            Provider.of<CardExpansionNotifier>(context, listen: false)
                .addBean(statId); // Update the notifier
          },
        );
      },
    );
  }
}
