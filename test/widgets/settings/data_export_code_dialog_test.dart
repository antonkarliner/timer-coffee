import 'dart:async';

import 'package:coffee_timer/database/database.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/services/analytics_service.dart';
import 'package:coffee_timer/services/data_export_service.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/widgets/fields/otp_code_field.dart';
import 'package:coffee_timer/widgets/settings/data_export_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_database.dart';

/// Overrides confirmation without reading the database or contacting Supabase.
class _FakeDataExportService extends DataExportService {
  _FakeDataExportService(AppDatabase database) : super(database: database);

  final result = Completer<DataExportResult>();
  final codes = <String>[];

  @override
  Future<DataExportResult> confirmAndSend(String code) {
    codes.add(code);
    return result.future;
  }
}

Future<void> _openDialog(
  WidgetTester tester,
  DataExportService service,
  ValueChanged<bool?> onClosed,
) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: Builder(
          builder: (context) => AppTextButton(
            label: 'Open',
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (_) => DataExportCodeDialog(
                  service: service,
                  email: 'coffee@example.com',
                ),
              );
              onClosed(result);
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  late AppDatabase database;

  // Built inside each test body, not in setUp: setUp runs outside
  // testWidgets' fake-async zone, and a Completer created there resumes its
  // awaiters in the real zone, which `pump` never drains.
  _FakeDataExportService newService() => _FakeDataExportService(database);

  setUp(() async {
    database = openTestDatabase();
    SharedPreferences.setMockInitialValues({});
    AnalyticsService.resetForTesting();
    await AnalyticsService.initialize(await SharedPreferences.getInstance());
  });

  tearDown(() async {
    AnalyticsService.resetForTesting();
    await database.close();
  });

  testWidgets('six digits confirm once and success pops true', (tester) async {
    final service = newService();
    final results = <bool?>[];
    await _openDialog(tester, service, results.add);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.pump();

    expect(service.codes, ['123456']);
    expect(results, isEmpty);
    expect(
      tester.widget<OtpCodeField>(find.byType(OtpCodeField)).enabled,
      isFalse,
    );
    expect(
      tester
          .widget<AppElevatedButton>(find.byType(AppElevatedButton))
          .isLoading,
      isTrue,
    );
    service.result.complete(const DataExportSuccess());
    await tester.pumpAndSettle();

    expect(results, [true]);
    expect(service.codes, hasLength(1));
    expect(find.byType(DataExportCodeDialog), findsNothing);
  });

  testWidgets(
    'incorrect code stays open with localized error and empty field',
    (tester) async {
      final service = newService();
      final results = <bool?>[];
      await _openDialog(tester, service, results.add);
      final loc = AppLocalizations.of(
        tester.element(find.byType(DataExportCodeDialog)),
      )!;
      final originalState = tester.state(find.byType(OtpCodeField));

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();
      service.result.complete(
        const DataExportIncorrectCode(attemptsRemaining: 2),
      );
      await tester.pumpAndSettle();

      expect(results, isEmpty);
      expect(find.byType(DataExportCodeDialog), findsOneWidget);
      expect(find.text(loc.dataExportIncorrectCodeAttempts(2)), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, isEmpty);
      expect(field.focusNode!.hasFocus, isTrue);
      expect(tester.state(find.byType(OtpCodeField)), same(originalState));
      expect(service.codes, ['123456']);
    },
  );

  testWidgets('renders shared OTP field with export semantic identifier', (
    tester,
  ) async {
    final service = newService();
    await _openDialog(tester, service, (_) {});

    expect(find.byType(OtpCodeField), findsOneWidget);
    final field = tester.widget<OtpCodeField>(find.byType(OtpCodeField));
    expect(field.semanticIdentifier, 'dataExportCodeField');
    expect(service.codes, isEmpty);
  });
}
