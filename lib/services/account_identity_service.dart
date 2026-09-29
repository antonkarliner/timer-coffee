import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_logger.dart';
import '../utils/input_validator.dart';
import 'auth/native_auth_credentials.dart';

enum EmailChangeRequest {
  sent,
  invalidEmail,
  sameAsCurrent,
  emailTaken,
  rateLimited,
  failed,
}

enum EmailCodeResult { accepted, completed, invalidOrExpired, failed }

enum LinkOutcome {
  linked,
  redirected,
  cancelled,
  alreadyUsedByAnotherAccount,
  linkingDisabled,
  unsupportedPlatform,
  failed,
}

enum UnlinkOutcome { unlinked, notAllowed, failed }

/// Manages email changes and linked sign-in identities for the current user.
///
/// Secure email changes need codes from both addresses; the SDK reports the
/// first accepted code as an exception because its response has no session.
/// Linking adds a sign-in method to the same user ID, so no data migration is
/// needed.
class AccountIdentityService {
  AccountIdentityService({
    GoTrueClient? auth,
    NativeAuthCredentials? credentials,
    bool? isWeb,
    TargetPlatform? platform,
  }) : _injectedAuth = auth,
       _credentials = credentials ?? const NativeAuthCredentials(),
       _isWeb = isWeb ?? kIsWeb,
       _platform = platform ?? defaultTargetPlatform;

  @visibleForTesting
  static const missingVerificationSessionMessage =
      'An error occurred on token verification.';

  static const _nativeRedirect = 'timercoffee://';
  static const _webRedirect = 'https://app.timer.coffee/';
  static const _emailExistsCode = 'email_exists';
  static const _identityAlreadyExistsCode = 'identity_already_exists';
  static const _manualLinkingDisabledCode = 'manual_linking_disabled';
  static const _overEmailSendRateLimitCode = 'over_email_send_rate_limit';
  static const _otpExpiredCode = 'otp_expired';
  static const _singleIdentityNotDeletableCode =
      'single_identity_not_deletable';
  static const _emailConflictIdentityNotDeletableCode =
      'email_conflict_identity_not_deletable';

  final GoTrueClient? _injectedAuth;
  final NativeAuthCredentials _credentials;
  final bool _isWeb;
  final TargetPlatform _platform;

  GoTrueClient get auth => _injectedAuth ?? Supabase.instance.client.auth;

  GoTrueClient get _auth => auth;

  bool get canLinkGoogle => true;

  bool get canLinkApple =>
      !_isWeb &&
      (_platform == TargetPlatform.iOS || _platform == TargetPlatform.macOS);

  Future<List<UserIdentity>> identities() => _auth.getUserIdentities();

  /// Whether the current non-anonymous account has a confirmed account email.
  ///
  /// Email-code sign-in and secure email changes use the account email, so an
  /// email identity is not required.
  bool get canChangeEmail {
    final user = _auth.currentUser;
    return user != null &&
        !user.isAnonymous &&
        (user.email?.trim().isNotEmpty ?? false) &&
        user.emailConfirmedAt != null;
  }

  /// Returns the account email selected by GoTrue after [removing], or `null`
  /// when the account email will stay unchanged.
  static String? accountEmailAfterUnlink({
    required String? currentEmail,
    required UserIdentity removing,
    required List<UserIdentity> all,
  }) {
    final remaining = all
        .where((identity) => identity.identityId != removing.identityId)
        .toList();
    if (remaining.isEmpty) return null;

    final normalizedCurrentEmail = currentEmail?.trim().toLowerCase();
    if (normalizedCurrentEmail != null &&
        normalizedCurrentEmail.isNotEmpty &&
        remaining.any(
          (identity) =>
              _identityEmail(identity)?.toLowerCase() == normalizedCurrentEmail,
        )) {
      return null;
    }

    remaining.sort((left, right) {
      final rankComparison = _identityEmailRank(
        left,
      ).compareTo(_identityEmailRank(right));
      if (rankComparison != 0) return rankComparison;

      // Mirrors GoTrue v2.197.0 UpdateUserEmailFromIdentities: oldest first,
      // then the identity row id (identity_id, not the provider's id).
      final createdAtComparison = _createdAt(left).compareTo(_createdAt(right));
      if (createdAtComparison != 0) return createdAtComparison;

      return left.identityId.compareTo(right.identityId);
    });

    return _identityEmail(remaining.first);
  }

