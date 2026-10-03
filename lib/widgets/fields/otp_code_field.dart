import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/design_tokens.dart';

/// A single accessible text field presented as a segmented one-time-code bar.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    super.key,
    this.controller,
    this.focusNode,
    this.length = 6,
    this.label,
    this.onChanged,
    this.onCompleted,
    this.enabled = true,
    this.autofocus = false,
    this.errorText,
    this.semanticLabel,
    this.semanticIdentifier,
  }) : assert(length > 0);

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final int length;
  final String? label;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool enabled;
  final bool autofocus;
  final String? errorText;
  final String? semanticLabel;
  final String? semanticIdentifier;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  String? _lastCompletedCode;
  bool _isAdjustingSelection = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller.addListener(_handleTextChanged);
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(OtpCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_handleTextChanged);
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_handleTextChanged);
      _lastCompletedCode = null;
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_handleFocusChanged);
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_handleFocusChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.removeListener(_handleFocusChanged);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) setState(() {});
  }

  void _handleTextChanged() {
    if (_isAdjustingSelection) return;

    final code = _controller.text;
    final endSelection = TextSelection.collapsed(offset: code.length);
    if (_controller.selection != endSelection) {
      _isAdjustingSelection = true;
      _controller.selection = endSelection;
      _isAdjustingSelection = false;
    }

    widget.onChanged?.call(code);

    if (code.length == widget.length) {
      if (_lastCompletedCode != code) {
        _lastCompletedCode = code;
        widget.onCompleted?.call(code);
      }
    } else {
      _lastCompletedCode = null;
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final code = _controller.text;
    final activeCell = code.length >= widget.length
        ? widget.length - 1
        : code.length;
    // Mirrors LabeledField's greys, but the outer border stays at the focus
    // width in every state: at 1dp the segmented bar read as a hairline.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = widget.errorText != null
        ? colorScheme.error
        : _focusNode.hasFocus
        ? (isDark ? Colors.grey.shade300 : Colors.grey.shade700)
        : (isDark ? Colors.grey.shade600 : Colors.grey.shade400);
    final digitColor = widget.enabled
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.38);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: AppTextStyles.fieldLabel),
          const SizedBox(height: AppSpacing.sm),
        ],
        SizedBox(
          height: AppButton.heightLarge,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ExcludeSemantics(
                child: DecoratedBox(
                  // Painted over the cells so the active-cell tint can't
                  // cover the inner half of the border.
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: borderColor,
                      width: AppStroke.focus,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.field),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.field),
                    child: Row(
                      children: List.generate(widget.length, (index) {
                        final isActive =
                            widget.enabled &&
                            _focusNode.hasFocus &&
                            index == activeCell;
                        return Expanded(
                          child: DecoratedBox(
                            key: ValueKey('otp_cell_$index'),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? colorScheme.primary.withValues(alpha: 0.10)
                                  : null,
                              border: index == 0
                                  ? null
                                  : Border(
                                      left: BorderSide(
                                        color: borderColor,
                                        width: AppStroke.border,
                                      ),
                                    ),
                            ),
                            child: Center(
                              child: Text(
                                index < code.length ? code[index] : '',
                                style: AppTextStyles.title.copyWith(
                                  color: digitColor,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
              Semantics(
                identifier: widget.semanticIdentifier,
                label: widget.semanticLabel ?? widget.label,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  autofocus: widget.autofocus,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  enableInteractiveSelection: true,
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0),
                  ),
                  cursorColor: colorScheme.onSurface.withValues(alpha: 0),
                  showCursor: false,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        widget.errorText == null
            ? const SizedBox.shrink()
            : Text(
                widget.errorText!,
                style: AppTextStyles.caption.copyWith(color: colorScheme.error),
              ),
      ],
    );
  }
}
