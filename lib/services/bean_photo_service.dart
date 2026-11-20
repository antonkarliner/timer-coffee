import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/supabase_endpoint_resolver.dart';
import '../database/database.dart';
import '../utils/app_logger.dart';

/// Owned object identifiers travel in the existing photo_url field. The
/// stored legacy signed URL is treated only as an object-key reference.
class BeanPhotoService {
  static const String _bucket = 'bean-photos';
  static const int _maxSidePx = 800;
  static const int _jpegQuality = 60;
  static const int readLinkSeconds = 5 * 60;

  final SupabaseClient _client;
  final User? Function() _currentUser;

  BeanPhotoService(this._client, this._currentUser);

  factory BeanPhotoService.forDatabase(AppDatabase db) {
    final scope = db.accountScope;
    if (scope != null) {
      return BeanPhotoService(scope.client, () => scope.currentUser);
    }
    final client = Supabase.instance.client;
    return BeanPhotoService(client, () => client.auth.currentUser);
  }

  static String? ownedObjectKey(
    String? reference, {
    required String ownerId,
    required String beanId,
  }) {
    if (reference == null || !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(beanId)) {
      return null;
    }
    String key = reference;
    final uri = Uri.tryParse(reference);
    if (uri == null) return null;
    if (uri.hasScheme || uri.hasAuthority) {
      final direct = Uri.parse(SupabaseEndpointResolver.directUrl);
      final proxy = Uri.parse(SupabaseEndpointResolver.proxyUrl);
      if (uri.scheme != 'https' ||
          uri.userInfo.isNotEmpty ||
          (uri.authority != direct.authority &&
              uri.authority != proxy.authority)) {
        return null;
      }
      const prefix = '/storage/v1/object/sign/bean-photos/';
      if (!uri.path.startsWith(prefix)) return null;
      key = uri.path.substring(prefix.length);
    }

    final expected = RegExp(
      '^${RegExp.escape(ownerId)}/${RegExp.escape(beanId)}'
      '(?:--[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12})?\\.jpg\$',
    );
    return expected.hasMatch(key) ? key : null;
  }

  Future<String?> uploadPhoto(File imageFile, String beansUuid) async {
    if (kIsWeb) return null;
    final user = _currentUser();
    if (user == null || user.isAnonymous) return null;

    try {
      final compressed = await _compress(imageFile);
      if (compressed == null || _currentUser()?.id != user.id) return null;
      final path = '${user.id}/$beansUuid--${const Uuid().v7()}.jpg';
      await _client.storage
          .from(_bucket)
          .uploadBinary(
            path,
            compressed,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              cacheControl: '300',
            ),
          );
      return path;
    } catch (error) {
      AppLogger.warning('Bean photo upload failed', errorObject: error);
      return null;
    }
  }

  /// Resolve a short-lived display link only while this account is active.
  Future<String?> readUrl(String reference, String beanId) async {
    final user = _currentUser();
    if (user == null || user.isAnonymous) return null;
    final key = ownedObjectKey(reference, ownerId: user.id, beanId: beanId);
    if (key == null) return null;
    try {
      final url = await _client.storage
          .from(_bucket)
          .createSignedUrl(key, readLinkSeconds);
      return _currentUser()?.id == user.id ? url : null;
    } catch (error) {
      AppLogger.warning('Bean photo could not be opened', errorObject: error);
      return null;
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
            ? img.copyResize(
                decoded,
                width: _maxSidePx,
                interpolation: img.Interpolation.average,
              )
            : decoded;
      } else {
        resized = decoded.height > _maxSidePx
            ? img.copyResize(
                decoded,
                height: _maxSidePx,
                interpolation: img.Interpolation.average,
              )
            : decoded;
      }

      return Uint8List.fromList(img.encodeJpg(resized, quality: _jpegQuality));
    } catch (e) {
      AppLogger.error('[BeanPhotoService] Compression failed', errorObject: e);
      return null;
    }
  }
}
