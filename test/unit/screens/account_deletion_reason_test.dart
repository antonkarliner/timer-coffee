import 'package:coffee_timer/screens/account_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Plan 074 phase 13: the `account_deletion_failed` reason classification.
/// The real account flows need a live Supabase, so the flows themselves are
/// covered by reading; this pins the one piece of decision logic — an edge
/// function rejection (supabase throws FunctionException for non-2xx) is
/// `server`, everything else is `error`.
void main() {
  group('accountDeletionFailureReason', () {
    test('FunctionException classifies as server', () {
      expect(
        accountDeletionFailureReason(const FunctionException(status: 402)),
        'server',
      );
      expect(
        accountDeletionFailureReason(
          const FunctionException(
            status: 500,
            reasonPhrase: 'Internal Server Error',
          ),
        ),
        'server',
      );
    });

    test('everything else classifies as error', () {
      expect(
        accountDeletionFailureReason(Exception('SocketException: …')),
        'error',
      );
      expect(accountDeletionFailureReason(StateError('no session')), 'error');
      expect(
        accountDeletionFailureReason(Exception('AuthApiClient error')),
        'error',
      );
    });
  });
}
