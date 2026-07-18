import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/widgets/fields/chip_input.dart';
import 'package:coffee_timer/widgets/new_beans/optional_details/sections/flavor_profile_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for the beans add/edit tasting-notes data-loss bug:
/// [ChipInput] only turns typed text into a chip on submit/suggestion tap,
/// so text still sitting in the field was silently dropped on a direct Save
/// tap. [NewBeansScreen] now folds the pending controller text in via
/// [chipsWithPending] at save time, mirroring the brew diary tags fix
/// ([diaryTagsWithPending] in lib/utils/diary_tags.dart).
void main() {
  Widget host(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    );
  }

  group('chipsWithPending', () {
    test('trims whitespace from the pending text', () {
      expect(
        chipsWithPending(['fruity'], '  kettle  '),
        ['fruity', 'kettle'],
      );
    });

    test('empty pending text returns the original list', () {
      expect(chipsWithPending(['fruity'], ''), ['fruity']);
    });

    test('whitespace-only pending text returns the original list', () {
      expect(chipsWithPending(['fruity'], '   '), ['fruity']);
    });

    test('duplicate pending text (exact match after trim) is not appended', () {
      expect(chipsWithPending(['fruity'], ' fruity '), ['fruity']);
    });

    test('non-duplicate pending text is appended at the end', () {
      expect(chipsWithPending(['fruity', 'nutty'], 'kettle'), [
        'fruity',
        'nutty',
        'kettle',
      ]);
    });
  });

  group('FlavorProfileSection + pending controller (NewBeansScreen wiring)', () {
    testWidgets(
      'typed-but-unsubmitted tasting note is included on a direct Save tap',
      (tester) async {
        List<String>? captured;
        final harnessKey = GlobalKey<_HarnessState>();

        await tester.pumpWidget(
          host(
            _Harness(
              key: harnessKey,
              onSave: (values) => captured = values,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final input = find.byType(TextFormField);

        // First note: typed and submitted, so it becomes a committed chip.
        await tester.enterText(input, 'chocolate');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        // ChipInput requests focus again 100ms after adding a chip; advance
        // past that so no timer is left pending when the test ends.
        await tester.pump(const Duration(milliseconds: 150));

        expect(find.text('Chocolate'), findsOneWidget);
        expect(harnessKey.currentState!.controller.text, isEmpty);

        // Second note: typed but never submitted.
        await tester.enterText(input, 'citrus');
        await tester.pump();

        await tester.tap(find.byType(AppElevatedButton));
        await tester.pump();

        expect(captured, ['chocolate', 'citrus']);
      },
    );

    testWidgets(
      'a pending duplicate of an existing chip is not double-saved',
      (tester) async {
        List<String>? captured;

        await tester.pumpWidget(
          host(_Harness(onSave: (values) => captured = values)),
        );
        await tester.pumpAndSettle();

        final input = find.byType(TextFormField);

        // Commit 'fruity' as a chip first.
        await tester.enterText(input, 'fruity');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        // ChipInput requests focus again 100ms after adding a chip; advance
        // past that so no timer is left pending when the test ends.
        await tester.pump(const Duration(milliseconds: 150));

        expect(find.text('Fruity'), findsOneWidget);

        // Type the same value again without submitting it.
        await tester.enterText(input, 'fruity');
        await tester.pump();

        await tester.tap(find.byType(AppElevatedButton));
        await tester.pump();

        expect(captured, ['fruity']);
      },
    );
  });
}

/// Minimal harness wiring [FlavorProfileSection] the same way
/// [NewBeansScreen] does: a screen-lifetime pending [TextEditingController]
/// plus a Save button that folds it in via [chipsWithPending].
class _Harness extends StatefulWidget {
  final ValueChanged<List<String>> onSave;

  const _Harness({super.key, required this.onSave});

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  List<String> _notes = [];
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FlavorProfileSection(
          tastingNotes: _notes,
          tastingNotesOptions: Future.value(const <String>[]),
          onTastingNotesChanged: (values) => setState(() => _notes = values),
          pendingController: controller,
        ),
        AppElevatedButton(
          label: 'Save',
          onPressed: () => widget.onSave(chipsWithPending(_notes, controller.text)),
        ),
      ],
    );
  }
}
