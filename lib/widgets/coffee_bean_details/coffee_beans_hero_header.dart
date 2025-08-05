import 'package:flutter/material.dart';
import 'package:auto_size_text_plus/auto_size_text_plus.dart';
import 'package:coffeico/coffeico.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../models/coffee_beans_model.dart';
import '../../providers/coffee_beans_provider.dart';
import '../roaster_logo.dart';
import 'quick_stat_chip.dart';

/// A reusable hero header widget for coffee bean detail screens.
///
/// This widget displays the main coffee bean information in a visually appealing
/// hero header format with gradient background, roaster logo, bean details,
/// favorite toggle functionality, and quick stats for roast date and cupping score.
///
/// The component adapts to light/dark themes and provides proper contrast
/// in both modes. It includes comprehensive accessibility support and follows
/// the design patterns established in the coffee beans detail screen.
///
/// Example usage:
/// ```dart
/// CoffeeBeansHeroHeader(
///   bean: coffeeBean,
///   originalUrl: logoOriginalUrl,
///   mirrorUrl: logoMirrorUrl,
///   coffeeBeansProvider: provider,
///   onFavoriteToggle: () => _loadBean(),
/// )
/// ```
class CoffeeBeansHeroHeader extends StatelessWidget {
  /// The coffee bean model to display
  final CoffeeBeansModel bean;

  /// Original URL for the roaster logo
  final String? originalUrl;

  /// Mirror URL for the roaster logo (fallback)
  final String? mirrorUrl;

  /// Coffee beans provider for favorite toggle functionality
  final CoffeeBeansProvider coffeeBeansProvider;

  /// Callback function called after favorite status is toggled
  final VoidCallback? onFavoriteToggle;

  /// Optional custom gradient start color (defaults to theme-based gray)
  final Color? gradientStartColor;

  /// Optional custom gradient end color (defaults to theme-based gray)
  final Color? gradientEndColor;

  /// Optional custom icon color for fallback logo (defaults to theme-based color)
  final Color? fallbackIconColor;

  /// Optional custom text colors
  final Color? primaryTextColor;
  final Color? secondaryTextColor;
  final Color? tertiaryTextColor;

  /// Optional custom logo dimensions
  final double logoHeight;
  final double logoWidth;

  /// Optional custom favorite icon size
  final double favoriteIconSize;

  const CoffeeBeansHeroHeader({
    super.key,
    required this.bean,
    this.originalUrl,
    this.mirrorUrl,
    required this.coffeeBeansProvider,
    this.onFavoriteToggle,
    this.gradientStartColor,
    this.gradientEndColor,
    this.fallbackIconColor,
    this.primaryTextColor,
    this.secondaryTextColor,
    this.tertiaryTextColor,
    this.logoHeight = 80.0,
    this.logoWidth = 120.0,
    this.favoriteIconSize = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    // Theme-adaptive gradient colors
    final bgStart = gradientStartColor ??
        (isLight ? Colors.grey.shade200 : Colors.grey.shade800);
    final bgEnd = gradientEndColor ??
        (isLight ? Colors.grey.shade100 : Colors.grey.shade700);

    // Theme-adaptive text colors
    final primaryColor = primaryTextColor ?? theme.colorScheme.onSurface;
    final secondaryColor = secondaryTextColor ??
        theme.colorScheme.onSurfaceVariant.withOpacity(0.85);
    final tertiaryColor = tertiaryTextColor ??
        theme.colorScheme.onSurfaceVariant.withOpacity(0.6);
    final iconColor =
        fallbackIconColor ?? theme.colorScheme.onSurface.withOpacity(0.6);

    return Semantics(
      identifier: 'coffeeBeansHeroHeader_${bean.beansUuid}',
      label: '${bean.name} from ${bean.roaster}, ${bean.origin}',
      child: Card(
        elevation: 4,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [bgStart, bgEnd],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo or placeholder
                    _buildLogoSection(context, iconColor),
                    const SizedBox(width: 20),
                    // Name / roaster / origin
                    _buildInfoSection(
                        context, primaryColor, secondaryColor, tertiaryColor),
                    const SizedBox(width: 12),
                    // Favorite button
                    _buildFavoriteButton(context),
                  ],
                ),
                // Quick stats (roast date & cupping score)
                if (bean.roastDate != null || bean.cuppingScore != null)
                  _buildQuickStats(context, loc),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the logo section with roaster logo or fallback icon
  Widget _buildLogoSection(BuildContext context, Color iconColor) {
    return Semantics(
      identifier: 'roasterLogo_${bean.roaster}',
      label: 'Logo for ${bean.roaster}',
      child: SizedBox(
        height: logoHeight,
        width: logoWidth,
        child: (originalUrl != null || mirrorUrl != null)
            ? RoasterLogo(
                originalUrl: originalUrl,
                mirrorUrl: mirrorUrl,
                height: logoHeight,
                width: logoWidth,
                borderRadius: 12.0,
                forceFit: BoxFit.contain,
              )
            : Icon(
                Coffeico.bag_with_bean,
                size: 60,
                color: iconColor,
              ),
      ),
    );
  }

  /// Builds the main information section with bean name, roaster, and origin
  Widget _buildInfoSection(
    BuildContext context,
    Color primaryColor,
    Color secondaryColor,
    Color tertiaryColor,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            identifier: 'beanName_${bean.beansUuid}',
            label: 'Coffee bean name: ${bean.name}',
            child: AutoSizeText(
              bean.name,
              maxLines: 2,
              minFontSize: 12,
              overflow: TextOverflow.visible,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            identifier: 'roasterName_${bean.beansUuid}',
            label: 'Roaster: ${bean.roaster}',
            child: Text(
              bean.roaster,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: secondaryColor,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Semantics(
            identifier: 'beanOrigin_${bean.beansUuid}',
            label: 'Origin: ${bean.origin}',
            child: Text(
              bean.origin,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: tertiaryColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the favorite toggle button
  Widget _buildFavoriteButton(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Semantics(
      identifier: 'favoriteButton_${bean.beansUuid}',
      label: bean.isFavorite ? 'Remove from favorites' : 'Add to favorites',
      button: true,
      child: IconButton(
        iconSize: favoriteIconSize,
        icon: Icon(
          bean.isFavorite ? Icons.favorite : Icons.favorite_border,
          color: bean.isFavorite
              ? (isLight ? const Color(0xff8e2e2d) : const Color(0xffc66564))
              : null,
        ),
        onPressed: () async {
          await coffeeBeansProvider.toggleFavoriteStatus(
              bean.beansUuid!, !bean.isFavorite);
          onFavoriteToggle?.call();
        },
      ),
    );
  }

  /// Builds the quick stats section with roast date and cupping score
  Widget _buildQuickStats(BuildContext context, AppLocalizations loc) {
    return Semantics(
      identifier: 'quickStats_${bean.beansUuid}',
      label: 'Quick statistics',
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (bean.roastDate != null)
              QuickStatChip(
                icon: Icons.calendar_today,
                label: loc.roastDate,
                value: DateFormat.yMMMd().format(bean.roastDate!),
              ),
            if (bean.cuppingScore != null)
              QuickStatChip(
                icon: Icons.star,
                label: loc.cuppingScore,
                value: '${bean.cuppingScore}',
              ),
          ],
        ),
      ),
    );
  }
}
