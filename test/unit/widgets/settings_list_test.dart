import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/settings/settings_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _options = [
  SettingsChoiceOption<String>(
    value: 'system',
    label: 'System',
    identifier: 'themeSystem',
  ),
  SettingsChoiceOption<String>(
    value: 'light',
    label: 'Light',
    identifier: 'themeLight',
  ),
  SettingsChoiceOption<String>(
    value: 'dark',
    label: 'Dark',
    identifier: 'themeDark',
  ),
];

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

Widget _choiceRow(ValueChanged<String> onChanged) {
  return SettingsChoiceRow<String>(
    identifier: 'themeChoice',
    title: 'Theme',
    options: _options,
    current: 'light',
    onChanged: onChanged,
  );
}

void main() {
  testWidgets('choice row shows current value and changes to another option', (
    tester,
  ) async {
    String? changedTo;
    await tester.pumpWidget(_app(_choiceRow((value) => changedTo = value)));

    expect(find.text('Light'), findsOneWidget);
    await tester.tap(find.bySemanticsIdentifier('themeChoice'));
    await tester.pumpAndSettle();

    expect(find.text('Theme'), findsNWidgets(2));
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(
      find.descendant(
        of: find.bySemanticsIdentifier('themeLight'),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.bySemanticsIdentifier('themeDark'),
        matching: find.byIcon(Icons.check),
      ),
      findsNothing,
    );

    await tester.tap(find.bySemanticsIdentifier('themeDark'));
    await tester.pumpAndSettle();
    expect(changedTo, 'dark');
  });

  testWidgets('choosing the current value does not call onChanged', (
    tester,
  ) async {
    var changes = 0;
    await tester.pumpWidget(_app(_choiceRow((_) => changes++)));

    await tester.tap(find.bySemanticsIdentifier('themeChoice'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('themeLight'));
    await tester.pumpAndSettle();

    expect(changes, 0);
  });

  testWidgets('dismissing the choice sheet does not call onChanged', (
    tester,
  ) async {
    var changes = 0;
    await tester.pumpWidget(_app(_choiceRow((_) => changes++)));

    await tester.tap(find.bySemanticsIdentifier('themeChoice'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(1, 1));
    await tester.pumpAndSettle();

    expect(changes, 0);
    expect(find.bySemanticsIdentifier('themeLight'), findsNothing);
  });

  testWidgets(
    'long choice sheet scrolls to the last option on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final options = List.generate(
        25,
        (index) => SettingsChoiceOption<int>(
          value: index,
          label: 'Option $index',
          identifier: 'option$index',
        ),
      );

      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showSettingsChoiceSheet<int>(
                context: context,
                title: 'Long list',
                options: options,
                current: 0,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.bySemanticsIdentifier('option24'),
        AppSpacing.xxl,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Option 24'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('short choice sheet sizes to its content', (tester) async {
    await tester.pumpWidget(_app(_choiceRow((_) {})));

    await tester.tap(find.bySemanticsIdentifier('themeChoice'));
    await tester.pumpAndSettle();

    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final sheetHeight = tester.getSize(find.byType(BottomSheet)).height;
    expect(sheetHeight, lessThan(screenHeight * 0.5));
  });

  testWidgets('choice row with a value missing from its options still builds', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SettingsChoiceRow<String>(
          identifier: 'themeChoice',
          title: 'Theme',
          options: _options,
          current: 'sepia',
          onChanged: (_) {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Theme'), findsOneWidget);
  });

  testWidgets('navigation row renders and exposes its identifier', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        SettingsNavRow(
          identifier: 'notificationsSettings',
          icon: Icons.notifications,
          title: 'Notifications',
          subtitle: 'Alerts are on',
          onTap: () => taps++,
        ),
      ),
    );

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Alerts are on'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    final row = find.bySemanticsIdentifier('notificationsSettings');
    expect(row, findsOneWidget);
    expect(tester.getSemantics(row).flagsCollection.isButton, isTrue);
    await tester.tap(row);
    expect(taps, 1);
  });

  testWidgets('section header renders with header semantics', (tester) async {
    await tester.pumpWidget(
      _app(const SettingsSectionHeader(title: 'Appearance')),
    );

    expect(find.text('Appearance'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.header == true,
      ),
      findsOneWidget,
    );
  });

  testWidgets('page scaffold renders without a router', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsPageScaffold(
          title: 'Settings category',
          children: [Text('Category content')],
        ),
      ),
    );

    expect(find.text('Settings category'), findsOneWidget);
    expect(find.text('Category content'), findsOneWidget);
    expect(find.bySemanticsIdentifier('settingsBackButton'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
