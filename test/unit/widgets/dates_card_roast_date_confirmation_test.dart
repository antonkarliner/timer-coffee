import 'dart:async';

import 'package:coffee_timer/controllers/new_beans_image_controller.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/providers/coffee_beans_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/screens/new_beans_screen.dart';
import 'package:coffee_timer/services/photo_library_service.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/widgets/fields/date_field.dart';
import 'package:coffee_timer/widgets/new_beans/dates_card.dart';
import 'package:coffee_timer/widgets/new_beans/image_flow/collected_data_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/coffee_beans_controller_async_context_test.mocks.dart';
import 'brew_flow_async_context_test.mocks.dart' as brew_mocks;

/// Regression coverage for plan 051 phase 2 (scanned-label roast-date
/// confirmation prompt).
///
/// [DatesCard] gained `roastDateRawText` / `needsConfirmation` /
/// `onRoastDateConfirmed`: when the backend flags a scanned label's roast
/// date as ambiguous, a hint row asks the user to confirm or add it. These
/// tests pin down:
///   1. the flagged-with-raw-text rendering (prompt wording + raw text
///      actually visible, not just a widget existing somewhere),
///   2. the flagged-with-no-raw-text rendering ("not found" wording, and
///      NOT the prompt wording),
///   3. that the pre-existing bare-DateField UI is byte-for-byte unchanged
///      when `needsConfirmation` is false and no raw text is supplied, and
///   4. — the important one — that an older backend/app response shaped
///      without the two new keys at all (`roastDateRawText`,
///      `roastDateNeedsConfirmation`) still fills the roast date and shows
///      no confirmation hint. That last case is driven through the real
///      [NewBeansScreen]._fillFields code path (via a fake
///      [NewBeansImageController] that hands a raw response map to the
///      screen's `onData` callback, exactly as the real scan flow does) —
///      not a hand-typed restatement of the map-reading logic — so a
///      regression in the actual null-safe reads would fail this test.
void main() {
  Widget host(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  // NOTE on the two-phase pump below: this mirrors the real app sequence —
  // [NewBeansScreen] always mounts `DatesCard` with `roastDate: null` first,
  // then fills it in later via a single `setState` (see `_fillFields`).
  // [DateField] used to silently fail to display a date supplied on its
  // very first mount (a bug in its `initState`/`AppLocalizations` handling,
  // now fixed — see the "mounted with non-null initialValue" test below and
  // the roast-date-confirmation-sequence test further down, which pins down
  // the exact single-setState transition that used to blank the field).
  Future<AppLocalizations> pumpNarrowDatesCard(
    WidgetTester tester, {
    required DateTime? roastDate,
    String? roastDateRawText,
    bool needsConfirmation = false,
    VoidCallback? onRoastDateConfirmed,
    ValueChanged<DateTime?>? onRoastDateChanged,
  }) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      host(
        DatesCard(
          harvestDate: null,
          roastDate: null,
          onHarvestDateChanged: (_) {},
          onRoastDateChanged: onRoastDateChanged ?? (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      host(
        DatesCard(
          harvestDate: null,
          roastDate: roastDate,
          onHarvestDateChanged: (_) {},
          onRoastDateChanged: onRoastDateChanged ?? (_) {},
          roastDateRawText: roastDateRawText,
          needsConfirmation: needsConfirmation,
          onRoastDateConfirmed: onRoastDateConfirmed,
        ),
      ),
    );
    await tester.pumpAndSettle();

    return AppLocalizations.of(tester.element(find.byType(DatesCard)))!;
  }

  group('DatesCard roast date confirmation hint', () {
    testWidgets('flagged with raw text shows the confirm prompt and the '
        'raw text is visible in the rendered text', (tester) async {
      final loc = await pumpNarrowDatesCard(
        tester,
        roastDate: null,
        roastDateRawText: '02/08',
        needsConfirmation: true,
        onRoastDateConfirmed: () {},
      );

      final expectedPrompt = loc.roastDateConfirmPrompt('02/08');
      // The template embeds the raw text, so resolving the localized string
      // with the actual raw text already proves it is rendered — but assert
      // on the substring too, per the "must be visible in rendered text"
      // requirement rather than only widget presence.
      expect(
        find.descendant(
          of: find.byType(DatesCard),
          matching: find.text(expectedPrompt),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(DatesCard),
          matching: find.textContaining('02/08'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(DatesCard),
          matching: find.byIcon(Icons.info_outline),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(DatesCard),
          matching: find.text(loc.roastDateConfirmAction),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('flagged with null raw text shows the not-found wording, '
        'not the prompt wording', (tester) async {
      final loc = await pumpNarrowDatesCard(
        tester,
        roastDate: null,
        roastDateRawText: null,
        needsConfirmation: true,
      );

      expect(
        find.descendant(
          of: find.byType(DatesCard),
          matching: find.text(loc.roastDateNotFound),
        ),
        findsOneWidget,
      );
      // Distinctive fragment of the prompt wording that the not-found
      // message never contains, confirming the other branch didn't render.
      expect(
        find.descendant(
          of: find.byType(DatesCard),
          matching: find.textContaining('please confirm'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(DatesCard),
          matching: find.byIcon(Icons.info_outline),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('not flagged renders exactly today\'s bare-DateField UI: '
        'no hint row, no info icon, no confirm button', (tester) async {
      final roastDate = DateTime(2026, 1, 5);
      final loc = await pumpNarrowDatesCard(
        tester,
        roastDate: roastDate,
        roastDateRawText: null,
        needsConfirmation: false,
      );

      expect(
        find.descendant(
          of: find.byType(DatesCard),
          matching: find.byIcon(Icons.info_outline),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(DatesCard),
          matching: find.byType(AppTextButton),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(DatesCard),
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.identifier == 'roastDateConfirmationHint',
          ),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(DatesCard),
          matching: find.text(loc.roastDateConfirmAction),
        ),
        findsNothing,
      );

      // The roast date field itself is still present and shows the date.
      final expectedDisplay = DateFormat.yMd(loc.localeName).format(roastDate);
      expect(
        find.descendant(
          of: find.byType(DatesCard),
          matching: find.text(expectedDisplay),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('confirm button invokes onRoastDateConfirmed exactly once', (
      tester,
    ) async {
      var confirmedCount = 0;
      await pumpNarrowDatesCard(
        tester,
        roastDate: null,
        roastDateRawText: '02/08',
        needsConfirmation: true,
        onRoastDateConfirmed: () => confirmedCount++,
      );

      await tester.tap(
        find.descendant(
          of: find.byType(DatesCard),
          matching: find.byType(AppTextButton),
        ),
      );
      await tester.pump();

      expect(confirmedCount, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('wide layout renders the hint without overflowing', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        host(
          DatesCard(
            harvestDate: null,
            roastDate: null,
            onHarvestDateChanged: (_) {},
            onRoastDateChanged: (_) {},
            roastDateRawText: '02/08',
            needsConfirmation: true,
            onRoastDateConfirmed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final loc = AppLocalizations.of(tester.element(find.byType(DatesCard)))!;
      expect(
        find.descendant(
          of: find.byType(DatesCard),
          matching: find.text(loc.roastDateConfirmPrompt('02/08')),
        ),
        findsOneWidget,
      );
      // A RenderFlex overflow surfaces as an exception during the pump
      // above; asserting no exception is the overflow guard.
      expect(tester.takeException(), isNull);
    });
  });

  group('DatesCard single-setState scan transition (defect 1 regression)', () {
    testWidgets(
      'roastDate + roastDateRawText + needsConfirmation arriving together '
      'in one setState (exactly as _fillFields does it) still shows the '
      'formatted date, not just the hint',
      (tester) async {
        tester.view.physicalSize = const Size(400, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(host(const _ScanTransitionHost()));
        await tester.pumpAndSettle();

        // Before the scan lands: bare field, no hint.
        expect(
          find.descendant(
            of: find.byType(DatesCard),
            matching: find.byIcon(Icons.info_outline),
          ),
          findsNothing,
        );

        // Drive the exact _fillFields sequence: a single setState flips
        // roastDate, roastDateRawText and needsConfirmation together.
        final state = tester.state<_ScanTransitionHostState>(
          find.byType(_ScanTransitionHost),
        );
        state.applyScanResult();
        await tester.pumpAndSettle();

        final loc = AppLocalizations.of(
          tester.element(find.byType(DatesCard)),
        )!;

        // The hint must show.
        expect(
          find.descendant(
            of: find.byType(DatesCard),
            matching: find.text(loc.roastDateConfirmPrompt('02/08')),
          ),
          findsOneWidget,
        );

        // AND the formatted date must be visible in the field — this is
        // the assertion that failed before the fix: the DateField element
        // was destroyed and recreated with a non-null initialValue,
        // tripping the AppLocalizations-in-initState bug and rendering
        // blank ("Select Roast Date") instead of the parsed date.
        final expectedDisplay = DateFormat.yMd(
          loc.localeName,
        ).format(DateTime(2026, 8, 2));
        expect(
          find.descendant(
            of: find.byType(DatesCard),
            matching: find.text(expectedDisplay),
          ),
          findsOneWidget,
        );
        // The underlying text field itself must hold the formatted date —
        // this is the field that read blank when the defect was present
        // (find.text(hintText) alone isn't a reliable "field is blank"
        // check: Material's InputDecorator keeps the hint Text widget in
        // the tree at opacity 0 once there is content, for its fade
        // animation, so it would still be found either way). Scope to the
        // roast date field specifically — DatesCard also renders a harvest
        // date field with its own TextFormField.
        final roastDateField = find.byWidgetPredicate(
          (w) => w is DateField && w.semanticIdentifier == 'roastDatePickerButton',
        );
        final textField = tester.widget<TextFormField>(
          find.descendant(
            of: roastDateField,
            matching: find.byType(TextFormField),
          ),
        );
        expect(textField.controller?.text, expectedDisplay);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('DateField first-mount with non-null initialValue (defect 1(b) '
      'root cause)', () {
    testWidgets(
      'a DateField constructed with a non-null initialValue on its very '
      'first build displays the formatted date immediately',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: DateField(
                label: 'Roast Date',
                initialValue: DateTime(2026, 8, 2).toIso8601String(),
              ),
            ),
          ),
        );
        // Deliberately a single pump (not pumpAndSettle before assertion)
        // to prove the date renders on the very first frame, not only
        // after a later rebuild.
        await tester.pump();

        final loc = AppLocalizations.of(
          tester.element(find.byType(DateField)),
        )!;
        final expectedDisplay = DateFormat.yMd(
          loc.localeName,
        ).format(DateTime(2026, 8, 2));

        expect(find.text(expectedDisplay), findsOneWidget);
        // The underlying text field itself must hold the formatted date,
        // not just some other Text widget coincidentally matching — this
        // is what actually reads blank when the defect is present.
        final textField = tester.widget<TextFormField>(
          find.descendant(
            of: find.byType(DateField),
            matching: find.byType(TextFormField),
          ),
        );
        expect(textField.controller?.text, expectedDisplay);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('CollectedDataDialog hides internal plan-051 keys', () {
    testWidgets(
      'roastDateRawText and roastDateNeedsConfirmation never appear as '
      'raw key labels, while normal fields still render',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return CollectedDataDialog(
                    data: const <String, dynamic>{
                      'roaster': 'Test Roaster',
                      'roastDate': '2026-08-02T00:00:00.000',
                      'roastDateRawText': '02/08',
                      'roastDateNeedsConfirmation': true,
                    },
                    humanizeKey: (key) => key,
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Normal fields still render. `humanizeKey` is the identity function
        // here, so the label is the raw key plus a trailing colon (matching
        // CollectedDataDialog's `'${labelFor(key)}:'` rendering) — this
        // pins down the 'roastDate' row specifically, distinct from a
        // (would-be) 'roastDateRawText' row, which also contains the
        // substring "roastDate".
        expect(find.text('roaster:'), findsOneWidget);
        expect(find.textContaining('Test Roaster'), findsOneWidget);
        expect(find.text('roastDate:'), findsOneWidget);

        // The two technical keys must never leak as raw labels.
        expect(find.textContaining('roastDateRawText'), findsNothing);
        expect(find.textContaining('roastDateNeedsConfirmation'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('CollectedDataDialog inline roast date confirmation hint', () {
    Future<AppLocalizations> pumpDialog(
      WidgetTester tester,
      Map<String, dynamic> data,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return CollectedDataDialog(
                  data: data,
                  humanizeKey: (key) => key,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return AppLocalizations.of(
        tester.element(find.byType(CollectedDataDialog)),
      )!;
    }

    testWidgets(
      'flag true + raw text renders the confirm prompt under the roast '
      'date value, and normal rows and key-hiding still hold',
      (tester) async {
        final loc = await pumpDialog(tester, <String, dynamic>{
          'roaster': 'Test Roaster',
          'roastDate': '2026-08-02T00:00:00.000',
          'roastDateRawText': '02/08',
          'roastDateNeedsConfirmation': true,
        });

        expect(
          find.text(loc.roastDateConfirmPrompt('02/08')),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.info_outline), findsOneWidget);

        // Normal rows still render.
        expect(find.text('roaster:'), findsOneWidget);
        expect(find.textContaining('Test Roaster'), findsOneWidget);
        expect(find.text('roastDate:'), findsOneWidget);

        // The two technical keys never leak as raw labels.
        expect(find.textContaining('roastDateRawText'), findsNothing);
        expect(
          find.textContaining('roastDateNeedsConfirmation'),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'flag true + null raw text renders the not-found wording, not the '
      'confirm prompt wording',
      (tester) async {
        final loc = await pumpDialog(tester, <String, dynamic>{
          'roaster': 'Test Roaster',
          'roastDate': '2026-08-02T00:00:00.000',
          'roastDateRawText': null,
          'roastDateNeedsConfirmation': true,
        });

        expect(find.text(loc.roastDateNotFound), findsOneWidget);
        expect(
          find.textContaining('please confirm'),
          findsNothing,
        );
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'flag true + blank raw text also renders the not-found wording',
      (tester) async {
        final loc = await pumpDialog(tester, <String, dynamic>{
          'roaster': 'Test Roaster',
          'roastDate': '2026-08-02T00:00:00.000',
          'roastDateRawText': '   ',
          'roastDateNeedsConfirmation': true,
        });

        expect(find.text(loc.roastDateNotFound), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'legacy response with neither key renders exactly as before: no '
      'info icon, no hint text',
      (tester) async {
        await pumpDialog(tester, <String, dynamic>{
          'roaster': 'Legacy Roaster',
          'roastDate': '2026-01-05T00:00:00.000',
        });

        expect(find.byIcon(Icons.info_outline), findsNothing);
        expect(find.text('roastDate:'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'flag present but false renders no hint either',
      (tester) async {
        await pumpDialog(tester, <String, dynamic>{
          'roaster': 'Test Roaster',
          'roastDate': '2026-08-02T00:00:00.000',
          'roastDateRawText': '02/08',
          'roastDateNeedsConfirmation': false,
        });

        expect(find.byIcon(Icons.info_outline), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'flag true but no roastDate key at all renders no crash and no '
      'invented row (field-level hint still covers this case)',
      (tester) async {
        await pumpDialog(tester, <String, dynamic>{
          'roaster': 'Test Roaster',
          'roastDateRawText': '02/08',
          'roastDateNeedsConfirmation': true,
        });

        expect(find.text('roaster:'), findsOneWidget);
        expect(find.text('roastDate:'), findsNothing);
        expect(find.byIcon(Icons.info_outline), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'a wrapped payload ({"0": {...}}) carrying the flag still surfaces '
      'the hint — guards the unwrap-ordering trap',
      (tester) async {
        final loc = await pumpDialog(tester, <String, dynamic>{
          '0': <String, dynamic>{
            'roaster': 'Wrapped Roaster',
            'roastDate': '2026-08-02T00:00:00.000',
            'roastDateRawText': '02/08',
            'roastDateNeedsConfirmation': true,
          },
        });

        expect(
          find.text(loc.roastDateConfirmPrompt('02/08')),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
        expect(find.text('roaster:'), findsOneWidget);
        expect(find.textContaining('Wrapped Roaster'), findsOneWidget);

        // Still never leaks as raw labels once unwrapped.
        expect(find.textContaining('roastDateRawText'), findsNothing);
        expect(
          find.textContaining('roastDateNeedsConfirmation'),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('NewBeansScreen backward compatibility with pre-confirmation scan '
      'responses', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await Supabase.initialize(
        url: 'http://localhost:54321',
        anonKey: 'test-anon-key',
      );
    });

    Widget localizedApp(Widget child) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(body: child),
      );
    }

    testWidgets(
      'a scan response with neither roastDateRawText nor '
      'roastDateNeedsConfirmation still fills the roast date and shows no '
      'confirmation hint',
      (tester) async {
        // Force the narrow (single-column) NewBeansScreen layout so exactly
        // one DatesCard is in the tree (the screen switches at 800px).
        tester.view.physicalSize = const Size(700, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        SharedPreferences.setMockInitialValues({'hasShownPopup': true});
        final coffeeBeansProvider = MockCoffeeBeansProvider();
        when(
          coffeeBeansProvider.fetchAllDistinctGrindSizes(),
        ).thenAnswer((_) async => <String>[]);
        final userStatProvider = brew_mocks.MockUserStatProvider();
        when(
          userStatProvider.fetchAllDistinctGrindSizes(),
        ).thenAnswer((_) async => <String>[]);
        final imageController = _ScanDataImageController();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<CoffeeBeansProvider>.value(
                value: coffeeBeansProvider,
              ),
              ChangeNotifierProvider<UserStatProvider>.value(
                value: userStatProvider,
              ),
            ],
            child: localizedApp(
              NewBeansScreen(imageController: imageController),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final loc = AppLocalizations.of(
          tester.element(find.byType(NewBeansScreen)),
        )!;
        await tester.tap(find.text(loc.aiScanLabel));
        await tester.pump();
        expect(imageController.started, isTrue);

        // Legacy backend/app shape: `roastDate` present, but the two new
        // confirmation keys are entirely absent from the map (not merely
        // null) — this is what an older client/server pairing sends.
        final legacyRoastDate = DateTime(2026, 1, 5);
        imageController.data(<String, dynamic>{
          'roaster': 'Legacy Roaster',
          'roastDate': legacyRoastDate.toIso8601String(),
        });
        await tester.pump();
        await tester.pump();

        // The scan flow shows a "collected data" confirmation dialog before
        // returning to the form; dismiss it to see the filled-in DatesCard.
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.text(loc.ok));
        await tester.pumpAndSettle();

        expect(find.byType(DatesCard), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(DatesCard),
            matching: find.byIcon(Icons.info_outline),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byType(DatesCard),
            matching: find.byType(AppTextButton),
          ),
          findsNothing,
        );

        final expectedDisplay = DateFormat.yMd(
          loc.localeName,
        ).format(legacyRoastDate);
        expect(
          find.descendant(
            of: find.byType(DatesCard),
            matching: find.text(expectedDisplay),
          ),
          findsOneWidget,
        );

        expect(tester.takeException(), isNull);
      },
    );
  });
}

/// Minimal stand-in for the relevant slice of [NewBeansScreen] state: a
/// [DatesCard] whose roast-date-related fields are all flipped together in
/// one `setState`, exactly like the real `_fillFields` does after a scan.
/// Mounts blank (mirrors the real screen's initial `DatesCard` state) so the
/// regression is specifically about the *transition*, not the initial mount.
class _ScanTransitionHost extends StatefulWidget {
  const _ScanTransitionHost();

  @override
  State<_ScanTransitionHost> createState() => _ScanTransitionHostState();
}

class _ScanTransitionHostState extends State<_ScanTransitionHost> {
  DateTime? _roastDate;
  String? _roastDateRawText;
  bool _needsConfirmation = false;

  void applyScanResult() {
    setState(() {
      _roastDate = DateTime(2026, 8, 2);
      _roastDateRawText = '02/08';
      _needsConfirmation = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DatesCard(
      harvestDate: null,
      roastDate: _roastDate,
      onHarvestDateChanged: (_) {},
      onRoastDateChanged: (_) {},
      roastDateRawText: _roastDateRawText,
      needsConfirmation: _needsConfirmation,
      onRoastDateConfirmed: () {},
    );
  }
}

typedef _ShowPreviewCallback =
    Future<void> Function(
      List<XFile> images,
      ImageSource source,
      Future<void> Function(List<XFile>, bool) onConfirm,
      Future<void> Function() onBackToSelection,
      Future<XFile?> Function()? onAddPhoto,
    );

/// Minimal fake image controller that only needs to capture the screen's
/// real `onData` callback (== the wiring around `_fillFields`) so a test can
/// hand it a raw response map, exactly as the live scan flow would.
class _ScanDataImageController extends NewBeansImageController {
  _ScanDataImageController()
    : super(
        supabaseClient: SupabaseClient(
          'https://example.supabase.co',
          'anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  bool started = false;
  late void Function(Map<String, dynamic>) data;

  @override
  Future<void> start({
    required BuildContext context,
    required String locale,
    required void Function(bool) onLoading,
    required void Function(Map<String, dynamic>) onData,
    required void Function(String) onError,
    required Future<ImageSource?> Function() onChooseSource,
    required _ShowPreviewCallback onShowPreview,
    String? userId,
    bool isFirstTime = false,
    void Function(BeanScanStage stage)? onStage,
    required void Function(PhotoLibrarySaveResult result) onPhotoSaveResult,
  }) {
    started = true;
    data = onData;
    // Never completes — the test drives `data` directly and doesn't need
    // the rest of the controller's picker/preview flow.
    return Completer<void>().future;
  }
}
