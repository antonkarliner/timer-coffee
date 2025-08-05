import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:coffeico/coffeico.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:auto_size_text_plus/auto_size_text_plus.dart';

import '../../app_router.gr.dart';
import '../../providers/coffee_beans_provider.dart';
import '../../providers/database_provider.dart';
import '../../models/coffee_beans_model.dart';
import '../confirm_delete_dialog.dart';
import '../roaster_logo.dart';

/// A stateless widget representing a coffee bean card in grid view.
///
/// This widget displays coffee bean information in a compact vertical card layout
/// optimized for grid display. It uses AutoSizeText for responsive text scaling
/// and follows the callback pattern for all interactions.
class CoffeeBeanGridCard extends StatelessWidget {
  /// The coffee bean model to display
  final CoffeeBeansModel bean;

  /// Whether the card is in edit mode
  final bool isEditMode;

  /// Callback for delete action
  final VoidCallback onDelete;

  /// Callback for favorite toggle action
  final VoidCallback? onFavoriteToggle;

  /// Callback for navigation to detail screen
  final VoidCallback? onTap;

  const CoffeeBeanGridCard({
    Key? key,
    required this.bean,
    required this.isEditMode,
    required this.onDelete,
    this.onFavoriteToggle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // same neutral gradient as hero header
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgStart = isLight ? Colors.grey.shade200 : Colors.grey.shade800;
    final bgEnd = isLight ? Colors.grey.shade100 : Colors.grey.shade700;
    // icon tint
    final iconColor =
        Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.6).round());

    final coffeeBeansProvider =
        Provider.of<CoffeeBeansProvider>(context, listen: false);
    final databaseProvider =
        Provider.of<DatabaseProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;

    return Semantics(
      identifier: 'coffeeBeanGridCard_${bean.beansUuid}',
      label: '${bean.name}, ${bean.roaster}, ${bean.origin}',
      child: GestureDetector(
        onTap: onTap ??
            () => context.router
                .push(CoffeeBeansDetailRoute(uuid: bean.beansUuid!)),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bgStart, bgEnd],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with favorite - reduced padding
                Container(
                  height: 40, // Fixed height
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        iconSize: 18, // Reduced size
                        padding: const EdgeInsets.all(4), // Reduced padding
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        icon: Icon(
                          bean.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: bean.isFavorite
                              ? (Theme.of(context).brightness ==
                                      Brightness.light
                                  ? const Color(0xff8e2e2d)
                                  : const Color(0xffc66564))
                              : null,
                        ),
                        onPressed: onFavoriteToggle ??
                            () async {
                              await coffeeBeansProvider.toggleFavoriteStatus(
                                bean.beansUuid!,
                                !bean.isFavorite,
                              );
                            },
                      ),
                    ],
                  ),
                ),

                // Logo section - flexible but with constraints
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: FutureBuilder<Map<String, String?>>(
                      future: databaseProvider
                          .fetchCachedRoasterLogoUrls(bean.roaster),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final originalUrl = snapshot.data!['original'];
                          final mirrorUrl = snapshot.data!['mirror'];
                          if (originalUrl != null || mirrorUrl != null) {
                            return RoasterLogo(
                              originalUrl: originalUrl,
                              mirrorUrl: mirrorUrl,
                              height: 50, // Reduced height
                              borderRadius: 8.0,
                              forceFit: BoxFit.contain,
                            );
                          }
                        }
                        return Icon(
                          Coffeico.bag_with_bean,
                          size: 50, // Reduced size
                          color: iconColor,
                        );
                      },
                    ),
                  ),
                ),

                // Text information - flexible with minimum height
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize:
                          MainAxisSize.min, // Important: minimize space
                      children: [
                        const SizedBox(height: 6),
                        Flexible(
                          // Use Flexible instead of fixed height
                          child: AutoSizeText(
                            bean.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 2, // Reduced from 3
                            minFontSize: 10, // Reduced from 12
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 2), // Reduced spacing
                        Text(
                          bean.roaster,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withAlpha((255 * 0.85).round()),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2), // Reduced spacing
                        Text(
                          bean.origin,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withAlpha((255 * 0.6).round()),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                // Action buttons - only show in edit mode with fixed height
                if (isEditMode)
                  Container(
                    height: 40, // Fixed height
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          iconSize: 18, // Reduced size
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => ConfirmDeleteDialog(
                                title: loc.confirmDeleteTitle,
                                content: loc.confirmDeleteMessage,
                                confirmLabel: loc.delete,
                                cancelLabel: loc.cancel,
                              ),
                            );
                            if (confirmed == true) onDelete();
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
