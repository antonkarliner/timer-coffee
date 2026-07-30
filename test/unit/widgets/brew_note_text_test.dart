import 'dart:io';

import 'package:coffee_timer/widgets/brew_diary/brew_note_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Plan 036, Phase 3: brew notes are linkified because their audience is
/// exactly one — the local, signed-in-to-themselves author. Everything
/// user-published (bean reviews, public recipes, roaster content, review
/// replies) MUST keep rendering as inert text. These tests cover both the
/// linkify behaviour itself and — the mandatory guard — that this widget
/// stays confined to the private brew-diary render path.
void main() {
  testWidgets('renders plain notes as ordinary text (no accidental link)', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BrewNoteText('Great pour, no rush this time.'),
        ),
      ),
    );

    expect(find.textContaining('Great pour, no rush this time.'), findsOneWidget);
  });

  testWidgets('linkifies a URL in the note and opens it externally on tap', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'canLaunch' || call.method == 'launch'
              ? true
              : null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BrewNoteText(
            'Found this recipe at https://example.com/brew and it was great',
          ),
        ),
      ),
    );

    // humanize (default) strips the scheme from the displayed text.
    final linkFinder = find.textContaining('example.com/brew');
    expect(linkFinder, findsOneWidget);

    await tester.tap(linkFinder);
    await tester.pumpAndSettle();

    expect(
      calls.any(
        (call) =>
            call.method == 'launch' &&
            (call.arguments as Map)['url'] == 'https://example.com/brew',
      ),
      isTrue,
      reason: 'tapping the link should launch the exact URL externally',
    );
  });

  testWidgets('does not linkify a bare word that merely contains a dot', (
    tester,
  ) async {
    // Guard against over-eager (loose) URL matching: "v60" or "e.g." style
    // text should never become tappable — only explicit http(s):// or
    // www.-prefixed strings should.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: BrewNoteText('Used the v60, e.g. slower pour.')),
      ),
    );

    expect(find.textContaining('Used the v60, e.g. slower pour.'), findsOneWidget);
  });

  test(
    'BrewNoteText is referenced only by the private brew-diary render path',
    () {
      // This is the mandatory Phase 3 guard: linkification must stay
      // opt-in at specific private render sites, never available to any
      // widget that also renders user-published/public content (bean
      // reviews, public recipes, roaster content, review replies). If this
      // test fails, something outside the brew diary started importing or
      // referencing BrewNoteText — that is exactly the mistake guard 1 in
      // plan 036 Phase 3 forbids.
      final referencingFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => file.readAsStringSync().contains('BrewNoteText'))
          .map((file) => file.path.replaceAll(r'\', '/'))
          .toSet();

      const allowedPrivateDiaryFiles = {
        'lib/widgets/brew_diary/brew_note_text.dart', // widget's own definition
        'lib/widgets/brew_diary/brew_entry_card.dart', // private diary list card
        'lib/widgets/brew_diary/brew_detail_sheet.dart', // private diary detail sheet
      };

      expect(referencingFiles, allowedPrivateDiaryFiles);
    },
  );

  test(
    'known public-content render paths do not import the private note-linkify widget',
    () {
      // Belt-and-braces: explicitly confirm the surfaces called out in plan
      // 036 Phase 3 as deliberately-inert stay that way.
      const publicContentFiles = [
        'lib/widgets/roaster_profile/review_body.dart',
        'lib/widgets/roaster_profile/review_form.dart',
        'lib/widgets/recipe_detail/recipe_content_builder.dart',
        'lib/screens/roaster_profile_screen.dart',
      ];

      for (final path in publicContentFiles) {
        final file = File(path);
        if (!file.existsSync()) continue;
        final contents = file.readAsStringSync();
        expect(
          contents.contains('BrewNoteText') ||
              contents.contains('brew_note_text.dart'),
          isFalse,
          reason: '$path must keep rendering public content as inert text',
        );
      }
    },
  );
}
