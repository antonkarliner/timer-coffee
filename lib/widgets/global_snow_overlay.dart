import 'package:coffee_timer/widgets/snow_widget.dart';
import 'package:flutter/material.dart';

class GlobalSnowOverlay extends StatelessWidget {
  final bool isSnowing;
  const GlobalSnowOverlay({Key? key, required this.isSnowing})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isSnowing) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: SnowWidget(
          key: UniqueKey(),
          totalSnow: 30,
          speed: 0.5,
          isRunning: isSnowing,
          themeBrightness: Theme.of(context).brightness,
        ),
      ),
    );
  }
}
