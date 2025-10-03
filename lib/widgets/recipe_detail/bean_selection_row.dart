import 'dart:math' as math;
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:coffeico/coffeico.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/widgets/roaster_logo.dart';
import 'package:shared_preferences/shared_preferences.dart';

double _hairline(BuildContext context, {double scale = 1.0}) {
  final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
  return math.max(0.5, 1.0 / dpr) * scale; // stable hairline across devices
}

/// Tokens resolved from Theme.of(context).colorScheme
@immutable
class BeansChipTokens {
  final Color container;
  final Color border;
  final Color text;
  final Color plate;
  final Color plateBorder;
  final Color overlay; // pressed/hover overlay

  const BeansChipTokens({
    required this.container,
    required this.border,
    required this.text,
    required this.plate,
    required this.plateBorder,
    required this.overlay,
  });

  factory BeansChipTokens.resolve(ColorScheme cs, Brightness b) {
    // Tonal "quiet" defaults using M3 containers + outlineVariant.
    // Light maps close to: container ~ #F2F3F5, border ~ black@6–10%,
    // Dark maps close to:   container ~ #2C2C2E, border ~ white@10–12%.
    return BeansChipTokens(
      container: b == Brightness.light
          ? cs.surfaceContainerHighest
          : cs.surfaceContainerHighest, // works well for both
      border: cs.outlineVariant,
      text: cs.onSurface,
      plate:
          b == Brightness.light ? Colors.grey.shade400 : Colors.grey.shade700,
      //: Color(
      //0xFF5A6268), // Custom medium-grey for better contrast in dark mode
      plateBorder: cs.outlineVariant,
      overlay: cs.onSurface.withOpacity(0.06),
    );
  }
}

class BeansChip extends StatelessWidget {
  const BeansChip({
    super.key,
    required this.onTap,
    this.onClear,
    this.labelText,
    this.logoImage,
    this.placeholderText = 'Select Beans',
    this.enabled = true,
    this.ghost = false,
    this.height = 44,
    this.minWidth = 0, // allow to shrink in tight spaces
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.clearTooltip = 'Clear',
  });

  final VoidCallback onTap;
  final VoidCallback? onClear;

  /// When null => empty state (placeholder)
  final String? labelText;

  /// When null => show generic beans icon in the plate
  final ImageProvider? logoImage;

  final String placeholderText;
  final bool enabled;

  /// Transparent container but keeps the plate (even lighter look)
  final bool ghost;

  final double height;
  final double minWidth;
  final EdgeInsets padding;
  final String clearTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final b = theme.brightness;
    final t = BeansChipTokens.resolve(cs, b);

    final selected = labelText != null;
    final containerColor = ghost ? Colors.transparent : t.container;
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: t.text.withOpacity(enabled ? 1 : 0.5),
      height: 1.2,
    );

    final borderSide = BorderSide(
      color: t.border.withOpacity(ghost ? 0.6 : 1),
      width: _hairline(context),
    );

    final radius = BorderRadius.circular(14);

    Widget buildPlate() {
      final hasLogo = logoImage != null;
      final plate = AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: 36, // Increased from 28 to 36
        height: 36, // Increased from 28 to 36
        decoration: BoxDecoration(
          color: hasLogo ? t.plate : Colors.transparent,
          borderRadius: BorderRadius.circular(10), // Increased from 8 to 10
          border: hasLogo
              ? Border.all(
                  color: t.plateBorder.withOpacity(0.8),
                  width: _hairline(context))
              : null,
        ),
        clipBehavior: Clip.hardEdge,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1).animate(anim),
                  child: child)),
          child: hasLogo
              ? Image(
                  key: const ValueKey('logo'),
                  image: logoImage!,
                  fit: BoxFit.contain,
                )
              : Icon(
                  key: const ValueKey('placeholder'),
                  Coffeico.bag_with_bean,
                  size: 22, // Increased from 18 to 22
                  color: t.text.withOpacity(0.55),
                ),
        ),
      );
      return plate;
    }

    final label = Flexible(
      child: Text(
        selected ? labelText! : placeholderText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle?.copyWith(
          fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
          color: selected ? t.text : t.text.withOpacity(0.75),
        ),
      ),
    );

    final clear = onClear == null
        ? const SizedBox()
        : Tooltip(
            message: clearTooltip,
            child: InkResponse(
              onTap: enabled ? onClear : null,
              customBorder: const CircleBorder(),
              radius: 18,
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: t.text.withOpacity(0.6),
              ),
            ),
          );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildPlate(),
        const SizedBox(width: 10),
        label,
        const SizedBox(width: 10),
        if (onClear != null) clear,
      ],
    );

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth, minHeight: height),
      child: Material(
        color: containerColor,
        shape: RoundedRectangleBorder(borderRadius: radius, side: borderSide),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: radius,
          overlayColor: WidgetStateProperty.all(t.overlay),
          child: Padding(
            padding: padding,
            child: SizedBox(
                height: height,
                child: Align(alignment: Alignment.centerLeft, child: content)),
          ),
        ),
      ),
    );
  }
}

