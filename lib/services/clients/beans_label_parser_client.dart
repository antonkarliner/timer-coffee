import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin client wrapper around Supabase Edge Function `parse-coffee-label`.
/// Hides transport details and normalizes error messages.
class BeansLabelParserClient {
  final SupabaseClient supabase;

  BeansLabelParserClient(this.supabase);

  /// Invokes the Edge Function.
  /// - imagesBase64: required
  /// - locale: target translation locale (still sent)
  /// - userId: optional
  Future<Map<String, dynamic>> parseLabel({
    required List<String> base64Images,
    required String locale,
    String? userId,
  }) async {
    final images = await compute(prepareLabelPhotos, base64Images);
    final auth = supabase.auth;
    final session = auth.currentSession;
    if (session?.user.id != userId) {
      throw StateError('Label scan session changed');
    }
    // Snapshot credentials before the SDK begins asynchronous body encoding.
    final authorization = session == null
        ? auth.headers['Authorization']
        : 'Bearer ${session.accessToken}';
    if (authorization == null || authorization.isEmpty) {
      throw StateError('Label scan credentials are unavailable');
    }
    final Map<String, dynamic> body = {
      'imagesBase64': images,
      'locale': locale, // keep target locale for translation
      'userId': userId,
    };

    final response = await supabase.functions.invoke(
      'parse-coffee-label',
      body: body,
      headers: {'Authorization': authorization},
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

/// Only pixel data crosses the label-recognition boundary. Even small,
/// already-resized images can contain original camera metadata.
List<String> prepareLabelPhotos(List<String> photos) {
  return photos.map((encoded) {
    final bytes = base64Decode(encoded);
    final decoder = img.findDecoderForData(bytes);
    final info = decoder?.startDecode(bytes);
    if (info == null ||
        info.width <= 0 ||
        info.height <= 0 ||
        info.width * info.height > 48000000) {
      throw const FormatException('Unsupported label photo');
    }
    final frame = decoder!.decodeFrame(0);
    if (frame == null) throw const FormatException('Unreadable label photo');
    final oriented = img.bakeOrientation(frame);
    final resized = oriented.width > 1600 || oriented.height > 1600
        ? img.copyResize(
            oriented,
            width: oriented.width >= oriented.height ? 1600 : null,
            height: oriented.height > oriented.width ? 1600 : null,
          )
        : oriented;
    final rgb = resized
        .convert(format: img.Format.uint8, numChannels: 3)
        .getBytes(order: img.ChannelOrder.rgb);
    final clean = img.Image.fromBytes(
      width: resized.width,
      height: resized.height,
      bytes: rgb.buffer,
      bytesOffset: rgb.offsetInBytes,
      numChannels: 3,
    );
    return base64Encode(img.encodeJpg(clean, quality: 85));
  }).toList();
}
