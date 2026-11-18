import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/bean_recommendation_model.dart';
import 'package:coffee_timer/providers/recommendation_provider.dart';
import 'package:coffee_timer/screens/taste_profile_screen.dart';
import 'package:coffee_timer/services/clients/bean_recommendation_client.dart';
import 'package:coffee_timer/widgets/settings/settings_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// English ARB strings the tests interact with.
const _intro =
    'Worked out from the beans you add and brew. It shapes your bean suggestions.';
const _notEnough =
    'Add at least 3 beans and log 5 brews, and we’ll work out what you like. '
    'You can already tell us below.';
const _twoOrigins = 'Origins you drink most: Ethiopia and Kenya';
const _oneOrigin = 'Origin you drink most: Ethiopia';
const _processLine = 'Most common process: Washed';
const _roastLine = 'Most common roast: Light';
const _roastDarkLine = 'Most common roast: Dark';
const _twoFlavors = 'Flavors you drink most: Fruity and Berry';
const _ofYourCoffees = ' of your coffees';
const _notInHistory = 'Not in your history yet';
const _addOrigin = 'Add an origin';
const _timingNote =
    'Never applies right away. More and Less apply the next time your '
    'suggestions are rebuilt, within about an hour.';
const _loadFailed = 'Couldn’t load your taste profile';
const _saveFailed = 'Couldn’t save that change. Try again.';
const _retry = 'Retry';
const _more = 'More';
const _never = 'Never';
const _noChange = 'No change';
const _adjust = 'Adjust';

/// Hand-written fake — no Supabase anywhere in these tests (same shape as
/// the one in test/unit/providers/recommendation_taste_profile_test.dart).
class _FakeClient implements BeanRecommendationClient, TasteProfileClient {
  TasteProfile? profile;
  Object? profileError;
  Object? setError;
  int profileFetchCount = 0;
  final List<(TasteDimension, String, TastePreference?)> setCalls = [];

  @override
  Future<RecommendationResult?> fetch({String? locale}) async => null;

  @override
  Future<BeanRecommendationStatus> generate({
    required String locale,
    String? countryCode,
    bool forceRefresh = false,
  }) async => BeanRecommendationStatus.ok;

  @override
  Future<void> dismiss(String stockId) async {}

  @override
  Future<void> logReferredClick(String stockId, String surface) async {}

  @override
  Future<void> deleteMine() async {}

  @override
  Future<TasteProfile?> fetchTasteProfile() async {
    profileFetchCount++;
    if (profileError != null) throw profileError!;
    return profile;
  }

  @override
  Future<void> setTastePreference(
    TasteDimension dimension,
    String value,
    TastePreference? preference,
  ) async {
    setCalls.add((dimension, value, preference));
    if (setError != null) throw setError!;
  }
}

Map<String, Object?> _profileJson({
  bool enoughHistory = true,
  List<Object?> origin = const [
    {'value': 'ET', 'share': 0.4286},
    {'value': 'KE', 'share': 0.2857},
    {'value': 'CO', 'share': 0.2857},
  ],
  List<Object?> process = const [
    {'value': 'washed', 'share': 0.5714},
    {'value': 'natural', 'share': 0.4286},
  ],
  List<Object?> roast = const [
    {'value': 'light', 'share': 1.0},
  ],
  List<Object?> flavor = const [
    {'value': 'fruity', 'share': 0.5},
    {'value': 'berry', 'share': 0.5},
  ],
  List<Object?> preferences = const [],
}) => {
  'origin': origin,
  'process': process,
  'roast': roast,
  'flavor': flavor,
  'bean_count': 7,
  'brew_count': 12,
  'enough_history': enoughHistory,
  'preferences': preferences,
};

Future<RecommendationProvider> _makeProvider(_FakeClient client) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final provider = RecommendationProvider(
    client: client,
    currentUserId: () => 'user-1',
    featureFlagEnabled: () => true,
    countryCodeLookup: (_) async => 'DE',
    prefs: prefs,
    debugMode: true,
  );
  return provider;
}

Widget _harness(RecommendationProvider provider) =>
    ChangeNotifierProvider<RecommendationProvider>.value(
      value: provider,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const TasteProfileScreen(),
      ),
    );

