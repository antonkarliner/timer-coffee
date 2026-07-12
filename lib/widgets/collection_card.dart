import 'package:auto_route/auto_route.dart';
import 'package:coffee_timer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_router.gr.dart';
import '../models/recipe_collection_model.dart';
import '../services/analytics_service.dart';
import '../services/collection_new_badge_service.dart';
import '../theme/design_tokens.dart';

/// Full-width collection card shown on the Brewing Methods home.
///
/// Visual treatment mirrors [CoffeeBeanCard] (Card + elevation + gradient
/// background, horizontal logo/text layout) for a consistent look across
/// the app's discovery surfaces.
class CollectionCard extends StatelessWidget {
  final RecipeCollectionModel collection;
  final int cardIndex;
  final int collectionCount;

  const CollectionCard({
    super.key,
    required this.collection,
    required this.cardIndex,
    required this.collectionCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hasNew = context.watch<CollectionNewBadgeService>().hasNew(
      collection.id,
    );
    final isLight = theme.brightness == Brightness.light;
    final bgStart = isLight ? Colors.grey.shade400 : Colors.grey.shade800;
    final bgEnd = isLight ? Colors.grey.shade300 : Colors.grey.shade700;

    const double emojiBoxSize = 80.0;
    final hasDescription =
        collection.description != null && collection.description!.isNotEmpty;

    return Semantics(
      identifier: 'collectionCard_${collection.id}',
      label: hasNew
          ? '${collection.name}, ${l10n.collectionNewBadgeLabel}'
          : collection.name,
      child: GestureDetector(
        onTap: () {
          AnalyticsService.instance.track(
            'collection_card_tapped',
            properties: {
              'collection_id': collection.id,
              'source': 'home_carousel',
              'card_index': cardIndex,
              'collection_count': collectionCount,
              'has_new_badge': hasNew,
            },
          );
          context.router.push(
            CollectionDetailRoute(collectionId: collection.id),
          );
        },
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          elevation: 4,
          clipBehavior: Clip.antiAlias,
          // Horizontal spacing handled by the parent carousel; keep only
          // a small vertical margin so the elevation shadow has room.
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    children: [
                      // ───────── EMOJI SLOT ─────────
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.small),
                        child: Container(
                          height: emojiBoxSize,
                          width: emojiBoxSize,
                          alignment: Alignment.center,
                          color: theme.colorScheme.surface.withAlpha(
                            (255 * 0.6).round(),
                          ),
                          child: Text(
                            collection.emoji,
                            style: const TextStyle(fontSize: 48),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // ───────── TEXT SECTION ─────────
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              collection.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            if (hasDescription) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                collection.description!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withAlpha((255 * 0.85).round()),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (hasNew)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Container(
                    width: AppSpacing.sm + AppStroke.focus,
                    height: AppSpacing.sm + AppStroke.focus,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: AppStroke.focus,
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
