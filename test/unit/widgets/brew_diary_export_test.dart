import 'dart:convert';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/providers/database_provider.dart';
import 'package:coffee_timer/providers/user_stat_provider.dart';
import 'package:coffee_timer/screens/brew_diary_screen.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

import 'brew_flow_async_context_test.mocks.dart';

/// Covers the "whole diary" and "per bean" share entry points (plan 036,
/// Phase 2b) in the brew diary screen.
///
/// `share_plus` has no registered platform channel handler under
/// `flutter_test` (calling the real channel hangs rather than throwing), so
/// these tests install a fake [SharePlatform] — the standard federated-
/// plugin test double pattern — to observe what `shareBrewExport` actually
/// hands to the share sheet, without ever touching a real channel.
class _RecordingSharePlatform extends SharePlatform {
  ShareParams? lastParams;
  int callCount = 0;

  void reset() {
    lastParams = null;
    callCount = 0;
  }

  @override
  Future<ShareResult> share(ShareParams params) async {
    callCount++;
    lastParams = params;
    return const ShareResult('ok', ShareResultStatus.success);
  }
}

void main() {
  // One fake for the whole file, reset between tests — NOT a fresh instance per
  // test. `SharePlus.instance` is a `static final` that binds to whatever
  // `SharePlatform.instance` holds the first time it is touched, so swapping in
  // a new platform per test leaves `SharePlus` talking to the first test's fake
  // and every later test observes callCount == 0.
  final sharePlatform = _RecordingSharePlatform();

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharePlatform.instance = sharePlatform;
    sharePlatform.reset();
  });

  Widget localizedApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    );
  }

  DiaryEntry entry() => DiaryEntry(
    statUuid: 'stat-1',
    recipeId: 'recipe-1',
    recipeName: 'Test recipe',
    brewingMethodId: 'v60',
    methodName: 'V60',
    createdAt: DateTime.utc(2026, 7, 1, 8, 30),
    coffeeAmount: 15,
    waterAmount: 250,
    isMarked: false,
    notes: 'Sweet cup',
    coffeeBeansUuid: 'bean-1',
    beanName: 'Test beans',
    roaster: 'Test roaster',
  );

  DatabaseProvider stubbedDatabaseProvider() {
    final mock = MockDatabaseProvider();
    when(
      mock.fetchCachedRoasterLogoUrls(any),
    ).thenAnswer((_) async => const {'original': null, 'mirror': null});
    return mock;
  }

  Widget diaryApp(UserStatProvider provider, {DatabaseProvider? database}) {
    final resolvedDatabase = database ?? stubbedDatabaseProvider();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserStatProvider>.value(value: provider),
        Provider<DatabaseProvider>.value(value: resolvedDatabase),
        ChangeNotifierProvider<DateTimeFormatService>(
          create: (_) => DateTimeFormatService(),
        ),
      ],
      child: localizedApp(const BrewDiaryScreen()),
    );
  }

  testWidgets('share-diary button is disabled while the diary is empty', (
    tester,
  ) async {
    final provider = MockUserStatProvider();
    when(
      provider.fetchDiaryEntries('en'),
    ).thenAnswer((_) async => <DiaryEntry>[]);
    when(provider.topMethodsLast90Days('en')).thenAnswer((_) async => const []);

    await tester.pumpWidget(diaryApp(provider));
    await tester.pumpAndSettle();

    final button = tester.widget<IconButton>(
      find.byKey(const Key('shareDiaryButton')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets(
    'share-diary button shares the whole diary as a markdown file once entries load',
    (tester) async {
      final provider = MockUserStatProvider();
      final e = entry();
      when(provider.fetchDiaryEntries('en')).thenAnswer((_) async => [e]);
      when(
        provider.topMethodsLast90Days('en'),
      ).thenAnswer((_) async => const []);

      await tester.pumpWidget(diaryApp(provider));
      await tester.pumpAndSettle();

      final button = tester.widget<IconButton>(
        find.byKey(const Key('shareDiaryButton')),
      );
      expect(button.onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('shareDiaryButton')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(sharePlatform.callCount, 1);
      final params = sharePlatform.lastParams!;
      expect(params.text, isNull);
      expect(params.files, hasLength(1));
      final file = params.files!.single;
      // charset is declared explicitly: a bare .md carries no encoding hint,
      // and viewers that guess Latin-1 render every multi-byte character as
      // mojibake ("90 °C" → "90 Â°C").
      expect(file.mimeType, 'text/markdown; charset=utf-8');
      // Share sheets show this as the item's headline; without it iOS renders
      // only "MD · <size>" with no name.
      expect(params.title, isNotEmpty);
      // The shared file is named via `fileNameOverrides`, NOT via XFile's
      // `path`/`name`. share_plus only writes a bytes-backed XFile to a temp
      // file when `XFile.path` is empty (`MethodChannelShare._getFile` returns
      // early on a non-empty path), so giving the XFile a path produces a
      // zero-byte, unnamed item in the iOS share sheet — confirmed on an
      // iPhone 17 Pro simulator. Assert the empty path explicitly so
      // reintroducing one fails here instead of silently on a device.
      expect(file.path, isEmpty);
      expect(params.fileNameOverrides, hasLength(1));
      expect(params.fileNameOverrides!.single, endsWith('.md'));
      expect(
        params.fileNameOverrides!.single,
        startsWith('timer_coffee_brew_diary_'),
      );
      final bytes = await file.readAsBytes();
      // Leading UTF-8 BOM (EF BB BF) so viewers stop guessing the encoding.
      expect(bytes.take(3), orderedEquals(<int>[0xEF, 0xBB, 0xBF]));
      final content = utf8.decode(bytes);
      // Whole-diary export carries a document title + export timestamp —
      // absent from a single-brew export.
      expect(content, contains('Timer.Coffee Brew Diary'));
      expect(content, contains('Test beans'));
      // No non-breaking spaces: invisible in a plain-text file, and they were
      // the most common non-ASCII byte in the output.
      expect(content, isNot(contains('\u00A0')));
    },
  );

  testWidgets(
    'per-bean share button in the grouped view shares that bean as a markdown file',
    (tester) async {
      final provider = MockUserStatProvider();
      final e = entry();
      when(provider.fetchDiaryEntries('en')).thenAnswer((_) async => [e]);
      when(
        provider.topMethodsLast90Days('en'),
      ).thenAnswer((_) async => const []);

      await tester.pumpWidget(diaryApp(provider));
      await tester.pumpAndSettle();

      // Switch to the bean-grouped view via the axis TabBar.
      final loc = AppLocalizations.of(
        tester.element(find.byType(BrewDiaryScreen)),
      )!;
      await tester.tap(find.text(loc.diaryGroupByBean));
      await tester.pumpAndSettle();

      final shareButtonFinder = find.byKey(
        Key('diaryGroupShareButton_${e.coffeeBeansUuid}'),
      );
      expect(shareButtonFinder, findsOneWidget);

      await tester.tap(shareButtonFinder);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(sharePlatform.callCount, 1);
      final params = sharePlatform.lastParams!;
      expect(params.text, isNull);
      expect(params.files, hasLength(1));
      final content = utf8.decode(await params.files!.single.readAsBytes());
      // by-bean scope headings are "Roaster · Bean name", no document title.
      expect(content, isNot(contains('Timer.Coffee Brew Diary')));
      expect(content, contains('Test roaster'));
      expect(content, contains('Test beans'));
    },
  );
}
