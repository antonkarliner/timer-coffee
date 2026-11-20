import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/widgets/brewing/bottom_action_row.dart';
import 'package:coffee_timer/widgets/recipe_detail/floating_nav_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void _setSurface(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

void main() {
  final action = find.byType(FloatingActionButton);
  final row = find.ancestor(of: action, matching: find.byType(Row));

  testWidgets('a long scaled link fits beside the full-size action', (
    tester,
  ) async {
    _setSurface(tester, const Size(320, 700));
    const label = 'Brew later · Reminder set for tomorrow morning';

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: BottomActionRow(
            leading: FittedBox(
              fit: BoxFit.scaleDown,
              child: AppTextButton(
                label: label,
                icon: Icons.alarm,
                isFullWidth: false,
                onPressed: () {},
              ),
            ),
            action: FloatingActionButton(onPressed: () {}),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final actionBounds = tester.getRect(action);
    final linkBounds = tester.getRect(find.byType(FittedBox));
    expect(linkBounds.left, AppSpacing.base);
    expect(
      linkBounds.right,
      lessThanOrEqualTo(actionBounds.left - AppSpacing.base),
    );
    expect(actionBounds.size, const Size.square(AppButton.heightLarge));
    expect(tester.getSize(row).height, actionBounds.height);
  });

  testWidgets('an empty leading slot keeps the action at the end', (tester) async {
    const surface = Size(320, 700);
    _setSurface(tester, surface);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BottomActionRow(
            leading: const SizedBox.shrink(),
            action: FloatingActionButton(onPressed: () {}),
          ),
        ),
      ),
    );

    final actionBounds = tester.getRect(action);
    expect(actionBounds.right, surface.width - AppSpacing.base);
    expect(tester.getSize(row).height, actionBounds.height);
  });

  testWidgets('an expanded stack pins the arrow below short content', (
    tester,
  ) async {
    const surface = Size(390, 844);
    const safeArea = FakeViewPadding(bottom: 34);
    _setSurface(tester, surface);
    tester.view.padding = safeArea;
    tester.view.viewPadding = safeArea;
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(),
          body: Stack(
            fit: StackFit.expand,
            children: [
              const SingleChildScrollView(child: Text('Short recipe')),
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                child: BottomActionRow(
                  leading: const SizedBox.shrink(),
                  action: FloatingNavButton(onPressed: () {}),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final bounds = tester.getRect(find.byType(FloatingNavButton));
    expect(bounds.bottom, surface.height - safeArea.bottom - AppSpacing.base);
    expect(bounds.right, surface.width - AppSpacing.base);
  });
}