/// Stateless bean selection row used in Recipe Detail.
/// All state and side effects (SharedPreferences, providers) must be handled by the caller.
class BeanSelectionRow extends StatefulWidget {
  final String? selectedBeanUuid;
  final String? selectedBeanName;
  final String? originalRoasterLogoUrl;
  final String? mirrorRoasterLogoUrl;

  /// Called when the user taps the button to choose beans.
  final VoidCallback onSelectBeans;

  /// Called when the user taps the clear (cancel) icon.
  final VoidCallback onClearSelection;

  const BeanSelectionRow({
    Key? key,
    required this.selectedBeanUuid,
    required this.selectedBeanName,
    required this.originalRoasterLogoUrl,
    required this.mirrorRoasterLogoUrl,
    required this.onSelectBeans,
    required this.onClearSelection,
  }) : super(key: key);

  @override
  State<BeanSelectionRow> createState() => _BeanSelectionRowState();
}

class _BeanSelectionRowState extends State<BeanSelectionRow> {
  bool _isLogoHorizontal = false;
  bool _callbackReceived = false;

  @override
  void initState() {
    super.initState();
    // Reset the horizontal flag when the widget is initialized
    developer.log(
        '🏗️ BeanSelectionRow initState: Resetting _isLogoHorizontal to false');
    _isLogoHorizontal = false;
    _callbackReceived = false;

    // Set a fallback timer in case callback is never received
    _scheduleFallbackCheck();
  }

  @override
  void didUpdateWidget(BeanSelectionRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset the horizontal flag when the logo image changes
    if (oldWidget.originalRoasterLogoUrl != widget.originalRoasterLogoUrl ||
        oldWidget.mirrorRoasterLogoUrl != widget.mirrorRoasterLogoUrl ||
        oldWidget.selectedBeanUuid != widget.selectedBeanUuid) {
      developer.log(
          '🔄 BeanSelectionRow didUpdateWidget: Logo changed, resetting _isLogoHorizontal to false');
      setState(() {
        _isLogoHorizontal = false;
        _callbackReceived = false;
      });

      // Reschedule fallback check for new logo
      _scheduleFallbackCheck();
    }
  }

