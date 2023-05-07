// lib/screens/finish_screen.dart
import 'package:flutter/material.dart';

class FinishScreen extends StatelessWidget {
  final String brewingMethodName;

  FinishScreen({required this.brewingMethodName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Finish')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Thanks for using coffee timer! Enjoy your $brewingMethodName!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24),
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
