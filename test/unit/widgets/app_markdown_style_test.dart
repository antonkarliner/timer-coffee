import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/visual/color_schemes.dart';
import 'package:coffee_timer/widgets/markdown/app_markdown_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the app long-form Markdown tokens', () {
    // MaterialApp localizes the theme before any page sees it; fromTheme
    // asserts on the font sizes that step adds.
    final theme = ThemeData.localize(
      ThemeData(colorScheme: lightColorScheme),
      Typography.material2021().englishLike,
    );
    final sheet = appMarkdownStyleSheet(theme);

    expect(sheet.h1?.fontSize, AppTextStyles.headline.fontSize);
    expect(sheet.h1?.fontWeight, AppTextStyles.headline.fontWeight);
    expect(sheet.h2?.fontSize, AppTextStyles.title.fontSize);
    expect(sheet.h2?.fontWeight, AppTextStyles.title.fontWeight);
    expect(sheet.h3?.fontSize, AppTextStyles.fieldLabel.fontSize);
    expect(sheet.h3?.fontWeight, AppTextStyles.fieldLabel.fontWeight);
    expect(sheet.p?.fontSize, AppTextStyles.body.fontSize);
    expect(sheet.p?.fontWeight, AppTextStyles.body.fontWeight);
    expect(sheet.p?.height, 1.5);
    expect(sheet.a?.color, lightColorScheme.primary);
    expect(sheet.a?.decoration, TextDecoration.underline);
    expect(sheet.a?.decorationColor, lightColorScheme.primary);
    expect(
      sheet.pPadding,
      const EdgeInsets.only(bottom: AppSpacing.sm),
    );
    expect(
      sheet.h1Padding,
      const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.base,
      ),
    );
    expect(
      sheet.h2Padding,
      const EdgeInsets.only(
        top: AppSpacing.base,
        bottom: AppSpacing.sm,
      ),
    );
    expect(
      sheet.h3Padding,
      const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.xs,
      ),
    );
    expect(sheet.blockSpacing, AppSpacing.base);
    expect(sheet.listIndent, AppSpacing.lg);
    expect(sheet.listBullet, AppTextStyles.body);
    expect(
      sheet.listBulletPadding,
      const EdgeInsets.only(right: AppSpacing.sm),
    );
  });
}
