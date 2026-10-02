import 'dart:convert';

import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/screens/account_screen.dart';
import 'package:coffee_timer/services/account_identity_service.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/base_buttons.dart';
import 'package:coffee_timer/widgets/settings/settings_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Layout tests for the signed-in Account page ([AccountScreenBody]).
///
/// The real screen needs a live Supabase to load the profile (see
/// `account_deletion_reason_test.dart`), so the state class extracts the
/// signed-in body into [AccountScreenBody]; these tests pump that with a
/// mock-backed [AccountIdentityService] so the sign-in methods section
/// renders the same rows the screen shows.
void main() {
  const authUrl = 'https://example.test/auth/v1';
  const userId = '22222222-2222-2222-2222-222222222222';
  const pictureUrl = 'https://example.test/custom-picture.webp';

  final userJson = {
    'id': userId,
    'aud': 'authenticated',
    'email': 'user@example.com',
    'email_confirmed_at': '2026-01-01T00:00:00.000Z',
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
    'created_at': '2026-01-01T00:00:00.000Z',
    'identities': [
      {
        'identity_id': 'email-identity',
        'id': 'email-id',
        'user_id': userId,
        'provider': 'email',
        'identity_data': <String, dynamic>{
          'provider': 'email',
          'email': 'user@example.com',
          'email_verified': true,
        },
        'created_at': '2026-01-01T00:00:00.000Z',
        'last_sign_in_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
      },
    ],
  };

  Future<void> pumpBody(
    WidgetTester tester, {
    required bool isEditMode,
    _Taps? taps,
    EdgeInsets bottomPadding = EdgeInsets.zero,
  }) async {
    final auth = GoTrueClient(
      url: authUrl,
      httpClient: MockClient((request) async {
        if (request.method == 'GET' && request.url.path.endsWith('/user')) {
          return http.Response(
            jsonEncode(userJson),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        throw StateError(
          'Unexpected request: ${request.method} ${request.url.path}',
        );
      }),
      autoRefreshToken: false,
    );
    addTearDown(auth.dispose);
    await auth.recoverSession(
      jsonEncode({
        'access_token': 'test-access-token',
        'refresh_token': 'test-refresh-token',
        'token_type': 'bearer',
        'expires_in': 3600,
        'expires_at': 4102444800,
        'user': userJson,
      }),
    );

    final service = AccountIdentityService(
      auth: auth,
      isWeb: false,
      platform: TargetPlatform.iOS,
    );

    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(800, 1600),
            padding: bottomPadding,
          ),
          child: Scaffold(
            body: AccountScreenBody(
              displayName: 'Test User',
              profilePictureUrl: pictureUrl,
              defaultAvatarUrl: 'https://example.test/avatar_default.webp',
              isEditMode: isEditMode,
              onEditName: () => taps?.editName = true,
              onEditPicture: () => taps?.editPicture = true,
              onDeletePicture: () => taps?.deletePicture = true,
              onSignOut: () => taps?.signOut = true,
              onDeleteAccount: () => taps?.deleteAccount = true,
              signInMethodsService: service,
            ),
          ),
        ),
      ),
    );
    // The section refreshes its identities in a post-frame callback; fixed
    // pumps run it without waiting on the avatar's image placeholder.
    await tester.pump();
    await tester.pump();
  }

  testWidgets(
    'renders the two action rows after the sign-in rows, with no elevated '
    'buttons and no shadowed footer',
    (tester) async {
      await pumpBody(tester, isEditMode: false, taps: _Taps());

      expect(find.byType(AppElevatedButton), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              ((widget.decoration! as BoxDecoration).boxShadow?.isNotEmpty ??
                  false),
        ),
        findsNothing,
      );
      expect(find.byType(SettingsActionRow), findsNWidgets(2));

      // The delete row follows the sign-out row, and both follow the
      // sign-in rows.
      final emailRowTop = tester.getTopLeft(
        find.byKey(const ValueKey('email')),
      ).dy;
      final signOutTop = tester.getTopLeft(
        find.bySemanticsIdentifier('accountSignOutRow'),
      ).dy;
      final deleteTop = tester.getTopLeft(
        find.bySemanticsIdentifier('accountDeleteRow'),
      ).dy;
      expect(emailRowTop, lessThan(signOutTop));
      expect(signOutTop, lessThan(deleteTop));

      final signOutRow = tester.widget<SettingsActionRow>(
        find.ancestor(
          of: find.bySemanticsIdentifier('accountSignOutRow'),
          matching: find.byType(SettingsActionRow),
        ),
      );
      expect(signOutRow.title, 'Sign out');
      expect(signOutRow.destructive, isFalse);

      final deleteRow = tester.widget<SettingsActionRow>(
        find.ancestor(
          of: find.bySemanticsIdentifier('accountDeleteRow'),
          matching: find.byType(SettingsActionRow),
        ),
      );
      expect(deleteRow.title, 'Delete account');
      expect(deleteRow.destructive, isTrue);
    },
  );

  testWidgets('tapping the rows calls the sign-out and delete callbacks', (
    tester,
  ) async {
    final taps = _Taps();
    await pumpBody(tester, isEditMode: false, taps: taps);

    await tester.tap(find.bySemanticsIdentifier('accountSignOutRow'));
    await tester.tap(find.bySemanticsIdentifier('accountDeleteRow'));

    expect(taps.signOut, isTrue);
    expect(taps.deleteAccount, isTrue);
    expect(taps.editName, isFalse);
  });

  testWidgets('the display name uses the headline style', (tester) async {
    await pumpBody(tester, isEditMode: false, taps: _Taps());

    final style = tester.widget<Text>(find.text('Test User')).style;
    expect(style?.fontSize, AppTextStyles.headline.fontSize);
    expect(style?.fontWeight, AppTextStyles.headline.fontWeight);
  });

  testWidgets('the edit-mode overlay buttons appear only in edit mode', (
    tester,
  ) async {
    final taps = _Taps();
    await pumpBody(tester, isEditMode: false, taps: taps);
    expect(find.byIcon(Icons.edit), findsNothing);
    expect(find.byIcon(Icons.delete), findsNothing);

    await pumpBody(tester, isEditMode: true, taps: taps);
    // The avatar overlay and the name-row pencil (the app bar is not part of
    // the extracted body).
    expect(find.byIcon(Icons.edit), findsNWidgets(2));
    // The avatar delete overlay; the delete ACCOUNT row has no icon.
    expect(find.byIcon(Icons.delete), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit).first);
    await tester.tap(find.byIcon(Icons.edit).at(1));
    await tester.tap(find.byIcon(Icons.delete));
    expect(taps.editPicture, isTrue);
    expect(taps.editName, isTrue);
    expect(taps.deletePicture, isTrue);
    expect(taps.signOut, isFalse);
  });

  testWidgets('the page clears the bottom safe area like SettingsPageScaffold',
      (tester) async {
    await pumpBody(
      tester,
      isEditMode: false,
      taps: _Taps(),
      bottomPadding: const EdgeInsets.only(bottom: 34),
    );

    final padding = tester.widget<ListView>(find.byType(ListView)).padding!;
    expect((padding as EdgeInsetsDirectional).bottom, 34 + AppSpacing.base);
  });
}

/// Records which handlers the pumped body invoked.
class _Taps {
  bool editName = false;
  bool editPicture = false;
  bool deletePicture = false;
  bool signOut = false;
  bool deleteAccount = false;
}
