import 'package:flutter/material.dart';

class AutocompleteInputField extends StatefulWidget {
  final String label;
  final String hintText;
  final Future<List<String>> initialOptions;
  final Function(String) onSelected;
  final ValueChanged<String>? onChanged;
  final String? initialValue;

  const AutocompleteInputField({
    Key? key,
    required this.label,
    required this.hintText,
    required this.initialOptions,
    required this.onSelected,
    this.onChanged,
    this.initialValue,
  }) : super(key: key);

  @override
  _AutocompleteInputFieldState createState() => _AutocompleteInputFieldState();
}

class _AutocompleteInputFieldState extends State<AutocompleteInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late Future<List<String>> _optionsFuture;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_handleTextChange);
    // Cache options Future to avoid refetch/spinner on unrelated rebuilds.
    _optionsFuture = widget.initialOptions;
  }

  @override
  void didUpdateWidget(covariant AutocompleteInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      // Defer text assignment to avoid setState/markNeedsBuild during build.
      // Also, do NOT override user typing while focused.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _focusNode.hasFocus) return;
        final newText = widget.initialValue ?? '';
        if (_controller.text != newText) {
          _controller.value = _controller.value.copyWith(
            text: newText,
            selection: TextSelection.collapsed(offset: newText.length),
            composing: TextRange.empty,
          );
        }
      });
    }
    if (oldWidget.initialOptions != widget.initialOptions) {
      _optionsFuture = widget.initialOptions;
      setState(() {});
    }
  }

  void _handleTextChange() {
    // Per-keystroke changes should use onChanged (optional) to reduce rebuild churn.
    final text = _controller.text;
    if (widget.onChanged != null) {
      widget.onChanged!(text);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChange);
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // Rebuild when focus changes so optionsBuilder can react,
    // which ensures overlay hides when unfocused.
    if (mounted) setState(() {});
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
          future: _optionsFuture,
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
                // Hide suggestions when not focused.
                if (!_focusNode.hasFocus) {
                  return const <String>[];
                }
                // Optionally hide suggestions for empty query to avoid large overlays.
                if (textEditingValue.text.isEmpty) {
                  return const <String>[];
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
                // Update controller via value to keep selection stable.
                _controller.value = _controller.value.copyWith(
                  text: selection,
                  selection: TextSelection.collapsed(offset: selection.length),
                  composing: TextRange.empty,
                );
                widget.onSelected(selection);
                // Dismiss overlay by removing focus after selection.
                _focusNode.unfocus();
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
                                _controller.value = _controller.value.copyWith(
                                  text: option,
                                  selection: TextSelection.collapsed(
                                      offset: option.length),
                                  composing: TextRange.empty,
                                );
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
