// lib/screens/finish_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class FinishScreen extends StatefulWidget {
  final String brewingMethodName;

  FinishScreen({required this.brewingMethodName});

  @override
  _FinishScreenState createState() => _FinishScreenState();
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
    final int lastFactIndex = prefs.getInt('lastFactIndex') ?? -1;
    final int nextFactIndex =
        (lastFactIndex + 1 + Random().nextInt(coffeeFactsList.length - 1)) %
            coffeeFactsList.length;

    prefs.setInt('lastFactIndex', nextFactIndex);
    return coffeeFactsList[nextFactIndex];
  }

  Future<void> requestReview() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final DateTime firstUsageDate = DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt('firstUsageDate') ??
            DateTime.now().millisecondsSinceEpoch);
    final DateTime lastRequestedReview = DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt('lastRequestedReview') ?? 0);
    final DateTime now = DateTime.now();

    final List<int> reviewSchedule = [
      10,
      30,
      180,
      375,
      405,
      440,
      480,
      525
    ]; // Days after first usage

    for (int days in reviewSchedule) {
      DateTime reviewDate = firstUsageDate.add(Duration(days: days));

      if (now.isAfter(reviewDate) &&
          lastRequestedReview.isBefore(reviewDate) &&
          await inAppReview.isAvailable()) {
        inAppReview.requestReview();
        await prefs.setInt('lastRequestedReview', now.millisecondsSinceEpoch);
        break; // Exit the loop once a review has been requested
      }
    }
  }

  @override
  void initState() {
    super.initState();
    coffeeFact = getRandomCoffeeFact();
    requestReview();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Finish')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Thanks for using Timer.Coffee! Enjoy your ${widget.brewingMethodName}!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            FutureBuilder<String>(
              future: coffeeFact,
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.hasData) {
                  return Card(
                    margin: EdgeInsets.all(10),
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: <TextSpan>[
                            TextSpan(
                                text: 'Coffee Fact: ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20)),
                            TextSpan(
                                text: '${snapshot.data}',
                                style: TextStyle(fontSize: 20)),
                          ],
                        ),
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, ModalRoute.withName('/'));
              },
              child: Text('Home'),
            ),
          ],
        ),
      ),
    );
  }
}
