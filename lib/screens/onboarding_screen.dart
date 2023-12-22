import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class OnboardingScreen extends StatelessWidget {
  final List<PageViewModel> listPagesViewModel = [
    PageViewModel(
      title: "Welcome to Timer.Coffee",
      body: "Swipe for some useful tips about brewing coffee with this app.",
      image: _buildImage('intro1'), // Replace with your image path
      decoration: const PageDecoration(
        titleTextStyle: TextStyle(
            color: Color.fromRGBO(121, 85, 72, 1),
            fontSize: 28,
            fontWeight: FontWeight.bold),
        bodyTextStyle: TextStyle(fontSize: 20, color: Colors.black),
      ),
    ),
    PageViewModel(
      title: "Brew as much coffee as you need",
      body:
          "Simply adjust the values on the recipe page. All the brewing steps will update accordingly.",
      image: _buildImage('intro2', isGif: true), // Replace with your image path
      decoration: const PageDecoration(
        titleTextStyle: TextStyle(
            color: Color.fromRGBO(121, 85, 72, 1),
            fontSize: 28,
            fontWeight: FontWeight.bold),
        bodyTextStyle: TextStyle(fontSize: 20, color: Colors.black),
      ),
    ),
    PageViewModel(
      title: "Turn on sound chime",
      body:
          "Get notified about the next brewing steps. Useful when you use recipes with long brewing steps and don't want to look at your phone all the time.",
      image: _buildImage('intro3', isGif: true), // Replace with your image path
      decoration: const PageDecoration(
        titleTextStyle: TextStyle(
            color: Color.fromRGBO(121, 85, 72, 1),
            fontSize: 28,
            fontWeight: FontWeight.bold),
        bodyTextStyle: TextStyle(fontSize: 20, color: Colors.black),
      ),
    ),
    PageViewModel(
      title: "Share recipes with friends",
      body:
          "Send them the recipe link. They will be able to open it and brew even if they don't have the app installed.",
      image: _buildImage('intro4'), // Replace with your image path
      decoration: const PageDecoration(
        titleTextStyle: TextStyle(
            color: Color.fromRGBO(121, 85, 72, 1),
            fontSize: 28,
            fontWeight: FontWeight.bold),
        bodyTextStyle: TextStyle(fontSize: 20, color: Colors.black),
      ),
    ),
    // Add as many pages as you require
  ];

  static Widget _buildImage(String assetName, {bool isGif = false}) {
    if (isGif) {
      return Image.asset('assets/onboarding/gifs/$assetName.gif',
          fit: BoxFit.cover);
    } else {
      // Set different image paths for iOS and Android
      if (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS) {
        assetName = 'assets/onboarding/ios/$assetName.png';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        assetName = 'assets/onboarding/android/$assetName.png';
      }
      return Image.asset(assetName, fit: BoxFit.cover);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: IntroductionScreen(
          pages: listPagesViewModel,
          onDone: () {
            // Go to home screen when done button is pressed
            context.router.replaceNamed('/');
          },
          onSkip: () {
            // Go to home screen when skip button is pressed
            context.router.replaceNamed('/');
          },
          showSkipButton: true,
          skip: const Text('Skip'),
          next: const Text('Next'),
          done: const Text('Start brewing',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color.fromRGBO(121, 85, 72, 1))),
          dotsDecorator: const DotsDecorator(
            size: Size.square(10.0),
            activeColor: Color.fromRGBO(121, 85, 72, 1),
            activeSize: Size.square(20.0),
            activeShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(25.0))),
          ),
        ),
      ),
    );
  }
}
