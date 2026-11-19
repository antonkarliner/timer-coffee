import 'package:coffee_timer/widgets/app_bar_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _appBar({required Widget title, List<Widget>? actions}) {
  return MaterialApp(
    home: Scaffold(appBar: AppBar(title: title, actions: actions)),
  );
}

void main() {
  testWidgets('renders the icon and text', (tester) async {
    await tester.pumpWidget(
      _appBar(title: const AppBarTitle(text: 'Settings', icon: Icons.settings)),
    );

    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('accepts a leading widget instead of an icon', (tester) async {
    await tester.pumpWidget(
      _appBar(
        title: const AppBarTitle(text: 'Coffee', leading: Text('☕')),
      ),
    );

    expect(find.text('☕'), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
  });

  testWidgets('ellipsizes long text beside three actions at 320 wide', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const title = 'A very long app-bar title that must fit beside three actions';

    await tester.pumpWidget(
      _appBar(
        title: const AppBarTitle(text: title, icon: Icons.coffee),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.edit)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.widget<Text>(find.text(title)).overflow, TextOverflow.ellipsis);
  });

  testWidgets('places the icon to the right of the text in RTL', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              title: const AppBarTitle(text: 'Coffee', icon: Icons.coffee),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getCenter(find.byIcon(Icons.coffee)).dx,
      greaterThan(tester.getCenter(find.text('Coffee')).dx),
    );
  });
}
