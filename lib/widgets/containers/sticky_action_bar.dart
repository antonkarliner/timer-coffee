import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/design_tokens.dart';

/// A standardized bottom action bar that provides keyboard-aware positioning
/// and consistent styling for primary and secondary actions.
///
/// This component replaces the existing SaveButton implementation and provides
/// a more flexible solution with support for dual actions, loading states,
/// and proper keyboard handling.
class StickyActionBar extends StatelessWidget {
  /// The label for the primary action button
  final String primaryLabel;

  /// Callback when the primary action button is pressed
  final VoidCallback? onPrimaryPressed;

  /// The label for the secondary action button (optional)
  final String? secondaryLabel;

  /// Callback when the secondary action button is pressed (optional)
  final VoidCallback? onSecondaryPressed;

  /// Whether the primary action button should be disabled
  final bool primaryDisabled;

  /// Whether the secondary action button should be disabled
  final bool secondaryDisabled;

  /// Whether to show a loading indicator on the primary button
  final bool isLoading;

  /// Custom background color for the action bar
  final Color? backgroundColor;

  /// Custom elevation for the action bar
  final double? elevation;

  /// Custom padding for the action bar content
  final EdgeInsets? padding;

  /// Whether to show a divider above the action bar
  final bool showDivider;

  /// Semantic identifier for accessibility testing
  final String? semanticIdentifier;

  const StickyActionBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.primaryDisabled = false,
    this.secondaryDisabled = false,
    this.isLoading = false,
    this.backgroundColor,
    this.elevation,
    this.padding,
    this.showDivider = true,
    this.semanticIdentifier,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine if we should use single or dual button layout
    final hasSecondaryButton =
        secondaryLabel != null && onSecondaryPressed != null;

    return Semantics(
      identifier: semanticIdentifier ?? 'sticky_action_bar',
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDivider)
            Divider(
              height: 1,
              thickness: AppStroke.border,
              color: theme.dividerColor,
            ),
          // Wrap with Material to ensure proper elevation and background
          Material(
            color: backgroundColor ?? theme.scaffoldBackgroundColor,
            elevation: elevation ?? 8.0,
            child: SafeArea(
              // Only apply bottom padding to avoid keyboard overlap
              bottom: true,
              child: Padding(
                padding: padding ?? EdgeInsets.all(AppSpacing.base),
                child: hasSecondaryButton
                    ? _buildDualButtonLayout(context, colorScheme)
                    : _buildSingleButtonLayout(context, colorScheme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single button layout (primary action only)
  Widget _buildSingleButtonLayout(
      BuildContext context, ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: primaryDisabled || isLoading ? null : onPrimaryPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.primary.withOpacity(0.5),
          disabledForegroundColor: colorScheme.onPrimary.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? _buildLoadingIndicator(colorScheme.onPrimary)
            : Text(
                primaryLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  /// Builds a dual button layout (primary and secondary actions)
  Widget _buildDualButtonLayout(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        // Secondary button
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: secondaryDisabled ? null : onSecondaryPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                disabledForegroundColor: colorScheme.primary.withOpacity(0.5),
                side: BorderSide(
                  color: colorScheme.primary,
                  width: AppStroke.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
              ),
              child: Text(
                secondaryLabel!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: AppSpacing.base),
        // Primary button
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: primaryDisabled || isLoading ? null : onPrimaryPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                disabledBackgroundColor: colorScheme.primary.withOpacity(0.5),
                disabledForegroundColor: colorScheme.onPrimary.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? _buildLoadingIndicator(colorScheme.onPrimary)
                  : Text(
                      primaryLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a loading indicator widget
  Widget _buildLoadingIndicator(Color color) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

/// A wrapper widget that provides keyboard-aware positioning for the StickyActionBar
/// This ensures the action bar stays above the keyboard when it appears
class KeyboardAwareStickyActionBar extends StatefulWidget {
  final StickyActionBar child;

  const KeyboardAwareStickyActionBar({
    super.key,
    required this.child,
  });

  @override
  State<KeyboardAwareStickyActionBar> createState() =>
      _KeyboardAwareStickyActionBarState();
}

class _KeyboardAwareStickyActionBarState
    extends State<KeyboardAwareStickyActionBar> with WidgetsBindingObserver {
  double _keyboardHeight = 0.0;
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final wasKeyboardVisible = _isKeyboardVisible;
    _isKeyboardVisible = keyboardHeight > 0;

    if (wasKeyboardVisible != _isKeyboardVisible ||
        _keyboardHeight != keyboardHeight) {
      setState(() {
        _keyboardHeight = keyboardHeight;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(
        bottom: _isKeyboardVisible ? _keyboardHeight : 0,
      ),
      child: widget.child,
    );
  }
}
