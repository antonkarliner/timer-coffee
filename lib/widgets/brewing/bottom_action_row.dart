import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';

class BottomActionRow extends StatelessWidget {
  const BottomActionRow({super.key, required this.leading, required this.action});

  final Widget leading;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.base,
          0,
          AppSpacing.base,
          AppSpacing.base,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                // Wrap the link's height so it can't stretch the row to fill
                // the screen. Its empty slot keeps the same horizontal space.
                heightFactor: 1.0,
                child: leading,
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            action,
          ],
        ),
      ),
    );
  }
}
