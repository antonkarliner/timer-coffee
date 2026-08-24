import 'dart:convert';
import 'dart:io';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/new_beans/image_flow/selected_images_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('adds a second photo and updates the analyze action', (
    tester,
  ) async {
    final images = _createTestImages();
    addTearDown(images.dispose);
    List<XFile>? confirmed;

    await tester.pumpWidget(
      _testApp(
        SelectedImagesSheet(
          initialImages: [images.first],
          onAddPhoto: () async => images.second,
          onConfirm: (selected) async => confirmed = selected,
          onBackToSelection: () async {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Photos for AI scan'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('Analyze photo'), findsOneWidget);
    expect(find.text('Add another photo'), findsOneWidget);

    await tester.tap(find.text('Add another photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('Analyze 2 photos'), findsOneWidget);
    expect(find.text('Add another photo'), findsNothing);
    expect(find.bySemanticsLabel('Selected Image'), findsNWidgets(2));

    await tester.tap(find.text('Analyze 2 photos'));
    await tester.pump(const Duration(milliseconds: 11));

    expect(confirmed?.map((image) => image.path), [
      images.first.path,
      images.second.path,
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling the optional capture keeps the review sheet open', (
    tester,
  ) async {
    final images = _createTestImages();
    addTearDown(images.dispose);
    var addCalls = 0;

    await tester.pumpWidget(
      _testApp(
        SelectedImagesSheet(
          initialImages: [images.first],
          onAddPhoto: () async {
            addCalls += 1;
            return null;
          },
          onConfirm: (_) async {},
          onBackToSelection: () async {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Add another photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(addCalls, 1);
    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('Analyze photo'), findsOneWidget);
    expect(find.text('Add another photo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('zero photos keeps the singular analyze label disabled', (
    tester,
  ) async {
    final images = _createTestImages();
    addTearDown(images.dispose);

    await tester.pumpWidget(
      _testApp(
        SelectedImagesSheet(
          initialImages: [images.first],
          onAddPhoto: () async => images.second,
          onConfirm: (_) async {},
          onBackToSelection: () async {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(find.text('0/2'), findsOneWidget);
    expect(find.text('Add another photo'), findsOneWidget);
    expect(find.text('Analyze photo'), findsOneWidget);
    expect(find.text('Analyze 2 photos'), findsNothing);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _testApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

({XFile first, XFile second, VoidCallback dispose}) _createTestImages() {
  final directory = Directory.systemTemp.createTempSync(
    'selected-images-sheet-test-',
  );
  final bytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  );
  final first = File('${directory.path}/first.png');
  final second = File('${directory.path}/second.png');
  first.writeAsBytesSync(bytes);
  second.writeAsBytesSync(bytes);

  return (
    first: XFile(first.path),
    second: XFile(second.path),
    dispose: () => directory.deleteSync(recursive: true),
  );
}
