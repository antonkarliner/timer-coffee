import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_endpoint_resolver.dart';
import '../utils/app_logger.dart';

/// Service for compressing and uploading bean cover photos to Supabase Storage.
///
/// Path convention: bean-photos/{userId}/{beansUuid}.jpg
/// Compression: 800px longest side, JPEG quality 70 (~50-80KB per photo)
class BeanPhotoService {
  static const String _bucket = 'bean-photos';
  static const int _maxSidePx = 800;
  static const int _jpegQuality = 60;

  final SupabaseClient _supabase;

  BeanPhotoService(this._supabase);

  /// Compresses [imageFile] and uploads it to Supabase Storage.
  /// Returns the public URL on success, or null on failure.
  Future<String?> uploadPhoto(File imageFile, String beansUuid) async {
    if (kIsWeb) return null; // Web has no file system access in this flow

    final user = _supabase.auth.currentUser;
    if (user == null || user.isAnonymous) return null;

    try {
      // Compress
      final compressed = await _compress(imageFile);
      if (compressed == null) return null;

      final path = '${user.id}/$beansUuid.jpg';

      // Upload (upsert so re-saves overwrite the old photo)
      await _supabase.storage.from(_bucket).uploadBinary(
            path,
            compressed,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      // Return a signed URL valid for 10 years (effectively permanent for user data)
      final signedUrl = await _supabase.storage
          .from(_bucket)
          .createSignedUrl(path, 60 * 60 * 24 * 365 * 10);

      AppLogger.debug('[BeanPhotoService] Uploaded photo for bean $beansUuid');
      // Store the canonical direct-host URL so proxy-region uploads don't leak
      // an api.timer.coffee host into shared data.
      return SupabaseEndpointResolver.canonicalizeStorageUrl(signedUrl);
    } catch (e) {
      AppLogger.error('[BeanPhotoService] Upload failed', errorObject: e);
      return null;
    }
  }

  /// Deletes the stored photo for [beansUuid]. Fire-and-forget; errors are logged.
  Future<void> deletePhoto(String beansUuid) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final path = '${user.id}/$beansUuid.jpg';
      await _supabase.storage.from(_bucket).remove([path]);
      AppLogger.debug('[BeanPhotoService] Deleted photo for bean $beansUuid');
    } catch (e) {
      AppLogger.warning('[BeanPhotoService] Delete failed (non-critical)',
          errorObject: e);
    }
  }

  /// Resize to max 800px on longest side, encode as JPEG quality 70.
  static Future<Uint8List?> _compress(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final img.Image resized;
      if (decoded.width >= decoded.height) {
        resized = decoded.width > _maxSidePx
            ? img.copyResize(decoded, width: _maxSidePx,
                interpolation: img.Interpolation.average)
            : decoded;
      } else {
        resized = decoded.height > _maxSidePx
            ? img.copyResize(decoded, height: _maxSidePx,
                interpolation: img.Interpolation.average)
            : decoded;
      }

      return Uint8List.fromList(img.encodeJpg(resized, quality: _jpegQuality));
    } catch (e) {
      AppLogger.error('[BeanPhotoService] Compression failed', errorObject: e);
      return null;
    }
  }
}
