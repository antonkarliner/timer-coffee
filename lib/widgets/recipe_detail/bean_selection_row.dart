import 'dart:math' as math;
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:coffeico_plus/coffeico_plus.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:coffee_timer/theme/design_tokens.dart';
import 'package:coffee_timer/widgets/roaster_logo.dart';
import 'package:shared_preferences/shared_preferences.dart';

double _hairline(BuildContext context, {double scale = 1.0}) {
  final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
  return math.max(0.5, 1.0 / dpr) * scale; // stable hairline across devices
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
    super.key,
    required this.selectedBeanUuid,
    required this.selectedBeanName,
    required this.originalRoasterLogoUrl,
    required this.mirrorRoasterLogoUrl,
    required this.onSelectBeans,
    required this.onClearSelection,
  });

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
              BorderRadius.circular(AppRadius.small)
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
                  color: Theme.of(context).colorScheme.onSurface,
                ),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;

    final selected = widget.selectedBeanUuid != null;
    final textStyle = selected
        ? AppTextStyles.fieldLabel.copyWith(color: cs.onSurface)
        : AppTextStyles.body.copyWith(color: cs.onSurface);

    final borderSide = BorderSide(
      color: cs.outlineVariant,
      width: _hairline(context),
    );

    final radius = BorderRadius.circular(AppRadius.card);

    final label = Text(
      selected ? widget.selectedBeanName ?? '' : loc.selectBeans,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textStyle,
    );

    final clear = selected
        ? Tooltip(
            message: loc.fieldClearButtonTooltip,
            child: InkResponse(
              onTap: widget.onClearSelection,
              customBorder: const CircleBorder(),
              radius: 18,
              child: Icon(
                Icons.close_rounded,
                size: AppIconSize.small,
                color: cs.onSurface,
              ),
            ),
          )
        : const SizedBox();

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildCustomPlate(),
        const SizedBox(width: AppSpacing.sm),
        // Use Expanded for text to ensure proper ellipsis handling
        Expanded(
          child: label,
        ),
        const SizedBox(width: AppSpacing.sm),
        clear,
      ],
    );

    return IntrinsicWidth(
      child: Material(
        color: cs.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: radius, side: borderSide),
        child: InkWell(
          onTap: widget.onSelectBeans,
          borderRadius: radius,
          overlayColor:
              WidgetStateProperty.all(cs.onSurface.withValues(alpha: 0.06)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minHeight: 54, // Better proportion for 44px plates
                minWidth: 120, // Minimum width for usability
                maxWidth: maxWidth > 0
                    ? maxWidth
                    : double.infinity), // Use parent width as max
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.base),
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
