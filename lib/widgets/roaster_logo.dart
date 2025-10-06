import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:coffeico/coffeico.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'roaster_logo_cache_manager.dart';

class RoasterLogo extends StatefulWidget {
  final String? originalUrl;
  final String? mirrorUrl;
  final double height;
  final double? width;
  final double borderRadius;
  final BoxFit? forceFit;
  final void Function(bool isHorizontal)? onAspectRatioDetermined;
  final bool debugForceReanalysis;

  const RoasterLogo({
    Key? key,
    required this.originalUrl,
    required this.mirrorUrl,
    this.height = 40.0,
    this.width,
    this.borderRadius = 8.0,
    this.forceFit,
    this.onAspectRatioDetermined,
    this.debugForceReanalysis = false,
  }) : super(key: key);

  @override
  State<RoasterLogo> createState() => _RoasterLogoState();
}

class _RoasterLogoState extends State<RoasterLogo> {
  static SharedPreferences? _prefs;
  static Future<void>? _prefsInitializer;
  static const String _cacheVersionKey = 'aspect_ratio_cache_version';
  static const String _currentCacheVersion =
      'v2'; // Increment to invalidate old cache

  String? _currentUrl;
  bool _triedMirror = false;
  Color? _bgColor;
  BoxFit? _fit;
  bool? _isHorizontal;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.originalUrl;
    _initialize();
  }

  Future<void> _initialize() async {
    _prefsInitializer ??= SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });
    await _prefsInitializer;

    // Check if original is broken
    if (widget.originalUrl != null &&
        (_prefs?.getBool('broken_${_normalizeUrl(widget.originalUrl!)}') ??
            false) &&
        widget.mirrorUrl != null) {
      _currentUrl = widget.mirrorUrl;
      _triedMirror = true;
    } else {
      _currentUrl = widget.originalUrl;
      _triedMirror = false;
    }

    if (mounted) {
      _loadLogo();
    }
  }

  Future<void> _loadLogo() async {
    if (_currentUrl == null) {
      if (mounted) setState(() {});
      return;
    }

    final cacheKey = _normalizeUrl(_currentUrl!);
    final fit = _getFitFromCache(cacheKey);
    final color = _getBgColorFromCache(cacheKey);
    final isHorizontal = _getIsHorizontalFromCache(cacheKey);
    final cacheVersion = _getCacheVersion();

    // Check if we need to force re-analysis (debug mode or cache version mismatch)
    final forceReanalysis =
        widget.debugForceReanalysis || cacheVersion != _currentCacheVersion;

    if (forceReanalysis) {
      log('🔄 Forcing re-analysis for $_currentUrl (debug: ${widget.debugForceReanalysis}, cache version: $cacheVersion vs $_currentCacheVersion)');
      // Clear old cache if version mismatch
      if (cacheVersion != _currentCacheVersion) {
        await _clearCacheForUrl(cacheKey);
        await _saveCacheVersion(_currentCacheVersion);
      }
    }

    if (fit != null && !forceReanalysis) {
      log('✅ Using cached metadata for $_currentUrl, isHorizontal: ${isHorizontal ?? false}');
      if (mounted) {
        setState(() {
          _fit = fit;
          _bgColor = color;
          _isHorizontal = isHorizontal;
        });

        // Notify parent widget about the aspect ratio immediately for cached values
        if (isHorizontal != null) {
          log('📢 Notifying parent widget immediately: isHorizontal = $isHorizontal');
          // Use WidgetsBinding to ensure callback happens in the same frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              log('🚀 Executing callback for cached value: isHorizontal = $isHorizontal');
              widget.onAspectRatioDetermined?.call(isHorizontal);
            }
          });
        }
      }
      return;
    }

    log('ℹ️ No cached metadata for $_currentUrl or forcing re-analysis, computing...');

    try {
      final file = await RoasterLogoCacheManager.instance
          .getSingleFile(_currentUrl!, key: cacheKey);
      final bytes = await file.readAsBytes();

      final computedFit = await _computeFit(bytes);
      final computedColor = await _analyzeEdgeLuminance(
          bytes, Theme.of(context).brightness == Brightness.dark);
      final computedIsHorizontal = await _computeIsHorizontal(bytes);

      await _saveFitToCache(cacheKey, computedFit);
      await _saveBgColorToCache(cacheKey, computedColor);
      await _saveIsHorizontalToCache(cacheKey, computedIsHorizontal);

      if (mounted) {
        setState(() {
          _fit = computedFit;
          _bgColor = computedColor;
          _isHorizontal = computedIsHorizontal;
        });

        // Notify parent widget about the aspect ratio
        log('📢 Notifying parent widget: computed isHorizontal = $computedIsHorizontal');
        widget.onAspectRatioDetermined?.call(computedIsHorizontal);
      }
    } catch (_) {
      _handleError();
    }
  }

  Future<void> _handleError() async {
    if (!_triedMirror && widget.mirrorUrl != null) {
      // Mark the originalUrl as broken in prefs
      await _prefs?.setBool(
          'broken_${_normalizeUrl(widget.originalUrl!)}', true);
      if (mounted) {
        setState(() {
          _triedMirror = true;
          _currentUrl = widget.mirrorUrl;
        });
        _loadLogo();
      }
    } else {
      if (mounted) setState(() {});
    }
  }

  BoxFit? _getFitFromCache(String cacheKey) {
    final fitString = _prefs?.getString('fit_$cacheKey');
    if (fitString == null) return null;
    return BoxFit.values.firstWhere((e) => e.toString() == fitString);
  }

  Future<void> _saveFitToCache(String cacheKey, BoxFit fit) async {
    await _prefs?.setString('fit_$cacheKey', fit.toString());
  }

  Color? _getBgColorFromCache(String cacheKey) {
    final colorInt = _prefs?.getInt('bg_$cacheKey');
    if (colorInt == null) return null;
    if (colorInt == -1) return null;
    return Color(colorInt);
  }

  Future<void> _saveBgColorToCache(String cacheKey, Color? color) async {
    await _prefs?.setInt('bg_$cacheKey', color?.value ?? -1);
  }

  bool? _getIsHorizontalFromCache(String cacheKey) {
    return _prefs?.getBool('horizontal_$cacheKey');
  }

  Future<void> _saveIsHorizontalToCache(
      String cacheKey, bool isHorizontal) async {
    await _prefs?.setBool('horizontal_$cacheKey', isHorizontal);
  }

  String _normalizeUrl(String url) {
    final uri = Uri.parse(url);
    return uri.replace(query: '', fragment: '').toString();
  }

  String? _getCacheVersion() {
    return _prefs?.getString(_cacheVersionKey);
  }

  Future<void> _saveCacheVersion(String version) async {
    await _prefs?.setString(_cacheVersionKey, version);
  }

  Future<void> _clearCacheForUrl(String cacheKey) async {
    await _prefs?.remove('fit_$cacheKey');
    await _prefs?.remove('bg_$cacheKey');
    await _prefs?.remove('horizontal_$cacheKey');
    log('🗑️ Cleared cache for $cacheKey');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _prefsInitializer,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            height: widget.height,
            width: widget.width ?? widget.height,
            child: Center(
              child: Icon(Coffeico.bag_with_bean, size: widget.height),
            ),
          );
        }

        if (_currentUrl == null) {
          return Icon(Coffeico.bag_with_bean, size: widget.height);
        }

        if (_fit == null) {
          // Still loading
          return SizedBox(
            height: widget.height,
            width: widget.width ?? widget.height,
            child: Center(
              child: Icon(Coffeico.bag_with_bean, size: widget.height),
            ),
          );
        }

        final isSvg = _currentUrl!.toLowerCase().endsWith('.svg');
        final usedFit = widget.forceFit ?? _fit ?? BoxFit.contain;

        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: Container(
            height: widget.height,
            width: widget.width ?? widget.height,
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            child: FittedBox(
              fit: usedFit,
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: isSvg
                    ? SvgPicture.network(
                        _currentUrl!,
                        fit: BoxFit.contain,
                        placeholderBuilder: (context) =>
                            Icon(Coffeico.bag_with_bean, size: widget.height),
                      )
                    : CachedNetworkImage(
                        cacheKey: _normalizeUrl(_currentUrl!),
                        imageUrl: _currentUrl!,
                        cacheManager: RoasterLogoCacheManager.instance,
                        fit: BoxFit.contain,
                        placeholder: (context, url) =>
                            Icon(Coffeico.bag_with_bean, size: widget.height),
                        errorWidget: (context, url, error) {
                          _handleError();
                          return Icon(Coffeico.bag_with_bean,
                              size: widget.height);
                        },
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Static Analysis Functions (moved from original for clarity) ---
  static Future<BoxFit> _computeFit(Uint8List bytes) async {
    try {
      final img.Image? image = img.decodeImage(bytes);
      if (image == null) return BoxFit.contain;

      // Check for transparency
      bool hasTransparency = false;
      for (int y = 0; y < image.height && !hasTransparency; y++) {
        for (int x = 0; x < image.width; x++) {
          if (image.getPixel(x, y).a < 200) {
            hasTransparency = true;
            break;
          }
        }
      }

      if (hasTransparency) {
        // Transparency-based cropping heuristic
        int top = 0,
            bottom = image.height - 1,
            left = 0,
            right = image.width - 1;
        bool topFound = false,
            bottomFound = false,
            leftFound = false,
            rightFound = false;

        for (int y = 0; y < image.height; y++) {
          for (int x = 0; x < image.width; x++) {
            if (image.getPixel(x, y).a > 0) {
              top = y;
              topFound = true;
              break;
            }
          }
          if (topFound) break;
        }

        for (int y = image.height - 1; y >= 0; y--) {
          for (int x = 0; x < image.width; x++) {
            if (image.getPixel(x, y).a > 0) {
              bottom = y;
              bottomFound = true;
              break;
            }
          }
          if (bottomFound) break;
        }

        for (int x = 0; x < image.width; x++) {
          for (int y = 0; y < image.height; y++) {
            if (image.getPixel(x, y).a > 0) {
              left = x;
              leftFound = true;
              break;
            }
          }
          if (leftFound) break;
        }

        for (int x = image.width - 1; x >= 0; x--) {
          for (int y = 0; y < image.height; y++) {
            if (image.getPixel(x, y).a > 0) {
              right = x;
              rightFound = true;
              break;
            }
          }
          if (rightFound) break;
        }

        final w = right - left;
        final h = bottom - top;
        final isSquare = ((w - h).abs() / (w > h ? w : h)) <= 0.15;
        return isSquare ? BoxFit.cover : BoxFit.contain;
      } else {
        // Opaque image: detect solid margins
        List<img.Pixel> corners = [
          image.getPixel(0, 0),
          image.getPixel(image.width - 1, 0),
          image.getPixel(0, image.height - 1),
          image.getPixel(image.width - 1, image.height - 1),
        ];
        int avgR = 0, avgG = 0, avgB = 0;
        for (var p in corners) {
          avgR += p.r.toInt();
          avgG += p.g.toInt();
          avgB += p.b.toInt();
        }
        avgR = (avgR ~/ 4);
        avgG = (avgG ~/ 4);
        avgB = (avgB ~/ 4);

        bool isBg(img.Pixel p) {
          const int delta = 30;
          return (p.r - avgR).abs() <= delta &&
              (p.g - avgG).abs() <= delta &&
              (p.b - avgB).abs() <= delta;
        }

        final int threshW = (image.width * 0.10).floor();
        final int threshH = (image.height * 0.10).floor();

        int top = 0;
        for (; top < image.height; top++) {
          int diffCount = 0;
          for (int x = 0; x < image.width; x++) {
            if (!isBg(image.getPixel(x, top))) diffCount++;
          }
          if (diffCount > threshW) break;
        }
        int bottom = image.height - 1;
        for (; bottom >= 0; bottom--) {
          int diffCount = 0;
          for (int x = 0; x < image.width; x++) {
            if (!isBg(image.getPixel(x, bottom))) diffCount++;
          }
          if (diffCount > threshW) break;
        }
        int left = 0;
        for (; left < image.width; left++) {
          int diffCount = 0;
          for (int y = 0; y < image.height; y++) {
            if (!isBg(image.getPixel(left, y))) diffCount++;
          }
          if (diffCount > threshH) break;
        }
        int right = image.width - 1;
        for (; right >= 0; right--) {
          int diffCount = 0;
          for (int y = 0; y < image.height; y++) {
            if (!isBg(image.getPixel(right, y))) diffCount++;
          }
          if (diffCount > threshH) break;
        }

        final w = right - left;
        final h = bottom - top;
        final double horizMargin = (image.width - w) / image.width;
        final double vertMargin = (image.height - h) / image.height;
        if (horizMargin >= 0.15 || vertMargin >= 0.15) {
          return BoxFit.cover;
        }
        final isSquare = ((w - h).abs() / (w > h ? w : h)) <= 0.15;
        return isSquare ? BoxFit.cover : BoxFit.contain;
      }
    } catch (_) {
      return BoxFit.contain;
    }
  }

  static Future<Color?> _analyzeEdgeLuminance(
      Uint8List bytes, bool isDarkMode) async {
    return await compute((List<dynamic> args) {
      final Uint8List bytes = args[0];
      final bool isDarkMode = args[1];
      try {
        final img.Image? image = img.decodeImage(bytes);
        if (image == null) return null;
        final int w = image.width;
        final int h = image.height;
        List<img.Pixel> edgePixels = [];

        bool isTransparent(img.Pixel p) => p.a < 50;

        for (int x = 0; x < w; x++) {
          for (int y in [0, h - 1]) {
            final p = image.getPixel(x, y);
            if (p.a > 200) {
              bool touchesTransparency = false;
              for (var dy in [-1, 0, 1]) {
                int ny = y + dy;
                if (ny < 0 || ny >= h) continue;
                if (isTransparent(image.getPixel(x, ny))) {
                  touchesTransparency = true;
                }
              }
              if (touchesTransparency) edgePixels.add(p);
            }
          }
        }
        for (int y = 1; y < h - 1; y++) {
          for (int x in [0, w - 1]) {
            final p = image.getPixel(x, y);
            if (p.a > 200) {
              bool touchesTransparency = false;
              for (var dx in [-1, 0, 1]) {
                int nx = x + dx;
                if (nx < 0 || nx >= w) continue;
                if (isTransparent(image.getPixel(nx, y))) {
                  touchesTransparency = true;
                }
              }
              if (touchesTransparency) edgePixels.add(p);
            }
          }
        }
        if (edgePixels.isEmpty) return null;

        double luminanceSum = 0;
        for (var p in edgePixels) {
          int r = p.r.toInt();
          int g = p.g.toInt();
          int b = p.b.toInt();
          double l =
              0.2126 * (r / 255) + 0.7152 * (g / 255) + 0.0722 * (b / 255);
          luminanceSum += l;
        }
        double avgLuminance = luminanceSum / edgePixels.length;

        if (avgLuminance >= 0.85) {
          if (!isDarkMode) {
            return Colors.black.withOpacity(0.15);
          }
        } else if (avgLuminance <= 0.25) {
          if (isDarkMode) {
            return Colors.white;
          }
        }
        return null;
      } catch (_) {
        return null;
      }
    }, [bytes, isDarkMode]);
  }

  static Future<bool> _computeIsHorizontal(Uint8List bytes) async {
    return await compute((Uint8List bytes) {
      try {
        final img.Image? image = img.decodeImage(bytes);
        if (image == null) return false;

        // Consider horizontal if width is significantly greater than height (20% or more)
        final aspectRatio = image.width / image.height;
        final isHorizontal = aspectRatio > 1.2;
        log('🔍 Image analysis: ${image.width}x${image.height}, aspectRatio: $aspectRatio, isHorizontal: $isHorizontal');
        return isHorizontal;
      } catch (_) {
        return false;
      }
    }, bytes);
  }
}
