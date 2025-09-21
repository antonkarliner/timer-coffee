import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:coffee_timer/providers/theme_provider.dart';

/// A reusable widget that applies Liquid Glass effect conditionally on iOS.
/// On non-iOS platforms, it renders the child without any glass effect.
/// Respects accessibility settings for reduced motion and transparency.
class GlassContainer extends StatefulWidget {
  final Widget child;
  final double blurSigma;
  final Color? glassColor;
  final Color? borderColor;
  final double borderWidth;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? foregroundColor;

  const GlassContainer({
    Key? key,
    required this.child,
    this.blurSigma = 8.0,
    this.glassColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.borderRadius,
    this.padding,
    this.margin,
    this.foregroundColor,
  }) : super(key: key);

  /// Default foreground color that meets contrast requirements for text/icons
  /// when rendered on a glass background. Adjusts for theme brightness and
  /// accessibility high-contrast settings.
  static Color defaultForegroundColor(BuildContext context,
      {bool emphasize = false}) {
    final brightness = Theme.of(context).brightness;
    final mediaQuery = MediaQuery.maybeOf(context);
    final bool highContrast = (mediaQuery?.highContrast ?? false) ||
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
            .highContrast;

    final Color base =
        brightness == Brightness.dark ? Colors.white : Colors.black;
    if (highContrast) {
      return base;
    }

    final double targetOpacity = emphasize
        ? (brightness == Brightness.dark ? 0.95 : 0.92)
        : (brightness == Brightness.dark ? 0.92 : 0.88);
    return base.withOpacity(targetOpacity);
  }

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _blurAnimation;

