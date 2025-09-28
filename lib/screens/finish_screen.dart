// lib/screens/finish_screen.dart
import 'dart:async';

import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:advanced_in_app_review/advanced_in_app_review.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:auto_route/auto_route.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_router.gr.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe_model.dart';
import '../providers/user_stat_provider.dart';
import '../providers/coffee_beans_provider.dart';
import 'package:uuid/uuid.dart';

class FinishScreen extends StatefulWidget {
  final String brewingMethodName;
  final RecipeModel recipe;
  final double waterAmount;
  final double coffeeAmount;
  final int sweetnessSliderPosition;
  final int strengthSliderPosition;

  const FinishScreen({
    super.key,
    required this.brewingMethodName,
    required this.recipe,
    required this.waterAmount,
    required this.coffeeAmount,
    required this.sweetnessSliderPosition,
    required this.strengthSliderPosition,
  });

  @override
  State<FinishScreen> createState() => _FinishScreenState();
}

class _FinishScreenState extends State<FinishScreen> {
  late Future<String> coffeeFact;
  final AdvancedInAppReview advancedInAppReview = AdvancedInAppReview();
  final Uuid _uuid = Uuid();

  @override
  void initState() {
    super.initState();

    WakelockPlus.enabled.then((bool wakelockEnabled) {
      if (wakelockEnabled) {
        WakelockPlus.disable();
      }
    });

    coffeeFact = Provider.of<RecipeProvider>(context, listen: false)
        .getRandomCoffeeFactFromDB();
    requestReview();
    insertBrewingDataToSupabase();
    insertBrewingDataToAppDatabase();
    _updateBeanWeightAfterBrew();
    requestOneSignalPermissionFirstTime();
  }

  void insertBrewingDataToSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final data = {
        'user_id': user.id,
        'brewing_method': widget.brewingMethodName,
        'recipe_id': widget.recipe.id,
        'water_amount': widget.waterAmount,
      };

      try {
        await Supabase.instance.client
            .from('global_stats')
            .insert(data)
            .timeout(const Duration(seconds: 3));
      } on TimeoutException catch (e) {
        print('Supabase request timed out: $e');
        // Optionally, handle the timeout here
      } catch (e) {
        print('Error inserting brewing data to Supabase: $e');
        // Handle other exceptions as needed
      }
    }
  }

  void insertBrewingDataToAppDatabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final statUuid = _uuid.v7();

        // Fetch the coffee beans UUID from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final coffeeBeansUuid = prefs.getString('selectedBeanUuid');

        await Provider.of<UserStatProvider>(context, listen: false)
            .insertUserStat(
          recipeId: widget.recipe.id,
          coffeeAmount: widget.coffeeAmount,
          waterAmount: widget.waterAmount,
          sweetnessSliderPosition: widget.sweetnessSliderPosition,
          strengthSliderPosition: widget.strengthSliderPosition,
          brewingMethodId: widget.recipe.brewingMethodId,
          statUuid: statUuid,
          coffeeBeansUuid: coffeeBeansUuid, // Add this line
        );
        print(
            'Inserted new stat with UUID: $statUuid and Coffee Beans UUID: $coffeeBeansUuid');
      } catch (e) {
        print("Error inserting brewing data to app database: $e");
      }
    } else {
      print('No user signed in');
    }
  }

  void _updateBeanWeightAfterBrew() async {
    try {
      // Only proceed if we have a valid coffee amount
      if (widget.coffeeAmount <= 0) {
        print('DEBUG: No coffee amount to subtract from bean weight');
        return;
      }

      // Get the selected bean UUID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final coffeeBeansUuid = prefs.getString('selectedBeanUuid');

      if (coffeeBeansUuid == null || coffeeBeansUuid.isEmpty) {
        print('DEBUG: No selected bean UUID found in SharedPreferences');
        return;
      }

      // Get the CoffeeBeansProvider from context
      final coffeeBeansProvider =
          Provider.of<CoffeeBeansProvider>(context, listen: false);

      // Update the bean weight
      final newWeight = await coffeeBeansProvider.updateBeanWeightAfterBrew(
        coffeeBeansUuid,
        widget.coffeeAmount,
      );

      if (newWeight != null) {
        print('DEBUG: Successfully updated bean weight to ${newWeight}g');
      } else {
        print('DEBUG: Bean weight update failed or was not applicable');
      }
    } catch (e) {
      print('DEBUG: Error updating bean weight: $e');
    }
  }

  void requestOneSignalPermissionFirstTime() async {
    const firstFinishScreenKey = 'firstfinishscreen';
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool firstFinishScreen = prefs.getBool(firstFinishScreenKey) ?? true;

    if (firstFinishScreen) {
      if (!kIsWeb) {
        OneSignal.Notifications.requestPermission(true);
      }
      await prefs.setBool(firstFinishScreenKey, false);
    }
  }

  Future<void> requestReview() async {
    if (!kIsWeb) {
      advancedInAppReview
          .setMinDaysBeforeRemind(7)
          .setMinDaysAfterInstall(2)
          .setMinLaunchTimes(2)
          .setMinSecondsBeforeShowDialog(4);
      advancedInAppReview.monitor();
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: false, forceWebView: false);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          identifier: 'finishBrewTitle',
          child: Text(AppLocalizations.of(context)!.finishbrew),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              identifier: 'finishMessage',
              child: Text(
                '${AppLocalizations.of(context)!.finishmsg} ${widget.brewingMethodName}!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(height: 20),
            Semantics(
              identifier: 'coffeeFactCard',
              child: FutureBuilder<String>(
                future: coffeeFact,
                builder:
                    (BuildContext context, AsyncSnapshot<String> snapshot) {
                  if (snapshot.hasData) {
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: <TextSpan>[
                              TextSpan(
                                text:
                                    '${AppLocalizations.of(context)!.coffeefact}: ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              TextSpan(
                                  text: '${snapshot.data}',
                                  style: const TextStyle(fontSize: 20)),
                            ],
                          ),
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            Semantics(
              identifier: 'homeButton',
              child: ElevatedButton(
                onPressed: () {
                  context.router.push(const HomeRoute());
                },
                child: Text(AppLocalizations.of(context)!.home),
              ),
            ),
            const SizedBox(height: 20),
            if (kIsWeb || !Platform.isIOS)
              Semantics(
                identifier: 'buyMeACoffeeButton',
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _launchURL('https://www.buymeacoffee.com/timercoffee'),
                  icon: const Icon(Icons.local_cafe),
                  label: Text(AppLocalizations.of(context)!.support),
                ),
              )
            else if (!kIsWeb && Platform.isIOS)
              Semantics(
                identifier: 'supportButton',
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.router.push(const DonationRoute());
                  },
                  icon: const Icon(Icons.local_cafe),
                  label: Text(AppLocalizations.of(context)!.support),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
