import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/services/advanced_features_service.dart';
import 'package:coffee_timer/widgets/settings/advanced_features_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'programmatic expansion shows the description and exposes the pour tile',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final advancedFeatures = AdvancedFeaturesService();
      final controller = ExpansibleController();
      final pourLayoutTileKey = GlobalKey();
      addTearDown(advancedFeatures.dispose);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<AdvancedFeaturesService>.value(
          value: advancedFeatures,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: AdvancedFeaturesSection(
                  controller: controller,
                  pourLayoutTileKey: pourLayoutTileKey,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Immersive brewing screen'), findsNothing);
      expect(
        find.text(
          'These features are experimental and may sometimes be unstable.',
        ),
        findsNothing,
      );

      controller.expand();
      await tester.pumpAndSettle();

      expect(find.text('Immersive brewing screen'), findsOneWidget);
      expect(pourLayoutTileKey.currentContext, isNotNull);
      expect(
        find.text(
          'These features are experimental and may sometimes be unstable.',
        ),
        findsOneWidget,
      );
    },
  );
}