/// The row's current choice by name (`none`, `more`, `less`, `never`); the
/// screen's choice type is private.
String _choice(WidgetTester tester, String id) =>
    (_row(tester, id).current! as Enum).name;

SettingsChoiceRow<Object?> _row(WidgetTester tester, String id) => tester
    .widgetList<SettingsChoiceRow<Object?>>(
      find.byWidgetPredicate(
        (widget) =>
            widget is SettingsChoiceRow<Object?> && widget.identifier == id,
      ),
    )
    .single;

bool _hasRow(WidgetTester tester, String id) => tester
    .widgetList<SettingsChoiceRow<Object?>>(
      find.byWidgetPredicate(
        (widget) =>
            widget is SettingsChoiceRow<Object?> && widget.identifier == id,
      ),
    )
    .isNotEmpty;

void main() {
  Finder addRow(String dim) => find.byWidgetPredicate(
    (widget) =>
        widget is SettingsActionRow && widget.identifier == 'tasteAdd_$dim',
  );

  Future<RecommendationProvider> pumpWith(
    WidgetTester tester,
    _FakeClient client,
  ) async {
    final provider = await _makeProvider(client);
    addTearDown(provider.dispose);
    await tester.pumpWidget(_harness(provider));
    await tester.pumpAndSettle();
    return provider;
  }

  testWidgets('error state shows retry, and retrying loads', (tester) async {
    final client = _FakeClient()..profileError = Exception('offline');
    final provider = await pumpWith(tester, client);

    expect(provider.tasteProfileState, TasteProfileLoadState.error);
    expect(provider.tasteProfile, isNull);
    expect(find.text(_loadFailed), findsOneWidget);
    expect(find.text(_retry), findsOneWidget);
    expect(find.text(_intro), findsOneWidget, reason: 'intro is always shown');

    client
      ..profileError = null
      ..profile = TasteProfile.fromJson(_profileJson());
    await tester.tap(find.text(_retry));
    await tester.pumpAndSettle();

    expect(provider.tasteProfileState, TasteProfileLoadState.ready);
    expect(find.text(_loadFailed), findsNothing);
    expect(find.text(_retry), findsNothing);
    expect(find.text(_twoOrigins), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ready profile with enough history shows summary, item rows '
      'with percentages, the add rows and the timing footer', (tester) async {
    // Tall enough that the lazy ListView materialises every section.
    await tester.binding.setSurfaceSize(const Size(800, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final client = _FakeClient()
      ..profile = TasteProfile.fromJson(_profileJson());
    await pumpWith(tester, client);

    expect(find.text(_intro), findsOneWidget);
    expect(find.text(_twoOrigins), findsOneWidget);
    expect(find.text(_processLine), findsOneWidget);
    expect(find.text(_roastLine), findsOneWidget);
    expect(find.text(_twoFlavors), findsOneWidget);
    expect(find.text(_notEnough), findsNothing);

    // Percentages are formatted with NumberFormat.percentPattern.
    expect(
      find.text('43%$_ofYourCoffees'),
      findsNWidgets(2),
      reason: 'ET (origin) and natural (process) are both 42.86% → 43%',
    );
    expect(
      find.text('29%$_ofYourCoffees'),
      findsNWidgets(2),
      reason: 'KE and CO are both 28.57% → 29%',
    );
    expect(find.text('57%$_ofYourCoffees'), findsOneWidget);
    expect(find.text('100%$_ofYourCoffees'), findsOneWidget);
    expect(find.text('50%$_ofYourCoffees'), findsNWidgets(2));

    // One row per labelled history value, with the sheet’s choices.
    final etRow = _row(tester, 'tasteItem_origin_ET');
    expect(etRow.title, 'Ethiopia');
    expect(etRow.subtitle, '43%$_ofYourCoffees');
    expect(_choice(tester, 'tasteItem_origin_ET'), 'none');
    expect(etRow.valueLabel, _adjust,
        reason: 'an unset row reads as a call to action, not "No change"');
    expect(etRow.options.map((o) => o.label), [
      _noChange,
      _more,
      'Less',
      _never,
    ]);
    expect(etRow.options.map((o) => (o.value! as Enum).name), [
      'none',
      'more',
      'less',
      'never',
    ]);
    expect(_row(tester, 'tasteItem_origin_KE').subtitle, '29%$_ofYourCoffees');
    expect(_row(tester, 'tasteItem_process_washed').title, 'Washed');
    expect(_row(tester, 'tasteItem_roast_light').title, 'Light');
    expect(_row(tester, 'tasteItem_flavor_fruity').title, 'Fruity');

    // One add row per dimension, and the flavor section carries the
    // timing footer.
    for (final dim in ['origin', 'process', 'roast', 'flavor']) {
      expect(addRow(dim), findsOneWidget);
    }
    final flavorSection = tester.widget<SettingsSection>(
      find.ancestor(
        of: addRow('flavor'),
        matching: find.byType(SettingsSection),
      ),
    );
    expect(flavorSection.footer, _timingNote);
    expect(
      tester
          .widgetList<SettingsSection>(find.byType(SettingsSection))
          .where((s) => s.footer != null),
      hasLength(1),
      reason: 'only the last section has a footer',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a single origin reads singular, empty flavor omits its line', (
    tester,
  ) async {
    final client = _FakeClient()
      ..profile = TasteProfile.fromJson(
        _profileJson(
          origin: const [
            {'value': 'ET', 'share': 1.0},
          ],
          process: const [
            {'value': 'washed', 'share': 1.0},
          ],
          roast: const [
            {'value': 'dark', 'share': 1.0},
          ],
          flavor: const [],
        ),
      );
    await pumpWith(tester, client);

    expect(find.text(_oneOrigin), findsOneWidget);
    expect(find.text(_twoOrigins), findsNothing);
    expect(find.text(_processLine), findsOneWidget);
    expect(find.text(_roastDarkLine), findsOneWidget);
    expect(find.text(_twoFlavors), findsNothing);
    expect(_hasRow(tester, 'tasteItem_flavor_fruity'), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('not enough history shows the note instead of summary lines '
      'and keeps the add rows (plus added adjustments)', (tester) async {
    final client = _FakeClient()
      ..profile = TasteProfile.fromJson(
        _profileJson(
          enoughHistory: false,
          preferences: [
            {'dimension': 'origin', 'value': 'br', 'preference': 'more'},
          ],
        ),
      );
    await pumpWith(tester, client);

    expect(find.text(_intro), findsOneWidget);
    expect(find.text(_notEnough), findsOneWidget);
    expect(find.text(_twoOrigins), findsNothing);
    expect(find.text(_processLine), findsNothing);
    expect(find.text(_roastLine), findsNothing);
    expect(find.text(_twoFlavors), findsNothing);
    // History share rows are withheld, but the section itself stays.
    expect(_hasRow(tester, 'tasteItem_origin_ET'), isFalse);
    expect(find.textContaining(_ofYourCoffees), findsNothing);
    // The added adjustment renders even without history.
    expect(_hasRow(tester, 'tasteItem_origin_BR'), isTrue);
    expect(find.text(_notInHistory), findsOneWidget);
    expect(_choice(tester, 'tasteItem_origin_BR'), 'more');
    // All four add rows remain.
    for (final dim in ['origin', 'process', 'roast', 'flavor']) {
      expect(addRow(dim), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('choosing Never on an item saves through the client', (
    tester,
  ) async {
    final client = _FakeClient()
      ..profile = TasteProfile.fromJson(_profileJson());
    await pumpWith(tester, client);

    await tester.ensureVisible(find.text('Ethiopia'));
    await tester.tap(find.text('Ethiopia'));
    await tester.pumpAndSettle();
    expect(find.text('Ethiopia'), findsWidgets, reason: 'sheet is open');

    await tester.tap(find.text(_never));
    await tester.pumpAndSettle();

    expect(client.setCalls.single, (
      TasteDimension.origin,
      'ET',
      TastePreference.never,
    ));
    expect(_choice(tester, 'tasteItem_origin_ET'), 'never');
    expect(tester.takeException(), isNull);
  });

  testWidgets('choosing No change clears a stored preference', (tester) async {
    final client = _FakeClient()
      ..profile = TasteProfile.fromJson(
        _profileJson(
          preferences: const [
            {'dimension': 'origin', 'value': 'KE', 'preference': 'more'},
          ],
        ),
      );
    await pumpWith(tester, client);
    expect(_choice(tester, 'tasteItem_origin_KE'), 'more');
    expect(_row(tester, 'tasteItem_origin_KE').valueLabel, isNull,
        reason: 'a set row shows its option label');
    expect(find.text(_more), findsOneWidget);

    await tester.ensureVisible(find.text('Kenya'));
    await tester.tap(find.text('Kenya'));
    await tester.pumpAndSettle();
    // Tap the sheet option by its identifier.
    await tester.tap(
      find.byWidgetPredicate(
        (w) =>
            w is Semantics && w.properties.identifier == 'tasteSheetPref_none',
      ),
    );
    await tester.pumpAndSettle();

    expect(client.setCalls.single, (TasteDimension.origin, 'KE', null));
    expect(_choice(tester, 'tasteItem_origin_KE'), 'none');
    expect(_row(tester, 'tasteItem_origin_KE').valueLabel, _adjust);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed save shows the tasteSaveFailed snackbar', (
    tester,
  ) async {
    final client = _FakeClient()
      ..profile = TasteProfile.fromJson(_profileJson())
      ..setError = Exception('500');
    await pumpWith(tester, client);

    await tester.ensureVisible(find.text('Ethiopia'));
    await tester.tap(find.text('Ethiopia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_more));
    await tester.pumpAndSettle();

    expect(client.setCalls.single, (
      TasteDimension.origin,
      'ET',
      TastePreference.more,
    ));
    expect(find.text(_saveFailed), findsOneWidget);
    // The failed write rolled back.
    expect(_choice(tester, 'tasteItem_origin_ET'), 'none');
    expect(tester.takeException(), isNull);
  });

  testWidgets('add flow: pick a country, then More; the client receives it '
      'and the new row appears', (tester) async {
    final client = _FakeClient()
      ..profile = TasteProfile.fromJson(_profileJson());
    await pumpWith(tester, client);

    await tester.ensureVisible(addRow('origin'));
    await tester.tap(find.text(_addOrigin));
    await tester.pumpAndSettle();

    // The sheet lists countries that are not rows yet, labels sorted.
    expect(
      find.text('Bolivia'),
      findsOneWidget,
      reason: 'Bolivia sorts first among the offered origins',
    );
    await tester.tap(find.text('Brazil'));
    await tester.pumpAndSettle();

    expect(find.text('How should we treat Brazil?'), findsOneWidget);
    await tester.tap(find.text(_more));
    await tester.pumpAndSettle();

    expect(client.setCalls.single, (
      TasteDimension.origin,
      'BR',
      TastePreference.more,
    ));
    expect(_hasRow(tester, 'tasteItem_origin_BR'), isTrue);
    expect(_row(tester, 'tasteItem_origin_BR').title, 'Brazil');
    expect(_row(tester, 'tasteItem_origin_BR').subtitle, _notInHistory);
    expect(find.text(_notInHistory), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unknown values are never rendered', (tester) async {
    final client = _FakeClient()
      ..profile = TasteProfile.fromJson(
        _profileJson(
          origin: const [
            {'value': 'XX', 'share': 1.0},
          ],
          process: const [
            {'value': 'foo', 'share': 1.0},
          ],
          roast: const [
            {'value': 'char', 'share': 1.0},
          ],
          flavor: const [
            {'value': 'blueberry', 'share': 1.0},
          ],
        ),
      );
    await pumpWith(tester, client);

    expect(find.text('XX'), findsNothing);
    expect(find.text('foo'), findsNothing);
    expect(find.text('char'), findsNothing);
    expect(find.text('blueberry'), findsNothing);
    expect(
      find.textContaining(_ofYourCoffees),
      findsNothing,
      reason: 'no row may render for an unlabelled value',
    );
    // The summary omits the lines with nothing labelled to say, and the
    // add rows remain.
    expect(find.text(_twoOrigins), findsNothing);
    expect(find.text(_processLine), findsNothing);
    expect(find.text(_roastLine), findsNothing);
    expect(find.text(_twoFlavors), findsNothing);
    for (final dim in ['origin', 'process', 'roast', 'flavor']) {
      expect(addRow(dim), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
