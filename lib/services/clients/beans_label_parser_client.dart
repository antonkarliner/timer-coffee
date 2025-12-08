import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin client wrapper around Supabase Edge Function `parse-coffee-label-groq`.
/// Hides transport details and normalizes error messages.
class BeansLabelParserClient {
  final SupabaseClient supabase;

  BeansLabelParserClient(this.supabase);

  /// Invokes the Edge Function.
  /// - imagesBase64: required
  /// - locale: target translation locale (still sent)
  /// - userId: optional
  /// - ocrText/mode/minTextChars: optional hints to allow server auto-select text vs image path
  /// Note: Locale is not used for OCR; server can detect source language from OCR text.
  Future<Map<String, dynamic>> parseLabel({
    required List<String> base64Images,
    required String locale,
    String? userId,
    String? ocrText,
    String mode = 'auto',
    int minTextChars = 120,
  }) async {
    final Map<String, dynamic> body = {
      'imagesBase64': base64Images,
      'locale': locale, // keep target locale for translation
      'userId': userId,
      // Extended fields: server may ignore until fully supported.
      'ocrText': ocrText,
      'mode': mode,
      'minTextChars': minTextChars,
    };

    final response = await supabase.functions.invoke(
      'parse-coffee-label-groq',
      body: body,
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
