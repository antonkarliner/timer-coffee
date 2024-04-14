import 'package:flutter/material.dart';

class ExpandableCard extends StatefulWidget {
  final Widget leading; // Widget to display the icon
  final String header;
  final String subtitle;
  final Widget detail;

  const ExpandableCard({
    Key? key,
    required this.leading,
    required this.header,
    required this.subtitle,
    required this.detail,
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
            onTap:
                _toggleExpanded, // Toggle expansion when the ListTile area is tapped
            child: ListTile(
              leading: widget.leading, // Place the icon here
              title: Text(widget.header),
              subtitle: Text(widget.subtitle),
              trailing: IconButton(
                icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                onPressed:
                    _toggleExpanded, // Same toggle function for the icon button
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: Container(), // Empty container for collapsed state
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
