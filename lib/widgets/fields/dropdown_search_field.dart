import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

  /// Suggestions to show when the field has focus but the user has not typed
  /// yet — on focus, and again whenever the field is emptied. Receives the
  /// field's current text (so the caller can exclude it). When null, the
  /// field behaves exactly as before.
  final Future<List<String>> Function(String currentText)? initialSuggestions;

  /// Whether the field should receive focus automatically.
  final bool autofocus;

  /// Render suggestions below the field in normal layout instead of an overlay.
  final bool inlineSuggestions;

  /// Debounce delay in milliseconds for search requests
  final int debounceDelay;

  /// Maximum number of suggestions to display
  final int maxSuggestions;

  /// Whether to allow custom entry (values not in suggestions)
  final bool allowCustomEntry;

  /// Custom error message when no results found
  final String? noResultsMessage;

  /// Custom loading message while searching
  final String? loadingMessage;

  const DropdownSearchField({
    super.key,
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
    this.initialSuggestions,
    this.autofocus = false,
    this.inlineSuggestions = false,
    this.debounceDelay = 250,
    this.maxSuggestions = 8,
    this.allowCustomEntry = true,
    this.noResultsMessage,
    this.loadingMessage,
  });

  @override
  State<DropdownSearchField> createState() => _DropdownSearchFieldState();
}

