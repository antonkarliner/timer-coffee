import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:coffeico/coffeico.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';

import '../../app_router.gr.dart';
import '../../providers/coffee_beans_provider.dart';
import '../../providers/database_provider.dart';
import '../../models/coffee_beans_model.dart';
import '../confirm_delete_dialog.dart';
import '../roaster_logo.dart';

/// A stateless widget representing a coffee bean card in list view.
///
/// This widget displays coffee bean information in a horizontal card layout
/// with roaster logo, bean details, and action buttons. It follows the callback
/// pattern for all interactions and maintains the exact same UI/UX as the original.
class CoffeeBeanCard extends StatelessWidget {
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

  const CoffeeBeanCard({
    Key? key,
    required this.bean,
    required this.isEditMode,
    required this.onDelete,
    this.onFavoriteToggle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // neutral gradient
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgStart = isLight ? Colors.grey.shade200 : Colors.grey.shade800;
    final bgEnd = isLight ? Colors.grey.shade100 : Colors.grey.shade700;
    final iconColor =
        Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.6).round());

    const double logoHeight = 80.0;
    const double maxWidthFactor = 2.0;

    final coffeeBeansProvider =
        Provider.of<CoffeeBeansProvider>(context, listen: false);
    final databaseProvider =
        Provider.of<DatabaseProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;

    return Semantics(
      identifier: 'coffeeBeanCard_${bean.beansUuid}',
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
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [bgStart, bgEnd],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      // ───────── LOGO SLOT ─────────
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: logoHeight,
                            maxHeight: logoHeight,
                            minWidth: logoHeight,
                            maxWidth: logoHeight * maxWidthFactor,
                          ),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            alignment: Alignment.centerLeft,
                            child: FutureBuilder<Map<String, String?>>(
                              future: databaseProvider
                                  .fetchCachedRoasterLogoUrls(bean.roaster),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final originalUrl =
                                      snapshot.data!['original'];
                                  final mirrorUrl = snapshot.data!['mirror'];
                                  if (originalUrl != null ||
                                      mirrorUrl != null) {
                                    return RoasterLogo(
                                      originalUrl: originalUrl,
                                      mirrorUrl: mirrorUrl,
                                      height: logoHeight,
                                      borderRadius: 8.0,
                                      forceFit: BoxFit.contain,
                                    );
                                  }
                                }
                                return Icon(
                                  Coffeico.bag_with_bean,
                                  size: logoHeight,
                                  color: iconColor,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      // ───────── TEXT SECTION ─────────
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bean.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bean.roaster,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withAlpha((255 * 0.85).round()),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bean.origin,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withAlpha((255 * 0.6).round()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ───────── ACTION BUTTONS ─────────
                      if (isEditMode)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.red),
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
                      IconButton(
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
              ),
              // Weight label in top-right corner if available
              if (bean.validatedPackageWeightGrams != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${bean.validatedPackageWeightGrams!.toInt()}${loc.unitGramsShort}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
