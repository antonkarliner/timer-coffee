import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/models/coffee_beans_model.dart';
import 'package:coffee_timer/services/date_time_format_service.dart';
import 'package:coffee_timer/widgets/coffee_bean_details/coffee_beans_hero_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'brew_flow_async_context_test.mocks.dart';

/// Returns the line tops each word of [paragraph]'s text is laid out on.
/// A word that spans more than one line was broken mid-word.
Map<String, Set<double>> _wordLineTops(RenderParagraph paragraph) {
  final text = paragraph.text.toPlainText();
  final result = <String, Set<double>>{};
  for (final match in RegExp(r'\S+').allMatches(text)) {
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: match.start, extentOffset: match.end),
    );
    result[match.group(0)!] = boxes.map((b) => b.top).toSet();
  }
  return result;
}

void main() {
  Future<RenderParagraph> pumpHeader(
    WidgetTester tester, {
    required String name,
    required String roaster,
  }) async {
    // iPhone 18 Pro logical width, where "Kenya Kamunyaka AA" used to break
    // as "Kenya Kam / unyaka AA" on device. The test font gives every glyph
    // the same width, so the cases below use names that reproduce the
    // mid-word break with it.
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final bean = CoffeeBeansModel(
      beansUuid: 'bean-1',
      roaster: roaster,
      name: name,
      origin: 'Kenya',
      isFavorite: true,
      versionVector: '{}',
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<DateTimeFormatService>.value(
        value: DateTimeFormatService(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: CoffeeBeansHeroHeader(
              bean: bean,
              coffeeBeansProvider: MockCoffeeBeansProvider(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.bySemanticsIdentifier('beanName_${bean.beansUuid}'),
        matching: find.byType(RichText),
      ),
    );
  }

  testWidgets('a long bean name is never broken in the middle of a word', (
    tester,
  ) async {
    final paragraph = await pumpHeader(
      tester,
      name: 'Yirgacheffe AA',
      roaster: 'Onyx Coffee Lab',
    );

    final tops = _wordLineTops(paragraph);
    expect(tops.keys, ['Yirgacheffe', 'AA']);
    for (final entry in tops.entries) {
      expect(
        entry.value,
        hasLength(1),
        reason: '"${entry.key}" was split across lines',
      );
    }
  });

  testWidgets('a long roaster name is never broken in the middle of a word', (
    tester,
  ) async {
    await pumpHeader(
      tester,
      name: 'Test Beans',
      roaster: 'Koffieboontje',
    );

    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.bySemanticsIdentifier('roasterName_bean-1'),
        matching: find.byType(RichText),
      ),
    );
    final tops = _wordLineTops(paragraph);
    expect(tops['Koffieboontje'], hasLength(1));
  });
}
