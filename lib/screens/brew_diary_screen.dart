import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/app_router.gr.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/user_stat_provider.dart';
import '../providers/coffee_beans_provider.dart';
import '../models/user_stat_model.dart';
import 'package:intl/intl.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../utils/icon_utils.dart';
import '../widgets/add_coffee_beans_widget.dart';
import '../widgets/expandable_card.dart';
import '../notifiers/card_expansion_notifier.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../models/coffee_beans_model.dart';
import '../widgets/roaster_logo.dart';

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

  Widget _buildGroupedList(List<UserStatsModel> stats) {
    final loc = AppLocalizations.of(context)!;

    // Group stats by date
    Map<String, List<UserStatsModel>> groupedStats = {};
    DateFormat dateFormat = DateFormat(
      loc.dateFormat,
      Localizations.localeOf(context).toString(),
    );

    for (var stat in stats) {
      String dateKey = dateFormat.format(stat.createdAt.toLocal());
      if (!groupedStats.containsKey(dateKey)) {
        groupedStats[dateKey] = [];
      }
      groupedStats[dateKey]!.add(stat);
    }

    // Sort dates in descending order (newest first)
    List<String> sortedDates = groupedStats.keys.toList();
    sortedDates.sort((a, b) {
      DateTime dateA =
          DateFormat(loc.dateFormat, Localizations.localeOf(context).toString())
              .parse(a);
      DateTime dateB =
          DateFormat(loc.dateFormat, Localizations.localeOf(context).toString())
              .parse(b);
      return dateB.compareTo(dateA); // Descending order
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _calculateTotalItems(groupedStats, sortedDates),
      itemBuilder: (context, index) {
        return _buildListItem(groupedStats, sortedDates, index);
      },
    );
  }

  int _calculateTotalItems(Map<String, List<UserStatsModel>> groupedStats,
      List<String> sortedDates) {
    int totalItems = 0;
    for (String date in sortedDates) {
      totalItems += 1; // Date separator
      totalItems += groupedStats[date]!.length; // Cards for that date
    }
    return totalItems;
  }

  Widget _buildListItem(Map<String, List<UserStatsModel>> groupedStats,
      List<String> sortedDates, int index) {
    int currentIndex = 0;

    for (String date in sortedDates) {
      // Check if this index is the date separator
      if (currentIndex == index) {
        return _buildDateSeparator(date);
      }
      currentIndex++;

      // Check if this index is one of the cards for this date
      List<UserStatsModel> statsForDate = groupedStats[date]!;
      for (int i = 0; i < statsForDate.length; i++) {
        if (currentIndex == index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: buildUserStatCard(context, statsForDate[i]),
          );
        }
        currentIndex++;
      }
    }

    // Fallback (should not happen)
    return const SizedBox.shrink();
  }

  Widget _buildDateSeparator(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          const Expanded(
            child: Divider(
              thickness: 1,
              color: Colors.grey,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              date,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          const Expanded(
            child: Divider(
              thickness: 1,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
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
              return _buildGroupedList(snapshot.data!);
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
    final databaseProvider = Provider.of<DatabaseProvider>(
        context); // Ensure this provider is available
    DateFormat dateFormat = DateFormat(
      '${loc.dateFormat} ${loc.timeFormat}',
      Localizations.localeOf(context).toString(),
    );

    return FutureBuilder<List<String>>(
      future: Future.wait([
        recipeProvider.getBrewingMethodName(stat.brewingMethodId),
        recipeProvider.getLocalizedRecipeName(stat.recipeId),
      ]),
      builder: (context, namesSnapshot) {
        if (namesSnapshot.hasData) {
          return Semantics(
            key: ValueKey(stat.statUuid),
            identifier: 'userStatCard_${stat.statUuid}',
            label: '${namesSnapshot.data![1]}, ${namesSnapshot.data![0]}',
            child: Consumer<CardExpansionNotifier>(
              builder: (context, notifier, _) {
                bool isExpanded = notifier.isExpanded(stat.statUuid);
                return ExpandableCard(
                  key: ValueKey(stat.statUuid),
                  leading: getIconByBrewingMethod(stat.brewingMethodId),
                  header: namesSnapshot.data![1],
                  subtitle:
                      "${namesSnapshot.data![0]} - ${dateFormat.format(stat.createdAt.toLocal())}",
                  detail: buildDetail(context, stat),
                  trailing: isEditMode
                      ? Semantics(
                          identifier: 'deleteUserStatButton_${stat.statUuid}',
                          child: IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.red),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => ConfirmDeleteDialog(
                                  title: AppLocalizations.of(context)!
                                      .confirmDeleteTitle,
                                  content: AppLocalizations.of(context)!
                                      .confirmDeleteMessage,
                                  confirmLabel:
                                      AppLocalizations.of(context)!.delete,
                                  cancelLabel:
                                      AppLocalizations.of(context)!.cancel,
                                ),
                              );
                              if (confirmed == true) {
                                await userStatProvider
                                    .deleteUserStat(stat.statUuid);
                                notifier.setExpansion(stat.statUuid, false);
                              }
                            },
                          ),
                        )
                      : null,
                  isExpanded: isExpanded,
                  onExpansionChanged: (bool expanded) {
                    notifier.setExpansion(stat.statUuid, expanded);
                  },
                );
              },
            ),
          );
        } else if (namesSnapshot.connectionState == ConnectionState.waiting) {
          return Semantics(
            identifier: 'brewDiaryCardLoading_${stat.statUuid}',
            label: 'Loading User Stat Card',
            child: const Card(child: ListTile(title: Text("Loading..."))),
          );
        } else {
          return Semantics(
            identifier: 'brewDiaryCardError_${stat.statUuid}',
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
    final databaseProvider = Provider.of<DatabaseProvider>(context);

    TextEditingController notesController =
        TextEditingController(text: stat.notes);
    FocusNode notesFocusNode = FocusNode();

    notesFocusNode.addListener(() {
      if (!notesFocusNode.hasFocus) {
        Provider.of<UserStatProvider>(context, listen: false).updateUserStat(
            statUuid: stat.statUuid, notes: notesController.text);
      }
    });

    return Semantics(
      identifier: 'userStatDetail_${stat.statUuid}',
      label: 'User Stat Details',
      child: Padding(
        padding:
            const EdgeInsets.all(16.0), // Increased padding for better spacing
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align children to start
          children: [
            // Coffee Amount
            Semantics(
              identifier: 'coffeeAmount_${stat.statUuid}',
              label: '${loc.coffeeamount}: ${stat.coffeeAmount}',
              child: Text("${loc.coffeeamount}: ${stat.coffeeAmount}",
                  style: detailTextStyle),
            ),
            const SizedBox(height: 8), // Added spacing between elements
            // Water Amount
            Semantics(
              identifier: 'waterAmount_${stat.id}',
              label: '${loc.wateramount}: ${stat.waterAmount}',
              child: Text("${loc.wateramount}: ${stat.waterAmount}",
                  style: detailTextStyle),
            ),
            const SizedBox(height: 8),
            // Sweetness and Strength (if applicable)
            if (stat.recipeId == '106')
              Semantics(
                identifier: 'sweetnessStrength_${stat.id}',
                label:
                    "${getSweeetnessLabel(stat.sweetnessSliderPosition)}, ${getStrengthLabel(stat.strengthSliderPosition)}",
                child: Text(
                    "${getSweeetnessLabel(stat.sweetnessSliderPosition)}, ${getStrengthLabel(stat.strengthSliderPosition)}",
                    style: detailTextStyle,
                    textAlign: TextAlign.start),
              ),
            const SizedBox(height: 8),
            // Divider
            const Divider(
              thickness: 0.5,
              indent: 10,
              endIndent: 10,
            ),
            const SizedBox(height: 8),
            // Beans Section Title
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                loc.beans,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            // Beans Details or Selection Button
            if (stat.coffeeBeansUuid == null)
              Center(
                child: Semantics(
                  identifier: 'selectBeansButton_${stat.statUuid}',
                  label: 'Select Beans Button',
                  child: OutlinedButton(
                    onPressed: () => _openAddBeansPopup(context, stat.statUuid),
                    child: Text(loc.selectBeans),
                  ),
                ),
              )
            else
              FutureBuilder<CoffeeBeansModel?>(
                future: coffeeBeansProvider
                    .fetchCoffeeBeansByUuid(stat.coffeeBeansUuid!),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.hasData && snapshot.data != null) {
                    final bean = snapshot.data!;
                    return FutureBuilder<Map<String, String?>>(
                      future: databaseProvider
                          .fetchCachedRoasterLogoUrls(bean.roaster),
                      builder: (context, logoSnapshot) {
                        const double logoHeight = 80.0;
                        const double maxWidthFactor = 2.0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Row with logo and details
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minHeight: logoHeight,
                                          maxHeight: logoHeight,
                                          minWidth: logoHeight,
                                          maxWidth: logoHeight * maxWidthFactor,
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.contain,
                                          alignment: Alignment.centerLeft,
                                          child: FutureBuilder<
                                              Map<String, String?>>(
                                            future: databaseProvider
                                                .fetchCachedRoasterLogoUrls(
                                                    bean.roaster),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                final originalUrl =
                                                    snapshot.data!['original'];
                                                final mirrorUrl =
                                                    snapshot.data!['mirror'];
                                                if (originalUrl != null ||
                                                    mirrorUrl != null) {
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
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('${loc.name}: ${bean.name}',
                                                style: detailTextStyle),
                                            const SizedBox(height: 4),
                                            Text(
                                                '${loc.roaster}: ${bean.roaster}',
                                                style: detailTextStyle),
                                            const SizedBox(height: 4),
                                            Text(
                                                '${loc.origin}: ${bean.origin}',
                                                style: detailTextStyle),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Buttons Row
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () {
                                        context.router.push(
                                          CoffeeBeansDetailRoute(
                                              uuid: bean.beansUuid!),
                                        );
                                      },
                                      child: Text(loc.details),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: () async {
                                        print(
                                            'Remove beans button pressed for stat: ${stat.statUuid}');
                                        print(
                                            'Current coffeeBeansUuid: ${stat.coffeeBeansUuid}');
                                        await Provider.of<UserStatProvider>(
                                                context,
                                                listen: false)
                                            .updateUserStat(
                                          statUuid: stat.statUuid,
                                          coffeeBeansUuid: null,
                                        );
                                        print('updateUserStat called');
                                        setState(() {
                                          print(
                                              'setState called to rebuild widget');
                                        });
                                      },
                                      child: Text(loc.removeBeans),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  } else {
                    return const Center(child: Text('No beans found'));
                  }
                },
              ),
            const Divider(
              thickness: 0.5,
              indent: 10,
              endIndent: 10,
            ),
            const SizedBox(height: 8),
            // Notes Section
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
              child: Text(
                loc.notes,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Semantics(
              identifier: 'notesInputField_${stat.statUuid}',
              label: 'Notes Input Field',
              child: TextFormField(
                initialValue: stat.notes,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                onChanged: (value) {
                  // Debounce the updates to avoid too many calls
                  Future.delayed(const Duration(milliseconds: 2000), () {
                    Provider.of<UserStatProvider>(context, listen: false)
                        .updateUserStat(
                      statUuid: stat.statUuid,
                      notes: value,
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddBeansPopup(BuildContext context, String statUuid) {
    showDialog(
      context: context,
      builder: (context) {
        return AddCoffeeBeansWidget(
          onSelect: (String selectedBeanUuid) async {
            await Provider.of<UserStatProvider>(context, listen: false)
                .updateUserStat(
              statUuid: statUuid,
              coffeeBeansUuid: selectedBeanUuid,
            );
            Navigator.of(context).pop(); // Close the dialog
            Provider.of<CardExpansionNotifier>(context, listen: false)
                .addBean(statUuid); // Update the notifier
          },
        );
      },
    );
  }
}