  bool _prefersReducedMotion = false;
  bool _prefersReducedTransparency = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 320),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ).drive(Tween<double>(begin: 0.94, end: 1.0));

    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ).drive(Tween<double>(begin: 0.0, end: 1.0));

    _blurAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncAccessibilityPreferences(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final bool reducedMotion = mediaQuery?.disableAnimations ?? false;
    final bool reducedTransparency = _readReduceTransparencyFlag();

    if (_prefersReducedMotion != reducedMotion) {
      _prefersReducedMotion = reducedMotion;
      if (_prefersReducedMotion) {
        _controller.value = 1.0;
      } else {
        _controller.forward(from: 0.0);
      }
    }

    _prefersReducedTransparency = reducedTransparency;

    if (!_prefersReducedMotion && !_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAccessibilityPreferences(context);
  }

  bool _readReduceTransparencyFlag() {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    try {
      final dynamic features = dispatcher.accessibilityFeatures;
      final bool? reduceTransparency = features.reduceTransparency as bool?;
      return reduceTransparency ?? false;
    } on NoSuchMethodError {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  void didUpdateWidget(covariant GlassContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_prefersReducedMotion && widget.blurSigma != oldWidget.blurSigma) {
      _controller.forward(from: 0.2);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only apply glass effect on iOS
    if (!Platform.isIOS) {
      return Container(
        padding: widget.padding,
        margin: widget.margin,
        child: widget.child,
      );
    }

    _syncAccessibilityPreferences(context);

    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final mediaQuery = MediaQuery.of(context);
    final bool highContrast = mediaQuery.highContrast ||
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
            .highContrast;

    final themeProvider =
        Provider.of<ThemeProvider?>(context, listen: false);

    Color glassSurface = widget.glassColor ??
        (themeProvider?.glassSurfaceFor(brightness) ??
            (brightness == Brightness.dark
                ? const Color(0x1AFFFFFF)
                : const Color(0x99FFFFFF)));

    Color borderColor = widget.borderColor ??
        (themeProvider?.glassBorderFor(brightness) ??
            (brightness == Brightness.dark
                ? const Color(0x33FFFFFF)
                : const Color(0xB3FFFFFF)));

    final Color highlightColor = themeProvider?.glassHighlightFor(brightness) ??
        (brightness == Brightness.dark
            ? Colors.white.withOpacity(0.35)
            : Colors.white.withOpacity(0.72));

    final Color shadowColor = themeProvider?.glassShadowFor(brightness) ??
        (brightness == Brightness.dark
            ? Colors.black.withOpacity(0.45)
            : Colors.black.withOpacity(0.12));

    final Color tintColor = themeProvider?.glassTintFor(brightness) ??
        (brightness == Brightness.dark
            ? const Color(0x1427434D)
            : const Color(0x1A9AB0C6));

    if (_prefersReducedTransparency) {
      final double minOpacity = brightness == Brightness.dark ? 0.55 : 0.78;
      if (glassSurface.opacity < minOpacity) {
        glassSurface = glassSurface.withOpacity(minOpacity);
      }
      final double clampedBorderOpacity =
          borderColor.opacity.clamp(0.3, 0.95).toDouble();
      borderColor = borderColor.withOpacity(clampedBorderOpacity);
    }

    if (highContrast) {
      final double opacityBoost =
          brightness == Brightness.dark ? 0.18 : 0.22;
      final double boostedGlassOpacity =
          (glassSurface.opacity + opacityBoost).clamp(0.0, 1.0).toDouble();
      final double boostedBorderOpacity =
          (borderColor.opacity + 0.18).clamp(0.0, 1.0).toDouble();
      glassSurface = glassSurface.withOpacity(boostedGlassOpacity);
      borderColor = borderColor.withOpacity(boostedBorderOpacity);
    }

    final Color effectiveGlassColor = tintColor.alpha == 0
        ? glassSurface
        : Color.alphaBlend(tintColor, glassSurface);

    final BorderRadius effectiveBorderRadius =
        widget.borderRadius ?? BorderRadius.circular(28.0);

    final EdgeInsetsGeometry effectiveMargin = widget.margin ??
        const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0);

    final Color? resolvedForegroundColor = widget.foregroundColor;

    Widget content = widget.child;
    if (resolvedForegroundColor != null) {
      final controlFill =
          MaterialStateProperty.resolveWith<Color?>((states) {
        if (states.contains(MaterialState.disabled)) {
          return resolvedForegroundColor.withOpacity(0.3);
        }
        if (states.contains(MaterialState.selected)) {
          return resolvedForegroundColor
              .withOpacity(highContrast ? 1.0 : 0.85);
        }
        return resolvedForegroundColor.withOpacity(0.55);
      });

      final ThemeData themedData = theme.copyWith(
        textTheme: theme.textTheme.apply(
          bodyColor: resolvedForegroundColor,
          displayColor: resolvedForegroundColor,
        ),
        iconTheme: theme.iconTheme.copyWith(color: resolvedForegroundColor),
        listTileTheme: theme.listTileTheme.copyWith(
          textColor: resolvedForegroundColor,
          iconColor: resolvedForegroundColor,
        ),
        radioTheme: theme.radioTheme.copyWith(
          fillColor: controlFill,
        ),
        checkboxTheme: theme.checkboxTheme.copyWith(
          fillColor: controlFill,
          overlayColor: MaterialStateProperty.all(
              resolvedForegroundColor.withOpacity(0.12)),
          checkColor: MaterialStateProperty.all(
            brightness == Brightness.dark ? Colors.black : Colors.white,
          ),
          side: BorderSide(color: resolvedForegroundColor.withOpacity(0.35)),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: resolvedForegroundColor,
          ),
        ),
      );

      content = Theme(
        data: themedData,
        child: IconTheme(
          data: theme.iconTheme.copyWith(color: resolvedForegroundColor),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: resolvedForegroundColor),
            child: widget.child,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double scale =
            _prefersReducedMotion ? 1.0 : _scaleAnimation.value;
        final double opacity =
            _prefersReducedMotion ? 1.0 : _opacityAnimation.value;
        final double blurAmount = (_prefersReducedMotion ||
                _prefersReducedTransparency)
            ? 0.0
            : widget.blurSigma * _blurAnimation.value;

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              margin: effectiveMargin,
              decoration: BoxDecoration(
                borderRadius: effectiveBorderRadius,
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 40,
                    spreadRadius: -12,
                    offset: const Offset(0, 24),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: effectiveBorderRadius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: blurAmount,
                    sigmaY: blurAmount,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: effectiveGlassColor,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(
                              brightness == Brightness.dark ? 0.08 : 0.32),
                          Colors.white.withOpacity(
                              brightness == Brightness.dark ? 0.03 : 0.18),
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                      borderRadius: effectiveBorderRadius,
                    ),
                    child: CustomPaint(
                      foregroundPainter: _GlassRimPainter(
                        borderRadius: effectiveBorderRadius,
                        borderColor: borderColor,
                        borderWidth: widget.borderWidth,
                        highlightColor: highlightColor,
                        shadowColor: shadowColor,
                      ),
                      child: Padding(
                        padding: widget.padding ??
                            const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 16.0),
                        child: Material(
                          type: MaterialType.transparency,
                          child: content,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GlassRimPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final Color borderColor;
  final double borderWidth;
  final Color highlightColor;
  final Color shadowColor;

  const _GlassRimPainter({
    required this.borderRadius,
    required this.borderColor,
    required this.borderWidth,
    required this.highlightColor,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final RRect rrect = borderRadius.toRRect(Offset.zero & size);

    final double strokeOffset = borderWidth / 2;
    if (borderWidth > 0 && borderColor.opacity > 0) {
      final Paint borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..color = borderColor;
      canvas.drawRRect(rrect.deflate(strokeOffset), borderPaint);
    }

    final Paint rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          highlightColor,
          highlightColor.withOpacity(0.0),
          shadowColor.withOpacity(0.35),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(rrect.outerRect);
    canvas.drawRRect(rrect.deflate(0.5), rimPaint);
  }

  @override
  bool shouldRepaint(covariant _GlassRimPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.highlightColor != highlightColor ||
        oldDelegate.shadowColor != shadowColor;
  }
}
