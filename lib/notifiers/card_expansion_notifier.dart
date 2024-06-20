import 'package:flutter/foundation.dart';

class CardExpansionNotifier extends ChangeNotifier {
  Map<int, bool> expandedState = {};

  bool isExpanded(int id) => expandedState[id] ?? false;

  void toggleExpansion(int id) {
    expandedState[id] = !isExpanded(id);
    notifyListeners();
  }

  void setExpansion(int id, bool isExpanded) {
    expandedState[id] = isExpanded;
    notifyListeners();
  }

  void addBean(int id) {
    expandedState[id] = true;
    notifyListeners();
  }

  void removeBean(int id) {
    expandedState[id] = true;
    notifyListeners();
  }
}
