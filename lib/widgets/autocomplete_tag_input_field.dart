import 'package:flutter/material.dart';

class AutocompleteTagInputField extends StatefulWidget {
  final String label;
  final String hintText;
  final Future<List<String>> initialOptions;
  final Function(List<String>) onSelected;
  final List<String>? initialValues;

  const AutocompleteTagInputField({
    Key? key,
    required this.label,
    required this.hintText,
    required this.initialOptions,
    required this.onSelected,
    this.initialValues,
  }) : super(key: key);

  @override
  _AutocompleteTagInputFieldState createState() =>
      _AutocompleteTagInputFieldState();
}

class _AutocompleteTagInputFieldState extends State<AutocompleteTagInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late Future<List<String>> _optionsFuture;
  List<String> _tags = [];
  List<String> _allOptions = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    if (widget.initialValues != null) {
      _tags = widget.initialValues!
          .where((tag) => tag.isNotEmpty)
          .map((tag) => tag.toLowerCase())
          .toList();
    }
    _optionsFuture = widget.initialOptions;
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final options = await _optionsFuture;
    if (!mounted) return;
    setState(() {
      _allOptions = options;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final normalizedTag = tag.toLowerCase();
    if (normalizedTag.isNotEmpty && !_tags.contains(normalizedTag)) {
      setState(() {
        _tags.add(normalizedTag);
        _controller.clear();
      });
      widget.onSelected(_tags);
      // Keep the focus on the input field
      Future.delayed(Duration(milliseconds: 100), () {
        FocusScope.of(context).requestFocus(_focusNode);
      });
    } else if (_tags.contains(normalizedTag)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$tag" is already added')),
      );
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag.toLowerCase());
    });
    widget.onSelected(_tags);
  }

  List<String> _getFilteredOptions(String query) {
    final recentItems = _allOptions
        .where((item) => item.isNotEmpty && !_tags.contains(item.toLowerCase()))
        .toList();
    if (query.isEmpty) {
      return recentItems;
    }
    return recentItems
        .where((option) =>
            option.toLowerCase().contains(query.trim().toLowerCase()))
        .toList();
  }

  String _capitalize(String input) {
    return input.split(' ').map((str) {
      if (str.isNotEmpty) {
        return str[0].toUpperCase() + str.substring(1).toLowerCase();
      }
      return str;
    }).join(' ');
  }

  @override
  void didUpdateWidget(covariant AutocompleteTagInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh options only if the Future instance changed.
    if (oldWidget.initialOptions != widget.initialOptions) {
      _optionsFuture = widget.initialOptions;
      _loadOptions();
    }
    // Sync tags if external values changed (avoid overriding while focused typing).
    if (oldWidget.initialValues != widget.initialValues &&
        widget.initialValues != null) {
      final newTags = widget.initialValues!
          .where((t) => t.isNotEmpty)
          .map((t) => t.toLowerCase())
          .toList();
      if (_tags.join(',') != newTags.join(',')) {
        setState(() {
          _tags = newTags;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Text(widget.label.capitalize(),
              style: Theme.of(context).textTheme.titleLarge),
        ),
        Wrap(
          spacing: 8.0,
          children: _tags
              .map((tag) => Chip(
                    label: Text(_capitalize(tag)),
                    onDeleted: () => _removeTag(tag),
                  ))
              .toList(),
        ),
        RawAutocomplete<String>(
          textEditingController: _controller,
          focusNode: _focusNode,
          optionsBuilder: (TextEditingValue textEditingValue) {
            // Hide suggestions when not focused.
            if (!_focusNode.hasFocus) {
              return const <String>[];
            }
            // Hide when query is empty to reduce overlay flicker.
            if (textEditingValue.text.isEmpty) {
              return const <String>[];
            }
            return _getFilteredOptions(textEditingValue.text);
          },
          fieldViewBuilder: (BuildContext context,
              TextEditingController fieldTextEditingController,
              FocusNode fieldFocusNode,
              VoidCallback onFieldSubmitted) {
            return TextFormField(
              controller: fieldTextEditingController,
              focusNode: fieldFocusNode,
              decoration: InputDecoration(hintText: widget.hintText),
              onFieldSubmitted: (value) {
                if (value.isNotEmpty) {
                  _addTag(value);
                }
              },
            );
          },
          onSelected: (String selection) {
            _addTag(selection);
            // Dismiss overlay to avoid overlapping UI; keep focus for quick entry.
            // Keep focus but clear field so options re-evaluate on next char.
            _controller.clear();
          },
          optionsViewBuilder: (BuildContext context,
              AutocompleteOnSelected<String> onSelected,
              Iterable<String> options) {
            double listHeight = options.length * 60.0;
            double maxHeight = 200.0;
            double actualHeight =
                listHeight < maxHeight ? listHeight : maxHeight;

            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: Container(
                    width: MediaQuery.of(context).size.width - 55,
                    height: actualHeight,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        String option = options.elementAt(index);
                        return GestureDetector(
                          onTap: () {
                            onSelected(option);
                          },
                          child: ListTile(title: Text(_capitalize(option))),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

extension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
