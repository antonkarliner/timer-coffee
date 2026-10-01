import 'dart:ui' show Tristate;

import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/settings/settings_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

SettingsValueRow _valueRow({
  String title = 'Zeitformat',
  String value = 'Automatisch (an Sprache angepasst)',
}) {
  return SettingsValueRow(
    identifier: 'valueRow',
    title: title,
    value: value,
    onTap: () {},
  );
}

Finder _rowText(String identifier, String text) => find.descendant(
  of: find.bySemanticsIdentifier(identifier),
  matching: find.text(text),
);

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

  testWidgets('navigation row uses item title weight and allows no icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SettingsNavRow(
          identifier: 'iconlessNavigation',
          title: 'General',
          onTap: () {},
        ),
      ),
    );

    final title = tester.renderObject<RenderParagraph>(find.text('General'));
    expect(title.text.style?.fontWeight, FontWeight.w600);
    final tile = tester.widget<ListTile>(find.byType(ListTile));
    expect(tile.leading, isNull);
  });

  testWidgets('long value uses at most half the title slot', (tester) async {
    // The test font draws every glyph 1 em wide, so 'Zeitformat' is ~160 pt
    // here (about twice its real width); 440 pt (the iPhone Pro Max width)
    // still leaves the title room for it while the value has to wrap.
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(_valueRow()));

    final tile = tester.widget<ListTile>(find.byType(ListTile));
    final titleSlotSize = tester.getSize(find.byWidget(tile.title!));
    final title = tester.renderObject<RenderParagraph>(
      _rowText('valueRow', 'Zeitformat'),
    );
    final value = tester.renderObject<RenderParagraph>(
      _rowText('valueRow', 'Automatisch (an Sprache angepasst)'),
    );

    final valueSingleLineHeight = value.getMaxIntrinsicHeight(double.infinity);
    final titleSingleLineHeight = title.getMaxIntrinsicHeight(double.infinity);
    expect(value.size.height, closeTo(valueSingleLineHeight * 2, 0.01));
    expect(value.size.width, lessThanOrEqualTo(titleSlotSize.width / 2));
    expect(title.size.height, closeTo(titleSingleLineHeight, 0.01));
  });

  testWidgets('short value leaves more than half the slot to a long title', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        _valueRow(title: 'Morgendliche Brüherinnerung jeden Tag', value: 'Aus'),
      ),
    );

    final tile = tester.widget<ListTile>(find.byType(ListTile));
    final titleSlotSize = tester.getSize(find.byWidget(tile.title!));
    final titleSize = tester.getSize(
      _rowText('valueRow', 'Morgendliche Brüherinnerung jeden Tag'),
    );
    expect(titleSize.width, greaterThan(titleSlotSize.width / 2));
  });

  testWidgets('value row mirrors title and value in RTL', (tester) async {
    await tester.pumpWidget(
      _app(
        Directionality(
          textDirection: TextDirection.rtl,
          child: _valueRow(title: 'Title', value: 'Value'),
        ),
      ),
    );

    expect(
      tester.getCenter(_rowText('valueRow', 'Value')).dx,
      lessThan(tester.getCenter(_rowText('valueRow', 'Title')).dx),
    );
  });

  testWidgets('value row supports intrinsic height and width', (tester) async {
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            IntrinsicHeight(child: _valueRow()),
            SizedBox(
              width: 320,
              child: IntrinsicWidth(child: _valueRow(value: 'Aus')),
            ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('value row with a subtitle places its title like other rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SettingsNavRow(
          identifier: 'navRow',
          title: 'Zeitformat',
          subtitle: 'Explanation',
          onTap: () {},
        ),
      ),
    );
    final navTitleTop = tester.getTopLeft(find.text('Zeitformat')).dy;

    await tester.pumpWidget(
      _app(
        SettingsValueRow(
          identifier: 'valueRow',
          title: 'Zeitformat',
          value: 'Aus',
          subtitle: 'Explanation',
          onTap: () {},
        ),
      ),
    );
    final valueTitleTop = tester.getTopLeft(find.text('Zeitformat')).dy;

    expect(valueTitleTop, closeTo(navTitleTop, 0.5));
  });

  testWidgets('value row reports a dry baseline', (tester) async {
    await tester.pumpWidget(
      _app(
        SettingsValueRow(
          identifier: 'valueRow',
          title: 'Zeitformat',
          value: 'Aus',
          subtitle: 'Explanation',
          onTap: () {},
        ),
      ),
    );

    final tile = tester.renderObject<RenderBox>(find.byType(ListTile));
    final baseline = tile.getDryBaseline(
      const BoxConstraints(maxWidth: 375),
      TextBaseline.alphabetic,
    );
    expect(baseline, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('headless sections preserve the Hub section gap', (tester) async {
    const firstKey = Key('firstSectionRow');
    const secondKey = Key('secondSectionRow');
    await tester.pumpWidget(
      _app(
        const Column(
          children: [
            SettingsSection(children: [SizedBox(key: firstKey, height: 20)]),
            SettingsSection(children: [SizedBox(key: secondKey, height: 20)]),
          ],
        ),
      ),
    );

    final gap =
        tester.getTopLeft(find.byKey(secondKey)).dy -
        tester.getBottomLeft(find.byKey(firstKey)).dy;
    expect(gap, AppSpacing.sectionGap);
  });

  testWidgets('headed sections preserve the Hub section gap', (tester) async {
    const firstKey = Key('firstSectionRow');
    await tester.pumpWidget(
      _app(
        const Column(
          children: [
            SettingsSection(children: [SizedBox(key: firstKey, height: 20)]),
            SettingsSection(header: 'Second', children: [SizedBox(height: 20)]),
          ],
        ),
      ),
    );

    final gap =
        tester.getTopLeft(find.text('Second')).dy -
        tester.getBottomLeft(find.byKey(firstKey)).dy;
    expect(gap, AppSpacing.sectionGap);
  });

  testWidgets('section renders its footer', (tester) async {
    await tester.pumpWidget(
      _app(
        const SettingsSection(footer: 'Footer note', children: [Text('Row')]),
      ),
    );

    expect(find.text('Footer note'), findsOneWidget);
  });

  testWidgets('switch row toggles from a row tap and exposes semantics', (
    tester,
  ) async {
    bool? changedTo;
    await tester.pumpWidget(
      _app(
        SettingsSwitchRow(
          identifier: 'switchRow',
          title: 'Enabled',
          value: true,
          onChanged: (value) => changedTo = value,
        ),
      ),
    );

    final row = find.bySemanticsIdentifier('switchRow');
    expect(tester.getSemantics(row).flagsCollection.isToggled, Tristate.isTrue);
    await tester.tap(find.text('Enabled'));
    expect(changedTo, isFalse);
  });

  testWidgets('switch row is disabled when onChanged is null', (tester) async {
    await tester.pumpWidget(
      _app(
        const SettingsSwitchRow(
          identifier: 'switchRow',
          title: 'Disabled',
          value: false,
          onChanged: null,
        ),
      ),
    );

    final tile = tester.widget<ListTile>(find.byType(ListTile));
    expect(tile.enabled, isFalse);
    await tester.tap(find.bySemanticsIdentifier('switchRow'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabled action row ignores taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        SettingsActionRow(
          identifier: 'disabledAction',
          title: 'Action',
          onTap: () => taps++,
          enabled: false,
        ),
      ),
    );

    await tester.tap(find.bySemanticsIdentifier('disabledAction'));
    expect(taps, 0);
  });

  testWidgets('destructive action row uses the error colour', (tester) async {
    late Color errorColor;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            errorColor = Theme.of(context).colorScheme.error;
            return Scaffold(
              body: SettingsActionRow(
                identifier: 'destructiveAction',
                title: 'Delete',
                onTap: () {},
                destructive: true,
              ),
            );
          },
        ),
      ),
    );

    final title = tester.renderObject<RenderParagraph>(find.text('Delete'));
    expect(title.text.style?.color, errorColor);
  });

  testWidgets('inline choice checks current option and changes selection', (
    tester,
  ) async {
    String? changedTo;
    await tester.pumpWidget(
      _app(
        SettingsInlineChoice<String>(
          options: _options,
          current: 'light',
          onChanged: (value) => changedTo = value,
        ),
      ),
    );

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
    expect(changedTo, 'dark');
  });

  testWidgets('choice sheet shows a drag handle', (tester) async {
    await tester.pumpWidget(_app(_choiceRow((_) {})));

    await tester.tap(find.bySemanticsIdentifier('themeChoice'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<BottomSheet>(find.byType(BottomSheet)).showDragHandle,
      isTrue,
    );
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
