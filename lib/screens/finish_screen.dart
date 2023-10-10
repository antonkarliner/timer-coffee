// lib/screens/finish_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
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

  Future<String> getRandomCoffeeFact() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Locale locale = Localizations.localeOf(context);
    final String localizedFilePath =
        'assets/data/${locale.languageCode}/coffee_facts.json';

    final String coffeeFactsString =
        await rootBundle.loadString(localizedFilePath);
    final List<String> coffeeFactsList =
        List<String>.from(jsonDecode(coffeeFactsString));

    List<int> shownFactsIndices =
        (prefs.getStringList('shownFactsIndices') ?? [])
            .map(int.parse)
            .toList();

    if (shownFactsIndices.length == coffeeFactsList.length) {
      shownFactsIndices = [];
    }

    List<int> unseenFactsIndices =
        List<int>.generate(coffeeFactsList.length, (i) => i)
          ..removeWhere((index) => shownFactsIndices.contains(index));

    final int nextFactIndex =
        unseenFactsIndices[Random().nextInt(unseenFactsIndices.length)];
    shownFactsIndices.add(nextFactIndex);

    prefs.setStringList('shownFactsIndices',
        shownFactsIndices.map((i) => i.toString()).toList());

    return coffeeFactsList[nextFactIndex];
  }

  @override
  void initState() {
    super.initState();

    WakelockPlus.enabled.then((bool wakelockEnabled) {
      if (wakelockEnabled) {
        WakelockPlus.disable();
      }
    });

    coffeeFact = getRandomCoffeeFact();
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
