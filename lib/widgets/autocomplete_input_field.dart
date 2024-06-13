import 'package:flutter/material.dart';

class AutocompleteInputField extends StatefulWidget {
  final String label;
  final String hintText;
  final Future<List<String>> initialOptions;
  final Function(String) onSelected;
  final String? initialValue;

  const AutocompleteInputField({
    Key? key,
    required this.label,
    required this.hintText,
    required this.initialOptions,
    required this.onSelected,
    this.initialValue,
  }) : super(key: key);

  @override
  _AutocompleteInputFieldState createState() => _AutocompleteInputFieldState();
}

class _AutocompleteInputFieldState extends State<AutocompleteInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _controller.addListener(_handleTextChange);
  }

  @override
  void didUpdateWidget(covariant AutocompleteInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _controller.text = widget.initialValue ?? '';
    }
  }

  void _handleTextChange() {
    String text = _controller.text;
    widget.onSelected(text);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
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
        FutureBuilder<List<String>>(
          future: widget.initialOptions,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError || !snapshot.hasData) {
              return const Text('Failed to load data');
            }
            List<String> recentItems =
                snapshot.data!.where((item) => item.isNotEmpty).toList();
            return RawAutocomplete<String>(
              textEditingController: _controller,
              focusNode: _focusNode,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return recentItems;
                }
                return recentItems
                    .where((option) => option
                        .toLowerCase()
                        .contains(textEditingValue.text.trim().toLowerCase()))
                    .toList()
                  ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
              },
              fieldViewBuilder: (BuildContext context,
                  TextEditingController fieldTextEditingController,
                  FocusNode fieldFocusNode,
                  VoidCallback onFieldSubmitted) {
                return TextFormField(
                  controller: fieldTextEditingController,
                  focusNode: fieldFocusNode,
                  decoration: InputDecoration(hintText: widget.hintText),
                );
              },
              onSelected: (String selection) {
                _controller.text = selection;
                widget.onSelected(selection);
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
                      constraints:
                          BoxConstraints(maxHeight: maxHeight, minHeight: 60.0),
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
                                _controller.text = option;
                              },
                              child: ListTile(title: Text(option)),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
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
