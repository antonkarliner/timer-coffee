import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../theme/design_tokens.dart';
import 'labeled_field.dart';
import '../../l10n/app_localizations.dart';

/// A standardized dropdown search field component that provides enhanced autocomplete
/// functionality with debounced search, caching, and consistent styling.
///
/// This component extends the LabeledField component for consistent styling and
/// provides advanced autocomplete features including:
/// - Debounced search to reduce API calls
/// - Caching for recent selections
/// - Support for async data sources
/// - Top 5 matches with option for custom entry
/// - Request cancellation on dispose
/// - Free-text fallback when no matches found
class DropdownSearchField extends StatefulWidget {
  /// The label text displayed above the field
  final String label;

  /// The hint text displayed inside the field when empty
  final String? hintText;

  /// The helper text displayed below the field
  final String? helperText;

  /// The error text to display when validation fails
  final String? errorText;

  /// The initial value of the field
  final String? initialValue;

  /// Callback when the field value changes
  final ValueChanged<String>? onChanged;

  /// Callback when the field is submitted
  final ValueChanged<String>? onSubmitted;

  /// Validator function for the field
  final FormFieldValidator<String>? validator;

  /// Whether the field is enabled
  final bool enabled;

  /// Whether the field is required
  final bool required;

  /// Semantic identifier for accessibility
  final String? semanticIdentifier;

  /// Focus node for controlling focus
  final FocusNode? focusNode;

  /// Text controller for the field
  final TextEditingController? controller;

  /// Whether to show a clear button
  final bool showClearButton;

  /// Icon to show at the end of the field
  final Widget? suffixIcon;

  /// Icon to show at the beginning of the field
  final Widget? prefixIcon;

  /// Async function to fetch suggestions based on query
  final Future<List<String>> Function(String query) onSearch;

  /// Debounce delay in milliseconds for search requests
  final int debounceDelay;

  /// Maximum number of suggestions to display
  final int maxSuggestions;

  /// Whether to allow custom entry (values not in suggestions)
  final bool allowCustomEntry;

  /// Whether to show recent selections when field is focused
  final bool showRecentSelections;

  /// Maximum number of recent selections to cache
  final int maxRecentSelections;

  /// Custom error message when no results found
  final String? noResultsMessage;

  /// Custom loading message while searching
  final String? loadingMessage;

  const DropdownSearchField({
    Key? key,
    required this.label,
    required this.onSearch,
    this.hintText,
    this.helperText,
    this.errorText,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.enabled = true,
    this.required = false,
    this.semanticIdentifier,
    this.focusNode,
    this.controller,
    this.showClearButton = true,
    this.suffixIcon,
    this.prefixIcon,
    this.debounceDelay = 250,
    this.maxSuggestions = 8,
    this.allowCustomEntry = true,
    this.showRecentSelections = false,
    this.maxRecentSelections = 10,
    this.noResultsMessage,
    this.loadingMessage,
  }) : super(key: key);

  @override
  State<DropdownSearchField> createState() => _DropdownSearchFieldState();
}

