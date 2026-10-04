import 'dart:async';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/fields/dropdown_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildSubject({
  Future<List<String>> Function(String)? initialSuggestions,
  required Future<List<String>> Function(String) onSearch,
  TextEditingController? controller,
  FocusNode? focusNode,
  ValueChanged<String>? onChanged,
  bool autofocus = false,
  bool inlineSuggestions = false,
  Widget? below,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownSearchField(
            label: 'Grind size',
            initialValue: controller == null ? '24 clicks' : null,
            controller: controller,
            focusNode: focusNode,
            initialSuggestions: initialSuggestions,
            onSearch: onSearch,
            onChanged: onChanged,
            autofocus: autofocus,
            inlineSuggestions: inlineSuggestions,
          ),
          ?below,
        ],
      ),
    ),
  );
}

// The dropdown's follower hangs below the field (bottomLeft -> topLeft); the
// text field's own selection handles use followers too, so match on anchors.
final _dropdownOverlay = find.byWidgetPredicate(
  (widget) =>
      widget is CompositedTransformFollower &&
      widget.targetAnchor == Alignment.bottomLeft &&
      widget.followerAnchor == Alignment.topLeft,
);

void _expectNoStatusRows() {
  expect(find.text('No results found'), findsNothing);
  expect(find.textContaining('Use "'), findsNothing);
  expect(find.text('Searching...'), findsNothing);
}

