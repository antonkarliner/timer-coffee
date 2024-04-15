import 'package:flutter/material.dart';

class ExpandableCard extends StatefulWidget {
  final Widget leading; // Widget to display the icon
  final String header;
  final String subtitle;
  final Widget detail;
  final Widget? trailing; // Optional widget for trailing area

  const ExpandableCard({
    Key? key,
    required this.leading,
    required this.header,
    required this.subtitle,
    required this.detail,
    this.trailing, // Initialize the trailing widget
  }) : super(key: key);

  @override
  _ExpandableCardState createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: _toggleExpanded,
            child: ListTile(
              leading: widget.leading,
              title: Text(widget.header),
              subtitle: Text(widget.subtitle),
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
}
