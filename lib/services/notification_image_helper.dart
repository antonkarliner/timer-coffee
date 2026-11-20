import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:coffee_timer/utils/app_logger.dart';

import 'roaster_logo_client.dart';

/// Downloads a roaster logo and normalizes it into a PNG suitable for a local
/// notification attachment.
///
/// We always re-encode to PNG because:
///  - iOS `DarwinNotificationAttachment` resolves the media type from the file
///    extension/UTI and only accepts jpeg/png/gif. Source URLs frequently carry
///    query strings (`logo.png?width=1200`) or no usable extension at all, and
///    the always-`.webp` mirror logos are unsupported by iOS — all of which
///    cause the attachment to be silently dropped.
///  - Decoding then re-encoding guarantees the bytes match the extension, so the
///    same cached file works on both iOS and Android.
class NotificationImageHelper {
  static Future<String?> downloadLogoToCache(String url) async {
    if (!(Platform.isAndroid || Platform.isIOS)) return null;
    try {
      final tmp = await getTemporaryDirectory();
      // Previous app versions cached files produced by the unbounded loader.
      final dir = Directory(p.join(tmp.path, 'notif_logos_bounded_v1'));
      await dir.create(recursive: true);

      // Always a .png — the file is re-encoded below.
      final hash = sha1.convert(utf8.encode(url)).toString();
      final file = File(p.join(dir.path, '$hash.png'));
      if (await file.exists()) {
        final size = await file.length();
        if (size > 0 && size <= RoasterLogoClient.byteLimit) return file.path;
      }

      final uri = Uri.parse(url);
      if (RoasterLogoClient.isSvg(uri)) return null;
      final bytes = await RoasterLogoClient.download(uri);
      final temporary = File(
        '${file.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
      );
      try {
        await temporary.writeAsBytes(bytes, flush: true);
        await temporary.rename(file.path);
      } finally {
        if (await temporary.exists()) await temporary.delete();
      }
      return file.path;
    } catch (e) {
      AppLogger.debug('Notification logo download failed: $e');
      return null;
    }
  }
}
