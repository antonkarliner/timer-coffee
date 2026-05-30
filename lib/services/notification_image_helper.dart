import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:coffee_timer/utils/app_logger.dart';

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
  static const Duration _timeout = Duration(seconds: 5);

  /// Reject absurdly large downloads before decoding (logos are small).
  static const int _maxDownloadBytes = 5 * 1024 * 1024;

  /// Cap the longest edge so the attachment stays lightweight.
  static const int _maxDimension = 512;

  static Future<String?> downloadLogoToCache(String url) async {
    if (!(Platform.isAndroid || Platform.isIOS)) return null;
    try {
      final tmp = await getTemporaryDirectory();
      final dir = Directory(p.join(tmp.path, 'notif_logos'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Always a .png — the file is re-encoded below.
      final hash = sha1.convert(utf8.encode(url)).toString();
      final file = File(p.join(dir.path, '$hash.png'));
      if (await file.exists() && await file.length() > 0) {
        return file.path;
      }

      final response = await http.get(Uri.parse(url)).timeout(_timeout);
      if (response.statusCode != 200) return null;
      if (response.bodyBytes.isEmpty) return null;
      if (response.bodyBytes.length > _maxDownloadBytes) return null;

      // Decode any raster format (jpg/png/webp/gif). Non-raster sources such as
      // SVG return null → caller falls back to a text-only notification.
      final decoded = img.decodeImage(response.bodyBytes);
      if (decoded == null) {
        AppLogger.debug('Notification logo: undecodable format for $url');
        return null;
      }

      final resized = (decoded.width > _maxDimension ||
              decoded.height > _maxDimension)
          ? img.copyResize(
              decoded,
              width: decoded.width >= decoded.height ? _maxDimension : null,
              height: decoded.height > decoded.width ? _maxDimension : null,
            )
          : decoded;

      await file.writeAsBytes(img.encodePng(resized), flush: true);
      return file.path;
    } catch (e) {
      AppLogger.debug('Notification logo download failed: $e');
      return null;
    }
  }
}
