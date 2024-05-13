import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/utils/icon_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_router.gr.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_provider.dart';
import '../providers/database_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum TimePeriod { today, thisWeek, thisMonth, custom }

@RoutePage()
class StatsScreen extends StatefulWidget {
  StatsScreen({Key? key}) : super(key: key);

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  TimePeriod _selectedPeriod = TimePeriod.today;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  late DatabaseProvider db;
  double totalGlobalCoffeeBrewed = 0.0;
  double temporaryUpdates = 0.0;
  bool includesToday = true;

  DateTime _getStartDate(RecipeProvider provider, TimePeriod period) {
    switch (period) {
      case TimePeriod.today:
        return provider.getStartOfToday();
      case TimePeriod.thisWeek:
        return provider.getStartOfWeek();
      case TimePeriod.thisMonth:
        return provider.getStartOfMonth();
      case TimePeriod.custom:
        return _customStartDate ?? DateTime.now();
    }
  }

  Future<void> _showDatePickerDialog(BuildContext context) async {
    var results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.range,
      ),
      dialogSize: const Size(325, 400),
      value: [_customStartDate, _customEndDate],
      borderRadius: BorderRadius.circular(15),
    );

    if (results != null && results.length == 2) {
      setState(() {
        _customStartDate = results[0];
        _customEndDate = results[1];
        _selectedPeriod = TimePeriod.custom;
        DateTime startDate = _customStartDate ?? DateTime.now();
        DateTime endDate = _customEndDate ?? DateTime.now();
        includesToday = startDate.isBefore(DateTime.now()) &&
            endDate.isAfter(DateTime.now());
        fetchInitialTotal(startDate, endDate);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    db = Provider.of<DatabaseProvider>(context, listen: false);
    _updateTimePeriod(_selectedPeriod);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeRealtimeSubscription();
    });
  }

  bool _isDateWithinRange(DateTime date) {
    DateTime startDate = _getStartDate(
        Provider.of<RecipeProvider>(context, listen: false), _selectedPeriod);
    DateTime endDate = _selectedPeriod == TimePeriod.custom
        ? (_customEndDate ?? DateTime.now())
        : DateTime.now();
    return date.isAfter(startDate) && date.isBefore(endDate);
  }

  void initializeRealtimeSubscription() {
    final channel = Supabase.instance.client.channel('public:global_stats');
    channel
        .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'global_stats',
            callback: (payload) {
              print('Change received: ${payload.newRecord}');
              if (payload.newRecord != null &&
                  payload.newRecord['water_amount'] != null) {
                String recipeId = payload.newRecord['recipe_id'].toString();
                _showRecipeBrewedSnackbar(
                    recipeId, context); // Use correct context

                // Parse the created_at date from the payload to check if the update is within the current range
                DateTime createdAt =
                    DateTime.parse(payload.newRecord['created_at']);
                double updateAmount =
                    (payload.newRecord['water_amount'] as num) / 1000;

                // Check if the created_at date is within the selected period
                if (_isDateWithinRange(createdAt)) {
                  setState(() {
                    totalGlobalCoffeeBrewed += updateAmount;
                  });
                }
              }
            })
        .subscribe();
  }

  Future<void> _showRecipeBrewedSnackbar(
      String recipeId, BuildContext ctx) async {
    String recipeName = await Provider.of<RecipeProvider>(ctx, listen: false)
        .getLocalizedRecipeName(recipeId);
    ScaffoldMessenger.of(ctx)
        .hideCurrentSnackBar(); // Clear any existing snack bars
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(ctx)!.someoneJustBrewed(recipeName)),
        behavior: SnackBarBehavior.floating, // Make it floating
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0), // Rounded corners
        ),
        duration: const Duration(seconds: 10), // Show it for 10 seconds
        showCloseIcon: true, // Automatically include a close icon
      ),
    );
  }

  void _updateTimePeriod(TimePeriod period) {
    setState(() {
      _selectedPeriod = period;
    });
    DateTime startDate = _getStartDate(
        Provider.of<RecipeProvider>(context, listen: false), period);
    DateTime endDate = _selectedPeriod == TimePeriod.custom
        ? (_customEndDate ?? DateTime.now())
        : DateTime.now();
    includesToday =
        DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);
    fetchInitialTotal(startDate, endDate);
  }

  Future<void> fetchInitialTotal(DateTime start, DateTime end) async {
    double initialTotal = await db.fetchGlobalBrewedCoffeeAmount(start, end);
    setState(() {
      totalGlobalCoffeeBrewed =
          initialTotal + (includesToday ? temporaryUpdates : 0.0);
      temporaryUpdates = 0.0; // Discard temporary updates after applying
    });
  }

  @override
  void dispose() {
    Supabase.instance.client
        .removeAllChannels(); // Make sure to properly dispose of all subscriptions
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RecipeProvider>(context, listen: false);
    DateTime startDate = _getStartDate(provider, _selectedPeriod);
    DateTime endDate = _selectedPeriod == TimePeriod.custom
        ? (_customEndDate ?? DateTime.now())
        : DateTime.now();

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          identifier: 'statsBackButton',
          child: const BackButton(),
        ),
        title: Semantics(
          identifier: 'statsTitle',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bar_chart),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.statsscreen),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              identifier: 'statsTimePeriodSection',
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(AppLocalizations.of(context)!.statsFor,
                          style: const TextStyle(fontSize: 20)),
                    ),
                    Flexible(
                      child: Semantics(
                        identifier: 'statsTimePeriodDropdown',
                        child: DropdownButton<TimePeriod>(
                          isExpanded: true,
                          underline: Container(),
                          value: _selectedPeriod,
                          style: TextStyle(
                              fontSize: 20,
                              color: Theme.of(context).colorScheme.onBackground,
                              fontWeight: FontWeight.bold),
                          onChanged: (TimePeriod? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedPeriod = newValue;
                              });
                              if (newValue == TimePeriod.custom) {
                                _showDatePickerDialog(
                                    context); // Ensure this is called when custom is selected
                              } else {
                                // Update for other selections without showing the date picker
                                DateTime startDate = _getStartDate(
                                    Provider.of<RecipeProvider>(context,
                                        listen: false),
                                    newValue);
                                DateTime endDate = newValue == TimePeriod.custom
                                    ? (_customEndDate ?? DateTime.now())
                                    : DateTime.now();
                                includesToday =
                                    startDate.isBefore(DateTime.now()) &&
                                        endDate.isAfter(DateTime.now());
                                fetchInitialTotal(startDate, endDate);
                              }
                            }
                          },
                          items: <TimePeriod>[
                            TimePeriod.today,
                            TimePeriod.thisWeek,
                            TimePeriod.thisMonth,
                            TimePeriod.custom
                          ].map<DropdownMenuItem<TimePeriod>>(
                              (TimePeriod value) {
                            return DropdownMenuItem<TimePeriod>(
                              value: value,
                              child: Text(_formatTimePeriod(value)),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Semantics(
              identifier: 'yourStatsSection',
              child: _buildStatSection(context, provider, startDate, endDate),
            ),
            Semantics(
              identifier: 'globalStatsSection',
              child: _buildGlobalStatSection(context, startDate, endDate),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimePeriod(TimePeriod period) {
    switch (period) {
      case TimePeriod.today:
        return AppLocalizations.of(context)!.timePeriodToday;
      case TimePeriod.thisWeek:
        return AppLocalizations.of(context)!.timePeriodThisWeek;
      case TimePeriod.thisMonth:
        return AppLocalizations.of(context)!.timePeriodThisMonth;
      case TimePeriod.custom:
        return AppLocalizations.of(context)!.timePeriodCustom;
      default:
        return "";
    }
  }

  Widget _buildStatSection(BuildContext context, RecipeProvider provider,
      DateTime start, DateTime end) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            identifier: 'yourStatsHeading',
            child: Row(children: [
              const Icon(Icons.person),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.yourStats,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 8.0),
          Semantics(
            identifier: 'yourStatsCoffeeBrewedTitle',
            child: Text(AppLocalizations.of(context)!.coffeeBrewed,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Semantics(
            identifier: 'yourStatsCoffeeBrewedValue',
            child: FutureBuilder<double>(
              future: provider.fetchBrewedCoffeeAmountForPeriod(start, end),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  } else if (snapshot.hasData) {
                    final coffeeBrewed =
                        snapshot.data! / 1000; // Convert to liters
                    return Text(
                        '${coffeeBrewed.toStringAsFixed(2)} ${AppLocalizations.of(context)!.litersUnit}');
                  }
                }
                return const CircularProgressIndicator();
              },
            ),
          ),
          const SizedBox(height: 16.0),
          Semantics(
            identifier: 'yourStatsMostUsedRecipesTitle',
            child: Text(AppLocalizations.of(context)!.mostUsedRecipes,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Semantics(
            identifier: 'yourStatsMostUsedRecipes',
            child: FutureBuilder<List<String>>(
              future: provider.fetchTopRecipeIdsForPeriod(start, end),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  } else if (snapshot.data!.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: snapshot.data!
                          .map((id) => FutureBuilder<RecipeModel>(
                                future: provider.getRecipeById(id),
                                builder: (context, recipeSnapshot) {
                                  if (recipeSnapshot.connectionState ==
                                      ConnectionState.done) {
                                    if (recipeSnapshot.hasData) {
                                      Icon brewingMethodIcon =
                                          getIconByBrewingMethod(recipeSnapshot
                                              .data!.brewingMethodId);
                                      return InkWell(
                                        onTap: () => context.router.push(
                                            RecipeDetailRoute(
                                                brewingMethodId: recipeSnapshot
                                                    .data!.brewingMethodId,
                                                recipeId:
                                                    recipeSnapshot.data!.id)),
                                        child: Row(
                                          children: [
                                            brewingMethodIcon,
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                  recipeSnapshot.data!.name,
                                                  style: const TextStyle(
                                                      color: Colors.lightBlue),
                                                  overflow: TextOverflow
                                                      .ellipsis, // Ensure text does not overflow
                                                  maxLines:
                                                      2), // Allow up to two lines
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      return Text(
                                        AppLocalizations.of(context)!
                                            .unknownRecipe,
                                      );
                                    }
                                  }
                                  return const CircularProgressIndicator();
                                },
                              ))
                          .toList(),
                    );
                  } else {
                    return Text(
                      AppLocalizations.of(context)!.noData,
                    );
                  }
                }
                return const CircularProgressIndicator();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalStatSection(
      BuildContext context, DateTime start, DateTime end) {
    TextStyle titleStyle = const TextStyle(
      fontSize: 14, // Specified font size
      fontWeight: FontWeight.bold,
    );

    TextStyle headingStyle = const TextStyle(
      fontSize: 16, // Specified font size
      fontWeight: FontWeight.bold,
    );

    TextStyle valueStyle = const TextStyle(
      fontSize: 14,
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            identifier: 'globalStatsHeading',
            child: Row(children: [
              const Icon(Icons.public),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.globalStats,
                  style: headingStyle),
            ]),
          ),
          const SizedBox(height: 8.0),
          Semantics(
            identifier: 'globalStatsCoffeeBrewedTitle',
            child: Text(AppLocalizations.of(context)!.coffeeBrewed,
                style: titleStyle),
          ),
          Semantics(
            identifier: 'globalStatsCoffeeBrewedValue',
            child: Text(
                '${totalGlobalCoffeeBrewed.toStringAsFixed(2)} ${AppLocalizations.of(context)!.litersUnit}',
                style: valueStyle),
          ),
          const SizedBox(height: 16.0),
          Semantics(
            identifier: 'globalStatsMostUsedRecipesTitle',
            child: Text(AppLocalizations.of(context)!.mostUsedRecipes,
                style: titleStyle),
          ),
          Semantics(
            identifier: 'globalStatsMostUsedRecipes',
            child: FutureBuilder<List<String>>(
              future: db.fetchGlobalTopRecipes(start, end),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}", style: valueStyle);
                  } else if (snapshot.data!.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: snapshot.data!
                          .map((id) => FutureBuilder<RecipeModel>(
                                future: Provider.of<RecipeProvider>(context,
                                        listen: false)
                                    .getRecipeById(id),
                                builder: (context, recipeSnapshot) {
                                  if (recipeSnapshot.connectionState ==
                                      ConnectionState.done) {
                                    if (recipeSnapshot.hasData) {
                                      Icon brewingMethodIcon =
                                          getIconByBrewingMethod(recipeSnapshot
                                              .data!.brewingMethodId);
                                      return InkWell(
                                        onTap: () => context.router.push(
                                            RecipeDetailRoute(
                                                brewingMethodId: recipeSnapshot
                                                    .data!.brewingMethodId,
                                                recipeId:
                                                    recipeSnapshot.data!.id)),
                                        child: Row(
                                          children: [
                                            brewingMethodIcon,
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                  recipeSnapshot.data!.name,
                                                  style: const TextStyle(
                                                      color: Colors.lightBlue,
                                                      fontSize: 14),
                                                  overflow: TextOverflow
                                                      .ellipsis, // Ensure text does not overflow
                                                  maxLines:
                                                      2), // Allow up to two lines
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      return Text(
                                          AppLocalizations.of(context)!
                                              .unknownRecipe,
                                          style: valueStyle);
                                    }
                                  }
                                  return const CircularProgressIndicator();
                                },
                              ))
                          .toList(),
                    );
                  } else {
                    return Text(AppLocalizations.of(context)!.noData,
                        style: valueStyle);
                  }
                }
                return const CircularProgressIndicator();
              },
            ),
          ),
        ],
      ),
    );
  }
}
