import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/ui_state/coffee_beans_view_state.dart';

/// Animated bottom app bar for the coffee beans screen with hide-on-scroll functionality.
///
/// This widget contains filter and edit mode buttons and uses the [CoffeeBeansViewState]
/// model for visibility state management. It follows the callback pattern for
/// parent-child communication.
class CoffeeBeansBottomBar extends StatelessWidget {
  /// Current view state containing visibility and edit mode state
  final CoffeeBeansViewState viewState;

  /// Callback when filter button is pressed
  final VoidCallback onFilterPressed;

  /// Callback when edit mode is toggled
  final VoidCallback onEditModeToggled;

  /// The lift amount for the bottom bar (typically half the ConvexAppBar height plus bottom inset)
  final double lift;

  const CoffeeBeansBottomBar({
    Key? key,
    required this.viewState,
    required this.onFilterPressed,
    required this.onEditModeToggled,
    required this.lift,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: viewState.isBottomBarVisible ? kBottomNavigationBarHeight : 0,
        margin: EdgeInsets.only(
          bottom: viewState.isBottomBarVisible ? lift : 0,
        ),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(
                    Theme.of(context).brightness == Brightness.dark ? 31 : 20,
                  ),
              width: 1,
            ),
          ),
          color: Theme.of(context).bottomAppBarTheme.color ??
              Theme.of(context).colorScheme.surface,
        ),
        child: IgnorePointer(
          ignoring: !viewState.isBottomBarVisible,
          child: AnimatedOpacity(
            opacity: viewState.isBottomBarVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: BottomAppBar(
              shape: const CircularNotchedRectangle(),
              notchMargin: 8,
              color: Colors.transparent,
              elevation: 0,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list, size: 28),
                    tooltip: loc.filter,
                    onPressed: onFilterPressed,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      viewState.isEditMode ? Icons.done : Icons.edit_note,
                      size: 28,
                    ),
                    tooltip: loc.toggleEditMode,
                    onPressed: onEditModeToggled,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