  void _scheduleFallbackCheck() {
    // Cancel any previous timer
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_callbackReceived && widget.selectedBeanUuid != null) {
        developer.log(
            '⏰ Fallback check: No callback received, keeping square layout as default');
        setState(() {
          _isLogoHorizontal = false; // Default to square, safer fallback
        });
      }
    });
  }

  Future<bool> _getCachedIsHorizontal() async {
    if (widget.originalRoasterLogoUrl == null) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _normalizeUrl(widget.originalRoasterLogoUrl!);
      return prefs.getBool('horizontal_$cacheKey') ?? false;
    } catch (e) {
      developer.log('❌ Error getting cached aspect ratio: $e');
      return false;
    }
  }

  String _normalizeUrl(String url) {
    final uri = Uri.parse(url);
    return uri.replace(query: '', fragment: '').toString();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // Check for cached aspect ratio immediately
    if (!_callbackReceived && widget.originalRoasterLogoUrl != null) {
      _getCachedIsHorizontal().then((cachedIsHorizontal) {
        if (mounted &&
            !_callbackReceived &&
            cachedIsHorizontal != _isLogoHorizontal) {
          developer.log('🎯 Using cached aspect ratio: $cachedIsHorizontal');
          setState(() {
            _isLogoHorizontal = cachedIsHorizontal;
          });
        }
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate maximum width based on parent constraints
        final maxWidth = constraints.maxWidth;
        developer.log('📏 LayoutBuilder: maxWidth=$maxWidth');

        return _buildDynamicButton(context, loc, maxWidth);
      },
    );
  }

  Widget _buildDynamicButton(
      BuildContext context, AppLocalizations loc, double maxWidth) {
    // For the BeansChip, we need to convert the RoasterLogo to an ImageProvider
    // Since RoasterLogo is a complex widget with caching and fallback logic,
    // we'll use a different approach - we'll create a custom plate widget
    // that includes the RoasterLogo functionality

    Widget buildCustomPlate() {
      // Give RoasterLogo a unique key that changes on every bean selection
      final Key? roasterLogoKey = widget.selectedBeanUuid != null
          ? ValueKey(
              widget.selectedBeanUuid! +
                  (widget.originalRoasterLogoUrl ?? '') +
                  (widget.mirrorRoasterLogoUrl ?? ''),
            )
          : null;

      final hasLogo = widget.selectedBeanUuid != null &&
          (widget.originalRoasterLogoUrl != null ||
              widget.mirrorRoasterLogoUrl != null);

      // Make plate responsive: square for square logos (44x44), wider for horizontal logos (60x40)
      final plateWidth =
          _isLogoHorizontal ? 60.0 : 44.0; // Middle ground dimensions
      final plateHeight = _isLogoHorizontal ? 40.0 : 44.0;

      developer.log(
          '🎨 Building plate: _isLogoHorizontal=$_isLogoHorizontal, plateWidth=$plateWidth');

      return AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: plateWidth,
        height: plateHeight,
        decoration: BoxDecoration(
          color: hasLogo
              ? (Theme.of(context).brightness == Brightness.light
                  ? Colors.grey.shade400
                  : Colors.grey
                      .shade700) // Custom medium-grey for better contrast in dark mode
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(11), // Middle ground for 44x44 plate
          // Removed border for cleaner appearance
        ),
        clipBehavior: Clip.hardEdge,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1).animate(anim),
                  child: child)),
          child: hasLogo
              ? Padding(
                  key: const ValueKey('logo'),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 2.0,
                      vertical:
                          2.0), // Reduced horizontal padding to allow more spread
                  child: RoasterLogo(
                    key: roasterLogoKey,
                    originalUrl: widget.originalRoasterLogoUrl,
                    mirrorUrl: widget.mirrorRoasterLogoUrl,
                    height: _isLogoHorizontal
                        ? 36.0
                        : 40.0, // Middle ground dimensions
                    width:
                        _isLogoHorizontal ? 56.0 : 40.0, // Proportional scaling
                    borderRadius: 4,
                    forceFit: BoxFit.contain,
                    debugForceReanalysis:
                        false, // Disable debug mode for production
                    onAspectRatioDetermined: (isHorizontal) {
                      developer.log(
                          '📨 BeanSelectionRow received callback: isHorizontal=$isHorizontal, current=$_isLogoHorizontal, mounted=$mounted');
                      _callbackReceived = true;
                      if (mounted && _isLogoHorizontal != isHorizontal) {
                        developer.log(
                            '🔄 BeanSelectionRow updating state: _isLogoHorizontal changing from $_isLogoHorizontal to $isHorizontal');
                        setState(() {
                          _isLogoHorizontal = isHorizontal;
                        });
                      } else if (!mounted) {
                        developer.log(
                            '⚠️ BeanSelectionRow callback received but widget not mounted');
                      } else {
                        developer.log(
                            'ℹ️ BeanSelectionRow callback received but no state change needed');
                      }
                    },
                  ),
                )
              : Icon(
                  key: const ValueKey('placeholder'),
                  Coffeico.bag_with_bean,
                  size: 28, // Middle ground for 44x44 plate
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                ),
        ),
      );
    }

    // Create a custom implementation of BeansChip that uses our RoasterLogo
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final b = theme.brightness;
    final t = BeansChipTokens.resolve(cs, b);

    final selected = widget.selectedBeanUuid != null;
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: t.text,
      height: 1.2,
    );

    final borderSide = BorderSide(
      color: t.border,
      width: _hairline(context),
    );

    final radius = BorderRadius.circular(14);

    final label = Flexible(
      child: Text(
        selected ? widget.selectedBeanName ?? '' : loc.selectBeans,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle?.copyWith(
          fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
          color: selected ? t.text : t.text.withOpacity(0.75),
        ),
      ),
    );

    final clear = selected
        ? Tooltip(
            message: 'Clear',
            child: InkResponse(
              onTap: widget.onClearSelection,
              customBorder: const CircleBorder(),
              radius: 18,
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: t.text.withOpacity(0.6),
              ),
            ),
          )
        : const SizedBox();

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildCustomPlate(),
        const SizedBox(width: 10),
        // Use Expanded for text to ensure proper ellipsis handling
        Expanded(
          child: label,
        ),
        const SizedBox(width: 8),
        clear,
      ],
    );

    return IntrinsicWidth(
      child: Material(
        color: t.container,
        shape: RoundedRectangleBorder(borderRadius: radius, side: borderSide),
        child: InkWell(
          onTap: widget.onSelectBeans,
          borderRadius: radius,
          overlayColor: WidgetStateProperty.all(t.overlay),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minHeight: 54, // Better proportion for 44px plates
                minWidth: 120, // Minimum width for usability
                maxWidth: maxWidth > 0
                    ? maxWidth
                    : double.infinity), // Use parent width as max
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                  height: 54, // Better proportion for 44px plates
                  child:
                      Align(alignment: Alignment.centerLeft, child: content)),
            ),
          ),
        ),
      ),
    );
  }
}
