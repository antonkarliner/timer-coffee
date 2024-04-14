import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../providers/recipe_provider.dart';
import '../models/user_stat_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/expandable_card.dart';
import '../widgets/autocomplete_input_field.dart';
import '../utils/icon_utils.dart';

@RoutePage()
class BrewDiaryScreen extends StatefulWidget {
  const BrewDiaryScreen({Key? key}) : super(key: key);

  @override
  _BrewDiaryScreenState createState() => _BrewDiaryScreenState();
}

class _BrewDiaryScreenState extends State<BrewDiaryScreen> {
  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.brewdiary),
      ),
      body: FutureBuilder<List<UserStatsModel>>(
        future: recipeProvider.fetchAllUserStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                UserStatsModel stat = snapshot.data![index];
                return FutureBuilder<List<String>>(
                  future: Future.wait([
                    recipeProvider.getBrewingMethodName(stat.brewingMethodId),
                    recipeProvider.getLocalizedRecipeName(stat.recipeId),
                  ]),
                  builder: (context, namesSnapshot) {
                    if (namesSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Card(
                          child: ListTile(title: Text("Loading...")));
                    } else if (namesSnapshot.hasData) {
                      DateFormat dateFormat = DateFormat(
                          '${loc.dateFormat} ${loc.timeFormat}',
                          Localizations.localeOf(context).toString());
                      return ExpandableCard(
                        leading: getIconByBrewingMethod(stat.brewingMethodId),
                        header: namesSnapshot.data![1],
                        subtitle:
                            "${namesSnapshot.data![0]} - ${dateFormat.format(stat.createdAt.toLocal())}",
                        detail: buildDetail(context, stat),
                      );
                    } else {
                      return const Card(
                          child:
                              ListTile(title: Text("Error fetching records")));
                    }
                  },
                );
              },
            );
          } else {
            return Center(child: Text(loc.brewdiarynotfound));
          }
        },
      ),
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

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${loc.coffeeamount}: ${stat.coffeeAmount}",
              style: detailTextStyle),
          Text("${loc.wateramount}: ${stat.waterAmount}",
              style: detailTextStyle),
          TextFormField(
            controller: notesController,
            focusNode: notesFocusNode,
            decoration: InputDecoration(labelText: loc.notes),
            maxLines: null,
            keyboardType: TextInputType.multiline,
          ),
          AutocompleteInputField(
            label: loc.roaster,
            hintText: loc.roaster,
            initialOptions: recipeProvider.fetchAllDistinctRoasters(),
            onSelected: (value) {
              recipeProvider.updateUserStat(id: stat.id, roaster: value);
            },
            initialValue: stat.roaster, // Add the initial value here
          ),
          AutocompleteInputField(
            label: loc.beans,
            hintText: loc.beans,
            initialOptions: recipeProvider.fetchAllDistinctBeans(),
            onSelected: (value) {
              recipeProvider.updateUserStat(id: stat.id, beans: value);
            },
            initialValue: stat.beans, // Add the initial value here
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: RatingBar.builder(
              initialRating: stat.rating ?? 0.0,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 30.0,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Colors.brown),
              onRatingUpdate: (rating) {
                recipeProvider.updateUserStat(id: stat.id, rating: rating);
              },
            ),
          ),
        ],
      ),
    );
  }
}