  Future<EmailChangeRequest> requestEmailChange(String newEmail) async {
    final email = _validatedEmail(newEmail);
    if (email == null) return EmailChangeRequest.invalidEmail;

    final currentEmail = _auth.currentUser?.email?.trim();
    if (currentEmail != null &&
        currentEmail.toLowerCase() == email.toLowerCase()) {
      return EmailChangeRequest.sameAsCurrent;
    }

    try {
      await _auth.updateUser(
        UserAttributes(email: email),
        emailRedirectTo: _emailRedirectTo,
      );
      return EmailChangeRequest.sent;
    } on AuthException catch (error) {
      return _mapEmailRequestError(error);
    } catch (error) {
      AppLogger.error('Email change request failed', errorObject: error);
      return EmailChangeRequest.failed;
    }
  }

  Future<EmailCodeResult> confirmEmailChangeCode({
    required String email,
    required String code,
  }) async {
    final normalizedCode = code.replaceAll(RegExp(r'\s+'), '');
    if (normalizedCode.isEmpty) return EmailCodeResult.invalidOrExpired;

    try {
      await _auth.verifyOTP(
        email: email.trim(),
        token: normalizedCode,
        type: OtpType.emailChange,
      );
      await _refreshUser('Email change completed but user refresh failed');
      return EmailCodeResult.completed;
    } on AuthApiException catch (error) {
      if (error.statusCode == '403' || error.code == _otpExpiredCode) {
        return EmailCodeResult.invalidOrExpired;
      }
      AppLogger.warning('Email change code verification failed');
      return EmailCodeResult.failed;
    } on AuthException catch (error) {
      if (error is! AuthApiException &&
          error.message == missingVerificationSessionMessage) {
        return EmailCodeResult.accepted;
      }
      AppLogger.warning('Email change code verification failed');
      return EmailCodeResult.failed;
    } catch (error) {
      AppLogger.error('Email change code verification failed');
      return EmailCodeResult.failed;
    }
  }

  Future<EmailChangeRequest> resendEmailChange(String newEmail) async {
    final email = _validatedEmail(newEmail);
    if (email == null) return EmailChangeRequest.invalidEmail;

    try {
      await _auth.resend(
        email: email,
        type: OtpType.emailChange,
        emailRedirectTo: _emailRedirectTo,
      );
      return EmailChangeRequest.sent;
    } on AuthException catch (error) {
      return _mapEmailRequestError(error);
    } catch (error) {
      AppLogger.error('Email change resend failed', errorObject: error);
      return EmailChangeRequest.failed;
    }
  }

  Future<LinkOutcome> linkGoogle() async {
    try {
      if (_isWeb) {
        await _auth.linkIdentity(
          OAuthProvider.google,
          redirectTo: _webRedirect,
        );
        return LinkOutcome.redirected;
      }

      final tokens = await _credentials.google(forceAccountChooser: true);
      if (tokens == null) return LinkOutcome.cancelled;
      await _auth.linkIdentityWithIdToken(
        provider: OAuthProvider.google,
        idToken: tokens.idToken,
        accessToken: tokens.accessToken,
      );
      await _refreshSession('Google linked but session refresh failed');
      return LinkOutcome.linked;
    } on AuthException catch (error) {
      return _mapLinkError(error);
    } catch (error) {
      AppLogger.error('Google identity linking failed', errorObject: error);
      return LinkOutcome.failed;
    }
  }

