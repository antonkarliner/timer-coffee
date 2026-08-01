import 'package:coffee_timer/utils/app_material_symbols.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  test('vitalSigns preserves the Material Symbols glyph metadata', () {
    expect(AppMaterialSymbols.vitalSigns.codePoint, 0xe650);
    expect(AppMaterialSymbols.vitalSigns.fontFamily, 'MaterialSymbolsOutlined');
    expect(AppMaterialSymbols.vitalSigns.fontPackage, 'material_symbols_icons');
  });

  testWidgets('VitalSignsIcon renders the SVG fallback', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: IconTheme(
          data: IconThemeData(size: 32, color: Colors.red),
          child: VitalSignsIcon(),
        ),
      ),
    );

    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('NewsModeIcon renders the exact SVG fallback', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: IconTheme(
          data: IconThemeData(size: 32, color: Colors.red),
          child: NewsModeIcon(),
        ),
      ),
    );

    expect(find.byType(SvgPicture), findsOneWidget);
  });
}
