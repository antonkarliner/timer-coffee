// lib/screens/finish_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart';
import 'package:url_launcher/url_launcher.dart';

class FinishScreen extends StatefulWidget {
  final String brewingMethodName;

  const FinishScreen({super.key, required this.brewingMethodName});

  @override
  State<FinishScreen> createState() => _FinishScreenState();
}

class _FinishScreenState extends State<FinishScreen> {
  late Future<String> coffeeFact;

  final InAppReview inAppReview = InAppReview.instance;

  Future<String> getRandomCoffeeFact() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String coffeeFactsString =
        await rootBundle.loadString('assets/data/coffee_facts.json');
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

  Future<void> requestReview() async {
    if (await inAppReview.isAvailable()) {
      inAppReview.requestReview();
    }
  }

  @override
  void initState() {
    super.initState();
    coffeeFact = getRandomCoffeeFact();
    requestReview();
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
      appBar: AppBar(title: const Text('Finish')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Thanks for using Timer.Coffee! Enjoy your ${widget.brewingMethodName}!',
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
                            const TextSpan(
                                text: 'Coffee Fact: ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20)),
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
              child: const Text('Home'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () =>
                  _launchURL('https://www.buymeacoffee.com/timercoffee'),
              icon: const Icon(Icons.local_cafe),
              label: const Text('Buy me a coffee'),
            ),
          ],
        ),
      ),
    );
  }
}
