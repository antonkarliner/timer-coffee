import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum PendingWebSignInAction { none, expired, resume, cancelled }

class PendingWebSignIn {
  const PendingWebSignIn({
    required this.oldUserId,
    required this.oldAccessToken,
    required this.source,
    required this.method,
    required this.createdAtMs,
  });

  static const storageKey = 'auth_pending_web_sign_in_v1';
  static const ttl = Duration(minutes: 15);

  final String? oldUserId;
  final String? oldAccessToken;
  final String source;
  final String method;
  final int createdAtMs;

  String toJson() => jsonEncode({
    'oldUserId': oldUserId,
    'oldAccessToken': oldAccessToken,
    'source': source,
    'method': method,
    'createdAtMs': createdAtMs,
  });

  static PendingWebSignIn? fromJson(String? value) {
    if (value == null) return null;

    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) return null;

      final oldUserId = decoded['oldUserId'];
      final oldAccessToken = decoded['oldAccessToken'];
      final source = decoded['source'];
      final method = decoded['method'];
      final createdAtMs = decoded['createdAtMs'];
      if ((oldUserId != null && oldUserId is! String) ||
          (oldAccessToken != null && oldAccessToken is! String) ||
          source is! String ||
          method is! String ||
          createdAtMs is! int) {
        return null;
      }

      return PendingWebSignIn(
        oldUserId: oldUserId as String?,
        oldAccessToken: oldAccessToken as String?,
        source: source,
        method: method,
        createdAtMs: createdAtMs,
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> save() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(storageKey, toJson());
  }

  static Future<PendingWebSignIn?> load() async {
    final preferences = await SharedPreferences.getInstance();
    return fromJson(preferences.getString(storageKey));
  }

  static Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(storageKey);
  }
}

PendingWebSignInAction decidePendingWebSignIn({
  required PendingWebSignIn? pending,
  required String? currentUserId,
  required bool currentUserIsAnonymous,
  required DateTime now,
}) {
  if (pending == null) return PendingWebSignInAction.none;

  final age = now.difference(
    DateTime.fromMillisecondsSinceEpoch(pending.createdAtMs),
  );
  if (age > PendingWebSignIn.ttl) {
    return PendingWebSignInAction.expired;
  }

  if (currentUserId != null &&
      !currentUserIsAnonymous &&
      currentUserId != pending.oldUserId) {
    return PendingWebSignInAction.resume;
  }

  return PendingWebSignInAction.cancelled;
}
