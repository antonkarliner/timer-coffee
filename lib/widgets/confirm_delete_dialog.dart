import 'package:flutter/material.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import '../theme/design_tokens.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmLabel;
  final String cancelLabel;

  const ConfirmDeleteDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.confirmLabel,
    required this.cancelLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        AppTextButton(
          label: cancelLabel,
          onPressed: () => Navigator.of(context).pop(false),
          isFullWidth: false,
          height: AppButton.heightSmall,
          padding: AppButton.paddingSmall,
        ),
        AppElevatedButton(
          label: confirmLabel,
          onPressed: () => Navigator.of(context).pop(true),
          isFullWidth: false,
          height: AppButton.heightSmall,
          padding: AppButton.paddingSmall,
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
      ],
    );
  }
}
