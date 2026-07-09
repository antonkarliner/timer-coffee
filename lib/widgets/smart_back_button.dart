import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/app_router.gr.dart';

/// A back button that navigates home when there is no route to pop back to.
/// Useful for screens reachable via deep links / direct URLs.
class SmartBackButton extends StatelessWidget {
  const SmartBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      // BackButtonIcon matches the default AppBar back button exactly,
      // including its platform-specific icon (arrow on Android, chevron on iOS).
      icon: const BackButtonIcon(),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () {
        if (context.router.canPop()) {
          context.router.maybePop();
        } else {
          context.router.replaceAll([const HomeRoute()]);
        }
      },
    );
  }
}
