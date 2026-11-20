import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:flutter/material.dart';

class StatsRow extends StatelessWidget {
  const StatsRow({
    super.key,
    required this.identifier,
    required this.icon,
    required this.label,
    this.value,
    this.mutedValue = false,
    this.isLoading = false,
    this.isRecipe = false,
    this.onTap,
  });

  final String identifier;
  final IconData icon;
  final String label;
  final String? value;
  final bool mutedValue;
  final bool isLoading;
  final bool isRecipe;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final trailingValue = value;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppButton.heightMedium),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            SizedBox.square(
              dimension: AppIconSize.medium,
              child: Icon(
                icon,
                size: AppIconSize.medium,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: Text(
                label,
                style: isRecipe ? AppTextStyles.body : AppTextStyles.itemTitle,
                maxLines: isRecipe ? 2 : null,
                overflow: isRecipe ? TextOverflow.ellipsis : null,
              ),
            ),
            if (isLoading || trailingValue != null)
              const SizedBox(width: AppSpacing.sm),
            if (isLoading)
              const SizedBox.square(
                dimension: AppIconSize.small,
                child: CircularProgressIndicator(strokeWidth: AppStroke.focus),
              )
            else if (trailingValue != null)
              Text(
                trailingValue,
                textAlign: TextAlign.right,
                style: AppTextStyles.body.copyWith(
                  color: mutedValue
                      ? colorScheme.outline
                      : colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                size: AppIconSize.medium,
                color: colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );

    return Semantics(
      identifier: identifier,
      button: onTap != null ? true : null,
      child: onTap == null ? row : InkWell(onTap: onTap, child: row),
    );
  }
}

class StatsRowDivider extends StatelessWidget {
  const StatsRowDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: AppStroke.border,
      thickness: AppStroke.border,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
