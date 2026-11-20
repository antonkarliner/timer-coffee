import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/roaster_logo_client.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class RoasterLogoCacheManager extends CacheManager {
  static const key = 'boundedRoasterLogoCache';
  static final instance = RoasterLogoCacheManager._();

  static Future<Uint8List> loadBytes(String url, {required String key}) async {
    if (kIsWeb) return RoasterLogoClient.download(Uri.parse(url));
    final file = await instance.getSingleFile(url, key: key);
    if (await file.length() > RoasterLogoClient.byteLimit) {
      throw const FormatException('Cached logo exceeds byte limit');
    }
    return file.readAsBytes();
  }

  RoasterLogoCacheManager._()
    : super(
        Config(
          key,
          fileService: HttpFileService(httpClient: RoasterLogoClient()),
          stalePeriod: const Duration(days: 30),
          maxNrOfCacheObjects: 300,
        ),
      );
}
