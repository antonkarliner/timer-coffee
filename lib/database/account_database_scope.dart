import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// The storage namespace and remote credentials for one account partition.
/// A pending request from an old partition cannot acquire a new user's token.
class AccountDatabaseScope {
  AccountDatabaseScope({
    required this.userId,
    required this.partitionId,
    required String supabaseUrl,
    required String supabaseKey,
    required Session? Function() currentSession,
    http.Client? httpClient,
  }) : _currentSession = currentSession {
    client = SupabaseClient(
      supabaseUrl,
      supabaseKey,
      httpClient: httpClient,
      accessToken: () async {
        if (userId == null) return null;
        final session = _currentSession();
        if (session == null || session.user.id != userId) {
          throw StateError('The local account partition is no longer active');
        }
        return session.accessToken;
      },
    );
  }

  final String? userId;
  final String partitionId;
  final Session? Function() _currentSession;
  late final SupabaseClient client;

  String get databaseName {
    final encodedId = base64Url.encode(utf8.encode(partitionId));
    return 'account-$encodedId.sqlite';
  }

  bool get isActive => _currentSession()?.user.id == userId;

  User? get currentUser {
    final user = _currentSession()?.user;
    return user?.id == userId ? user : null;
  }
}
