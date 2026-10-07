import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/widgets/roaster/roaster_report_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _roasterProfileId = '11111111-2222-3333-4444-555555555555';
const _roasterName = 'Test Roastery';

// English ARB strings the tests interact with.
const _title = 'Report an error';
const _categoryWrongLocation = 'Wrong city or country';
const _categoryClosed = 'Permanently closed';
const _categoryOther = 'Something else';
const _submitLabel = 'Send report';
const _rateLimitedError = 'Too many reports. Please try again later.';
const _genericError = 'Couldn’t send the report. Please try again.';

/// Records every submitted body and returns a canned outcome.
class _FakeSubmitter {
  _FakeSubmitter(this.outcome);

  final RoasterReportOutcome outcome;
  final List<Map<String, dynamic>> bodies = [];

  Future<RoasterReportOutcome> call(Map<String, dynamic> body) async {
    bodies.add(Map<String, dynamic>.from(body));
    return outcome;
  }
}

Finder _submitFinder() => find.widgetWithText(AppElevatedButton, _submitLabel);

bool _submitEnabled(WidgetTester tester) =>
    tester.widget<AppElevatedButton>(_submitFinder()).onPressed != null;

/// Pumps a harness that opens the sheet with [submitter] and records the
/// resolved results. The tall surface keeps every category row on screen so
/// taps do not need scrolling.
Future<List<bool>> _openSheet(
  WidgetTester tester,
  _FakeSubmitter submitter,
) async {
  await tester.binding.setSurfaceSize(const Size(800, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final results = <bool>[];
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: AppTextButton(
              label: 'Open report sheet',
              onPressed: () async {
                results.add(
                  await showRoasterReportSheet(
                    context,
                    roasterProfileId: _roasterProfileId,
                    roasterName: _roasterName,
                    submitter: submitter.call,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open report sheet'));
  await tester.pumpAndSettle();
  return results;
}

void main() {
  testWidgets('submit is disabled until a category is picked', (tester) async {
    final submitter = _FakeSubmitter(RoasterReportOutcome.ok);
    await _openSheet(tester, submitter);

    expect(_submitEnabled(tester), isFalse);

    await tester.tap(find.text(_categoryWrongLocation));
    await tester.pumpAndSettle();

    expect(_submitEnabled(tester), isTrue);
  });

  testWidgets(
    'correction field appears for wrong_location, clears and disappears '
    'for closed',
    (tester) async {
      final submitter = _FakeSubmitter(RoasterReportOutcome.ok);
      await _openSheet(tester, submitter);

      // Only the details field exists before a category is picked.
      expect(find.byType(TextFormField), findsOneWidget);

      await tester.tap(find.text(_categoryWrongLocation));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNWidgets(2));

      await tester.enterText(find.byType(TextFormField).first, 'Lisbon');
      await tester.pump();
      expect(find.text('Lisbon'), findsOneWidget);

      // Switching to a category without a correction field removes it.
      await tester.tap(find.text(_categoryClosed));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Lisbon'), findsNothing);

      // Switching between two categories with the field clears the stale text.
      await tester.tap(find.text(_categoryWrongLocation));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Lisbon');
      await tester.pump();
      await tester.tap(find.text(_categoryOther));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_categoryWrongLocation));
      await tester.pumpAndSettle();
      expect(find.text('Lisbon'), findsNothing);
    },
  );

  testWidgets('other keeps submit disabled until details are entered', (
    tester,
  ) async {
    final submitter = _FakeSubmitter(RoasterReportOutcome.ok);
    await _openSheet(tester, submitter);

    await tester.tap(find.text(_categoryOther));
    await tester.pumpAndSettle();
    expect(_submitEnabled(tester), isFalse);

    await tester.enterText(
      find.byType(TextFormField).last,
      'It is actually a cafe',
    );
    await tester.pump();
    expect(_submitEnabled(tester), isTrue);
  });

  testWidgets('submitted body is correct and omits empty fields', (
    tester,
  ) async {
    final submitter = _FakeSubmitter(RoasterReportOutcome.ok);
    await _openSheet(tester, submitter);

    await tester.tap(find.text(_categoryWrongLocation));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      '  Lisbon, Portugal  ',
    );
    // Details left empty on purpose.
    await tester.tap(_submitFinder());
    await tester.pumpAndSettle();

    expect(submitter.bodies, hasLength(1));
    final body = submitter.bodies.single;
    expect(body['kind'], 'report');
    expect(body['roasterProfileId'], _roasterProfileId);
    expect(body['category'], 'wrong_location');
    expect(body['suggestedValue'], 'Lisbon, Portugal');
    expect(body.containsKey('details'), isFalse);
  });

  testWidgets('ok outcome closes the sheet and resolves true', (tester) async {
    final submitter = _FakeSubmitter(RoasterReportOutcome.ok);
    final results = await _openSheet(tester, submitter);

    await tester.tap(find.text(_categoryWrongLocation));
    await tester.pumpAndSettle();
    await tester.tap(_submitFinder());
    await tester.pumpAndSettle();

    expect(find.text(_title), findsNothing);
    expect(results, [true]);
  });

  testWidgets('rateLimited outcome shows the inline error and stays open', (
    tester,
  ) async {
    final submitter = _FakeSubmitter(RoasterReportOutcome.rateLimited);
    await _openSheet(tester, submitter);

    await tester.tap(find.text(_categoryWrongLocation));
    await tester.pumpAndSettle();
    await tester.tap(_submitFinder());
    await tester.pumpAndSettle();

    expect(find.text(_rateLimitedError), findsOneWidget);
    expect(find.text(_title), findsOneWidget);
  });

  testWidgets('error outcome shows the inline error and stays open', (
    tester,
  ) async {
    final submitter = _FakeSubmitter(RoasterReportOutcome.error);
    await _openSheet(tester, submitter);

    await tester.tap(find.text(_categoryWrongLocation));
    await tester.pumpAndSettle();
    await tester.tap(_submitFinder());
    await tester.pumpAndSettle();

    expect(find.text(_genericError), findsOneWidget);
    expect(find.text(_title), findsOneWidget);
  });
}