class _DropdownSearchFieldState extends State<DropdownSearchField> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  Timer? _debounceTimer;
  List<String> _suggestions = [];
  List<String> _recentSelections = [];
  bool _isLoading = false;
  bool _showDropdown = false;
  String _lastQuery = '';
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _targetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);

    // Load recent selections from cache (in a real app, this would use SharedPreferences)
    _loadRecentSelections();

    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(DropdownSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialValue != widget.initialValue &&
        widget.controller == null &&
        _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue ?? '';
    }
  }

  @override
  void dispose() {
    // Cancel any pending search
    _debounceTimer?.cancel();

    // Remove overlay if visible
    _removeOverlay();

    // Dispose controllers and nodes if they were created internally
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    if (widget.controller == null) {
      _controller.dispose();
    }

    super.dispose();
  }

  void _loadRecentSelections() {
    // In a real implementation, this would load from persistent storage
    // For now, we'll use an in-memory cache
    _recentSelections = [];
  }

  void _saveRecentSelection(String value) {
    if (value.isEmpty) return;

    // Remove if already exists
    _recentSelections.remove(value);

    // Add to beginning
    _recentSelections.insert(0, value);

    // Limit to max recent selections
    if (_recentSelections.length > widget.maxRecentSelections) {
      _recentSelections =
          _recentSelections.take(widget.maxRecentSelections).toList();
    }

    // In a real implementation, this would save to persistent storage
  }

  void _onFocusChange() {
    if (mounted) {
      if (_focusNode.hasFocus) {
        _showDropdownIfNeeded();
      } else {
        _hideDropdown();
      }
    }
  }

  void _onTextChanged() {
    final text = _controller.text;

    // Notify parent of change
    if (widget.onChanged != null) {
      widget.onChanged!(text);
    }

    // Reset debounce timer
    _debounceTimer?.cancel();

    if (text.isEmpty) {
      _hideDropdown();
      // Force rebuild to update clear button visibility
      if (mounted) {
        setState(() {});
      }
      return;
    }

    // Start debounce timer
    _debounceTimer = Timer(Duration(milliseconds: widget.debounceDelay), () {
      _performSearch(text);
    });
  }

  void _performSearch(String query) {
    if (!mounted || query.isEmpty) return;

    // Avoid duplicate searches
    if (query == _lastQuery) return;
    _lastQuery = query;

    setState(() {
      _isLoading = true;
    });

    // Perform async search
    widget.onSearch(query).then((results) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _suggestions = results.take(widget.maxSuggestions).toList();
      });

      _showDropdownIfNeeded();
    }).catchError((error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _suggestions = [];
      });

      // Show error in a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!
              .dropdownSearchLoadingError(error.toString())),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _showDropdownIfNeeded() {
    if (!_focusNode.hasFocus || !widget.enabled) {
      _hideDropdown();
      return;
    }

    final text = _controller.text.trim();

    // Only show dropdown if there's actual input or loading
    if (text.isEmpty) {
      _hideDropdown();
      return;
    }

    // Show suggestions if we have them or loading
    if (_suggestions.isNotEmpty || _isLoading) {
      _showSuggestionsDropdown(_suggestions);
      return;
    }

    // Hide dropdown if no content to show
    _hideDropdown();
  }

  void _showSuggestionsDropdown(List<String> items) {
    _removeOverlay();

    // Get the render box from the target key widget
    final RenderBox? renderBox =
        _targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) => _DropdownOverlay(
        items: items,
        isLoading: _isLoading,
        noResultsMessage: widget.noResultsMessage ??
            AppLocalizations.of(context)!.dropdownSearchNoResults,
        loadingMessage: widget.loadingMessage ??
            AppLocalizations.of(context)!.dropdownSearchLoading,
        allowCustomEntry: widget.allowCustomEntry,
        currentQuery: _controller.text.trim(),
        onSelect: _selectSuggestion,
        renderBox: renderBox,
        localizations: AppLocalizations.of(context)!,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _showDropdown = true;
    });
  }

  void _hideDropdown() {
    _removeOverlay();
    if (_showDropdown) {
      setState(() {
        _showDropdown = false;
      });
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectSuggestion(String value) {
    _controller.text = value;
    _saveRecentSelection(value);

    // Hide dropdown
    _hideDropdown();

    // Notify parent
    widget.onChanged?.call(value);

    // Unfocus to close keyboard
    _focusNode.unfocus();
  }

  void _onFieldSubmitted(String value) {
    if (value.isNotEmpty) {
      _selectSuggestion(value);
      widget.onSubmitted?.call(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: widget.semanticIdentifier,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Container(
          key: _targetKey,
          child: LabeledField(
            label: widget.label,
            hintText: widget.hintText ??
                AppLocalizations.of(context)!.dropdownSearchHintText,
            helperText: widget.helperText,
            errorText: widget.errorText,
            initialValue: widget.initialValue,
            onChanged: (value) {
              // Forward to our text change handler to ensure state synchronization
              _onTextChanged();
            },
            onSubmitted: _onFieldSubmitted,
            validator: widget.validator,
            enabled: widget.enabled,
            required: widget.required,
            semanticIdentifier: widget.semanticIdentifier,
            focusNode: _focusNode,
            controller: _controller,
            showClearButton: widget.showClearButton,
            prefixIcon: widget.prefixIcon,
          ),
        ),
      ),
    );
  }
}

/// Overlay widget for displaying search suggestions
class _DropdownOverlay extends StatelessWidget {
  final List<String> items;
  final bool isLoading;
  final String noResultsMessage;
  final String loadingMessage;
  final bool allowCustomEntry;
  final String currentQuery;
  final Function(String) onSelect;
  final RenderBox renderBox;
  final AppLocalizations localizations;

  const _DropdownOverlay({
    required this.items,
    required this.isLoading,
    required this.noResultsMessage,
    required this.loadingMessage,
    required this.allowCustomEntry,
    required this.currentQuery,
    required this.onSelect,
    required this.renderBox,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    // Get safe area insets
    final EdgeInsets safeInsets = mediaQuery.padding;
    final Size screenSize = mediaQuery.size;

    // Get the position and size of the text field
    final Size textFieldSize = renderBox.size;
    final Offset textFieldPosition = renderBox.localToGlobal(Offset.zero);

    // Calculate effective screen boundaries (excluding safe areas)
    final Rect effectiveScreenBounds = Rect.fromLTWH(
      safeInsets.left,
      safeInsets.top,
      screenSize.width - safeInsets.left - safeInsets.right,
      screenSize.height - safeInsets.top - safeInsets.bottom,
    );

    // Calculate item height (approximate)
    const double itemHeight = 48.0;
    final double dropdownItemHeight = isLoading ? itemHeight : itemHeight;

    // Calculate content height based on items
    int contentItems = items.length;
    if (isLoading) contentItems = 1;
    if (items.isEmpty && allowCustomEntry && currentQuery.isNotEmpty)
      contentItems = 2;
    if (items.isEmpty && !allowCustomEntry) contentItems = 1;

    final double contentHeight = contentItems * dropdownItemHeight;
    final double maxDropdownHeight = 8 * itemHeight; // Max 8 items

    // Always show below the input field
    final double textFieldBottom = textFieldPosition.dy + textFieldSize.height;
    final double spaceBelow =
        effectiveScreenBounds.bottom - textFieldBottom - 8.0;
    final double availableHeight = spaceBelow;
    final double dropdownHeight = contentHeight < maxDropdownHeight
        ? (contentHeight < availableHeight ? contentHeight : availableHeight)
        : (maxDropdownHeight < availableHeight
            ? maxDropdownHeight
            : availableHeight);

    // Calculate horizontal positioning
    final double spaceOnRight =
        effectiveScreenBounds.right - textFieldPosition.dx - 8.0;
    final double spaceOnLeft =
        textFieldPosition.dx - effectiveScreenBounds.left - 8.0;

    // Determine dropdown width (at least as wide as text field, but not wider than available space)
    final double minDropdownWidth = textFieldSize.width;
    final double maxDropdownWidth =
        math.max(minDropdownWidth, 200.0); // Minimum 200dp width
    final double dropdownWidth =
        math.min(maxDropdownWidth, math.max(minDropdownWidth, spaceOnRight));

    // Determine if we need to align to the right
    final bool alignRight =
        spaceOnRight < minDropdownWidth && spaceOnLeft > spaceOnRight;

    // Calculate offsets - always position below
    final double verticalOffset = textFieldSize.height + 8.0;
    final double horizontalOffset =
        alignRight ? -(dropdownWidth - textFieldSize.width) : 0.0;
    return Positioned(
      left: textFieldPosition.dx + horizontalOffset,
      top: textFieldPosition.dy + verticalOffset,
      child: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(AppRadius.field),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: dropdownHeight,
            minWidth: dropdownWidth,
            maxWidth: dropdownWidth,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey.shade400
                  : Colors.grey.shade300,
              width: AppStroke.border,
            ),
          ),
          child: isLoading
              ? _buildLoadingState()
              : items.isEmpty
                  ? _buildEmptyState()
                  : _buildSuggestionsList(theme),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Row(
        children: [
          SizedBox(
            width: AppIconSize.small,
            height: AppIconSize.small,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            loadingMessage,
            style: AppTextStyles.body.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final children = <Widget>[];

    // Show no results message
    children.add(
      Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Text(
          noResultsMessage,
          style: AppTextStyles.body.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );

    // Show custom entry option if allowed and query is not empty
    if (allowCustomEntry && currentQuery.isNotEmpty) {
      children.add(
        InkWell(
          onTap: () => onSelect(currentQuery),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.cardPadding,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add,
                  size: AppIconSize.small,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    localizations.dropdownSearchUseCustomEntry(currentQuery),
                    style: AppTextStyles.body.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _buildSuggestionsList(ThemeData theme) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final suggestion = items[index];
        return InkWell(
          onTap: () => onSelect(suggestion),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.cardPadding,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    suggestion,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
