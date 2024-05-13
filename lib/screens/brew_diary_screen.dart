import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../models/user_stat_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/autocomplete_input_field.dart';
import '../utils/icon_utils.dart';
import '../widgets/expandable_card.dart';

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
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
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
        future: recipeProvider.fetchAllUserStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Semantics(
                identifier: 'brewDiaryLoading',
                label: 'Loading',
                child: const CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
                child: Semantics(
              identifier: 'brewDiaryError',
              label: 'Error',
              child: Text("Error: ${snapshot.error}"),
            ));
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
                return buildUserStatCard(context, stat, index);
              },
            );
          } else {
            return Center(
                child: Semantics(
              identifier: 'brewDiaryEmptyFallback',
              label: loc.brewdiarynotfound,
              child: Text(loc.brewdiarynotfound),
            ));
          }
        },
      ),
    );
  }

  Widget buildUserStatCard(
      BuildContext context, UserStatsModel stat, int index) {
    final loc = AppLocalizations.of(context)!;
    final recipeProvider = Provider.of<RecipeProvider>(context);
    DateFormat dateFormat = DateFormat('${loc.dateFormat} ${loc.timeFormat}',
        Localizations.localeOf(context).toString());

    return FutureBuilder<List<String>>(
      future: Future.wait([
        recipeProvider.getBrewingMethodName(stat.brewingMethodId),
        recipeProvider.getLocalizedRecipeName(stat.recipeId),
      ]),
      builder: (context, namesSnapshot) {
        if (namesSnapshot.connectionState == ConnectionState.waiting) {
          return Semantics(
            identifier: 'brewDiaryCardLoading_$index',
            label: 'Loading User Stat Card',
            child: const Card(child: ListTile(title: Text("Loading..."))),
          );
        } else if (namesSnapshot.hasData) {
          return Semantics(
            identifier: 'userStatCard_$index',
            label: '${namesSnapshot.data![1]}, ${namesSnapshot.data![0]}',
            child: ExpandableCard(
              leading: getIconByBrewingMethod(stat.brewingMethodId),
              header: namesSnapshot.data![1],
              subtitle:
                  "${namesSnapshot.data![0]} - ${dateFormat.format(stat.createdAt.toLocal())}",
              detail: buildDetail(context, stat),
              trailing: isEditMode
                  ? Semantics(
                      identifier: 'deleteUserStatButton_$index',
                      child: IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red),
                        onPressed: () async {
                          await recipeProvider.deleteUserStat(stat.id);
                          setState(() {});
                        },
                      ),
                    )
                  : null,
            ),
          );
        } else {
          return Semantics(
            identifier: 'brewDiaryCardError_$index',
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
    final recipeProvider = Provider.of<RecipeProvider>(context);

    TextEditingController notesController =
        TextEditingController(text: stat.notes);
    FocusNode notesFocusNode = FocusNode();

    notesFocusNode.addListener(() {
      if (!notesFocusNode.hasFocus) {
        Provider.of<RecipeProvider>(context, listen: false)
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
            Semantics(
              identifier: 'roasterAutocomplete_${stat.id}',
              label: loc.roaster,
              child: AutocompleteInputField(
                label: loc.roaster,
                hintText: loc.roaster,
                initialOptions: recipeProvider.fetchAllDistinctRoasters(),
                onSelected: (value) {
                  recipeProvider.updateUserStat(id: stat.id, roaster: value);
                },
                initialValue: stat.roaster,
              ),
            ),
            Semantics(
              identifier: 'beansAutocomplete_${stat.id}',
              label: loc.beans,
              child: AutocompleteInputField(
                label: loc.beans,
                hintText: loc.beans,
                initialOptions: recipeProvider.fetchAllDistinctBeans(),
                onSelected: (value) {
                  recipeProvider.updateUserStat(id: stat.id, beans: value);
                },
                initialValue: stat.beans,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
