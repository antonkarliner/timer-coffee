import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/providers/snow_provider.dart';
import 'package:coffee_timer/providers/theme_provider.dart';
import 'package:coffee_timer/screens/settings/settings_appearance_screen.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/brewing/layout_preview_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _lightDefaultPreview({required bool isDark, required bool isAndroid}) =>
    'assets/icons/previews/default_light.png';

void main() {
  late ThemeProvider themeProvider;
  late SnowEffectProvider snowProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
    themeProvider = ThemeProvider(ThemeMode.light);
    snowProvider = SnowEffectProvider();
  });

  tearDown(() {
    AnalyticsService.resetForTesting();
  });

  List<Map<String, dynamic>> settingChangedEvents() => AnalyticsService
      .instance.bufferedEventsForTesting
      .where((event) => event['event_name'] == 'setting_changed')
      .toList();

  Widget app(Widget child) => MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<SnowEffectProvider>.value(value: snowProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: child,
        ),
      );

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(app(const SettingsAppearanceScreen()));
    await tester.pumpAndSettle();
  }

  /// Pumps [AppIconPreviewGrid] alone — the icon API is unavailable in the
  /// test environment, so the page can never show the real grid. The grid is
  /// built through [buildGrid] because its options use a library-private
  /// type that this file cannot name.
  Future<void> pumpGrid(
    WidgetTester tester, {
    required AppIconPreviewGrid Function(AppLocalizations l10n) buildGrid,
    double width = 400,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: Builder(
                builder: (context) => buildGrid(AppLocalizations.of(context)!),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The width of one grid cell on a [width]-wide canvas: the grid's 16 pt
  /// page insets and 3 gutters spread across 4 equal columns.
  double cellWidth(double width) =>
      (width - AppSpacing.base * 2 - 3 * AppSpacing.sm) / 4;

  testWidgets('renders theme and snow controls without exceptions',
      (tester) async {
    await pumpPage(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.bySemanticsIdentifier('settingsThemeTile'), findsOneWidget);
    expect(find.bySemanticsIdentifier('settingsSnowSwitch'), findsOneWidget);
    // The icon API is unavailable in the test environment, so the whole
    // section (header included) stays hidden.
    expect(find.text('App icon'), findsNothing);
    expect(find.bySemanticsIdentifier('appIconDefaultTile'), findsNothing);
    expect(find.bySemanticsIdentifier('appIconLegacyTile'), findsNothing);
  });

  testWidgets('choosing a theme applies it and emits one setting_changed',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.bySemanticsIdentifier('settingsThemeTile'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('themeDarkListTile'));
    await tester.pumpAndSettle();

    expect(themeProvider.themeMode, ThemeMode.dark);
    expect(settingChangedEvents(), hasLength(1));
    expect(settingChangedEvents().single['properties'], {
      'key': 'theme',
      'value': 'dark',
      'previous': 'light',
      'source': 'settings',
    });
  });

  testWidgets('choosing the current theme emits nothing', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.bySemanticsIdentifier('settingsThemeTile'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('themeLightListTile'));
    await tester.pumpAndSettle();

    expect(themeProvider.themeMode, ThemeMode.light);
    expect(settingChangedEvents(), isEmpty);
  });

  testWidgets('toggling snow updates the provider, persists and emits',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.bySemanticsIdentifier('settingsSnowSwitch'));
    await tester.pumpAndSettle();

    expect(snowProvider.isSnowing, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('snow_effect_enabled'), isTrue);
    expect(settingChangedEvents(), hasLength(1));
    expect(settingChangedEvents().single['properties'], {
      'key': 'snow_effect',
      'value': 'on',
      'previous': 'off',
      'source': 'settings',
    });
  });

  testWidgets('theme sheet: the Automatic option carries the device subtitle',
      (tester) async {
    await pumpPage(tester);

    await tester.tap(find.bySemanticsIdentifier('settingsThemeTile'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.bySemanticsIdentifier('themeSystemListTile'),
        matching: find.text('Matches your device'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('icon grid lays out four equal start-aligned columns',
      (tester) async {
    const gridWidth = 400.0;
    await pumpGrid(
      tester,
      width: gridWidth,
      buildGrid: (l10n) => AppIconPreviewGrid(
        options: appIconPreviewOptions(l10n),
        selectedId: 'Default',
        isAndroid: false,
        isDark: false,
        onSelected: (_) {},
      ),
    );

    final defaultCell =
        tester.getRect(find.bySemanticsIdentifier('appIconDefaultTile'));
    final legacyCell =
        tester.getRect(find.bySemanticsIdentifier('appIconLegacyTile'));
    final expectedWidth = cellWidth(gridWidth);

    // Start-aligned: the first cell sits at the page inset, the second one
    // cell width + gutter after it.
    expect(defaultCell.left, AppSpacing.base);
    expect(legacyCell.left,
        defaultCell.left + expectedWidth + AppSpacing.sm);
    expect(defaultCell.width, expectedWidth);
    expect(legacyCell.width, expectedWidth);
    // Two icons fill half a 4-column row: nothing occupies the right half.
    expect(legacyCell.right, lessThan(gridWidth - AppSpacing.base));
  });

  testWidgets('selected icon cell has the check badge and a w600 label; '
      'the other has neither', (tester) async {
    await pumpGrid(
      tester,
      buildGrid: (l10n) => AppIconPreviewGrid(
        options: appIconPreviewOptions(l10n),
        selectedId: 'Default',
        isAndroid: false,
        isDark: false,
        onSelected: (_) {},
      ),
    );

    final defaultCell =
        find.bySemanticsIdentifier('appIconDefaultTile');
    final legacyCell = find.bySemanticsIdentifier('appIconLegacyTile');

    expect(
      find.descendant(of: defaultCell, matching: find.byType(SelectionCheckBadge)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: legacyCell, matching: find.byType(SelectionCheckBadge)),
      findsNothing,
    );
    // The badge sits on the top-end corner of the ring's box (the 60 pt
    // icon plus gap and stroke on each side), not on the icon's own corner.
    final cellRect = tester.getRect(defaultCell);
    final badgeRect = tester.getRect(find.byType(SelectionCheckBadge));
    const ringBox =
        AppIconSize.appIconPreview + 2 * (AppSpacing.xs + AppStroke.focus);
    expect(badgeRect.top, cellRect.top);
    expect(badgeRect.right, cellRect.center.dx + ringBox / 2);

    // w600 on the selected label only.
    final selectedLabel = tester.widget<Text>(find.text('Default'));
    expect(selectedLabel.style?.fontWeight, FontWeight.w600);
    final unselectedLabel = tester.widget<Text>(find.text('Legacy'));
    expect(unselectedLabel.style?.fontWeight, isNot(FontWeight.w600));
  });

  testWidgets('icon cell height is identical selected or not',
      (tester) async {
    // Compare the same cell across both states: labels of different lengths
    // may wrap differently, that must not matter.
    Future<double> defaultCellHeight(String selectedId) async {
      await pumpGrid(
        tester,
        buildGrid: (l10n) => AppIconPreviewGrid(
          options: appIconPreviewOptions(l10n),
          selectedId: selectedId,
          isAndroid: false,
          isDark: false,
          onSelected: (_) {},
        ),
      );
      return tester
          .getRect(find.bySemanticsIdentifier('appIconDefaultTile'))
          .height;
    }

    final selectedHeight = await defaultCellHeight('Default');
    final unselectedHeight = await defaultCellHeight('Legacy');
    expect(unselectedHeight, selectedHeight);

    // Both cells reserve the same icon area: the 60 pt preview plus the
    // ring's gap and stroke (60 + 2 * (4 + 2)).
    const iconArea = 72.0;
    final reservedBoxes = tester
        .widgetList<SizedBox>(
          find.byWidgetPredicate(
            (w) => w is SizedBox && w.width == iconArea && w.height == iconArea,
          ),
        )
        .toList();
    expect(reservedBoxes, hasLength(2));
  });

  testWidgets('a 30-character label wraps to at most 2 lines without overflow',
      (tester) async {
    const longLabel = 'Sehr langer Symbolname ABCDEFG'; // 30 characters
    await pumpGrid(
      tester,
      buildGrid: (l10n) => AppIconPreviewGrid(
        options: [
          AppIconOption(
            id: 'Default',
            label: 'Default',
            previewAsset: _lightDefaultPreview,
            identifier: 'appIconDefaultTile',
          ),
          AppIconOption(
            id: 'Legacy',
            label: longLabel,
            previewAsset: _lightDefaultPreview,
            identifier: 'appIconLegacyTile',
          ),
        ],
        selectedId: 'Default',
        isAndroid: false,
        isDark: false,
        onSelected: (_) {},
      ),
    );

    expect(tester.takeException(), isNull);
    final label = tester.widget<Text>(find.text(longLabel));
    expect(label.maxLines, 2);
    expect(label.overflow, TextOverflow.ellipsis);
    // The label wraps inside its column instead of widening the cell.
    expect(
      tester.getRect(find.bySemanticsIdentifier('appIconLegacyTile')).width,
      cellWidth(400),
    );
  });

  testWidgets('Android cells use the oval mask, other platforms the squircle',
      (tester) async {
    Future<void> pump({required bool isAndroid}) => pumpGrid(
          tester,
          buildGrid: (l10n) => AppIconPreviewGrid(
            options: appIconPreviewOptions(l10n),
            selectedId: 'Default',
            isAndroid: isAndroid,
            isDark: false,
            onSelected: (_) {},
          ),
        );

    await pump(isAndroid: true);
    expect(find.byType(ClipOval), findsWidgets);
    expect(find.byType(ClipRSuperellipse), findsNothing);

    await pump(isAndroid: false);
    expect(find.byType(ClipRSuperellipse), findsWidgets);
    expect(find.byType(ClipOval), findsNothing);
  });

  testWidgets('tapping the selected icon does nothing; the other is reported',
      (tester) async {
    final selected = <String>[];
    await pumpGrid(
      tester,
      buildGrid: (l10n) => AppIconPreviewGrid(
        options: appIconPreviewOptions(l10n),
        selectedId: 'Default',
        isAndroid: false,
        isDark: false,
        onSelected: selected.add,
      ),
    );

    await tester.tap(find.bySemanticsIdentifier('appIconDefaultTile'));
    await tester.pump();
    expect(selected, isEmpty);

    await tester.tap(find.bySemanticsIdentifier('appIconLegacyTile'));
    await tester.pump();
    expect(selected, ['Legacy']);
  });

  testWidgets('Android icon confirmation: Cancel resolves false',
      (tester) async {
    bool? confirmed;
    await tester.pumpWidget(confirmationHarness((value) => confirmed = value));
    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Change the app icon?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(confirmed, isFalse);
  });

  testWidgets('Android icon confirmation: Confirm resolves true',
      (tester) async {
    bool? confirmed;
    await tester.pumpWidget(confirmationHarness((value) => confirmed = value));
    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();

    expect(find.textContaining('will close to apply it'), findsOneWidget);
    await tester.tap(find.text('Change icon'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
  });
}

/// Pumps a one-button harness that opens the Android icon-switch
/// confirmation and reports the outcome through [onResult].
Widget confirmationHarness(void Function(bool confirmed) onResult) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () async {
          final l10n = AppLocalizations.of(context)!;
          final result = await showAppIconSwitchConfirmation(
            context: context,
            l10n: l10n,
          );
          onResult(result);
        },
        child: const Text('Open dialog'),
      ),
    ),
  );
}
