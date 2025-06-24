import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class RoasterLogoCacheManager extends CacheManager {
  static const key = 'roasterLogoCache';
  static final instance = RoasterLogoCacheManager._();

  RoasterLogoCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 100,
          ),
        );
}
