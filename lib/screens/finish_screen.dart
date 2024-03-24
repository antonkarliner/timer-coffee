// lib/screens/finish_screen.dart
import 'package:coffee_timer/providers/recipe_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:advanced_in_app_review/advanced_in_app_review.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FinishScreen extends StatefulWidget {
  final String brewingMethodName;

  const FinishScreen({super.key, required this.brewingMethodName});

  @override
  State<FinishScreen> createState() => _FinishScreenState();
}

class _FinishScreenState extends State<FinishScreen> {
  late Future<String> coffeeFact;

  final AdvancedInAppReview advancedInAppReview = AdvancedInAppReview();

  @override
  void initState() {
    super.initState();

    // Assuming WakelockPlus and requestReview() remain unchanged
    WakelockPlus.enabled.then((bool wakelockEnabled) {
      if (wakelockEnabled) {
        WakelockPlus.disable();
      }
    });

    // Updated to fetch coffee fact from database via RecipeProvider
    coffeeFact = Provider.of<RecipeProvider>(context, listen: false)
        .getRandomCoffeeFactFromDB();
    requestReview();
  }

  Future<void> requestReview() async {
    if (Platform.isIOS && !kIsWeb) {
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
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.finishbrew)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${AppLocalizations.of(context)!.finishmsg} ${widget.brewingMethodName}!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            FutureBuilder<String>(
              future: coffeeFact,
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.router.push(const HomeRoute());
              },
              child: Text(AppLocalizations.of(context)!.home),
            ),
            const SizedBox(height: 20),
            if (kIsWeb || !Platform.isIOS) // Conditional statement
              ElevatedButton.icon(
                onPressed: () =>
                    _launchURL('https://www.buymeacoffee.com/timercoffee'),
                icon: const Icon(Icons.local_cafe),
                label: Text(AppLocalizations.of(context)!.support),
              ),
            if (!kIsWeb && Platform.isIOS) // New condition specifically for iOS
              ElevatedButton.icon(
                onPressed: () {
                  context.router
                      .push(const DonationRoute()); // Your routing logic
                },
                icon: const Icon(Icons.local_cafe),
                label: Text(AppLocalizations.of(context)!.support),
              ),
          ],
        ),
      ),
    );
  }
}
