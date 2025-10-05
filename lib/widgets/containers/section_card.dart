import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

/// A standardized section container component with optional collapsible functionality.
///
/// This component provides a consistent way to display sections of content with
/// a standardized header, optional subtitle, and icon. It supports both collapsible
/// and non-collapsible modes, with smooth animations for expand/collapse actions.
///
/// Example usage:
/// ```dart
/// SectionCard(
///   title: 'Basic Information',
///   subtitle: 'Required details about the coffee beans',
///   icon: Icons.info_outline,
///   initiallyExpanded: true,
///   child: Column(
///     children: [
///       // Your content here
///     ],
///   ),
/// )
/// ```
class SectionCard extends StatefulWidget {
  /// The title displayed in the section header
  final String title;

  /// Optional subtitle displayed below the title
  final String? subtitle;

  /// Optional icon displayed before the title
  final IconData? icon;

  /// Whether the section should be collapsible
  /// Defaults to true
  final bool isCollapsible;

  /// Whether the section should be initially expanded
  /// Only applies when [isCollapsible] is true
  /// Defaults to false
  final bool initiallyExpanded;

  /// Callback when the expansion state changes
  /// Only called when [isCollapsible] is true
  final ValueChanged<bool>? onExpansionChanged;

  /// Optional widget to display in the trailing position of the header
  /// When [isCollapsible] is true, this will be displayed alongside the expand/collapse icon
  final Widget? trailing;

  /// The content to display in the section
  final Widget child;

  /// Semantic identifier for accessibility testing
  final String? semanticIdentifier;

  /// Whether to add padding around the child content
  /// Defaults to true
  final bool paddingChild;

  /// Whether to show a divider between the header and content
  /// Defaults to true
  final bool showDivider;

  const SectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.isCollapsible = true,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
    this.trailing,
    required this.child,
    this.semanticIdentifier,
    this.paddingChild = true,
    this.showDivider = true,
  });

  @override
  State<SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<SectionCard>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _iconRotation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    // Initialize animation controller for smooth expand/collapse
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _iconRotation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Set initial animation state
    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(SectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle external expansion state changes
    if (widget.initiallyExpanded != oldWidget.initiallyExpanded &&
        widget.initiallyExpanded != _isExpanded) {
      _toggleExpansion(notify: false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion({bool notify = true}) {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

    if (notify && widget.onExpansionChanged != null) {
      widget.onExpansionChanged!(_isExpanded);
    }
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: widget.isCollapsible ? _toggleExpansion : null,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(AppRadius.card),
        topRight: Radius.circular(AppRadius.card),
        bottomLeft: Radius.circular(
            !widget.isCollapsible || _isExpanded ? 0 : AppRadius.card),
        bottomRight: Radius.circular(
            !widget.isCollapsible || _isExpanded ? 0 : AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Row(
          children: [
            if (widget.icon != null) ...[
              Icon(
                widget.icon,
                color: colorScheme.primary,
                size: AppIconSize.medium,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.trailing != null) ...[
              widget.trailing!,
              const SizedBox(width: AppSpacing.sm),
            ],
            if (widget.isCollapsible)
              AnimatedBuilder(
                animation: _iconRotation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle:
                        _iconRotation.value * 3.14159, // 180 degrees in radians
                    child: Icon(
                      Icons.expand_more,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (!widget.isCollapsible || _isExpanded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showDivider && widget.isCollapsible)
            Divider(
              height: 1,
              thickness: AppStroke.border,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
            ),
          if (widget.paddingChild)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: widget.child,
            )
          else
            widget.child,
        ],
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context),
        if (widget.isCollapsible)
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _expandAnimation,
                axisAlignment: -1.0,
                child: _buildContent(),
              );
            },
          )
        else
          _buildContent(),
      ],
    );

    // Wrap with semantic annotations for accessibility
    Widget result = content;
    if (widget.semanticIdentifier != null) {
      result = Semantics(
        identifier: widget.semanticIdentifier,
        container: true,
        child: result,
      );
    }

    // Apply the CardTheme from the theme provider
    return Card(
      margin: EdgeInsets.zero, // Let parent control margins
      child: result,
    );
  }

  @override
  bool get wantKeepAlive => widget.isCollapsible;
}
