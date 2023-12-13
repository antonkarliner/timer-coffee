import 'dart:math';

import 'package:flutter/material.dart';

class SnowWidget extends StatefulWidget {
  final int totalSnow;
  final double speed;
  final bool isRunning;
  final Brightness themeBrightness; // Add this line

  const SnowWidget({
    required Key key,
    required this.totalSnow,
    required this.speed,
    required this.isRunning,
    required this.themeBrightness, // Add this line
  }) : super(key: key);

  @override
  _SnowWidgetState createState() => _SnowWidgetState();
}

class _SnowWidgetState extends State<SnowWidget>
    with SingleTickerProviderStateMixin {
  late Random _rnd;
  late AnimationController controller;
  late Animation animation;
  late List<Snow> _snows;
  double angle = 0;
  double W = 0;
  double H = 0;

  @override
  void initState() {
    super.initState();
    _rnd = Random();
    _snows = List<Snow>.empty(growable: true); // Initialize _snows

    // Initialize controller
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 20000),
    )..addListener(() {
        if (mounted) {
          setState(() {
            update();
          });
        }
      });

    // Start or stop the animation based on isRunning
    if (widget.isRunning) {
      controller.repeat();
    } else {
      controller.stop();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _createSnow() {
    _snows = List<Snow>.empty(growable: true);
    for (var i = 0; i < widget.totalSnow; i++) {
      _snows.add(Snow(
        x: _rnd.nextDouble() * W,
        y: _rnd.nextDouble() * H,
        r: _rnd.nextDouble() * 4 + 1,
        d: _rnd.nextDouble() * widget.speed,
      ));
    }
  }

  update() {
    angle += 0.01;
    for (var i = 0; i < widget.totalSnow; i++) {
      var snow = _snows[i];
      snow.y += (cos(angle + snow.d) + 1 + snow.r / 2) * widget.speed;
      snow.x += sin(angle) * 2 * widget.speed;

      // Reset snowflake position when it moves out of view
      if (snow.x > W + 5 || snow.x < -5 || snow.y > H) {
        snow.x = _rnd.nextDouble() * W;
        snow.y = -10;
        snow.r = _rnd.nextDouble() * 4 + 1;
        snow.d = _rnd.nextDouble() * widget.speed;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        W = constraints.maxWidth;
        H = constraints.maxHeight;
        if (_snows.isEmpty) {
          _createSnow();
        }
        return CustomPaint(
          willChange: widget.isRunning,
          painter: SnowPainter(
            isRunning: widget.isRunning,
            snows: _snows,
            themeBrightness: widget.themeBrightness,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class Snow {
  double x;
  double y;
  double r; //radius
  double d; //density
  Snow({required this.x, required this.y, required this.r, required this.d});
}

class SnowPainter extends CustomPainter {
  List<Snow> snows;
  bool isRunning;
  Brightness themeBrightness; // Add this line

  SnowPainter({
    required this.isRunning,
    required this.snows,
    required this.themeBrightness, // Add this line
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isRunning) return;

    // Set snowflake color based on theme brightness
    Color snowColor =
        themeBrightness == Brightness.dark ? Colors.white : Colors.grey[300]!;

    final Paint paint = Paint()
      ..color = snowColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10.0;

    for (var i = 0; i < snows.length; i++) {
      var snow = snows[i];
      canvas.drawCircle(Offset(snow.x, snow.y), snow.r, paint);
    }
  }

  @override
  bool shouldRepaint(SnowPainter oldDelegate) => isRunning;
}