void main() {
  testWidgets('inline list pushes content down and preserves input focus', (
    tester,
  ) async {
    final afterClear = Completer<List<String>>();
    final search = Completer<List<String>>();
    var initialCalls = 0;
    await tester.pumpWidget(
      _buildSubject(
        inlineSuggestions: true,
        below: const Text('Below field'),
        initialSuggestions: (_) => ++initialCalls == 1
            ? Future.value(['Fine', 'Medium'])
            : afterClear.future,
        onSearch: (_) => search.future,
      ),
    );
    final input = find.byType(TextFormField);
    final editable = find.byType(EditableText);
    final originalState = tester.state<EditableTextState>(editable);
    final originalTop = tester.getTopLeft(find.text('Below field')).dy;

    await tester.tap(input);
    await tester.pumpAndSettle();
    expect(_dropdownOverlay, findsNothing);
    expect(
      find.descendant(
        of: find.byType(DropdownSearchField),
        matching: find.text('Fine'),
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.text('Below field')).dy,
      greaterThan(originalTop),
    );
    expect(originalState.widget.focusNode.hasFocus, isTrue);
    expect(tester.state<EditableTextState>(editable), same(originalState));

    await tester.enterText(input, 'M');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text('Searching...'), findsOneWidget);
    expect(originalState.widget.focusNode.hasFocus, isTrue);
    search.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('No results found'), findsOneWidget);
    expect(find.text('Use "M"'), findsOneWidget);
    expect(_dropdownOverlay, findsNothing);

    await tester.enterText(input, '');
    await tester.pump();
    expect(find.text('Fine'), findsNothing);
    expect(tester.getTopLeft(find.text('Below field')).dy, originalTop);
    expect(tester.state<EditableTextState>(editable), same(originalState));
    expect(originalState.widget.focusNode.hasFocus, isTrue);
    afterClear.complete(['Fine']);
    await tester.pumpAndSettle();
    expect(find.text('Fine'), findsOneWidget);
    expect(originalState.widget.focusNode.hasFocus, isTrue);
    expect(tester.state<EditableTextState>(editable), same(originalState));
    expect(_dropdownOverlay, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('prefilled focus loads initial suggestions with current text', (
    tester,
  ) async {
    final initialCalls = <String>[];
    final searches = <String>[];
    await tester.pumpWidget(
      _buildSubject(
        initialSuggestions: (text) async {
          initialCalls.add(text);
          return ['Fine', 'Medium', 'Coarse'];
        },
        onSearch: (query) async {
          searches.add(query);
          return ['Search result'];
        },
      ),
    );
    await tester.tap(find.byType(TextFormField));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(initialCalls, ['24 clicks']);
    expect(searches, isEmpty);
    expect(find.text('Fine'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Coarse'), findsOneWidget);
    expect(_dropdownOverlay, findsOneWidget);
    _expectNoStatusRows();
  });

  testWidgets(
    'cursor moves keep initial suggestions and parent notifications',
    (tester) async {
      final controller = TextEditingController(text: '24 clicks');
      addTearDown(controller.dispose);
      final searches = <String>[];
      final changes = <String>[];
      await tester.pumpWidget(
        _buildSubject(
          controller: controller,
          initialSuggestions: (_) async => ['Fine'],
          onChanged: changes.add,
          onSearch: (query) async {
            searches.add(query);
            return ['Search result'];
          },
        ),
      );
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();
      final beforeMove = changes.length;
      await tester.tapAt(
        tester.getTopLeft(find.byType(TextFormField)) + const Offset(20, 40),
      );
      controller.selection = const TextSelection.collapsed(offset: 2);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(changes.length, greaterThan(beforeMove));
      expect(changes.last, '24 clicks');
      expect(searches, isEmpty);
      expect(find.text('Fine'), findsOneWidget);
    },
  );

  testWidgets('typing switches to debounced search results', (tester) async {
    final searches = <String>[];
    await tester.pumpWidget(
      _buildSubject(
        initialSuggestions: (_) async => ['Fine'],
        onSearch: (query) async {
          searches.add(query);
          return ['Search result'];
        },
      ),
    );
    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '24 clicksx');
    expect(searches, isEmpty);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(searches, ['24 clicksx']);
    expect(find.text('Search result'), findsOneWidget);
    expect(find.text('Fine'), findsNothing);
  });

  testWidgets(
    'clearing restores initial suggestions and resets duplicate query',
    (tester) async {
      final initialCalls = <String>[];
      final searches = <String>[];
      await tester.pumpWidget(
        _buildSubject(
          initialSuggestions: (text) async {
            initialCalls.add(text);
            return ['Fine'];
          },
          onSearch: (query) async {
            searches.add(query);
            return ['Search result'];
          },
        ),
      );
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Med');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '');
      await tester.pumpAndSettle();
      expect(initialCalls, ['24 clicks', '']);
      expect(find.text('Fine'), findsOneWidget);
      expect(find.text('Search result'), findsNothing);
      _expectNoStatusRows();
      await tester.enterText(find.byType(TextFormField), 'Med');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(searches, ['Med', 'Med']);
      expect(find.text('Search result'), findsOneWidget);
    },
  );

  testWidgets('clearing cancels a search still waiting for debounce', (
    tester,
  ) async {
    final searches = <String>[];
    await tester.pumpWidget(
      _buildSubject(
        initialSuggestions: (_) async => ['Fine'],
        onSearch: (query) async {
          searches.add(query);
          return ['Search result'];
        },
      ),
    );
    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Med');
    await tester.enterText(find.byType(TextFormField), '');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(searches, isEmpty);
    expect(find.text('Fine'), findsOneWidget);
    _expectNoStatusRows();
  });

  testWidgets('empty initial results show no overlay', (tester) async {
    await tester.pumpWidget(
      _buildSubject(
        initialSuggestions: (_) async => [],
        onSearch: (_) async => ['Search result'],
      ),
    );
    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();
    _expectNoStatusRows();
    expect(_dropdownOverlay, findsNothing);
  });

  testWidgets('selecting initial suggestion sets text and notifies parent', (
    tester,
  ) async {
    final changes = <String>[];
    await tester.pumpWidget(
      _buildSubject(
        initialSuggestions: (_) async => ['Fine'],
        onSearch: (_) async => [],
        onChanged: changes.add,
      ),
    );
    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fine'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      'Fine',
    );
    expect(changes.last, 'Fine');
    expect(_dropdownOverlay, findsNothing);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );
  });

  testWidgets(
    'without initial suggestions focus retains the legacy empty state',
    (tester) async {
      final focusNode = FocusNode();
      final controller = TextEditingController.fromValue(
        const TextEditingValue(
          text: '24 clicks',
          selection: TextSelection.collapsed(offset: 9),
        ),
      );
      addTearDown(focusNode.dispose);
      addTearDown(controller.dispose);
      final searches = <String>[];
      await tester.pumpWidget(
        _buildSubject(
          focusNode: focusNode,
          controller: controller,
          onSearch: (query) async {
            searches.add(query);
            return [];
          },
        ),
      );
      // Request focus without a tap changing selection: the existing focus
      // handler opens the empty/custom-entry overlay but does not search.
      focusNode.requestFocus();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(searches, isEmpty);
      expect(find.text('No results found'), findsOneWidget);
      expect(find.text('Use "24 clicks"'), findsOneWidget);
    },
  );

  testWidgets('autofocus shows initial suggestions after the first frames', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildSubject(
        autofocus: true,
        initialSuggestions: (_) async => ['Fine'],
        onSearch: (_) async => [],
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Fine'), findsOneWidget);
    _expectNoStatusRows();
  });

  testWidgets('initial loading and errors stay invisible', (tester) async {
    final pending = Completer<List<String>>();
    await tester.pumpWidget(
      _buildSubject(
        initialSuggestions: (_) => pending.future,
        onSearch: (_) async => [],
      ),
    );
    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    _expectNoStatusRows();
    expect(_dropdownOverlay, findsNothing);
    pending.completeError(StateError('Unavailable'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(SnackBar), findsNothing);
    expect(_dropdownOverlay, findsNothing);
  });

  testWidgets('late initial result cannot replace a newer search', (
    tester,
  ) async {
    final pending = Completer<List<String>>();
    await tester.pumpWidget(
      _buildSubject(
        initialSuggestions: (_) => pending.future,
        onSearch: (_) async => ['Search result'],
      ),
    );
    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField), 'Med');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    pending.complete(['Stale initial']);
    await tester.pumpAndSettle();
    expect(find.text('Search result'), findsOneWidget);
    expect(find.text('Stale initial'), findsNothing);
  });

  testWidgets(
    'late search result cannot replace initial suggestions after clearing',
    (tester) async {
      final pending = Completer<List<String>>();
      await tester.pumpWidget(
        _buildSubject(
          initialSuggestions: (_) async => ['Fine'],
          onSearch: (_) => pending.future,
        ),
      );
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Med');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byType(TextFormField), '');
      await tester.pumpAndSettle();
      pending.complete(['Stale search']);
      await tester.pumpAndSettle();
      expect(find.text('Fine'), findsOneWidget);
      expect(find.text('Stale search'), findsNothing);
    },
  );

  testWidgets('search results from an older query are ignored', (tester) async {
    final first = Completer<List<String>>();
    await tester.pumpWidget(
      _buildSubject(
        initialSuggestions: (_) async => ['Fine'],
        onSearch: (query) =>
            query == 'M' ? first.future : Future.value(['Latest']),
      ),
    );
    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'M');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextFormField), 'Me');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    first.complete(['Stale search']);
    await tester.pumpAndSettle();
    expect(find.text('Latest'), findsOneWidget);
    expect(find.text('Stale search'), findsNothing);
  });

  testWidgets('initial results are ignored after focus loss and disposal', (
    tester,
  ) async {
    final pending = Completer<List<String>>();
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      _buildSubject(
        focusNode: focusNode,
        initialSuggestions: (_) => pending.future,
        onSearch: (_) async => [],
      ),
    );
    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    focusNode.unfocus();
    await tester.pump();
    pending.complete(['Stale initial']);
    await tester.pumpAndSettle();
    expect(find.text('Stale initial'), findsNothing);
    final afterDispose = Completer<List<String>>();
    await tester.pumpWidget(
      _buildSubject(
        focusNode: focusNode,
        initialSuggestions: (_) => afterDispose.future,
        onSearch: (_) async => [],
      ),
    );
    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    afterDispose.complete(['Disposed result']);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Disposed result'), findsNothing);
  });
}
