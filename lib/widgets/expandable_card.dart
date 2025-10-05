import 'package:flutter/material.dart';

class ExpandableCard extends StatefulWidget {
  final Key key;
  final Widget leading;
  final String header;
  final TextStyle? headerStyle;
  final String subtitle;
  final Widget? subtitleWidget;
  final Widget detail;
  final Widget? trailing;
  final bool isExpanded;
  final Function(bool) onExpansionChanged;

  const ExpandableCard({
    required this.key,
    required this.leading,
    required this.header,
    this.headerStyle,
    required this.subtitle,
    this.subtitleWidget,
    required this.detail,
    this.trailing,
    required this.isExpanded,
    required this.onExpansionChanged,
  }) : super(key: key);

  @override
  _ExpandableCardState createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard>
    with AutomaticKeepAliveClientMixin {
  bool _isExpanded;

  _ExpandableCardState() : _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onExpansionChanged(_isExpanded);
  }

  @override
  void didUpdateWidget(covariant ExpandableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      setState(() {
        _isExpanded = widget.isExpanded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: _toggleExpanded,
            child: ListTile(
              leading: widget.leading,
              title: Text(
                widget.header,
                style: widget.headerStyle,
              ),
              subtitle: widget.subtitleWidget != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: widget.subtitleWidget,
                    )
                  : Text(widget.subtitle),
              trailing: widget.trailing ??
                  IconButton(
                    icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: _toggleExpanded,
                  ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: Container(),
            secondChild: Container(
              padding: const EdgeInsets.all(16),
              child: widget.detail,
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