  Future<LinkOutcome> linkApple() async {
    if (!_isWeb &&
        _platform != TargetPlatform.iOS &&
        _platform != TargetPlatform.macOS) {
      return LinkOutcome.unsupportedPlatform;
    }

    try {
      if (_isWeb) {
        await _auth.linkIdentity(OAuthProvider.apple, redirectTo: _webRedirect);
        return LinkOutcome.redirected;
      }

      final tokens = await _credentials.apple();
      await _auth.linkIdentityWithIdToken(
        provider: OAuthProvider.apple,
        idToken: tokens.idToken,
        nonce: tokens.rawNonce,
      );
      await _refreshSession('Apple linked but session refresh failed');
      return LinkOutcome.linked;
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return LinkOutcome.cancelled;
      }
      AppLogger.warning('Apple identity authorization failed');
      return LinkOutcome.failed;
    } on AuthException catch (error) {
      return _mapLinkError(error);
    } catch (error) {
      AppLogger.error('Apple identity linking failed', errorObject: error);
      return LinkOutcome.failed;
    }
  }

  bool canUnlink(UserIdentity identity, List<UserIdentity> all) {
    return (identity.provider == 'google' || identity.provider == 'apple') &&
        all.length > 1;
  }

  Future<UnlinkOutcome> unlink(UserIdentity identity) async {
    try {
      final all = await identities();
      if (!canUnlink(identity, all)) return UnlinkOutcome.notAllowed;

      await _auth.unlinkIdentity(identity);
      await _refreshSession('Identity unlinked but session refresh failed');
      return UnlinkOutcome.unlinked;
    } on AuthException catch (error) {
      if (error.code == _singleIdentityNotDeletableCode ||
          error.code == _emailConflictIdentityNotDeletableCode) {
        return UnlinkOutcome.notAllowed;
      }
      AppLogger.warning('Identity unlink failed');
      return UnlinkOutcome.failed;
    } catch (error) {
      AppLogger.error('Identity unlink failed', errorObject: error);
      return UnlinkOutcome.failed;
    }
  }

  String? get _emailRedirectTo => _isWeb ? null : _nativeRedirect;

  String? _validatedEmail(String rawEmail) {
    return InputValidator.validateAndSanitizeEmail(rawEmail.trim());
  }

  EmailChangeRequest _mapEmailRequestError(AuthException error) {
    if (error.code == _emailExistsCode) {
      return EmailChangeRequest.emailTaken;
    }
    if (error.statusCode == '429' ||
        error.code == _overEmailSendRateLimitCode) {
      return EmailChangeRequest.rateLimited;
    }
    AppLogger.warning('Email change request failed');
    return EmailChangeRequest.failed;
  }

  LinkOutcome _mapLinkError(AuthException error) {
    if (error.code == _identityAlreadyExistsCode) {
      return LinkOutcome.alreadyUsedByAnotherAccount;
    }
    if (error.code == _manualLinkingDisabledCode) {
      AppLogger.error('Manual identity linking is disabled');
      return LinkOutcome.linkingDisabled;
    }
    AppLogger.warning('Identity linking failed');
    return LinkOutcome.failed;
  }

  Future<void> _refreshUser(String failureMessage) async {
    try {
      await _auth.getUser();
    } catch (error) {
      AppLogger.warning(failureMessage, errorObject: error);
    }
  }

  Future<void> _refreshSession(String failureMessage) async {
    try {
      await _auth.refreshSession();
    } catch (error) {
      AppLogger.warning(failureMessage, errorObject: error);
    }
  }

  static String? _identityEmail(UserIdentity identity) {
    final email = identity.identityData?['email'];
    if (email is! String || email.trim().isEmpty) return null;
    return email.trim();
  }

  static DateTime _createdAt(UserIdentity identity) =>
      DateTime.tryParse(identity.createdAt ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  static int _identityEmailRank(UserIdentity identity) {
    if (_identityEmail(identity) == null) return 2;
    return identity.identityData?['email_verified'] == true ? 0 : 1;
  }
}
