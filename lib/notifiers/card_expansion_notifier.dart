import 'package:flutter/foundation.dart';

class CardExpansionNotifier extends ChangeNotifier {
  Map<String, bool> expandedState = {};

  bool isExpanded(String statUuid) => expandedState[statUuid] ?? false;

  void toggleExpansion(String statUuid) {
    expandedState[statUuid] = !isExpanded(statUuid);
    notifyListeners();
  }

  void setExpansion(String statUuid, bool isExpanded) {
    expandedState[statUuid] = isExpanded;
    notifyListeners();
  }

  void addBean(String statUuid) {
    expandedState[statUuid] = true;
    notifyListeners();
  }

  void removeBean(String statUuid) {
    expandedState[statUuid] = true;
    notifyListeners();
  }
}
