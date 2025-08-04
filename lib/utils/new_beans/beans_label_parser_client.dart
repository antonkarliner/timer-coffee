import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin client wrapper around Supabase Edge Function `parse-coffee-label-gemini`.
/// Hides transport details and normalizes error messages.
class BeansLabelParserClient {
  final SupabaseClient supabase;

  BeansLabelParserClient(this.supabase);

  /// Invokes the Edge Function with base64 images and locale/user context.
  /// Returns parsed Map on success. Throws an Exception with a user-friendly message on failure.
  Future<Map<String, dynamic>> parseLabel({
    required List<String> base64Images,
    required String locale,
    String? userId,
  }) async {
    final response = await supabase.functions.invoke(
      'parse-coffee-label-gemini',
      body: {
        'imagesBase64': base64Images,
        'locale': locale,
        'userId': userId,
      },
    );

    if (response.status != 200) {
      throw Exception('Unexpected status code ${response.status}');
    }

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }

    if (data.containsKey('error')) {
      final err = data['error'];
      final msg = data['message'];
      if (err == 'Invocation limit reached') {
        throw Exception('Invocation limit reached');
      } else if (err == 'No coffee labels detected') {
        throw Exception('No coffee labels detected');
      } else {
        throw Exception(msg ?? 'Unexpected error occurred');
      }
    }

    return data;
  }
}
