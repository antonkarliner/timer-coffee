import 'package:flutter/material.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import '../../models/brewing_method_model.dart';
import '../../theme/design_tokens.dart';

class RecipeBrewingMethodCard extends StatelessWidget {
  final List<BrewingMethodModel> brewingMethods;
  final String? selectedBrewingMethodId;
  final ValueChanged<String?> onBrewingMethodChanged;

  const RecipeBrewingMethodCard({
    super.key,
    required this.brewingMethods,
    required this.selectedBrewingMethodId,
    required this.onBrewingMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: TextFormField(
          controller: TextEditingController(
            text: selectedBrewingMethodId != null
                ? brewingMethods
                    .firstWhere(
                        (method) =>
                            method.brewingMethodId == selectedBrewingMethodId,
                        orElse: () => brewingMethods.first)
                    .brewingMethod
                : '',
          ),
          readOnly: true,
          onTap: () => _showBrewingMethodModal(context),
          decoration: InputDecoration(
            labelText: l10n.recipeCreationScreenBrewingMethodLabel,
            suffixIcon: const Icon(Icons.keyboard_arrow_down),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.cardPadding,
              vertical: AppSpacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.field),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade500
                    : Colors.grey.shade300,
                width: AppStroke.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.field),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade500
                    : Colors.grey.shade300,
                width: AppStroke.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.field),
              borderSide: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade300
                    : Colors.grey.shade700,
                width: AppStroke.focus,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.recipeCreationScreenBrewingMethodValidator;
            }
            return null;
          },
        ),
      ),
    );
  }

  void _showBrewingMethodModal(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedMethod = selectedBrewingMethodId != null
        ? brewingMethods.firstWhere(
            (method) => method.brewingMethodId == selectedBrewingMethodId,
            orElse: () => brewingMethods.first)
        : null;

    // Create a custom overlay that appears below the input field
    late OverlayEntry overlay;
    overlay = OverlayEntry(
      builder: (context) => _BrewingMethodOverlay(
        brewingMethods: brewingMethods,
        selectedMethodId: selectedBrewingMethodId,
        onMethodSelected: (methodId) {
          onBrewingMethodChanged(methodId);
          // Remove the overlay
          overlay.remove();
        },
        onDismissed: () => overlay.remove(),
        title: l10n.recipeCreationScreenBrewingMethodLabel,
      ),
    );

    // Insert the overlay
    Overlay.of(context).insert(overlay);
  }
}

// Custom overlay widget for brewing methods
class _BrewingMethodOverlay extends StatefulWidget {
  final List<BrewingMethodModel> brewingMethods;
  final String? selectedMethodId;
  final ValueChanged<String> onMethodSelected;
  final VoidCallback onDismissed;
  final String title;

  const _BrewingMethodOverlay({
    required this.brewingMethods,
    required this.selectedMethodId,
    required this.onMethodSelected,
    required this.onDismissed,
    required this.title,
  });

  @override
  State<_BrewingMethodOverlay> createState() => _BrewingMethodOverlayState();
}

class _BrewingMethodOverlayState extends State<_BrewingMethodOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final appBarHeight = kToolbarHeight + mediaQuery.padding.top;
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: widget.onDismissed,
        behavior: HitTestBehavior.translucent,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: GestureDetector(
              onTap: () {}, // Prevent tap events from bubbling up to the parent
              child: Container(
                margin: EdgeInsets.only(
                  top: appBarHeight,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade600
                        : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: mediaQuery.size.height - appBarHeight - 32,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: widget.brewingMethods.length,
                    itemBuilder: (context, index) {
                      final method = widget.brewingMethods[index];
                      final isSelected =
                          method.brewingMethodId == widget.selectedMethodId;
                      return ListTile(
                        title: Text(
                          method.brewingMethod,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                        onTap: () {
                          widget.onMethodSelected(method.brewingMethodId);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
