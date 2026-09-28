import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleIdTokens {
  const GoogleIdTokens({required this.idToken, required this.accessToken});

  final String idToken;
  final String accessToken;
}

class AppleIdTokens {
  const AppleIdTokens({required this.idToken, required this.rawNonce});

  final String idToken;
  final String rawNonce;
}

class NativeAuthCredentials {
  const NativeAuthCredentials({GoTrueClient? auth}) : _injectedAuth = auth;

  static const _webClientId =
      '158450410168-i70d1cqrp1kkg9abet7nv835cbf8hmfn.apps.googleusercontent.com';
  static const _iosClientId =
      '158450410168-8o2bk6r3e4ik8i413ua66bc50iug45na.apps.googleusercontent.com';

  final GoTrueClient? _injectedAuth;

  GoTrueClient get _auth => _injectedAuth ?? Supabase.instance.client.auth;

  /// Returns null when the user cancels the Google account chooser.
  Future<GoogleIdTokens?> google({bool forceAccountChooser = false}) async {
    final googleSignIn = GoogleSignIn(
      clientId: _iosClientId,
      serverClientId: _webClientId,
    );
    if (forceAccountChooser) {
      await googleSignIn.signOut();
    }

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;
    if (accessToken == null) {
      throw 'No Access Token found.';
    }
    if (idToken == null) {
      throw 'No ID Token found.';
    }

    return GoogleIdTokens(idToken: idToken, accessToken: accessToken);
  }

  /// Throws [SignInWithAppleAuthorizationException] when authorization fails.
  Future<AppleIdTokens> apple() async {
    final rawNonce = _auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException(
        'Could not find ID Token from generated credential.',
      );
    }

    return AppleIdTokens(idToken: idToken, rawNonce: rawNonce);
  }
}
