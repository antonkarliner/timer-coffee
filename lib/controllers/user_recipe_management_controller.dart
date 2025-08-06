import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Controller for the User Recipe Management screen.
/// Holds edit mode state and an optional scroll controller for UI behaviors.
class UserRecipeManagementController extends ChangeNotifier {
  final ValueNotifier<bool> editMode = ValueNotifier<bool>(false);
  final ScrollController scrollController = ScrollController();

  void toggleEdit() {
    editMode.value = !editMode.value;
    // Notify external listeners in case they rely on ChangeNotifier
    notifyListeners();
  }

  @override
  void dispose() {
    editMode.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
