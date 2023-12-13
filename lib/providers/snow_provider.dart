import 'package:flutter/material.dart';

class SnowEffectProvider with ChangeNotifier {
  bool _isSnowing = false;

  bool get isSnowing => _isSnowing;

  void toggleSnowEffect() {
    _isSnowing = !_isSnowing;
    notifyListeners();
  }
}
