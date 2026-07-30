
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/diary_entry.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/widgets/brew_diary/brew_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

/// Covers the single-brew share entry point (plan 036, Phase 2b) in
/// `brew_detail_sheet.dart`'s header.
///
/// `share_plus` has no registered platform channel handler under
/// `flutter_test` (calling the real channel hangs rather than throwing), so
/// these tests install a fake [SharePlatform] — the standard federated-
/// plugin test double pattern — to observe what `shareBrewExport` actually
/// hands to the share sheet, without ever touching a real channel.
class _RecordingSharePlatform extends SharePlatform {
  ShareParams? lastParams;
  int callCount = 0;

  @override
  Future<ShareResult> share(ShareParams params) async {
    callCount++;
    lastParams = params;
    return const ShareResult('ok', ShareResultStatus.success);
  }
}

void main() {
  late _RecordingSharePlatform sharePlatform;

  setUp(() {
    sharePlatform = _RecordingSharePlatform();
    SharePlatform.instance = sharePlatform;
  });

  final entry = DiaryEntry(
    statUuid: 'stat-1',
    recipeId: 'recipe-1',
    recipeName: 'Test recipe',
    brewingMethodId: 'v60',
    methodName: 'V60',
    createdAt: DateTime.utc(2026, 7, 14),
    coffeeAmount: 15,
    waterAmount: 250,
    isMarked: false,
    notes: 'Great cup',
    grindSize: '24 clicks',
    waterTemp: 93,
    rating: 4.5,
  );

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<DateTimeFormatService>(
        create: (_) => DateTimeFormatService(),
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: BrewDetailSheet(entry: entry)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('share button exists in the header alongside bookmark and menu', (
    tester,
  ) async {
    await pumpSheet(tester);

    expect(find.byKey(const Key('shareBrewButton')), findsOneWidget);
  });

  testWidgets('tapping share shares the brew as text, not a file', (
    tester,
  ) async {
    await pumpSheet(tester);

    await tester.tap(find.byKey(const Key('shareBrewButton')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(sharePlatform.callCount, 1);
    final params = sharePlatform.lastParams!;
    expect(params.files, isNull);
    expect(params.text, isNotNull);
    // Single-brew export carries no document title / export timestamp —
    // just the brew — so it pastes cleanly into a message or forum post.
    expect(params.text, isNot(contains('Timer.Coffee Brew Diary')));
    expect(params.text, contains('Great cup'));
    expect(params.text, contains('24 clicks'));
  });
}
