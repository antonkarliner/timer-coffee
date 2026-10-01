import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../theme/design_tokens.dart';

/// The app's long-form Markdown style for Help Center articles and the
/// privacy policy.
MarkdownStyleSheet appMarkdownStyleSheet(ThemeData theme) {
  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    a: AppTextStyles.body.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.primary,
    ),
    p: AppTextStyles.body.copyWith(height: 1.5),
    pPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
    h1: AppTextStyles.headline,
    h1Padding: const EdgeInsets.only(
      top: AppSpacing.sm,
      bottom: AppSpacing.base,
    ),
    h2: AppTextStyles.title,
    h2Padding: const EdgeInsets.only(
      top: AppSpacing.base,
      bottom: AppSpacing.sm,
    ),
    h3: AppTextStyles.fieldLabel,
    h3Padding: const EdgeInsets.only(
      top: AppSpacing.sm,
      bottom: AppSpacing.xs,
    ),
    blockSpacing: AppSpacing.base,
    listIndent: AppSpacing.lg,
    listBullet: AppTextStyles.body,
    listBulletPadding: const EdgeInsets.only(right: AppSpacing.sm),
  );
}