class _DropdownSearchFieldState extends State<DropdownSearchField> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  Timer? _debounceTimer;
  List<String> _suggestions = [];
  bool _isLoading = false;
  String _lastQuery = '';
  late String _lastSeenText;
  bool _initialMode = false;
  int _requestGeneration = 0;
  bool _showInline = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _targetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);

    _lastSeenText = _controller.text;
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
    _requestGeneration++;
    _debounceTimer?.cancel();
    // A caller-owned controller or focus node outlives this field, so the
    // listeners must come off or they fire into a disposed state.
    _focusNode.removeListener(_onFocusChange);
    _controller.removeListener(_onTextChanged);

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

  void _onFocusChange() {
    if (mounted) {
      if (_focusNode.hasFocus) {
        if (widget.initialSuggestions != null) {
          _showInitialSuggestions();
        } else {
          _showDropdownIfNeeded();
        }
      } else {
        if (widget.initialSuggestions != null) {
          _requestGeneration++;
          _debounceTimer?.cancel();
          _initialMode = false;
        }
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

    if (widget.initialSuggestions != null) {
      // Controller listeners also fire for cursor/selection changes. Keep
      // parent notifications above, but only actual edits change modes.
      if (text == _lastSeenText) return;
      _lastSeenText = text;
      _requestGeneration++;
      _initialMode = false;
      _lastQuery = '';
      _debounceTimer?.cancel();
      if (!_focusNode.hasFocus) return;
      if (text.isEmpty) {
        _showInitialSuggestions();
        if (mounted) setState(() {});
        return;
      }
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

  bool _isCurrentRequest(int generation, {required bool initial}) =>
      mounted &&
      generation == _requestGeneration &&
      _focusNode.hasFocus &&
      _initialMode == initial;

  Future<void> _showInitialSuggestions() async {
    _debounceTimer?.cancel();
    final generation = ++_requestGeneration;
    _initialMode = true;
    _lastSeenText = _controller.text;
    _lastQuery = '';
    _isLoading = false;
    _suggestions = [];
    _hideDropdown();

    try {
      final results = await widget.initialSuggestions!(_controller.text);
      if (!_isCurrentRequest(generation, initial: true)) return;
      setState(() {
        _suggestions = results.take(widget.maxSuggestions).toList();
      });
      _showDropdownIfNeeded();
    } catch (_) {
      // Initial suggestions are a convenience; failure leaves no overlay.
    }
  }

  void _performSearch(String query) {
    if (!mounted || query.isEmpty) return;
    if (widget.initialSuggestions != null &&
        (!_focusNode.hasFocus || _initialMode)) {
      return;
    }

    // Avoid duplicate searches
    if (query == _lastQuery) return;
    _lastQuery = query;
    final generation = ++_requestGeneration;

    setState(() {
      _isLoading = true;
    });
    // Mark any open overlay dirty so the loading row replaces stale
    // suggestions immediately instead of waiting for the search to resolve.
    if (widget.inlineSuggestions) {
      _showDropdownIfNeeded();
    } else {
      _overlayEntry?.markNeedsBuild();
    }

    // Perform async search
    widget
        .onSearch(query)
        .then((results) {
          if (!mounted) return;
          if (widget.initialSuggestions != null &&
              !_isCurrentRequest(generation, initial: false)) {
            return;
          }

          setState(() {
            _isLoading = false;
            _suggestions = results.take(widget.maxSuggestions).toList();
          });

          _showDropdownIfNeeded();
        })
        .catchError((error) {
          if (!mounted) return;
          if (widget.initialSuggestions != null &&
              !_isCurrentRequest(generation, initial: false)) {
            return;
          }

          setState(() {
            _isLoading = false;
            _suggestions = [];
          });

          _showDropdownIfNeeded();

          // Show error in a snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                )!.dropdownSearchLoadingError(error.toString()),
              ),
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

    if (_initialMode) {
      if (_suggestions.isEmpty) {
        _hideDropdown();
      } else {
        _showSuggestionsDropdown();
      }
      return;
    }

    final text = _controller.text.trim();

    // Only show dropdown if there's actual input or loading
    if (text.isEmpty) {
      _hideDropdown();
      return;
    }

    // Show the dropdown whenever there's a non-empty query: either we have
    // suggestions, a search is in flight (loading row), or there are none
    // (empty state, which also surfaces the custom-entry affordance).
    _showSuggestionsDropdown();
  }

  void _showSuggestionsDropdown() {
    if (widget.inlineSuggestions) {
      if (!_showInline && mounted) setState(() => _showInline = true);
      return;
    }
    if (widget.initialSuggestions != null) {
      final renderBox =
          _targetKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null ||
          !renderBox.hasSize ||
          WidgetsBinding.instance.schedulerPhase ==
              SchedulerPhase.persistentCallbacks) {
        final generation = _requestGeneration;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || generation != _requestGeneration) return;
          _showDropdownIfNeeded();
        });
        return;
      }
    }
    // If an overlay is already showing, just mark it dirty so it rebuilds
    // with the live state instead of tearing it down and re-inserting a new
    // entry on every completed search.
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        // Look up the render box fresh on every build so it stays valid
        // across markNeedsBuild calls (e.g. after layout changes).
        final RenderBox? renderBox =
            _targetKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null ||
            (widget.initialSuggestions != null && !renderBox.hasSize)) {
          return const SizedBox.shrink();
        }

        return _DropdownOverlay(
          items: _suggestions,
          isLoading: _isLoading,
          noResultsMessage:
              widget.noResultsMessage ??
              AppLocalizations.of(context)!.dropdownSearchNoResults,
          loadingMessage:
              widget.loadingMessage ??
              AppLocalizations.of(context)!.dropdownSearchLoading,
          allowCustomEntry: !_initialMode && widget.allowCustomEntry,
          currentQuery: _controller.text.trim(),
          onSelect: _selectSuggestion,
          renderBox: renderBox,
          layerLink: _layerLink,
          localizations: AppLocalizations.of(context)!,
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideDropdown() {
    if (widget.inlineSuggestions) {
      if (_showInline && mounted) setState(() => _showInline = false);
      return;
    }
    _removeOverlay();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectSuggestion(String value) {
    _controller.text = value;

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
    final field = Semantics(
      identifier: widget.semanticIdentifier,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Container(
          key: _targetKey,
          child: LabeledField(
            label: widget.label,
            hintText:
                widget.hintText ??
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
            autofocus: widget.autofocus,
            required: widget.required,
            focusNode: _focusNode,
            controller: _controller,
            showClearButton: widget.showClearButton,
            prefixIcon: widget.prefixIcon,
          ),
        ),
      ),
    );
    if (!widget.inlineSuggestions) return field;

    // Always keep the field at this position, even when the list is hidden.
    // Changing between a bare field and a Column would remount the input.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field,
        _showInline
            ? Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Container(
                  constraints: const BoxConstraints(
                    maxHeight: 4 * AppSpacing.xxl,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.field),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.grey.shade300,
                      width: AppStroke.border,
                    ),
                  ),
                  child: _DropdownContent(
                    items: _suggestions,
                    isLoading: _isLoading,
                    noResultsMessage:
                        widget.noResultsMessage ??
                        AppLocalizations.of(context)!.dropdownSearchNoResults,
                    loadingMessage:
                        widget.loadingMessage ??
                        AppLocalizations.of(context)!.dropdownSearchLoading,
                    allowCustomEntry: !_initialMode && widget.allowCustomEntry,
                    currentQuery: _controller.text.trim(),
                    onSelect: _selectSuggestion,
                    localizations: AppLocalizations.of(context)!,
                    inline: true,
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ],
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
  final LayerLink layerLink;
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
    required this.layerLink,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    // Get safe area insets
    final EdgeInsets safeInsets = mediaQuery.padding;
    final EdgeInsets viewInsets = mediaQuery.viewInsets;
    final Size screenSize = mediaQuery.size;

    // Get the position and size of the text field
    final Size textFieldSize = renderBox.size;
    final Offset textFieldPosition = renderBox.localToGlobal(Offset.zero);

    // Calculate effective screen boundaries (excluding safe areas and,
    // when present, the on-screen keyboard — whichever intrudes more from
    // the bottom).
    final double effectiveBottomInset = math.max(
      safeInsets.bottom,
      viewInsets.bottom,
    );
    final Rect effectiveScreenBounds = Rect.fromLTWH(
      safeInsets.left,
      safeInsets.top,
      screenSize.width - safeInsets.left - safeInsets.right,
      screenSize.height - safeInsets.top - effectiveBottomInset,
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

    // Always show below the input field. The field can sit flush against
    // (or past) the keyboard, so never hand the container a negative cap.
    final double textFieldBottom = textFieldPosition.dy + textFieldSize.height;
    final double spaceBelow =
        effectiveScreenBounds.bottom - textFieldBottom - 8.0;
    final double availableHeight = math.max(0.0, spaceBelow);
    final bool showsSuggestions = !isLoading && items.isNotEmpty;
    // The loading and empty states are short, scrollable and shrink-wrap
    // their real row heights, so cap them by space alone — a flat
    // per-row estimate under-counts the padded message row and clipped it.
    final double dropdownHeight = showsSuggestions
        ? math.min(math.min(contentHeight, maxDropdownHeight), availableHeight)
        : math.min(maxDropdownHeight, availableHeight);

    // Calculate horizontal positioning
    final double spaceOnRight =
        effectiveScreenBounds.right - textFieldPosition.dx - 8.0;
    final double spaceOnLeft =
        textFieldPosition.dx - effectiveScreenBounds.left - 8.0;

    // Determine dropdown width (at least as wide as text field, but not wider than available space)
    final double minDropdownWidth = textFieldSize.width;
    final double maxDropdownWidth = math.max(
      minDropdownWidth,
      200.0,
    ); // Minimum 200dp width
    final double dropdownWidth = math.min(
      maxDropdownWidth,
      math.max(minDropdownWidth, spaceOnRight),
    );

    // Determine if we need to align to the right
    final bool alignRight =
        spaceOnRight < minDropdownWidth && spaceOnLeft > spaceOnRight;

    // Calculate horizontal offset - always position below via the follower
    final double horizontalOffset = alignRight
        ? -(dropdownWidth - textFieldSize.width)
        : 0.0;
    return Positioned(
      width: dropdownWidth,
      child: CompositedTransformFollower(
        link: layerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: Offset(horizontalOffset, 8.0),
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
            child: _DropdownContent(
              items: items,
              isLoading: isLoading,
              noResultsMessage: noResultsMessage,
              loadingMessage: loadingMessage,
              allowCustomEntry: allowCustomEntry,
              currentQuery: currentQuery,
              onSelect: onSelect,
              localizations: localizations,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared rows for both overlay and inline presentation.
class _DropdownContent extends StatelessWidget {
  const _DropdownContent({
    required this.items,
    required this.isLoading,
    required this.noResultsMessage,
    required this.loadingMessage,
    required this.allowCustomEntry,
    required this.currentQuery,
    required this.onSelect,
    required this.localizations,
    this.inline = false,
  });

  final List<String> items;
  final bool isLoading;
  final String noResultsMessage;
  final String loadingMessage;
  final bool allowCustomEntry;
  final String currentQuery;
  final Function(String) onSelect;
  final AppLocalizations localizations;
  final bool inline;

  @override
  Widget build(BuildContext context) => isLoading
      ? _buildLoadingState()
      : items.isEmpty
      ? _buildEmptyState()
      : _buildSuggestionsList(Theme.of(context));

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Row(
        children: [
          SizedBox(
            width: AppIconSize.small,
            height: AppIconSize.small,
            child: CircularProgressIndicator(
              strokeWidth: AppStroke.focus,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            loadingMessage,
            style: AppTextStyles.body.copyWith(color: Colors.grey.shade600),
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
          style: AppTextStyles.body.copyWith(color: Colors.grey.shade600),
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

    // Scrollable so a cramped space above the keyboard clips into a scroll
    // instead of overflowing the overlay.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _buildSuggestionsList(ThemeData theme) {
    // AlertDialog asks for intrinsic dimensions. A scrollable Column supports
    // that sizing pass; a shrink-wrapped ListView viewport does not.
    if (inline) {
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final suggestion in items) _buildItem(suggestion, theme),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (context, index) => _buildItem(items[index], theme),
    );
  }

  Widget _buildItem(String suggestion, ThemeData theme) {
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
              child: Text(suggestion, style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
